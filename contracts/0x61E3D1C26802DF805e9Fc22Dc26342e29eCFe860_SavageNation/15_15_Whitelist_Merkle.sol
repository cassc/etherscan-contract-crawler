// SPDX-License-Identifier: MIT

/**
 * Author: Lambdalf the White
 * Edit  : Squeebo
 */

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Whitelist_Merkle {
    // Errors
    /**
     * @dev Thrown when trying to query the whitelist while it's not set
     */
    error Whitelist_NOT_SET();
    /**
     * @dev Thrown when `account` has consumed their alloted access and tries to query more
     *
     * @param account : address trying to access the whitelist
     */
    error Whitelist_CONSUMED(address account);
    /**
     * @dev Thrown when `account` does not have enough alloted access to fulfil their query
     *
     * @param account : address trying to access the whitelist
     */
    error Whitelist_FORBIDDEN(address account);

    bytes32 private _root;
    mapping(address => uint256) private _consumed;

    /**
     * @dev Ensures that `account_` has `qty_` alloted access on the whitelist.
     *
     * @param account_ : the address to validate access
     * @param proof_   : the Merkle proof to validate whitelist allocation
     * @param alloted_ : the max amount of whitelist spots allocated
     * @param qty_     : the amount of whitelist access requested
     */
    modifier isWhitelisted(
        address account_,
        bytes32[] memory proof_,
        uint256 alloted_,
        uint256 qty_
    ) {
        if (qty_ > alloted_) {
            revert Whitelist_FORBIDDEN(account_);
        }

        uint256 _allowed_ = checkWhitelistAllowance(account_, proof_, alloted_);

        if (_allowed_ < qty_) {
            revert Whitelist_FORBIDDEN(account_);
        }

        _;
    }

    /**
     * @dev Internal function setting the pass to protect the whitelist.
     *
     * @param root_ : the Merkle root to hold the whitelist
     */
    function _setWhitelist(bytes32 root_) internal virtual {
        _root = root_;
    }

    /**
     * @dev Returns the amount that `account_` is allowed to access from the whitelist.
     *
     * @param account_ : the address to validate access
     * @param proof_   : the Merkle proof to validate whitelist allocation
     *
     * @return uint256 : the total amount of whitelist allocation remaining for `account_`
     *
     * Requirements:
     *
     * - `_root` must be set.
     */
    function checkWhitelistAllowance(
        address account_,
        bytes32[] memory proof_,
        uint256 alloted_
    ) public view returns (uint256) {
        if (_root == 0) {
            revert Whitelist_NOT_SET();
        }

        if (_consumed[account_] >= alloted_) {
            revert Whitelist_CONSUMED(account_);
        }

        if (!_computeProof(account_, proof_)) {
            revert Whitelist_FORBIDDEN(account_);
        }

        uint256 _res_;
        unchecked {
            _res_ = alloted_ - _consumed[account_];
        }

        return _res_;
    }

    /**
     * @dev Processes the Merkle proof to determine if `account_` is whitelisted.
     *
     * @param account_ : the address to validate access
     * @param proof_   : the Merkle proof to validate whitelist allocation
     *
     * @return bool : whether `account_` is whitelisted or not
     */
    function _computeProof(address account_, bytes32[] memory proof_)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(account_));
        return MerkleProof.processProof(proof_, leaf) == _root;
    }

    /**
     * @dev Consumes `amount_` whitelist access passes from `account_`.
     *
     * @param account_ : the address to consume access from
     *
     * Note: Before calling this function, eligibility should be checked through {Whitelistable-checkWhitelistAllowance}.
     */
    function _consumeWhitelist(address account_, uint256 qty_) internal {
        unchecked {
            _consumed[account_] += qty_;
        }
    }
}