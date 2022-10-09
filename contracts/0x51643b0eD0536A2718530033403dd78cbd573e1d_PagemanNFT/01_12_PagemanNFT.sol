// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//                                                       __ _   
//                                                      / _| |  
//  _ __   __ _  __ _  ___ _ __ ___   __ _ _ __    _ __ | |_| |_ 
// | '_ \ / _` |/ _` |/ _ \ '_ ` _ \ / _` | '_ \  | '_ \|  _| __|
// | |_) | (_| | (_| |  __/ | | | | | (_| | | | | | | | | | | |_ 
// | .__/ \__,_|\__, |\___|_| |_| |_|\__,_|_| |_| |_| |_|_|  \__|
// | |           __/ |                                           
//  _|          |___/                                            


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "erc721b/contracts/ERC721B.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/access/AccessControl.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
contract PagemanNFT is ERC721B, Ownable, AccessControl, IERC721Metadata {
  using Strings for uint256;

  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant _CURATOR_ROLE = keccak256("CURATOR_ROLE");
  string private _URI;
  uint256 public constant MAX_SUPPLY = 50;
  constructor(address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }
  function name () external pure returns (string memory) {
    return "Pageman NFT";
  }

  function symbol () external pure returns (string memory) {
    return "PGMN";
  }

  function mint(address to, uint256 amount) external onlyRole(_MINTER_ROLE) {
    if (totalSupply() + amount > MAX_SUPPLY) revert("supply is exceeded");
    _safeMint(to, amount);
  }
 
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl,ERC721B,IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    
    if (!_exists(tokenId)) revert ("token does not exist");
    return bytes(_URI).length > 0 ? string(abi.encodePacked(_URI, tokenId.toString(),".json")) : "";
  }
  function setURI(string memory uri) external onlyRole(_CURATOR_ROLE) {
    _URI = uri;
  }
}