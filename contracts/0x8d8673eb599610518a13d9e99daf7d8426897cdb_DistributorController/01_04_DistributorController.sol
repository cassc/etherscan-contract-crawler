pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface ICumulativeMerkleDistributor {
    function updateRoot(bytes32 _newRoot) external;

    function withdrawTokens(address _to, uint256 _amount) external;

    function withdrawNative(address _to, uint256 _amount) external;

    function transferOwnership(address newOwner) external;

    function TOKEN() external returns (address);
}

contract DistributorController is Ownable {
    ICumulativeMerkleDistributor public immutable distributor;
    IERC20 public immutable rewardToken;
    address public rewardsSupplier;
    address public distributorAdmin;

    event RewardsSupplierUpdated(address newRewardsSupplier);

    error OnlyDistributorAdmin();
    event DistributorAdminUpdated(address newDistributorAdmin);

    error ForbiddenZeroAddress();
    error RewardTokenMismatch();

    event DistributionHalted();
    event EmergencyWithdrawal();

    modifier onlyDistributorAdmin() {
        if (msg.sender != distributorAdmin && msg.sender != owner()) revert OnlyDistributorAdmin();
        _;
    }

    constructor(
        address owner,
        ICumulativeMerkleDistributor _distributor,
        IERC20 _rewardToken
    ) {
        _transferOwnership(owner);
        rewardsSupplier = owner;
        distributorAdmin = owner;

        if (address(_distributor) == address(0)) revert ForbiddenZeroAddress();
        if (address(_rewardToken) != _distributor.TOKEN()) revert RewardTokenMismatch();

        distributor = _distributor;
        rewardToken = _rewardToken;
    }

    function updateMerkleRootAndTransferRewards(
        bytes32 merkleRoot,
        uint256 totalRewards,
        bool resetRoot
    ) external onlyDistributorAdmin {
        if (totalRewards > 0) rewardToken.transferFrom(rewardsSupplier, address(distributor), totalRewards);
        if (resetRoot) distributor.updateRoot(bytes32(0));
        distributor.updateRoot(merkleRoot);
    }

    function transferRewardsOnly(uint256 totalRewards) external onlyDistributorAdmin {
        rewardToken.transferFrom(rewardsSupplier, address(distributor), totalRewards);
    }

    // utility functions to collect non claimed rewards
    function withdrawTokensFromDistributor(uint256 amount) external onlyOwner {
        distributor.withdrawTokens(msg.sender, amount);
    }

    function withdrawNativeTokensFromDistributor(uint256 amount) external onlyOwner {
        distributor.withdrawNative(msg.sender, amount);
    }

    // utility functions to manage roles
    function setRewardsSupplier(address _newRewardsSupplier) external onlyOwner {
        rewardsSupplier = _newRewardsSupplier;
        emit RewardsSupplierUpdated(_newRewardsSupplier);
    }

    function setDistributorAdmin(address _newDistributorAdmin) external onlyOwner {
        distributorAdmin = _newDistributorAdmin;
        emit DistributorAdminUpdated(_newDistributorAdmin);
    }

    function transferDistributorOwnership(address newDistributorOwner) external onlyOwner {
        if (newDistributorOwner == address(0)) revert ForbiddenZeroAddress();
        distributor.transferOwnership(newDistributorOwner);
    }

    // functions for emergency usage only, the features are already possible by combining the rest of the functions
    function haltDistribution() external onlyOwner {
        distributor.updateRoot(bytes32(0));
        distributor.updateRoot(bytes32(0));
        rewardsSupplier = address(0);
        distributorAdmin = address(0);

        emit DistributionHalted();
    }

    function emergencyWithdraw() external onlyOwner {
        distributor.withdrawTokens(msg.sender, type(uint256).max);
        distributor.withdrawNative(msg.sender, type(uint256).max);

        emit EmergencyWithdrawal();
    }
}