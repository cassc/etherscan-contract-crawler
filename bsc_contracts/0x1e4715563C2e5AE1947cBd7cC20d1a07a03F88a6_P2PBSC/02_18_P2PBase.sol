// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

abstract contract P2PBase {
    using SafeERC20 for IERC20;

    address private constant UNISWAP_V2_ROUTER_ADDR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address private constant UNISWAP_FACTORY_ADDR = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant VOLT = 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;

    address public WETH;
    uint256 public fee; // default to 50 bp
    address public wallet;
    mapping(address => bool) public whitelisted_tokens;

    struct p2pOrder {
        address _from;
        address _to;
        address _tokenIn;
        uint256 _amountIn;
        address _tokenOut;
        uint256 _amountOut;
        uint256 _expires;
    }

    p2pOrder[] public p2pOrders;
    event p2pOrderCreated(
        address _from,
        address _to,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut,
        uint256 _arrayIndex,
        uint256 _expires
    );

    event p2pOrderDeleted(uint256 _orderIndex);

    constructor(uint256 _fee, address _addr) {
        fee = _fee;
        wallet = _addr;
        WETH = UNISWAP_V2_ROUTER().WETH();
    }

    modifier validate(address[] memory path) {
        require(path.length >= 2, "INVALID_PATH");
        _;
    }

    function UNISWAP_V2_ROUTER() internal pure virtual returns (IUniswapV2Router02);

    function UNISWAP_FACTORY() internal pure virtual returns (IUniswapV2Factory);

    // requires that msg.sender approves this contract to move his tokens
    // _amountIn may be reduced if token has fees on transfer
    function sendP2POffer(
        address _to,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut,
        uint256 _expires
    ) external payable {
        require(_expires > block.timestamp, "_expires");
        p2pOrder memory order;
        if (msg.value > 0) {
            IWETH(WETH).deposit{value: msg.value}();
            order = p2pOrder(msg.sender, _to, WETH, msg.value, _tokenOut, _amountOut, _expires);
            p2pOrders.push(order);
            emit p2pOrderCreated(
                msg.sender,
                _to,
                _tokenIn,
                msg.value,
                _tokenOut,
                _amountOut,
                p2pOrders.length > 0 ? p2pOrders.length - 1 : 0,
                _expires
            );
        } else {
            uint256 prev_balance = IERC20(_tokenIn).balanceOf(address(this));
            IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            uint256 curr_balance = IERC20(_tokenIn).balanceOf(address(this));
            order = p2pOrder(
                msg.sender,
                _to,
                _tokenIn,
                curr_balance - prev_balance, // I do this to take into consideration fees on transfers
                // which can make the amountIn less than the real amount exchanged
                _tokenOut,
                _amountOut,
                _expires
            );
            p2pOrders.push(order);
            emit p2pOrderCreated(
                msg.sender,
                _to,
                _tokenIn,
                curr_balance - prev_balance,
                _tokenOut,
                _amountOut,
                p2pOrders.length > 0 ? p2pOrders.length - 1 : 0,
                _expires
            );
        }
    }

    // requires that msg.sender approves this contract to move his tokens
    // token out may be reduced if token has fees on transfer
    function acceptP2Porder(
        uint256 _orderIndex,
        bool _orderAccepted,
        address[] memory path
    ) external {
        p2pOrder memory order = p2pOrders[_orderIndex];
        require(order._to == msg.sender, "not sender");
        if (_orderAccepted && order._expires >= block.timestamp) {
            IERC20(order._tokenOut).safeTransferFrom(msg.sender, order._from, order._amountOut);

            uint256 _feeAmount = (order._amountIn * fee) / 10000;
            uint256 _amountInSub = order._amountIn - _feeAmount;
            if (order._tokenIn == WETH) {
                IWETH(WETH).withdraw(order._amountIn);
                (bool sent, ) = msg.sender.call{value: _amountInSub}("");
                require(sent, "Failed to send Ether");
            } else {
                IERC20(order._tokenIn).safeTransfer(msg.sender, _amountInSub);
            }
            burn(order._tokenIn, order._tokenOut, _feeAmount, path);
        } else {
            IERC20(order._tokenIn).safeTransfer(order._from, order._amountIn);
        }
        p2pOrders[_orderIndex] = p2pOrders[p2pOrders.length - 1];
        p2pOrders.pop();
        emit p2pOrderDeleted(_orderIndex);
    }

    function getP2PordersCount() public view returns (uint256) {
        return p2pOrders.length;
    }

    function burn(
        address _tokenIn,
        address _tokenOut,
        uint256 _feeAmount,
        address[] memory path
    ) internal {
        if (_tokenIn == WETH) {
            if (_tokenOut != VOLT) {
                uint256 _firstFeeAmount = _feeAmount / 2;
                // console.log("starting second swap");
                UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{value: _firstFeeAmount}(
                    0,
                    path,
                    deadAddress,
                    block.timestamp
                );
                // console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                (bool sent, ) = wallet.call{value: _secondFeeAmount}("");
                require(sent, "transfer ETH failed.");
            } else {
                (bool sent, ) = wallet.call{value: _feeAmount}("");
                require(sent, "transfer ETH failed.");
            }
        } else if (_tokenOut == WETH) {
            if (_tokenIn == VOLT) {
                IERC20(_tokenIn).safeTransfer(deadAddress, _feeAmount);
            } else {
                IERC20(_tokenIn).safeIncreaseAllowance(UNISWAP_V2_ROUTER_ADDR, _feeAmount);
                uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
                uint256 _firstFeeAmount = _feeAmount / 2;
                // console.log("starting second swap");
                UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _firstFeeAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                (bool sent, ) = wallet.call{value: address(this).balance - prev_balance}("");
                require(sent, "Failed to send Ether");
                // console.log("second swap done");
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                if (!whitelisted_tokens[_tokenIn]) {
                    IERC20(_tokenIn).safeTransfer(deadAddress, _secondFeeAmount);
                } else {
                    prev_balance = address(this).balance; // prev_balance should be always == 0
                    // console.log("starting third swap");
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );
                    (sent, ) = wallet.call{value: address(this).balance - prev_balance}("");
                    require(sent, "Failed to send Ether");
                    // console.log("third swap done");
                }
            }
        } else {
            if (_tokenIn == VOLT) {
                IERC20(_tokenIn).safeTransfer(deadAddress, _feeAmount);
            } else {
                IERC20(_tokenIn).safeIncreaseAllowance(UNISWAP_V2_ROUTER_ADDR, _feeAmount);
                uint256 _firstFeeAmount = _feeAmount / 2;
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                uint256 prev_balance = address(this).balance; // prev_balance should be always == 0
                address[] memory _path;
                _path[0] = _tokenIn;
                _path[1] = WETH;
                // console.log("starting second swap");
                UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _firstFeeAmount,
                    0,
                    _path,
                    address(this),
                    block.timestamp
                );
                (bool sent, ) = wallet.call{value: address(this).balance - prev_balance}("");
                require(sent, "Failed to send Ether");
                // console.log("second swap done");
                if (!whitelisted_tokens[_tokenIn] && whitelisted_tokens[_tokenOut]) {
                    IERC20(_tokenIn).safeTransfer(deadAddress, _secondFeeAmount);
                } else if (!whitelisted_tokens[_tokenOut]) {
                    prev_balance = IERC20(_tokenOut).balanceOf(address(this)); //prev_balance should always be equal to 0;
                    // console.log("starting third swap");
                    UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );
                    // console.log("third swap done");
                    uint256 curr_balance = IERC20(_tokenOut).balanceOf(address(this));
                    IERC20(_tokenOut).safeTransfer(deadAddress, curr_balance - prev_balance);
                }
            }
        }
    }

    receive() external payable {}
}