//.██████..███████.███████.██.....██████..██████...██████.
//.██...██.██......██......██.....██...██.██...██.██....██
//.██████..█████...█████...██.....██████..██████..██....██
//.██...██.██......██......██.....██......██...██.██....██
//.██...██.███████.██......██.....██......██...██..██████.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { Auth, Authority } from "solmate/auth/Auth.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

import { IVaultConfig } from "./interfaces/IVaultConfig.sol";
import { RPVault } from "./RPVault.sol";

contract DefaultVaultConfig is Auth, IVaultConfig {
    bool public _isFeeEnabled = true;
    uint256 public _entryFeeBps = 100;
    uint256 public _exitFeeBps = 100;

    uint256 public minimumStoredValueBeforeFees = 10_000 * 1e6; // 25k USDC
    uint256 public minimumRefiHeld = 1_000_000 * 1e18; // 1 million REFI

    address public refiAddress;
    address public vaultAddress;

    struct UserOverride {
        bool shouldOverrideCanDeposit;
        bool canDeposit;
        bool hasCustomMinimum;
        uint256 customMinimum;
    }
    mapping(address => UserOverride) public userOverrides;

    error VaultNotSetup();

    modifier onlyAfterVaultSetup() {
        if (!isVaultSetup()) {
            revert VaultNotSetup();
        }
        _;
    }

    constructor(
        address _owner,
        address _refiAddress,
        address _vaultAddress
    ) Auth(msg.sender, Authority(address(0))) {
        refiAddress = _refiAddress;
        setVaultAddress(_vaultAddress);

        // transactions from https://etherscan.io/address/0x00000997e18087b2477336fe87b0c486c6a2670d
        setUserOverride(0xad55d623201C26Ac599A4F6898fdD519d98D1070, true);
        setUserOverride(0x00d16F998e1f62fB2a58995dd2042f108eB800d1, true);
        setUserOverride(0x7e849911b62B91eb3623811A42b9820a4a78755b, true);
        setUserOverride(0x82D746d7d53515B22Ad058937EE4D139bA09Ff07, true);
        setUserOverride(0x9F58E312F9efFF3e055e75A154Df8C624D07Cde9, true);
        setUserOverride(0x5189d4978504CfB245D3ed918a6C2629Cac7b0df, true);
        setUserOverride(0xf4d430dD8EaA0412c802fFb450250cC8B6117895, true);
        setUserOverride(0xb6Aa99C580A5203A6C0d7FA40b88d09cb5D65911, true);
        setUserOverride(0x29b7e5E20820ec9A27896AE25f768B8F3B3Bc263, true);

        // new
        setUserOverride(0xf3782301916F56598dDBE5c74C91fd1Aa52B4CC3, true);

        setOwner(_owner);
    }

    ///////////////////////////////////////////////////////////////////////////
    // IVaultConfig ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    function canDeposit(address _user, uint256 _assets) external view onlyAfterVaultSetup returns (bool) {
        if (userOverrides[_user].shouldOverrideCanDeposit) {
            return userOverrides[_user].canDeposit;
        }
        if (userOverrides[_user].hasCustomMinimum) {
            return _assets + getAlreadyStoredValue(_user) >= userOverrides[_user].customMinimum;
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
        if (vaultAddress != address(0)) {
            return RPVault(vaultAddress).entryFeeBps();
        }
        return _entryFeeBps;
    }

    function exitFeeBps(address) external view onlyAfterVaultSetup returns (uint256) {
        if (vaultAddress != address(0)) {
            return RPVault(vaultAddress).exitFeeBps();
        }
        return _entryFeeBps;
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

    function setVaultAddress(address _vaultAddress) public requiresAuth {
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

    function setUserOverride(address _user, bool _canDeposit) public requiresAuth {
        userOverrides[_user].shouldOverrideCanDeposit = true;
        userOverrides[_user].canDeposit = _canDeposit;
    }

    function setUserCustomMinimum(address _user, uint256 _minimum) external requiresAuth {
        userOverrides[_user].hasCustomMinimum = true;
        userOverrides[_user].customMinimum = _minimum;
    }

    function removeUserCustomMinimum(address _user) external requiresAuth {
        userOverrides[_user].hasCustomMinimum = false;
    }
}