// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IBananaVault is IAccessControlEnumerable {
    function DEPOSIT_ROLE() external view returns (bytes32);

    function userInfo(address _address)
        external
        view
        returns (
            uint256 shares,
            uint256 lastDepositedTime,
            uint256 pacocaAtLastUserAction,
            uint256 lastUserActionTime
        );

    function earn() external;

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function lastHarvestedTime() external view returns (uint256);

    function calculateTotalPendingBananaRewards()
        external
        view
        returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function available() external view returns (uint256);

    function underlyingTokenBalance() external view returns (uint256);

    function masterApe() external view returns (address);
    
    function bananaToken() external view returns (address);

    function totalShares() external view returns (uint256);

    function withdrawAll() external;

    function treasury() external view returns (address);

    function setTreasury(address _treasury) external;
}