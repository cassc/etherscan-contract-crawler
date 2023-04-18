// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "../agents/AgentManager.sol";
import "../interfaces/IRestrictedList.sol";
import "./ERC20Permit.sol";

/**
 * @title LT Dao's HOPE Token Contract
 * @notice $HOPE, the ecosystem’s native pricing token backed by reserves
 * @author LT
 */
contract HOPE is ERC20Permit, AgentManager {
    // RestrictedList contract
    address public restrictedList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _restrictedList) external initializer {
        require(_restrictedList != address(0), "CE000");
        restrictedList = _restrictedList;
        __Ownable2Step_init();
        __ERC20_init("HOPE", "HOPE");
        __ERC20Permit_init();
    }

    /**
     * @notice mint amount to address
     * @dev mint only support Agent & Minable
     * @param to min to address
     * @param amount mint amount
     */
    function mint(address to, uint256 amount) public onlyAgent onlyMinable {
        require(!IRestrictedList(restrictedList).isRestrictedList(to), "FA000");
        require(tx.origin != _msgSender(), "HO000");
        require(getEffectiveBlock(_msgSender()) <= block.number, "AG014");
        require(getExpirationBlock(_msgSender()) >= block.number, "AG011");
        require(getRemainingCredit(_msgSender()) >= amount, "AG004");
        _mint(to, amount);
        _decreaseRemainingCredit(_msgSender(), amount);
    }

    /**
     * @notice burn amount from sender
     * @dev mint only support Agent & Burnable
     * @param amount burn amount
     */
    function burn(uint256 amount) external onlyAgent onlyBurnable {
        require(getEffectiveBlock(_msgSender()) <= block.number, "AG014");
        require(getExpirationBlock(_msgSender()) >= block.number, "AG011");
        _burn(_msgSender(), amount);
        _increaseRemainingCredit(_msgSender(), amount);
    }

    /**
     * @notice restricted list cannot call
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(
            !IRestrictedList(restrictedList).isRestrictedList(msg.sender) && !IRestrictedList(restrictedList).isRestrictedList(to),
            "FA000"
        );
        return super.transfer(to, amount);
    }

    /**
     * @notice restricted list cannot call
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!IRestrictedList(restrictedList).isRestrictedList(from) && !IRestrictedList(restrictedList).isRestrictedList(to), "FA000");
        return super.transferFrom(from, to, amount);
    }
}