// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts

// ERC20 Token Contract based on OpenZeppelin
//
// ## Minting:
// Mintable. Mint can be stopped forever by stopMint().
//
// ## AccessControl:
// DEFAULT_ADMIN_ROLE can grantRole to any other address.
// MINTER_ROLE - can mint
// PAUSER_ROLE - can pause transfers
// MINTSTOPPER_ROLE - can stop minting FOREVER
// Any role can be revoked from any address by DEFAULT_ADMIN_ROLE
// All role members can be listed anytime by getRoleMemberCount and getRoleMember
//
// ## Burning:
// tokens can be burnt by tokens holder
//
// ## Pausing:
// All transfers can be paused and unpaused anytime by PAUSER_ROLE
//
// ## Allowance and Approve:
// Default ERC20 allowance, approve, transferFrom 


pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MOSTToken is Context, AccessControlEnumerable, ERC20, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTSTOPPER_ROLE = keccak256("MINTSTOPPER_ROLE");

    // Mint is Stoppable
    bool public mintStopped = false;

    constructor(string memory name, string memory symbol, uint256 _initialSupply, address _initialHolder, address _admin) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MINTER_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
        _setupRole(MINTSTOPPER_ROLE, _admin);

        _mint(_initialHolder, _initialSupply);
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        require(mintStopped != true, "Mint stopped");
        _mint(to, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function stopMint() public onlyRole(MINTSTOPPER_ROLE) {
        mintStopped = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}