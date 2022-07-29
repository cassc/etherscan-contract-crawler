// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteTokenV1 is ERC20, Pausable, Ownable {
    /**
     * @dev Initially _paused is set to true to pause asset transfers.
     *
     * Set contract creator as owner of contract.
     */
    constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol) {
        _pause();
    }

    /**
     * @dev Only owner can mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Only owner can burn.
     */
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    /**
     * @dev Only owner can unpause, i.e. set _paused to false.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Only owner can pause, i.e. set _paused to true.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Transfer related functions are functional only when not paused.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        whenNotPaused
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        whenNotPaused
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}