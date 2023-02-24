// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract DnaToken is ERC20, ERC20Burnable, Ownable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  
  constructor() ERC20("DNA", "DNA") { }

  /**
   * mints $DNA to a recipient
   * @param to the recipient of the $DNA
   * @param amount the amount of $DNA to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function mintToMany(address[] calldata to, uint256[] calldata count) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require(to.length == count.length, "mismatching lengths!");
        
        for (uint256 i; i < to.length; i++) {
            _mint(to[i], count[i]);
        }
  }

  /**
   * burns $DNA from a holder
   * @param from the holder of the $DNA
   * @param amount the amount of $DNA to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}