// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./UniswapInterface.sol";
import "./SafeMath.sol";

/**
 ________      ___    ___ ________   ________  _____ ______   ___  ________     
|\   ___ \    |\  \  /  /|\   ___  \|\   __  \|\   _ \  _   \|\  \|\   ____\    
\ \  \_|\ \   \ \  \/  / | \  \\ \  \ \  \|\  \ \  \\\__\ \  \ \  \ \  \___|    
 \ \  \ \\ \   \ \    / / \ \  \\ \  \ \   __  \ \  \\|__| \  \ \  \ \  \       
  \ \  \_\\ \   \/  /  /   \ \  \\ \  \ \  \ \  \ \  \    \ \  \ \  \ \  \____  
   \ \_______\__/  / /      \ \__\\ \__\ \__\ \__\ \__\    \ \__\ \__\ \_______\
    \|_______|\___/ /        \|__| \|__|\|__|\|__|\|__|     \|__|\|__|\|_______|
             \|___|/                                                            
 */

contract CrossChain is Initializable, OwnableUpgradeable {
    // variables and mappings
    using SafeMath for uint256;
    uint256 public constant DIVIDER = 10000;
    uint256 public swapTimeout;
    uint256 public fee;
    address public router;
    address public weth;
    mapping(address => bool) public zeroFee;

    // structs and events
    event SwapForToken(
        address receiver,
        address tokenTo,
        uint256 amount,
        uint256 chainId
    );

    function initialize(
        uint256 _fee,
        address _router,
        address _weth
    ) public initializer {
        __Ownable_init();
        fee = _fee;
        router = _router;
        weth = _weth;
        swapTimeout = 900;
    }

    function updateSwapTimeout(uint256 _swapTimeout) public onlyOwner {
        swapTimeout = _swapTimeout;
    }

    function updateFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setFreeFee(address _target, bool _isFreeFee) public onlyOwner {
        zeroFee[_target] = _isFreeFee;
    }

    function swap(
        address _receiver,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn,
        uint256 _percentSlippage,
        uint64 _dstChainId
    ) external payable {
        if (_dstChainId == block.chainid) {
            swapSameChain(
                _receiver,
                _tokenFrom,
                _tokenTo,
                _amountIn,
                _percentSlippage
            );
            return;
        }

        uint256 amountOut = 0;
        uint256 remainingAmount = _amountIn;
        if (msg.value > 0) {
            require(msg.value == _amountIn, "Invalid input");
            if (!zeroFee[msg.sender] && fee > 0) {
                uint256 totalFee = (fee * _amountIn) / DIVIDER;
                remainingAmount = remainingAmount.sub(totalFee);
            }
            if (_tokenFrom == _tokenTo) {
                emit SwapForToken(
                    _receiver,
                    _tokenTo,
                    remainingAmount,
                    _dstChainId
                );
                return;
            }
            appove(router, _tokenFrom, remainingAmount);
            address[] memory path;
            path = new address[](2);
            path[0] = weth;
            path[1] = _tokenTo;
            uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                remainingAmount,
                path
            );
            require(amt[amt.length - 1] > 0, "Invalid param");
            uint256 amountOutMin = (amt[amt.length - 1] *
                (100 - _percentSlippage)) / 100;

            uint256[] memory amounts = IUniswapV2Router(router)
                .swapExactETHForTokens{value: remainingAmount}(
                amountOutMin,
                path,
                address(this),
                block.timestamp + swapTimeout
            );
            amountOut = amounts[amounts.length - 1];
        } else {
            bool result = IERC20Upgradeable(_tokenFrom).transferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
            require(result, "[DYNA]: Token transfer fail");
            if (!zeroFee[msg.sender] && fee > 0) {
                uint256 totalFee = (fee * _amountIn) / DIVIDER;
                remainingAmount = remainingAmount.sub(totalFee);
            }
            if (_tokenFrom == _tokenTo) {
                emit SwapForToken(
                    _receiver,
                    _tokenTo,
                    remainingAmount,
                    _dstChainId
                );
                return;
            }
            appove(router, _tokenFrom, remainingAmount);
            if (_tokenFrom != _tokenTo) {
                address[] memory path;
                if (_tokenFrom == weth || _tokenTo == weth) {
                    path = new address[](2);
                    path[0] = _tokenFrom;
                    path[1] = _tokenTo;
                } else {
                    path = new address[](3);
                    path[0] = _tokenFrom;
                    path[1] = weth;
                    path[2] = _tokenTo;
                }

                uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                    remainingAmount,
                    path
                );
                require(amt[amt.length - 1] > 0, "Invalid param");
                uint256 amountOutMin = (amt[amt.length - 1] *
                    (100 - _percentSlippage)) / 100;

                uint256[] memory amounts = IUniswapV2Router(router)
                    .swapExactTokensForTokens(
                        remainingAmount,
                        amountOutMin,
                        path,
                        address(this),
                        block.timestamp + swapTimeout
                    );
                amountOut = amounts[amounts.length - 1];
            }
        }

        emit SwapForToken(_receiver, _tokenTo, amountOut, _dstChainId);
    }

    function swapSameChain(
        address _receiver,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn,
        uint256 _percentSlippage
    ) internal {
        if (msg.value > 0) {
            address[] memory path;
            path = new address[](2);
            path[0] = weth;
            path[1] = _tokenTo;
            uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                _amountIn,
                path
            );

            require(amt[amt.length - 1] > 0, "Invalid param");
            uint256 amountOutMin = (amt[amt.length - 1] *
                (100 - _percentSlippage)) / 100;

            IUniswapV2Router(router).swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                path,
                _receiver,
                block.timestamp + swapTimeout
            );
            return;
        } else {
            bool result = IERC20Upgradeable(_tokenFrom).transferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
            require(result, "[DYNA]: Token transfer fail");
            appove(router, _tokenFrom, _amountIn);
            address[] memory path;
            if (_tokenFrom == weth || _tokenTo == weth) {
                path = new address[](2);
                path[0] = _tokenFrom;
                path[1] = _tokenTo;
            } else {
                path = new address[](3);
                path[0] = _tokenFrom;
                path[1] = weth;
                path[2] = _tokenTo;
            }

            uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                _amountIn,
                path
            );
            require(amt[amt.length - 1] > 0, "Invalid param");
            uint256 amountOutMin = (amt[amt.length - 1] *
                (100 - _percentSlippage)) / 100;
            IUniswapV2Router(router)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amountIn,
                    amountOutMin,
                    path,
                    _receiver,
                    block.timestamp + swapTimeout
                );
        }
    }

    function appove(
        address spener,
        address token,
        uint256 amount
    ) internal {
        if (
            IERC20Upgradeable(token).allowance(address(this), spener) < amount
        ) {
            IERC20Upgradeable(token).approve(spener, amount);
        }
    }

    function withdraw(address _token, uint256 _amount) public onlyOwner {
        IERC20Upgradeable(_token).transfer(_msgSender(), _amount);
    }

    function withdrawETH(uint256 _amount) public payable onlyOwner {
        (bool success, ) = _msgSender().call{value: _amount}("");
        require(success, "Transfer ETH failed");
    }

    function getAmountOut(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn
    ) public view returns (uint256) {
        address[] memory path;
        if (_tokenFrom == weth || _tokenTo == weth) {
            path = new address[](2);
            path[0] = _tokenFrom;
            path[1] = _tokenTo;
        } else {
            path = new address[](3);
            path[0] = _tokenFrom;
            path[1] = weth;
            path[2] = _tokenTo;
        }
        uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
            _amountIn,
            path
        );
        require(amt[amt.length - 1] > 0, "Invalid param");
        return amt[amt.length - 1];
    }
}