// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPaymentsWithFee.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./interfaces/IFiat24Account.sol";
import "./interfaces/IUSDC.sol";
import "./interfaces/SanctionsList.sol";

error Fiat24UsdcTopUp__NotOperator();
error Fiat24UsdcTopUp__CryptoTopUpSuspended();
error Fiat24UsdcTopUp__NoETHPoolAvailable();
error Fiat24UsdcTopUp__NotSufficientBalance();
error Fiat24UsdcTopUp__NotSufficientAllowance();
error Fiat24UsdcTopUp__ETHAmountMustNotBeZero();
error Fiat24UsdcTopUp__EthRefundFailed();
error Fiat24UsdcTopUp__AddressSanctioned();
error Fiat24UsdcTopUp__AddressUsdcBlackListed();
error Fiat24UsdcTopUp__AmountExceedsMaxTopUpAmount();
error Fiat24UsdcTopUp__AmountBelowMinTopUpAmount();
error Fiat24UsdcTopUp__MonthlyLimitExceeded();
error Fiat24UsdcTopUp__AddressHasNoToken();
error Fiat24UsdcTopUp__TokenIsNotLive();

contract Fiat24UsdcTopUp is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // RINKEBY
    // address public constant WETH_ADDRESS = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // address public constant USDC_ADDRESS = 0x53eFd5F117E51f891d2EC46bc92FC56A60E3D453;

    // MAINNET
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    IUSDC public constant USDC = IUSDC(USDC_ADDRESS);

    uint256 public fee;
    uint256 public slippage;
    uint256 public maxTopUpAmount;
    uint256 public minTopUpAmount;

    IUniswapV3Factory public constant uniswapFactory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IPeripheryPaymentsWithFee public constant peripheryPayments = IPeripheryPaymentsWithFee(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter public constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6); 

    address public usdcTreasuryAddress;
    address public usdcPLAddress;

    bool public blacklistCheck;
    bool public sanctionCheck;
    address public sanctionContractAddress;

    event UsdcTopUp(address indexed sender, address indexed tokenIn, uint256 indexed blockNumber, uint256 usdcAmount);

    function initialize(address usdcTreasuryAddress_, 
                        address usdcPLAddress_,
                        address sanctionContractAddress_,
                        uint256 maxTopUpAmount_,
                        uint256 minTopUpAmount_,
                        uint256 fee_, 
                        uint256 slippage_) public initializer {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        _setupRole(OPERATOR_ROLE, msg.sender);
        usdcTreasuryAddress = usdcTreasuryAddress_;
        usdcPLAddress = usdcPLAddress_;
        sanctionContractAddress = sanctionContractAddress_;
        sanctionCheck = false;
        blacklistCheck = false;
        maxTopUpAmount = maxTopUpAmount_;
        minTopUpAmount = minTopUpAmount_;
        fee = fee_;
        slippage = slippage_;
    }

    function topUpUSDCWithERC20(address tokenIn, uint256 amount) external returns(uint256) {
        if(paused()) {
            revert Fiat24UsdcTopUp__CryptoTopUpSuspended();
        }
        if(sanctionCheck) {
            SanctionsList sanctionsList = SanctionsList(sanctionContractAddress);
            if(sanctionsList.isSanctioned(msg.sender)) {
                revert Fiat24UsdcTopUp__AddressSanctioned();
            }
        }
        if(blacklistCheck) {
            if(USDC.isBlacklisted(msg.sender)) {
                revert Fiat24UsdcTopUp__AddressUsdcBlackListed();
            }
        }
        if(IERC20(tokenIn).balanceOf(msg.sender) < amount) {
            revert Fiat24UsdcTopUp__NotSufficientBalance();
        }
        if(IERC20(tokenIn).allowance(msg.sender, address(this)) < amount) {
            revert Fiat24UsdcTopUp__NotSufficientAllowance();
        }
        uint256 usdcAmount;
        if(tokenIn == USDC_ADDRESS) {
            usdcAmount = amount;
            TransferHelper.safeTransferFrom(USDC_ADDRESS, msg.sender, address(this), amount);
        } else {
            uint24 poolFee = getPoolFeeOfMostLiquidPool(tokenIn, USDC_ADDRESS);
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amount);
            TransferHelper.safeApprove(tokenIn, address(swapRouter), amount);
            if(poolFee == 0) {
                poolFee = getPoolFeeOfMostLiquidPool(tokenIn, WETH_ADDRESS);
                if(poolFee == 0) {
                    revert Fiat24UsdcTopUp__NoETHPoolAvailable();
                }
                uint24 ethUsdcPoolFee = getPoolFeeOfMostLiquidPool(WETH_ADDRESS, USDC_ADDRESS);
                uint256 amountOutMinimum = getQuoteMultihop(tokenIn, WETH_ADDRESS, USDC_ADDRESS, poolFee, ethUsdcPoolFee, amount);
                if(amountOutMinimum > maxTopUpAmount) {
                    revert Fiat24UsdcTopUp__AmountExceedsMaxTopUpAmount();
                }
                if(amountOutMinimum < minTopUpAmount) {
                    revert Fiat24UsdcTopUp__AmountBelowMinTopUpAmount();
                }
                amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
                ISwapRouter.ExactInputParams memory params =
                    ISwapRouter.ExactInputParams({
                        path: abi.encodePacked(tokenIn, poolFee, WETH_ADDRESS, ethUsdcPoolFee, USDC_ADDRESS),
                        recipient: address(this),
                        deadline: block.timestamp,
                        amountIn: amount,
                        amountOutMinimum: amountOutMinimum
                    });
                usdcAmount = swapRouter.exactInput(params);
            } else {
                uint256 amountOutMinimum = getQuoteSingle(tokenIn, USDC_ADDRESS, poolFee, amount);
                amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
                if(amountOutMinimum > maxTopUpAmount) {
                    revert Fiat24UsdcTopUp__AmountExceedsMaxTopUpAmount();
                }
                if(amountOutMinimum < minTopUpAmount) {
                    revert Fiat24UsdcTopUp__AmountBelowMinTopUpAmount();
                }
                ISwapRouter.ExactInputSingleParams memory params =
                    ISwapRouter.ExactInputSingleParams({
                        tokenIn: tokenIn,
                        tokenOut: USDC_ADDRESS,
                        fee: poolFee,
                        recipient: address(this),
                        deadline: block.timestamp + 15,
                        amountIn: amount,
                        amountOutMinimum: amountOutMinimum,
                        sqrtPriceLimitX96: 0
                    });
                usdcAmount = swapRouter.exactInputSingle(params);
            }
        }
        if(usdcAmount > maxTopUpAmount) {
            revert Fiat24UsdcTopUp__AmountExceedsMaxTopUpAmount();
        }
        uint256 usdcFee = usdcAmount.mul(fee).div(100);
        TransferHelper.safeTransfer(USDC_ADDRESS, usdcTreasuryAddress, usdcAmount-usdcFee);
        TransferHelper.safeTransfer(USDC_ADDRESS, usdcPLAddress, usdcFee);
        emit UsdcTopUp(msg.sender, tokenIn, block.number, usdcAmount-usdcFee);
        return usdcAmount-usdcFee;
    }

    function topUpUSDCWithETH() external payable returns(uint256) {
       if(paused()) {
            revert Fiat24UsdcTopUp__CryptoTopUpSuspended();
        }
        if(msg.value == 0) {
            revert Fiat24UsdcTopUp__ETHAmountMustNotBeZero();
        }
        if(sanctionCheck) {
            SanctionsList sanctionsList = SanctionsList(sanctionContractAddress);
            if(sanctionsList.isSanctioned(msg.sender)) {
                revert Fiat24UsdcTopUp__AddressSanctioned();
            }
        }
        if(blacklistCheck) {
            if(USDC.isBlacklisted(msg.sender)) {
                revert Fiat24UsdcTopUp__AddressUsdcBlackListed();
            }
        }
        uint24 poolFee = getPoolFeeOfMostLiquidPool(WETH_ADDRESS, USDC_ADDRESS);
        if(poolFee == 0) {
            revert Fiat24UsdcTopUp__NoETHPoolAvailable();
        }

        uint256 amountOutMinimum = getQuoteSingle(WETH_ADDRESS, USDC_ADDRESS, poolFee, msg.value);
        amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
        if(amountOutMinimum > maxTopUpAmount) {
            revert Fiat24UsdcTopUp__AmountExceedsMaxTopUpAmount();
        }
        if(amountOutMinimum < minTopUpAmount) {
            revert Fiat24UsdcTopUp__AmountBelowMinTopUpAmount();
        }
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH_ADDRESS,
                tokenOut: USDC_ADDRESS,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 15,
                amountIn: msg.value,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        uint256 usdcAmount = swapRouter.exactInputSingle{value: msg.value}(params);

        uint256 usdcFee = usdcAmount.mul(fee).div(100);
        TransferHelper.safeTransfer(USDC_ADDRESS, usdcTreasuryAddress, usdcAmount-usdcFee);
        TransferHelper.safeTransfer(USDC_ADDRESS, usdcPLAddress, usdcFee);
        peripheryPayments.refundETH();
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        if(!success) {
            revert Fiat24UsdcTopUp__EthRefundFailed();
        }
        emit UsdcTopUp(msg.sender, WETH_ADDRESS, block.number, usdcAmount-usdcFee);
        return usdcAmount-usdcFee;
    }

    function getPoolFeeOfMostLiquidPool(address inputToken, address outputToken) public view returns(uint24) {
        uint24 feeOfMostLiquidPool = 0;
        uint128 highestLiquidity = 0;
        uint128 liquidity;
        IUniswapV3Pool pool;
        address poolAddress = uniswapFactory.getPool(inputToken, outputToken, 100);
        if(poolAddress != address(0)) {
            pool = IUniswapV3Pool(poolAddress);
            liquidity = pool.liquidity();
            if(liquidity > highestLiquidity) {
                highestLiquidity = liquidity;
                feeOfMostLiquidPool = 100;
            }
        }
        poolAddress = uniswapFactory.getPool(inputToken, outputToken, 500);
        if(poolAddress != address(0)) {
            pool = IUniswapV3Pool(poolAddress);
            liquidity = pool.liquidity();
            if(liquidity > highestLiquidity) {
                highestLiquidity = liquidity;
                feeOfMostLiquidPool = 500;
            }
        }
        poolAddress = uniswapFactory.getPool(inputToken, outputToken, 3000);
        if(poolAddress != address(0)) {
            pool = IUniswapV3Pool(poolAddress);
            liquidity = pool.liquidity();
            if(liquidity > highestLiquidity) {
                highestLiquidity = liquidity;
                feeOfMostLiquidPool = 3000;
            }
        }
        poolAddress = uniswapFactory.getPool(inputToken, outputToken, 10000);
        if(poolAddress != address(0)) {
            pool = IUniswapV3Pool(poolAddress);
            liquidity = pool.liquidity();
            if(liquidity > highestLiquidity) {
                highestLiquidity = liquidity;
                feeOfMostLiquidPool = 10000;
            }
        }
        return feeOfMostLiquidPool;
    }

    function getQuoteSingle(address tokenIn, address tokenOut, uint24 fee_, uint256 amount) public payable returns(uint256) {
        return quoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee_,
            amount,
            0
        ); 
    }

    function getQuoteMultihop(address tokenIn, address tokenHop, address tokenOut, uint24 poolFee1, uint24 poolFee2, uint256 amount) public payable returns(uint256){
        return quoter.quoteExactInput(
            abi.encodePacked(tokenIn, poolFee1, tokenHop, poolFee2, tokenOut),
            amount
        );
    }

    function changeUsdcTreasuryAddress(address usdcTreasuryAddress_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        usdcTreasuryAddress = usdcTreasuryAddress_;
    }

    function changeUsdcPLAddress(address usdcPLAddress_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        usdcPLAddress = usdcPLAddress_;
    }

    function changeMaxTopUpAmount(uint256 maxTopUpAmount_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        maxTopUpAmount = maxTopUpAmount_;      
    }

    function changeMinTopUpAmount(uint256 minTopUpAmount_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        minTopUpAmount = minTopUpAmount_;      
    }

    function changeFee(uint256 fee_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        fee = fee_;       
    }

    function changeSlippage(uint256 slippage_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        slippage = slippage_;
    }

    function setBlacklistCheck(bool blacklistCheck_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        blacklistCheck = blacklistCheck_;
    }

    function setSanctionCheck(bool sanctionCheck_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        sanctionCheck = sanctionCheck_;
    }

    function setSanctionCheckContract(address sanctionContractAddress_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        sanctionContractAddress = sanctionContractAddress_;
    }

    function pause() public {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        _pause();
    }

    function unpause() public {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24UsdcTopUp__NotOperator();
        }
        _unpause();
    }

    function setupRoleDefaultAdmin(address adminAddress_) external {
        if(!(hasRole(OPERATOR_ROLE, msg.sender))) {
            revert Fiat24UsdcTopUp__NotOperator();
        }
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress_);
    }

    receive() payable external {}
}