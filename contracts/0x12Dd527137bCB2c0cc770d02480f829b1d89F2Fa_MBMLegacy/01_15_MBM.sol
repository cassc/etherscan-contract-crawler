// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MBMLegacy is ERC721, ERC721Burnable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    string private baseURI = "ipfs://bafybeiax5i3jxbd36j3q2ktedt3zjfzd2sys2h74l7sovr7lxpljg4sfqu/";
    uint256 public maxSupply = 300;
    bool public isMintEnabled = false;

    using ECDSA for bytes32;
    address public signerAddress = 0xb8174814d933A8f2E0aD50Fe6953b5aF7fC5fD14;

    mapping(uint64 => bool) public haveAlreadyMinted;

    constructor() ERC721("MBM Legacy", "MBML") {}

    function setBaseUri(string memory newUri) external onlyOwner {
        baseURI = newUri;
    }

    // Mint
    function mint(uint64 userId, bytes calldata signature) external payable {
        require(isMintEnabled, "The sale is not enabled.");
        require(maxSupply >= (tokenIds.current() + 1), "Exceeds max supply.");
        
        require(verifySignature(signature, userId), "Invalid signature.");
        require(!haveAlreadyMinted[userId], "You have already minted.");
        haveAlreadyMinted[userId] = true;

        mintOne(msg.sender);
    }

    // Airdrop
    function airdrop(address[] calldata addresses) external onlyOwner {
        for (uint16 i = 0; i < addresses.length; i++) {
            mintOne(addresses[i]);
        }
    }

    // Toggle Mint
    function toggleMint() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    // Set signer address
    function setSignerAddress(address newSignerAddress) external onlyOwner {
        signerAddress = newSignerAddress;
    }

    // Set max supply
    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
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

    // Burn
    function burn(uint256 tokenId) public override onlyOwner {
        _burn(tokenId);
    }

    /* No Transfers */

    function setApprovalForAll(address operator, bool approved) public override {
        revert("No Transfers!");
    }

    function approve(address operator, uint256 tokenId) public override {
        revert("No Transfers!");
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        revert("No Transfers!");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        revert("No Transfers!");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        revert("No Transfers!");
    }
}