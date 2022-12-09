//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IUniswapV2Router02.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../interfaces/pancake/IMasterChefV2.sol";
import "../../interfaces/IByalan.sol";

import "../ByalanIsland.sol";
import "../Sailor.sol";

contract PancakeByalanLPV2 is ByalanIsland, Sailor, IByalan {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // Tokens used
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public immutable override want;
    address public immutable lpToken0;
    address public immutable lpToken1;

    // Third party contracts
    address public constant MASTERCHEF = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;
    uint256 public immutable pid;

    // Routes
    address[] public cakeToWbnbRoute;
    address[] public cakeToLp0Route;
    address[] public cakeToLp1Route;

    event Harvest(address indexed harvester);

    constructor(
        address _hydra,
        address _izlude,
        address _kswFeeRecipient,
        address _treasuryFeeRecipient,
        address _harvester,
        uint256 _pid,
        address[] memory _cakeToLp0Route,
        address[] memory _cakeToLp1Route
    )
        ByalanIsland(
            _hydra,
            0x10ED43C718714eb63d5aA57B78B54704E256024E,
            _izlude,
            _kswFeeRecipient,
            _treasuryFeeRecipient,
            _harvester
        )
    {
        pid = _pid;

        want = IMasterChefV2(MASTERCHEF).lpToken(_pid);
        lpToken0 = IUniswapV2Pair(want).token0();
        lpToken1 = IUniswapV2Pair(want).token1();

        cakeToWbnbRoute = [CAKE, WBNB];
        if (lpToken0 != CAKE) {
            require(_cakeToLp0Route[0] == CAKE, "invalid lp 0 route");
            require(_cakeToLp0Route[_cakeToLp0Route.length - 1] == lpToken0, "invalid lp 0 route");
            require(
                IUniswapV2Router02(unirouter).getAmountsOut(1 ether, _cakeToLp0Route)[_cakeToLp0Route.length - 1] > 0,
                "invalid lp 0 route"
            );
            cakeToLp0Route = _cakeToLp0Route;
        }

        if (lpToken1 != CAKE) {
            require(_cakeToLp1Route[0] == CAKE, "invalid lp 1 route");
            require(_cakeToLp1Route[_cakeToLp1Route.length - 1] == lpToken1, "invalid lp 1 route");
            require(
                IUniswapV2Router02(unirouter).getAmountsOut(1 ether, _cakeToLp1Route)[_cakeToLp1Route.length - 1] > 0,
                "invalid lp 1 route"
            );
            cakeToLp1Route = _cakeToLp1Route;
        }

        _giveAllowances();
    }

    /**
     * @dev Function to synchronize balances before new user deposit.
     */
    function beforeDeposit() external override {}

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IMasterChefV2(MASTERCHEF).deposit(pid, wantBal);
        }
    }

    function withdraw(uint256 _amount) external override onlyIzlude {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IMasterChefV2(MASTERCHEF).withdraw(pid, _amount - wantBal);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(izlude, wantBal);
    }

    // compounds earnings and charges performance fee
    function harvest() external override whenNotPaused onlyEOA onlyHarvester gasThrottle {
        IMasterChefV2(MASTERCHEF).deposit(pid, 0);
        chargeFees();
        addLiquidity();
        deposit();

        emit Harvest(msg.sender);
    }

    // performance fees
    function chargeFees() internal {
        uint256 toBnb = (IERC20(CAKE).balanceOf(address(this)) * totalFee) / MAX_FEE;
        IUniswapV2Router02(unirouter).swapExactTokensForETH(toBnb, 0, cakeToWbnbRoute, address(this), block.timestamp);

        uint256 bnbBal = address(this).balance;

        uint256 callFeeAmount = (bnbBal * callFee) / feeSum;
        payable(msg.sender).sendValue(callFeeAmount);

        uint256 treasuryFeeAmount = (bnbBal * treasuryFee) / feeSum;
        payable(treasuryFeeRecipient).sendValue(treasuryFeeAmount);

        uint256 kswFeeAmount = (bnbBal * kswFee) / feeSum;
        payable(kswFeeRecipient).sendValue(kswFeeAmount);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 cakeHalf = IERC20(CAKE).balanceOf(address(this)) / 2;

        if (lpToken0 != CAKE) {
            IUniswapV2Router02(unirouter).swapExactTokensForTokens(
                cakeHalf,
                0,
                cakeToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != CAKE) {
            IUniswapV2Router02(unirouter).swapExactTokensForTokens(
                cakeHalf,
                0,
                cakeToLp1Route,
                address(this),
                block.timestamp
            );
        }

        IUniswapV2Router02(unirouter).addLiquidity(
            lpToken0,
            lpToken1,
            IERC20(lpToken0).balanceOf(address(this)),
            IERC20(lpToken1).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() external view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        return IMasterChefV2(MASTERCHEF).userInfo(pid, address(this)).amount;
    }

    function balanceOfMasterChef() external view override returns (uint256) {
        return IERC20(want).balanceOf(MASTERCHEF);
    }

    function pendingRewardTokens()
        external
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        rewardTokens = new IERC20[](1);
        rewardAmounts = new uint256[](1);
        rewardTokens[0] = IERC20(CAKE);
        rewardAmounts[0] =
            IMasterChefV2(MASTERCHEF).pendingCake(pid, address(this)) +
            IERC20(CAKE).balanceOf(address(this));
    }

    // called as part of strategy migration. Sends all the available funds back to the vault.
    function retireStrategy() external override onlyIzlude {
        IMasterChefV2(MASTERCHEF).emergencyWithdraw(pid);

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(izlude, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() external override onlyHydra {
        pause();
        IMasterChefV2(MASTERCHEF).emergencyWithdraw(pid);
    }

    function pause() public override onlyHydra {
        _pause();

        _removeAllowances();
    }

    function unpause() external override onlyHydra {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function paused() public view override(IByalan, Pausable) returns (bool) {
        return super.paused();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(MASTERCHEF, type(uint256).max);
        IERC20(CAKE).safeApprove(unirouter, type(uint256).max);

        // lp token 0 and 1 maybe cake so approve 0 is needed here
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(MASTERCHEF, 0);
        IERC20(CAKE).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }

    receive() external payable {
        require(msg.sender == unirouter, "reject");
    }
}