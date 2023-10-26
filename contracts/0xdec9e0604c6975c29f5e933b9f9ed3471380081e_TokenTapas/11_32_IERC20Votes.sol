// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (governance/utils/IVotes.sol)
pragma solidity >=0.8.17;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IVotes } from "@openzeppelin/governance/utils/IVotes.sol";

/**
 * @dev Union Interface for {IERC20} and {IVotes}
 */
interface IERC20Votes is IERC20, IVotes {

}