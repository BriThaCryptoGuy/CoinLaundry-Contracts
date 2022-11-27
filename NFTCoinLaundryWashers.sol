// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src//DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721EnumerableLite.sol";

contract NFTCoinLaundryWashers is 
    ERC721EnumerableLite,
    PaymentSplitter,
    DefaultOperatorFilterer,
    Ownable {
    using Strings for uint;

    uint public MAX_ORDER  = 20;
    uint public MAX_SUPPLY = 105;
    uint public PRICE      = 0.03 ether;

    bool public isActive   = true; 

    string private _baseTokenURI;
    string private _tokenURISuffix;

    address[] private addressList = [
        0x74371cd314AC736F5ce9e52afb488cC2eE6C4828,
        0x327EC442254e9Dc1dd91c2156725e0A523C06850

    ];
    uint[] private shareList = [
        80,
        20
    ];

    constructor()
    ERC721B("Washers", "WASH", 1)
    PaymentSplitter(addressList, shareList) {
        _baseTokenURI = "ipfs://bafybeielahtpv7xai4g2px337kcu5w7ocrkxdu4rlshxko2bag2pqczowu/";
        _tokenURISuffix = ".json";

        for(uint i = 1; i <= 74; ++i){
            _mint( msg.sender, i);
        }
        _mint(0x2C7C6E83aE6b0b37D64f3568df668D880dC58A73, 75);
    }

    fallback() external payable {}

    //Externals
    function mint( uint quantity ) external payable {
        require( isActive, "ERR:NA"); //Error -> Not Active 
        require( quantity <= MAX_ORDER, "ERR:OO"); //Error -> Oversized Order
        if (msg.sender != owner()) {
            require( msg.value >= PRICE * quantity, "ERR:TU"); //Error -> Transaction Underpriced
        }    

        uint supply = totalSupply();
        require( supply + quantity <= MAX_SUPPLY, "ERR:MO" ); //Error -> Mint Overflow
        for(uint i; i < quantity; ++i){
            _mint( msg.sender, supply + (i+1));
        }
    }

    function tokenURI(uint tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
    }

    //internal
    function _mint(address to, uint tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    //onlyOwner
    function setActive(bool isActive_) external onlyOwner{
        require( isActive != isActive_, "ERR:NC" ); //Error -> No Change
        isActive = isActive_;
    }
    
    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyOwner{
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function setMaxOrder(uint maxOrder) external onlyOwner{
        require( MAX_ORDER != maxOrder, "ERR:NC" ); //Error -> No Change
        MAX_ORDER = maxOrder;
    }

    function setPrice(uint price ) external onlyOwner{
        require( PRICE != price, "ERR:NC" ); //Error -> No Change
        PRICE = price;
    }


    
    function setMaxSupply(uint maxSupply) external onlyOwner{
        require( MAX_SUPPLY != maxSupply, "ERR:NC" ); //Error -> No Change
        require( maxSupply >= totalSupply(), "ERR:SL" ); //Error -> Supply To Low
        MAX_SUPPLY = maxSupply;
    }

     //Overrides
     function setApprovalForAll(address operator, bool approved) public virtual override(ERC721B, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721B, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721B, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721B, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721B, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}
