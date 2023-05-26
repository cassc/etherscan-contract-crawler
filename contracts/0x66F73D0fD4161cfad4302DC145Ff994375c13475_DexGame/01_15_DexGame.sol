pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DexGame is ERC20, Pausable, AccessControlEnumerable {
    using SafeMath for uint256;
    
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10**uint256(DECIMALS));
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    constructor() ERC20("DEXGame", "DXGM") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WHITELIST_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        
        _mint(_msgSender(), INITIAL_SUPPLY);
    }
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "User must have pauser role to pause");
        _pause();
    }
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "User must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused() || hasRole(WHITELIST_ROLE, _msgSender()), "ERC20Pausable: token transfer while paused");
    }
    function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			require(transfer(_receivers[i], _amounts[i]));
		}
	}
}