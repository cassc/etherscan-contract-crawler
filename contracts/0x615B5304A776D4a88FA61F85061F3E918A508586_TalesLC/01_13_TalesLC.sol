// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

//          ..
//         .c;
//      .,:dOo,.
//       .,xOl,.     .;,.
//        .c.        cXN0o.   .
//        ..        :KWNWO'  :kxo:.
//                .oXWWW0,  'kXXXx.                       ..
//              .'cOWWWXc   ,dO0O:                    .....
//             .;',OWWNd.  .  .'..  ..     ..      .....
//           .,:..dWWWO'  :kxc.    ;O0x:. ,kOl.  ....
//          .c;. :XMWX: .lXWWNo. .dXWWWk',xNWWx'..
//         ,l,  .OMMWd..:OMMM0,'cckNWWKl::oNWXl.
//       .ll.   cNMMO'',;0MMXdc;';OWWNko;'OWXl
//      .ol.   .kMMNo:;.lNMWKd'.;xWWWXk;'xNWx.
//       .     ;XMMNk;. ,dOOc. lXNMWW0l;dXW0,        ..
//             ;0NW0;      .  ,0MMMWKd:cOWO,        .:'
//              .';.         .xWMMMWNOd0Kd'       .,o0o..
//                           :XMMW0l:cl:.         ..ld;..
//                          .OMMMO'                ...
//                         .oWM0d,
//                         ;KMX:
//                         :0Ko.
//                          ...

// Contract by SignorCrypto

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract TalesLC is ERC1155, ERC2981, Ownable {
  struct Token {
    uint256 id;
    string uri;
    uint256 minted;
  }

  mapping(uint256 => Token) public tokens;

  uint256 public tokenIdCounter = 0;

  constructor() ERC1155("") {}

  function mint(
    address[] calldata _receivers,
    uint256 _id,
    uint256[] calldata _amounts,
    bytes memory data
  ) public onlyOwner {
    require(tokenIdCounter > _id, "Token does not exist");
    uint256 receiversLength = _receivers.length;
    uint256 amountsLength = _amounts.length;
    require(receiversLength == amountsLength, "Arrays do not match");

    uint256 sumAmounts = 0;
    for (uint256 i = 0; i < receiversLength; ++i) {
      _mint(_receivers[i], _id, _amounts[i], data);
      sumAmounts += _amounts[i];
    }

    Token storage token = tokens[_id];
    token.minted += sumAmounts;
  }

  function createToken(string memory _newuri) external onlyOwner {
    Token storage token = tokens[tokenIdCounter];
    token.id = tokenIdCounter;
    token.uri = _newuri;

    tokenIdCounter++;
  }

  function setURI(uint256 _tokenId, string memory _newuri) external onlyOwner {
    Token storage token = tokens[_tokenId];
    token.uri = _newuri;
  }

  function setDefaultRoyalty(address receiver, uint96 feeBasisPoints) external onlyOwner {
    _setDefaultRoyalty(receiver, feeBasisPoints);
  }

  function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
    Token storage token = tokens[_id];
    return token.uri;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
    return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}