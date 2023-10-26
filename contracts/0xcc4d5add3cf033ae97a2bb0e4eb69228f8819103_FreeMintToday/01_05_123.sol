// SPDX-License-Identifier: MINT

/*
    ____                      
   / __/_______  ___          
  / /_/ ___/ _ \/ _ \         
 / __/ /  /  __/  __/         
/_/ /_/   \___/\___/  __      
   ____ ___  (_)___  / /_     
  / __ `__ \/ / __ \/ __/     
 / / / / / / / / / / /_       
/_/_/_/ /_/_/_/ /_/\__/       
  / /_____  ____/ /___ ___  __
 / __/ __ \/ __  / __ `/ / / /
/ /_/ /_/ / /_/ / /_/ / /_/ / 
\__/\____/\__,_/\__,_/\__, /  
                     /____/   
 */

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';

contract FreeMintToday is Ownable, ERC721A {
  string public constant baseURI =
    'ipfs://bafybeid42e3eucun3w6o2kfxvcnstnxhjaqia5qojireqaajlj373a7dpa/';

  uint256 public constant maxSupply = 2222;

  uint256 public constant maxWalletSupply = 2;

  constructor() ERC721A('FreeMintToday', 'FMT') {}

  function _baseURI() internal pure override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function mint(address to, uint256 quantity) external {
    unchecked {
      require((_nextTokenId() - 1 + quantity) <= maxSupply);
      require((_numberMinted(msg.sender) + quantity) <= maxWalletSupply);
    }

    _mint(to, quantity);
  }
}