// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface with pausability
 * When paused by the pauser admin, transfers revert.
 */
contract ERC20Pausable is ERC20, Pausable {
    address public immutable roleAdmin;

    // initially no-one should have the pauser role
    // it can be granted and revoked by the admin policy
    address public pauser;

    /**
     * @notice event indicating the pauser was updated
     * @param pauser The new pauser
     */
    event PauserAssignment(address indexed pauser);

    constructor(
        string memory name,
        string memory symbol,
        address _roleAdmin,
        address _initialPauser
    ) ERC20(name, symbol) {
        require(
            address(_roleAdmin) != address(0),
            "Unrecoverable: do not set the _roleAdmin as the zero address"
        );
        roleAdmin = _roleAdmin;
        pauser = _initialPauser;
        emit PauserAssignment(_initialPauser);
    }

    modifier onlyAdmin() {
        require(msg.sender == roleAdmin, "ERC20Pausable: not admin");
        _;
    }

    modifier onlyPauser() {
        require(msg.sender == pauser, "ERC20Pausable: not pauser");
        _;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * If the token is not paused, it will pass through the amount
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused returns (uint256) {
        return amount;
    }

    /**
     * @notice pauses transfers of this token
     * @dev only callable by the pauser
     */
    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @notice unpauses transfers of this token
     * @dev only callable by the pauser
     */
    function unpause() external onlyPauser {
        _unpause();
    }

    /**
     * @notice set the given address as the pauser
     * @param _pauser The address that can pause this token
     * @dev only the roleAdmin can call this function
     */
    function setPauser(address _pauser) public onlyAdmin {
        require(_pauser != pauser, "ERC20Pausable: must change pauser");
        pauser = _pauser;
        emit PauserAssignment(_pauser);
    }
}