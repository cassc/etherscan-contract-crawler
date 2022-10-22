// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error AddressZeroIsNotAValidOwner();
error BurnAmountExceedsBalance();
error CannotBurnFromTheZeroAddress();
error CannotMintToTheZeroAddress();
error CannotSetApprovalStatusForSelf();
error IdDoesNotExist();
error InputArrayLengthMismatch();
error InvalidMetadataFormatterContract();
error NoMetadataFormatterFoundForSpecifiedId();
error SoulboundTokensAreLockedAndMayNotBeTransferred();

/**
 * @title SoulboundERC1155
 * @author Limit Break, Inc.
 * @notice Base contract for fungible ERC-1155 multi-tokens that are soulbound, yet burnable.
 */
abstract contract SoulboundERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {

    /// @dev Mapping from token ID to account balances
    mapping (uint256 => mapping (address => uint256)) private _balances;

    /// @dev Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    /// @notice Approves an operator to burn, but not transfer tokens, as these are soulbound and non-transferrable
    function setApprovalForAll(address operator, bool approved) external virtual override {
        if(_msgSender() == operator) {
            revert CannotSetApprovalStatusForSelf();
        }

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Always throws - these tokens are soulbound and non-transferrable but this function is required for ERC-1155 spec compliance
    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*id*/, uint256 /*amount*/, bytes memory /*data*/) external override pure {
        revert SoulboundTokensAreLockedAndMayNotBeTransferred();
    }

    /// @notice Always throws - these tokens are soulbound and non-transferrable but this function is required for ERC-1155 spec compliance
    function safeBatchTransferFrom(address /*from*/, address /*to*/, uint256[] memory /*ids*/, uint256[] memory /*amounts*/, bytes memory /*data*/) external override pure {
        revert SoulboundTokensAreLockedAndMayNotBeTransferred();
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns the balance of the specified account for the specified token ID
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if(account == address(0)) {
            revert AddressZeroIsNotAValidOwner();
        }
        
        return _balances[id][account];
    }

    /// @notice Returns the balance of the specified accounts for the specified token IDs
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) public view virtual override returns (uint256[] memory) {
        _requireInputArrayLengthsMatch(accounts.length, ids.length);

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i = 0; i < accounts.length; ++i) {
                batchBalances[i] = balanceOf(accounts[i], ids[i]);
            }
        }

        return batchBalances;
    }

    /// @notice Returns true if the specified operator has been approved by the specified account to burn tokens
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /// @dev Not implemented - inheriting contracts must implement the uri scheme that is appropriate for their usage.
    function uri(uint256 id) public virtual view override returns (string memory);

    /// @dev Mints `amount` tokens of the specified `id` to the `to` address.
    /// Throws if attempting to mint to the zero address.
    function _mint(address to, uint256 id, uint256 amount) internal virtual {
        if(to == address(0)) {
            revert CannotMintToTheZeroAddress();
        }

        _balances[id][to] += amount;
        
        emit TransferSingle(_msgSender(), address(0), to, id, amount);
    }

    /// @dev Mints a batch of `amount` tokens of the specified `ids` to the `to` address.
    /// Throws if attempting to mint to the zero address.
    /// Throws if the ids and amounts arrays don't have the same size.
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        if(to == address(0)) {
            revert CannotMintToTheZeroAddress();
        }
        
        _requireInputArrayLengthsMatch(ids.length, amounts.length);

        for (uint256 i = 0; i < ids.length;) {
            _balances[ids[i]][to] += amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(_msgSender(), address(0), to, ids, amounts);
    }

    /// @dev Burns `amount` tokens of the specified `id` from the `from` address.
    /// Throws if attempting to burn from the zero address.
    /// Throws if the amount exceeds the available balance.
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        if(from == address(0)) {
            revert CannotBurnFromTheZeroAddress();
        }

        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        if(amount > fromBalance) {
            revert BurnAmountExceedsBalance();
        }

        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /// @dev Burns a batch of `amount` tokens of the specified `ids` from the `from` address.
    /// Throws if attempting to burn from the zero address.
    /// Throws if the ids and amounts arrays don't have the same size.
    /// Throws if any amount exceeds the available balance.
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        if(from == address(0)) {
            revert CannotBurnFromTheZeroAddress();
        }
        
        _requireInputArrayLengthsMatch(ids.length, amounts.length);

        address operator = _msgSender();

        uint256 id;
        uint256 amount;
        for (uint256 i = 0; i < ids.length;) {
            id = ids[i];
            amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if(amount > fromBalance) {
                revert BurnAmountExceedsBalance();
            }

            unchecked {
                _balances[id][from] = fromBalance - amount;
                ++i;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /// @dev Validates that the length of two input arrays matched.
    /// Throws if the array lengths are mismatched.
    function _requireInputArrayLengthsMatch(uint256 inputArray1Length, uint256 inputArray2Length) internal pure {
        if(inputArray1Length != inputArray2Length) {
            revert InputArrayLengthMismatch();
        }
    }
}