// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashStrategy {
    event BurnedFToken(address indexed _address, uint256 _tokenAmount, uint256 _yieldReturned);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function burnFToken(
        uint256 _tokenAmount,
        uint256 _minimumReturned,
        address _yieldTo
    ) external returns (uint256);

    function claimAAVEv2Rewards(address[] memory _assets, uint256 _amount) external;

    function depositPrincipal(uint256 _tokenAmount) external returns (uint256);

    function getFTokenAddress() external view returns (address);

    function getMaxStakeDuration() external pure returns (uint256);

    function getPrincipalAddress() external view returns (address);

    function getPrincipalBalance() external view returns (uint256);

    function getYieldBalance() external view returns (uint256);

    function increaseAllowance() external;

    function lockSetUserIncentiveAddress() external;

    function owner() external view returns (address);

    function quoteBurnFToken(uint256 _tokenAmount) external view returns (uint256);

    function quoteMintFToken(uint256 _tokenAmount, uint256 _duration) external view returns (uint256);

    function renounceOwnership() external;

    function setFTokenAddress(address _fTokenAddress) external;

    function setUserIncentiveAddress(address _userIncentiveAddress) external;

    function transferOwnership(address newOwner) external;

    function userIncentiveAddress() external view returns (address);

    function userIncentiveAddressLocked() external view returns (bool);

    function withdrawERC20(address[] memory _tokenAddresses, uint256[] memory _tokenAmounts) external;

    function withdrawPrincipal(uint256 _tokenAmount) external;
}