// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IOperators.sol";

interface ITokenMinter is IERC20 {
    function mint(uint256 value) external;
}

interface ITokenLocker {
    event PullFromGame(
        uint256 __serialid,
        uint256 _id,
        address _user,
        uint256 _value
    );
    event ClaimToken(uint256 __serialid, address _user, uint256 _value);

    struct LockedItem {
        uint256 sid;
        address user;
        uint256 amount;
        uint256 timestamp;
        bool unlocked;
    }

    function token() external view returns (ITokenMinter);

    function pending(uint256 lid) external view returns (uint256, uint256);

    function getItem(uint256 lid) external view returns (LockedItem memory);

    function getLockTimeRate() external view returns (uint256, uint256);

    function setLockTimeRate(uint256 _feeLockTime, uint256 _feeRate) external;

    function claimBatch(uint256[] memory lid, address _touser) external;

    function gameOut(
        uint256 _serialid,
        address _user,
        uint256 _timestamp,
        uint256 _value
    ) external;

    function gameOutBatch(
        uint256[] memory _serialid,
        address[] memory _user,
        uint256[] memory _timestamp,
        uint256[] memory _value
    ) external;
}