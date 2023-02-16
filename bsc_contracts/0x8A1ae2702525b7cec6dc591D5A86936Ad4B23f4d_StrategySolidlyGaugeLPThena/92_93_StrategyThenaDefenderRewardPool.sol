// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/IGasPrice.sol";
import "../interfaces/IFarming.sol";
import "../utils/StringUtils.sol";
import "./FeeManager.sol";

contract StrategyThenaDefenderRewardPool is FeeManager {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public gasprice;
    // Tokens used
    address public native;
    address public output;
    address public want;
    address public eth;
    address public cham;

    address public thenaRouter;

    // Third party contracts
    address public masterChef;
    uint256 public poolId;

    bool public harvestOnDeposit;
    uint256 public lastHarvest;
    string public pendingRewardsFunctionName;

    // Routes
    address[] public outputToNativeRoute;
    address[] public outputToEthRoute;
    ISolidlyRouter.Routes[] public ethToChamRoute;

    event StratHarvest(
        address indexed harvester,
        uint256 wantHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(
        uint256 callFees,
        uint256 coFees,
        uint256 strategistFees
    );

    modifier gasThrottle() {
        require(
            !IGasPrice(gasprice).enabled() ||
                tx.gasprice <= IGasPrice(gasprice).maxGasPrice(),
            "Strategy: GAS_TOO_HIGH"
        );
        _;
    }

    constructor(
        address _want,
        uint256 _poolId,
        address _masterChef,
        address _gasprice,
        address _eth,
        address _thenaRouter,
        CommonAddresses memory _commonAddresses,
        address[] memory _outputToNativeRoute
    ) StratManager(_commonAddresses) {
        want = _want;
        poolId = _poolId;
        masterChef = _masterChef;
        gasprice = _gasprice;
        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        thenaRouter = _thenaRouter;
        eth = _eth;

        outputToNativeRoute = _outputToNativeRoute;
        
        outputToEthRoute.push(output);
        outputToEthRoute.push(native);
        outputToEthRoute.push(eth);

        // setup lp routing
        address lpToken0 = IUniswapV2Pair(want).token0();
        if (lpToken0 != eth) {
            cham = lpToken0;
        } else {
            cham = IUniswapV2Pair(want).token1();
        }

        bytes memory _stable = Address.functionStaticCall(
            want,
            abi.encodeWithSignature("stable()")
        );
        ethToChamRoute.push(ISolidlyRouter.Routes({
            from : eth,
            to : cham,
            stable : abi.decode(_stable, (bool))
        }));

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IFarming(masterChef).deposit(poolId, wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "Strategy: VAULT_ONLY");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IFarming(masterChef).withdraw(poolId, _amount.sub(wantBal));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "Strategy: VAULT_ONLY");
            _harvest(tx.origin);
        }
    }

    function harvest() external virtual gasThrottle {
        _harvest(tx.origin);
    }

    function harvest(address callFeeRecipient) external virtual gasThrottle {
        _harvest(callFeeRecipient);
    }

    function managerHarvest() external onlyManager {
        _harvest(tx.origin);
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal whenNotPaused {
        IFarming(masterChef).deposit(poolId, 0);
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        if (outputBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 toNative = IERC20(output)
            .balanceOf(address(this))
            .mul(totalPerformanceFee)
            .div(PERCENTAGE);

        IUniswapV2Router(uniRouter).swapExactTokensForTokens(
            toNative,
            0,
            outputToNativeRoute,
            address(this),
            block.timestamp
        );

        uint256 nativeBal = IERC20(native).balanceOf(address(this));

        uint256 callFeeAmount = nativeBal.mul(callFee).div(MAX_FEE);
        IERC20(native).safeTransfer(callFeeRecipient, callFeeAmount);

        uint256 coFeeAmount = nativeBal.mul(coFee).div(MAX_FEE);
        IERC20(native).safeTransfer(coFeeRecipient, coFeeAmount);

        uint256 strategistFeeAmount = nativeBal.mul(strategistFee).div(MAX_FEE);
        IERC20(native).safeTransfer(strategist, strategistFeeAmount);

        emit ChargedFees(callFeeAmount, coFeeAmount, strategistFeeAmount);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 balanceOutput = IERC20(output).balanceOf(address(this));
        if (balanceOutput > 0) {
            // swap reward to ETH
            IUniswapV2Router(uniRouter).swapExactTokensForTokens(
                balanceOutput,
                0,
                outputToEthRoute,
                address(this),
                block.timestamp
            );

            uint256 ethHalf = IERC20(eth).balanceOf(address(this)).div(2);
            ISolidlyRouter(thenaRouter).swapExactTokensForTokens(
                ethHalf,
                0,
                ethToChamRoute,
                address(this),
                block.timestamp
            );

            uint256 ethBal = IERC20(eth).balanceOf(address(this));
            uint256 chamBal = IERC20(cham).balanceOf(address(this));
            ISolidlyRouter(thenaRouter).addLiquidity(
                eth,
                cham,
                false,
                ethBal,
                chamBal,
                1,
                1,
                address(this),
                block.timestamp
            );
        }
    }

    // calculate the total underlying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount, ) = IFarming(masterChef).userInfo(
            poolId,
            address(this)
        );
        return _amount;
    }

    function setPendingRewardsFunctionName(
        string calldata _pendingRewardsFunctionName
    ) external onlyManager {
        pendingRewardsFunctionName = _pendingRewardsFunctionName;
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        string memory signature = StringUtils.concat(
            pendingRewardsFunctionName,
            "(uint256,address)"
        );
        bytes memory result = Address.functionStaticCall(
            masterChef,
            abi.encodeWithSignature(signature, poolId, address(this))
        );
        return abi.decode(result, (uint256));
    }

    // native reward amount for calling harvest
    function callReward() public view returns (uint256) {
        uint256 outputBal = rewardsAvailable();
        uint256 nativeOut;
        if (outputBal > 0) {
            uint256[] memory amountOut = IUniswapV2Router(uniRouter)
                .getAmountsOut(outputBal, outputToNativeRoute);
            nativeOut = amountOut[amountOut.length - 1];
        }

        return
            nativeOut.mul(totalPerformanceFee).div(PERCENTAGE).mul(callFee).div(
                MAX_FEE
            );
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "Strategy: VAULT_ONLY");
        IFarming(masterChef).emergencyWithdraw(poolId);
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        IFarming(masterChef).emergencyWithdraw(poolId);
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
        IERC20(want).safeApprove(masterChef, type(uint256).max);
        IERC20(output).safeApprove(uniRouter, type(uint256).max);

        IERC20(cham).safeApprove(thenaRouter, 0);
        IERC20(cham).safeApprove(thenaRouter, type(uint256).max);

        IERC20(eth).safeApprove(thenaRouter, 0);
        IERC20(eth).safeApprove(thenaRouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(masterChef, 0);
        IERC20(output).safeApprove(uniRouter, 0);
        IERC20(eth).safeApprove(thenaRouter, 0);
        IERC20(cham).safeApprove(thenaRouter, 0);
    }

    function outputToNative() external view returns (address[] memory) {
        return outputToNativeRoute;
    }

    function setThenaRouter(address _thenaRouter) external onlyOwner {
        thenaRouter = _thenaRouter;
    }
}