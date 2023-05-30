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
                                                                                                         
// ▄▄▄█████▓ ██▀███   ▒█████   ██▓███   ██░ ██  ██▓▓█████   ██████                                          
// ▓  ██▒ ▓▒▓██ ▒ ██▒▒██▒  ██▒▓██░  ██▒▓██░ ██▒▓██▒▓█   ▀ ▒██    ▒                                          
// ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██░  ██▒▓██░ ██▓▒▒██▀▀██░▒██▒▒███   ░ ▓██▄                                            
// ░ ▓██▓ ░ ▒██▀▀█▄  ▒██   ██░▒██▄█▓▒ ▒░▓█ ░██ ░██░▒▓█  ▄   ▒   ██▒                                         
//   ▒██▒ ░ ░██▓ ▒██▒░ ████▓▒░▒██▒ ░  ░░▓█▒░██▓░██░░▒████▒▒██████▒▒                                         
//   ▒ ░░   ░ ▒▓ ░▒▓░░ ▒░▒░▒░ ▒▓▒░ ░  ░ ▒ ░░▒░▒░▓  ░░ ▒░ ░▒ ▒▓▒ ▒ ░                                         
//     ░      ░▒ ░ ▒░  ░ ▒ ▒░ ░▒ ░      ▒ ░▒░ ░ ▒ ░ ░ ░  ░░ ░▒  ░ ░                                         
//   ░        ░░   ░ ░ ░ ░ ▒  ░░        ░  ░░ ░ ▒ ░   ░   ░  ░  ░                                           
//             ░         ░ ░            ░  ░  ░ ░     ░  ░      ░                                           


import {ERC1155Factory} from "./base/ERC1155Factory.sol";

error MismatchingArrayLength();

contract MoonrunnersTrophies is ERC1155Factory {
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
    address[] memory to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) external onlyOwnerOrController {
    if (!((to.length == ids.length) && (to.length == amounts.length))) revert MismatchingArrayLength();

    for (uint256 i; i < to.length; ++i) {
      _mint(to[i], ids[i], amounts[i]);
    }
  }
}