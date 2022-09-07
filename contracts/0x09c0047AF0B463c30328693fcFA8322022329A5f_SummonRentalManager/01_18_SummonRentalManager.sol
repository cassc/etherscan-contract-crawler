//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./GnosisSafe/GnosisSafe.sol";

abstract contract IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) virtual external;
}

contract SummonRentalManager {

  // Constant used for default owner of GnosisSafe
  address internal constant SENTINEL_OWNERS = address(0x1);

  // Safes -> tokenAddress/ID hash -> RentalInfo
  mapping(address => mapping(bytes32 => RentalInfo)) internal activeRentals;

  event RentalAdded(address safeAddress, address tokenAddress, uint256 tokenId, address lenderAddress, address borrowerAddress);
  event RentalEnded(address safeAddress, address tokenAddress, uint256 tokenId, address lenderAddress, address borrowerAddress);
  event BorrowerChanged(address safeAddress, address oldBorrower, address newBorrower);

  struct RentalInfo {
    address borrowerAddress;
    address lenderAddress;
    bool isIntialized;
  }

  function addRental(
    address safeAddress,
    address borrowerAddress,
    address tokenAddress,
    uint256 tokenId,
    bytes memory signature
  ) public {
    GnosisSafe safe = GnosisSafe(payable(safeAddress));

    // Ensure safe is availible
    require(
      safe.getOwners().length == 1 &&
      safe.isOwner(address(this)),
      "Safe address is already in use"
    );

    // Ensure rental isn't already active
    bytes32 rentalHash = genrateRentalHash(tokenAddress, tokenId);
    require(
      activeRentals[safeAddress][rentalHash].isIntialized == false,
      "Rental is already active"
     );

    // Store record of rental
    activeRentals[safeAddress][rentalHash] = RentalInfo(
      borrowerAddress,
      msg.sender,
      true
    );

    // Add module to safe to enable NFT return if it's not been added
    if (!safe.isModuleEnabled(address(this))) {
      bytes memory moduleData = abi.encodeWithSignature(
        "enableModule(address)",
        address(this)
      );

      execTransaction(safeAddress, 0, moduleData, signature);
    }

    addOwnerToSafe(safeAddress, msg.sender, 1, signature);
    addOwnerToSafe(safeAddress, borrowerAddress, 3, signature);

    emit RentalAdded(safeAddress, tokenAddress, tokenId, msg.sender, borrowerAddress);
  }

  function addOwnerToSafe(
    address safeAddress,
    address newOwner,
    uint256 threshold,
    bytes memory signature
  ) internal {
    bytes memory addOwnerData = abi.encodeWithSignature(
      "addOwnerWithThreshold(address,uint256)",
      newOwner,
      threshold
    );

    execTransaction(safeAddress, 0, addOwnerData, signature);
  }

  //prevOwner is used by GnosisSafe to point to oldBorrower
  function swapBorrower(
    address safeAddress,
    address tokenAddress,
    uint256 tokenId,
    address prevOwner,
    address oldBorrower,
    address newBorrower
  ) public {
    bytes32 rentalHash = genrateRentalHash(tokenAddress, tokenId);
    RentalInfo memory info = activeRentals[safeAddress][rentalHash];

    // Ensure that the user triggering the swap authorized the rental
    require(msg.sender == info.lenderAddress, "Sender not authorized");

    bytes memory swapOwnerData = abi.encodeWithSignature(
      "swapOwner(address,address,address)",
      prevOwner,
      oldBorrower,
      newBorrower
    );

    GnosisSafe(payable(safeAddress)).execTransactionFromModule(
      safeAddress,
      0,
      swapOwnerData,
      Enum.Operation.Call
    );

    emit BorrowerChanged(safeAddress, oldBorrower, newBorrower);
  }

  function getRentalInfo(
    address safe,
    address tokenAddress,
    uint256 tokenId
  ) public view returns(RentalInfo memory) {
    bytes32 rentalHash = genrateRentalHash(tokenAddress, tokenId);
    return activeRentals[safe][rentalHash];
  }

  function returnNFT(
    address safeAddress,
    address tokenAddress,
    uint256 tokenId
  ) public {
    bytes32 rentalHash = genrateRentalHash(tokenAddress, tokenId);
    RentalInfo memory info = activeRentals[safeAddress][rentalHash];

    // Ensure that the user triggering the return is the lender
    require(msg.sender == info.lenderAddress, "Sender not authorized");

    // Transfer NFT back to lender wallet
    bytes memory transferData = abi.encodeWithSignature(
      "safeTransferFrom(address,address,uint256)",
      safeAddress,
      info.lenderAddress,
      tokenId
    );

    GnosisSafe(payable(safeAddress)).execTransactionFromModule(
      tokenAddress,
      0,
      transferData,
      Enum.Operation.Call
    );

    resetSafe(safeAddress, tokenAddress, tokenId);

    // Remove rental entry
    delete activeRentals[safeAddress][rentalHash];

    emit RentalEnded(safeAddress, tokenAddress, tokenId, info.lenderAddress, info.borrowerAddress);
  }

  function resetSafe(
    address safeAddress,
    address tokenAddress,
    uint256 tokenId
  ) internal {
    bytes32 rentalHash = genrateRentalHash(tokenAddress, tokenId);
    RentalInfo memory info = activeRentals[safeAddress][rentalHash];

    removeOwnerFromSafe(safeAddress, info.borrowerAddress, 1);
    removeOwnerFromSafe(safeAddress, info.lenderAddress, 1);
  }

  function removeOwnerFromSafe(
    address safeAddress,
    address owner,
    uint256 threshold
  ) internal {
    GnosisSafe safe = GnosisSafe(payable(safeAddress));
    address[] memory owners = safe.getOwners();

// We must send the address of the 'prevOwner' that points to owner that we want to
// remove.
    address prevOwner;

    for (uint256 i = 0; i < owners.length; i++) {
      if (owners[i] == owner) {
        if(i == 0) {
          prevOwner = SENTINEL_OWNERS;
        } else {
          prevOwner = owners[i - 1];
        }
      }
    }

    bytes memory removeOwnerData = abi.encodeWithSignature(
      "removeOwner(address,address,uint256)",
      prevOwner,
      owner,
      threshold
    );

    GnosisSafe(payable(safeAddress)).execTransactionFromModule(
      safeAddress,
      0,
      removeOwnerData,
      Enum.Operation.Call
    );
  }

  function genrateRentalHash(
    address tokenAdress,
    uint256 tokenId
  ) internal pure returns(bytes32) {
    return keccak256(abi.encodePacked(tokenAdress, tokenId));
  }

  function execTransaction (
   address safeAddress,
   uint256 value,
   bytes memory data,
   bytes memory signature
 ) internal {
   GnosisSafe(payable(safeAddress)).execTransaction(
     safeAddress,
     value,
     data,
     Enum.Operation.Call,
     0,
     0,
     0,
     address(0),
     payable(address(0)),
     signature
   );
 }
}