// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./SignatureVerifier.sol";

/// @custom:security-contact [email protected]
contract Achievements is ERC1155, Ownable, ERC1155Supply, SignatureVerifier {
    mapping(address => uint256) public nonces;

    constructor(address signer)
        ERC1155("https://achievements.supremacy.game/api/metadata/{id}.json")
        SignatureVerifier(signer)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function signedMint(uint256 tokenID, bytes calldata signature) public {
        bytes32 messageHash = getMessageHash(
            msg.sender,
            tokenID,
            nonces[msg.sender]++
        );

        require(verify(messageHash, signature), "Invalid Signature");
        _mint(msg.sender, tokenID, 1, bytes(""));
    }

    function getMessageHash(
        address account,
        uint256 tokenID,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(account, tokenID, nonce));
    }
}