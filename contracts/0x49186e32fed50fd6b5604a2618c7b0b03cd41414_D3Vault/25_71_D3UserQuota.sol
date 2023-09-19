// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "../../../intf/IERC20.sol";
import {ID3UserQuota} from "../../intf/ID3UserQuota.sol";
import {ID3Vault} from "../../intf/ID3Vault.sol";
import "../../../intf/ID3Oracle.sol";
import "../../lib/DecimalMath.sol";

/// @title UserQuota
/// @notice This contract is used to set/get user's quota, i.e., determine the amount of token user can deposit into the pool.
contract D3UserQuota is Ownable, ID3UserQuota {
    using DecimalMath for uint256;

    // only user who holds vToken can deposit money
    address public _vTOKEN_;
    // tiers based on the amount of vToken user holds
    mapping(address => uint256[]) public vTokenTiers;
    // token => [quota on each tier]
    mapping(address => uint256[]) public quotaOnTiers;
    // token => bool, if false, a token is not using quota, can deposit unlimit amount
    mapping(address => bool) public isUsingQuota;
    // token => bool, if true, using global quota instead of vToken quota
    mapping(address => bool) public isGlobalQuota;
    // token => quota
    mapping(address => uint256) public globalQuota;

    ID3Vault public d3Vault;

    constructor(address vToken, address d3VaultAddress) {
        _vTOKEN_ = vToken;
        d3Vault = ID3Vault(d3VaultAddress);
    }

    /// @notice Enable quota for a token
    function enableQuota(address token, bool status) external onlyOwner {
        isUsingQuota[token] = status;
    }

    /// @notice Enable global quota for a token
    function enableGlobalQuota(address token, bool status) external onlyOwner {
        isGlobalQuota[token] = status;
    }

    /// @notice Set global quota for a token
    /// @notice Global quota means every user has the same quota, no matter how many vToken they hold
    function setGlobalQuota(address token, uint256 amount) external onlyOwner {
        globalQuota[token] = amount;
    }

    // @notice Set vToken address
    function setVToken(address vToken) external onlyOwner {
        _vTOKEN_ = vToken;
    }

    /// @notice Set the amount of tokens held and their corresponding quotas
    /// @notice for example, tiers = [100, 200, 300, 400], amounts = [1000, 4000, 6000, 10000]
    /// @notice user who holds 100 vToken, can deposit 1000 token
    /// @notice user who holds 200 vToken, can deposit 4000 token
    /// @notice user who holds 300 vToken, can deposit 6000 token
    /// @notice user who holds 400 vToken, can deposit 10000 token
    function setTiers(address token, uint256[] calldata tiers, uint256[] calldata amounts) external onlyOwner {
        require(tiers.length > 0 && tiers.length == amounts.length, "D3UserQuota: length not match");
        vTokenTiers[token] = tiers;
        quotaOnTiers[token] = amounts;
    }

    /// @notice Get the user quota based on tier
    function getTierQuota(address user, address token) public view returns (uint256 quota) {
        uint256 vTokenBalance = IERC20(_vTOKEN_).balanceOf(user);
        uint256[] memory tiers = vTokenTiers[token];
        uint256[] memory amounts = quotaOnTiers[token];
        for (uint256 i = 0; i < tiers.length; i++) {
            if (vTokenBalance < tiers[i]) {
                return quota = amounts[i];
            }
        }
        quota = amounts[amounts.length - 1];
    }

    /// @notice Get the used quota
    function getUsedQuota(address user, address token) public view returns (uint256) {
        (address dToken,,,,,,,,,,) = d3Vault.getAssetInfo(token);
        uint256 dTokenBalance = IERC20(dToken).balanceOf(user);
        uint256 exchangeRate = d3Vault.getExchangeRate(token);
        return dTokenBalance.mul(exchangeRate);
    }

    /// @notice Get the user quota for a token
    function getUserQuota(address user, address token) public view returns (uint256) {
        uint256 usedQuota = getUsedQuota(user, token);
        if (isUsingQuota[token]) {
            if (isGlobalQuota[token]) {
                return globalQuota[token] - usedQuota;
            } else {
                return getTierQuota(user, token) - usedQuota;
            }
        } else {
            return type(uint256).max;
        }
    }

    /// @notice Check if the quantity of tokens deposited by the user is allowed.
    function checkQuota(address user, address token, uint256 amount) public view returns (bool) {
        return (amount <= getUserQuota(user, token));
    }
}