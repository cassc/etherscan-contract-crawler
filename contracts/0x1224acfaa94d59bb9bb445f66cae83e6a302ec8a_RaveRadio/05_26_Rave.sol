// SPDX-License-Identifier: MIT

/*
                                                                                                                                                                        
RRRRRRRRRRRRRRRRR                                                          FFFFFFFFFFFFFFFFFFFFFF                                                                        
R::::::::::::::::R                                                         F::::::::::::::::::::F                                                                        
R::::::RRRRRR:::::R                                                        F::::::::::::::::::::F                                                                        
RR:::::R     R:::::R                                                       FF::::::FFFFFFFFF::::F                                                                        
  R::::R     R:::::R  aaaaaaaaaaaaavvvvvvv           vvvvvvv eeeeeeeeeeee    F:::::F       FFFFFFaaaaaaaaaaaaa      cccccccccccccccc    eeeeeeeeeeee        ssssssssss   
  R::::R     R:::::R  a::::::::::::av:::::v         v:::::vee::::::::::::ee  F:::::F             a::::::::::::a   cc:::::::::::::::c  ee::::::::::::ee    ss::::::::::s  
  R::::RRRRRR:::::R   aaaaaaaaa:::::av:::::v       v:::::ve::::::eeeee:::::eeF::::::FFFFFFFFFF   aaaaaaaaa:::::a c:::::::::::::::::c e::::::eeeee:::::eess:::::::::::::s 
  R:::::::::::::RR             a::::a v:::::v     v:::::ve::::::e     e:::::eF:::::::::::::::F            a::::ac:::::::cccccc:::::ce::::::e     e:::::es::::::ssss:::::s
  R::::RRRRRR:::::R     aaaaaaa:::::a  v:::::v   v:::::v e:::::::eeeee::::::eF:::::::::::::::F     aaaaaaa:::::ac::::::c     ccccccce:::::::eeeee::::::e s:::::s  ssssss 
  R::::R     R:::::R  aa::::::::::::a   v:::::v v:::::v  e:::::::::::::::::e F::::::FFFFFFFFFF   aa::::::::::::ac:::::c             e:::::::::::::::::e    s::::::s      
  R::::R     R:::::R a::::aaaa::::::a    v:::::v:::::v   e::::::eeeeeeeeeee  F:::::F            a::::aaaa::::::ac:::::c             e::::::eeeeeeeeeee        s::::::s   
  R::::R     R:::::Ra::::a    a:::::a     v:::::::::v    e:::::::e           F:::::F           a::::a    a:::::ac::::::c     ccccccce:::::::e           ssssss   s:::::s 
RR:::::R     R:::::Ra::::a    a:::::a      v:::::::v     e::::::::e        FF:::::::FF         a::::a    a:::::ac:::::::cccccc:::::ce::::::::e          s:::::ssss::::::s
R::::::R     R:::::Ra:::::aaaa::::::a       v:::::v       e::::::::eeeeeeeeF::::::::FF         a:::::aaaa::::::a c:::::::::::::::::c e::::::::eeeeeeee  s::::::::::::::s 
R::::::R     R:::::R a::::::::::aa:::a       v:::v         ee:::::::::::::eF::::::::FF          a::::::::::aa:::a cc:::::::::::::::c  ee:::::::::::::e   s:::::::::::ss  
RRRRRRRR     RRRRRRR  aaaaaaaaaa  aaaa        vvv            eeeeeeeeeeeeeeFFFFFFFFFFF           aaaaaaaaaa  aaaa   cccccccccccccccc    eeeeeeeeeeeeee    sssssssssss    
                                                                                                                                                                         
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Rave is ERC20Burnable, Ownable {
  using SafeMath for uint256;

  // Stores the addresses of other contracts which are able to mint and burn tokens.
  mapping(address => bool) controllers;

  // This contract is able to produce a maximum of 100,000,000 RAVES.
  uint256 public MAXIMUM_RAVE_SUPPLY = 100000000 * (10**18);

  // Stores the total minted tokens
  uint256 public totalMintedSupply;

  // If this true, then no more controllers can be added to this contract.
  // Controllers are only able to burn and mint, and it's not possible to mint above the maximum supply.
  // This enables us to create additional contracts such as a staking contract for the RAVE token.

  bool private _isControllersLocked;

  constructor() ERC20("R4V3", "R4V3") {}

  function addController(address controller) external onlyOwner {
    require(_isControllersLocked == false, "Controllers are locked");
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    require(_isControllersLocked == false, "Controllers are locked");
    controllers[controller] = false;
  }

  function lockControllers() public onlyOwner {
    _isControllersLocked = true;
  }

  function isControllersLocked() public view returns (bool) {
    return _isControllersLocked;
  }

  function maxSupply() public view returns (uint256) {
    return MAXIMUM_RAVE_SUPPLY;
  }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");

    // This function intentionally don't revert, since we want to make sure it's
    // still callable even when supply is reached maximum.
    // In that case we just don't mint the new tokens.

    if (totalMintedSupply < MAXIMUM_RAVE_SUPPLY) {
      _mint(to, amount);
      totalMintedSupply.add(amount);
    }
  }

  function burnFrom(address account, uint256 amount) public override {
    if (controllers[msg.sender]) {
      _burn(account, amount);
    } else {
      super.burnFrom(account, amount);
    }
  }
}