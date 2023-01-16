// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../../interfaces/IUniswapRouter.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IMasterWombatV2.sol";
import "../Common/StratManager.sol";
import "../Common/FeeManager.sol";
import "../../interfaces/IZaynReferrer.sol";
contract WombatStrategyBUSD is StratManager, FeeManager {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address constant public wom = address(0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1);
    address constant public busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    address public want;

    // Third party contracts
    IPool public wombatPool = IPool(0x0520451B19AD0bb00eD35ef391086A692CFC74B2);
    address constant public masterchef = address(0xE2C07d20AF0Fb50CAE6cDD615CA44AbaAA31F9c8);
    uint256 public poolId;

    // Routes
    address[] public womToWant = [wom, busd];

    uint256 public lastFeeCharge;

    bool public revShareEnabled = false;
    IZaynReferrer public zaynReferrer;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester);
    event Migrated();

    constructor(
        address _want,
        uint256 _poolId,
        address _vault,
        address _unirouter,
        address _keeper,
        address _strategist,
        address _zaynFeeRecipient
    ) StratManager(_keeper, _strategist, _unirouter, _vault, _zaynFeeRecipient) public {
        want = _want;
        poolId = _poolId;
        lastFeeCharge = block.timestamp;

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal > 0) {
            IMasterWombatV2(masterchef).deposit(poolId, wantBal);
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IMasterWombatV2(masterchef).withdraw(poolId, _amount.sub(wantBal));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        if (tx.origin == owner() || paused()) {
            IERC20(want).safeTransfer(vault, wantBal);
        } else {
            // uint256 withdrawalFeeAmount = wantBal.mul(withdrawalFee).div(WITHDRAWAL_MAX);
            IERC20(want).safeTransfer(vault, wantBal);
        }
    }

    // compounds earnings and charges performance fee
    function harvest() external whenNotPaused {
        IMasterWombatV2(masterchef).deposit(poolId, 0);
        chargeFees();
        addLiquidity();
        deposit();

        emit StratHarvest(msg.sender);
    }

    // performance fees
    function chargeFees() internal {
        uint256 harvested = IERC20(wom).balanceOf(address(this));
        IUniswapRouter(unirouter).swapExactTokensForTokens(harvested, 0, womToWant, address(this), block.timestamp);

        uint256 swapped = IERC20(busd).balanceOf(address(this));

        uint256 zaynFee = swapped.mul(zaynFee).div(MAX_FEE);
        if (revShareEnabled) {
            uint256 revShareFees = zaynFee.mul(revShareFees).div(MAX_FEE);
            IERC20(busd).safeTransfer(address(zaynReferrer), revShareFees);
            IERC20(busd).safeTransfer(zaynFeeRecipient, zaynFee.sub(revShareFees));


        } else {
            IERC20(busd).safeTransfer(zaynFeeRecipient, zaynFee);
        }
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 daiAmount = IERC20(busd).balanceOf(address(this));
        wombatPool.deposit(busd, daiAmount, 0, address(this), block.timestamp, false);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount, ) = IMasterWombatV2(masterchef).userInfo(poolId, address(this));
        return _amount;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        IMasterWombatV2(masterchef).emergencyWithdraw(poolId);

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        IMasterWombatV2(masterchef).emergencyWithdraw(poolId);
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(masterchef, type(uint256).max);
        IERC20(wom).safeApprove(unirouter, type(uint256).max);
        IERC20(busd).safeApprove(address(wombatPool), type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(wom).safeApprove(unirouter, 0);
        IERC20(busd).safeApprove(address(wombatPool), 0);
    }

    // charges 2% annual management fee per 12 hours.
    function chargeManagementFees() external {
        if (block.timestamp >= lastFeeCharge.add(feeChargeSeconds)) {
            uint secondsElapsed = block.timestamp - lastFeeCharge;
            uint chargeAmount = chargePerDay.div(86400).mul(secondsElapsed); // getting 0.02 / 365 / 86400

            uint256 tvl = balanceOf();
            uint256 fees = tvl.mul(chargeAmount).div(1e18);

            IMasterWombatV2(masterchef).withdraw(poolId, fees);
            IERC20(want).safeTransfer(zaynFeeRecipient, fees);
            lastFeeCharge = block.timestamp;
        }
    }

    function enableRevShare(IZaynReferrer _referrer) external onlyOwner {
        revShareEnabled = true;
        zaynReferrer = _referrer;
    }

    function disableRevShare() external onlyOwner {
        revShareEnabled = false;
    }

    function migrate() override external virtual {
        emit Migrated();
    }
}