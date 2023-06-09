//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/token/IERC20.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/ILGEToken.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IXVIX.sol";
import "./interfaces/IFloor.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract Distributor is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant FLOOR_BASIS_POINTS = 5000;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    bool public isInitialized;

    uint256 public lgeEndTime;
    uint256 public lpUnlockTime;
    bool public lgeIsActive;
    uint256 public ethReceived;

    address public xvix;
    address public weth;
    address public dai;
    address public lgeTokenWETH;
    address public lgeTokenDAI;
    address public floor;
    address public minter;
    address public router; // uniswap router
    address public factory; // uniswap factory
    address[] public path;

    address public gov;

    event Join(address indexed account, uint256 value);
    event RemoveLiquidity(address indexed to, address lgeToken, uint256 amountLGEToken);
    event EndLGE();

    constructor() public {
        lgeIsActive = true;
        gov = msg.sender;
    }

    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }

    function initialize(
        address[] memory _addresses,
        uint256 _lgeEndTime,
        uint256 _lpUnlockTime
    ) public nonReentrant {
        require(msg.sender == gov, "Distributor: forbidden");
        require(!isInitialized, "Distributor: already initialized");
        isInitialized = true;

        xvix = _addresses[0];
        weth = _addresses[1];
        dai = _addresses[2];
        lgeTokenWETH = _addresses[3];
        lgeTokenDAI = _addresses[4];
        floor = _addresses[5];
        minter = _addresses[6];
        router = _addresses[7];
        factory = _addresses[8];

        require(ILGEToken(lgeTokenWETH).token() == weth, "Distributor: misconfigured lgeTokenWETH");
        require(ILGEToken(lgeTokenDAI).token() == dai, "Distributor: misconfigured lgeTokenDAI");

        path.push(weth);
        path.push(dai);

        lgeEndTime = _lgeEndTime;
        lpUnlockTime = _lpUnlockTime;
    }

    function join(address _receiver, uint256 _minDAI, uint256 _deadline) public payable nonReentrant {
        require(lgeIsActive, "Distributor: LGE has ended");
        require(msg.value > 0, "Distributor: insufficient value");

        uint256 floorETH = msg.value.mul(FLOOR_BASIS_POINTS).div(BASIS_POINTS_DIVISOR);
        (bool success,) = floor.call{value: floorETH}("");
        require(success, "Distributor: transfer to floor failed");

        uint256 toSwap = msg.value.sub(floorETH).div(2);
        IUniswapV2Router(router).swapExactETHForTokens{value: toSwap}(
            _minDAI,
            path,
            address(this),
            _deadline
        );

        ILGEToken(lgeTokenWETH).mint(_receiver, msg.value);
        ILGEToken(lgeTokenDAI).mint(_receiver, msg.value);
        ethReceived = ethReceived.add(msg.value);

        emit Join(_receiver, msg.value);
    }

    function endLGE(uint256 _deadline) public nonReentrant {
        require(lgeIsActive, "Distributor: LGE already ended");
        if (block.timestamp < lgeEndTime) {
            require(msg.sender == gov, "Distributor: forbidden");
        }

        lgeIsActive = false;

        // update the rebase divisor so that it will not suddenly increase
        // on the first XVIX transfer
        IXVIX(xvix).rebase();

        uint256 totalXVIX = IERC20(xvix).balanceOf(address(this));
        require(totalXVIX > 0, "Distributor: insufficient XVIX");

        uint256 amountXVIX = totalXVIX.div(2);

        _addLiquidityETH(_deadline, amountXVIX);
        _addLiquidityDAI(_deadline, amountXVIX);

        // for simplicity, assume that the minter starts with the exact number of XVIX tokens
        // as the Distributor
        // 1/2 of the XVIX owned by the Distributor and 1/4 of the ETH received by the Distributor
        // is sent to the XVIX / ETH pair
        // this would give a price of (total XVIX) / (1/2 ETH received)
        //
        // initializing the minter with the ethReceived value will let it have a
        // starting price of (total XVIX) / (ETH received)
        // which would be twice the starting price of the XVIX / ETH Uniswap pair
        IMinter(minter).enableMint(ethReceived);

        emit EndLGE();
    }

    function removeLiquidityETH(
        uint256 _amountLGEToken,
        uint256 _amountXVIXMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    ) public nonReentrant {
        uint256 amountWETH = _removeLiquidity(
            lgeTokenWETH,
            _amountLGEToken,
            _amountXVIXMin,
            _amountETHMin,
            _to,
            _deadline
        );

        IWETH(weth).withdraw(amountWETH); // convert WETH to ETH

        (bool success,) = _to.call{value: amountWETH}("");
        require(success, "Distributor: ETH transfer failed");
    }

    function removeLiquidityDAI(
        uint256 _amountLGEToken,
        uint256 _amountXVIXMin,
        uint256 _amountTokenMin,
        address _to,
        uint256 _deadline
    ) public nonReentrant {
        uint256 amountDAI = _removeLiquidity(
            lgeTokenDAI,
            _amountLGEToken,
            _amountXVIXMin,
            _amountTokenMin,
            _to,
            _deadline
        );

        IERC20(dai).transfer(_to, amountDAI);
    }

    function _removeLiquidity(
        address _lgeToken,
        uint256 _amountLGEToken,
        uint256 _amountXVIXMin,
        uint256 _amountTokenMin,
        address _to,
        uint256 _deadline
    ) private returns (uint256) {
        require(!lgeIsActive, "Distributor: LGE has not ended");
        require(block.timestamp >= lpUnlockTime, "Distributor: unlock time not yet reached");

        uint256 liquidity = _getLiquidityAmount(_lgeToken, _amountLGEToken);

        // burn after calculating liquidity because _getLiquidityAmount uses
        // lgeToken.totalSupply to calculate liquidity
        ILGEToken(_lgeToken).burn(msg.sender, _amountLGEToken);

        if (liquidity == 0) { return 0; }

        address pair = _getPair(_lgeToken);
        IERC20(pair).approve(router, liquidity);

        IUniswapV2Router(router).removeLiquidity(
            xvix,
            ILGEToken(_lgeToken).token(),
            liquidity,
            _amountXVIXMin,
            _amountTokenMin,
            address(this),
            _deadline
        );

        uint256 amountXVIX = IERC20(xvix).balanceOf(address(this));
        uint256 amountToken = IERC20(ILGEToken(_lgeToken).token()).balanceOf(address(this));

        uint256 refundBasisPoints = _getRefundBasisPoints(_lgeToken, _amountLGEToken, amountToken);
        uint256 refundAmount = amountXVIX.mul(refundBasisPoints).div(BASIS_POINTS_DIVISOR);

        // burn XVIX to refund the XLGE participant
        if (refundAmount > 0) {
            IFloor(floor).refund(_to, refundAmount);
        }

        // permanently remove the remaining XVIX by burning
        // and reducing xvix.maxSupply
        uint256 toastAmount = amountXVIX.sub(refundAmount);
        if (toastAmount > 0) {
            IXVIX(xvix).toast(toastAmount);
        }

        emit RemoveLiquidity(_to, _lgeToken, _amountLGEToken);

        return amountToken;
    }

    function _getRefundBasisPoints(
        address _lgeToken,
        uint256 _amountLGEToken,
        uint256 _amountToken
    ) private view returns (uint256) {
        // lgeTokenWETH.refBalance: total ETH holdings at endLGE
        // lgeTokenWETH.refSupply: totalSupply of lgeTokenWETH at endLGE
        // lgeTokenDAI.refBalance: total DAI holdings at endLGE
        // lgeTokenDAI.refSupply: totalSupply of lgeTokenDAI at endLGE
        uint256 refBalance = ILGEToken(_lgeToken).refBalance();
        uint256 refSupply = ILGEToken(_lgeToken).refSupply();
        // refAmount is the proportional amount of WETH or DAI
        // that the user contributed for the given amountLGEToken
        uint256 refAmount = _amountLGEToken.mul(refBalance).div(refSupply);

        // if the user contributed 1 ETH, this ETH is split into:
        // Floor: 0.5 ETH
        // XVIX / ETH LP: 0.25 ETH
        // XVIX / DAI LP: 0.25 ETH worth of DAI
        // the user would then be issued 1 lgeTokenWETH and 1 lgeTokenDAI
        // each lgeToken entitles the user to assets worth ~0.5 ETH
        // e.g. 1 lgeTokenWETH entitles to the user to 0.25 ETH from the XVIX / ETH LP
        // and XVIX worth 0.25 ETH, redeemable from the Floor
        //
        // if the user wants to redeem an _amountLGEToken of 0.8 for lgeTokenWETH
        // refAmount would be 0.2, 0.8 * 0.25 / 1
        // the minExpectedAmount would be 0.4, 0.2 * 2
        uint256 minExpectedAmount = refAmount.mul(2);

        // amountToken is the amount of WETH / DAI already retrieved from
        // removing liquidity
        // if the price of XVIX has doubled, the amount of WETH / DAI retrieved
        // would be doubled as well, so no refund of XVIX is required
        if (_amountToken >= minExpectedAmount) { return 0; }

        // if the price of XVIX has not doubled, some refund would be required
        // e.g. minExpectedAmount is 0.4 and amountToken is 0.3
        // in this case, diff would be 0.1
        // and refundBasisPoints would be 5000, 0.1 * 10,000 / 0.2
        // so 50% of the XVIX retrieved from removing liquidity would be
        // burnt to redeem ETH for the user
        uint256 diff = minExpectedAmount.sub(_amountToken);
        uint256 refundBasisPoints = diff.mul(BASIS_POINTS_DIVISOR).div(refAmount);

        if (refundBasisPoints >= BASIS_POINTS_DIVISOR) {
            return BASIS_POINTS_DIVISOR;
        }

        return refundBasisPoints;
    }

    function _getLiquidityAmount(address _lgeToken, uint256 _amountLGEToken) private view returns (uint256) {
        address pair = _getPair(_lgeToken);
        uint256 pairBalance = IERC20(pair).balanceOf(address(this));
        uint256 totalSupply = IERC20(_lgeToken).totalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        // each lgeToken represents a percentage ownership of the
        // liquidity in the XVIX / WETH or XVIX / DAI Uniswap pair
        // e.g. if there are 10 lgeTokens and _amountLGEToken is 1
        // then the liquidity owned by that 1 token is
        // 1 / 10 * (total liquidity owned by this contract)
        return pairBalance.mul(_amountLGEToken).div(totalSupply);
    }

    function _getPair(address _lgeToken) private view returns (address) {
        return IUniswapV2Factory(factory).getPair(xvix, ILGEToken(_lgeToken).token());
    }

    function _addLiquidityETH(uint256 _deadline, uint256 _amountXVIX) private {
        uint256 amountETH = address(this).balance;
        require(amountETH > 0, "Distributor: insufficient ETH");

        IERC20(xvix).approve(router, _amountXVIX);

        IUniswapV2Router(router).addLiquidityETH{value: amountETH}(
            xvix, // token
            _amountXVIX, // amountTokenDesired
            0, // amountTokenMin
            0, // amountETHMin
            address(this), // to
            _deadline // deadline
        );

        ILGEToken(lgeTokenWETH).setRefBalance(amountETH);
        uint256 totalSupply = IERC20(lgeTokenWETH).totalSupply();
        ILGEToken(lgeTokenWETH).setRefSupply(totalSupply);
    }

    function _addLiquidityDAI(uint256 _deadline, uint256 _amountXVIX) private {
        uint256 amountDAI = IERC20(dai).balanceOf(address(this));
        require(amountDAI > 0, "Distributor: insufficient DAI");

        IERC20(xvix).approve(router, _amountXVIX);
        IERC20(dai).approve(router, amountDAI);

        IUniswapV2Router(router).addLiquidity(
            xvix, // tokenA
            dai, // tokenB
            _amountXVIX, // amountADesired
            amountDAI, // amountBDesired
            0, // amountAMin
            0, // amountBMin
            address(this), // to
            _deadline // deadline
        );

        ILGEToken(lgeTokenDAI).setRefBalance(amountDAI);
        uint256 totalSupply = IERC20(lgeTokenDAI).totalSupply();
        ILGEToken(lgeTokenDAI).setRefSupply(totalSupply);
    }
}