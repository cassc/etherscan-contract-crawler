// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IETF.sol";
import "./pancake/interfaces/IWETH.sol";
import "./pancake/interfaces/IPancakeRouter02.sol";
import "./pancake/libraries/PancakeLibrary.sol";

contract ZapperETF is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* Structs */
    struct Source {
        uint256 amountIn;
        address[] path;
    }

    /* Public variables */
    address public ownerSource;
    IPancakeRouter02 public router;
    address public weth;

    receive() external payable {
        assert(msg.sender == weth);
    }

    /* Events */
    event RouterUpdated(address router);
    event OwnerSourceUpdated(address ownerSource);

    /* Contructor */
    constructor(address _router, address _ownerSource) {
        _updateOwnerSource(_ownerSource);
        _updateRouter(_router);
    }

    /* External methods */
    function join(
        IETF etf,
        address[] memory path,
        uint256 minAmountOut
    ) payable external notContract onlyPositiveAmount(msg.value) nonReentrant returns (uint256 amountOut) {
        address etfNative = etf.native();
        address from = path[0];
        address to = path[path.length - 1];
        require(from == weth, "ZapperETF: First path element neq weth");
        require(to == etfNative, "ZapperETF: Last path element neq etf native");
        uint256 amountIn = msg.value;
        IWETH(weth).deposit{value: amountIn}();
        if (from != to) amountIn = _swap(path, amountIn, address(this), false);
        amountOut = _join(etf, etfNative, amountIn, minAmountOut);
        IERC20(address(etf)).safeTransfer(msg.sender, amountOut);
    }

    function joinMulti(
        IETF etf,
        Source[] memory sources,
        uint256 minAmountOut
    ) external notContract nonReentrant returns (uint256 amountOut) {
        address etfNative = etf.native();
        uint256 nativeAmount = 0;
        for (uint256 i = 0; i < sources.length; i++) {
            Source memory source_ = sources[i];
            address[] memory path = source_.path;
            address to = path[path.length - 1];
            require(source_.amountIn > 0, "ZapperETF: Amount is zero");
            require(to == etfNative, "ZapperETF: Last path element neq etf native");
            if (path[0] != to) nativeAmount += _swap(path, source_.amountIn, address(this), true);
        }
        amountOut = _join(etf, etfNative, nativeAmount, minAmountOut);
        IERC20(address(etf)).safeTransfer(msg.sender, amountOut);
    }

    function exit(
        IETF etf,
        uint256 amountIn,
        address[] memory path,
        uint256 minAmountOut
    ) external notContract onlyPositiveAmount(amountIn) nonReentrant returns (uint256 amountOut) {
        address etfNative = etf.native();
        IERC20(address(etf)).safeTransferFrom(msg.sender, address(this), amountIn);
        amountOut = etf.exit(amountIn);
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        require(tokenIn == etfNative, "ZapperETF: First path elemt neq etf native");  
        if (tokenOut == address(0)) {
            if (etfNative != weth) {
                path[path.length - 1] = weth;
                amountOut = _swap(path, amountOut, address(this), false);
            }
            IWETH(weth).withdraw(amountOut);
            (bool success,) = payable(msg.sender).call{value: amountOut}("");
            require(success, "ZapperETF: Transfer failed");
        } else {
            if (tokenIn != tokenOut) amountOut = _swap(path, amountOut, msg.sender, false);
            else IERC20(etfNative).safeTransfer(msg.sender, amountOut);
        }
        require(amountOut >= minAmountOut, "ZapperETF: AmountOut underflow");
    }

    function updateRouter(address _router) external onlyOwner returns (bool) {
        _updateRouter(_router);
        return true;
    }

    function updateOwnerSource(address _ownerSource) external onlyOwner returns (bool) {
        _updateOwnerSource(_ownerSource);
        return true;
    }

    /* Private methods */
    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _join(
        IETF etf,
        address native,
        uint256 amountIn,
        uint256 minAmountOut
    ) private returns (uint256 amountOut) {
        IERC20(native).approve(address(etf), amountIn);
        amountOut = etf.join(amountIn);
        require(amountOut >= minAmountOut, "ZapperETF: AmountOut underflow");
    }

    function _updateRouter(address _router) private {
        require(_router != address(0), "ZapperETF: Router is zero address");
        router = IPancakeRouter02(_router);
        weth = router.WETH();
        emit RouterUpdated(_router);
    }

    function _updateOwnerSource(address _ownerSource) private {
        require(_ownerSource != address(0), "ZapperETF: Owner source is zero address");
        ownerSource = _ownerSource;
        emit OwnerSourceUpdated(_ownerSource);
    }

    function _swap(
        address[] memory path,
        uint256 amountIn,
        address to,
        bool transferFromRequired
    ) private returns (uint256 tokenAmountOut) {
        IERC20 from = IERC20(path[0]);
        if (transferFromRequired) from.safeTransferFrom(msg.sender, address(this), amountIn);
        from.approve(address(router), amountIn);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            1,
            path,
            to,
            block.timestamp
        );
        tokenAmountOut = amounts[amounts.length - 1];
    }

    /* Modifiers */
    modifier notContract() {
        require(!_isContract(msg.sender), "ZapperETF: Contract not allowed");
        require(msg.sender == tx.origin, "ZapperETF: Proxy contract not allowed");
        _;
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "ZapperETF: Amount is zero");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == Ownable(ownerSource).owner(), "ZapperETF: Caller is not owner");
        _;
    }
}