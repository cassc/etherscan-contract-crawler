// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BaseBondDepository.sol";

import "./interfaces/ITreasuryBondDepository.sol";
import "./interfaces/IBondGovernor.sol";
import "./interfaces/ITreasury.sol";

/// @title TreasuryBondDepository
/// @author Bluejay Core Team
/// @notice TreasuryBondDepository allows the protocol to raise funds into the Treasury by selling bonds.
/// These bonds allow users to claim governance token vested over a period of time.
/// The bonds are priced based on outstanding debt ratio and a bond control variable.
/// @dev This contract is only suitable for assets with 18 decimals.
contract TreasuryBondDepository is
  Ownable,
  BaseBondDepository,
  ITreasuryBondDepository
{
  using SafeERC20 for IERC20;

  uint256 private constant WAD = 10**18;
  uint256 private constant RAY = 10**27;
  uint256 private constant RAD = 10**45;

  /// @notice Contract address of the BLU Token
  IERC20 public immutable BLU;

  /// @notice Contract address of the asset used to pay for the bonds
  IERC20 public immutable override reserve;

  /// @notice Contract address of the Treasury where the reserve assets are sent and BLU minted
  ITreasury public immutable treasury;

  /// @notice Vesting period of bonds, in seconds
  uint256 public immutable vestingPeriod;

  /// @notice Contract address of the BondGovernor where bond parameters are defined
  IBondGovernor public bondGovernor;

  /// @notice Address where fees collected from bond sales are sent
  address public feeCollector;

  /// @notice Flag to pause purchase of bonds
  bool public isPurchasePaused;

  /// @notice Flag to pause redemption of bonds
  bool public isRedeemPaused;

  /// @notice Governance token debt outstanding, decaying over the vesting period, in WAD
  uint256 public totalDebt;

  /// @notice Timestamp of last debt decay, in unix timestamp
  uint256 public lastDecay;

  /// @notice Constructor to initialize the contract
  /// @dev Bond parameters should be initialized in the bond governor.
  /// @param _bondGovernor Address of bond governor which defines bond parameters
  /// @param _reserve Address of the asset accepted for payment of the bonds
  /// @param _BLU Address of the BLU token
  /// @param _treasury Address of the Treasury for minting BLU tokens and storing proceeds
  /// @param _feeCollector Address to send fees collected from bond sales
  /// @param _vestingPeriod Vesting period of bonds, in seconds
  constructor(
    address _bondGovernor,
    address _reserve,
    address _BLU,
    address _treasury,
    address _feeCollector,
    uint256 _vestingPeriod
  ) {
    bondGovernor = IBondGovernor(_bondGovernor);
    reserve = IERC20(_reserve);
    BLU = IERC20(_BLU);
    treasury = ITreasury(_treasury);
    feeCollector = _feeCollector;
    vestingPeriod = _vestingPeriod;
    isPurchasePaused = true;
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Decrease total debt by removing amount of debt decayed during the period elapsed
  function _decayDebt() internal {
    totalDebt = totalDebt - debtDecay();
    lastDecay = block.timestamp;
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Purchase treasury bond paid with reserve assets
  /// @dev Approval of reserve asset to this address is required
  /// @param amount Amount of reserve asset to spend, in WAD
  /// @param maxPrice Maximum price to pay for the bond to prevent slippages, in WAD
  /// @param recipient Address to issue the bond to
  /// @return bondId ID of bond that was issued
  function purchase(
    uint256 amount,
    uint256 maxPrice,
    address recipient
  ) public override returns (uint256 bondId) {
    require(!isPurchasePaused, "Purchase paused");
    (
      uint256 controlVariable,
      uint256 minimumPrice,
      uint256 minimumSize,
      uint256 maximumSize,
      uint256 fees
    ) = bondGovernor.getPolicy(address(reserve));
    require(recipient != address(0), "Invalid address");

    _decayDebt();

    uint256 price = calculateBondPrice(
      controlVariable,
      minimumPrice,
      debtRatio()
    );
    require(price <= maxPrice, "Price too high");

    uint256 payout = (amount * WAD) / price;
    require(payout >= minimumSize, "Bond size too small");
    require(payout <= maximumSize, "Bond size too big");

    uint256 feeCollected = (amount * fees) / price;
    reserve.safeTransferFrom(msg.sender, address(treasury), amount);
    treasury.mint(address(this), payout + feeCollected);

    if (feeCollected > 0) {
      BLU.safeTransfer(feeCollector, feeCollected);
    }

    bondId = _mint(recipient, payout, vestingPeriod);
    totalDebt += payout;

    emit BondPurchased(bondId, recipient, amount, payout, price);
  }

  /// @notice Redeem BLU tokens from previously purchased bond.
  /// BLU is linearly vested over the vesting period and user can redeem vested tokens at any time.
  /// @dev Bond will be deleted after the bond is fully vested and redeemed
  /// @param bondId ID of bond to redeem, caller must the bond owner
  /// @param recipient Address to send vested BLU tokens to
  /// @return payout Amount of BLU tokens sent to recipient, in WAD
  /// @return principal Amount of BLU tokens left to be vested on the bond, in WAD
  function redeem(uint256 bondId, address recipient)
    public
    override
    returns (uint256 payout, uint256 principal)
  {
    require(!isRedeemPaused, "Redeem paused");
    require(bondOwners[bondId] == msg.sender, "Not bond owner");
    Bond memory bond = bonds[bondId];
    if (bond.lastRedeemed + bond.vestingPeriod <= block.timestamp) {
      _burn(bondId);
      payout = bond.principal;
      BLU.safeTransfer(recipient, bond.principal);
      emit BondRedeemed(bondId, recipient, true, payout, 0);
    } else {
      payout =
        (bond.principal * (block.timestamp - bond.lastRedeemed)) /
        bond.vestingPeriod;
      principal = bond.principal - payout;
      bonds[bondId] = Bond({
        principal: principal,
        vestingPeriod: bond.vestingPeriod -
          (block.timestamp - bond.lastRedeemed),
        purchased: bond.purchased,
        lastRedeemed: block.timestamp
      });
      BLU.safeTransfer(recipient, payout);
      emit BondRedeemed(bondId, recipient, false, payout, principal);
    }
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Set the address where fees are sent to
  /// @param _feeCollector Address of fee collector
  function setFeeCollector(address _feeCollector) public override onlyOwner {
    feeCollector = _feeCollector;
    emit UpdatedFeeCollector(_feeCollector);
  }

  /// @notice Pause or unpause redemption of bonds
  /// @param pause True to pause redemption, false to unpause redemption
  function setIsRedeemPaused(bool pause) public override onlyOwner {
    isRedeemPaused = pause;
    emit RedeemPaused(pause);
  }

  /// @notice Pause or unpause purchase of bonds
  /// @param pause True to pause purchase, false to unpause purchase
  function setIsPurchasePaused(bool pause) public override onlyOwner {
    isPurchasePaused = pause;
    emit PurchasePaused(pause);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Calculate current debt after debt decay
  /// @return debt Amount of current debt, in WAD
  function currentDebt() public view override returns (uint256 debt) {
    debt = totalDebt - debtDecay();
  }

  /// @notice Calculate amount of debt decayed during the period elapsed
  /// @return decay Amount of debt to decay by, in WAD
  function debtDecay() public view override returns (uint256 decay) {
    uint256 timeSinceLast = block.timestamp - lastDecay;
    decay = (totalDebt * timeSinceLast) / vestingPeriod;
    if (decay > totalDebt) {
      decay = totalDebt;
    }
  }

  /// @notice Calculate ratio of debt against the total supply of BLU tokens
  /// @return ratio Debt ratio, in WAD
  function debtRatio() public view override returns (uint256 ratio) {
    ratio = (currentDebt() * WAD) / BLU.totalSupply();
  }

  /// @notice Calculate current price of bond
  /// @return price Price of bond, in WAD
  function bondPrice() public view override returns (uint256 price) {
    (uint256 controlVariable, uint256 minimumPrice, , , ) = bondGovernor
      .getPolicy(address(reserve));
    return calculateBondPrice(controlVariable, minimumPrice, debtRatio());
  }

  /// @notice Calculate price of bond using the control variable, debt ratio and min price
  /// @param controlVariable Control variable of bond, in RAY
  /// @param minimumPrice Minimum price of bond, in WAD
  /// @param ratio Debt ratio, in WAD
  /// @return price Price of bond, in WAD
  function calculateBondPrice(
    uint256 controlVariable,
    uint256 minimumPrice,
    uint256 ratio
  ) public pure override returns (uint256 price) {
    price = (controlVariable * ratio + RAD) / RAY;
    if (price < minimumPrice) {
      price = minimumPrice;
    }
  }
}