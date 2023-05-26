// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ERC1155 } from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import { Pausable } from '@openzeppelin/contracts/security/Pausable.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { SignatureChecker } from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

contract BookNFT is DefaultOperatorFilterer, ERC1155, Ownable, Pausable, ReentrancyGuard { 
    using ECDSA for bytes32;
    address public ecdsaSigner;

    mapping (string => bool) public usedBookCodes;
  
    constructor(address ecdsaSigner_, string memory uri_) ERC1155(uri_) {
        ecdsaSigner = ecdsaSigner_;
    }

    function bookCodeMint(string calldata bookCode, bytes calldata signature) external whenNotPaused nonReentrant {
        bytes32 signedHash = keccak256(abi.encodePacked(msg.sender, bookCode)).toEthSignedMessageHash();
        require(SignatureChecker.isValidSignatureNow(ecdsaSigner, signedHash, signature), "Invalid book code");

        require(!usedBookCodes[bookCode], "An NFT has already been claimed with this code.");

        _mint(msg.sender, 1, 1, "");

        usedBookCodes[bookCode] = true;
    }

    function withdraw(address toAddress) external onlyOwner nonReentrant {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = toAddress.call{value: address(this).balance}("");

        require(sent, "Failed to send Ether");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string.concat(super.uri(tokenId), Strings.toString(tokenId));
    }

    function setURI(string memory newUri) external onlyOwner {
        _setURI(newUri);
    }

    function symbol() public pure returns (string memory) {
        return "WEB3MKT";
    }   

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    receive() external payable {}
}