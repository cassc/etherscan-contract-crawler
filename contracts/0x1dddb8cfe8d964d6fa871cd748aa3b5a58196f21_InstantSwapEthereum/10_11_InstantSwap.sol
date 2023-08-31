// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWETH.sol";

abstract contract InstantSwap is Ownable {
    address internal immutable WETH;
    uint256 public teamFee;
    address public teamWalletAddress;
    address public dexToken = address(0);
    uint256 public amountGetFreeTax = 1000 * 10 ** 9;

    event Swap(address user, address tokenIn, uint256 amountIn, address tokenOut);

    modifier validate(address[] memory path) {
        require(path.length >= 2, "Invalid path");
        _;
    }

    constructor(uint256 _teamFee, address _teamWallet) {
        require(_teamFee >= 0 && _teamFee <= 10000, "Invalid swap fee");
        WETH = UNISWAP_V2_ROUTER().WETH();
        teamFee = _teamFee;
        teamWalletAddress = _teamWallet;
    }

    function UNISWAP_V2_ROUTER() internal pure virtual returns (IUniswapV2Router02);

    function UNISWAP_FACTORY() internal pure virtual returns (IUniswapV2Factory);

    function setAmountGetFreeTax(uint256 _newAmount) public onlyOwner {
        require(_newAmount >= 0, "Invalid amount");
        amountGetFreeTax = _newAmount;
    }

    function setDexToken(address _dexToken) public onlyOwner {
        require(_dexToken != address(0) && _dexToken != address(this), "Invalid dex-token address");
        dexToken = _dexToken;
    }

    function setSwapFee(uint256 _newFee) public onlyOwner {
        require(_newFee >= 0 && _newFee <= 10000, "Invalid swap fee");
        teamFee = _newFee;
    }

    function getSwapFee(address _user) internal view returns (uint256) {
        uint256 swapFee = teamFee;
        if (dexToken != address(0)) {
            uint256 userDexTokenBalance = ERC20(dexToken).balanceOf(_user);
            if (userDexTokenBalance >= amountGetFreeTax * 10 ** ERC20(dexToken).decimals()) {
                swapFee = 0;
            }
        }
        return swapFee;
    }

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];
        address tokenOut = _path[_path.length - 1];
        ERC20(tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        uint256 _realAmountIn = ERC20(tokenIn).balanceOf(address(this));

        _approve(tokenIn, _realAmountIn);

        uint256 swapFee = getSwapFee(msg.sender);
        uint256 teamAmount = (_realAmountIn * swapFee) / 10000;
        uint256 totalFee = teamAmount;
        uint256 amountInSub = _realAmountIn - totalFee;
        UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInSub,
            _amountOutMin,
            _path,
            msg.sender,
            block.timestamp
        );
        if (teamAmount > 0) {
            ERC20(tokenIn).transfer(teamWalletAddress, teamAmount);
        }
        emit Swap(msg.sender, tokenIn, _realAmountIn, tokenOut);
    }

    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];
        address tokenOut = _path[_path.length - 1];
        ERC20(tokenIn).transferFrom(msg.sender, address(this), _amountInMax);
        uint256 adjustedAmountIn = ERC20(tokenIn).balanceOf(address(this));

        _approve(tokenIn, adjustedAmountIn);

        uint256 swapFee = getSwapFee(msg.sender);
        uint256 adjustedTeamFee = (adjustedAmountIn * swapFee) / 10000;
        uint256 totalFee = adjustedTeamFee;
        uint256 amountInSub = adjustedAmountIn - totalFee;
        uint256[] memory amounts = UNISWAP_V2_ROUTER().swapTokensForExactTokens(
            _amountOut,
            amountInSub,
            _path,
            msg.sender,
            block.timestamp
        );

        uint256 realAmountIn = amounts[0];
        uint256 teamAmount = (realAmountIn * swapFee) / 10000;
        uint256 totalConsume = realAmountIn + teamAmount;
        uint256 refundAmount = adjustedAmountIn - totalConsume;
        if (refundAmount > 0) {
            ERC20(tokenIn).transfer(msg.sender, refundAmount);
        }
        if (teamAmount > 0) {
            ERC20(tokenIn).transfer(teamWalletAddress, teamAmount);
        }
        emit Swap(msg.sender, tokenIn, realAmountIn, tokenOut);
    }

    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];
        ERC20(tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        uint256 adjustedAmountIn = ERC20(tokenIn).balanceOf(address(this));

        if (tokenIn == WETH) {
            IWETH(WETH).withdraw(adjustedAmountIn);
            _transfer(msg.sender, adjustedAmountIn);
        } else {
            _approve(tokenIn, adjustedAmountIn);
            uint256 swapFee = getSwapFee(msg.sender);
            uint256 teamAmount = (adjustedAmountIn * swapFee) / 10000;
            uint256 totalFee = teamAmount;
            uint256 amountInSub = adjustedAmountIn - totalFee;
            UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountInSub,
                _amountOutMin,
                _path,
                msg.sender,
                block.timestamp
            );
            if (teamAmount > 0) {
                ERC20(tokenIn).transfer(teamWalletAddress, teamAmount);
            }
        }
        emit Swap(msg.sender, tokenIn, _amountIn, WETH);
    }

    function swapTokensForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];
        address tokenOut = _path[_path.length - 1];
        ERC20(tokenIn).transferFrom(msg.sender, address(this), _amountInMax);
        uint256 adjustedAmountIn = ERC20(tokenIn).balanceOf(address(this));

        if (tokenIn == WETH) {
            IWETH(WETH).withdraw(adjustedAmountIn);
            _transfer(msg.sender, adjustedAmountIn);
            emit Swap(msg.sender, WETH, adjustedAmountIn, address(0));
        } else {
            _approve(tokenIn, adjustedAmountIn);
            uint256 swapFee = getSwapFee(msg.sender);
            uint256 adjustedTeamFee = (adjustedAmountIn * swapFee) / 10000;
            uint256 totalFee = adjustedTeamFee;
            uint256 amountInSub = adjustedAmountIn - totalFee;
            uint256[] memory amounts = UNISWAP_V2_ROUTER().swapTokensForExactETH(
                _amountOut,
                amountInSub,
                _path,
                msg.sender,
                block.timestamp
            );
            uint256 realAmountIn = amounts[0];
            uint256 teamAmount = (realAmountIn * swapFee) / 10000;
            uint256 totalConsume = realAmountIn + teamAmount;
            uint256 refundAmount = adjustedAmountIn - totalConsume;
            if (refundAmount > 0) {
                ERC20(tokenIn).transfer(msg.sender, refundAmount);
            }
            if (teamAmount > 0) {
                ERC20(tokenIn).transfer(teamWalletAddress, teamAmount);
            }
            emit Swap(msg.sender, tokenIn, realAmountIn, tokenOut);
        }
    }

    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] memory _path
    ) public payable validate(_path) {
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            ERC20(WETH).transfer(msg.sender, amountIn);
        } else {
            uint256 swapFee = getSwapFee(msg.sender);
            uint256 teamAmount = (amountIn * swapFee) / 10000;
            uint256 totalFee = teamAmount;
            uint256 amountInSub = amountIn - totalFee;
            UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amountInSub
            }(_amountOutMin, _path, msg.sender, block.timestamp);
            if (teamAmount > 0) {
                _transfer(teamWalletAddress, teamAmount);
            }
        }
        emit Swap(msg.sender, WETH, amountIn, tokenOut);
    }

    function swapETHForExactTokens(
        uint256 _amountOut,
        address[] memory _path
    ) public payable validate(_path) {
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            ERC20(WETH).transfer(msg.sender, amountIn);
        } else {
            uint256 swapFee = getSwapFee(msg.sender);
            uint256 teamAmount = (amountIn * swapFee) / 10000;
            uint256 totalFee = teamAmount;
            uint256 amountInSub = amountIn - totalFee;
            uint256[] memory amounts = UNISWAP_V2_ROUTER().swapETHForExactTokens{
                value: amountInSub
            }(_amountOut, _path, msg.sender, block.timestamp);
            uint256 refund = amountInSub - amounts[0];
            if (refund > 0) {
                _transfer(msg.sender, refund);
            }
            if (teamAmount > 0) {
                _transfer(teamWalletAddress, teamAmount);
            }
        }
        emit Swap(msg.sender, WETH, amountIn, tokenOut);
    }

    function getPair(address _tokenIn, address _tokenOut) external view returns (address) {
        return UNISWAP_FACTORY().getPair(_tokenIn, _tokenOut);
    }

    function getAmountIn(uint256 _amountOut, address[] memory _path) public view returns (uint256) {
        uint256[] memory amountsIn = UNISWAP_V2_ROUTER().getAmountsIn(_amountOut, _path);
        uint256 amountInWithoutFee = amountsIn[0];
        uint256 swapFee = getSwapFee(msg.sender);
        uint256 teamAmount = (amountInWithoutFee * swapFee) / 10000;
        uint256 totalFee = teamAmount;
        uint256 amountInWithFee = amountInWithoutFee + totalFee;
        return amountInWithFee;
    }

    function getAmountOut(uint256 _amountIn, address[] memory _path) public view returns (uint256) {
        uint256 swapFee = getSwapFee(msg.sender);
        uint256 teamAmount = (_amountIn * swapFee) / 10000;
        uint256 totalFee = teamAmount;
        uint256 amountInSub = _amountIn - totalFee;
        uint256[] memory amountOutMins = UNISWAP_V2_ROUTER().getAmountsOut(amountInSub, _path);
        return amountOutMins[amountOutMins.length - 1];
    }

    function _getWETHPath(
        address[] memory _path
    ) internal view returns (address[] memory wethPath) {
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

    function _transfer(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
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