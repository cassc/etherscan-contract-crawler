//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;


//  ███▄ ▄███▓ ▒█████   ▒█████   ███▄    █  ██▀███   █    ██  ███▄    █  ███▄    █ ▓█████  ██▀███    ██████ 
// ▓██▒▀█▀ ██▒▒██▒  ██▒▒██▒  ██▒ ██ ▀█   █ ▓██ ▒ ██▒ ██  ▓██▒ ██ ▀█   █  ██ ▀█   █ ▓█   ▀ ▓██ ▒ ██▒▒██    ▒ 
// ▓██    ▓██░▒██░  ██▒▒██░  ██▒▓██  ▀█ ██▒▓██ ░▄█ ▒▓██  ▒██░▓██  ▀█ ██▒▓██  ▀█ ██▒▒███   ▓██ ░▄█ ▒░ ▓██▄   
// ▒██    ▒██ ▒██   ██░▒██   ██░▓██▒  ▐▌██▒▒██▀▀█▄  ▓▓█  ░██░▓██▒  ▐▌██▒▓██▒  ▐▌██▒▒▓█  ▄ ▒██▀▀█▄    ▒   ██▒
// ▒██▒   ░██▒░ ████▓▒░░ ████▓▒░▒██░   ▓██░░██▓ ▒██▒▒▒█████▓ ▒██░   ▓██░▒██░   ▓██░░▒████▒░██▓ ▒██▒▒██████▒▒
// ░ ▒░   ░  ░░ ▒░▒░▒░ ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░ ▒▓ ░▒▓░░▒▓▒ ▒ ▒ ░ ▒░   ▒ ▒ ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒▓ ░▒▓░▒ ▒▓▒ ▒ ░
// ░  ░      ░  ░ ▒ ▒░   ░ ▒ ▒░ ░ ░░   ░ ▒░  ░▒ ░ ▒░░░▒░ ░ ░ ░ ░░   ░ ▒░░ ░░   ░ ▒░ ░ ░  ░  ░▒ ░ ▒░░ ░▒  ░ ░
// ░      ░   ░ ░ ░ ▒  ░ ░ ░ ▒     ░   ░ ░   ░░   ░  ░░░ ░ ░    ░   ░ ░    ░   ░ ░    ░     ░░   ░ ░  ░  ░  
//        ░       ░ ░      ░ ░           ░    ░        ░              ░          ░    ░  ░   ░           ░  
                                                                                                         
//  ██▓     ▒█████   ▒█████  ▄▄▄█████▓                                                                      
// ▓██▒    ▒██▒  ██▒▒██▒  ██▒▓  ██▒ ▓▒                                                                      
// ▒██░    ▒██░  ██▒▒██░  ██▒▒ ▓██░ ▒░                                                                      
// ▒██░    ▒██   ██░▒██   ██░░ ▓██▓ ░                                                                       
// ░██████▒░ ████▓▒░░ ████▓▒░  ▒██▒ ░                                                                       
// ░ ▒░▓  ░░ ▒░▒░▒░ ░ ▒░▒░▒░   ▒ ░░                                                                         
// ░ ░ ▒  ░  ░ ▒ ▒░   ░ ▒ ▒░     ░                                                                          
//   ░ ░   ░ ░ ░ ▒  ░ ░ ░ ▒    ░                                                                            
//     ░  ░    ░ ░      ░ ░                                                                                 


import {ERC1155Factory} from "./base/ERC1155Factory.sol";

error MismatchingArrayLength();

contract MoonrunnersLoot is ERC1155Factory {
  constructor(string memory name_, string memory symbol_) ERC1155Factory(name_, symbol_) {}

  /* -------------------------------------------------------------------------- */
  /*                           onlyOwnerOrController                            */
  /* -------------------------------------------------------------------------- */

  function mint(
    address to,
    uint256 id,
    uint256 amount
  ) public onlyOwnerOrController {
    _mint(to, id, amount);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public onlyOwnerOrController {
    _mintBatch(to, ids, amounts);
  }

  function moonDrop(
    address[] calldata to,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external onlyOwnerOrController {
    if (!((to.length == ids.length) && (to.length == amounts.length))) revert MismatchingArrayLength();

    for (uint256 i; i < to.length; ++i) {
      _mint(to[i], ids[i], amounts[i]);
    }
  }

  function moonDropBatch(
    address[] calldata to,
    uint256[][] calldata ids,
    uint256[][] calldata amounts
  ) external onlyOwnerOrController {
    if (!((to.length == ids.length) && (to.length == amounts.length))) revert MismatchingArrayLength();

    for (uint256 i; i < to.length; ++i) {
      address _to = to[i];
      uint256[] calldata _ids = ids[i];
      uint256[] calldata _amounts = amounts[i];

      if (_ids.length != _amounts.length) revert MismatchingArrayLength();
      _mintBatch(_to, _ids, _amounts);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                     Burn                                   */
  /* -------------------------------------------------------------------------- */

  function burn(uint256 id, uint256 amount) external {
    _burn(_msgSender(), id, amount);
  }

  /// @notice burn from controller
  function controlledBurn(
    address from,
    uint256 id,
    uint256 amount
  ) public onlyController {
    _burn(from, id, amount);
  }
}