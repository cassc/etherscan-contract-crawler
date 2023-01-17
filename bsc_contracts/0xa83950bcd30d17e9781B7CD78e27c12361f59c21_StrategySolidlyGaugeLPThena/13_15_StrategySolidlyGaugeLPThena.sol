// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/IThenaGauge.sol";
import "../interfaces/IGasPrice.sol";
import "../vault-lp/FeeManager.sol";

contract StrategySolidlyGaugeLPThena is FeeManager {
    using SafeERC20 for IERC20;

    // Tokens used
    address public native;
    address public output;
    address public want;
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public gauge;

    address public gasprice;
    bool public stable;
    bool public harvestOnDeposit;
    uint256 public lastHarvest;

    address[] public rewards;
    ISolidlyRouter.Routes[] public outputToNativeRoute;
    ISolidlyRouter.Routes[] public outputToLp0Route;
    ISolidlyRouter.Routes[] public outputToLp1Route;

    uint256 lp0Decimals;
    uint256 lp1Decimals;

    event StratHarvest(
        address indexed harvester,
        uint256 wantHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(
        uint256 callFees,
        uint256 beefyFees,
        uint256 strategistFees
    );

    constructor(
        address _want,
        address _gauge,
        address _gasprice,
        CommonAddresses memory _commonAddresses,
        ISolidlyRouter.Routes[] memory _outputToNativeRoute,
        ISolidlyRouter.Routes[] memory _outputToLp0Route,
        ISolidlyRouter.Routes[] memory _outputToLp1Route
    ) StratManager(_commonAddresses) {
        want = _want;
        gauge = _gauge;
        gasprice = _gasprice;

        for (uint i; i < _outputToNativeRoute.length; ++i) {
            outputToNativeRoute.push(_outputToNativeRoute[i]);
        }
        for (uint i; i < _outputToLp0Route.length; ++i) {
            outputToLp0Route.push(_outputToLp0Route[i]);
        }
        for (uint i; i < _outputToLp1Route.length; ++i) {
            outputToLp1Route.push(_outputToLp1Route[i]);
        }

        output = outputToNativeRoute[0].from;
        native = outputToNativeRoute[outputToNativeRoute.length - 1].to;
        lpToken0 = outputToLp0Route[outputToLp0Route.length - 1].to;
        lpToken1 = outputToLp1Route[outputToLp1Route.length - 1].to;

        bytes memory data;

        bool _stable;
        (, data) = want.call(abi.encodeWithSignature("stable()"));
        assembly {
            _stable := mload(add(data, 32))
        }
        stable = _stable;

        uint decimals;
        (, data) = lpToken0.call(abi.encodeWithSignature("decimals()"));
        assembly {
            decimals := mload(add(data, add(0x20, 0)))
        }
        lp0Decimals = 10 ** decimals;

        (, data) = lpToken1.call(abi.encodeWithSignature("decimals()"));
        assembly {
            decimals := mload(add(data, add(0x20, 0)))
        }
        lp1Decimals = 10 ** decimals;

        rewards.push(output);
        _giveAllowances();
    }

    modifier gasThrottle() {
        require(
            !IGasPrice(gasprice).enabled() ||
                tx.gasprice <= IGasPrice(gasprice).maxGasPrice(),
            "Strategy: GAS_TOO_HIGH"
        );
        _;
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IThenaGauge(gauge).deposit(wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "Strategy: VAULT_ONLY");

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal < _amount) {
            IThenaGauge(gauge).withdraw(_amount - wantBal);
            wantBal = IERC20(want).balanceOf(address(this));
        }
        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);
        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external virtual override {
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
        IThenaGauge(gauge).getReward();
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
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        uint256 toNative = (outputBal * totalPerformanceFee) / PERCENTAGE;
        ISolidlyRouter(uniRouter).swapExactTokensForTokens(
            toNative,
            0,
            outputToNativeRoute,
            address(this),
            block.timestamp
        );

        uint256 nativeBal = IERC20(native).balanceOf(address(this));

        uint256 callFeeAmount = (nativeBal * callFee) / MAX_FEE;
        IERC20(native).safeTransfer(callFeeRecipient, callFeeAmount);

        uint256 coFeeAmount = (nativeBal * coFee) / MAX_FEE;
        IERC20(native).safeTransfer(coFeeRecipient, coFeeAmount);

        uint256 strategistFeeAmount = (nativeBal * strategistFee) / MAX_FEE;
        IERC20(native).safeTransfer(strategist, strategistFeeAmount);

        emit ChargedFees(callFeeAmount, coFeeAmount, strategistFeeAmount);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        uint256 lp0Amt = outputBal / 2;
        uint256 lp1Amt = outputBal - lp0Amt;

        if (stable) {
            uint256 out0 = (ISolidlyRouter(uniRouter).getAmountsOut(
                lp0Amt,
                outputToLp0Route
            )[outputToLp0Route.length] * 1e18) / lp0Decimals;

            uint256 out1 = (ISolidlyRouter(uniRouter).getAmountsOut(
                lp1Amt,
                outputToLp1Route
            )[outputToLp1Route.length] * 1e18) / lp1Decimals;

            (uint256 amountA, uint256 amountB, ) = ISolidlyRouter(uniRouter)
                .quoteAddLiquidity(lpToken0, lpToken1, stable, out0, out1);

            amountA = (amountA * 1e18) / lp0Decimals;
            amountB = (amountB * 1e18) / lp1Decimals;
            uint256 ratio = (((out0 * 1e18) / out1) * amountB) / amountA;
            lp0Amt = (outputBal * 1e18) / (ratio + 1e18);
            lp1Amt = outputBal - lp0Amt;
        }

        if (lpToken0 != output) {
            ISolidlyRouter(uniRouter).swapExactTokensForTokens(
                lp0Amt,
                0,
                outputToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != output) {
            ISolidlyRouter(uniRouter).swapExactTokensForTokens(
                lp1Amt,
                0,
                outputToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        ISolidlyRouter(uniRouter).addLiquidity(
            lpToken0,
            lpToken1,
            stable,
            lp0Bal,
            lp1Bal,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return IThenaGauge(gauge).balanceOf(address(this));
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return IThenaGauge(gauge).earned(address(this));
    }

    // native reward amount for calling harvest
    function callReward() public view returns (uint256) {
        uint256 outputBal = rewardsAvailable();
        uint256 nativeOut;
        if (outputBal > 0) {
            uint256[] memory amountsOut = ISolidlyRouter(uniRouter)
                .getAmountsOut(outputBal, outputToNativeRoute);
            nativeOut = amountsOut[amountsOut.length - 1];
        }
        return
            (((nativeOut * totalPerformanceFee) / PERCENTAGE) * callFee) /
            MAX_FEE;
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "Strategy: VAULT_ONLY");

        IThenaGauge(gauge).withdrawAll();

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        IThenaGauge(gauge).withdrawAll();
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
        IERC20(want).safeApprove(gauge, type(uint).max);
        IERC20(output).safeApprove(uniRouter, type(uint).max);

        IERC20(lpToken0).safeApprove(uniRouter, 0);
        IERC20(lpToken0).safeApprove(uniRouter, type(uint).max);

        IERC20(lpToken1).safeApprove(uniRouter, 0);
        IERC20(lpToken1).safeApprove(uniRouter, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(gauge, 0);
        IERC20(output).safeApprove(uniRouter, 0);

        IERC20(lpToken0).safeApprove(uniRouter, 0);
        IERC20(lpToken1).safeApprove(uniRouter, 0);
    }

    function _solidlyToRoute(
        ISolidlyRouter.Routes[] memory _route
    ) internal pure returns (address[] memory) {
        address[] memory route = new address[](_route.length + 1);
        route[0] = _route[0].from;
        for (uint i; i < _route.length; ++i) {
            route[i + 1] = _route[i].to;
        }
        return route;
    }

    function outputToNative() external view returns (address[] memory) {
        ISolidlyRouter.Routes[] memory _route = outputToNativeRoute;
        return _solidlyToRoute(_route);
    }

    function outputToLp0() external view returns (address[] memory) {
        ISolidlyRouter.Routes[] memory _route = outputToLp0Route;
        return _solidlyToRoute(_route);
    }

    function outputToLp1() external view returns (address[] memory) {
        ISolidlyRouter.Routes[] memory _route = outputToLp1Route;
        return _solidlyToRoute(_route);
    }
}