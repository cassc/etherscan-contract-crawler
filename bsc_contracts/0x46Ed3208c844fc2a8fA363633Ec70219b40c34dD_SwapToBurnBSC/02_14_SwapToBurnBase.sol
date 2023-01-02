// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IBurnHandler.sol";

abstract contract SwapToBurnBase is Ownable {
    using SafeERC20 for IERC20;
    address internal constant nullAddress = 0x000000000000000000000000000000000000dEaD;
    address internal immutable WETH;
    address public immutable burnHandlerAddress;
    uint256 public immutable burnFee;
    uint256 public immutable teamFee;
    address public teamWalletAddress;

    modifier validate(address[] memory path) {
        require(path.length >= 2, "INVALID_PATH");
        _;
    }

    constructor(
        uint256 _burnFee,
        uint256 _teamFee,
        address _burnHandler,
        address _teamWallet
    ) {
        WETH = UNISWAP_V2_ROUTER().WETH();
        burnFee = _burnFee;
        teamFee = _teamFee;
        burnHandlerAddress = _burnHandler;
        teamWalletAddress = _teamWallet;
    }

    //need to override here
    function LUFFY() public pure virtual returns (address);

    function UNISWAP_V2_ROUTER() internal pure virtual returns (IUniswapV2Router02);

    function UNISWAP_FACTORY() internal pure virtual returns (IUniswapV2Factory);

    function burn(uint256 _burnAmount, address[] memory _path) internal {
        address tokenIn = _path[0];
        if (tokenIn == LUFFY()) {
            //if token is LUFFY TOKEN just burn it
            IERC20(tokenIn).safeTransfer(nullAddress, _burnAmount);
        } else {
            if (tokenIn == WETH) {
                _safeTransfer(burnHandlerAddress, _burnAmount);
            } else {
                address[] memory wethPath = _getWETHPath(_path);
                if (wethPath.length >= 2) {
                    // buy ETH and send to fee-handler contract to buy-back and burn LUFFY
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _burnAmount,
                        0,
                        wethPath,
                        burnHandlerAddress,
                        block.timestamp
                    );
                } else {
                    IERC20(tokenIn).safeTransfer(burnHandlerAddress, _burnAmount);
                }
            }
        }
    }

    function swapTokenForToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        uint256 _realAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        _approve(tokenIn, _realAmountIn);

        uint256 burnAmount = (_realAmountIn * burnFee) / 10000;
        uint256 teamAmount = (_realAmountIn * teamFee) / 10000;
        uint256 totalFee = burnAmount + teamAmount;
        uint256 amountInSub = _realAmountIn - totalFee;
        UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInSub,
            _amountOutMin,
            _path,
            msg.sender,
            block.timestamp
        );
        burn(burnAmount, _path);
        IERC20(tokenIn).safeTransfer(teamWalletAddress, teamAmount);
    }

    function swapTokenForExactToken(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountInMax);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        _approve(tokenIn, adjustedAmountIn);

        uint256 adjustedBurnFee = (adjustedAmountIn * burnFee) / 10000;
        uint256 adjustedTeamFee = (adjustedAmountIn * teamFee) / 10000;
        uint256 totalFee = adjustedBurnFee + adjustedTeamFee;
        uint256 amountInSub = adjustedAmountIn - totalFee;
        uint256[] memory amounts = UNISWAP_V2_ROUTER().swapTokensForExactTokens(
            _amountOut,
            amountInSub,
            _path,
            msg.sender,
            block.timestamp
        );

        uint256 realAmountIn = amounts[0];
        uint256 burnAmount = (realAmountIn * burnFee) / 10000;
        uint256 teamAmount = (realAmountIn * teamFee) / 10000;
        uint256 totalConsume = realAmountIn + burnAmount + teamAmount;
        uint256 refundAmount = adjustedAmountIn - totalConsume;
        if (refundAmount > 0) {
            IERC20(tokenIn).safeTransfer(msg.sender, refundAmount);
        }
        burn(burnAmount, _path);
        IERC20(tokenIn).safeTransfer(teamWalletAddress, teamAmount);
    }

    function swapTokenForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        if (tokenIn == WETH) {
            IWETH(WETH).withdraw(adjustedAmountIn);
            _safeTransfer(msg.sender, adjustedAmountIn);
        } else {
            _approve(tokenIn, adjustedAmountIn);
            uint256 burnAmount = (adjustedAmountIn * burnFee) / 10000;
            uint256 teamAmount = (adjustedAmountIn * teamFee) / 10000;
            uint256 totalFee = burnAmount + teamAmount;
            uint256 amountInSub = adjustedAmountIn - totalFee;
            UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountInSub,
                _amountOutMin,
                _path,
                msg.sender,
                block.timestamp
            );
            burn(burnAmount, _path);
            IERC20(tokenIn).safeTransfer(teamWalletAddress, teamAmount);
        }
    }

    function swapTokenForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountInMax);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        if (tokenIn == WETH) {
            IWETH(WETH).withdraw(adjustedAmountIn);
            _safeTransfer(msg.sender, adjustedAmountIn);
        } else {
            _approve(tokenIn, adjustedAmountIn);
            uint256 adjustedBurnFee = (adjustedAmountIn * burnFee) / 10000;
            uint256 adjustedTeamFee = (adjustedAmountIn * teamFee) / 10000;
            uint256 totalFee = adjustedBurnFee + adjustedTeamFee;
            uint256 amountInSub = adjustedAmountIn - totalFee;
            uint256[] memory amounts = UNISWAP_V2_ROUTER().swapTokensForExactETH(
                _amountOut,
                amountInSub,
                _path,
                msg.sender,
                block.timestamp
            );
            uint256 realAmountIn = amounts[0];
            uint256 burnAmount = (realAmountIn * burnFee) / 10000;
            uint256 teamAmount = (realAmountIn * teamFee) / 10000;
            uint256 totalConsume = realAmountIn + burnAmount + teamAmount;
            uint256 refundAmount = adjustedAmountIn - totalConsume;
            if (refundAmount > 0) {
                IERC20(tokenIn).safeTransfer(msg.sender, refundAmount);
            }
            burn(burnAmount, _path);
            IERC20(tokenIn).safeTransfer(teamWalletAddress, teamAmount);
        }
    }

    function swapETHForToken(uint256 _amountOutMin, address[] memory _path)
        public
        payable
        validate(_path)
    {
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            IERC20(WETH).safeTransfer(msg.sender, amountIn);
        } else {
            uint256 burnAmount = (amountIn * burnFee) / 10000;
            uint256 teamAmount = (amountIn * teamFee) / 10000;
            uint256 totalFee = burnAmount + teamAmount;
            uint256 amountInSub = amountIn - totalFee;            
            UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amountInSub
            }(_amountOutMin, _path, msg.sender, block.timestamp);
            burn(burnAmount, _path);
            _safeTransfer(teamWalletAddress, teamAmount);
        }
    }

    function swapETHforExactToken(uint256 _amountOut, address[] memory _path)
        public
        payable
        validate(_path)
    {
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            IERC20(WETH).safeTransfer(msg.sender, amountIn);
        } else {
            uint256 burnAmount = (amountIn * burnFee) / 10000;
            uint256 teamAmount = (amountIn * teamFee) / 10000;
            uint256 totalFee = burnAmount + teamAmount;
            uint256 amountInSub = amountIn - totalFee;
            uint256[] memory amounts = UNISWAP_V2_ROUTER().swapETHForExactTokens{
                value: amountInSub
            }(_amountOut, _path, msg.sender, block.timestamp);
            uint256 refund = amountInSub - amounts[0];
            if (refund > 0) {
                _safeTransfer(msg.sender, refund);
            }
            burn(burnAmount, _path);
            _safeTransfer(teamWalletAddress, teamAmount);
        }
    }

    function getPair(address _tokenIn, address _tokenOut) external view returns (address) {
        return UNISWAP_FACTORY().getPair(_tokenIn, _tokenOut);
    }

    function getAmountIn(uint256 _amountOut, address[] memory _path) public view returns (uint256) {
        uint256[] memory amountsIn = UNISWAP_V2_ROUTER().getAmountsIn(_amountOut, _path);
        uint256 amountInWithoutFee = amountsIn[0];
        uint256 burnAmount = (amountInWithoutFee * burnFee) / 10000;
        uint256 teamAmount = (amountInWithoutFee * teamFee) / 10000;
        uint256 totalFee = burnAmount + teamAmount;
        uint256 amountInWithFee = amountInWithoutFee + totalFee;
        return amountInWithFee;
    }

    function getAmountOut(uint256 _amountIn, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256 burnAmount = (_amountIn * burnFee) / 10000;
        uint256 teamAmount = (_amountIn * teamFee) / 10000;
        uint256 totalFee = burnAmount + teamAmount;
        uint256 amountInSub = _amountIn - totalFee;
        uint256[] memory amountOutMins = UNISWAP_V2_ROUTER().getAmountsOut(amountInSub, _path);
        return amountOutMins[amountOutMins.length - 1];
    }

    function _getWETHPath(address[] memory _path)
        internal
        view
        returns (address[] memory wethPath)
    {
        uint256 index = 0;
        for (uint256 i = 0; i < _path.length; i++) {
            if (_path[i] == WETH) {
                index = i + 1;
                break;
            }
        }
        wethPath = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            wethPath[i] = _path[i];
        }
    }

    function _safeTransfer(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getTokenDecimals(address _addr) public view returns (uint8) {
        return IERC20Metadata(_addr).decimals();
    }

    function setTeamWallet(address payable _teamWallet) public onlyOwner {
        require(_teamWallet != address(0), "invalid team wallet");
        teamWalletAddress = _teamWallet;
    }

    /// @dev USDTs token implementation does not conform to the ERC20 standard
    /// first of all it requires an allowance to be set to zero before it can be set to a new value, therefore we set the allowance to zero here first
    /// secondly the return type does not conform to the ERC20 standard, therefore we ignore the return value
    function _approve(address token, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", address(UNISWAP_V2_ROUTER()), 0)
        );
        require(success, "Approval to zero failed");
        (success, ) = token.call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(UNISWAP_V2_ROUTER()),
                amount
            )
        );
        require(success, "Approval failed");
    }    

    receive() external payable {}
}