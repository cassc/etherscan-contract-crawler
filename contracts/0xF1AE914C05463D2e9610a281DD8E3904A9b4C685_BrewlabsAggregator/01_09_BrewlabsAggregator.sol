// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "contracts/helpers/UniERC20.sol";

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

interface IAggregationExecutor {
    function callBytes(address msgSender, bytes calldata data) external payable;
}

interface IAggregationRouter {
    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount,
            uint256 gasLeft
        );

    function unoswap(
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);
}

contract BrewlabsAggregator is Ownable {
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    IAggregationRouter private constant aggregationRouter =
        IAggregationRouter(0x1111111254fb6c44bAC0beD2854e76F90643097d);

    uint256 public feeAmount;
    address payable public feeAddress;

    event UpdateFeeAmount(uint256 indexed oldAmount, uint256 indexed newAmount);
    event UpdateFeeAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    constructor(uint256 _feeAmount, address payable _feeAddress) {
        feeAmount = _feeAmount;
        feeAddress = _feeAddress;
    }

    receive() external payable {}

    function updateFeeAmount(uint256 _newAmount) external onlyOwner {
        require(
            _newAmount != feeAmount,
            "Brewlabs: Cannot update to same value"
        );
        uint256 _oldAmount = feeAmount;
        feeAmount = _newAmount;
        emit UpdateFeeAmount(_oldAmount, _newAmount);
    }

    function updateFeeAddress(address payable _newAddress) external onlyOwner {
        require(
            _newAddress != feeAddress,
            "Brewlabs: Cannot update to same value"
        );
        address _oldAddress = feeAddress;
        feeAddress = _newAddress;
        emit UpdateFeeAddress(_oldAddress, _newAddress);
    }

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) public payable {
        IERC20 srcToken = desc.srcToken;
        bool srcETH = srcToken.isETH();

        if (srcETH) {
            require(
                msg.value == desc.amount + feeAmount,
                "Brewlabs: ether is not correct"
            );
        } else {
            require(msg.value == feeAmount, "Brewlabs: ether is not correct");
        }

        feeAddress.transfer(feeAmount);

        if (!srcETH) {
            srcToken.safeTransferFrom(msg.sender, address(this), desc.amount);
            srcToken.approve(address(aggregationRouter), desc.amount);
        }

        aggregationRouter.swap{value: srcETH ? desc.amount : 0}(
            caller,
            desc,
            data
        );
    }

    function unoswap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) public payable {
        bool srcETH = srcToken.isETH();
        bool dstETH = dstToken.isETH();

        if (srcETH) {
            require(
                msg.value == amount + feeAmount,
                "Brewlabs: ether is not correct"
            );
        } else {
            require(msg.value == feeAmount, "Brewlabs: ether is not correct");
        }

        feeAddress.transfer(feeAmount);

        uint256 beforeAmt;
        uint256 tokenAmt;

        if (!srcETH) {
            beforeAmt = srcToken.balanceOf(address(this));
            srcToken.safeTransferFrom(msg.sender, address(this), amount);
            tokenAmt = srcToken.balanceOf(address(this)).sub(beforeAmt);
            srcToken.approve(address(aggregationRouter), tokenAmt);
        }

        if (!dstETH) beforeAmt = dstToken.balanceOf(address(this));

        uint256 returnAmount = aggregationRouter.unoswap{
            value: srcETH ? amount : 0
        }(srcToken, srcETH ? amount : tokenAmt, minReturn, pools);

        if (!dstETH)
            tokenAmt = dstToken.balanceOf(address(this)).sub(beforeAmt);

        if (!dstETH) {
            dstToken.safeTransfer(msg.sender, tokenAmt);
        } else {
            msg.sender.transfer(returnAmount);
        }
    }

    function uniswapV3SwapTo(
        IERC20 srcToken,
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) public payable {
        bool srcETH = srcToken.isETH();

        if (srcETH) {
            require(
                msg.value == amount + feeAmount,
                "Brewlabs: ether is not correct"
            );
        } else {
            require(msg.value == feeAmount, "Brewlabs: ether is not correct");
        }

        feeAddress.transfer(feeAmount);

        uint256 beforeAmt;
        uint256 tokenAmt;

        if (!srcETH) {
            beforeAmt = srcToken.balanceOf(address(this));
            srcToken.safeTransferFrom(msg.sender, address(this), amount);
            tokenAmt = srcToken.balanceOf(address(this)).sub(beforeAmt);
            srcToken.approve(address(aggregationRouter), tokenAmt);
        }

        aggregationRouter.uniswapV3SwapTo{value: srcETH ? amount : 0}(
            recipient,
            srcETH ? amount : tokenAmt,
            minReturn,
            pools
        );
    }
}