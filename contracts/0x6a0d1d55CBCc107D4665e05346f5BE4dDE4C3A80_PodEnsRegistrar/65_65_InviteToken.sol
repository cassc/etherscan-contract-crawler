pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract InviteToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("Ship Token", "$SHIP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    function decimals() public view override returns (uint8) {
        return 0;
    }

    function batchMint(address[] calldata accounts, uint256 amount) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            mint(accounts[i], amount);
        }
    }

    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minters can mint");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Only burners can burn");
        _burn(account, amount);
    }
}