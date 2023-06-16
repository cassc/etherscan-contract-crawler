// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IProxyVault {
    function initialize(
        address _feeManager,
        address _depositToken,
        uint256 _initAmount,
        uint256 _maturityTimestamp,
        uint256 _assetId,
        address _receipt1155,
        bytes calldata _data,
        bytes calldata _depositBytes
    ) external;

    function deposit(uint256 _amount, bytes calldata _depositBytes) external;
    function withdrawMatured(
        address destination, 
        bool toUser, 
        address user, 
        uint256 userAmount
    ) external returns (uint256 withdrawnAmount);
    function claimRewards() external returns (address[] memory rewardTokens, uint256[] memory amountEarned);
    function rescue(address _token, uint256 _amount) external;
    function getRewardDestination() external view returns (address);
    function getFeeManager() external view returns (address);
    function getDepositVault() external view returns (address);
    function getDepositToken() external view returns (address);
    function getMaturityTimestamp() external view returns (uint256);
    function getDepositId() external view returns (bytes32);
    function earned() external view returns (address[] memory rewardTokens, uint256[] memory amountEarned);
    function setVars(bytes calldata _data) external;
    function transferOwnership(address _newOwner) external;
}

interface IMaturedVault {
    function depositMatured(uint256 amount) external;
    function withdrawMatured(uint256 _amount, address _recipient) external;
    function transferAssets(address _newMatureVault) external;
    function rescue(address _token, uint256 _amount) external;
    function getTotalHoldings() external view returns (uint256);
    function transferOwnership(address _newOwner) external;
}

interface IFraxFarm {
    function periodFinish() external view returns (uint256);
}