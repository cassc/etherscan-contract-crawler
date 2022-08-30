// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router01} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {ILendingPool, ILendingPoolAddressesProvider} from "./interfaces/Interfaces.sol";
import {IFlashLoanReceiver, ILendingPoolAddressesProvider, ILendingPool} from "./interfaces/Interfaces.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "./libraries/TransferHelper.sol";

/************
    This contract only works for v2 LP contracts.  Uniswap v3 contracts are not supported. 
***********/
contract MevTest is Ownable, ReentrancyGuard, IFlashLoanReceiver {
    using SafeERC20 for IERC20;
    uint256 public deadline = 20e18;
    address public mevUser;
    ILendingPoolAddressesProvider public immutable addressProvider;
    ILendingPool public immutable lendingPool;
    address public token0;
    address public token1;
    address public poolA;
    address public poolB;
    address constant factoryA = 0x1F98431c8aD98523631AE4a59f267346ea31F984; //Address for UniswapV3 factory
    address constant factoryB = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac; //Address for SushiSwap factory
    address constant routerA = 0xE592427A0AEce92De3Edee1F18E0157C05861564; //Address for UniswapV3 router
    address constant routerB = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; //Address for SushiSwap router
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public minProfitNumerator = 5;
    uint256 public minerNumerator = 500;
    uint256 constant minerDenominator = 1000;
    uint256 constant minProfitDenominator = 1000;
    uint24 public fee;

    event ExecuteSwap(
        address indexed initiator,
        uint256 amountInvested,
        uint256 premium,
        uint256 minerFee,
        uint256 profit,
        uint256 time
    );

    event Withdraw(address indexed user, uint256 amountWithdraw);

    constructor(
        address _addressProvider,
        address _mevUser,
        address _token0,
        address _token1,
        uint24 _fee
    ) {
        mevUser = _mevUser;
        addressProvider = ILendingPoolAddressesProvider(_addressProvider);
        lendingPool = ILendingPool(addressProvider.getLendingPool());
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        poolA = IUniswapV3Factory(factoryA).getPool(_token0, _token1, _fee);
        poolB = IUniswapV2Factory(factoryB).getPair(_token0, _token1);
    }

    modifier onlyMEVUser() {
        require(mevUser == msg.sender, "MEVUser: caller is not the user");
        _;
    }

    // Updates the mev user
    function updateMEVUser(address _user) external onlyOwner {
        mevUser = _user;
    }

    // Updates the minimum profit that the bot must check for.
    function updateMinProfitNumerator(uint256 _minProfitNumerator)
        external
        onlyOwner
    {
        minProfitNumerator = _minProfitNumerator;
    }

    // Update the numerator percentage for paying the miner.
    function updateMinerNumerator(uint256 _minerNumerator) external onlyOwner {
        minerNumerator = _minerNumerator;
    }

    // Updates the swap deadline
    function updateDeadline(uint256 _deadline) external onlyOwner {
        deadline = _deadline;
    }

    function updateFee(uint24 _fee) public onlyOwner {
        fee = _fee;
    }

    // Withdraw tokens from the contract
    // To deposit, just simply send tokens to the contract address
    function withdraw(uint256 _amount, address _token) external onlyOwner {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        require(_amount <= _balance && _balance > 0, "Invalid amount");
        if (_balance > 0) IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function balance()
        external
        view
        returns (uint256 _balance0, uint256 _balance1)
    {
        _balance0 = IERC20(token0).balanceOf(address(this));
        _balance1 = IERC20(token1).balanceOf(address(this));
    }

    function swapWithoutLoan(uint256 amountIn0)
        public
        onlyMEVUser
        returns (
            uint256 amountOut,
            uint256 profitMargin,
            uint256 amountOutAfterProfit
        )
    {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amountIn0);
        (amountOut, profitMargin, amountOutAfterProfit) = _swap(
            amountIn0,
            msg.sender,
            0
        );
    }

    // Used if the base token is an ERC20 token
    function _swap(
        uint256 amountIn0,
        address _sender,
        uint256 _premium
    )
        internal
        returns (
            uint256 amountOut0,
            uint256 profitMargin,
            uint256 amountOutAfterProfit
        )
    {
        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;
        IERC20(token0).approve(routerA, amountIn0);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                token0,
                token1,
                fee,
                address(this),
                deadline,
                amountIn0,
                amountOutMinimum,
                sqrtPriceLimitX96
            );

        amountOut0 = ISwapRouter(routerA).exactInputSingle(params);
        profitMargin = amountOut0 * minProfitNumerator / minProfitDenominator;
        amountOutAfterProfit = amountOut0 + profitMargin;

        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token0;

        IERC20(token1).approve(routerB, amountOutAfterProfit);

        IUniswapV2Router01(routerB).swapTokensForExactTokens(
            amountIn0 + _premium,
            amountOutAfterProfit,
            path,
            _sender,
            deadline
        );
    }

    //Required callback function for flashlloan
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.
        (, uint256 profitMargin, ) = _swap(
            amounts[0],
            address(this),
            premiums[0]
        );

        // Premiums are usually 0.09 % of the loan amount
        uint256 amountOwing = amounts[0] + premiums[0];

        require(profitMargin > 0, "No profit after expenses");
        // Used to pay a percentage of profit to miner.  Default is 50%.
        uint256 _bidAmount = (profitMargin * minerNumerator) / minerDenominator;

        // Checks if the base token is WETH.  If it already is then convert to ETH and send to mev and miner.
        if (token1 == WETH) {
            IWETH(WETH).withdraw(_bidAmount);
            block.coinbase.transfer(_bidAmount);
        }
        // If not then swap to WETH, then convert to ETH and send to mev and miner.
        else {
            IERC20(token1).approve(routerA, _bidAmount);

            ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter
                .ExactInputSingleParams(
                    token1,
                    WETH,
                    fee,
                    address(this),
                    deadline,
                    _bidAmount,
                    1,
                    0
                );

            uint256 wethAmount = ISwapRouter(routerA).exactInputSingle(_params);
            IWETH(WETH).withdraw(wethAmount);
            block.coinbase.transfer(wethAmount);
        }

        IERC20(assets[0]).approve(address(lendingPool), amountOwing);
        emit ExecuteSwap(
            initiator,
            amounts[0],
            premiums[0],
            _bidAmount,
            profitMargin,
            block.timestamp
        );

        return true;
    }

    // This function calls flashloans to borrow funds.  It will fail, if it doesn't pay back in a single TX.
    function flashArb(uint256 _amount, bytes memory params) public onlyMEVUser {
        address receiverAddress = address(this);

        address[] memory assets = new address[](0);
        assets[0] = address(token1);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        uint16 referralCode = 0;

        lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
}