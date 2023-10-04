/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */

pragma solidity 0.8.16;

import "contracts/interfaces/IWommf.sol";
import "contracts/kyc/KYCRegistryClient.sol";
import "contracts/RWAHubInstantMints.sol";

contract OMMFManager is RWAHubInstantMints, KYCRegistryClient {
  /// @notice `rwa` variable is OMMF token contract
  IWOMMF public immutable wommf;
  bytes32 public constant REDEMPTION_PROVER_ROLE =
    keccak256("REDEMPTION_PROVER_ROLE");

  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount,
    address _instantMintAssetManager,
    address _kycRegistry,
    uint256 _kycRequirementGroup,
    address _wommf
  )
    RWAHubInstantMints(
      _collateral,
      _rwa,
      managerAdmin,
      pauser,
      _assetSender,
      _feeRecipient,
      _minimumDepositAmount,
      _minimumRedemptionAmount,
      _instantMintAssetManager
    )
  {
    _setKYCRegistry(_kycRegistry);
    _setKYCRequirementGroup(_kycRequirementGroup);
    wommf = IWOMMF(_wommf);
    _setRoleAdmin(REDEMPTION_PROVER_ROLE, MANAGER_ADMIN);
  }

  /**
   * @notice Function to add a redemption proof to the contract
   *
   * @param txHash           The tx hash (redemption Id) of the redemption
   * @param user             The address of the user who made the redemption
   * @param rwaAmountToBurn  The amount of OMMF burned
   * @param timestamp        The timestamp of the redemption request
   */
  function addRedemptionProof(
    bytes32 txHash,
    address user,
    uint256 rwaAmountToBurn,
    uint256 timestamp
  ) external onlyRole(REDEMPTION_PROVER_ROLE) checkRestrictions(user) {
    if (redemptionIdToRedeemer[txHash].user != address(0)) {
      revert RedemptionProofAlreadyExists();
    }
    if (rwaAmountToBurn == 0) {
      revert RedemptionTooSmall();
    }
    if (user == address(0)) {
      revert RedeemerNull();
    }
    rwa.burnFrom(msg.sender, rwaAmountToBurn);
    redemptionIdToRedeemer[txHash] = Redeemer(user, rwaAmountToBurn, 0);

    emit RedemptionProofAdded(txHash, user, rwaAmountToBurn, timestamp);
  }

  /**
   * @notice Function to claim a subscription request in wrapped rwa
   *         token
   *
   * @param depositIds The depositIds to be claimed
   */
  function claimMint_wOMMF(
    bytes32[] memory depositIds
  ) external nonReentrant ifNotPaused(subscriptionPaused) {
    uint256 cacheLength = depositIds.length;
    for (uint256 i; i < cacheLength; ++i) {
      // Get depositor
      Depositor memory depositor = depositIdToDepositor[depositIds[i]];

      // Check if the depositor is valid
      if (depositor.priceId == 0) {
        revert PriceIdNotSet();
      }

      // Get price and rwaOwed based on priceId
      uint256 price = pricer.getPrice(depositor.priceId);
      uint256 rwaOwed = _getMintAmountForPrice(
        depositor.amountDepositedMinusFees,
        price
      );

      // Clean up storage and mint
      delete depositIdToDepositor[depositIds[i]];
      rwa.mint(address(this), rwaOwed);

      // Wrap and transfer wOMMF
      rwa.approve(address(wommf), rwaOwed);
      wommf.wrap(rwaOwed);
      uint256 wRwaOwed = wommf.getwOMMFByOMMF(rwaOwed);
      wommf.transfer(depositor.user, wRwaOwed);

      emit WrappedMintCompleted(
        depositor.user,
        depositIds[i],
        rwaOwed,
        wRwaOwed,
        depositor.amountDepositedMinusFees,
        price
      );
    }
  }

  /**
   * @notice Function to request a redemption in instances when the user would
   *         like to burn the wrapped rwa token
   *
   * @param amount The amount of wrapped rwa that the user would like to burn
   */
  function requestRedemption_wOMMF(
    uint256 amount
  ) external nonReentrant ifNotPaused(redemptionPaused) {
    uint256 ommfAmount = wommf.getOMMFbywOMMF(amount);
    if (ommfAmount < minimumRedemptionAmount) {
      revert RedemptionTooSmall();
    }

    // Transfer and unwrap
    wommf.transferFrom(msg.sender, address(this), amount);
    wommf.unwrap(amount);

    bytes32 redemptionId = bytes32(redemptionRequestCounter++);
    redemptionIdToRedeemer[redemptionId] = Redeemer(msg.sender, amount, 0);

    rwa.burn(ommfAmount);

    emit WrappedRedemptionRequested(
      msg.sender,
      redemptionId,
      ommfAmount,
      amount
    );
  }

  /**
   * @notice Function to enforce KYC/AML requirements that will
   *         be implemented on calls to `requestSubscription` and
   *         `claimRedemption`
   *
   * @param account The account that we would like to check the KYC
   *                status for
   */
  function _checkRestrictions(address account) internal view override {
    // Check Basic KYC requirements for OMMF
    if (!_getKYCStatus(account)) {
      revert KYCCheckFailed();
    }
  }

  /*//////////////////////////////////////////////////////////////
                        KYC Registry Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Update KYC group of the contract for which
   *         accounts are checked against
   *
   * @param _kycRequirementGroup The new KYC requirement group
   */
  function setKYCRequirementGroup(
    uint256 _kycRequirementGroup
  ) external onlyRole(MANAGER_ADMIN) {
    _setKYCRequirementGroup(_kycRequirementGroup);
  }

  /**
   * @notice Update KYC registry address
   *
   * @param _kycRegistry The new KYC registry address
   */
  function setKYCRegistry(
    address _kycRegistry
  ) external onlyRole(MANAGER_ADMIN) {
    _setKYCRegistry(_kycRegistry);
  }

  /**
   * @notice Event emitted when a Mint request is completed
   *
   * @param user                      The address of the user getting the funds
   * @param depositId                 The deposit Id for the subscription request
   * @param rwaAmountOut              The amount of RWA token minted to the
   *                                  user
   * @param wRWAAmountOut             The amount of wrapped RWA token minted
   * @param collateralAmountDeposited The amount of collateral deposited
   * @param price                     The price set for the depositId
   */
  event WrappedMintCompleted(
    address indexed user,
    bytes32 indexed depositId,
    uint256 rwaAmountOut,
    uint256 wRWAAmountOut,
    uint256 collateralAmountDeposited,
    uint256 price
  );

  /**
   * @notice Event emitted when a Redemption request is completed
   *
   * @param user               The address of the user
   * @param redemptionId       The redemption Id for a given redemption
   *                           request
   * @param rwaAmountIn        The amount of rwa being redeemed
   * @param wrappedRwaAmountIn The amount of wrapped rwa to convert to rwa
   */
  event WrappedRedemptionRequested(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaAmountIn,
    uint256 wrappedRwaAmountIn
  );

  /**
   * @notice Event emitted when redemption proof has been added
   *
   * @param txHash                Tx hash (redemption id) of the redemption transfer
   * @param user                  Address of the user who made the redemption
   * @param rwaAmountBurned       Amount of OMMF burned
   * @param timestamp             Timestamp of the redemption
   */
  event RedemptionProofAdded(
    bytes32 indexed txHash,
    address indexed user,
    uint256 rwaAmountBurned,
    uint256 timestamp
  );

  error KYCCheckFailed();
}