// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./interfaces/IToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ILiquidityManager.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract LMD is OwnableUpgradeable, ILiquidityManager {
    using SafeMath for uint256;
    IERC20 USDC;
    IToken TOKEN;
    address public tokenAddr;
    address public swapPairAddr;
    address public usdcAddr;
    uint256 public amountModifier;
    uint256 public priceBalancerUpperThreshold;
    uint256 public priceBalancerLowerThreshold;
    bool public liquidityManagementEnabled;
    IUniswapV2Router02 private uniSwapRouter;

    uint256 public distributedUsdcTotal;
    uint32 public pricePrecision;
    mapping(address => bool) private adminAddresses;

    function initialize(address router, address usdcContract) external initializer {
        __Ownable_init();

        usdcAddr = usdcContract;
        USDC = ERC20(usdcContract);
        uniSwapRouter = IUniswapV2Router02(router);
        amountModifier = 200;
        pricePrecision = 1000;

        priceBalancerUpperThreshold = 10000;
        priceBalancerLowerThreshold = 8001;
        liquidityManagementEnabled = true;
    }

    modifier adminsOnly() {
        require(
            (_msgSender() == owner() ||
                adminAddresses[_msgSender()] ||
                _msgSender() == address(this)),
            "Access only for Owner and the token contracts"
        );
        _;
    }

    modifier zeroAddressCheck(address addr) {
        require(addr != address(0), "zero address detected");
        _;
    }

    function setThresholds(uint256 upperBound, uint256 lowerBound)
        external
        adminsOnly
    {
        require(
            upperBound > lowerBound,
            "UpperBound needs to be bigger than LowerBound"
        );
        priceBalancerUpperThreshold = upperBound;
        priceBalancerLowerThreshold = lowerBound;
    }

    function setAdmins(address adminAddr, bool value) external onlyOwner {
        adminAddresses[adminAddr] = value;
    }

    function setTokenContractAddr(address tokenContractAddr)
        external
        zeroAddressCheck(tokenContractAddr)
        onlyOwner
    {
        tokenAddr = tokenContractAddr;
        TOKEN = IToken(tokenContractAddr);
        IUniswapV2Factory factory = IUniswapV2Factory(uniSwapRouter.factory());
        swapPairAddr = factory.getPair(tokenAddr, usdcAddr);
    }

    function setSwapPair(address swapPair)
        external
        zeroAddressCheck(swapPair)
        onlyOwner
    {
        swapPairAddr = swapPair;
    }

    function enableLiquidityManager(bool value) external override adminsOnly {
        liquidityManagementEnabled = value;
        //if (value == true) {
            //require(
                //_msgSender() == tokenAddr,
                //"LM can only be reactivated from token contract"
            //);
        //}
    }

    // calculate price based on pair reserves
    function getTokenPrice() public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(swapPairAddr);
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        //Avoid division by zero first time Liquidity is added to LP
        if (Res0 == 0 || Res1 == 0) return 0;
        uint256 usdcReserve = Res0;
        uint256 tokenReserve = Res1;

        address token0 = pair.token0();
        if (token0 == tokenAddr) {
            tokenReserve = Res0;
            usdcReserve = Res1;
        }
        return usdcReserve.div(tokenReserve.div(pricePrecision)); // return amount of token0 needed to buy token1
    }

    function swapTokenForUsdc(
        address to,
        uint256 amountIn,
        uint256 amountOutMin
    ) external override adminsOnly {
        bool success = TOKEN.transferFrom(to, address(this), amountIn);
        require(success, "Transfer of TOKEN failed");
        _swapTokensForUSDC(to, amountIn, amountOutMin);
    }

    function swapUsdcForToken(
        address to,
        uint256 amountIn,
        uint256 amountOutMin
    ) external override adminsOnly zeroAddressCheck(to) {
        uint256 sc = USDC.allowance(to, address(this));
        require(sc >= amountIn, "Allowance too low");
        bool success = USDC.transferFrom(to, address(this), amountIn);
        require(success, "Transfer of USDC failed");

        _swapUSDCForTokens(to, amountIn, amountOutMin);
    }

    function swapTokenForUsdcToWallet(
        address from,
        address destination,
        uint256 tokenAmount,
        uint256 slippage
    ) external override adminsOnly {
        TOKEN.transferFrom(from, address(this), tokenAmount);
        slippage = slippage.mul(100);
        uint256 origTokenPrice = getTokenPrice();
        uint256 desiredAmount = origTokenPrice.mul(tokenAmount).div(
            pricePrecision
        );
        uint256 minAcceptableAmount = desiredAmount.sub(
            desiredAmount.mul(slippage).div(1e4)
        );

        _swapTokensForUSDC(destination, tokenAmount, minAcceptableAmount);
    }

    function _swapTokensForUSDC(
        address destination,
        uint256 tokenAmount,
        uint256 amountOutMin
    ) private {
        require(amountOutMin > 0, "Minimum Output amount can not be zero");
        address[] memory path = new address[](2);
        path[0] = tokenAddr;
        path[1] = usdcAddr;
        bool success = IERC20(tokenAddr).approve(
            address(uniSwapRouter),
            tokenAmount
        );

        require(success, "Approval of TOKEN amount failed");
        uniSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            amountOutMin, // if 0 it accepts any amount of USDC
            path,
            destination,
            block.timestamp
        );
    }

    function _swapUSDCForTokens(
        address destination,
        uint256 usdcAmount,
        uint256 amountOutMin
    ) private {
        require(amountOutMin > 0, "Minimum Output amount can not be zero");
        address[] memory path = new address[](2);
        path[0] = usdcAddr;
        path[1] = tokenAddr;
        bool success = ERC20(usdcAddr).approve(
            address(uniSwapRouter),
            usdcAmount
        );
        require(success, "Approval of USDC amount failed");
        uniSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            usdcAmount,
            amountOutMin, // if 0 it accepts any amount of TOKEN
            path,
            destination,
            block.timestamp
        );
    }

    function rebalance(uint256 amount, bool buyback) external override
    {}

    /**
     * Set address book.
     * @param address_ Address book address.
     * @dev Sets the address book address.
     */
    function setAddressBook(address address_) public onlyOwner
    {
    }
}