// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IOperatorDelegation {
    struct OperatorInfo {
        address operator;
        string name;
    }

    struct OwnerOperatorInfo {
        address operator;
        string name;
        bool allowed;
    }

    event OperatorApproved(
        address indexed owner,
        address indexed operator,
        bool approved,
        string operatorName
    );

    event AllowedOperatorAdded(
        address indexed operator,
        string operatorName,
        address sender
    );

    event AllowedOperatorRemoved(
        address indexed operator,
        string operatorName,
        address sender
    );

    event OperatorNameUpdated(
        address indexed operator,
        string previousName,
        string newName,
        address sender
    );

    /**
     * @dev Approve or remove `operator` as an operator for the sender.
     */
    function setApprovalToOperator(address operator, bool _approved) external;

    /**
     * @dev check if operator is in the allowed list
     */
    function isOperatorAllowed(address operator) external view returns (bool);

    /**
     * @dev check if the `operator` is allowed to manage on behalf of `owner`.
     */
    function isApprovedOperator(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev check details of operator by address
     */
    function getOperator(address operator)
        external
        view
        returns (OperatorInfo memory);

    /**
     * @dev get the allowed list of operators
     */
    function getAllowedOperators()
        external
        view
        returns (OperatorInfo[] memory);

    /**
     * @dev get approved operators of a given address
     */
    function getOwnerApprovedOperators(address owner)
        external
        view
        returns (OwnerOperatorInfo[] memory);

    /**
     * @dev add allowed operator to allowed list
     */
    function addAllowedOperator(address newOperator, string memory operatorName)
        external;

    /**
     * @dev remove allowed operator from allowed list
     */
    function removeAllowedOperator(address operator) external;

    /**
     * @dev update name of an operator
     */
    function updateOperatorName(address operator, string memory newName)
        external;
}