// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of a TablelandController compliant contract.
 *
 * This interface can be implemented to enabled advanced access control for a table.
 * Call {ITablelandTables-setController} with the address of your implementation.
 *
 * See {test/TestTablelandController} for an example of token-gating table write-access.
 */
interface ITablelandController {
    /**
     * @dev Object defining how a table can be accessed.
     */
    struct Policy {
        // Whether or not the table should allow SQL INSERT statements.
        bool allowInsert;
        // Whether or not the table should allow SQL UPDATE statements.
        bool allowUpdate;
        // Whether or not the table should allow SQL DELETE statements.
        bool allowDelete;
        // A conditional clause used with SQL UPDATE and DELETE statements.
        // For example, a value of "foo > 0" will concatenate all SQL UPDATE
        // and/or DELETE statements with "WHERE foo > 0".
        // This can be useful for limiting how a table can be modified.
        // Use {Policies-joinClauses} to include more than one condition.
        string whereClause;
        // A conditional clause used with SQL INSERT statements.
        // For example, a value of "foo > 0" will concatenate all SQL INSERT
        // statements with a check on the incoming data, i.e., "CHECK (foo > 0)".
        // This can be useful for limiting how table data ban be added.
        // Use {Policies-joinClauses} to include more than one condition.
        string withCheck;
        // A list of SQL column names that can be updated.
        string[] updatableColumns;
    }

    /**
     * @dev Returns a {Policy} struct defining how a table can be accessed by `caller`.
     */
    function getPolicy(address caller) external payable returns (Policy memory);
}