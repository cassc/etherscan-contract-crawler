pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/*


 */
contract DogeElemental is ERC721A,ERC2981, Ownable,DefaultOperatorFilterer {

    constructor(address payable royaltyReceiver) ERC721A("Doge Elemental Bean", "Doge Elemental Bean") {
        _setDefaultRoyalty(royaltyReceiver, 500);
    }
    bool public sales_locked=false;
    uint8 public MAX_PUBLIC_TX=10;
    uint32 public PUBLIC_START = 1682784211;
    uint32 public PUBLIC_END = 	1719029506;
    uint64 public PUBLIC_MINT_PRICE= 0.0015 ether;
    uint256 public MAX_SUPPLY = 10000;
    string public baseURI;
    mapping(address => uint256) private _tokensMinted;
    mapping(address => bool) private _hasMinted;
    function getSalesInfo() public view returns (uint8,uint32,uint32,uint64,uint256){
        return (MAX_PUBLIC_TX,PUBLIC_START,PUBLIC_END,PUBLIC_MINT_PRICE,MAX_SUPPLY);
    }
    function mint_limit_config(uint8 new_public_max) public onlyOwner{
        MAX_PUBLIC_TX=new_public_max;
    }

    function set_public_start(uint32 newTime) public onlyOwner {
        require(!sales_locked,"Sales Locked");
        PUBLIC_START=newTime;
    }
    function set_public_end(uint32 newTime) public onlyOwner {
        require(!sales_locked,"Sales Locked");
        PUBLIC_END=newTime;
    }
    function set_public_price(uint64 newPrice) public onlyOwner {
        PUBLIC_MINT_PRICE=newPrice;
    }
    function set_base_uri(string calldata newURI) public onlyOwner{
        baseURI=newURI;
    }
    function lockSales() public onlyOwner {
        sales_locked=true;
    }
    function reduce_supply(uint256 newsupply) public onlyOwner{
        require(newsupply<MAX_SUPPLY,"Can't increase supply");
        MAX_SUPPLY=newsupply;
    }
    modifier supplyAvailable(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY,"Sold Out");
        _;
    }


   function team_mint(uint256 quantity,address addr) public payable onlyOwner supplyAvailable(quantity)
    {
        require(!sales_locked,"Sales Locked");
        _mint(addr, quantity);
    }


    function public_mint(uint256 quantity) public payable supplyAvailable(quantity)
    {   
        require(msg.value == PUBLIC_MINT_PRICE*quantity, "Invalid funds");
        require(block.timestamp >= PUBLIC_START && block.timestamp <= PUBLIC_END, "Not in public mint phase");
        require(quantity > 0 && quantity<=MAX_PUBLIC_TX, "Invalid quantity");
        _hasMinted[msg.sender]=true;
        _mint(msg.sender, quantity);

    }
    function setNewOwner(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    // BASE URI
    function _baseURI() internal view override(ERC721A)
        returns (string memory)
    {
        return baseURI;
    }

// operation filter override functions
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    //royaltyInfo
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}