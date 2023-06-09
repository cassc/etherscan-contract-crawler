// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@shared/lib-contracts-v0.8/contracts/Dependencies/AddressLib.sol";
import "./Interfaces/IRewards.sol";
import "./Interfaces/IPendleProxyMainchain.sol";
import "./Interfaces/Pendle/IPFeeDistributorV2.sol";
import "./Interfaces/Pendle/IPVotingController.sol";
import "./Interfaces/Pendle/IPVotingEscrowMainchain.sol";
import "./PendleProxyBaseUpg.sol";

contract PendleProxyMainchain is PendleProxyBaseUpg, IPendleProxyMainchain {
    using SafeERC20 for IERC20;

    address public pendle;
    address public pendleVotingController;

    address public depositor;

    address public ePendleRewardPool;

    address public feeDistributorV2;

    address public feeCollector;

    bytes32 public constant FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
    bytes32 public constant VOTE_ADMIN_ROLE = keccak256("VOTE_ADMIN_ROLE");

    function initialize() public initializer {
        __PendleProxyBaseUpg_init();
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "!auth");
        _;
    }

    function setParams(
        address _pendleMarketFactory,
        address _pendleVotingController,
        address _booster,
        address _depositor,
        address _ePendleRewardPool,
        address _feeDistributorV2,
        address _feeCollector
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _pendleVotingController != address(0),
            "invalid _pendleVotingController"
        );
        require(_depositor != address(0), "invalid _depositor!");
        require(
            _ePendleRewardPool != address(0),
            "invalid _ePendleRewardPool!"
        );
        require(_feeDistributorV2 != address(0), "invalid _feeDistributorV2!");
        require(_feeCollector != address(0), "invalid _feeCollector!");

        _setParams(_pendleMarketFactory, _booster);

        pendle = IPVotingEscrowMainchain(vePendle).pendle();
        pendleVotingController = _pendleVotingController;

        depositor = _depositor;
        ePendleRewardPool = _ePendleRewardPool;
        feeDistributorV2 = _feeDistributorV2;
        feeCollector = _feeCollector;

        emit DepositorUpdated(_depositor);
        emit EPendleRewardPoolUpdated(_ePendleRewardPool);
        emit FeeDistributorV2Updated(_feeDistributorV2);
        emit FeeCollectorUpdated(_feeCollector);
    }

    function setFeeCollector(
        address _feeCollector
    ) external onlyRole(FEE_ADMIN_ROLE) {
        require(_feeCollector != address(0), "invalid _feeCollector!");
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(_feeCollector);
    }

    function lockPendle(uint128 _expiry) external override onlyDepositor {
        uint256 balance = IERC20(pendle).balanceOf(address(this));

        if (balance > 0) {
            IERC20(pendle).safeApprove(vePendle, 0);
            IERC20(pendle).safeApprove(vePendle, balance);
        }

        IPVotingEscrowMainchain(vePendle).increaseLockPosition(
            uint128(balance),
            _expiry
        );

        emit PendleLocked(uint128(balance), _expiry);
    }

    function vote(
        address[] calldata _pools,
        uint64[] calldata _weights
    ) external onlyRole(VOTE_ADMIN_ROLE) {
        IPVotingController(pendleVotingController).vote(_pools, _weights);
    }

    function claimYTFees() external onlyRole(FEE_ADMIN_ROLE) {
        address[] memory pools = new address[](1);
        pools[0] = vePendle;
        (
            uint256 totalAmountOut,
            uint256[] memory amountsOut
        ) = IPFeeDistributorV2(feeDistributorV2).claimProtocol(
                address(this),
                pools
            );

        if (totalAmountOut == 0) {
            return;
        }

        IRewards(ePendleRewardPool).queueNewRewards{value: totalAmountOut}(
            AddressLib.PLATFORM_TOKEN_ADDRESS,
            totalAmountOut
        );

        emit FeesClaimed(pools, totalAmountOut, amountsOut);
    }

    function claimSwapFees(
        address[] calldata _pools
    ) external onlyRole(FEE_ADMIN_ROLE) {
        for (uint256 i = 0; i < _pools.length; i++) {
            require(_pools[i] != vePendle, "cannot claim vePendle fees!");
        }

        (
            uint256 totalAmountOut,
            uint256[] memory amountsOut
        ) = IPFeeDistributorV2(feeDistributorV2).claimProtocol(
                feeCollector,
                _pools
            );

        emit FeesClaimed(_pools, totalAmountOut, amountsOut);
    }
}