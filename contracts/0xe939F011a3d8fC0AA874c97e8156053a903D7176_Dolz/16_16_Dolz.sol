// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {NativeMetaTransaction} from "./common/NativeMetaTransaction.sol";
import {ContextMixin} from "./common/ContextMixin.sol";
import {AccessControlMixin} from "./common/AccessControlMixin.sol";

contract Dolz is
    ERC20,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(string memory name_, string memory symbol_, uint256 initialSupply_)
        ERC20(name_, symbol_)
    {
        _setupContractId("Dolz");
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PREDICATE_ROLE, _msgSender());

        _mint(_msgSender(), initialSupply_);
        _initializeEIP712(name_);
    }

    /// @dev Allow user to burn his token
    /// @param _amount Amount of tokens to burn
    function burn(uint256 _amount)
    external {
        _burn(_msgSender(), _amount);
    }

    function _msgSender()
    internal
    view
    virtual
    override
    returns (address) {
        return ContextMixin.msgSender();
    }
}