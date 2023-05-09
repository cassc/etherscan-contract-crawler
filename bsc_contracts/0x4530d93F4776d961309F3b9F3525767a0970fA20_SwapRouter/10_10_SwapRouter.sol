/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ManageableUpgradeable.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract SwapRouter is
    Initializable,
    OwnableUpgradeable,
    ManageableUpgradeable
{
    IUniswapV2Router02 public ROUTER;
    address public GROWTH;
    address public DEAD_ADDRESS;
    uint256 public BURN_PERC;
    uint256 public PRECISION;

    event Request(
        string indexed id,
        address indexed user,
        uint256 amount,
        uint256 timeout,
        uint256 nativePercentage,
        uint256 srcChainID,
        uint256 destChainID
    );

    modifier validate(address[] memory path) {
        require(path.length >= 2, "INVALID_PATH");
        _;
    }

    function initialize(
        address router,
        address growth,
        uint256 burn
    ) public initializer {
        __Ownable_init();
        ROUTER = IUniswapV2Router02(router);
        GROWTH = growth;

        DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

        BURN_PERC = burn;
        PRECISION = 10000;
    }

    function swapTokenForToken(
        uint256 fromValue,
        uint256 toValueMin,
        address[] memory _path,
        bool burnActive
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).transferFrom(_msgSender(), address(this), fromValue);
        uint256 _realAmountIn = IERC20(tokenIn).balanceOf(address(this));

        _approve(tokenIn, _realAmountIn);

        uint256 feeAmount = burnActive
            ? (_realAmountIn * BURN_PERC) / PRECISION
            : 0;
        uint256 amountInSub = _realAmountIn - feeAmount;
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInSub,
            toValueMin,
            _path,
            msg.sender,
            block.timestamp
        );
        if (feeAmount > 0) _burn(feeAmount, _path);
    }

    function swapTokenForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        bool burnActive
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this));

        if (tokenIn == ROUTER.WETH()) {
            IWETH(ROUTER.WETH()).withdraw(adjustedAmountIn);
            _safeTransfer(msg.sender, adjustedAmountIn);
        } else {
            _approve(tokenIn, adjustedAmountIn);
            uint256 feeAmount = burnActive
                ? (adjustedAmountIn * BURN_PERC) / PRECISION
                : 0;
            uint256 amountInSub = adjustedAmountIn - feeAmount;
            ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountInSub,
                _amountOutMin,
                _path,
                msg.sender,
                block.timestamp
            );
            if (feeAmount > 0) _burn(feeAmount, _path);
        }
    }

    function swapETHForToken(
        uint256 _amountOutMin,
        address[] memory _path,
        bool burnActive
    ) public payable validate(_path) {
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == ROUTER.WETH()) {
            IWETH(ROUTER.WETH()).deposit{value: amountIn}();
            IERC20(ROUTER.WETH()).transfer(msg.sender, amountIn);
        } else {
            uint256 feeAmount = burnActive
                ? (amountIn * BURN_PERC) / PRECISION
                : 0;
            uint256 amountInSub = amountIn - feeAmount;
            ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amountInSub
            }(_amountOutMin, _path, msg.sender, block.timestamp);
            if (feeAmount > 0) _burn(feeAmount, _path);
        }
    }

    function _burn(uint256 feeAmount, address[] memory _path) internal {
        address tokenIn = _path[0];
        feeAmount = feeAmount / 3;

        if (tokenIn == ROUTER.WETH()) {
            // BURN OUTPUT TOKEN
            ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: feeAmount
            }(0, _path, DEAD_ADDRESS, block.timestamp);

            // BUY BACK FUNDS
            _safeTransfer(GROWTH, feeAmount * 2);
        } else {
            // BURN INPUT TOKEN
            IERC20(tokenIn).transfer(DEAD_ADDRESS, feeAmount);

            // BURN OUTPUT TOKEN
            ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                feeAmount,
                0,
                _path,
                DEAD_ADDRESS,
                block.timestamp
            );

            // BUY BACK FUNDS
            address[] memory wethPath = _getWETHPath(_path);
            if (wethPath.length >= 2) {
                ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    feeAmount,
                    0,
                    wethPath,
                    GROWTH,
                    block.timestamp
                );
            } else {
                IERC20(tokenIn).transfer(GROWTH, feeAmount);
            }
        }
    }

    function _getWETHPath(
        address[] memory _path
    ) internal view returns (address[] memory wethPath) {
        uint256 index = 0;
        for (uint256 i = 0; i < _path.length; i++) {
            if (_path[i] == ROUTER.WETH()) {
                index = i + 1;
                break;
            }
        }
        wethPath = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            wethPath[i] = _path[i];
        }
    }

    function _approve(address token, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(ROUTER),
                0
            )
        );
        require(success, "Approval to zero failed");
        (success, ) = token.call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(ROUTER),
                amount
            )
        );
        require(success, "Approval failed");
    }

    function _safeTransfer(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    function updateRouter(address value) public onlyOwner {
        ROUTER = IUniswapV2Router02(value);
    }

    function updatePrecision(uint256 value) public onlyOwner {
        PRECISION = value;
    }
}