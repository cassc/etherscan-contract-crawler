// Copyright (c) 2023, ApeFathers NFT - GSKNNFT Inc
// Contract name: RoyaltiesFacet.sol

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.20;

import {IRoyalties} from "../interfaces/IRoyalties.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibDiamondDapes} from "../libraries/LibDiamondDapes.sol";
import {BitMapsUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/contracts/utils/structs/BitMapsUpgradeable.sol";

contract RoyaltiesFacet is IRoyalties {
  using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
  using LibDiamond for LibDiamond.DiamondStorage;
  using LibDiamondDapes for LibDiamondDapes.DiamondDapesStruct;

  /*
   * @notice Allow owner to pause contract
   */
  function setRoyaltyAddress(address _royaltyAddress) external {
    LibDiamond.enforceIsContractOwner();
    LibDiamondDapes.diamondDapesStorage().royaltyAddress = _royaltyAddress;
  }

  /**
   * @notice Change the royalty fee for the collection
   */
  function setRoyaltyFee(uint96 _feeNumerator) external {
    LibDiamond.enforceIsContractOwner();
    LibDiamondDapes.diamondDapesStorage().royaltyFee = _feeNumerator;
  }

  /**
   * @notice allows changing of the the address of the royalty recipient
   */
  function changeRoyalties(address _newRoyaltyAddress, uint96 _royaltyFee) external {
    LibDiamond.enforceIsContractOwner();
    require(
      _newRoyaltyAddress != LibDiamondDapes.diamondDapesStorage().royaltyAddress,
      "New address is same as current one"
    );
    LibDiamondDapes.diamondDapesStorage().royaltyAddress = _newRoyaltyAddress;
    LibDiamondDapes.diamondDapesStorage().royaltyFee = _royaltyFee;
  }

  /**
   * @notice allows changing of the the address of the payout recipients
   * @param _newPayoutAddresses - array of addresses to receive payouts
   * @param _newPayoutBasisPoints - array of basis points to receive payouts
   */
  function changePayoutAddresses(
    address[] calldata _newPayoutAddresses,
    uint16[] calldata _newPayoutBasisPoints
  ) external {
    LibDiamond.enforceIsContractOwner();
    require(
      _newPayoutAddresses.length == _newPayoutBasisPoints.length,
      "Payout addresses and basis points must be same length"
    );
    LibDiamondDapes.diamondDapesStorage().payoutAddresses = _newPayoutAddresses;
    LibDiamondDapes.diamondDapesStorage().payoutBasisPoints = _newPayoutBasisPoints;
  }

  /**
   * @notice Change the royalty address where royalty payouts are sent
   */
  function setRoyalty(uint96 _fee, address _recipient) external {
    LibDiamond.enforceIsContractOwner();
    require(_recipient != address(0), "Royalty recipient cannot be zero address");
    require(_fee <= 1500, "Invalid royalty fee"); // Ensure royalty fee is no more than 15%
    LibDiamondDapes.diamondDapesStorage().royaltyFee = _fee;
    LibDiamondDapes.diamondDapesStorage().royaltyAddress = _recipient;
  }

  function activateHolderRoyalties(bool _val, uint256 _perc) external {
    LibDiamond.enforceIsContractOwner();
    LibDiamondDapes.diamondDapesStorage().holderRoyaltiesActive = _val;
    LibDiamondDapes.diamondDapesStorage().holderPercents = _perc;
  }

  function calculateHolderRoyalties(uint256 total) internal view returns (uint256) {
    uint256 royaltyFee = calculateRoyaltyFee(total);
    uint256 holderRoyalty = (royaltyFee * LibDiamondDapes.diamondDapesStorage().holderPercents) / 100;
    return holderRoyalty;
  }

function calculateRoyaltyFee(uint256 total) internal view returns (uint256) {
  if (LibDiamondDapes.diamondDapesStorage().royaltyFee == 0) {
    return 0;
  }
  uint256 feeAmount = (total * LibDiamondDapes.diamondDapesStorage().royaltyFee) / 100;
  return feeAmount;
}


  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) public view returns (address receiver, uint256 royaltyAmount) {
    uint256 royaltyFee = LibDiamondDapes.diamondDapesStorage().royaltyFee;
    if (royaltyFee == 0) {
      return (address(0), 0);
    }
    uint256 feeAmount = calculateRoyaltyFee(_salePrice);
    return (LibDiamondDapes.diamondDapesStorage().royaltyAddress, feeAmount);
  }

  /**
   * @notice Withdraws all funds held within contract
   */
  function withdrawRoyalties() external {
    LibDiamond.enforceIsContractOwner();
    require(address(this).balance > 0, "NO_FUNDS");
    uint256 balance = address(this).balance;
    for (uint256 i = 0; i < LibDiamondDapes.diamondDapesStorage().payoutAddresses.length; i++) {
      require(
        payable(LibDiamondDapes.diamondDapesStorage().payoutAddresses[i]).send(
          (balance * LibDiamondDapes.diamondDapesStorage().payoutBasisPoints[i]) / 10000
        )
      );
    }
  }

  /*
   * @notice Allow owner to freeze payout addresses and basis points
   */
  function freezePayoutAddresses() external {
    LibDiamond.enforceIsContractOwner();
    require(
      LibDiamondDapes.diamondDapesStorage().payoutAddressesFrozen == false,
      "ApeFathers: payout addresses are frozen"
    );
    LibDiamondDapes.diamondDapesStorage().payoutAddressesFrozen = true;
  }

  function beforeTokenTransfers_(address from, address to, uint256, uint256) external payable {
    if (to == address(0) || from == address(0) || msg.value == 0 || LibDiamondDapes.diamondDapesStorage().royaltyFee == 0) {
      return; // Ignore the rest of the function and return
    } else {
      // Check if royalties are due
      if (LibDiamondDapes.diamondDapesStorage().holderRoyaltiesActive == true) {
        if (from != address(0) && LibDiamondDapes.diamondDapesStorage().royaltyFee > 0 && msg.value > 0) {
          uint256 royalty = calculateRoyaltyFee(msg.value); // Calculate royalty based on fee
          uint256 holderRoyalty = calculateHolderRoyalties(royalty); // Calculate holder royalty based on fee
          uint256 ownerRoyalty = royalty - holderRoyalty; // Calculate owner royalty as the difference
          (bool successHolder, ) = address(from).call{value: holderRoyalty}(""); // Transfer holder royalty to seller
          (bool successOwner, ) = LibDiamondDapes.diamondDapesStorage().royaltyAddress.call{value: ownerRoyalty}(""); // Transfer remaining royalty to owner
          require(successHolder && successOwner, "Royalty transfer failed");
        } else {
          // if the above statements are false, then no royalties are due to the holder (holderRoyaltiesActive == false)
          if (from != address(0) && LibDiamondDapes.diamondDapesStorage().royaltyFee > 0 && msg.value > 0) {
            uint256 royalty = calculateRoyaltyFee(msg.value); // Calculate royalty based on fee
            (bool success, ) = LibDiamondDapes.diamondDapesStorage().royaltyAddress.call{value: royalty}(""); // Transfer royalty to owner
            require(success, "Royalty transfer failed");
          }
        }
      }
    }
  }
}