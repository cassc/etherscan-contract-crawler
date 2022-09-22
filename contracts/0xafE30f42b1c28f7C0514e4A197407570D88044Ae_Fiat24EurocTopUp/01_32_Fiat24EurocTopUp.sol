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
import "./interfaces/IEUROC.sol";
import "./interfaces/SanctionsList.sol";

error Fiat24EurocTopUp__NotOperator();
error Fiat24EurocTopUp__CryptoTopUpSuspended();
error Fiat24EurocTopUp__NoUSDCPoolAvailable();
error Fiat24EurocTopUp__NotSufficientBalance();
error Fiat24EurocTopUp__NotSufficientAllowance();
error Fiat24EurocTopUp__ETHAmountMustNotBeZero();
error Fiat24EurocTopUp__EthRefundFailed();
error Fiat24EurocTopUp__AddressSanctioned();
error Fiat24EurocTopUp__AddressEurocBlackListed();
error Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
error Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
error Fiat24EurocTopUp__MonthlyLimitExceeded();
error Fiat24EurocTopUp__AddressHasNoToken();
error Fiat24EurocTopUp__TokenIsNotLive();

contract Fiat24EurocTopUp is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // RINKEBY
    // address public constant WETH_ADDRESS = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // address public constant USDC_ADDRESS = 0x53eFd5F117E51f891d2EC46bc92FC56A60E3D453;
    // address public constant EUROC_ADDRESS = 0xc9E42020Cae3f4994443c25da7681a54870e8E5E;

    // MAINNET
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant EUROC_ADDRESS = 0x1aBaEA1f7C830bD89Acc67eC4af516284b1bC33c;

    IEUROC public constant EUROC_CONTRACT = IEUROC(EUROC_ADDRESS);

    uint256 public constant STATUS_LIVE = 5;

    uint256 public constant FOURDECIMALS = 10000;

    uint256 public fee;
    uint256 public slippage;
    uint256 public chfEurRate;
    uint256 public maxTopUpAmount;
    uint256 public minTopUpAmount;

    IUniswapV3Factory public constant uniswapFactory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IPeripheryPaymentsWithFee public constant peripheryPayments = IPeripheryPaymentsWithFee(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter public constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6); 

    address public eurocTreasuryAddress;
    address public eurocPLAddress;

    bool public blacklistCheck;
    bool public sanctionCheck;
    address public sanctionContractAddress;

    IFiat24Account public fiat24Account;

    event EurocTopUp(uint256 indexed tokenId, address indexed sender, address indexed tokenIn, uint256 eurcAmount);

    function initialize(address fiat24AccountAddress_,
                        address eurocTreasuryAddress_, 
                        address eurocPLAddress_,
                        address sanctionContractAddress_,
                        uint256 maxTopUpAmount_,
                        uint256 minTopUpAmount_,
                        uint256 fee_, 
                        uint256 slippage_, 
                        uint256 chfEurRate_) public initializer {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        _setupRole(OPERATOR_ROLE, msg.sender);
        fiat24Account = IFiat24Account(fiat24AccountAddress_);
        eurocTreasuryAddress = eurocTreasuryAddress_;
        eurocPLAddress = eurocPLAddress_;
        sanctionContractAddress = sanctionContractAddress_;
        sanctionCheck = false;
        blacklistCheck = false;
        maxTopUpAmount = maxTopUpAmount_;
        minTopUpAmount = minTopUpAmount_;
        fee = fee_;
        slippage = slippage_;
        chfEurRate = chfEurRate_;
    }

    function topUpEUROCWithERC20(address tokenIn, uint256 amount) external returns(uint256) {
        if(paused()) {
            revert Fiat24EurocTopUp__CryptoTopUpSuspended();
        }
        uint256 tokenId = getTokenByAddress(msg.sender);
        if(tokenId == 0) {
            revert Fiat24EurocTopUp__AddressHasNoToken();
        }
        if(fiat24Account.status(tokenId) != STATUS_LIVE) {
            revert Fiat24EurocTopUp__TokenIsNotLive();
        }
        if(sanctionCheck) {
            SanctionsList sanctionsList = SanctionsList(sanctionContractAddress);
            if(sanctionsList.isSanctioned(msg.sender)) {
                revert Fiat24EurocTopUp__AddressSanctioned();
            }
        }
        if(blacklistCheck) {
            if(EUROC_CONTRACT.isBlacklisted(msg.sender)) {
                revert Fiat24EurocTopUp__AddressEurocBlackListed();
            }
        }
        if(IERC20(tokenIn).balanceOf(msg.sender) < amount) {
            revert Fiat24EurocTopUp__NotSufficientBalance();
        }
        if(IERC20(tokenIn).allowance(msg.sender, address(this)) < amount) {
            revert Fiat24EurocTopUp__NotSufficientAllowance();
        }
        uint24 poolFee = getPoolFeeOfMostLiquidPool(tokenIn, EUROC_ADDRESS);
        uint256 eurocAmount;
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amount);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amount);
        if(poolFee == 0) {
            poolFee = getPoolFeeOfMostLiquidPool(tokenIn, USDC_ADDRESS);
            if(poolFee == 0) {
                revert Fiat24EurocTopUp__NoUSDCPoolAvailable();
            }
            uint24 usdcEurcPoolFee = getPoolFeeOfMostLiquidPool(USDC_ADDRESS, EUROC_ADDRESS);
            uint256 amountOutMinimum = getQuoteMultihop(tokenIn, USDC_ADDRESS, EUROC_ADDRESS, poolFee, usdcEurcPoolFee, amount);
            if(amountOutMinimum > maxTopUpAmount) {
                revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
            }
            if(amountOutMinimum < minTopUpAmount) {
                revert Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
            }
            if(!fiat24Account.checkLimit(tokenId, convertEurToChf(amountOutMinimum.div(FOURDECIMALS)))) {
                revert Fiat24EurocTopUp__MonthlyLimitExceeded();
            }
            amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
            ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(tokenIn, poolFee, USDC_ADDRESS, usdcEurcPoolFee, EUROC_ADDRESS),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amount,
                    amountOutMinimum: amountOutMinimum
                });
            eurocAmount = swapRouter.exactInput(params);
        } else {
            uint256 amountOutMinimum = getQuoteSingle(tokenIn, EUROC_ADDRESS, poolFee, amount);
            amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
            if(amountOutMinimum > maxTopUpAmount) {
                revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
            }
            if(amountOutMinimum < minTopUpAmount) {
                revert Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
            }
            if(!fiat24Account.checkLimit(tokenId, convertEurToChf(amountOutMinimum.div(FOURDECIMALS)))) {
                revert Fiat24EurocTopUp__MonthlyLimitExceeded();
            }
            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: EUROC_ADDRESS,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp + 15,
                    amountIn: amount,
                    amountOutMinimum: amountOutMinimum,
                    sqrtPriceLimitX96: 0
                });
            eurocAmount = swapRouter.exactInputSingle(params);
        }
        if(eurocAmount > maxTopUpAmount) {
            revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
        }
        uint256 eurocFee = eurocAmount.mul(fee).div(100);
        TransferHelper.safeTransfer(EUROC_ADDRESS, eurocTreasuryAddress, eurocAmount-eurocFee);
        TransferHelper.safeTransfer(EUROC_ADDRESS, eurocPLAddress, eurocFee);
        fiat24Account.updateLimit(tokenId, convertEurToChf((eurocAmount-eurocFee).div(FOURDECIMALS)));
        emit EurocTopUp(tokenId, msg.sender, tokenIn, eurocAmount-eurocFee);
        return eurocAmount-eurocFee;
    }

    function topUpEUROCWithETH() external payable returns(uint256) {
       if(paused()) {
            revert Fiat24EurocTopUp__CryptoTopUpSuspended();
        }
        if(msg.value == 0) {
            revert Fiat24EurocTopUp__ETHAmountMustNotBeZero();
        }
        uint256 tokenId = getTokenByAddress(msg.sender);
        if(tokenId == 0) {
            revert Fiat24EurocTopUp__AddressHasNoToken();
        }
        if(fiat24Account.status(tokenId) != STATUS_LIVE) {
            revert Fiat24EurocTopUp__TokenIsNotLive();
        }
        if(sanctionCheck) {
            SanctionsList sanctionsList = SanctionsList(sanctionContractAddress);
            if(sanctionsList.isSanctioned(msg.sender)) {
                revert Fiat24EurocTopUp__AddressSanctioned();
            }
        }
        if(blacklistCheck) {
            if(EUROC_CONTRACT.isBlacklisted(msg.sender)) {
                revert Fiat24EurocTopUp__AddressEurocBlackListed();
            }
        }
        uint24 poolFee = getPoolFeeOfMostLiquidPool(WETH_ADDRESS, EUROC_ADDRESS);
        uint256 eurocAmount;
        if(poolFee == 0) {
            poolFee = getPoolFeeOfMostLiquidPool(WETH_ADDRESS, USDC_ADDRESS);
            if(poolFee == 0) {
                revert Fiat24EurocTopUp__NoUSDCPoolAvailable();
            }
            uint24 usdcEurcPoolFee = getPoolFeeOfMostLiquidPool(USDC_ADDRESS, EUROC_ADDRESS);
            uint256 amountOutMinimum = getQuoteMultihop(WETH_ADDRESS, USDC_ADDRESS, EUROC_ADDRESS, poolFee, usdcEurcPoolFee, msg.value);
            if(amountOutMinimum > maxTopUpAmount) {
                revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
            }
            if(amountOutMinimum < minTopUpAmount) {
                revert Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
            }
            if(!fiat24Account.checkLimit(tokenId, convertEurToChf(amountOutMinimum.div(FOURDECIMALS)))) {
                revert Fiat24EurocTopUp__MonthlyLimitExceeded();
            }
            amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
            ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(WETH_ADDRESS, poolFee, USDC_ADDRESS, usdcEurcPoolFee, EUROC_ADDRESS),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: msg.value,
                    amountOutMinimum: amountOutMinimum
                });
            eurocAmount = swapRouter.exactInput{value: msg.value}(params);
        } else {
            uint256 amountOutMinimum = getQuoteSingle(WETH_ADDRESS, EUROC_ADDRESS, poolFee, msg.value);
            amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
            if(amountOutMinimum > maxTopUpAmount) {
                revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
            }
            if(amountOutMinimum < minTopUpAmount) {
                revert Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
            }
            if(!fiat24Account.checkLimit(tokenId, convertEurToChf(amountOutMinimum.div(FOURDECIMALS)))) {
                revert Fiat24EurocTopUp__MonthlyLimitExceeded();
            }
            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH_ADDRESS,
                    tokenOut: EUROC_ADDRESS,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp + 15,
                    amountIn: msg.value,
                    amountOutMinimum: amountOutMinimum,
                    sqrtPriceLimitX96: 0
                });
            eurocAmount = swapRouter.exactInputSingle{value: msg.value}(params);
        }
        uint256 eurocFee = eurocAmount.mul(fee).div(100);
        TransferHelper.safeTransfer(EUROC_ADDRESS, eurocTreasuryAddress, eurocAmount-eurocFee);
        TransferHelper.safeTransfer(EUROC_ADDRESS, eurocPLAddress, eurocFee);
        peripheryPayments.refundETH();
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        if(!success) {
            revert Fiat24EurocTopUp__EthRefundFailed();
        }
        fiat24Account.updateLimit(tokenId, convertEurToChf((eurocAmount-eurocFee).div(FOURDECIMALS)));
        emit EurocTopUp(tokenId, msg.sender, WETH_ADDRESS, eurocAmount-eurocFee);
        return eurocAmount-eurocFee;
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

    function getTokenByAddress(address owner) internal view returns(uint256) {
        try fiat24Account.tokenOfOwnerByIndex(owner, 0) returns(uint256 tokenid) {
            return tokenid;
        } catch Error(string memory) {
            return fiat24Account.historicOwnership(owner);
        } catch (bytes memory) {
            return fiat24Account.historicOwnership(owner);
        }
    }

    function convertEurToChf(uint256 amount) public view returns(uint256) {
        return amount.mul(chfEurRate).div(1000);
    }

    function changeEurocTreasuryAddress(address eurocTreasuryAddress_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        eurocTreasuryAddress = eurocTreasuryAddress_;
    }

    function changeEurocPLAddress(address eurocPLAddress_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        eurocPLAddress = eurocPLAddress_;
    }

    function changeMaxTopUpAmount(uint256 maxTopUpAmount_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        maxTopUpAmount = maxTopUpAmount_;      
    }

    function changeMinTopUpAmount(uint256 minTopUpAmount_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        minTopUpAmount = minTopUpAmount_;      
    }

    function changeFee(uint256 fee_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        fee = fee_;       
    }

    function changeSlippage(uint256 slippage_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        slippage = slippage_;
    }

    function changeChfEurRate(uint256 chfEurRate_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        chfEurRate = chfEurRate_; 
    }

    function setBlacklistCheck(bool blacklistCheck_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        blacklistCheck = blacklistCheck_;
    }

    function setSanctionCheck(bool sanctionCheck_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        sanctionCheck = sanctionCheck_;
    }

    function setSanctionCheckContract(address sanctionContractAddress_) external {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        sanctionContractAddress = sanctionContractAddress_;
    }

    function pause() public {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        _pause();
    }

    function unpause() public {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        _unpause();
    }

    receive() payable external {}
}