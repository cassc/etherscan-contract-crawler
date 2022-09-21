// SPDX-License-Identifier: Apache License 2.0

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Phi.sol";

contract DelphiaCredit is Ownable {

    Phi public immutable phi;

    struct Receipt {
        address recipient;
        uint256 amount;
    }

    mapping(address => bool) public operators;
    mapping(address => uint256) public withdrawBalances;
    uint256 public activeBalance;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Distributed(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event NewRDO(address operator);
    event RemovedRDO(address operator);

    /// @dev Reverts if the caller is not a Rewards Dispersement Operator or an owner
    modifier onlyRDOperator() {
        require(owner() == msg.sender || operators[msg.sender] == true,
            "DelphiaCredit: Only RD operators can distribute rewards");
        _;
    }

    /// @notice Constructor of DelphiaCredit
    /// @param token Address of Phi used as a payment
    constructor (Phi token) {
        phi = token;
    }

    /// @notice Function to add RDO
    /// @dev Only owner can add RDO
    /// @param operator Address of the RDO
    function addRDOperator(address operator) external onlyOwner{
        require(operators[operator] == false,
            "DelphiaCredit.addRDOperator: There is already such operator");
        operators[operator] = true;
        emit NewRDO(operator);
    }

    /// @notice Function to remove RDO
    /// @dev Only owner can remove RDO
    /// @param operator Address of the RDO
    function removeRDOperator(address operator) external onlyOwner{
        require(operators[operator] == true,
            "DelphiaCredit.removeRDOperator: There is no such operator");
        operators[operator] = false;
        emit RemovedRDO(operator);
    }

    /**
     * @dev Receives deposited tokens from the outside users.
     * @param amount The amount of tokens sent to the contract.
     */
    function deposit(uint256 amount) external {
        activeBalance += amount;
        require(phi.transferFrom(msg.sender, address (this), amount),
            "DelphiaCredit.deposit: Can't transfer token to the DelphiaCredit");
        emit Deposited(msg.sender, amount);
    }

    /**
    * @dev Withdraws deposited tokens to the outside users.
    */
    function withdraw(address payee) external {
        uint256 balance = withdrawBalances[payee];
        require(balance > 0,
            "DelphiaCredit.withdraw: There is nothing to withdraw");
        withdrawBalances[payee] = 0;
        require(phi.transfer(payee, balance),
            "Failed to transfer Phi");
        emit Withdrawn(payee, balance);
    }

     /**
     * @dev Distributes received tokens after the game.
     * @param receipts Array of addresses and their rewards amount.
     */
    function distribute(Receipt[] memory receipts) external onlyRDOperator{
        require(receipts.length <= 200,
            "DelphiaCredit.distribute: Can distribute 200 receipts at max");
        for(uint64 j = 0; j < receipts.length; j++){
            activeBalance -= receipts[j].amount;
            withdrawBalances[receipts[j].recipient] += receipts[j].amount;
            emit Distributed(receipts[j].recipient, receipts[j].amount);
        }
    }


}