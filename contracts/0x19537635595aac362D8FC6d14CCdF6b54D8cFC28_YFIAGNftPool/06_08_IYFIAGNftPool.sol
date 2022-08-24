// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IYFIAGNftPool {
    function subOwnerFeeBalance() external payable;
    function getBalance() external view returns(uint256);
    function withdraw(address _tokenAddress) external;
    function getAmountEarn(address _user, address _tokenAddress) external view returns(uint256);
    function getAmountWithdrawn(address _user, address _tokenAddress) external view returns(uint256);
    function setMarketplaceAddress(address marketPlaceAddress) external;
    function migratePool(address newPool,address tokenAddress) external;
}