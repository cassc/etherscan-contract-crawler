// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MEO is ERC20Burnable, ERC20Capped, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");



    constructor(address _admin) ERC20("MEO TOKEN", "MEO") ERC20Capped(100000000e18){
         _setupRole(DEFAULT_ADMIN_ROLE, _admin);
         _setupRole(MINTER_ROLE, _admin);
         _setupRole(BURNER_ROLE, _admin);

    }

    function _mint(address _owner, uint256 _amount) internal override (ERC20,ERC20Capped) {
         ERC20Capped._mint(_owner, _amount);
    }
    function mint(address to, uint256 amount) public  onlyRole(MINTER_ROLE) {
        _mint(to, amount);
       
    }
    function burn(uint amount) public override onlyRole(BURNER_ROLE) {
        ERC20Burnable.burn(amount);
    }

    function burnFrom(address from, uint amount) public override onlyRole(BURNER_ROLE) {
        ERC20Burnable.burnFrom(from, amount);
    }
}