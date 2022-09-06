// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { ERC1155Minter } from "./ERC1155Minter.sol";

contract ES0rigin is Ownable, ERC1155Minter, ERC2981 {
    event RoyaltyInfoUpdated(address receiver, uint96 feeNumerator);

    constructor(string memory uri_) ERC1155Minter("ES0rigin", "ES0", uri_) {}

    /**
     * @notice Sets the royalty information that all ids in this contract will default to
     * See {ERC2981-_setDefaultRoyalty}
     * @param receiver cannot be the zero address
     * @param feeNumerator cannot be greater than the fee denominator
     */
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyInfoUpdated(receiver, feeNumerator);
    }

    /**
     * @notice Sets a new uri for all token types, by relying on the token type id
     * @param newURI metadata uri
     */
    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}