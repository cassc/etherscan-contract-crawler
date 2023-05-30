// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract HanzGenesis is ERC721, Ownable, DefaultOperatorFilterer {

    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    string private baseURI = "ipfs://bafybeihinztrxr63qpmanjh3o362re46enadugjv3drsx2o6wkc55wysde/";
    uint256 public maxSupply = 99;
    bool public isPublicEnabled = false;
    bool public isWlEnabled = false;
    uint256 public price = 0.5 ether;

    using ECDSA for bytes32;
    address public signerAddress;

    mapping(uint64 => bool) public haveAlreadyMinted;

    constructor() ERC721("Hanz Genesis", "HANZ") {}

    function setBaseUri(string memory newUri) external onlyOwner {
        baseURI = newUri;
    }

    // Public Mint
    function mint() external payable {
        require(isPublicEnabled, "The sale is not enabled.");
        require(maxSupply >= (tokenIds.current() + 1), "Exceeds max supply.");
        require(msg.value >= price, "Insufficient funds.");

        mintOne(msg.sender);
    }

    // Whitelist Mint
    function whitelistMint(uint64 userId, bytes calldata signature) external payable {
        require(isWlEnabled, "The sale is not enabled.");
        require(maxSupply >= (tokenIds.current() + 1), "Exceeds max supply.");
        require(msg.value >= price, "Insufficient funds.");
        
        require(verifySignature(signature, userId), "Invalid signature.");
        require(!haveAlreadyMinted[userId], "You already minted.");
        haveAlreadyMinted[userId] = true;

        mintOne(msg.sender);
    }

    // Airdrop
    function airdrop(address[] calldata addresses) external onlyOwner {
        for (uint16 i = 0; i < addresses.length; i++) {
            mintOne(addresses[i]);
        }
    }

    // Toggle Public Mint
    function togglePublicMint() external onlyOwner {
        isPublicEnabled = !isPublicEnabled;
    }

    // Toggle Whitelist Mint
    function toggleWhitelistMint() external onlyOwner {
        isWlEnabled = !isWlEnabled;
    }

    // Set signer address
    function setSignerAddress(address newSignerAddress) external onlyOwner {
        signerAddress = newSignerAddress;
    }

    // Set max supply
    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    // Set mint price
    function setMintPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    // Withdraw balance
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Get token metadata URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Invalid token ID");
 
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json"))
            : "";
    }

    //////////

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mintOne(address receiver) private {
        tokenIds.increment();
        uint256 newTokenID = tokenIds.current();
        _safeMint(receiver, newTokenID);
    }

    function verifySignature(bytes memory signature, uint64 userId) internal view returns (bool) {
        return signerAddress ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(abi.encodePacked(msg.sender, userId))
                )
            ).recover(signature);
    }

    //////////

    /* Opensea stuff */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}