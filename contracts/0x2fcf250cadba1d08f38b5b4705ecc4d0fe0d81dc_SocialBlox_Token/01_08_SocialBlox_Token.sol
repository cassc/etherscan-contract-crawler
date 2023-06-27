// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract SocialBlox_Token is ERC20, AccessControl{
     using SafeMath for uint256;

  uint256 public _maxSupply = 0;
  uint256 internal _totalSupply = 0;
  
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() public ERC20("SocialBlox", "SBLX") {
    _maxSupply = 21000000000 * 10**18;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function mint(address account, uint256 amount) public virtual returns (bool) {
    require(account != address(0), "ERC20: mint to the zero address");
    require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
    uint256 newMintSupply = _totalSupply.add(amount * 10**18);
    require(newMintSupply <= _maxSupply, "supply is max!");
    _mint(account, amount * 10**18);
    _totalSupply = _totalSupply.add(amount * 10**18);

    return true;
  }
}