// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IOperatorDelegation.sol";

contract OperatorDelegation is IOperatorDelegation, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Allowed operator contracts will be reviewed
    // to make sure the original caller is the owner.
    // And the operator contract is a just a delegator contract
    // that does what the owner intended
    EnumerableSet.AddressSet private _allowedOperators;
    mapping(address => string) private _operatorName;
    mapping(address => EnumerableSet.AddressSet) private _operatorApprovals;

    /**
     * @dev See {IOperatorDelegation-setApprovalToOperator}.
     */
    function setApprovalToOperator(address operator, bool approved) public {
        _setApprovalToOperator(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IOperatorDelegation-isOperatorAllowed}.
     */
    function isOperatorAllowed(address operator) public view returns (bool) {
        return _allowedOperators.contains(operator);
    }

    /**
     * @dev See {IOperatorDelegation-isApprovedOperator}.
     */
    function isApprovedOperator(address owner, address operator)
        public
        view
        returns (bool)
    {
        return
            isOperatorAllowed(operator) &&
            _operatorApprovals[owner].contains(operator);
    }

    /**
     * @dev See {IOperatorDelegation-getOperator}.
     */
    function getOperator(address operator)
        external
        view
        returns (OperatorInfo memory operatorInfo)
    {
        if (isOperatorAllowed(operator)) {
            operatorInfo = OperatorInfo({
                operator: operator,
                name: _operatorName[operator]
            });
        }
    }

    /**
     * @dev See {IOperatorDelegation-getAllowedOperators}.
     */
    function getAllowedOperators()
        external
        view
        returns (OperatorInfo[] memory operators)
    {
        operators = new OperatorInfo[](_allowedOperators.length());

        for (uint256 i; i < _allowedOperators.length(); i++) {
            operators[i] = OperatorInfo({
                operator: _allowedOperators.at(i),
                name: _operatorName[_allowedOperators.at(i)]
            });
        }
    }

    /**
     * @dev See {IOperatorDelegation-getOwnerApprovedOperators}.
     */
    function getOwnerApprovedOperators(address owner)
        external
        view
        returns (OwnerOperatorInfo[] memory operators)
    {
        uint256 ownerOperatorCount = _operatorApprovals[owner].length();
        operators = new OwnerOperatorInfo[](ownerOperatorCount);

        for (uint256 i; i < ownerOperatorCount; i++) {
            address operator = _operatorApprovals[owner].at(i);
            operators[i] = OwnerOperatorInfo({
                operator: operator,
                name: _operatorName[operator],
                allowed: _allowedOperators.contains(operator)
            });
        }
    }

    /**
     * @dev See {IOperatorDelegation-addAllowedOperator}.
     */
    function addAllowedOperator(address newOperator, string memory operatorName)
        external
        onlyOwner
    {
        require(
            !_allowedOperators.contains(newOperator),
            "operator already in allowed list"
        );

        _allowedOperators.add(newOperator);
        _operatorName[newOperator] = operatorName;

        emit AllowedOperatorAdded(newOperator, operatorName, _msgSender());
    }

    /**
     * @dev See {IOperatorDelegation-removeAllowedOperator}.
     */
    function removeAllowedOperator(address operator) external onlyOwner {
        require(
            _allowedOperators.contains(operator),
            "operator not in allowed list"
        );

        string memory operatorName = _operatorName[operator];

        _allowedOperators.remove(operator);
        delete _operatorName[operator];

        emit AllowedOperatorRemoved(operator, operatorName, _msgSender());
    }

    /**
     * @dev See {IOperatorDelegation-updateOperatorName}.
     */
    function updateOperatorName(address operator, string memory newName)
        external
        onlyOwner
    {
        require(
            _allowedOperators.contains(operator),
            "operator not in allowed list"
        );

        string memory oldName = _operatorName[operator];

        require(
            keccak256(abi.encodePacked((newName))) ==
                keccak256(abi.encodePacked((oldName))),
            "operator name unchanged"
        );

        _operatorName[operator] = newName;

        emit OperatorNameUpdated(operator, oldName, newName, _msgSender());
    }

    /**
     * @dev Approve `operator` to operate on behalf of `owner`
     */
    function _setApprovalToOperator(
        address owner,
        address operator,
        bool approved
    ) private {
        require(
            _allowedOperators.contains(operator),
            "operator not in allowed list"
        );
        require(owner != operator, "approve to sender");

        if (approved) {
            _operatorApprovals[owner].add(operator);
        } else {
            _operatorApprovals[owner].remove(operator);
        }

        string memory operatorName = _operatorName[operator];
        emit OperatorApproved(owner, operator, approved, operatorName);
    }
}