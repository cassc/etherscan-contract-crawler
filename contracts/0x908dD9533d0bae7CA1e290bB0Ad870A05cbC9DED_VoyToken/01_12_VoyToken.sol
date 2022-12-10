// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


/**
 * VoyToken contract in the Ethereum network
 */
contract VoyToken is ERC20, AccessControl, Pausable {
    uint256 public MAX_SUPPLY = 500_000_000 ether; // MAX_SUPPLY is 500M

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event SwapStarted(address _user, uint256 _amount);
    event SwapCompleted(address _user, uint256 _amount);

    constructor() ERC20("Voy Token", "VOY") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function completeSwapFromPolygon(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        uint256 _totalSupply = totalSupply();
        require(
            _amount <= MAX_SUPPLY - _totalSupply,
            "VoyToken: MAX_SUPPLY is out"
        );
        _mint(_to, _amount);

        emit SwapCompleted(_to, _amount);
    }

    function swapToPolygon(uint256 amount) external {
        _burn(msg.sender, amount);

        emit SwapStarted(msg.sender, amount);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}