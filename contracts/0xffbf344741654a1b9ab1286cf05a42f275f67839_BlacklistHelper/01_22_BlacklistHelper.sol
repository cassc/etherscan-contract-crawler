// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ACLTrait } from "../core/ACLTrait.sol";
import { IBlacklistHelper } from "../interfaces/IBlacklistHelper.sol";
import { ICreditFacade } from "../interfaces/ICreditFacade.sol";

interface IBlacklistableUSDC {
    function isBlacklisted(address _account) external view returns (bool);
}

interface IBlacklistableUSDT {
    function isBlackListed(address _account) external view returns (bool);
}

/// @title Blacklist Helper
/// @dev A contract used to enable successful liquidations when the borrower is blacklisted
///      while simultaneously allowing them to recover their funds under a different address
contract BlacklistHelper is ACLTrait, IBlacklistHelper {
    using SafeERC20 for IERC20;

    /// @dev Address of USDC
    address public immutable usdc;

    /// @dev Address of USDT
    address public immutable usdt;

    /// @dev mapping from address to supported Credit Facade status
    mapping(address => bool) public isSupportedCreditFacade;

    /// @dev mapping from (underlying, account) to amount available to claim
    mapping(address => mapping(address => uint256)) public claimable;

    /// @dev Contract version
    uint256 public constant override version = 3_00;

    /// @dev Restricts calls to Credit Facades only
    modifier creditFacadeOnly() {
        if (!isSupportedCreditFacade[msg.sender]) {
            revert CreditFacadeOnlyException();
        }
        _;
    }

    /// @param _addressProvider Address of the address provider
    /// @param _usdc Address of USDC
    /// @param _usdt Address of USDT
    constructor(
        address _addressProvider,
        address _usdc,
        address _usdt
    ) ACLTrait(_addressProvider) {
        usdc = _usdc; // F:[BH-1]
        usdt = _usdt; // F:[BH-1]
    }

    /// @dev Returns whether the account is blacklisted for a particular underlying
    /// @param underlying Underlying token to check
    /// @param account Account to check
    /// @notice Used to consolidate different `isBlacklisted` functions under the same interface
    function isBlacklisted(address underlying, address account)
        external
        view
        override
        returns (bool)
    {
        if (underlying == usdc) {
            return IBlacklistableUSDC(usdc).isBlacklisted(account); // F:[BH-2]
        } else if (underlying == usdt) {
            return IBlacklistableUSDT(usdt).isBlackListed(account); // F:[BH-2]
        } else {
            return false;
        }
    }

    /// @dev Increases the underlying balance available to claim by the account
    /// @param underlying Underlying to increase claimable for
    /// @param holder Account to increase claimable for
    /// @param amount Amount to increase claimable claimable for
    /// @notice Can only be called by Credit Facades when liquidating a blacklisted borrower
    ///         Expects the underlying to be transferred directly to this contract in the same transaction
    function addClaimable(
        address underlying,
        address holder,
        uint256 amount
    ) external override creditFacadeOnly {
        claimable[underlying][holder] += amount; // F:[BH-4]
        emit ClaimableAdded(underlying, holder, amount); // F:[BH-4]
    }

    /// @dev Transfers the sender's claimable balance of underlying to the specified address
    /// @param underlying Underlying to transfer
    /// @param to Recipient address
    function claim(address underlying, address to) external override {
        uint256 amount = claimable[underlying][msg.sender];
        if (amount < 1) {
            revert NothingToClaimException(); // F:[BH-5]
        }
        claimable[underlying][msg.sender] = 0; // F:[BH-5]
        IERC20(underlying).safeTransfer(to, amount); // F:[BH-5]
        emit Claimed(underlying, msg.sender, to, amount); // F:[BH-5]
    }

    /// @dev Adds a new Credit Facade to `supported` list
    /// @param _creditFacade Address of the Credit Facade
    function addCreditFacade(address _creditFacade) external configuratorOnly {
        if (!ICreditFacade(_creditFacade).isBlacklistableUnderlying()) {
            revert CreditFacadeNonBlacklistable(); // F:[BH-3]
        }
        isSupportedCreditFacade[_creditFacade] = true; // F:[BH-3]
        emit CreditFacadeAdded(_creditFacade); // F:[BH-3]
    }

    /// @dev Removes a Credit Facade from the `supported` list
    /// @param _creditFacade Address of the Credit Facade
    function removeCreditFacade(address _creditFacade)
        external
        configuratorOnly
    {
        isSupportedCreditFacade[_creditFacade] = false; // F:[BH-3]
        emit CreditFacadeRemoved(_creditFacade); // F:[BH-3]
    }
}