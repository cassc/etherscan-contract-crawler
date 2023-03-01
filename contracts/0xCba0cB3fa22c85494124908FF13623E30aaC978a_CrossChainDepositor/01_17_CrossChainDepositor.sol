// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/LogicUpgradeable.sol";
import "../Interfaces/IStargateRouter.sol";

contract CrossChainDepositor is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private accumulatedDepositor;
    address private stargateRouter;
    mapping(address => uint8) private stargateTokenPoolId;
    uint256 stargateDstGasForCall;

    event SetAccumulatedDepositor(address accumulatedDepositor);
    event SetStargateTokenPoolId(address token, uint8 poolId);
    event SetStargateDstGasForCall(uint256 stargateDstGasForCall);
    event DepositStargate(
        uint16 chainId,
        uint8 srcPoolId,
        uint8 dstPoolId,
        uint256 amountIn,
        uint256 dstGasForCall,
        uint256 gasFee,
        address depositor,
        address accumulatedDepositor,
        address stargateRouter
    );

    function __CrossChainDepositor_init() public initializer {
        LogicUpgradeable.initialize();
    }

    receive() external payable {}

    fallback() external payable {}

    modifier isUsedStargateToken(address token) {
        require(stargateTokenPoolId[token] != 0, "CD1");
        _;
    }

    /*** User function ***/

    /**
     * @notice Set AccumulatedDepositor address on destination chain
     * @param _accumulatedDepositor Address AccumulatedDepositor on destination chain
     */
    function setAccumulatedDepositor(address _accumulatedDepositor)
        external
        onlyOwner
    {
        accumulatedDepositor = _accumulatedDepositor;

        emit SetAccumulatedDepositor(_accumulatedDepositor);
    }

    /**
     * @notice set stargateRouter
     * @param _stargateRouter StargateRouter address
     */
    function setStargateRouter(address _stargateRouter) external onlyOwner {
        stargateRouter = _stargateRouter;
    }

    /**
     * @notice Set stargateDstGasForCall value that gas amount for destination chain
     * @param _stargateDstGasForCall Amount of DstGasForCall
     */
    function setStargateDstGasForCall(uint256 _stargateDstGasForCall)
        external
        onlyOwner
    {
        stargateDstGasForCall = _stargateDstGasForCall;

        emit SetStargateDstGasForCall(_stargateDstGasForCall);
    }

    /**
     * @notice Add Stargate accepted token and poolID
     * @param token Address of Token for deposited
     * @param poolId Pool ID defined in Stargate
     */
    function addStargateToken(address token, uint8 poolId) external onlyOwner {
        require(token != address(0), "CD2");
        require(stargateTokenPoolId[token] == 0, "CD3");

        stargateTokenPoolId[token] = poolId;

        emit SetStargateTokenPoolId(token, poolId);
    }

    /**
     * @notice Estimate swap fee for Stargate
     * @param chainId Destination chainId
     * @param dstGasForCall Destination required gas for call
     */
    function getDepositFeeStargate(uint16 chainId, uint256 dstGasForCall)
        public
        view
        returns (uint256 feeWei)
    {
        require(accumulatedDepositor != address(0), "CD4");

        bytes memory data = abi.encode(msg.sender);

        (feeWei, ) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            chainId,
            1, // swap remote
            abi.encodePacked(accumulatedDepositor),
            data,
            IStargateRouter.lzTxObj(
                dstGasForCall,
                0,
                abi.encodePacked(accumulatedDepositor)
            )
        );
    }

    /**
     * @notice Deposit stablecoin to destination chain
     * @param chainId Destination chainId
     * @param srcToken stablecoin address in source chain
     * @param dstToken stablecoin address in destination chain
     * @param amountIn deposit amount
     * @param amountOutMin expected out amount minimum
     * @param dstGasForCall Destination required gas for call
     */
    function depositStarGate(
        uint16 chainId,
        address srcToken,
        address dstToken,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 dstGasForCall
    )
        external
        payable
        isUsedStargateToken(srcToken)
        isUsedStargateToken(dstToken)
    {
        address _accumulatedDepositor = accumulatedDepositor;

        require(msg.value > 0, "CD5");
        require(_accumulatedDepositor != address(0), "CD4");
        require(amountIn > 0, "CD6");
        require(
            stargateDstGasForCall > 0 && stargateDstGasForCall <= dstGasForCall,
            "CD8"
        );

        // Estimate gas fee
        uint256 feeWei = getDepositFeeStargate(chainId, dstGasForCall);
        require(msg.value >= feeWei, "CD7");

        // Take token from user wallet
        IERC20Upgradeable(srcToken).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        // Approve token for swap
        IERC20Upgradeable(srcToken).safeApprove(
            address(stargateRouter),
            amountIn
        );

        // Swap via Stargate
        IStargateRouter(stargateRouter).swap{value: msg.value}(
            chainId,
            stargateTokenPoolId[srcToken],
            stargateTokenPoolId[dstToken],
            payable(msg.sender),
            amountIn,
            amountOutMin,
            IStargateRouter.lzTxObj(dstGasForCall, 0, "0x"),
            abi.encodePacked(_accumulatedDepositor),
            abi.encode(msg.sender)
        );

        emit DepositStargate(
            chainId,
            stargateTokenPoolId[srcToken],
            stargateTokenPoolId[dstToken],
            amountIn,
            dstGasForCall,
            msg.value,
            msg.sender,
            _accumulatedDepositor,
            stargateRouter
        );
    }
}