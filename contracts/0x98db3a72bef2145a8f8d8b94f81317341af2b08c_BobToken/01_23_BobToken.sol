// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "./proxy/EIP1967Admin.sol";
import "./token/ERC677.sol";
import "./token/ERC20Permit.sol";
import "./token/ERC20MintBurn.sol";
import "./token/ERC20Recovery.sol";
import "./token/ERC20Blocklist.sol";
import "./utils/Claimable.sol";

/**
 * @title BobToken
 */
contract BobToken is
    EIP1967Admin,
    BaseERC20,
    ERC677,
    ERC20Permit,
    ERC20MintBurn,
    ERC20Recovery,
    ERC20Blocklist,
    Claimable
{
    /**
     * @dev Creates a proxy implementation for BobToken.
     * @param _self address of the proxy contract, linked to the deployed implementation,
     * required for correct EIP712 domain derivation.
     */
    constructor(address _self) ERC20Permit(_self) {}

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return "BOB";
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view override returns (string memory) {
        return "BOB";
    }

    /**
     * @dev Tells if caller is the contract owner.
     * Gives ownership rights to the proxy admin as well.
     * @return true, if caller is the contract owner or proxy admin.
     */
    function _isOwner() internal view override returns (bool) {
        return super._isOwner() || _admin() == _msgSender();
    }
}