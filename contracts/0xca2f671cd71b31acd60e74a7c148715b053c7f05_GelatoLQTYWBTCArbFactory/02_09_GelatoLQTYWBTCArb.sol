// based on https://etherscan.io/address/0xf9a0e641c98f964b1c732661fab9d5b96af28d49#code
pragma solidity ^0.8.14;

import "../Tools/Interfaces/IUniswapQuoter.sol";
import "../Tools/Interfaces/IUniswapReserve.sol";
import "./Gelato/OpsReady.sol";


interface ICurvePool {
    function get_dy(uint i, uint j, uint dx) external view returns(uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns(uint);
    function exchange(uint i, uint j, uint dx, uint minDy, bool useEth) external payable;
    function exchange_underlying(int128 i, int128 j, uint dx, uint minDy) external returns(uint);
}

interface IGemSeller {
    function getSwapGemAmount(uint lusdQty) external view returns(uint gemAmount, uint feeLusdAmount);
    function swap(uint lusdAmount, uint minGemReturn, address payable dest) external returns(uint);
    function fetchGem2EthPrice() external view returns(uint);
    function fetchEthPrice() external view returns(uint);
    function gemToUSD(uint gemQty, uint gem2EthPrice, uint eth2UsdPrice) external pure returns(uint);
    function USDToGem(uint lusdQty, uint gem2EthPrice, uint eth2UsdPrice) external pure returns(uint);
    function getReturn(uint xQty, uint xBalance, uint yBalance, uint A) external pure returns(uint);
    function compensateForLusdDeviation(uint gemAmount) external view returns(uint newGemAmount);
}

interface ERC20Like {
    function approve(address spender, uint value) external returns(bool);
    function transfer(address to, uint value) external returns(bool);
    function balanceOf(address a) external view returns(uint);
}

interface WethLike is ERC20Like {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IUSDT {
    function approve(address spender, uint amount) external;
}


contract GelatoLQTYWBTCArb is OpsReady {
    address constant LQTY = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IGemSeller immutable gemSeller;

    IUniswapReserve constant WBTCLQTY = IUniswapReserve(0xeFd784093dDD12e24231Fa6B792c09d03A4F7B7E);
    IUniswapReserve constant WBTCWETH = IUniswapReserve(0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0);
    IUniswapQuoter constant uniswapQuoter = IUniswapQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 constant MIN_SQRT_RATIO = 4295128739;

    ICurvePool constant threeCrypto = ICurvePool(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
    ICurvePool constant lusdCrv = ICurvePool(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);

    constructor(address _gemSellerAddress, address _ops, address _taskCreator) OpsReady(_ops, _taskCreator) {
        gemSeller = IGemSeller(_gemSellerAddress);
        ERC20Like(WBTC).approve(address(threeCrypto), type(uint256).max);
        IUSDT(USDT).approve(address(lusdCrv), type(uint256).max);
        ERC20Like(LUSD).approve(address(gemSeller), type(uint256).max);
    }

    function getSwapAmount(uint wbtcAmount) public view returns(uint lqtyAmount) {
        // wbtc => usdt => lusd => lqty
        uint usdtAmount = threeCrypto.get_dy(1, 0, wbtcAmount);
        uint lusdAmount = lusdCrv.get_dy_underlying(3, 0, usdtAmount);
        (lqtyAmount,) = gemSeller.getSwapGemAmount(lusdAmount);
    }

    function swap(uint lqtyQty, address lqtyDest, uint minLqtyProfit) external payable returns(uint) {
        WBTCLQTY.swap(address(this), false, int256(lqtyQty), MAX_SQRT_RATIO - 1, new bytes(0));

        uint retVal = ERC20Like(LQTY).balanceOf(address(this));
        require(retVal >= minLqtyProfit, "insufficient arb profit");
        ERC20Like(LQTY).transfer(lqtyDest, retVal);

        return retVal;
     }

    function _uniswapWBTCWETHCallback(
        int256 amount0Delta,
        int256 /* amount1Delta */,
        bytes calldata /* data */
    ) internal {
        if(amount0Delta > 0) {
            ERC20Like(WBTC).transfer(msg.sender, uint(amount0Delta));
        }
    }

    function _uniswapWBTCLQTYCallback(
        int256 /* amount0Delta */,
        int256 amount1Delta,
        bytes calldata /* data */
    ) internal {
        // swap WBTC to LQTY
        //uint wbtcAmount = uint(-1 * amount1Delta);
        uint totalWbtcBal = ERC20Like(WBTC).balanceOf(address(this));

        // pay for gelato fees
        (uint256 fee, address feeToken) = _getFeeDetails();
        uint256 wbtcFeeAmount = uniswapQuoter.quoteExactOutputSingle(
            WBTC,
            WETH,
            500,
            fee,
            MIN_SQRT_RATIO + 1
        );
        require(totalWbtcBal > wbtcFeeAmount, "Gelato fee too high");
        WBTCWETH.swap(address(this), true, int256(wbtcFeeAmount), MIN_SQRT_RATIO + 1, new bytes(0));
        WethLike(WETH).withdraw(fee);
        uint totalEthBal = address(this).balance;
        require(totalEthBal > fee, "Fee > ETH received");
        _transfer(fee, feeToken);

        // wbtc => usdt => lusd => lqty
        threeCrypto.exchange(1, 0, totalWbtcBal - wbtcFeeAmount, 1, false);
        uint usdtBalance = ERC20Like(USDT).balanceOf(address(this));
        uint lusdBalance = lusdCrv.exchange_underlying(3, 0, usdtBalance, 1);

        require(gemSeller.swap(lusdBalance, 1, payable(this)) > 0, "Nothing swapped in GemSeller");

        if(amount1Delta > 0) {
            ERC20Like(LQTY).transfer(msg.sender, uint(amount1Delta));
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        if (msg.sender == address(WBTCWETH)) {
            _uniswapWBTCWETHCallback(amount0Delta, amount1Delta, data);
        } else if (msg.sender == address(WBTCLQTY)) {
            _uniswapWBTCLQTYCallback(amount0Delta, amount1Delta, data);
        } else {
            revert("uniswapV3SwapCallback: invalid sender");
        }
    }

    receive() external payable {}
}