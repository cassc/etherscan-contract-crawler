// SPDX-License-Identifier: MIT
//A product of https://keyoflife.fi

pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ISolidlyRouter.sol";
import "./IThenaGauge.sol";
import "./IGasPrice.sol";
import "./FeeManager.sol";

contract KolStrategyThenaDola is Initializable, UUPSUpgradeable, FeeManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Tokens used
    IERC20Upgradeable public want;
    address public  native;
    address public  output;
    address public  lpToken0;
    address public  lpToken1;

    // Third party contracts
    IThenaGauge public  gauge;

    IGasPrice public  gasprice;
    bool public  stable;
    bool public harvestOnDeposit;
    uint256 public lastHarvest;

    address[] public rewards;
    ISolidlyRouter.route[] public outputToNativeRoute;
    ISolidlyRouter.route[] public outputToLp0Route;
    ISolidlyRouter.route[] public outputToLp1Route;

    uint256  lp0Decimals;
    uint256  lp1Decimals;

    event StratHarvest(
        address indexed harvester,
        uint256 wantHarvested,
        uint256 tvl
    );

    /* New code */
    bool feeInDexNative;
    uint256 public totalDexFee;
    uint256 public totalNativeFee;

    uint256 public startingDate;

    uint256 public totalProtocolFee;
    uint256 public protocolFee;
    address public protocolReceiver;

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();

        totalPerformanceFee = 500;          //  5.00%
        callFee=100;                      //  1% of MAX_FEE
        strategistFee=0;                //  0% of MAX_FEE
        coFee = MAX_FEE - (strategistFee + callFee);

        keeper = 0x8B8eAbDAc18360793649Da12a703CCcB85A5dA48;
        strategist = 0x5A4A661594f978db52cD1BBEB36df05E6dd4E143;
        uniRouter = 0xd4ae6eCA985340Dd434D38F470aCCce4DC78D109;
        vault = 0x0000000000000000000000000000000000000000;
        coFeeRecipient = 0x94DC0b13E66ABa9450b3Cc44c2643BBb4C264BC7;

        address dexNative = 0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11; //THE
        address chainNative = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
        address CUSD = 0xFa4BA88Cf97e282c505BEa095297786c16070129; // CUSD
        address DOLA = 0x2F29Bc0FFAF9bff337b31CBe6CB5Fb3bf12e5840; // DOLA

        address _want = 0x7061F52ed4942021924745D454d722E52e057e03; //DOLA-CUSD LP
        address _gauge = 0xC2B56de677e6d35327E1Cf3dAF2357f20a4c8692;//DOLA-CUSD Thena Gauge
        address _gasprice = 0x6D1F6d21a355ba611F8eC6ad9d921b29EE7cB6e3; //GasPrice contract
        address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
        address USDT = 0x55d398326f99059fF775485246999027B3197955; // USDT
        address HAY = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5; //HAY
        address USDPLUS = 0xe80772Eaf6e2E18B651F160Bc9158b2A5caFCA65; //HAY
        want = IERC20Upgradeable(_want);
        gauge = IThenaGauge(_gauge);
        gasprice = IGasPrice(_gasprice);

        bytes memory data;

        bool _stable;
        (, data) = address(want).call(abi.encodeWithSignature("stable()"));
        assembly {
            _stable := mload(add(data, 32))
        }
        stable = _stable;

        ISolidlyRouter.route[] memory _outputToNativeRoute = new ISolidlyRouter.route[](1);
        _outputToNativeRoute[0].from = dexNative; //THE
        _outputToNativeRoute[0].to = chainNative; //WBNB
        _outputToNativeRoute[0].stable = false;

        ISolidlyRouter.route[] memory _outputToLp0Route = new ISolidlyRouter.route[](4);

        _outputToLp0Route[0].from = dexNative; //THE
        _outputToLp0Route[0].to = BUSD;
        _outputToLp0Route[0].stable = false;

        _outputToLp0Route[1].from = BUSD; //WBNB
        _outputToLp0Route[1].to = USDT;
        _outputToLp0Route[1].stable = true;

        _outputToLp0Route[2].from = USDT;
        _outputToLp0Route[2].to = USDPLUS;
        _outputToLp0Route[2].stable = true;

        _outputToLp0Route[3].from = USDPLUS;
        _outputToLp0Route[3].to = CUSD;
        _outputToLp0Route[3].stable = true;

        ISolidlyRouter.route[] memory _outputToLp1Route;

        if (DOLA == chainNative) {
            _outputToLp1Route = new ISolidlyRouter.route[](1);
            _outputToLp1Route[0].from = dexNative; //THE
            _outputToLp1Route[0].to = chainNative; //WBNB
            _outputToLp1Route[0].stable = false;
        }
        else {
            _outputToLp1Route = new ISolidlyRouter.route[](5);

            _outputToLp1Route[0].from = dexNative; //THE
            _outputToLp1Route[0].to = BUSD; //WBNB
            _outputToLp1Route[0].stable = false;

            _outputToLp1Route[1].from = BUSD;
            _outputToLp1Route[1].to = USDT;
            _outputToLp1Route[1].stable = true;

            _outputToLp1Route[2].from = USDT;
            _outputToLp1Route[2].to = USDPLUS;
            _outputToLp1Route[2].stable = true;

            _outputToLp1Route[3].from = USDPLUS;
            _outputToLp1Route[3].to = CUSD;
            _outputToLp1Route[3].stable = true;

            _outputToLp1Route[4].from = CUSD;
            _outputToLp1Route[4].to = DOLA;
            _outputToLp1Route[4].stable = true;
        }

        for (uint i; i < _outputToNativeRoute.length; ++i) {
            outputToNativeRoute.push(_outputToNativeRoute[i]);
        }

        for (uint i; i < _outputToLp0Route.length; ++i) {
            outputToLp0Route.push(_outputToLp0Route[i]);
        }
        for (uint i; i < _outputToLp1Route.length; ++i) {
            outputToLp1Route.push(_outputToLp1Route[i]);
        }

        output = _outputToNativeRoute[0].from;
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1].to;
        lpToken0 = _outputToLp0Route[_outputToLp0Route.length - 1].to;
        lpToken1 = _outputToLp1Route[_outputToLp1Route.length - 1].to;
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

        /*new code*/
        harvestOnDeposit = true;
        feeInDexNative = true;
        startingDate = block.timestamp;
    }

    modifier gasThrottle() {
        require(
            !gasprice.enabled() || tx.gasprice <= gasprice.maxGasPrice(),
            "Strategy: GAS_TOO_HIGH"
        );
        _;
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = want.balanceOf(address(this));

        if (wantBal > 0) {
            gauge.deposit(wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external {
        address _vault = vault;
        require(msg.sender == _vault, "Strategy: VAULT_ONLY");

        uint256 wantBal = want.balanceOf(address(this));
        if (wantBal < _amount) {
            gauge.withdraw(_amount - wantBal);
            wantBal = want.balanceOf(address(this));
        }
        if (wantBal > _amount) {
            wantBal = _amount;
        }
        want.safeTransfer(_vault, wantBal);
        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external virtual override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "Strategy: VAULT_ONLY");
            _harvest(tx.origin);
        }
    }

    function harvest() external virtual gasThrottle onlyEOA {
        _harvest(tx.origin);
    }

    function harvest(
        address callFeeRecipient
    ) external virtual gasThrottle onlyEOA {
        _harvest(callFeeRecipient);
    }

    function managerHarvest() external onlyManager {
        _harvest(tx.origin);
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal whenNotPaused {
        gauge.getReward();
        uint256 outputBal = IERC20Upgradeable(output).balanceOf(address(this));
        if (outputBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            if (protocolFee>0) {
                uint256 _toProtocol = wantHarvested * protocolFee / PERCENTAGE ;
                totalProtocolFee += _toProtocol;
                want.transfer(protocolReceiver, _toProtocol);
            }

            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 outputBal = IERC20Upgradeable(output).balanceOf(address(this));
        uint256 toNative = (outputBal * totalPerformanceFee) / PERCENTAGE;
        totalDexFee += toNative;

        if (feeInDexNative) {
            IERC20Upgradeable(output).safeTransfer(coFeeRecipient, toNative);
            emit ChargedFees(0, toNative, 0);
            return;
        }

        ISolidlyRouter(uniRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            toNative,
            0,
            outputToNativeRoute,
            address(this),
            block.timestamp
        );

        uint256 nativeBal = IERC20Upgradeable(native).balanceOf(address(this));
        totalNativeFee += nativeBal;

        uint256 callFeeAmount = (nativeBal * callFee) / MAX_FEE;
        IERC20Upgradeable(native).safeTransfer(callFeeRecipient, callFeeAmount);

        uint256 coFeeAmount = (nativeBal * coFee) / MAX_FEE;
        IERC20Upgradeable(native).safeTransfer(coFeeRecipient, coFeeAmount);

        uint256 strategistFeeAmount = (nativeBal * strategistFee) / MAX_FEE;
        IERC20Upgradeable(native).safeTransfer(strategist, strategistFeeAmount);

        emit ChargedFees(callFeeAmount, coFeeAmount, strategistFeeAmount);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputBal = IERC20Upgradeable(output).balanceOf(address(this));
        uint256 lp0Amt = outputBal / 2;
        uint256 lp1Amt = outputBal - lp0Amt;
        ISolidlyRouter router = ISolidlyRouter(uniRouter);

        if (stable) {
            uint256 out0 = lp0Amt;
            if (lpToken0 != output) {
                out0 =
                (router.getAmountsOut(lp0Amt, outputToLp0Route)[
                outputToLp0Route.length
                ] * 1e18) /
                lp0Decimals;
            }

            uint256 out1 = lp1Amt;
            if (lpToken1 != output) {
                out1 =
                (router.getAmountsOut(lp1Amt, outputToLp1Route)[
                outputToLp1Route.length
                ] * 1e18) /
                lp1Decimals;
            }

            (uint256 amountA, uint256 amountB, ) = router.quoteAddLiquidity(
                lpToken0,
                lpToken1,
                stable,
                out0,
                out1
            );

            amountA = (amountA * 1e18) / lp0Decimals;
            amountB = (amountB * 1e18) / lp1Decimals;
            uint256 ratio = (((out0 * 1e18) / out1) * amountB) / amountA;
            lp0Amt = (outputBal * 1e18) / (ratio + 1e18);
            lp1Amt = outputBal - lp0Amt;
        }

        if (lpToken0 != output) {
            router.swapExactTokensForTokens(
                lp0Amt,
                0,
                outputToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != output) {
            router.swapExactTokensForTokens(
                lp1Amt,
                0,
                outputToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20Upgradeable(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20Upgradeable(lpToken1).balanceOf(address(this));
        router.addLiquidity(
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

    // calculate the total 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return gauge.earned(address(this));
    }

    // native reward amount for calling harvest
    function callReward() public view returns (uint256) {
        if (feeInDexNative) return 0;
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
        emit SetHarvestOnDeposit(_harvestOnDeposit);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        gauge.withdrawAll();
        uint256 wantBal = want.balanceOf(address(this));
        emit Panic(wantBal);
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
        address _uniRouter = uniRouter;
        want.safeApprove(address(gauge), type(uint).max);
        IERC20Upgradeable(output).safeApprove(_uniRouter, type(uint).max);
        IERC20Upgradeable(lpToken0).safeApprove(_uniRouter, type(uint).max);
        IERC20Upgradeable(lpToken1).safeApprove(_uniRouter, type(uint).max);
        emit GiveAllowances();
    }

    function _removeAllowances() internal {
        address _uniRouter = uniRouter;
        want.safeApprove(address(gauge), 0);
        IERC20Upgradeable(output).safeApprove(_uniRouter, 0);
        IERC20Upgradeable(lpToken0).safeApprove(_uniRouter, 0);
        IERC20Upgradeable(lpToken1).safeApprove(_uniRouter, 0);
        emit RemoveAllowances();
    }

    function _solidlyToRoute(
        ISolidlyRouter.route[] memory _route
    ) internal pure returns (address[] memory) {
        address[] memory route = new address[](_route.length + 1);
        route[0] = _route[0].from;
        for (uint i; i < _route.length; ++i) {
            route[i + 1] = _route[i].to;
        }
        return route;
    }

    function outputToNative() external view returns (address[] memory) {
        ISolidlyRouter.route[] memory _route = outputToNativeRoute;
        return _solidlyToRoute(_route);
    }

    function outputToLp0() external view returns (address[] memory) {
        ISolidlyRouter.route[] memory _route = outputToLp0Route;
        return _solidlyToRoute(_route);
    }

    function outputToLp1() external view returns (address[] memory) {
        ISolidlyRouter.route[] memory _route = outputToLp1Route;
        return _solidlyToRoute(_route);
    }

    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees, uint256 coFees, uint256 strategistFees);
    event GiveAllowances();
    event RemoveAllowances();
    event SetHarvestOnDeposit(bool isEnabled);
    event RetireStrategy(address vault, uint256 amount);
    event Panic(uint256 balance);

    function set_ProtocolFee(uint256 _protocolFee, address _protocolReceiver) external  onlyManager {
        require(_protocolFee <= 200, "FeeManager: protocolFee > 2%");
        require(_protocolReceiver != address(0), "FeeManager: protocolReceiver = address(0)");
        protocolFee = _protocolFee;
        protocolReceiver = _protocolReceiver;
    }

    function updateV2() external onlyOwner {
    }

}