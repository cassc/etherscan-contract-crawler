// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../KContract.sol";

import "./ERC721Describable.sol";
import "./ERC721Details.sol";
import "./IKEIERC721.sol";

abstract contract KEIERC721 is IKEIERC721, KContract, ERC721Describable, ERC721Details {

    uint256 private $totalSupply;

    constructor() {
        _updateSellerFee(300);
    }

    function totalSupply() external virtual override view returns (uint256) {
        return $totalSupply;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721Describable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Details, ERC721Describable, KContract) returns (bool) {
        return interfaceId == type(IKEIERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function updateSellerFee(uint256 newSellerFee) external override onlyRole(MANAGE_ROLE) {
        _updateSellerFee(newSellerFee);
    }

    function updateDetails(IERC721Details.ContractDetails calldata newContractDetails) external override onlyRole(MANAGE_ROLE) {
        _updateDetails(newContractDetails);
    }

    function updateDescriptor(address newDescriptor) external override onlyRole(MANAGE_ROLE) {
        _updateDescriptor(newDescriptor);
    }

    function updateFeeReceiver(address newFeeReceiver) external override onlyRole(MANAGE_ROLE) {
        _updateFeeReceiver(newFeeReceiver);
    }

    function _mint(address to, uint256 tokenId) internal override virtual {
        super._mint(to, tokenId);
        unchecked {
            ++$totalSupply;
        }
    }

    function _burn(uint256 tokenId) internal override virtual {
        super._burn(tokenId);
        unchecked {
            --$totalSupply;
        }
    }
}