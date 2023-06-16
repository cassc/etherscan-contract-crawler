pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Blockable Token
 * @dev Allows accounts to be blocked by a BLOCKER_ROLE account
*/
abstract contract ERC20Blockable is AccessControl, ERC20 {
    bytes32 public constant BLOCKER_ROLE = keccak256("BLOCKER_ROLE");

    mapping(address => bool) internal blocklist;

    event Blocked(address indexed _account);
    event UnBlocked(address indexed _account);

    /**
     * @dev Grants `BLOCKER_ROLE` to the
     * account that deploys the contract.
     */
    constructor() internal {
        _setupRole(BLOCKER_ROLE, _msgSender());
    }

    /**
     * @dev Checks if account is blocked
     * @param _account The address to check    
    */
    function isBlocked(address _account) public view returns (bool) {
        return blocklist[_account];
    }

    /**
     * @dev Adds account to block list
     * @param _account The address to block
    */
    function blockAccount(address _account) public virtual {
        require(hasRole(BLOCKER_ROLE, _msgSender()), "ERC20Blockable: must have blocker role to block");
        blocklist[_account] = true;
        emit Blocked(_account);
    }

    /**
     * @dev Removes account from block list
     * @param _account The address to remove from the block list
    */
    function unBlockAccount(address _account) public virtual {
        require(hasRole(BLOCKER_ROLE, _msgSender()), "ERC20Blockable: must have blocker role to unblock");
        blocklist[_account] = false;
        emit UnBlocked(_account);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require (!isBlocked(from), "ERC20Blockable: token transfer rejected. Sender is blocked.");
        require (!isBlocked(to), "ERC20Blockable: token transfer rejected. Receiver is blocked.");
        super._beforeTokenTransfer(from, to, amount);
    }
}