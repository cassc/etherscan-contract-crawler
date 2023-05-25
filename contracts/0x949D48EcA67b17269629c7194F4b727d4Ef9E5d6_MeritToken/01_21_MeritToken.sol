// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MeritToken is Context, AccessControlEnumerable, ERC20Votes {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    modifier onlyHasRole(bytes32 _role) {
        require(hasRole(_role, _msgSender()), "MeritToken.onlyHasRole: msg.sender does not have role");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) ERC20Permit(_name) ERC20(_name, _symbol) {
        _mint(_msgSender(), _initialSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());  
    }

    function mint(address _to, uint256 _amount) onlyHasRole(MINTER_ROLE) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) onlyHasRole(BURNER_ROLE) external {
        _burn(_from, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        require(_to != address(this), "MeritToken._transfer: transfer to self not allowed");
        super._transfer(_from, _to, _amount);
    }
    
}