// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./LiquidityMiningLogic.sol";

contract ProxyLiquidityMining is LiquidityMiningLogic, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable router;
    IERC20 public immutable secondToken;
    IERC20 public immutable pair;

    constructor(
        address router_,
        address _DFI,
        address _secondToken,
        address _pair,
        uint256 _admin_speed
    ) LiquidityMiningLogic(_DFI, _admin_speed) {
        router = IUniswapV2Router02(router_);
        secondToken = IERC20(_secondToken);
        pair = IERC20(_pair);
        IERC20(_DFI).safeApprove(router_, MAX_INT);
        IERC20(_secondToken).safeApprove(router_, MAX_INT);
        IERC20(_pair).safeApprove(router_, MAX_INT);
    }

    /**
     * @notice Add liquidity to the pool
     * User will need to approve this proxy to spend their at least
     * "amountDFIDesired" amount and "amountsecondTokenDesired" amount first
     * @param amountDFIDesired maximum amount of DFI to be deposited into DFI-secondToken pool (required by UniswapV2Router02)
     * @param amountsecondTokenDesired maximum amount of secondToken to be deposited into DFI-secondToken pool (required by UniswapV2Router02)
     * @param amountDFIMin minimum amount of DFI to be deposited into DFI-secondToken pool (required by UniswapV2Router02)
     * @param amountsecondTokenMin minimum amount of secondToken to be deposited into DFI-secondToken pool (required by UniswapV2Router02)
     * @param deadline the deadline required by UniswapV2Router02
     */
    function addLiquidity(
        uint256 amountDFIDesired,
        uint256 amountsecondTokenDesired,
        uint256 amountDFIMin,
        uint256 amountsecondTokenMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (
            uint256 amountDFI,
            uint256 amountsecondToken,
            uint256 liquidity
        )
    {
        beforeHook(msg.sender);
        DFI.safeTransferFrom(msg.sender, address(this), amountDFIDesired);
        secondToken.safeTransferFrom(
            msg.sender,
            address(this),
            amountsecondTokenDesired
        );
        // amountDFI: actual amount of DFI sent to the pair
        // amountsecondToken: actual amount of secondToken sent to the pair
        (amountDFI, amountsecondToken, liquidity) = router.addLiquidity(
            address(DFI),
            address(secondToken),
            amountDFIDesired,
            amountsecondTokenDesired,
            amountDFIMin,
            amountsecondTokenMin,
            address(this),
            deadline
        );
        _addLiquidity(msg.sender, liquidity);
        uint256 returnDFI = amountDFIDesired - amountDFI;
        uint256 returnsecondToken = amountsecondTokenDesired -
            amountsecondToken;
        if (returnDFI > 0) DFI.safeTransfer(msg.sender, returnDFI);
        if (returnsecondToken > 0)
            secondToken.safeTransfer(msg.sender, returnsecondToken);
        emit LIQUIDITY_ADDED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity from the pool, user is going to receive
     * their share of DFI + secondToken from the DFI-secondToken  pool and DFI rewards thanks to liquidity mining
     * @param liquidity the amount of LP tokens that is going to be unstaked
     * @param amountDFIMin the minimum DFI tokens that is going to be returned to staker (from the Uniswap DFI-secondToken pool)
     * @param amountsecondTokenMin minimum secondToken tokens that is going to be returned to staker (from the Uniswap DFI-secondToken pool)
     * @param deadline the deadline for this action to be performed
     */
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountsecondTokenMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountDFI, uint256 amountsecondToken)
    {
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        beforeHook(msg.sender);
        _removeLiquidity(msg.sender, liquidity);
        _claimRewards(msg.sender);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountsecondToken) = router.removeLiquidity(
            address(DFI),
            address(secondToken),
            liquidity,
            amountDFIMin,
            amountsecondTokenMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice remove liquidity from the pool without claiming rewards
     */
    function removeLiquidityWithoutClaimingRewards(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountsecondTokenMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountDFI, uint256 amountsecondToken)
    {
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        beforeHook(msg.sender);
        _removeLiquidity(msg.sender, liquidity);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountsecondToken) = router.removeLiquidity(
            address(DFI),
            address(secondToken),
            liquidity,
            amountDFIMin,
            amountsecondTokenMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }


    /**
     * @notice remove liquidity from the pool in case of emergency
     */
    function removeLiquidityInEmergency(
        uint256 liquidity,
        uint256 amountDFIMin,
        uint256 amountsecondTokenMin,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountDFI, uint256 amountsecondToken)
    {
        require(emergency, "Not be in emergency mode yet");
        require(
            stakingMap[msg.sender] >= liquidity,
            "User does not have enough liquidity"
        );
        _removeLiquidity(msg.sender, liquidity);
        // router will send "liquidity" LP tokens back to the pool
        // for burning
        (amountDFI, amountsecondToken) = router.removeLiquidity(
            address(DFI),
            address(secondToken),
            liquidity,
            amountDFIMin,
            amountsecondTokenMin,
            msg.sender,
            deadline
        );
        emit LIQUIDITY_REMOVED(msg.sender, liquidity);
    }

    /**
     * @notice reset the allowance for the router by this contract, 
     * in case the allowances are too low
     */
    function resetAllowances() external {
        address routerAddr = address(router);
        DFI.safeApprove(routerAddr, 0);
        DFI.safeApprove(routerAddr, MAX_INT);
        secondToken.safeApprove(routerAddr, 0);
        secondToken.safeApprove(routerAddr, MAX_INT);
        pair.safeApprove(routerAddr, 0);
        pair.safeApprove(routerAddr, MAX_INT);
    }
}