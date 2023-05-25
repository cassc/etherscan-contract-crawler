// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IStakingFactory.sol";
import "./lib/BurnableBase.sol";

abstract contract SwapTokenBase is AccessControl, BurnableBase {
    using SafeERC20 for IERC20;

    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    address internal immutable _WETH;
    address internal immutable _wallet;
    uint256 public immutable fee;
    IStakingFactory public immutable staking;

    event Swap(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    event StakingFee(address indexed token, uint256 amount);

    constructor(uint256 fee_, address wallet_, address staking_) {
        _WETH = UNISWAP_V2_ROUTER().WETH();
        fee = fee_;
        _wallet = wallet_;
        staking = IStakingFactory(staking_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(DEVELOPER, msg.sender);
        IERC20(WETH()).approve(address(UNISWAP_V2_ROUTER()), type(uint256).max);
    }

    function WETH() public view virtual override returns (address) {
        return _WETH;
    }

    function beneficiary() public view virtual override returns (address) {
        return _wallet;
    }

    function swapTokenForToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        uint256 realAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        uint256 feeAmount = (realAmountIn * fee) / 10000;
        uint256 stakingFee = _distributeStakingReward(tokenIn, feeAmount);
        uint256 amountInSub = realAmountIn - feeAmount - stakingFee;

        _approve(tokenIn, amountInSub + feeAmount);

        UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInSub,
            _amountOutMin,
            _path,
            msg.sender,
            block.timestamp
        );
        _burn(feeAmount, _path);
        emit Swap(msg.sender, tokenIn, _path[_path.length - 1], realAmountIn, _amountOutMin);
    }

    function swapTokenForExactToken(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountInMax);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        uint256 adjustedFee = (adjustedAmountIn * fee) / 10000;
        uint256 stakingFee = _distributeStakingReward(tokenIn, adjustedFee);

        _approve(tokenIn, adjustedAmountIn - stakingFee);

        uint256[] memory amounts = UNISWAP_V2_ROUTER().swapTokensForExactTokens(
            _amountOut,
            adjustedAmountIn - adjustedFee - stakingFee,
            _path,
            msg.sender,
            block.timestamp
        );

        uint256 realAmountIn = amounts[0];
        uint256 refundAmount = adjustedAmountIn - realAmountIn - adjustedFee - stakingFee;
        if (refundAmount > 0) {
            IERC20(tokenIn).safeTransfer(msg.sender, refundAmount);
        }
        _burn(adjustedFee, _path);

        emit Swap(msg.sender, tokenIn, _path[_path.length - 1], realAmountIn, _amountOut);
    }

    function swapTokenForETH(uint256 _amountIn, uint256 _amountOutMin, address[] memory _path) public validate(_path) {
        require(_path[_path.length - 1] == WETH(), "INVALID_PATH");
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        if (tokenIn == WETH()) {
            IWETH(WETH()).withdraw(adjustedAmountIn);
            _safeTransfer(msg.sender, adjustedAmountIn);
            emit Swap(msg.sender, tokenIn, WETH(), adjustedAmountIn, adjustedAmountIn);
        } else {
            uint256 feeAmount = (adjustedAmountIn * fee) / 10000;
            uint256 stakingFee = _distributeStakingReward(tokenIn, feeAmount);
            uint256 amountInSub = adjustedAmountIn - feeAmount - stakingFee;
            _approve(tokenIn, amountInSub + feeAmount);
            UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountInSub,
                _amountOutMin,
                _path,
                msg.sender,
                block.timestamp
            );
            _burn(feeAmount, _path);
            emit Swap(msg.sender, tokenIn, WETH(), adjustedAmountIn, _amountOutMin);
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

        if (tokenIn == WETH()) {
            IWETH(WETH()).withdraw(adjustedAmountIn);
            _safeTransfer(msg.sender, adjustedAmountIn);
            emit Swap(msg.sender, tokenIn, WETH(), adjustedAmountIn, adjustedAmountIn);
        } else {
            uint256 adjustedFee = (adjustedAmountIn * fee) / 10000;
            uint256 stakingFee = _distributeStakingReward(tokenIn, adjustedFee);
            _approve(tokenIn, adjustedAmountIn - stakingFee);
            uint256[] memory amounts = UNISWAP_V2_ROUTER().swapTokensForExactETH(
                _amountOut,
                adjustedAmountIn - adjustedFee - stakingFee,
                _path,
                msg.sender,
                block.timestamp
            );
            uint256 realAmountIn = amounts[0];
            uint256 refundAmount = adjustedAmountIn - realAmountIn - adjustedFee - stakingFee;
            if (refundAmount > 0) {
                IERC20(tokenIn).safeTransfer(msg.sender, refundAmount);
            }
            _burn(adjustedFee, _path);
            emit Swap(msg.sender, tokenIn, WETH(), realAmountIn, _amountOut);
        }
    }

    function swapETHForToken(uint256 _amountOutMin, address[] memory _path) public payable validate(_path) {
        require(_path[0] == WETH(), "INVALID_PATH");
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH()) {
            IWETH(WETH()).deposit{value: amountIn}();
            IERC20(WETH()).safeTransfer(msg.sender, amountIn);
            emit Swap(msg.sender, WETH(), tokenOut, amountIn, amountIn);
        } else {
            uint256 feeAmount = (amountIn * fee) / 10000;
            uint256 amountInSub = amountIn - feeAmount;
            UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInSub}(
                _amountOutMin,
                _path,
                msg.sender,
                block.timestamp
            );
            IWETH(WETH()).deposit{value: feeAmount}();
            _burn(feeAmount, _path);
            emit Swap(msg.sender, WETH(), tokenOut, amountIn, _amountOutMin);
        }
    }

    function swapETHforExactToken(uint256 _amountOut, address[] memory _path) public payable validate(_path) {
        require(_path[0] == WETH(), "INVALID_PATH");
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH()) {
            IWETH(WETH()).deposit{value: amountIn}();
            IERC20(WETH()).safeTransfer(msg.sender, amountIn);
            emit Swap(msg.sender, WETH(), tokenOut, amountIn, amountIn);
        } else {
            uint256 feeAmount = (amountIn * fee) / 10000;
            uint256 amountInSub = amountIn - feeAmount;
            uint256[] memory amounts = UNISWAP_V2_ROUTER().swapETHForExactTokens{value: amountInSub}(
                _amountOut,
                _path,
                msg.sender,
                block.timestamp
            );
            uint256 refund = amountInSub - amounts[0];
            if (refund > 0) {
                _safeTransfer(msg.sender, refund);
            }
            IWETH(WETH()).deposit{value: feeAmount}();
            _burn(feeAmount, _path);
            emit Swap(msg.sender, WETH(), tokenOut, amounts[0], _amountOut);
        }
    }

    function getPair(address _tokenIn, address _tokenOut) external view returns (address) {
        return UNISWAP_FACTORY().getPair(_tokenIn, _tokenOut);
    }

    function getAmountIn(uint256 _amountOut, address[] memory _path) public view returns (uint256) {
        uint256[] memory amountsIn = UNISWAP_V2_ROUTER().getAmountsIn(_amountOut, _path);
        return amountsIn[0];
    }

    function getAmountOutMinWithFees(uint256 _amountIn, address[] memory _path) public view returns (uint256) {
        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 amountInSub = _amountIn - feeAmount;

        uint256[] memory amountOutMins = UNISWAP_V2_ROUTER().getAmountsOut(amountInSub, _path);
        return amountOutMins[amountOutMins.length - 1];
    }

    function _distributeStakingReward(address token, uint256 amount) internal returns (uint256) {
        address pool = staking.getPoolForRewardDistribution(token);
        if (pool != address(0)) {
            IERC20(token).safeTransfer(pool, amount);
            emit StakingFee(token, amount);
            return amount;
        }
        return 0;
    }

    function _safeTransfer(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getTokenDecimals(address _addr) public view returns (uint8) {
        return IERC20Metadata(_addr).decimals();
    }

    /// @dev USDTs token implementation does not conform to the ERC20 standard
    /// first of all it requires an allowance to be set to zero before it can be set to a new value, therefore we set the allowance to zero here first
    /// secondly the return type does not conform to the ERC20 standard, therefore we ignore the return value
    function _approve(address token, uint256 amount) internal {
        if (token == WETH()) return;
        (bool success, ) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", address(UNISWAP_V2_ROUTER()), 0)
        );
        require(success, "Approval to zero failed");
        (success, ) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", address(UNISWAP_V2_ROUTER()), amount)
        );
        require(success, "Approval failed");
    }

    receive() external payable {}
}