// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./utils/ContractMetadata.sol";
import "./utils/Royalty.sol";
import "./utils/OwnableAdmin.sol";


contract ERC721Base is ERC721A, OwnableAdmin, PaymentSplitter, Royalty, ContractMetadata {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address[] memory payees,
        uint256[] memory shares_
    ) ERC721A(_tokenName, _tokenSymbol) PaymentSplitter(payees, shares_) { }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner() || msg.sender == admin();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner() || msg.sender == admin();
    }

    /// @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }
}