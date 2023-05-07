// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'erc1155delta/contracts/extensions/ERC1155DeltaQueryable.sol';
import { ERC2981 } from '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

/**
 /$$$$$$$  /$$$$$$$$ /$$$$$$$  /$$$$$$$  /$$$$$$$  /$$$$$$$$
| $$__  $$| $$_____/| $$__  $$| $$__  $$| $$__  $$|_____ $$ 
| $$  \ $$| $$      | $$  \ $$| $$  \ $$| $$  \ $$     /$$/ 
| $$  | $$| $$$$$   | $$  | $$| $$$$$$$/| $$$$$$$/    /$$/  
| $$  | $$| $$__/   | $$  | $$| $$____/ | $$__  $$   /$$/   
| $$  | $$| $$      | $$  | $$| $$      | $$  \ $$  /$$/    
| $$$$$$$/| $$$$$$$$| $$$$$$$/| $$      | $$  | $$ /$$$$$$$$
|_______/ |________/|_______/ |__/      |__/  |__/|________/

www.dedprz.io
*/

/**
 * @title DEDPRZ Contract
 * @dev Extends ERC1155Delta Non-Fungible Token Standard
 */
contract DEDPRZ_Seed_NFT is
  ERC1155DeltaQueryable,
  ERC2981,
  DefaultOperatorFilterer
{
  address public owner; // contract owner

  /// @dev Owner only modifier
  modifier onlyOwner() {
    require(msg.sender == owner, '!Owner');
    _;
  }

  /// @dev Constructooor
  constructor()
    ERC1155Delta('https://dedprz-seed.s3.amazonaws.com/{id}.json')
    ERC1155DeltaQueryable()
    ERC2981()
  {
    // set owner
    owner = msg.sender;

    // mint 25 NFTs to deploying wallet
    _mint(msg.sender, 25);

    // set default royalty
    _setDefaultRoyalty(owner, 500);
  }

  /// @dev Override to use filter operator
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /// @dev Override transfer to use filter operator
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  /// @dev Override batch transfer to use filter operator
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /// @dev Override ERC1155Delta to also support ERC2981 royalty standard
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC1155Delta, ERC2981) returns (bool) {
    return
      ERC1155Delta.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  /// @notice Owner transfer function to send each of the 25 tokens to 25 different addresses
  function ownerTransfer(
    address[] memory to,
    uint256[] memory ids
  ) external onlyOwner {
    for (uint256 i = 0; i < 25; i++) {
      _safeTransferFrom(msg.sender, to[i], ids[i], 1, '');
    }
  }

  /// @notice Get total minted
  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  /// @notice Set owner address
  function setOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  /// @notice Set URI of tokens for future IPFS update
  function setURI(string memory newuri) external virtual onlyOwner {
    _setURI(newuri);
  }

  /// @notice Set royalty for marketplaces complying with ERC2981 standard
  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }
}