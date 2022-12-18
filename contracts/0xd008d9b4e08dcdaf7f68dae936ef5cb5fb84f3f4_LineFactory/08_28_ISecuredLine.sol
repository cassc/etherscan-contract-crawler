pragma solidity 0.8.9;

import {IEscrowedLine} from "./IEscrowedLine.sol";
import {ISpigotedLine} from "./ISpigotedLine.sol";

interface ISecuredLine is IEscrowedLine, ISpigotedLine {
    // Rollover
    error DebtOwed();
    error BadNewLine();
    error BadRollover();

    // Borrower functions

    /**
     * @notice - helper function to allow Borrower to easily transfer settings and collateral from this line to a new line
     *         - usefull after ttl has expired and want to renew Line with minimal effort
     * @dev    - transfers Spigot and Escrow ownership to newLine. Arbiter functions on this Line will no longer work
     * @param newLine - the new, uninitialized Line deployed by borrower
     * @return success - if
     */
    function rollover(address newLine) external returns (bool);
}