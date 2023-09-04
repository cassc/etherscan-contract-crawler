// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Interface of Unitas ERC-20 Token
 */
interface IERC20Token is IERC20Metadata {
    function GOVERNOR_ROLE() external view returns (bytes32);
    function GUARDIAN_ROLE() external view returns (bytes32);
    function MINTER_ROLE() external view returns (bytes32);
    function setGovernor(address newGovernor, address oldGovernor) external;
    function revokeGovernor(address oldGovernor) external;
    function setGuardian(address newGuardian, address oldGuardian) external;
    function revokeGuardian(address oldGuardian) external;
    function setMinter(address newMinter, address oldMinter) external;
    function revokeMinter(address oldMinter) external;
    function pause() external;
    function unpause() external;
    function mint(address account, uint256 amount) external;
    function burn(address burner, uint256 amount) external;
    function addBlackList(address evilUser) external;
    function removeBlackList(address clearedUser) external;
    function getBlacklist(address addr) external view returns (bool);
}