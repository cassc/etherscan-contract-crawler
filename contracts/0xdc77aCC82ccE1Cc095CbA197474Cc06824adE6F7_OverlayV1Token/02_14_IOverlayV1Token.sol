// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/access/IAccessControlEnumerable.sol";

bytes32 constant MINTER_ROLE = keccak256("MINTER");
bytes32 constant BURNER_ROLE = keccak256("BURNER");
bytes32 constant GOVERNOR_ROLE = keccak256("GOVERNOR");
bytes32 constant GUARDIAN_ROLE = keccak256("GUARDIAN");

interface IOverlayV1Token is IAccessControlEnumerable, IERC20 {
    // mint/burn
    function mint(address _recipient, uint256 _amount) external;

    function burn(uint256 _amount) external;
}