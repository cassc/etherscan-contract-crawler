// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ProxyLiquidityMining.sol";

contract ProxyLiquidityMiningETH is ProxyLiquidityMining {
    using SafeERC20 for IERC20;

    constructor(
        address router_,
        address _DFI,
        address _secondToken,
        address _pair,
        uint256 _admin_speed
    ) ProxyLiquidityMining(router_, _DFI, _secondToken, _pair, _admin_speed) {}

    /**
     * @notice Add liquidity to the pool
     * User will need to approve this proxy to spend their at least
     * "amountDFIDesired" amount first
     * @param amountDFIDesired maximum amount of DFI to be deposited into DFI-ETH pool (required by UniswapV2Router02)
     * @param amountDFIMin minimum amount of DFI to be deposited into DFI-ETH pool (required by UniswapV2Router02)
     * @param amountETHMin minimum amount of ETH/WETH to be deposited into DFI-ETH pool (required by UniswapV2Router02)
     * @param deadline the deadline required by UniswapV2Router02
     */
    function addLiquidityETH(
        uint256 amountDFIDesired,
        uint256 amountDFIMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        nonReentrant
        returns (
            uint256 amountDFI,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        beforeHook(msg.sender);
        DFI.safeTransferFrom(msg.sender, address(this), amountDFIDesired);
        // amountDFI: actual amount of DFI sent to the pair
        // amountETH: actual amount of WETH sent to the pair
        (amountDFI, amountETH, liquidity) = router.addLiquidityETH{
            value: msg.value
        }(
            address(DFI),
            amountDFIDesired,
            amountDFIMin,
            amountETHMin,
            address(this),
            deadline
        );
        _addLiquidity(msg.sender, liquidity);
        uint256 returnDFI = amountDFIDesired - amountDFI;
        uint256 returnETH = msg.value - amountETH;
        if (returnDFI > 0) DFI.safeTransfer(msg.sender, returnDFI);
        if (returnETH > 0) {
            (bool sent, ) = payable(msg.sender).call{value: returnETH}("");
            require(sent, "Failed to return redundant Ether back to user");
        }
        emit LIQUIDITY_ADDED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity from the pool, user is going to receive
     * their share of DFI + ETH from the DFI-ETH  pool and DFI rewards thanks to liquidity mining
     * @param liquidity the amount of LP tokens that is going to be unstaked
     * @param amountDFIMin the minimum DFI tokens that is going to be returned to staker (from the Uniswap DFI-ETH pool)
     * @param amountETHMin minimum ETH that is going to be returned to staker (from the Uniswap DFI-ETH pool)
     * @param deadline the deadline for this action to be performed
     */
    function removeLiquidityETH(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountDFI, uint256 amountETH) {
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        beforeHook(msg.sender);
        _removeLiquidity(msg.sender, liquidity);
        _claimRewards(msg.sender);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountETH) = router.removeLiquidityETH(
            address(DFI),
            liquidity,
            amountDFIMin,
            amountETHMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity from the pool without claiming rewards
     */
    function removeLiquidityETHWithoutClaimingRewards(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountDFI, uint256 amountETH) {
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        beforeHook(msg.sender);
        _removeLiquidity(msg.sender, liquidity);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountETH) = router.removeLiquidityETH(
            address(DFI),
            liquidity,
            amountDFIMin,
            amountETHMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity in emergency
     */
    function removeLiquidityETHInEmergency(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountDFI, uint256 amountETH) {
        require(emergency, "Not in emergency mode yet");
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        _removeLiquidity(msg.sender, liquidity);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountETH) = router.removeLiquidityETH(
            address(DFI),
            liquidity,
            amountDFIMin,
            amountETHMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice main purpose is to allow the router to pay back ETH to this contract
     * when the ratio of DFI/ETH deposited is not ideal
     */
    receive() external payable {}
}