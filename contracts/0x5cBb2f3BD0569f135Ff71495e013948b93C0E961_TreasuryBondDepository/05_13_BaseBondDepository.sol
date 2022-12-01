// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IBaseBondDepository.sol";

/// @title BaseBondDepository
/// @author Bluejay Core Team
/// @notice BaseBondDepository provides logic for minting, burning and storing bond info.
/// The contract is to be inherited by treasury bond depository and stabilizing bond depository.
abstract contract BaseBondDepository is IBaseBondDepository {
  /// @notice Number of bonds minted, monotonic increasing from 0
  uint256 public bondsCount;

  /// @notice Map of bond ID to the bond information
  mapping(uint256 => Bond) public override bonds;

  /// @notice Map of bond ID to the address of the bond owner
  mapping(uint256 => address) public bondOwners;

  /// @notice Map of bond owner address to array of bonds owned
  mapping(address => uint256[]) public ownedBonds;

  /// @notice Map of bond owner and bond ID to the index location of `ownedBonds`
  mapping(address => mapping(uint256 => uint256)) public ownedBondsIndex;

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function for child contract to mint a bond with fixed vesting period to an address
  /// @param to Address to mint the bond to
  /// @param payout Amount of assets to payout across the entire vesting period
  /// @param vestingPeriod Vesting period of the bond
  function _mint(
    address to,
    uint256 payout,
    uint256 vestingPeriod
  ) internal returns (uint256 bondId) {
    bondId = ++bondsCount;
    bonds[bondId] = Bond({
      principal: payout,
      vestingPeriod: vestingPeriod,
      purchased: block.timestamp,
      lastRedeemed: block.timestamp
    });
    bondOwners[bondId] = to;
    uint256[] storage userBonds = ownedBonds[to];
    ownedBondsIndex[to][bondId] = userBonds.length;
    userBonds.push(bondId);
  }

  /// @notice Internal function for child contract to burn a bond, usually after it fully vest
  /// This recover gas as well as delete the bond from the view functions
  /// @param bondId Bond ID of the bond to burn
  /// @dev Perform required sanity check on the bond before burning it
  function _burn(uint256 bondId) internal {
    address bondOwner = bondOwners[bondId];
    require(bondOwner != address(0), "Invalid bond");
    uint256[] storage userBonds = ownedBonds[bondOwner];
    mapping(uint256 => uint256) storage userBondIndices = ownedBondsIndex[
      bondOwner
    ];
    uint256 lastBondIndex = userBonds.length - 1;
    uint256 bondIndex = userBondIndices[bondId];
    if (bondIndex != lastBondIndex) {
      uint256 lastBondId = userBonds[lastBondIndex];
      userBonds[bondIndex] = lastBondId;
      userBondIndices[lastBondId] = bondIndex;
    }
    userBonds.pop();
    delete userBondIndices[bondId];
    delete bonds[bondId];
    delete bondOwners[bondId];
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice List all bond IDs owned by an address
  /// @param owner Address of the owner of the bonds
  /// @return bondIds List of bond IDs owned by the address
  function listBondIds(address owner)
    public
    view
    override
    returns (uint256[] memory bondIds)
  {
    bondIds = ownedBonds[owner];
  }

  /// @notice List all bond info owned by an address
  /// @param owner Address of the owner of the bonds
  /// @return Bond List of bond info owned by the address
  function listBonds(address owner)
    public
    view
    override
    returns (Bond[] memory)
  {
    uint256[] memory bondIds = ownedBonds[owner];
    Bond[] memory bondsOwned = new Bond[](bondIds.length);
    for (uint256 i = 0; i < bondIds.length; i++) {
      bondsOwned[i] = bonds[bondIds[i]];
    }
    return bondsOwned;
  }
}