// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBNVGoggle.sol";

/// @title BNV Goggle Contract
/// @author BNV Team
/// @dev based on a standard ERC1155
contract BNVGoggle is ERC1155, ERC1155Supply, IBNVGoggle, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // tokenIds
    EnumerableSet.UintSet private _tokenIds;

    // Whitelist
    EnumerableSet.AddressSet private _whitelists;

    /**
     * @dev Throws if called by any account other than the owner or WL address.
     */
    modifier onlyOwnerOrWhitelisted() {
        require(
            owner() == _msgSender() || _whitelists.contains(_msgSender()),
            "Caller is not the owner or whitelisted address"
        );
        _;
    }

    /// @notice Initializes the contract
    constructor() ERC1155("") {}

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

    function setURI(string memory newURI) external onlyOwner {
        super._setURI(newURI);
    }

    /// @notice Mint erc1155 function
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override onlyOwnerOrWhitelisted {
        super._mint(to, tokenId, amount, "");
    }

    /// @notice Mint multiple
    function mintMultiple(
        address[] memory tos,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyOwnerOrWhitelisted {
        require(
            tos.length == tokenIds.length && tokenIds.length == amounts.length,
            "Length is not the same"
        );
        for (uint256 i = 0; i < tos.length; i++) {
            super._mint(tos[i], tokenIds[i], amounts[i], "");
        }
    }

    /// @notice Mint batch erc1155 function
    function mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external override onlyOwnerOrWhitelisted {
        super._mintBatch(to, tokenIds, amounts, "");
    }

    /// @notice burn function
    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(
            owner() == _msgSender() ||
                _whitelists.contains(_msgSender()) ||
                from == _msgSender(),
            "No permission to burn"
        );
        super._burn(from, tokenId, amount);
    }

    /// @notice burn batch function
    function burnBatch(
        address from,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external {
        require(
            owner() == _msgSender() ||
                _whitelists.contains(_msgSender()) ||
                from == _msgSender(),
            "No permission to burn"
        );
        super._burnBatch(from, tokenIds, amounts);
    }

    // VIEW ONLY =======================================

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(id), Strings.toString(id)));
    }

    // ADMIN =======================================

    /// @notice get white list
    function getWhitelist() external view onlyOwner returns (address[] memory) {
        address[] memory arr = new address[](_whitelists.length());
        for (uint256 i = 0; i < _whitelists.length(); i++) {
            arr[i] = _whitelists.at(i);
        }
        return arr;
    }

    /// @notice add whitelist
    function _addToWhitelist(address newAddress) external onlyOwner {
        _whitelists.add(newAddress);
    }

    /// @notice remove from whitelist
    function _removeFromWhitelist(address existingAddress) external onlyOwner {
        _whitelists.remove(existingAddress);
    }
}