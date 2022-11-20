// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* CL PegSwap */
interface IPegSwap {
    function swap(
        uint256 amount,
        address source,
        address target
    ) external;
}

interface IERC677 is IERC20 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);
}

/* IWERC20 */
interface IWERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address target) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

/* UNI V2 */
interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

error BountyOutOfRange(uint256 value);
error RecoverTokenFailed();
error BountyPayFailed();
error TopUpFailed();
error RevertOnFallback();
error NothingToTrade();

contract GasStation is Ownable {
    using SafeERC20 for IERC20;

    event TopUpVRF(address coordinator, uint64 subscriptionId, address caller);
    event BountyChanged(uint256 newBounty);
    event PayBounty(address caller, uint256 bountyPaid);

    /* ERC677 Chainlink Token, used for payments */
    IERC677 public LINK_ERC677 =
        IERC677(0x404460C6A5EdE2D891e8297795264fDe62ADBB75);

    /* Bridged Chainlink Token */
    IERC20 public LINK_ERC20 =
        IERC20(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD);

    /* Wrapped BNB Token */
    IWERC20 public WRAPPED_ERC20 =
        IWERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    /* Pancake Router */
    IPancakeRouter02 public router =
        IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    /* Chainlink PegSwap Service */
    IPegSwap public pegSwap =
        IPegSwap(0x1FCc3B22955e76Ca48bF025f1A6993685975Bb9e);

    uint256 public topUpBounty = 500; // in bp

    constructor() {}

    function recoverTokens(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = payable(msg.sender).call{
                value: address(this).balance
            }("");
            if (!success) revert RecoverTokenFailed();
        } else {
            IERC20(token).safeTransfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function adjustBounty(uint256 newPercentage) external onlyOwner {
        if (newPercentage > 10000 || newPercentage < 0)
            revert BountyOutOfRange(newPercentage);

        topUpBounty = newPercentage;
        emit BountyChanged(topUpBounty);
    }

    /* Utils */
    function calcBounty(uint256 amountIn) external view returns (uint256) {
        return (amountIn * topUpBounty) / 10000;
    }

    function _payBounty(uint256 amountIn, address caller)
        internal
        returns (uint256)
    {
        uint256 bountyToPay = (amountIn * topUpBounty) / 10000;
        (bool success, ) = payable(caller).call{value: bountyToPay}("");
        if (!success) revert BountyPayFailed();

        return address(this).balance;
    }

    function _topUpVRF(
        address coordinator,
        uint64 subscriptionId,
        uint256 amountIn
    ) internal {
        bool success = LINK_ERC677.transferAndCall(
            coordinator,
            amountIn,
            abi.encode(subscriptionId)
        );
        if (!success) revert TopUpFailed();
    }

    function _swapToERC677(uint256 amountIn) internal returns (uint256) {
        LINK_ERC20.approve(address(pegSwap), amountIn);

        pegSwap.swap(amountIn, address(LINK_ERC20), address(LINK_ERC677));
        return IERC20(LINK_ERC677).balanceOf(address(this));
    }

    function _wrapBNB(uint256 amount) internal returns (uint256) {
        WRAPPED_ERC20.deposit{value: amount}();
        uint256 amountWrapped = WRAPPED_ERC20.balanceOf(address(this));
        return amountWrapped;
    }

    function _swapToLINK(uint256 amountIn) internal returns (uint256) {
        WRAPPED_ERC20.approve(address(router), amountIn);
        address[] memory path;
        path = new address[](2);
        path[0] = address(WRAPPED_ERC20);
        path[1] = address(LINK_ERC20);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        );

        return amounts[1];
    }

    /* Top up the VRF Subscription and pay bounty to caller */
    function topUp(
        address coordinator,
        uint64 subscriptionId,
        address caller
    ) external payable {
		if (msg.value == 0) revert NothingToTrade();
        /* Pay Incentive */
        uint256 out = _payBounty(msg.value, caller);
        /* Wrap BNB to WBNB */
        out = _wrapBNB(out);
        /* Swap to LINK from WBNB */
        out = _swapToLINK(out);
        /* PegSwap to ERC677 */
        out = _swapToERC677(out);
        /* Top Up Sub */
        _topUpVRF(coordinator, subscriptionId, out);

        emit TopUpVRF(coordinator, subscriptionId, caller);
    }

    /* Why do you send tokens here?? */
    receive() external payable {
        revert RevertOnFallback();
    }

    fallback() external payable {
        revert RevertOnFallback();
    }
}