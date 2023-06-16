// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "UniERC20.sol";

import "Context.sol";
import "ReentrancyGuard.sol";
import "Initializable.sol";
import "IWETH.sol";
import "IDexRouter.sol";
import "IUniswapV2Router.sol";

contract Port3Aggregator is Context, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;

    address private constant _ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    uint256 private constant _FEE_MOLECULAR = 1e6;

    IWETH public weth;
    address public owner;
    address public feeReceiver;
    uint256 public feeRate; // 8000

    IDexRouter public dexRouter;

    event Swap(
        address indexed _sender,
        string _swapType,
        address _tokenAddr,
        address _targetAddr,
        uint256 _tokenAmount,
        uint256 _returnAmount,
        uint256 _fee,
        uint256[] pools
    );

    /* solium-disable-next-line */
    receive () external payable {
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, "only admin is allowed");
        _;
    }

    function initialize(address _owner, address _weth, address _feeReceiver, address _dexRouter, uint256 _feeRate) external initializer {
        weth = IWETH(_weth);
        owner = _owner;
        feeRate = _feeRate;
        dexRouter = IDexRouter(_dexRouter);
        feeReceiver = _feeReceiver;
    }

    function unoswap(
        address srcToken,
        address targetToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns(uint256 returnAmount) {
        uint256 fee = amount.mul(feeRate).div(_FEE_MOLECULAR);
        uint256 totalAmount = amount.add(fee);

        if (srcToken == _ZERO_ADDRESS) {
            require(totalAmount == msg.value, "Amount is wrong");

            payable(feeReceiver).transfer(fee);
            returnAmount = dexRouter.unoswapTo{value: amount}(msg.sender, srcToken, amount, minReturn, pools);
        } else {
            require(IERC20(srcToken).balanceOf(msg.sender) >= totalAmount, "Insufficient token balance");
            require(IERC20(srcToken).allowance(msg.sender, address(this)) >= totalAmount, "Approve Insufficient balance");

            IERC20(srcToken).safeTransferFrom(msg.sender, address(this), totalAmount);
            IERC20(srcToken).safeTransfer(feeReceiver, fee);

            IERC20(srcToken).forceApprove(address(dexRouter), amount);
            returnAmount = dexRouter.unoswapTo(msg.sender, srcToken, amount, minReturn, pools);
        }

        emit Swap(msg.sender, "uno", srcToken, targetToken, amount, returnAmount, fee, pools);
    }

    function uniswapV3Swap(
        address srcToken,
        address targetToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns(uint256 returnAmount) {
        uint256 fee = amount.mul(feeRate).div(_FEE_MOLECULAR);
        uint256 totalAmount = amount.add(fee);

        if (srcToken == _ZERO_ADDRESS) {
            require(totalAmount == msg.value, "Amount is wrong");

            payable(feeReceiver).transfer(fee);
            returnAmount = dexRouter.uniswapV3SwapTo{value: amount}(msg.sender, amount, minReturn, pools);
        } else {
            require(IERC20(srcToken).balanceOf(msg.sender) >= totalAmount, "Insufficient token balance");
            require(IERC20(srcToken).allowance(msg.sender, address(this)) >= totalAmount, "Approve Insufficient balance");

            IERC20(srcToken).safeTransferFrom(msg.sender, address(this), totalAmount);
            IERC20(srcToken).safeTransfer(feeReceiver, fee);

            IERC20(srcToken).forceApprove(address(dexRouter), amount);
            returnAmount = dexRouter.uniswapV3SwapTo(msg.sender, amount, minReturn, pools);
        }

        emit Swap(msg.sender, "uniswapV3", srcToken, targetToken, amount, returnAmount, fee, pools);
    }

    function swapEth(uint256 amount) external payable returns (uint256 returnAmount) {
        bool wrapWeth = msg.value > 0;

        uint256 fee = amount.mul(feeRate).div(_FEE_MOLECULAR);
        uint256 totalAmount = amount.add(fee);

        if (wrapWeth) {
            require(msg.value == totalAmount, "Value invalid");

            payable(feeReceiver).transfer(fee);

            returnAmount = dexRouter.swapEthTo{value: amount}(msg.sender, amount);
        } else {
            require(weth.balanceOf(msg.sender) >= totalAmount, "Insufficient token balance");
            require(weth.allowance(msg.sender, address(this)) >= totalAmount, "Approve Insufficient balance");

            weth.transferFrom(msg.sender, address(this), totalAmount);
            weth.transfer(feeReceiver, fee);

            IERC20(weth).forceApprove(address(dexRouter), amount);
            returnAmount = dexRouter.swapEthTo(msg.sender, amount);
        }

        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(uint160(address(weth)));
        emit Swap(msg.sender, "wrap", wrapWeth ? address(0) : address(weth), wrapWeth ? address(weth) : address(0), amount, amount, fee, pools);
    }

    function getSwapAmounts(address router, bool isOut, uint256 amount, address[] calldata path) public view returns (uint256[] memory) {
        if (isOut) {
            return IUniswapV2Router(router).getAmountsOut(amount, path);
        } else {
            return IUniswapV2Router(router).getAmountsIn(amount, path);
        }
    }

    function getTotalAmount(uint256 amount) public view returns (uint256) {
        return amount.add(amount.mul(feeRate).div(_FEE_MOLECULAR));
    }

    // ========= Admin functions =========
    function rescueFunds(IERC20 token, uint256 amount) external onlyAdmin {
        token.uniTransfer(payable(msg.sender), amount);
    }

    function setOwner(address _owner) external onlyAdmin {
        require(_owner != address(0), "Owner can't be zero address");
        owner = _owner;
    }

    function setFeeReceiver(address _receiver) external onlyAdmin {
        require(_receiver != address(0), "fee receiver can't be zero address");
        feeReceiver = _receiver;
    }

    function setFee(uint256 _feeRate) external onlyAdmin {
        feeRate = _feeRate;
    }

    function setDexRouter(address _dexRouter) external onlyAdmin {
        require(_dexRouter != address(0), "Dex router can't be zero address");
        dexRouter = IDexRouter(_dexRouter);
    }

    function GetInitializeData(address _owner, address _weth, address _feeReceiver, address _dexRouter, uint256 _feeRate) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address,address,address,uint256)", _owner,_weth,_feeReceiver,_dexRouter,_feeRate);
    }
}