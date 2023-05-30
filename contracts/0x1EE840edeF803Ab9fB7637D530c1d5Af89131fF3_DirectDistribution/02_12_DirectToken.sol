pragma solidity ^0.8.0;


/// Openzeppelin imports
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol';


/**
 * @title Implementation of the basic standard ERC20 pausable token.
 *
 */
contract DirectToken is AccessControl, ERC20Pausable {

    uint256 public constant INITIALSUPPLY = 1200000000 * (10 ** 18);

    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    constructor(address adminAddress_)
            ERC20('Direct', 'DRCT') {

        _mint(msg.sender, INITIALSUPPLY);

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress_);
    }

    function pause() external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to pause");
        _pause();
    }

    function unpause() external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to unpause");
        _unpause();
    }
}