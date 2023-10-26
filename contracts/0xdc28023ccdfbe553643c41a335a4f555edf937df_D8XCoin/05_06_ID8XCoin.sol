// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ID8XCoin {
    function votes(address holder) external view returns (uint256);

    function canVoteFor(address delegate, address owner) external view returns (bool);

    function totalVotes() external view returns (uint256);

    function delegateVoteTo(address delegate) external;

    function epochDurationSec() external returns (uint256);

    function isQualified(
        address sender,
        uint16 _percentageBps,
        address[] calldata helpers
    ) external view returns (bool);

    // functions related to multi-chain capability
    function portalIn(uint256 _amount, address _from, address _wallet) external;

    function portalOut(uint256 _amount, address _wallet, address _to) external;

    function changeOfTheGuard(address _newGuardian) external;

    function replacePortal(address _newPortal) external;

    function executeTimeLocked() external;
}