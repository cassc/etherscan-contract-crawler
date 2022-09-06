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
    uint256 public deadline = 6000;
    address public mevUser;
    ILendingPoolAddressesProvider public immutable addressProvider;
    ILendingPool public immutable lendingPool;
    address public token0;
    address public token1;
    address public poolA;
    address public poolB;
    address public poolC;
    address constant factoryA = 0x1F98431c8aD98523631AE4a59f267346ea31F984; //Address for UniswapV3 factory
    address constant factoryB = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac; //Address for SushiSwap factory
    address constant factoryC = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //Address for UniswapV2 factory
    address constant routerA = 0xE592427A0AEce92De3Edee1F18E0157C05861564; //Address for UniswapV3 router
    address constant routerB = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; //Address for SushiSwap router
    address constant routerC = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Address for UniswapV2 router
    bytes public byteRouterB = "0x001";
    bytes public byteRouterC = "0x002";
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    bool public minProfitEnabled;
    uint256 public minProfit;
    uint256 public minerNumerator = 500;
    uint256 constant minerDenominator = 1000;
    uint256 gasReimbursement = 100;
    uint256 public slippage = 50;
    uint256 constant slippageDenom = 10000;
    uint24 public fee;

    event ExecuteSwap(
        address indexed initiator,
        uint256 amountInvested,
        uint256 amountGained,
        uint256 premium,
        uint256 minerFee,
        uint256 profit,
        uint256 time
    );

    event Withdraw(address indexed user, uint256 amountWithdraw);

    struct Adjustments {
        address adjustmentPool;
        address adjustmentToken0;
        uint256 adjustment0;
        uint256 adjustment1;
    }

    struct OrderedReserves {
        address pool1;
        uint256 pool1Reserve0;
        uint256 pool1Reserve1;
    }

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
        poolC = IUniswapV2Factory(factoryC).getPair(_token0, _token1);
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
    function updateMinProft(uint256 _minProfit) external onlyOwner {
        minProfit = _minProfit;
    }

    // Update the numerator percentage for paying the miner.
    function updateMinerNumerator(uint256 _minerNumerator) external onlyOwner {
        minerNumerator = _minerNumerator;
    }

    // Updates the swap deadline
    function updateDeadline(uint256 _deadline) external onlyOwner {
        deadline = _deadline;
    }

    // Updates the swap slippage
    function updateSlippage(uint256 _slippage) external onlyOwner {
        slippage = _slippage;
    }

    // Withdraw tokens from the contract
    // To deposit, just simply send tokens to the contract address
    function withdraw(uint256 _amount, address _token) external onlyOwner {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        require(_amount <= _balance && _balance > 0, "Invalid amount");
        if (_balance > 0) IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function baseTokenBalance() external view returns (uint256 _balance) {
        _balance = IERC20(token0).balanceOf(address(this));
    }

    // Incorporate mempool adjustments to each token in the token pair
    // This could come from uniswap or sushi
    function _getReserves(address _pool1, address _token0)
        internal
        view
        returns (OrderedReserves memory _orderReserves)
    {
        (uint256 _pool1Reserve0, uint256 _pool1Reserve1, ) = IUniswapV2Pair(
            _pool1
        ).getReserves();

        address _pool1Token0 = IUniswapV2Pair(_pool1).token0();

        _orderReserves.pool1 = _pool1;

        if (_token0 == _pool1Token0) {
            _orderReserves.pool1Reserve0 = _pool1Reserve0;
            _orderReserves.pool1Reserve1 = _pool1Reserve1;
        } else {
            _orderReserves.pool1Reserve1 = _pool1Reserve0;
            _orderReserves.pool1Reserve0 = _pool1Reserve1;
        }
    }

    function swapWithoutLoan(uint256 amountIn0,
        bytes memory _params) public onlyMEVUser returns (uint256 amountOut) {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amountIn0);
        amountOut = _swap(amountIn0, msg.sender, _params);
        IERC20(token0).safeTransfer(msg.sender, amountOut);
    }

    // Used if the base token is an ERC20 token
    function _swap(
        uint256 amountIn0,
        address _sender,
        bytes memory _params
    ) internal returns (uint256 amountOut1) {
        OrderedReserves memory _orderReserves;
        if (keccak256(_params) == keccak256(byteRouterB)) {
            _orderReserves = _getReserves(poolB, token0);
        }
        else {
            _orderReserves = _getReserves(poolC, token0);
        }

        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                token0,
                token1,
                fee,
                _sender,
                deadline,
                amountIn0,
                amountOutMinimum,
                sqrtPriceLimitX96
            );

        IERC20(token0).approve(routerA, amountIn0);

        uint256 amountOut0 = ISwapRouter(routerA).exactInputSingle(params);

        amountOut1 = IUniswapV2Router01(routerB).getAmountOut(
            amountOut0,
            _orderReserves.pool1Reserve1,
            _orderReserves.pool1Reserve0
        );

        address[] memory path1 = new address[](2);
        path1[0] = token1;
        path1[1] = token0;

        IERC20(token1).approve(routerB, amountOut0);

        // Swap from token1 to token0 on pool1
        IUniswapV2Router01(poolB).swapTokensForExactTokens(
            amountOut1,
            amountOut0,
            path1,
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
        uint256 _netAmount = _swap(amounts[0], address(this), params);

        IERC20(assets[0]).approve(address(lendingPool), amounts[0] + premiums[0]);

        return true;
    }

    // This function calls flashloans to borrow funds.  It will fail, if it doesn't pay back in a single TX.
    function flashArb(uint256 _amount, bytes memory params) public onlyMEVUser {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = address(token0);

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