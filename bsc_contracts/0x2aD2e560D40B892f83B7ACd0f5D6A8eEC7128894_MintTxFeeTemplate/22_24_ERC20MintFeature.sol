// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features-interfaces/IERC20MintFeature.sol";

/**
 * @dev ERC20 token with a mint control feature
 */
abstract contract ERC20MintFeature is ERC20Base, IERC20MintFeature {

    bytes32 public constant MINTER_ROLE = keccak256("ERC20_MINTER_ROLE");

    function __ERC20MintFeature_init_unchained() internal onlyInitializing {
    }

    /**
     * @notice Mint tokens to a single address
     * @dev Only the MINTER_ROLE can mint tokens.
     */
    function mint(address account, uint256 amount) public override onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    /**
     * @notice Mint tokens to a set of address
     * @dev Only the MINTER_ROLE can mint tokens. Should set the role
     */
    function bulkMint(address[] calldata accounts, uint256[] calldata amounts) public override onlyRole(MINTER_ROLE) {
        require(accounts.length == amounts.length, "Array length mismatch");
        for(uint i; i < accounts.length; i++){
            _mint(accounts[i], amounts[i]);
        }
    }

}