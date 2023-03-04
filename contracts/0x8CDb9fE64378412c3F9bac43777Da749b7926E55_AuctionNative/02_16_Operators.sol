// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Management of Operators.
 * @author Freeverse.io, www.freeverse.io
 * @dev The Operator role is to execute the actions required when
 * payments arrive to this contract, and then either
 * confirm the success of those actions, or confirm the failure.
 * All parties agree explicitly on a specific address to 
 * act as an Operator for each individual payment process. 
 *
 * The constructor sets a defaultOperator = deployer.
 * The owner of the contract can change the defaultOperator.
 *
 * The owner of the contract can assign explicit operators to each universe.
 * If a universe does not have an explicitly assigned operator,
 * the default operator is used.
 */

contract Operators is Ownable {
    /**
     * @dev Event emitted on change of default operator
     * @param operator The address of the new default operator
     * @param prevOperator The previous value of operator
     */
    event DefaultOperator(address indexed operator, address indexed prevOperator);

    /**
     * @dev Event emitted on change of a specific universe operator
     * @param universeId The id of the universe
     * @param operator The address of the new universe operator
     * @param prevOperator The previous value of operator
     */
    event UniverseOperator(
        uint256 indexed universeId,
        address indexed operator,
        address indexed prevOperator
    );

    /// @dev The address of the default operator:
    address private _defaultOperator;

    /// @dev The mapping from universeId to specific universe operator:
    mapping(uint256 => address) private _universeOperators;

    constructor() {
        setDefaultOperator(msg.sender);
    }

    /**
     * @dev Sets a new default operator
     * @param operator The address of the new default operator
     */
    function setDefaultOperator(address operator) public onlyOwner {
        emit DefaultOperator(operator, _defaultOperator);
        _defaultOperator = operator;
    }

    /**
     * @dev Sets a new specific universe operator
     * @param universeId The id of the universe
     * @param operator The address of the new universe operator
     */
    function setUniverseOperator(uint256 universeId, address operator)
        external
        onlyOwner
    {
        emit UniverseOperator(universeId, operator, universeOperator(universeId));
        _universeOperators[universeId] = operator;
    }

    /**
     * @dev Removes a specific universe operator
     * @notice The universe will then be operated by _defaultOperator
     * @param universeId The id of the universe
     */
    function removeUniverseOperator(uint256 universeId) external onlyOwner {
        emit UniverseOperator(universeId, _defaultOperator, _universeOperators[universeId]);
        delete _universeOperators[universeId];
    }

    /**
     * @dev Returns the default operator
     */
    function defaultOperator() external view returns (address) {
        return _defaultOperator;
    }

    /**
     * @dev Returns the operator of a specific universe
     * @param universeId The id of the universe
     */
    function universeOperator(uint256 universeId)
        public
        view
        returns (address)
    {
        address storedOperator = _universeOperators[universeId];
        return storedOperator == address(0) ? _defaultOperator : storedOperator;
    }
}