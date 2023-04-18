// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./interfaces/IStaking.sol";
import "./gauges/AbsGauge.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

contract StakingHOPE is IStaking, ERC20, AbsGauge {
    uint256 internal constant _LOCK_TIME = 28;

    // permit2 contract
    address public permit2Address;

    struct UnstakingOrderDetail {
        uint256 amount;
        uint256 redeemTime;
        bool redeemExecuted;
    }

    struct UnstakingOrderSummary {
        uint256 notRedeemAmount;
        uint256 index;
        mapping(uint256 => UnstakingOrderDetail) orderMap;
    }

    uint256 public totalNotRedeemAmount;
    mapping(address => UnstakingOrderSummary) public unstakingMap;
    mapping(uint256 => uint256) public unstakingDayHistory;
    uint256 private _unstakeTotal;

    constructor(address _stakedToken, address _minter, address _permit2Address) ERC20("staked HOPE", "stHOPE") {
        require(_stakedToken != address(0), "CE000");
        require(_permit2Address != address(0), "CE000");

        _init(_stakedToken, _minter, _msgSender());

        permit2Address = _permit2Address;
    }

    /***
     * @notice Stake HOPE to get stHOPE
     *
     * @param amount
     * @param nonce
     * @param deadline
     * @param signature
     */
    function staking(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external override returns (bool) {
        require(amount != 0, "CE002");

        address staker = _msgSender();
        // checking amount
        uint256 balanceOfUser = IERC20(lpToken).balanceOf(staker);
        require(balanceOfUser >= amount, "CE002");
        TransferHelper.doTransferIn(permit2Address, lpToken, amount, staker, nonce, deadline, signature);

        _checkpoint(staker);

        _mint(staker, amount);

        _updateLiquidityLimit(staker, lpBalanceOf(staker), lpTotalSupply());

        emit Staking(staker, amount);
        return true;
    }

    /***
     * @notice unstaking the staked amount
     * The unstaking process takes 28 days to complete. During this period,
     *  the unstaked $HOPE cannot be traded, and no staking rewards are accrued.
     *
     * @param
     * @return
     */
    function unstaking(uint256 amount) external {
        require(amount != 0, "CE002");

        address staker = _msgSender();
        // checking amount
        uint256 balanceOfUser = lpBalanceOf(staker);
        require(balanceOfUser >= amount, "CE002");

        _checkpoint(staker);

        uint256 nextDayTime = ((block.timestamp + _DAY) / _DAY) * _DAY;
        // lock 28 days
        uint256 redeemTime = nextDayTime + _DAY * _LOCK_TIME;

        unstakingDayHistory[nextDayTime] = unstakingDayHistory[nextDayTime] + amount;
        _unstakeTotal = _unstakeTotal + amount;

        UnstakingOrderSummary storage summaryMap = unstakingMap[staker];

        summaryMap.notRedeemAmount = summaryMap.notRedeemAmount + amount;
        summaryMap.index = summaryMap.index + 1;
        summaryMap.orderMap[summaryMap.index] = UnstakingOrderDetail(amount, redeemTime, false);
        totalNotRedeemAmount += amount;

        _updateLiquidityLimit(staker, lpBalanceOf(staker), lpTotalSupply());
        emit Unstaking(staker, amount);
    }

    /***
     * @notice get unstaking amount
     *
     * @return
     */
    function unstakingBalanceOf(address _addr) public view returns (uint256) {
        uint256 _unstakingAmount = 0;
        UnstakingOrderSummary storage summaryMap = unstakingMap[_addr];
        for (uint256 _index = summaryMap.index; _index > 0; _index--) {
            if (summaryMap.orderMap[_index].redeemExecuted) {
                break;
            }
            if (block.timestamp < summaryMap.orderMap[_index].redeemTime) {
                _unstakingAmount += summaryMap.orderMap[_index].amount;
            }
        }
        return _unstakingAmount;
    }

    function unstakingTotal() public view returns (uint256) {
        uint256 _unstakingTotal = 0;

        uint256 nextDayTime = ((block.timestamp + _DAY) / _DAY) * _DAY;
        for (uint256 i = 0; i < _LOCK_TIME; i++) {
            _unstakingTotal += unstakingDayHistory[nextDayTime - _DAY * i];
        }
        return _unstakingTotal;
    }

    /***
     * @notice get can redeem amount
     *
     * @param
     * @return
     */
    function unstakedBalanceOf(address _addr) public view returns (uint256) {
        uint256 amountToRedeem = 0;
        UnstakingOrderSummary storage summaryMap = unstakingMap[_addr];
        for (uint256 _index = summaryMap.index; _index > 0; _index--) {
            if (summaryMap.orderMap[_index].redeemExecuted) {
                break;
            }
            if (block.timestamp >= summaryMap.orderMap[_index].redeemTime) {
                amountToRedeem += summaryMap.orderMap[_index].amount;
            }
        }
        return amountToRedeem;
    }

    function unstakedTotal() external view returns (uint256) {
        return _unstakeTotal - unstakingTotal();
    }

    /***
     * @notice Redeem all amounts to your account
     *
     * @param
     * @return
     */
    function redeemAll() external override returns (uint256) {
        address redeemer = _msgSender();
        uint256 amountToRedeem = unstakedBalanceOf(redeemer);
        require(amountToRedeem != 0, "CE002");

        _checkpoint(redeemer);

        UnstakingOrderSummary storage summaryMap = unstakingMap[redeemer];
        for (uint256 _index = summaryMap.index; _index > 0; _index--) {
            if (summaryMap.orderMap[_index].redeemExecuted) {
                break;
            }
            if (block.timestamp >= summaryMap.orderMap[_index].redeemTime) {
                uint256 amount = summaryMap.orderMap[_index].amount;
                summaryMap.orderMap[_index].redeemExecuted = true;
                summaryMap.notRedeemAmount = summaryMap.notRedeemAmount - amount;
                totalNotRedeemAmount -= amount;
            }
        }

        _burn(redeemer, amountToRedeem);
        TransferHelper.doTransferOut(lpToken, redeemer, amountToRedeem);
        _updateLiquidityLimit(redeemer, lpBalanceOf(redeemer), lpTotalSupply());

        _unstakeTotal = _unstakeTotal - amountToRedeem;

        emit Redeem(redeemer, amountToRedeem);
        return amountToRedeem;
    }

    /***
     * @notice redeem amount by index(Prevent the number of unstaking too much to redeem)
     *
     * @param maxIndex
     * @return
     */
    function redeemByMaxIndex(uint256 maxIndex) external returns (uint256) {
        address redeemer = _msgSender();

        uint256 allToRedeemAmount = unstakedBalanceOf(redeemer);
        require(allToRedeemAmount != 0, "CE002");

        uint256 amountToRedeem = 0;
        _checkpoint(redeemer);

        UnstakingOrderSummary storage summaryMap = unstakingMap[redeemer];
        uint256 indexCount = 0;
        for (uint256 _index = 1; _index <= summaryMap.index; _index++) {
            if (indexCount >= maxIndex) {
                break;
            }
            if (block.timestamp >= summaryMap.orderMap[_index].redeemTime && !summaryMap.orderMap[_index].redeemExecuted) {
                uint256 amount = summaryMap.orderMap[_index].amount;
                amountToRedeem += amount;
                summaryMap.orderMap[_index].redeemExecuted = true;
                summaryMap.notRedeemAmount = summaryMap.notRedeemAmount - amount;
                totalNotRedeemAmount -= amount;
                indexCount++;
            }
        }

        if (amountToRedeem > 0) {
            _burn(redeemer, amountToRedeem);
            TransferHelper.doTransferOut(lpToken, redeemer, amountToRedeem);
            _updateLiquidityLimit(redeemer, lpBalanceOf(redeemer), lpTotalSupply());

            _unstakeTotal = _unstakeTotal - amountToRedeem;
            emit Redeem(redeemer, amountToRedeem);
        }
        return amountToRedeem;
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2Address;
        permit2Address = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    function lpBalanceOf(address _addr) public view override returns (uint256) {
        return super.balanceOf(_addr) - unstakingMap[_addr].notRedeemAmount;
    }

    function lpTotalSupply() public view override returns (uint256) {
        return super.totalSupply() - totalNotRedeemAmount;
    }

    /***
     * @notice Transfers Gauge deposit (stHOPE) from the caller to _to.
     *
     * @param to
     * @param amount
     * @return bool
     */
    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 fromBalance = lpBalanceOf(owner);
        require(fromBalance >= _amount, "CE002");

        _checkpoint(owner);
        _checkpoint(_to);

        bool result = super.transfer(_to, _amount);

        _updateLiquidityLimit(owner, lpBalanceOf(owner), lpTotalSupply());
        _updateLiquidityLimit(_to, lpBalanceOf(_to), lpTotalSupply());
        return result;
    }

    /***
     * @notice Tansfers a Gauge deposit between _from and _to.
     *
     * @param from
     * @param to
     * @param amount
     * @return bool
     */
    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        uint256 fromBalance = lpBalanceOf(_from);
        require(fromBalance >= _amount, "CE002");

        _checkpoint(_from);
        _checkpoint(_to);

        bool result = super.transferFrom(_from, _to, _amount);

        _updateLiquidityLimit(_from, lpBalanceOf(_from), lpTotalSupply());
        _updateLiquidityLimit(_to, lpBalanceOf(_to), lpTotalSupply());
        return result;
    }
}