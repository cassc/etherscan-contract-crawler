// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// OZ libraries
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract ProtocolFeeManager is Ownable {
  bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

  uint256 public protocolFeeRate;

  mapping(address => uint256) public premiumCollections;

  error InvalidProtocolFeeRate();

  event UpdatedCollectionFeeRate(address indexed collection, uint256 reducedFeeRate);
  event UpdatedProtocolFeeRate(uint256 protocolFeeRate);

  constructor(uint256 _protocolFeeRate) {
    protocolFeeRate = _protocolFeeRate;
  }

  /**
  * @notice updates the fee rate for the specified collection
  * @dev setting the fee rate to zero will remove the collection from the list of premium collections
  * @param collection the address of the collection to be added
  * @param feeRate the reduced fee rate to be applied for lenders who hold an NFT from this collection
  */
  function updateCollectionFeeRate(address collection, uint256 feeRate) external onlyOwner {
    premiumCollections[collection] = feeRate;
    
    emit UpdatedCollectionFeeRate(collection, feeRate);
  }

  /**
  * @notice updates the protocol fee rate
  * @dev cannot be set to a value greater than 10000 (100%)
  * @param _protocolFeeRate the new protocol fee rate
  */
  function updateProtocolFeeRate(uint256 _protocolFeeRate) external onlyOwner {
    if (_protocolFeeRate > 10000) revert InvalidProtocolFeeRate();
    protocolFeeRate = _protocolFeeRate;

    emit UpdatedProtocolFeeRate(_protocolFeeRate);
  }

  /** 
  * @notice Determines the protocol fee rate to charge based on whether the lender owns an NFT from a premium collection
  * @dev If the rate is set to 1, apply no fee
  * @param collection Collection address of one of the potential premium collections
  * @param tokenId token id of one of the potential premium collections
  * @param lender Address of the lender
  */
  function determineProtocolFeeRate(address collection, uint256 tokenId, address lender) external view returns (uint256) {
    if (
      collection != address(0)
      && premiumCollections[collection] > 0
      && ((IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) && IERC721(collection).ownerOf(tokenId) == lender)
      || (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155) && IERC1155(collection).balanceOf(lender, tokenId) > 0))
    ) { 
      uint256 premiumCollectionRate = premiumCollections[collection];
      if (premiumCollectionRate == 1) {
        return 0;
      }

      return premiumCollectionRate;
    } 

    return protocolFeeRate;
  }
}