// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SOW is
    ERC721A,
    Ownable,
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    bool public mintStarted = false;
    bool public isRevealed =false;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_WALLET = 50;
    uint256 public maxFreeMintsPerWallet = 1;
    uint256 public mintPrice = 0.005 ether;
    uint256 public maxTrxPerWallet = 10;
    string public preRevealURI;
    mapping(address => uint256) public alreadyFreeMinted;
    string public baseURI;

   constructor(string memory _preRevealURI) ERC721A("SOW NFT", "SOW") { 
        preRevealURI = _preRevealURI;
    }

    // Token URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
    if (!isRevealed){return preRevealURI;}
        return super.tokenURI(tokenId);
    }
    
    function setpreRevealURI(string memory _newPreRevealURI) external onlyOwner {
        preRevealURI = _newPreRevealURI;
    }

    function setpreRevealStatus(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /// @notice Sets the price
    /// @param _mintPrice New price
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /// @notice Sets the base metadata URI
    /// @param _uri The new URI
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 quantity) external payable {
        require(mintStarted, "Mint has not started yet!");
        require(quantity<=maxTrxPerWallet,"You exceeded the max trx per mint");
        require(_totalMinted() + quantity <= MAX_SUPPLY,"I'm sorry we reached the cap!");
        require(balanceOf(msg.sender) <= MAX_PER_WALLET,"Max Mint per wallet reached");
        uint256 payForMintCount = quantity;
        uint256 claimedMints = alreadyFreeMinted[_msgSender()];
        uint256 walletRemainingFreeMints = (maxFreeMintsPerWallet- claimedMints);
       
        if ( quantity <= walletRemainingFreeMints){
            payForMintCount =0;
        } 
        else
        {
            payForMintCount = quantity - walletRemainingFreeMints;
        }
        require(msg.value >= (payForMintCount * mintPrice),"Ether value sent is not sufficient");
        
         alreadyFreeMinted[_msgSender()] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address to, uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY,"Will exceed maximum supply");
        _safeMint(to, quantity);
    }

    function setMintingStatus(bool _mintStarted) external onlyOwner {
        mintStarted = _mintStarted;
    }

    function setMaxFreeMintsPerWallet(uint256 _maxFreeMintsPerWallet) external onlyOwner {
        maxFreeMintsPerWallet = _maxFreeMintsPerWallet;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from,address to,uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from,address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from,address to,uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdraw(address payable payee) public onlyOwner nonReentrant {
        payable(payee).transfer(address(this).balance);
    }
}