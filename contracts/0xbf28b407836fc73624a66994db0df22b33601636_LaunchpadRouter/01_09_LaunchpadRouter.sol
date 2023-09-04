// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/launchpad/ILaunchpadRouter.sol";
import "../interfaces/launchpad/ILaunchpadPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LaunchpadRouter is Ownable, ILaunchpadRouter {
    using SafeERC20 for IERC20;

    uint256 internal constant MAX_AMOUNT = uint256(-1);
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(string => address) public pools;

    constructor(address _owner) Ownable() {
        if (_owner != msg.sender) {
            transferOwnership(_owner);
        }
    }

    // ============ Safety Purposes, this contract should not hold values ==============

    receive() external payable {}

    function withdrawToken(
        address token,
        uint256 amount,
        address sendTo
    ) external onlyOwner {
        IERC20(token).safeTransfer(sendTo, amount);
    }

    function withdrawEther(uint256 amount, address payable sendTo) external onlyOwner {
        (bool success, ) = sendTo.call{value: amount}("");
        require(success, "withdraw failed");
    }

    // ============ Admin functions  ==============
    function updatePools(string[] calldata poolIds, address[] calldata poolAddresses)
        external
        onlyOwner
    {
        require(poolIds.length == poolAddresses.length, "mismatch length");
        for (uint256 i = 0; i < poolIds.length; i++) {
            pools[poolIds[i]] = poolAddresses[i];
        }
    }

    // ============ Main View Functions ==============
    function getPools(string[] calldata poolIds)
        external
        view
        override
        returns (address[] memory poolAddresses)
    {
        poolAddresses = new address[](poolIds.length);
        for (uint256 i = 0; i < poolIds.length; i++) {
            poolAddresses[i] = pools[poolIds[i]];
        }
    }

    function getPoolDetails(string[] calldata poolIds)
        external
        view
        override
        returns (ILaunchpadPool.PoolDetail[] memory poolDetails)
    {
        poolDetails = new ILaunchpadPool.PoolDetail[](poolIds.length);
        for (uint256 i = 0; i < poolIds.length; i++) {
            ILaunchpadPool pool = ILaunchpadPool(pools[poolIds[i]]);
            if (pool != ILaunchpadPool(0)) {
                poolDetails[i] = pool.getPoolDetail();
            }
        }
    }

    function getUserDetails(string calldata poolId, address[] calldata userAddresses)
        external
        view
        override
        returns (ILaunchpadPool.UserDetail[] memory)
    {
        return _pool(poolId).getUserDetails(userAddresses);
    }

    function purchase(
        string calldata poolId,
        address paymentToken,
        uint256 paymentAmount,
        uint256[] calldata purchaseAmount,
        uint256[] calldata purchaseCap,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    ) external payable override {
        _processPayment(paymentToken, paymentAmount);

        ILaunchpadPool pool = _pool(poolId);

        if (paymentToken == NATIVE_TOKEN_ADDRESS) {
            pool.purchase{value: paymentAmount}(
                msg.sender,
                paymentToken,
                paymentAmount,
                purchaseAmount,
                purchaseCap,
                merkleProof,
                signature
            );
        } else {
            _safeApproveAllowance(address(pool), paymentToken);
            pool.purchase(
                msg.sender,
                paymentToken,
                paymentAmount,
                purchaseAmount,
                purchaseCap,
                merkleProof,
                signature
            );
        }
    }

    function vest(string calldata poolId, uint256[] calldata vestAmount) external override {
        _pool(poolId).vest(msg.sender, vestAmount);
    }

    // ============ Internal Functions ==============
    function _processPayment(address paymentToken, uint256 paymentAmount) private {
        if (paymentToken == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == paymentAmount, "payment: wrong received amount");
        } else {
            require(msg.value == 0, "payment: extra received amount");
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), paymentAmount);
        }
    }

    function _pool(string calldata poolId) private view returns (ILaunchpadPool pool) {
        pool = ILaunchpadPool(pools[poolId]);
        require(pool != ILaunchpadPool(0), "pool not exist");
    }

    function _safeApproveAllowance(address spender, address token) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, MAX_AMOUNT);
        }
    }
}