// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITokenLockup {

    struct Schedule {
        uint256 endTime;
        uint256 portion;
    }

    event Fund(
      address indexed recipient,
      uint256 amount
    );

    event Claim(
      address indexed recipient,
      uint256 claimed
    );
    event Reclaim(
      address indexed recipient,
      uint256 claimed
    );

    event ChangeRecipient(
      address indexed oldRecipient,
      address indexed newRecipient
    );

    function addTokens(uint256 amount) external;
    function fund(address[] calldata recipients, uint256[] calldata amounts) external;

    function claim() external;
    function changeRecipient(address newRecipient) external;

    function unlockedSupply() external view returns (uint256);
    function lockedSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function unlockedOf(address account) external view returns (uint256);
    function lockedOf(address account) external view returns (uint256);
}