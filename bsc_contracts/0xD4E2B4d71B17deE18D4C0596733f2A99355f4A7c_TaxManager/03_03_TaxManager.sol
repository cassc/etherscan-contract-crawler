// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TaxManager {
    address public selfTaxPool;
    address public rightUpTaxPool;
    address public maintenancePool;
    address public devPool;
    address public rewardAllocationPool;
    address public perpetualPool;
    address public tierPool;
    address public revenuePool;
    address public marketingPool;
    address public admin;

    uint256 public selfTaxRate;
    uint256 public rightUpTaxRate;
    uint256 public maintenanceTaxRate;
    uint256 public protocolTaxRate;
    uint256 public perpetualPoolTaxRate;
    // uint256 public devPoolTaxRate;
    uint256 public rewardPoolTaxRate;
    uint256 public marketingTaxRate;
    uint256 public constant taxBaseDivisor = 10000;
    struct TaxRates {
        uint256 first;
        uint256 second;
        uint256 third;
        uint256 fourth;
    }
    mapping(uint256 => TaxRates) referralRate;
    uint256 public tierPoolRate;

    modifier onlyAdmin() {
        // Change this to a list with ROLE library
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setAdmin(address account) public onlyAdmin {
        admin = account;
    }

    // Getters and setters for Addresses

    function setSelfTaxPool(address _selfTaxPool) external onlyAdmin {
        selfTaxPool = _selfTaxPool;
    }

    function getSelfTaxPool() external view returns (address) {
        return selfTaxPool;
    }

    function setRightUpTaxPool(address _rightUpTaxPool) external onlyAdmin {
        rightUpTaxPool = _rightUpTaxPool;
    }

    function getRightUpTaxPool() external view returns (address) {
        return rightUpTaxPool;
    }

    function setMaintenancePool(address _maintenancePool) external onlyAdmin {
        maintenancePool = _maintenancePool;
    }

    function getMaintenancePool() external view returns (address) {
        return maintenancePool;
    }

    function setDevPool(address _devPool) external onlyAdmin {
        devPool = _devPool;
    }

    function getDevPool() external view returns (address) {
        return devPool;
    }

    function setRewardAllocationPool(
        address _rewardAllocationPool
    ) external onlyAdmin {
        rewardAllocationPool = _rewardAllocationPool;
    }

    function getRewardAllocationPool() external view returns (address) {
        return rewardAllocationPool;
    }

    function setPerpetualPool(address _perpetualPool) external onlyAdmin {
        perpetualPool = _perpetualPool;
    }

    function getPerpetualPool() external view returns (address) {
        return perpetualPool;
    }

    function setTierPool(address _tierPool) external onlyAdmin {
        tierPool = _tierPool;
    }

    function getTierPool() external view returns (address) {
        return tierPool;
    }

    function setMarketingPool(address _marketingPool) external onlyAdmin {
        marketingPool = _marketingPool;
    }

    function getMarketingPool() external view returns (address) {
        return marketingPool;
    }

    function setRevenuePool(address _revenuePool) external onlyAdmin {
        revenuePool = _revenuePool;
    }

    function getRevenuePool() external view returns (address) {
        return revenuePool;
    }

    // Getters and setters for the Tax Rates

    function setSelfTaxRate(uint256 _selfTaxRate) external onlyAdmin {
        selfTaxRate = _selfTaxRate;
    }

    function getSelfTaxRate() external view returns (uint256) {
        return selfTaxRate;
    }

    function setRightUpTaxRate(uint256 _rightUpTaxRate) external onlyAdmin {
        rightUpTaxRate = _rightUpTaxRate;
    }

    function getRightUpTaxRate() external view returns (uint256) {
        return rightUpTaxRate;
    }

    function setMaintenanceTaxRate(
        uint256 _maintenanceTaxRate
    ) external onlyAdmin {
        maintenanceTaxRate = _maintenanceTaxRate;
    }

    function getMaintenanceTaxRate() external view returns (uint256) {
        return maintenanceTaxRate;
    }

    function setProtocolTaxRate(uint256 _protocolTaxRate) external onlyAdmin {
        protocolTaxRate = _protocolTaxRate;
    }

    function getProtocolTaxRate() external view returns (uint256) {
        return protocolTaxRate + rightUpTaxRate;
    }

    function getTotalTaxAtMint() external view returns (uint256) {
        return protocolTaxRate + rightUpTaxRate + selfTaxRate;
    }

    function setPerpetualPoolTaxRate(
        uint256 _perpetualPoolTaxRate
    ) external onlyAdmin {
        perpetualPoolTaxRate = _perpetualPoolTaxRate;
    }

    function getPerpetualPoolTaxRate() external view returns (uint256) {
        return perpetualPoolTaxRate;
    }

    function getTaxBaseDivisor() external pure returns (uint256) {
        return taxBaseDivisor;
    }

    function setBulkReferralRate(
        uint256 tier,
        uint256 first,
        uint256 second,
        uint256 third,
        uint256 fourth
    ) external onlyAdmin {
        referralRate[tier].first = first;
        referralRate[tier].second = second;
        referralRate[tier].third = third;
        referralRate[tier].fourth = fourth;
    }

    function getReferralRate(
        uint256 depth,
        uint256 tier
    ) external view returns (uint256) {
        if (depth == 1) {
            return referralRate[tier].first;
        } else if (depth == 2) {
            return referralRate[tier].second;
        } else if (depth == 3) {
            return referralRate[tier].third;
        } else if (depth == 4) {
            return referralRate[tier].fourth;
        }
        return 0;
    }

    // function setDevPoolTaxRate(uint256 _devPoolRate) external {
    //     devPoolTaxRate = _devPoolRate;
    // }

    // function getDevPoolRate() external view returns (uint256) {
    //     return devPoolTaxRate;
    // }

    function setRewardPoolTaxRate(uint256 _rewardPoolRate) external onlyAdmin {
        rewardPoolTaxRate = _rewardPoolRate;
    }

    function getRewardPoolRate() external view returns (uint256) {
        return rewardPoolTaxRate;
    }

    function setTierPoolRate(uint256 _tierPoolRate) external onlyAdmin {
        tierPoolRate = _tierPoolRate;
    }

    function getTierPoolRate() external view returns (uint256) {
        return tierPoolRate;
    }

    function setMarketingTaxRate(uint256 _marketingTaxRate) external onlyAdmin {
        marketingTaxRate = _marketingTaxRate;
    }

    function getMarketingTaxRate() external view returns (uint256) {
        return marketingTaxRate;
    }

    function recoverTokens(address token, address benefactor) public onlyAdmin {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(benefactor, tokenBalance);
    }
}