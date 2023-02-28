// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC20G.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ERC20G is ERC20, IERC20G, AccessControl, Pausable {
    //keccak256("MINTER_ROLE");
    bytes32 internal constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    //keccak256("PAUSER_ROLE");
    bytes32 internal constant PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    //keccak256("BURNER_ROLE");
    bytes32 internal constant BURNER_ROLE = 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    //operational functions
    function setPause(bool status) external {
        require(hasRole(PAUSER_ROLE, msg.sender), "ERC20G: must have pauser role to pause");

        if (status) _pause();
        else _unpause();
    }

    //mint/burn/transfer
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC20G: must have minter role to mint");

        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external virtual {
        require(hasRole(BURNER_ROLE, msg.sender), "ERC20G: must have burner role to burn");

        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20G: token transfer while paused");
    }
}