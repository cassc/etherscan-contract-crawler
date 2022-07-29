// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VoteToken is ERC20, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant FULLTIMETRANSFER_ROLE =
        keccak256("FULLTIMETRANSFER_ROLE");

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant DEFAULT_ADMIN_ROLE by calling grantRole(),
     * and also can renounce it's own DEFAULT_ADMIN_ROLE by calling renounceRole().
     *
     * Initially _paused is set to true to pause asset transfers except for FULLTIMETRANSFER_ROLE.
     */
    constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _pause();
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant MINTER_ROLE by calling grantRole().
     * Only MINTER_ROLE can mint.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    
    /**
     * @dev DEFAULT_ADMIN_ROLE can grant BURNER_ROLE by calling grantRole().
     * Only BURNER_ROLE can burn.
     */
    function burn(address account, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
    {
        _burn(account, amount);
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant PAUSER_ROLE by calling grantRole().
     * Only PAUSER_ROLE can unpause.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant PAUSER_ROLE by calling grantRole().
     * Only PAUSER_ROLE can pause.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE can grant FULLTIMETRANSFER_ROLE by calling grantRole().
     * FULLTIMETRANSFER_ROLE is not subject to the _paused status.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPausedWithException(msg.sender)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        whenNotPausedWithException(msg.sender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPausedWithException(msg.sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        whenNotPausedWithException(msg.sender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        whenNotPausedWithException(msg.sender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    modifier whenNotPausedWithException(address caller) {
        if (hasRole(FULLTIMETRANSFER_ROLE, caller)) {
            _;
        } else {
            _requireNotPaused();
            _;
        }
    }
}