// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GentsCroquetClub is ERC721A, Ownable, ReentrancyGuard
{
    using Strings for string;

    address erc20Contract = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC ethereum mainnet
    uint256 public PRICE = 4500 * 10 ** 6; // 4500 USDC (mainnet value)

    // address erc20Contract = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; 
    // uint256 public PRICE = 1 * 10 ** 4; // 0.01 USDC (testnet value)

    uint public constant MAX_TOKENS = 975; 
    uint public constant NUMBER_RESERVED_TOKENS = 250; 
    uint public mainSaleLimit = 1; 
    uint public overflowSaleLimit = 1; 

    bool public mainSale = false; 
    bool public overflowSale = false; 
    bool public revealed = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI; 
    string public notRevealedUri; 
    mapping(address => uint) public addressMintedBalance;

    // these are test values which should be replaced on deploy
    bytes32 private _mainSaleRoot = 0xfbaa96a1f7806c1ab06f957c8fc6e60875b6880254f77b71439c7854a6b47755;
    bytes32 private _overflowSaleRoot = 0xebe9d4919dc853d1f14f189ec5b94af4fd297f7b8a9e2afa9e83f1e8735b1b58;

    address payable private devguy = payable(0x7ea9114092eC4379FFdf51bA6B72C71265F33e96); // Payment Splitter (MORE DETAILS ON THE PAYMENT SPLITTER PROVIDED BELOW)

    constructor() ERC721A("GentsCroquetClub", "GCC") {}

    function mintToken(uint256 amount, bytes32[] memory proof) public
    {
        require (mainSale || overflowSale, "Sale not open");
        bool mainSaleVerified = verifyMainSaleWhitelist(proof);

        require(!mainSale || mainSaleVerified, "Address not whitelisted for wl-main sale");

        bool withinWl1Limit = mainSaleVerified && addressMintedBalance[msg.sender] + amount <= mainSaleLimit && amount == mainSaleLimit;
        require(!mainSale || withinWl1Limit, "Exceeds wl-main mint limit");

        bool overflowSaleVerified = verifyOverflowWhitelist(proof);

        require(!overflowSale || overflowSaleVerified, "Address not whitelisted for wl-overflow sale");
        require(!overflowSale || (overflowSaleVerified && addressMintedBalance[msg.sender] + amount <= overflowSaleLimit && amount == overflowSaleLimit), "Exceeds wl-overflow mint limit"); // check whitelist 3 limit

        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");

        uint256 totalPrice = amount * PRICE;

        IERC20 tokenContract = IERC20(erc20Contract);

        bool transferred = tokenContract.transferFrom(msg.sender, address(this), totalPrice);
        require(transferred, "ERC20 tokens failed to transfer");

        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    // change price - USDC per token (remember USDC contracts only have 6 decimal places)
    function setPrice(uint256 newPrice) external onlyOwner
    {
        PRICE = newPrice;
    }

    function setMainSaleLimit(uint newLimit) external onlyOwner { mainSaleLimit = newLimit; }
    function setOverflowSaleLimit(uint newLimit) external onlyOwner { overflowSaleLimit = newLimit; }

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

    function flipOverflow() external onlyOwner
    {
        overflowSale = !overflowSale;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted += amount;
        _safeMint(to, amount);
    }

    function withdraw() external nonReentrant
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");
        (bool success, ) = devguy.call{value: address(this).balance / 100 * 2}(""); 
        (bool success2, ) = owner().call{value: address(this).balance}(""); 
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
    }

    function withdrawERC20() external nonReentrant
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");
        IERC20 tokenContract = IERC20(erc20Contract);

        uint256 totalBalance = tokenContract.balanceOf(address(this));
        uint256 devguySplit = totalBalance / 100 * 2; // set split
        uint256 ownerSplit = totalBalance - devguySplit;

        bool devguyTransfer = tokenContract.transfer(devguy, devguySplit);
        bool ownerTransfer = tokenContract.transfer(owner(), ownerSplit);

        require(devguyTransfer, "Transfer 1 failed");
        require(ownerTransfer, "Transfer 2 failed");
    }

    // whitelists and merkle verification

    function setMainSaleRoot(bytes32 root) external onlyOwner { _mainSaleRoot = root; }
    function setOverflowSaleRoot(bytes32 root) external onlyOwner { _overflowSaleRoot = root; }

    function verifyMainSaleWhitelist(bytes32[] memory proof) internal view returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, _mainSaleRoot, leaf);
    }

    function verifyOverflowWhitelist(bytes32[] memory proof) internal view returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, _overflowSaleRoot, leaf);
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
}