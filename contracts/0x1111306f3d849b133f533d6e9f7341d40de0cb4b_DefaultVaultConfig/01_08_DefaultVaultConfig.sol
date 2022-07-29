//.██████..███████.███████.██.....██████..██████...██████.
//.██...██.██......██......██.....██...██.██...██.██....██
//.██████..█████...█████...██.....██████..██████..██....██
//.██...██.██......██......██.....██......██...██.██....██
//.██...██.███████.██......██.....██......██...██..██████.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { Auth, Authority } from "solmate/auth/Auth.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

import { IVaultConfig } from "./interfaces/IVaultConfig.sol";
import { RPVault } from "./RPVault.sol";

contract DefaultVaultConfig is Auth, IVaultConfig {
    bool public _isFeeEnabled = true;
    uint256 public _entryFeeBps = 100;
    uint256 public _exitFeeBps = 100;

    uint256 public minimumStoredValueBeforeFees = 25_000 * 1e6; // 25k USDC
    uint256 public minimumRefiHeld = 1_000_000 * 1e18; // 1 million REFI

    address public refiAddress;
    address public vaultAddress;

    struct UserOverride {
        bool shouldOverrideCanDeposit;
        bool canDeposit;
    }
    mapping(address => UserOverride) public userOverrides;

    error VaultNotSetup();

    modifier onlyAfterVaultSetup() {
        if (!isVaultSetup()) {
            revert VaultNotSetup();
        }
        _;
    }

    constructor(address _owner, address _refiAddress) Auth(_owner, Authority(address(0))) {
        refiAddress = _refiAddress;
    }

    ///////////////////////////////////////////////////////////////////////////
    // IVaultConfig ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    function canDeposit(address _user, uint256 _assets) external view onlyAfterVaultSetup returns (bool) {
        if (userOverrides[_user].shouldOverrideCanDeposit) {
            return userOverrides[_user].canDeposit;
        }
        if (isRefiHolder(_user)) {
            return true;
        }
        return _assets + getAlreadyStoredValue(_user) >= minimumStoredValueBeforeFees;
    }

    function isFeeEnabled(address) external view onlyAfterVaultSetup returns (bool) {
        return _isFeeEnabled;
    }

    function entryFeeBps(address) external view onlyAfterVaultSetup returns (uint256) {
        return _entryFeeBps;
    }

    function exitFeeBps(address) external view onlyAfterVaultSetup returns (uint256) {
        return _exitFeeBps;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Helpers ////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    function isRefiHolder(address _user) internal view returns (bool) {
        ERC20 refi = ERC20(refiAddress);
        return refi.balanceOf(_user) >= minimumRefiHeld;
    }

    function getAlreadyStoredValue(address _user) internal view returns (uint256) {
        RPVault vault = RPVault(vaultAddress);
        return vault.getStoredValue(_user);
    }

    function isVaultSetup() internal view returns (bool) {
        return vaultAddress != address(0);
    }

    function setVaultAddress(address _vaultAddress) external requiresAuth {
        vaultAddress = _vaultAddress;
    }

    function setMinimumRefiHeld(uint256 _minimumRefiHeld) external requiresAuth {
        minimumRefiHeld = _minimumRefiHeld;
    }

    function setRefiAddress(address _refiAddress) external requiresAuth {
        refiAddress = _refiAddress;
    }

    function setMinimumDeposit(uint256 _assetAmount) external requiresAuth {
        minimumStoredValueBeforeFees = _assetAmount;
    }

    function removeUserOverride(address _user) external requiresAuth {
        userOverrides[_user].shouldOverrideCanDeposit = false;
    }

    function setUserOverride(address _user, bool _canDeposit) external requiresAuth {
        userOverrides[_user].shouldOverrideCanDeposit = true;
        userOverrides[_user].canDeposit = _canDeposit;
    }
}