/* 
  Copyright Statement

  Random Panda Club is an NFT project created by PandaDAO. The following is our copyright statement for NFT:

  i. You own the NFT. Each Random Panda is an NFT on the Ethereum blockchain. When you purchase an NFT, you own the underlying Art completely. Ownership of the NFT is mediated entirely by the Smart Contract and the Ethereum Network: at no point may we seize, freeze, or otherwise modify the ownership of any Random Panda.

  ii. Personal Use. Subject to your continued compliance with these Terms, PandaDAO LTD grants you a worldwide, royalty-free license to use, copy, and display the purchased Art, along with any extensions that you choose to create or use, solely for the following purposes: (i) for your own personal, non-commercial use; (ii) as part of a marketplace that permits the purchase and sale of your Random Panda / NFT, provided that the marketplace cryptographically verifies each Random Panda owner’s rights to display the Art for their Random Panda to ensure that only the actual owner can display the Art; or (iii) as part of a third party website or application that permits the inclusion, involvement, or participation of your Random Panda, provided that the website/application cryptographically verifies each Random Panda owner’s rights to display the Art for their Random Panda to ensure that only the actual owner can display the Art, and provided that the Art is no longer visible once the owner of the Random Panda leaves the website/application.

  iii. Commercial Use. Subject to your continued compliance with these Terms, PandaDAO LTD grants you an unlimited, worldwide license to use, copy, and display the purchased Art for the purpose of creating derivative works based upon the Art (“Commercial Use”). Examples of such Commercial Use would e.g. be the use of the Art to produce and sell merchandise products (T-Shirts etc.) displaying copies of the Art. For the sake of clarity, nothing in this Section will be deemed to restrict you from (i) owning or operating a marketplace that permits the use and sale of Random Panda generally, provided that the marketplace cryptographically verifies each Random Panda owner’s rights to display the Art for their Random Panda to ensure that only the actual owner can display the Art; (ii) owning or operating a third party website or application that permits the inclusion, involvement, or participation of Random Panda generally, provided that the third party website or application cryptographically verifies each Random Panda owner’s rights to display the Art for their Random Panda to ensure that only the actual owner can display the Art, and provided that the Art is no longer visible once the owner of the Purchased Random Panda leaves the website/application; or (iii) earning revenue from any of the foregoing.

  iiii. The holder of a Random Panda NFT can claim the CC0 copyright. Once the holder once does so, they will share the copyright of the NFT free to the world. The CC0 copyright is irreversible and will override the copyright notice in the i. ii. iii. content. 
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract RandomPandaClubSpecial is ERC1155, AccessControl {
  string public constant name = "Random Panda Club Special";
  string public constant symbol = "RPCSPECIAL";

  bytes32 public constant MINTER = keccak256("MINTER");

  mapping(uint256 => string) private _uris;
  string private _contractURI;

  constructor() ERC1155("") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(MINTER, _msgSender());
  }

  // Minting

  function mint(uint256 _id, uint256 _amount, string memory _uri, address _destination) public onlyRole(MINTER) {
    setUri(_id, _uri);
    _mint(_destination, _id, _amount, "");
  }

  function setUri(uint256 _id, string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _uris[_id] = _uri;
  }

  function uri(uint256 _id) public view virtual override returns (string memory) {
    return _uris[_id];
  }

  // Metadata

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _contractURI = _uri;
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId
      || interfaceId == type(AccessControl).interfaceId
      || super.supportsInterface(interfaceId);
  }
}