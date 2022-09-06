// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                          
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract S2Ticket is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    bool public transfersLocked = false;
    bool public saleOpen = false;
    bool public allowlistOpen = true;

    uint256 public macMints = 0;
    uint256 public gametokenMints = 0;
    uint256 public allowlistMints = 0;
    uint256 public publicMints = 0;

    uint256 public constant gametokenPrice = 0.034 ether;
    uint256 public constant allowlistPrice = 0.059 ether;
    uint256 public constant mintPrice = 0.069 ether;

    string private _tokenBaseURI = "https://meta.internet.game/s2/";
    address private _signerAddress = 0xa2aE2a63306f9410b341b82789A119f80a8f25f3;

    mapping(string => bool) private _usedNonces;
    
    constructor() ERC721A("Internet Game S2 Ticket", "INTERNET_GAME_S2_TICKET") {
    }

    function hashTransaction(address sender, string memory nonce, string memory list, uint256 maxQuantity) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encode(sender, nonce, list, maxQuantity)))
      ); 
      return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }

    function canMint(string memory nonce) public view returns(bool) {
        require(!_usedNonces[nonce], "Already minted");
        return true;
    }

    function mint(uint256 quantity) external payable {
        require(saleOpen, "Public sale not open");
        require(mintPrice * quantity <= msg.value, "ETH value sent is not enough");
        publicMints += quantity;
        _safeMint(msg.sender, quantity);
    }

    function allowlistMint(bytes32 hash, bytes memory signature, string memory nonce, string memory list, uint256 maxQuantity, uint256 quantity) external payable {
        uint price = 0;
        if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked('gametoken'))) price = gametokenPrice;
        else if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked('allowlist'))) price = allowlistPrice;

        require(allowlistOpen, "Private sale not open");
        require(matchAddresSigner(hash, signature), "Not the correct signer");
        require(hashTransaction(msg.sender, nonce, list, maxQuantity) == hash, "Incorrect hash");
        require(quantity <= maxQuantity, "That's more mints than you are allowed");
        require(!_usedNonces[nonce], "You already minted.");
        require(price * quantity <= msg.value, "ETH value sent is not enough");
        
        _usedNonces[nonce] = true;

        if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked("gametoken"))) gametokenMints += quantity;
        if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked("mac"))) macMints += quantity;
        if (keccak256(abi.encodePacked(list)) == keccak256(abi.encodePacked("allowlist"))) allowlistMints += quantity;

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