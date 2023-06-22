// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./lib/BurnableBase.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

abstract contract P2PBase is BurnableBase {
    using SafeERC20 for IERC20;

    struct p2pOrder {
        address from;
        address to;
        address tokenIn;
        uint256 amountIn;
        address tokenOut;
        uint256 amountOut;
        uint256 expires;
        bool isExecuted;
    }

    address internal _WETH;
    address internal _wallet;
    uint256 public fee; // default to 50 bp
    mapping(address => bool) public whitelisted_tokens;
    mapping(uint256 => p2pOrder) public p2pOrders;
    uint256 public orderCount;
    uint256 public processedOrderCount;

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

    event p2pOrderDeleted(uint256 orderIndex);
    event p2pOrderExpired(uint256 orderIndex);
    event p2pOrderAccepted(uint256 orderIndex);
    event p2pOrderDeclined(uint256 orderIndex);

    constructor(uint256 fee_, address wallet_) {
        fee = fee_;
        _wallet = wallet_;
        _WETH = UNISWAP_V2_ROUTER().WETH();
    }

    function WETH() public view virtual override returns (address) {
        return _WETH;
    }

    function beneficiary() public view virtual override returns (address) {
        return _wallet;
    }

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
        uint256 amountIn;
        if (msg.value != 0) {
            require(_tokenIn == WETH(), "wrong token");
            IWETH(WETH()).deposit{value: msg.value}();
            amountIn = msg.value;
        } else {
            uint256 prev_balance = IERC20(_tokenIn).balanceOf(address(this));
            IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            uint256 curr_balance = IERC20(_tokenIn).balanceOf(address(this));
            amountIn = curr_balance - prev_balance;
        }
        order = p2pOrder(msg.sender, _to, _tokenIn, amountIn, _tokenOut, _amountOut, _expires, false);
        p2pOrders[orderCount++] = order;
        emit p2pOrderCreated(msg.sender, _to, _tokenIn, amountIn, _tokenOut, _amountOut, orderCount, _expires);
    }

    // requires that msg.sender approves this contract to move his tokens
    // token out may be reduced if token has fees on transfer
    function acceptP2Porder(uint256 _orderIndex, bool _orderAccepted, address[] memory path) external validate(path) {
        p2pOrder storage order = p2pOrders[_orderIndex];
        require(order.to == msg.sender, "wrong sender");
        require(!order.isExecuted, "Already executed");
        order.isExecuted = true;
        if (_orderAccepted && order.expires >= block.timestamp) {
            require(order.tokenIn == path[0] && order.tokenOut == path[path.length - 1], "invalid path");
            IERC20(order.tokenOut).safeTransferFrom(msg.sender, order.from, order.amountOut);
            uint256 feeAmount = (order.amountIn * fee) / 10000;
            uint256 amountInSub = order.amountIn - feeAmount;
            IERC20(order.tokenIn).safeTransfer(msg.sender, amountInSub);
            _burn(feeAmount, path);
            emit p2pOrderAccepted(_orderIndex);
        } else {
            if (!_orderAccepted) emit p2pOrderDeclined(_orderIndex);
            else emit p2pOrderExpired(_orderIndex);
            IERC20(order.tokenIn).safeTransfer(order.from, order.amountIn);
        }
        processedOrderCount++;
    }

    function deleteP2Porder(uint256 _orderIndex) external {
        p2pOrder storage order = p2pOrders[_orderIndex];
        require(order.from == msg.sender, "wrong sender");
        require(!order.isExecuted, "Already executed");
        order.isExecuted = true;
        IERC20(order.tokenIn).safeTransfer(order.from, order.amountIn);
        processedOrderCount++;
        emit p2pOrderDeleted(_orderIndex);
    }

    function getP2PordersCount() public view returns (uint256) {
        return orderCount - processedOrderCount;
    }

    function _burn(uint256 amount, address[] memory path) internal virtual override {
        IERC20(path[0]).approve(address(UNISWAP_V2_ROUTER()), amount);
        super._burn(amount, path);
        // approval wipe
        IERC20(path[0]).approve(address(UNISWAP_V2_ROUTER()), 0);
    }

    receive() external payable {}
}