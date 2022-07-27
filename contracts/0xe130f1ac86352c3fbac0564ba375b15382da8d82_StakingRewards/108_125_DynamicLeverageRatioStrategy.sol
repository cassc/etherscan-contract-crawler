// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";
import "./LeverageRatioStrategy.sol";
import "../../interfaces/ISeniorPoolStrategy.sol";
import "../../interfaces/ISeniorPool.sol";
import "../../interfaces/ITranchedPool.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

contract DynamicLeverageRatioStrategy is LeverageRatioStrategy {
  bytes32 public constant LEVERAGE_RATIO_SETTER_ROLE = keccak256("LEVERAGE_RATIO_SETTER_ROLE");

  struct LeverageRatioInfo {
    uint256 leverageRatio;
    uint256 juniorTrancheLockedUntil;
  }

  // tranchedPoolAddress => leverageRatioInfo
  mapping(address => LeverageRatioInfo) public ratios;

  event LeverageRatioUpdated(
    address indexed pool,
    uint256 leverageRatio,
    uint256 juniorTrancheLockedUntil,
    bytes32 version
  );

  function initialize(address owner) public initializer {
    require(owner != address(0), "Owner address cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    _setupRole(LEVERAGE_RATIO_SETTER_ROLE, owner);

    _setRoleAdmin(LEVERAGE_RATIO_SETTER_ROLE, OWNER_ROLE);
  }

  function getLeverageRatio(ITranchedPool pool) public view override returns (uint256) {
    LeverageRatioInfo memory ratioInfo = ratios[address(pool)];
    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Junior));
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Senior));

    require(ratioInfo.juniorTrancheLockedUntil > 0, "Leverage ratio has not been set yet.");
    if (seniorTranche.lockedUntil > 0) {
      // The senior tranche is locked. Coherence check: we expect locking the senior tranche to have
      // updated `juniorTranche.lockedUntil` (compared to its value when `setLeverageRatio()` was last
      // called successfully).
      require(
        ratioInfo.juniorTrancheLockedUntil < juniorTranche.lockedUntil,
        "Expected junior tranche `lockedUntil` to have been updated."
      );
    } else {
      require(
        ratioInfo.juniorTrancheLockedUntil == juniorTranche.lockedUntil,
        "Leverage ratio is obsolete. Wait for its recalculation."
      );
    }

    return ratioInfo.leverageRatio;
  }

  /**
   * @notice Updates the leverage ratio for the specified tranched pool. The combination of the
   * `juniorTranchedLockedUntil` param and the `version` param in the event emitted by this
   * function are intended to enable an outside observer to verify the computation of the leverage
   * ratio set by calls of this function.
   * @param pool The tranched pool whose leverage ratio to update.
   * @param leverageRatio The leverage ratio value to set for the tranched pool.
   * @param juniorTrancheLockedUntil The `lockedUntil` timestamp, of the tranched pool's
   * junior tranche, to which this calculation of `leverageRatio` corresponds, i.e. the
   * value of the `lockedUntil` timestamp of the JuniorCapitalLocked event which the caller
   * is calling this function in response to having observed. By providing this timestamp
   * (plus an assumption that we can trust the caller to report this value accurately),
   * the caller enables this function to enforce that a leverage ratio that is obsolete in
   * the sense of having been calculated for an obsolete `lockedUntil` timestamp cannot be set.
   * @param version An arbitrary identifier included in the LeverageRatioUpdated event emitted
   * by this function, enabling the caller to describe how it calculated `leverageRatio`. Using
   * the bytes32 type accommodates using git commit hashes (both the current SHA1 hashes, which
   * require 20 bytes; and the future SHA256 hashes, which require 32 bytes) for this value.
   */
  function setLeverageRatio(
    ITranchedPool pool,
    uint256 leverageRatio,
    uint256 juniorTrancheLockedUntil,
    bytes32 version
  ) public onlySetterRole {
    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Junior));
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(uint256(ITranchedPool.Tranches.Senior));

    // NOTE: We allow a `leverageRatio` of 0.
    require(
      leverageRatio <= 10 * LEVERAGE_RATIO_DECIMALS,
      "Leverage ratio must not exceed 10 (adjusted for decimals)."
    );

    require(juniorTranche.lockedUntil > 0, "Cannot set leverage ratio if junior tranche is not locked.");
    require(seniorTranche.lockedUntil == 0, "Cannot set leverage ratio if senior tranche is locked.");
    require(juniorTrancheLockedUntil == juniorTranche.lockedUntil, "Invalid `juniorTrancheLockedUntil` timestamp.");

    ratios[address(pool)] = LeverageRatioInfo({
      leverageRatio: leverageRatio,
      juniorTrancheLockedUntil: juniorTrancheLockedUntil
    });

    emit LeverageRatioUpdated(address(pool), leverageRatio, juniorTrancheLockedUntil, version);
  }

  modifier onlySetterRole() {
    require(
      hasRole(LEVERAGE_RATIO_SETTER_ROLE, _msgSender()),
      "Must have leverage-ratio setter role to perform this action"
    );
    _;
  }
}