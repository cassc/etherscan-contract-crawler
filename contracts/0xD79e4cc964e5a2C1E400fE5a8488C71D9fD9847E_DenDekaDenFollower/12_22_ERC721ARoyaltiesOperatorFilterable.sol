pragma solidity ^0.8.17;

// SPDX-License-Identifier: SEE LICENSE IN LICENSE


// EIP 2981 for royalties
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// Using ERC721A for gas effiscient batch minting
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';

// filter registry library
import 'closedsea/src/OperatorFilterer.sol';

// library ERC721ARoyaltiesOperatableFilterableUpgradeable__Storage {
//   struct Layout {
//     // if we enable or disable filtering
//     bool operatorFilteringEnabled;
//   }

//   bytes32 internal constant STORAGE_SLOT = keccak256('ERC721ARoyaltiesOperatableFilterable.contracts.storage.facet');

//   function layout() internal pure returns (Layout storage l) {
//     bytes32 slot = STORAGE_SLOT;
//     assembly {
//       l.slot := slot
//     }
//   }
// }

abstract contract ERC721ARoyaltiesOperatorFilterable is
  ERC721AQueryable,
  ERC2981,
  OperatorFilterer,
  Ownable
{

  // use operator filtering by default
  bool operatorFilteringEnabled = true;

  constructor(string memory name_, string memory symbol_, address royaltyBeneficiary, uint96 feeNumerator ) ERC721A(name_, symbol_) {

    // register for filtering by default
    _registerForOperatorFiltering();

    // default royalties to deployer account and at $(ROYALITY_BASIS_POINTS)
    _setDefaultRoyalty(royaltyBeneficiary, feeNumerator);
  }


  // =============================================================
  //                            IERC165
  // =============================================================

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30000 gas.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  // =============================================================
  //                           IERC2981
  // =============================================================

  /**
   * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
   */
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  // =============================================================
  //                     FILTER OPERATOR
  // =============================================================

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }
  

  // function _isPriorityOperator(address operator) internal pure override returns (bool) {
  //     // OpenSea Seaport Conduit:
  //     // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
  //     // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
  //     return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
  // }
}