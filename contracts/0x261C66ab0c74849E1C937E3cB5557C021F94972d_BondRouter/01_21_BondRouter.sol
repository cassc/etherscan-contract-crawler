// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IStabilizingBondDepository.sol";
import "./interfaces/ITreasuryBondDepository.sol";
import "./interfaces/IStakedToken.sol";
import "./interfaces/IBondRouter.sol";

/// @title BondRouter
/// @author Bluejay Core Team
/// @notice BondRouter routes purchase and redemption of bonds from end users to
/// different bond depositories. This allow users to only grant approvals to their
/// assets only once.
/// @dev The router holds custody of all bonds purchased and assigns a separate
/// bond ID to each bond held.
contract BondRouter is
  Initializable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  IBondRouter
{
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;

  /// @notice Contract address of BLU token
  IERC20 public BLU;

  /// @notice Contract address of sBLU token, for staking of redeemed BLU
  IStakedToken public sBLU;

  /// @notice Counter for tracking bond ID assigned to bonds managed by this router
  /// @dev This ID is different from the bond ID from the different bond depository
  Counters.Counter private _tokenIdTracker;

  /// @notice Mapping of bond depository addresses to the assets they receives as payment
  /// @dev bondReserve[depositoryAddress] = assetAddress
  mapping(address => address) public bondReserve;

  /// @notice Mapping of bond depository addresses to type of depository
  /// @dev bondDepositoryType[depositoryAddress] = BondType
  mapping(address => BondType) public bondType;

  /// @notice Mapping of a bond ID to its owner's address
  mapping(uint256 => address) public bondOwner;

  /// @notice Mapping of a bond ID to information of underlying bond purchased
  mapping(uint256 => Bond) public bonds;

  /// @notice Mapping of a user addresses to a list of all bonds owned
  mapping(address => EnumerableSet.UintSet) private _ownedBonds;

  /// @notice Check that a bond depository has been initialized
  modifier bondAdded(address bond) {
    require(bondReserve[bond] != address(0), "Bond not added");
    _;
  }

  /// @notice Initializer to initialize the contract
  /// @param _blu address of BLU token
  /// @param _sblu address of sBLU token, for staking of redeemed BLU
  function initialize(address _blu, address _sblu) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();

    BLU = IERC20(_blu);
    sBLU = IStakedToken(_sblu);
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function mint a bond receipt to a user
  /// @dev Nore that he ID of the bond receipt may not correspond to the underlying bond
  /// from the depository.
  /// @param to Address of user who owns the bond
  /// @return tokenId ID of the bond receipt
  function _mint(address to) internal returns (uint256 tokenId) {
    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();
    bondOwner[tokenId] = to;
    _ownedBonds[to].add(tokenId);
  }

  /// @notice Internal function burn a bond receipt
  /// @param tokenId ID of the bond receipt
  function _burn(uint256 tokenId) internal {
    require(
      _ownedBonds[bondOwner[tokenId]].remove(tokenId),
      "Non-existent bond"
    );
    delete bonds[tokenId];
    delete bondOwner[tokenId];
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Purchase a treasury bond through the router
  /// @param bond Address of the bond depository selling the treasury bond
  /// @param amount Amount of assets used to purchase the bond
  /// @param maxPrice Maximum price to pay for the bond, in WAD
  /// @param recipient Address to credit the bond to
  /// @return tokenId ID of the bond receipt from the router, use this later for redemption
  /// @return bondId Bond ID assigned by the bond depository
  function purchaseTreasuryBond(
    address bond,
    uint256 amount,
    uint256 maxPrice,
    address recipient
  ) public override bondAdded(bond) returns (uint256 tokenId, uint256 bondId) {
    require(bondType[bond] == BondType.TREASURY, "Not treasury bond");
    IERC20 reserve = IERC20(bondReserve[bond]);
    reserve.safeTransferFrom(msg.sender, address(this), amount);
    reserve.safeIncreaseAllowance(bond, amount);
    bondId = ITreasuryBondDepository(bond).purchase(
      amount,
      maxPrice,
      address(this)
    );
    tokenId = _mint(recipient);
    bonds[tokenId] = Bond({depository: bond, id: bondId});
    emit BondPurchased(tokenId, bond, recipient, bondId);
  }

  /// @notice Purchase a stabilizing bond through the router
  /// @param bond Address of the bond depository selling the stabilizing bond
  /// @param amount Amount of assets used to purchase the bond
  /// @param maxPrice Maximum price to pay for the bond, in WAD
  /// @param minOutput Minimum output of the underlying swap to prevent slippages
  /// @param recipient Address to credit the bond to
  /// @return tokenId ID of the bond receipt from the router, use this later for redemption
  /// @return bondId Bond ID assigned by the bond depository
  function purchaseStabilizingBond(
    address bond,
    uint256 amount,
    uint256 maxPrice,
    uint256 minOutput,
    address recipient
  ) public override bondAdded(bond) returns (uint256 tokenId, uint256 bondId) {
    require(bondType[bond] == BondType.STABILIZING, "Not stabilizing bond");
    IERC20 reserve = IERC20(bondReserve[bond]);
    reserve.safeTransferFrom(msg.sender, address(this), amount);
    reserve.safeIncreaseAllowance(bond, amount);
    bondId = IStabilizingBondDepository(bond).purchase(
      amount,
      maxPrice,
      minOutput,
      address(this)
    );
    tokenId = _mint(recipient);
    bonds[tokenId] = Bond({depository: bond, id: bondId});
    emit BondPurchased(tokenId, bond, recipient, bondId);
  }

  /// @notice Redeem BLU tokens from a purchased bond
  /// @param id ID of the bond receipt when purchasing the bond
  /// @param recipient Address to credit the BLU to
  /// @return payout Amount of BLU tokens sent to recipient, in WAD
  /// @return principal Amount of BLU tokens left to be vested on the bond, in WAD
  function redeem(uint256 id, address recipient)
    public
    override
    returns (uint256 payout, uint256 principal)
  {
    require(msg.sender == bondOwner[id], "Not owner");
    Bond memory bond = bonds[id];
    (payout, principal) = IBondDepositoryCommon(bond.depository).redeem(
      bond.id,
      recipient
    );
    if (principal == 0) {
      _burn(id);
    }
    emit BondRedeemed(
      id,
      bond.depository,
      recipient,
      bond.id,
      payout,
      principal
    );
  }

  /// @notice Redeem BLU tokens from a purchased bond and stake them for the user
  /// @param id ID of the bond receipt when purchasing the bond
  /// @param recipient Address to credit the BLU to
  /// @return payout Amount of BLU tokens sent to recipient, in WAD
  /// @return principal Amount of BLU tokens left to be vested on the bond, in WAD
  function redeemAsStaked(uint256 id, address recipient)
    public
    override
    returns (uint256 payout, uint256 principal)
  {
    (payout, principal) = redeem(id, address(this));
    BLU.safeIncreaseAllowance(address(sBLU), payout);
    sBLU.stake(payout, recipient);
  }

  /// @notice Redeem BLU tokens from multiple purchased bond
  /// @param ids Array of IDs of the bond receipts when purchasing the bonds
  /// @param recipient Address to credit the BLU to
  /// @return payout Amount of BLU tokens sent to recipient, in WAD
  /// @return principal Amount of BLU tokens left to be vested on the bond, in WAD
  function redeemMultiple(uint256[] calldata ids, address recipient)
    public
    override
    returns (uint256 payout, uint256 principal)
  {
    for (uint256 i = 0; i < ids.length; i++) {
      (uint256 currentPayout, uint256 currentPrincipal) = redeem(
        ids[i],
        recipient
      );
      payout += currentPayout;
      principal += currentPrincipal;
    }
  }

  /// @notice Redeem BLU tokens from multiple purchased bond and stake them for the user
  /// @param ids Array of IDs of the bond receipts when purchasing the bonds
  /// @param recipient Address to credit the BLU to
  /// @return payout Amount of BLU tokens sent to recipient, in WAD
  /// @return principal Amount of BLU tokens left to be vested on the bond, in WAD
  function redeemMultipleAsStaked(uint256[] calldata ids, address recipient)
    public
    override
    returns (uint256 payout, uint256 principal)
  {
    (payout, principal) = redeemMultiple(ids, address(this));
    BLU.safeIncreaseAllowance(address(sBLU), payout);
    sBLU.stake(payout, recipient);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get bond receipt ID at a given index on the list of bonds owned by a user
  /// @dev There is no gurantee on the ordering of values inside the array, and
  /// it may change when more values are added or removed. This transaction reverts
  /// when index is greater than the length.
  /// @param user Address of the user
  /// @param index Index of the bond on the list of bonds owned by the user
  /// @return bondId ID of the bond receipt
  function bondAt(address user, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    return _ownedBonds[user].at(index);
  }

  /// @notice Count the number of bonds receipts a user has
  /// @dev Bonds that are fully redeemed are deleted
  /// @param user Address of the user
  /// @return count Number of bonds owned by the user
  function bondCount(address user) public view override returns (uint256) {
    return _ownedBonds[user].length();
  }

  /// @notice List the IDs of the bond receipts owned by a user
  /// @param user Address of the user
  /// @return ids Array of bond receipt IDs owned by the user
  function bondList(address user)
    public
    view
    override
    returns (uint256[] memory)
  {
    return _ownedBonds[user].values();
  }

  /// @notice List details of the bonds owned by a user
  /// @param owner Address of the owner
  /// @return bondDetails Array of bond details owned by the user
  function bondDetailList(address owner)
    public
    view
    override
    returns (BondDetail[] memory)
  {
    uint256[] memory bondIds = bondList(owner);
    BondDetail[] memory bondsOwned = new BondDetail[](bondIds.length);
    for (uint256 i = 0; i < bondIds.length; i++) {
      Bond memory bond = bonds[bondIds[i]];
      (
        uint256 principal,
        uint256 vestingPeriod,
        uint256 purchased,
        uint256 lastRedeemed
      ) = IBondDepositoryCommon(bond.depository).bonds(bond.id);
      bondsOwned[i] = BondDetail({
        depository: bond.depository,
        routerId: bondIds[i],
        id: bond.id,
        principal: principal,
        vestingPeriod: vestingPeriod,
        purchased: purchased,
        lastRedeemed: lastRedeemed
      });
    }
    return bondsOwned;
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Add a new bond depository to the router
  /// @param _bondAddr Address of the bond depository
  /// @param _bondType Type of bond router. 0 for Treasury, 1 for Stabilizing
  function addBond(address _bondAddr, BondType _bondType)
    public
    override
    onlyOwner
  {
    require(bondReserve[_bondAddr] == address(0));
    bondReserve[_bondAddr] = address(
      IBondDepositoryCommon(_bondAddr).reserve()
    );
    bondType[_bondAddr] = _bondType;
    emit AddedBond(_bondAddr, uint256(_bondType));
  }

  /// @notice Remove new bond depository from the router
  /// @param _bondAddr Address of the bond depository
  function removeBond(address _bondAddr)
    public
    override
    onlyOwner
    bondAdded(_bondAddr)
  {
    delete bondReserve[_bondAddr];
    delete bondType[_bondAddr];
    emit RemovedBond(_bondAddr);
  }

  /// @notice Internal function to check that upgrader of contract has UPGRADER_ROLE
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}
}