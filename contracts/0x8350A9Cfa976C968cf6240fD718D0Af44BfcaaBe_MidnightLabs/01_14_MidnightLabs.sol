// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/***
 *               _     _       _       _     _     _       _         
 *              (_)   | |     (_)     | |   | |   | |     | |        
 *     _ __ ___  _  __| |_ __  _  __ _| |__ | |_  | | __ _| |__  ___ 
 *    | '_ ` _ \| |/ _` | '_ \| |/ _` | '_ \| __| | |/ _` | '_ \/ __|
 *    | | | | | | | (_| | | | | | (_| | | | | |_  | | (_| | |_) \__ \
 *    |_| |_| |_|_|\__,_|_| |_|_|\__, |_| |_|\__| |_|\__,_|_.__/|___/
 *                                __/ |                              
 *                               |___/                               
 */


import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MidnightLabs is ERC1155Supply, Ownable, Pausable {
    using ECDSA for bytes32;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    uint256 public constant TOKEN_ID = 1;
    uint256 public constant MAX_TOKENS = 2000;

    // Used to validate authorized mint addresses
    address private signerAddress = 0xabcB40408a94E94f563d64ded69A75a3098cBf59;

    // Used to ensure each new token id can only be minted once by the owner
    mapping (uint256 => bool) public collectionMinted;
    mapping (uint256 => string) public tokenURI;
    mapping (address => bool) public hasAddressMinted;

    constructor(
        string memory uriBase,
        string memory _name,
        string memory _symbol
    ) ERC1155(uriBase) {
        name = _name;
        symbol = _symbol;
        tokenURI[TOKEN_ID] = uriBase;
    }

    /**
     * Returns the custom URI for each token id. Overrides the default ERC-1155 single URI.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        if (bytes(tokenURI[tokenId]).length == 0) {
            return super.uri(tokenId);
        }
        return tokenURI[tokenId];
    }

    /**
     * Sets a URI for a specific token id.
     */
    function setURI(string memory newTokenURI, uint256 tokenId) public onlyOwner {
        tokenURI[tokenId] = newTokenURI;
    }

    /**
     * Set the global default ERC-1155 base URI to be used for any tokens without unique URIs
     */
    function setGlobalURI(string memory newTokenURI) public onlyOwner {
        _setURI(newTokenURI);
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender));
    }

    /**
     * @notice Allow minting of a single token by whitelisted addresses only
     */
    function mint(bytes32 messageHash, bytes calldata signature) external {
        require(totalSupply(TOKEN_ID) < MAX_TOKENS, "MAX_TOKEN_SUPPLY_REACHED");
        require(hasAddressMinted[msg.sender] == false, "ADDRESS_HAS_ALREADY_MINTED_TOKEN");
        require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
        require(verifyAddressSigner(messageHash, signature), "SIGNATURE_VALIDATION_FAILED");

        hasAddressMinted[msg.sender] = true;

        _mint(msg.sender, TOKEN_ID, 1, "");

    }

    /**
     * @notice Allow minting of any future tokens as desired as part of the same collection,
     * which can then be transferred to another contract for distribution purposes
     */
    function adminMint(address account, uint256 id, uint256 amount) public onlyOwner
    {
        require(!collectionMinted[id], "CANNOT_MINT_EXISTING_TOKEN_ID");
        require(id != TOKEN_ID, "CANNOT_MINT_EXISTING_TOKEN_ID");
        collectionMinted[id] = true;
        _mint(account, id, amount, "");
    }

    /**
     * @notice Allow owner to send `mintNumber` tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256 numberOfTokens) external onlyOwner {
        require((totalSupply(TOKEN_ID) + (receivers.length * numberOfTokens)) <= MAX_TOKENS, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], TOKEN_ID, numberOfTokens, "");
        }
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed to prevent arbitrary creation of new tokens in the collection.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice When the contract is paused, all token transfers are prevented in case of emergency.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "BALANCE_IS_ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }
}