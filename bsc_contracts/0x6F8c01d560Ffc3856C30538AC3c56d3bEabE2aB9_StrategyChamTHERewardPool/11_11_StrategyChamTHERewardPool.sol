// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IRewardPool.sol";
import "../vault-ce/StrategyCeManager.sol";

contract StrategyChamTHERewardPool is StrategyCeManager {
    using SafeERC20 for IERC20;

    // Tokens used
    address public want;

    // Third party contracts
    address public rewardPool;

    bool public harvestOnDeposit;
    uint256 public lastHarvest;

    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees, uint256 coFees, uint256 strategistFees);

    constructor(
        address _want,
        address _rewardPool,
        CommonAddresses memory _commonAddresses
    ) StrategyCeManager(_commonAddresses) {
        want = _want;
        rewardPool = _rewardPool;
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = balanceOfWant();

        if (wantBal > 0) {
            IRewardPool(rewardPool).stake(wantBal - balanceOfPool());
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "Strategy: VAULT_ONLY");

        if (balanceOfPool() > 0) {
            IRewardPool(rewardPool).withdraw(_amount);
        }

        if (tx.origin != owner() && !paused()) {
            uint256 withdrawalFeeAmount = _amount * withdrawalFee / WITHDRAWAL_MAX;
            _amount = _amount - withdrawalFeeAmount;
        }

        IERC20(want).safeTransfer(vault, _amount);

        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "Strategy: VAULT_ONLY");
            _harvest();
        }
    }

    function harvest() external virtual {
        _harvest();
    }

    // compounds earnings and charges performance fee
    function _harvest() internal whenNotPaused {
        uint256 before = balanceOfWant();
        IRewardPool(rewardPool).getReward();
        uint256 rewardBal = balanceOfWant() - before;
        if (rewardBal > 0) {
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, rewardBal, balanceOf());
            emit ChargedFees(0,0,0);
        }
    }

    // calculate the total underlying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return IRewardPool(rewardPool).balanceOf(address(this));
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return IRewardPool(rewardPool).earned(address(this));
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;
        if (harvestOnDeposit == true) {
            setWithdrawalFee(0);
        } else {
            setWithdrawalFee(10);
        }
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "Strategy: VAULT_ONLY");

        IRewardPool(rewardPool).withdraw(balanceOfPool());

        uint256 wantBal = balanceOfWant();
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        IRewardPool(rewardPool).withdraw(balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();
    }

    function unpause() external onlyManager {
        _unpause();

        deposit();
    }
}