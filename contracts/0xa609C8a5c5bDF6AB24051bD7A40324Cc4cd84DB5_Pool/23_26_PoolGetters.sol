// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PoolState.sol";
import "../Constants.sol";

contract PoolGetters is PoolState {
    using SafeMath for uint256;

    /**
     * Global
     */

    function usdc() public pure returns (address) {
        return Constants.getUsdcAddress();
    }

    function dao() public view returns (IDAO) {
        return IDAO(daoAddress);
    }

    function dollar() public view returns (IDollar) {
        return IDollar(dollarAddress);
    }

    function lpToken(uint256 poolID) public view returns (IERC20) {
        return _state[poolID].provider.lpToken;
    }

    function lpType(uint256 poolID) public view returns (PoolStorage.LPType) {
        return _state[poolID].lpType;
    }

    function totalBonded(uint256 poolID) public view returns (uint256) {
        return _state[poolID].balance.bonded;
    }

    function totalStaged(uint256 poolID) public view returns (uint256) {
        return _state[poolID].balance.staged;
    }

    function totalClaimable(uint256 poolID) public view returns (uint256) {
        return _state[poolID].balance.claimable;
    }

    function totalPhantom(uint256 poolID) public view returns (uint256) {
        return _state[poolID].balance.phantom;
    }

    function totalRewarded(uint256 poolID) public view returns (uint256) {
        return balanceOfPool(poolID).sub(totalClaimable(poolID));
    }

    function balanceOfPool(uint256 poolID) public view returns (uint256) {
        return _state[poolID].balance.reward;
    }

    function paused(uint256 poolID) public view returns (bool) {
        return _state[poolID].paused;
    }

    function poolTotalCount() public view returns (uint256) {
        return poolCount;
    }

    /**
     * Account
     */

    function balanceOfStaged(address account, uint256 poolID)
        public
        view
        returns (uint256)
    {
        return _state[poolID].accounts[account].staged;
    }

    function balanceOfClaimable(address account, uint256 poolID)
        public
        view
        returns (uint256)
    {
        return _state[poolID].accounts[account].claimable;
    }

    function balanceOfBonded(address account, uint256 poolID)
        public
        view
        returns (uint256)
    {
        return _state[poolID].accounts[account].bonded;
    }

    function balanceOfPhantom(address account, uint256 poolID)
        public
        view
        returns (uint256)
    {
        return _state[poolID].accounts[account].phantom;
    }

    function balanceOfRewarded(address account, uint256 poolID)
        public
        view
        returns (uint256)
    {
        uint256 _totalBonded = totalBonded(poolID);
        if (_totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded(poolID).add(
            totalPhantom(poolID)
        );
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom
            .mul(balanceOfBonded(account, poolID))
            .div(_totalBonded);

        uint256 _balanceOfPhantom = balanceOfPhantom(account, poolID);
        if (balanceOfRewardedWithPhantom > _balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(_balanceOfPhantom);
        }
        return 0;
    }

    function fluidUntil(address account, uint256 poolID)
        public
        view
        returns (uint256)
    {
        return _state[poolID].accounts[account].fluidUntil;
    }

    function statusOf(address account, uint256 poolID)
        public
        view
        returns (PoolAccount.Status)
    {
        return
            epoch() >= _state[poolID].accounts[account].fluidUntil
                ? PoolAccount.Status.Frozen
                : PoolAccount.Status.Fluid;
    }

    /**
     * Epoch
     */

    function epoch() internal view returns (uint256) {
        return dao().epoch();
    }
}