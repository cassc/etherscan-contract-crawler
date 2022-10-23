// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                          
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@paperxyz/contracts/keyManager/IPaperKeyManager.sol";
import "hardhat/console.sol";

contract SAWGamesPass is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;
    IPaperKeyManager paperKeyManager;

    bool public transfersLocked = false;
    bool public saleOpen = true;
    bool public allowlistOpen = true;

    uint256 public macMints = 0;
    uint256 public gametokenMints = 0;
    uint256 public allowlistMints = 0;
    uint256 public publicMints = 0;

    uint256 public mintPrice = 0.04 ether;

    string private _tokenBaseURI = "https://meta.internet.game/saw/ig/";
    address private _signerAddress = 0xa2aE2a63306f9410b341b82789A119f80a8f25f3;

    mapping(string => bool) private _usedNonces;
    
    constructor(address _paperKeyManagerAddress) ERC721A("SAW Games Pass", "SAW_GAMES") {
        paperKeyManager = IPaperKeyManager(_paperKeyManagerAddress);
    }

    function registerPaperKey(address _paperKey) external onlyOwner {
        require(paperKeyManager.register(_paperKey), "Error registering key");
    }

    function hashTransaction(address sender, string memory nonce, string memory list, uint256 maxQuantity, uint256 price) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encode(sender, nonce, list, maxQuantity, price)))
      ); 
      return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }

    modifier onlyPaper(bytes32 _hash, bytes32 _nonce, bytes calldata _signature) {
        bool success = paperKeyManager.verify(_hash, _nonce, _signature);
        require(success, "Failed to verify signature");
        _;
    }

    // Method called by front-end to determine if allowlist spot has already been used
    function canMint(string memory nonce) public view returns(bool) {
        require(!_usedNonces[nonce], "Already minted");
        return true;
    }

    // Paper eligibilityMethod for fiat minting w/o discount code
    function fiatCanMint() public view returns(string memory) {
        require(saleOpen, "Public sale not open");
        return '';
    }

    // Paper eligibilityMethod for fiat minting w/ discount code
    function fiatAllowlistCanMint(string memory nonce) public view returns(string memory) {
        require(allowlistOpen, "Private sale not open");
        require(!_usedNonces[nonce], "Already minted");
        return '';
    }

    // Paper mint method for minting w/o discount code
    function fiatMint(address addr, uint256 quantity, bytes32 _nonce, bytes calldata _signature) external payable onlyPaper(keccak256(abi.encode(addr, quantity)), _nonce, _signature) {
        publicMints += quantity;
        _safeMint(addr, quantity);
    }

    // Paper mint method for minting w/ discount code
    function fiatAllowlistMint(address addr, uint256 quantity, string memory nonce, bytes32 _nonce, bytes calldata _signature) external payable onlyPaper(keccak256(abi.encode(addr, quantity, nonce)), _nonce, _signature) {
        _usedNonces[nonce] = true;
        allowlistMints += quantity;
        _safeMint(addr, quantity);
    }

    // Mint method for ETH minting w/o allowlist
    function mint(uint256 quantity) external payable {
        require(saleOpen, "Public sale not open");
        require(mintPrice * quantity <= msg.value, "ETH value sent is not enough");
        publicMints += quantity;
        _safeMint(msg.sender, quantity);
    }

    // Mint method for ETH w/ allowlist
    function allowlistMint(bytes32 hash, bytes memory signature, string memory nonce, string memory list, uint256 maxQuantity, uint256 quantity, uint256 price) external payable {
        require(allowlistOpen, "Private sale not open");
        require(matchAddresSigner(hash, signature), "Not the correct signer");
        require(hashTransaction(msg.sender, nonce, list, maxQuantity, price) == hash, "Incorrect hash");
        require(quantity <= maxQuantity, "That's more mints than you are allowed");
        require(!_usedNonces[nonce], "You already minted.");
        require(price * quantity <= msg.value, "ETH value sent is not enough");
        
        _usedNonces[nonce] = true;

        if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked("gametoken"))) gametokenMints += quantity;
        else if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked("mac"))) macMints += quantity;
        else if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked("allowlist"))) allowlistMints += quantity;

        _safeMint(msg.sender, quantity);
    }

    function adminMint(address addr, uint quantity) external onlyOwner {
        _safeMint(addr, quantity);
    }
    
    function toggleTransfers() external onlyOwner {
        transfersLocked = !transfersLocked;
    }

    function toggleSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function toggleAllowlist() external onlyOwner {
        allowlistOpen = !allowlistOpen;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function setMintPrice(uint price) external onlyOwner {
        mintPrice = price;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!transfersLocked, "Sales & transfers are locked during games");
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}