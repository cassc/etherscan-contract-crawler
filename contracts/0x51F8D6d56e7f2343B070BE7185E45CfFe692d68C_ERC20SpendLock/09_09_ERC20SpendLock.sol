// // SPDX-License-Identifier: GPL-v3
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
         ****   ******   *******  **     **  ******       **       *******  **       **  *******  ********
        **   *  **    *  **       ***    **  **   **      **         ***    ***     ***    ***       **
         **     **    *  **       ** *   **  **    **     **         ***    ** *   * **    ***       **
          **    ******   *******  **  *  **  **     **    **         ***    **  * *  **    ***       **
           **   **       **       **   * **  **    **     **         ***    **   *   **    ***       **
        *   **  **       **       **    ***  **   **      **         ***    **       **    ***       **
         ****   **       *******  **     **  ******       *******  *******  **       **  *******     **

        This contract is a modified version of the ERC20 contract from OpenZeppelin.
        It adds a spend limit to the transfer function.
        The spend limit is set by the owner of the contract.
        The owner can also set if an address is a receiver or not.
        If an address is a receiver, the person sending it there is not subject to the spend limit.

        NOTE:
        To allow selling of tokens, the owner should set the exchange router address as a receiver.
 */

contract ERC20SpendLock is ERC20, Ownable {
    using SafeERC20 for ERC20;

    struct SpendLimit {
        uint256 amount;
        bool is_receiver;
    }

    mapping(address => SpendLimit) private _spend_limit;

    // Events
    event SpendLimitSet(address indexed spender, uint256 amount);
    event SetReceiver(address indexed receiver, bool indexed is_receiver);
    event SpendLimitUsed(address indexed spender, uint256 amount);

    /**
     * Constructor for the ERC20SpendLock contract.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param total_supply The total supply of the token.
     * @param owner The owner of the token.
     */
    constructor(
        string memory name, 
        string memory symbol,
        uint256 total_supply, 
        address owner
    )
    ERC20(name, symbol) {
        _mint(owner, total_supply);
    }

    /**
     * Sets if an address is a receiver or not.
     * If an address is a receiver, the person sending it there is not subject to the spend limit.
     */
    function set_is_receiver(
        address receiver,
        bool is_receiver
    ) onlyOwner external {
        _spend_limit[receiver].is_receiver = is_receiver;
        emit SetReceiver(receiver, is_receiver);
    }

    /**
     * Returns if an address is a receiver or not.
     */
    function get_is_receiver(
        address receiver
    ) external view returns (bool) {
        return _spend_limit[receiver].is_receiver;
    }

    /**
     * Sets the spend limit for an address.
     */
    function set_spend_amount(
        address spender,
        uint256 amount
    ) onlyOwner external {
        _spend_limit[spender].amount = amount;
        emit SpendLimitSet(spender, amount);
    }

    function set_spend_amount_bulk(
        address[] memory spenders,
        uint256[] memory amounts
    ) onlyOwner external {
        require(spenders.length == amounts.length, "ERC20: spenders and amounts must be the same length");
        for (uint256 i = 0; i < spenders.length; i++) {
            _spend_limit[spenders[i]].amount = amounts[i];
            emit SpendLimitSet(spenders[i], amounts[i]);
        }
    }

    /**
     * Returns the spend limit for an address.
     */
    function get_spend_amount(
        address spender
    ) external view returns (uint256) {
        return _spend_limit[spender].amount;
    }

    /**
     * Transfers tokens to a specified address.
     * If the address is a receiver, the person sending it there is not subject to the spend limit.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (_spend_limit[recipient].is_receiver) {
            _transfer(msg.sender, recipient, amount);
            return true;
        }

        require(_spend_limit[msg.sender].amount >= amount, "ERC20: transfer amount exceeds spend limit");
        _spend_limit[msg.sender].amount -= amount;
        emit SpendLimitUsed(msg.sender, amount);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();

        if (_spend_limit[to].is_receiver) {
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
            return true;
        }

        require(_spend_limit[from].amount >= amount, "ERC20: transfer amount exceeds spend limit");
        _spend_limit[from].amount -= amount;
        emit SpendLimitUsed(from, amount);
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}