// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChopParty is ERC721A, Ownable, ReentrancyGuard
{
    using Strings for string;

    /// @notice Price per token minted duing main sale (public)
    uint256 public PRICE = 0.25 ether;

    /// @notice Absolute maximum number of tokens that can be minted (both for VIP & public).
    uint public constant MAX_TOKENS = 333; 

    /// @notice Maximum number of reserved tokens that can be minted
    uint public constant NUMBER_RESERVED_TOKENS = 5;

    /// @notice maximum number of tokens that can be minted per wallet
    uint public perAddressLimit = 2; 

    /// @notice mainsale phase (public) of the contract
    bool public mainSale = false; 

    /// @notice URI reveal set to false by default
    bool public revealed = false;

    /// @notice Number of reserved tokens that have been minted
    uint public reservedTokensMinted = 0;

    /// @notice Number of pledge tokens that have been minted
    uint public vipTokensMinted = 0;

    string private _baseTokenURI; 
    string public notRevealedUri; 
    mapping(address => uint) public addressMintedBalance;

    /// @notice pledgemint.io contract address
    address public pledgeContractAddress = address(0);

    constructor() ERC721A("ChopParty", "CHOP") {}

    /// @notice Mint function for public sale
    /// @param quantity Quantity to mint
    function mintToken(uint256 quantity) public payable
    {
        require (mainSale, "Sale not open");

        require(totalSupply() + quantity <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(addressMintedBalance[msg.sender] + quantity <= perAddressLimit, "Max NFT per address exceeded");

        require(msg.value >= PRICE * quantity, "Not enough ETH for transaction");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");

        addressMintedBalance[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /// @notice Mint function for pledgemint.io integration
    /// @param to The address to mint the tokens to
    /// @param quantity The number of tokens to mint
    function pledgeMint(address to, uint8 quantity)
        external
        payable 
        nonReentrant
    {
        require(
            msg.sender == pledgeContractAddress || msg.sender == owner(),
            "Only pledgemint or owner can call this function"
        );
        require(totalSupply() + quantity <= MAX_TOKENS, "Purchase would exceed max supply");
        require(
            addressMintedBalance[to] + quantity <= perAddressLimit,
            "Max NFT per address exceeded"
        );

        vipTokensMinted += quantity;
        addressMintedBalance[to] += quantity;
        _mint(to, quantity);
    }

    /// @notice This function sets the pledgemint contract address
    /// @param contractAddress The new pledgemint contract address
    function setPledgeContractAddress(address contractAddress)
        public
        onlyOwner
    {
        pledgeContractAddress = contractAddress;
    }

    function setPrice(uint256 newPrice) external onlyOwner
    {
        PRICE = newPrice;
    }

    function setPerAddressLimit(uint newLimit) external onlyOwner 
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipMainSale() external onlyOwner
    {
        mainSale = !mainSale;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner 
    {
        require(totalSupply() + amount <= MAX_TOKENS, "Exceeds max supply");
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted += amount;
        addressMintedBalance[to] += amount;
        _mint(to, amount);
    }

    function withdraw() external nonReentrant
    {
        require(msg.sender == owner(), "Invalid sender");
        (bool success, ) = owner().call{value: address(this).balance}(""); 
        require(success, "Transfer failed");
    }

    // URI management
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false)
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    function getPrice() public view returns (uint256) {
      return PRICE;
    }

    function getSaleState() public view returns (bool) {
      return mainSale;
    }

    function getPerAddressLimit() public view returns (uint256) {
      return perAddressLimit;
    }
}