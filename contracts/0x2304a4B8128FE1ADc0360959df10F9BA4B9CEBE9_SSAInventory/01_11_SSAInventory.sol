//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Prior art.

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// Contract art.

/*
                                                                                  ..    ' .
                                                                             .l-?}cQd*#MB*r.
                                                              ...,,i><]u0b%%[email protected]@[email protected][email protected]@@8p/`
        -U                                       .    .'i<)0do%8%@@[email protected][email protected]@@[email protected]@@@@@@@&ji.
       ;ob^                               'Il_-/[email protected]@@@[email protected]@@[email protected]%bf,
      'UBX             ..    . .'I_xYOhM&8B$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B%t
      i#MI      ..'"l_/rjzOM8&@@@@@@[email protected]@@@@@[email protected]*"
     I&@M_rwOpa*&%[email protected]@@[email protected]@@@@[email protected]@@[email protected]~
    [email protected]@@@@@BB%#oahmCz/1-. .      [email protected]@@[email protected])
    '[email protected]@Bd'' . .              `[email protected][email protected]%j
          [email protected]@M"                  .'[email protected]
          [email protected]@_                   `[email protected][
           [email protected]$z                   '[email protected]&]
           '[email protected]@%|.                  t%@@[email protected]#;
          . ([email protected]@Z`                  ~*@@[email protected]
            ^[email protected]@B/                  "[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$B|
             <*@@@? .                ;[email protected][email protected]@@U
              [email protected]}                  [email protected][email protected]@ai
               [email protected]@8_                 'v%@@[email protected]@J'
                (%@@@J`.               `[email protected]@[email protected])
                [email protected]@k>                ^mB$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$8!
                  ,LBBB8X^.             .'[email protected][email protected]@a<.
                   .]%@BBBO`             ..-#@@@[email protected]@@o!
                     "[email protected]@@8v`             .,Y%@@[email protected]@@Q`
                      ."Y&[email protected]@Bd1^  .          [email protected]@[email protected]@@BW).
                         '[email protected]@@@BMJ[:          ."[email protected]&t'
                           .[L#[email protected]@@BMn+>^.        ^juJ*&[email protected]@BW/.
                              [email protected]@@@@@WWdCxf)/[email protected]@@@[email protected]%f:
                               . .."Yw*[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]
                                        ,<{/0qmW%%B#aQv(-;'
                                                .
*/

// Whoops.

error ItemExists();
error SystemMustCall();

// Another agreement. A contract, if you will.

contract SSAInventory is ERC1155, Ownable {
using Strings for uint256;

  address public mainContractAddress;

  string public _baseURI;

  Item[] public items;
  mapping (string => Item) public inventory;

  struct Item {
    uint id;
    string name;
  }

  // Mods

  modifier onlySystem() {
    if (!(msg.sender == owner() || msg.sender == mainContractAddress)) revert SystemMustCall();
    _;
  }

  // Welcome to the Item Factory.

  constructor() ERC1155("") {}

  function supplyPaidAgents(address _to, uint _amount)
    external
    onlySystem
  {
    _mint(_to, 0, _amount, "");
    _mint(_to, 1, _amount, "");
    _mint(_to, 2, _amount, "");
  }

  // The Agency can shop for itself or others.
  function agencyMint(address _to, uint _itemId, uint _count)
    external
    onlySystem
  {
    _mint(_to, _itemId, _count, "");
  }

  // Admin.

  function addNewItem(string calldata _name)
    public
    onlyOwner
  {
    Item memory item = Item({
      id: items.length,
      name: _name
    });

    items.push(item);
    inventory[_name] = item;
  }

  function createGenesisItems(string[] calldata _names)
    external
    onlyOwner
  {
    for(uint i; i < _names.length;) {
      addNewItem(_names[i]);

      unchecked { ++i; }
    }
  }

  // Giveth. Taketh away.

  function sendAgentItems(address _to, uint _itemId, uint _count)
    external
    onlySystem
  {
    _mint(_to, _itemId, _count, "");
  }

  function destroyAgentItems(address _from, uint _itemId, uint _count)
    external
    onlySystem
  {
    _burn(_from, _itemId, _count);
  }

  // Set.

  function setBaseURI(string calldata baseURI)
    external
    onlyOwner
  {
    _baseURI = baseURI;
  }

  function setMainContractAddress(address _address)
    external
    onlyOwner
  {
    mainContractAddress = _address;
  }

  function uri(uint256 tokenId)
    public
    view
    virtual
    override
  returns (string memory) {
    return bytes(_baseURI).length > 0
      ? string(abi.encodePacked(_baseURI, tokenId.toString()))
      : "";
  }

}