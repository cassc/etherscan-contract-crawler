// SPDX-License-Identifier: MIT
///  #######   #    #  #####   #######  ####    #####  #######
///     #      #    #  #   #      #     #   #   #   #     # 
///     #      ######  #   #      #     # ##    #   #     #
///     #      #    #  #   #      #     #   #   #   #     #
///     #      #    #  #####      #     ####    #####     #

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ThotBots is ERC721A, ERC2981, Ownable,DefaultOperatorFilterer,ReentrancyGuard {
    string public baseURI="";
    string public tokenSuffix=".json";
    string public unrevealedURI="ipfs://bafkreiaen6xx3yr2ekchg56j54qyywuffc2ycqlt5sqot4ayu4oga6h6ce";
    bool public isRevealed = false;
    uint256 public MAX_MINT_PUBLIC = 2;
    uint256 public constant maxTokens = 222;
    uint256 public mintPhase=0;
    address public payoutAddress=0x3eCb5Cc0bbB1061662e3836Dc534b69490C01731;
    mapping(address => uint256) public publicMintedCount;  

    /**
     * @inheritdoc ERC721A
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId);
    }

    //constructor
    constructor() ERC721A("ThotBots", "THOTBOT") {
       setRoyalties(payoutAddress,750);
    }


    function publicMint(uint256 numberOfTokens) external payable nonReentrant{
        require(mintPhase==2,"Public Mint is not available");
        require(msg.sender == tx.origin, "Direct only");
        require(totalMinted()+numberOfTokens <= maxTokens, "Not enough tokens available to mint");
        require(publicMintedCount[msg.sender]+numberOfTokens <=MAX_MINT_PUBLIC,"Exceeded Public Allocation");
        _basicMint(msg.sender, numberOfTokens);
        publicMintedCount[msg.sender]+= numberOfTokens;
    }

    function adminMintBulk(address to,uint256 numberOfTokens) public onlyOwner {
        require(totalMinted()+numberOfTokens <= maxTokens, "Not enough tokens available to mint");      
        _basicMint(to, numberOfTokens);
    }

    function _basicMint(address to, uint256 q) private {
        _safeMint(to, q);
    }


    function getPublicMintedCountForAddress(address w) external view returns (uint256){
        return publicMintedCount[w];
    }

    function totalMinted() public view returns(uint) {
        return _totalMinted();
    }

    //OWNER Setters
    
    function setMAXPublic(uint256 p) external onlyOwner{
        MAX_MINT_PUBLIC=p;
    }

    function setIsRevealed(bool b) external onlyOwner{
        isRevealed=b;
    }
 
    function setMintPhase(uint256 p) external onlyOwner{
        mintPhase=p;
    }

   
     
    //balance withdrawal functions
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        uint256 payment = amount;
        Address.sendValue(payable(payoutAddress), payment);
    }

    function setPayoutAddress(address s) external onlyOwner {
        payoutAddress=s;
    }

    function payAddress(address to, uint256 amount) external onlyOwner{
        require(amount <= 1 ether, "Over max payment");
        require(address(this).balance >= amount, "Insufficient balance");
        Address.sendValue(payable(to), amount);
    }

    //URI
    function tokenURI (uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
        {
            require(_exists(tokenId), "URIQueryForNonexistentToken");

            if (!isRevealed) {
                return unrevealedURI;
            }

            return string.concat(baseURI, _toString(tokenId),tokenSuffix);
        }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTokenSuffix(string memory suffix) external onlyOwner {
        tokenSuffix = suffix;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }
    
    function _unrevealedURI() internal view virtual returns (string memory) {
        return unrevealedURI;
    }

       
    function setRoyalties(address receiver, uint96 royaltyFraction) public onlyOwner {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    function version() public pure returns (string memory){
        return ".1";
    }
    
   
   
    //OS Overrides
    //OS FILTERER
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
             override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
           override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
          override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}