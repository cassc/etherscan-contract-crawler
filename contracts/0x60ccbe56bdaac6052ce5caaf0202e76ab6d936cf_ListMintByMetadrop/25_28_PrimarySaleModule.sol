// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title PrimarySaleModule.sol. This contract is the base primary sale module contract
 * for the metadrop drop platform. All primary sale modules inherit from this contract
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "./IPrimarySaleModule.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../Global/AuthorityModel.sol";

/**
 *
 * @dev Inheritance details:
 *      IPrimarySaleModule         Interface for this module
 *      Pausable                   Allow modules to be paused
 *      AccessControl              Implement OZ access control for privileged access
 *
 *
 */

contract PrimarySaleModule is IPrimarySaleModule, Pausable, AuthorityModel {
  using Strings for uint256;

  // EPS Register
  IEPSDelegationRegister public immutable epsRegister;
  // Slot 1 - NFT and phase details (pack together for warm slot reads)
  //  160
  //   32
  //   32
  //   32
  //= 256

  uint32 public phaseQuantityMinted;

  INFTByMetadrop public nftContract;

  // Start time for  minting
  uint32 public phaseStart;

  // End time for minting. Note that this can be passed as maxUint32, which is a mint
  // unlimited by time
  uint32 public phaseEnd;

  // The number of NFTs that can be minted in this phase:
  uint32 public phaseMaxSupply;

  // Slot 2 - anti-bot-proection (pack together for warm slot reads)
  //  160
  //    8
  //    8
  //   32
  //= 208

  // The metadrop admin signer used as a trusted oracle (e.g. for anti-bot protection)
  address public metadropOracleAddress;

  // Bool to indicate if we are using the oracle for anti-bot protection
  bool public useOracleToAntiSybil;

  // Bool to indicate if EPS is in use in this drop
  bool public useEPS;

  // The oracle signed message validity period:
  uint80 public messageValidityInSeconds;

  // Slot 3 - not accessed in mints
  //  160
  //   32
  //    8
  //= 200

  // The contract to which all funds route. This is a payment splitting vesting contract
  address public vestingContract;

  // Point at which contract cannot be paused:
  uint32 public pauseCutoffInDays;

  // Bool that controls initialisation and only allows it to occur ONCE. This is
  // needed as this contract is clonable, threfore the constructor is not called
  // on cloned instances. We setup state of this contract through the initialise
  // function.
  bool public initialised;

  /** ====================================================================================================================
   *                                              CONSTRUCTOR AND INTIIALISE
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param epsRegister_        The EPS register address (0x888888888888660F286A7C06cfa3407d09af44B2 on most chains)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  constructor(address epsRegister_) {
    epsRegister = IEPSDelegationRegister(epsRegister_);
    initialised = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialisePrimarySaleModule  Defined here and must be overriden in child contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param initialInstanceOwner_  The owner for this contract. Will be used to set the owner in ERC721M and also the
   *                               platform admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_          The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vesting_               The vesting contract used for sales proceeds from this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param configData_            The drop specific configuration for this module. This is decoded and used to set
   *                               configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutoffInDays_     The maximum number of days after drop deployment that this contract can be paused
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_ The trusted metadrop signer. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_ The validity period of a signed message. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialisePrimarySaleModule(
    address initialInstanceOwner_,
    address projectOwner_,
    address vesting_,
    bytes calldata configData_,
    uint256 pauseCutoffInDays_,
    address metadropOracleAddress_,
    uint80 messageValidityInSeconds_
  ) public virtual {
    // Must be overridden
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) _initialisePrimarySaleModuleBase  Base configuration load that is shared across all primary sale
   *                                                   modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param initialInstanceOwner_  The owner for this contract. Will be used to set the owner in ERC721M and also the
   *                               platform admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_          The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vesting_               The vesting contract used for sales proceeds from this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutoffInDays_     The maximum number of days after drop deployment that this contract can be paused
   * ---------------------------------------------------------------------------------------------------------------------
   * @param start_                 The start date of this primary sale module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param end_                   The end date of this primary sale module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseMaxSupply_        The max supply for this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_ The trusted metadrop signer. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_ The validity period of a signed message. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialisePrimarySaleModuleBase(
    address initialInstanceOwner_,
    address projectOwner_,
    address vesting_,
    uint256 pauseCutoffInDays_,
    uint256 start_,
    uint256 end_,
    uint256 phaseMaxSupply_,
    address metadropOracleAddress_,
    uint80 messageValidityInSeconds_
  ) internal {
    if (initialised) revert AlreadyInitialised();

    _grantRole(PLATFORM_ADMIN, initialInstanceOwner_);
    _grantRole(PROJECT_OWNER, projectOwner_);

    // If the vesting contract is address(0) then the vesting module
    // has been flagged as not required for this drop. This will almost
    // exclusively be in the case of a free drop, where there are no funds
    // to vest or split.
    // To avoid any possible loss of funds from incorrect configuation we don't
    // set the vestingContract to address(0), but rather to the platform admin
    if (vesting_ == address(0)) {
      vestingContract = initialInstanceOwner_;
    } else {
      vestingContract = vesting_;
    }

    pauseCutoffInDays = uint32(pauseCutoffInDays_);

    phaseStart = uint32(start_);
    phaseEnd = uint32(end_);
    phaseMaxSupply = uint32(phaseMaxSupply_);

    metadropOracleAddress = metadropOracleAddress_;
    messageValidityInSeconds = messageValidityInSeconds_;

    useOracleToAntiSybil = true;
    useEPS = true;
    factory = msg.sender;

    initialised = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) setNFTAddress    Set the NFT contract for this drop
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftContract_           The deployed NFT contract
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setNFTAddress(
    address nftContract_
  ) external onlyFactoryOrPlatformAdmin {
    if (nftContract == INFTByMetadrop(address(0))) {
      nftContract = INFTByMetadrop(nftContract_);
    } else {
      revert AddressAlreadySet();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseStart  Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseStart_             The phase start time
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseStart(uint32 phaseStart_) external onlyPlatformAdmin {
    phaseStart = phaseStart_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseEnd    Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseEnd_               The phase end time
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseEnd(uint32 phaseEnd_) external onlyPlatformAdmin {
    phaseEnd = phaseEnd_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseMaxSupply     Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseMaxSupply_                The phase supply
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseMaxSupply(
    uint32 phaseMaxSupply_
  ) external onlyPlatformAdmin {
    phaseMaxSupply = phaseMaxSupply_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) phaseMintStatus    The status of the deployed primary sale module
   * _____________________________________________________________________________________________________________________
   */
  function phaseMintStatus() public view returns (MintStatus status) {
    return _primarySaleStatus(phaseStart, phaseEnd);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) _primarySaleStatus    Return the status of the mint type
   * _____________________________________________________________________________________________________________________
   */
  function _primarySaleStatus(
    uint256 start_,
    uint256 end_
  ) internal view returns (MintStatus) {
    // Explicitly check for open before anything else. This is the only valid path to making a
    // state change, so keep the gas as low as possible for the code path through 'open'
    if (block.timestamp >= (start_) && block.timestamp <= (end_)) {
      return (MintStatus.open);
    }

    if ((start_ + end_) == 0) {
      return (MintStatus.notEnabled);
    }

    if (block.timestamp > end_) {
      return (MintStatus.finished);
    }

    if (block.timestamp < start_) {
      return (MintStatus.notYetOpen);
    }

    return (MintStatus.unknown);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _mint         Called from all primary sale modules: perform minting!
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The number of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The per NFT price for this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageTimeStamp_      The timestamp of the signed message
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageHash_           The message hash signed by the trusted oracle signer. This will be the keccack256 hash
   *                               of received data about this social mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageSignature_      The signed message from the backend oracle signer for validation.
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _mint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    uint256 messageTimeStamp_,
    bytes32 messageHash_,
    bytes calldata messageSignature_
  ) internal whenNotPaused {
    if (phaseMintStatus() != MintStatus.open) revert ThisMintIsClosed();

    if (
      phaseMaxSupply != 0 &&
      quantityToMint_ > (phaseMaxSupply - phaseQuantityMinted)
    ) {
      revert QuantityExceedsPhaseRemainingSupply(
        quantityToMint_,
        phaseMaxSupply - phaseQuantityMinted
      );
    }

    phaseQuantityMinted += uint32(quantityToMint_);

    if (useOracleToAntiSybil) {
      // Check that this signature is from the oracle signer:
      if (!_validSignature(messageHash_, messageSignature_)) {
        revert InvalidOracleSignature();
      }

      // Check that the signature has not expired:
      if ((messageTimeStamp_ + messageValidityInSeconds) < block.timestamp) {
        revert OracleSignatureHasExpired();
      }

      // Signature is valid. Check that the passed parameters match the hash that was signed:
      if (
        !_parametersMatchHash(
          recipient_,
          quantityToMint_,
          msg.sender,
          messageTimeStamp_,
          messageHash_
        )
      ) {
        revert ParametersDoNotMatchSignedMessage();
      }
    }
    nftContract.metadropMint(
      caller_,
      recipient_,
      allowanceAddress_,
      quantityToMint_,
      unitPrice_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _validSignature         Checks the the signature on the signed message is from the metadrop oracle
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageHash_           The message hash signed by the trusted oracle signer. This will be the keccack256 hash
   *                               of received data about this social mint
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageSignature_      The signed message from the backend oracle signer for validation.
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _validSignature(
    bytes32 messageHash_,
    bytes memory messageSignature_
  ) internal view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash_)
    );

    // Check the signature is valid:
    return (
      SignatureChecker.isValidSignatureNow(
        metadropOracleAddress,
        ethSignedMessageHash,
        messageSignature_
      )
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _parametersMatchHash      Checks the the signature on the signed message is from the metadrop oracle
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The number of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The msg.sender on this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageTimeStamp_      The timestamp on the message
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageHash_           The message hash signed by the trusted oracle signer. This will be the keccack256 hash
   *                               of received data about this social mint
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _parametersMatchHash(
    address recipient_,
    uint256 quantityToMint_,
    address caller_,
    uint256 messageTimeStamp_,
    bytes32 messageHash_
  ) internal pure returns (bool) {
    return (
      (keccak256(
        abi.encodePacked(
          recipient_,
          quantityToMint_,
          caller_,
          messageTimeStamp_
        )
      ) == messageHash_)
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH      A withdraw function to allow ETH to be withdrawn to the vesting contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_             The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external onlyPlatformAdmin {
    (bool success, ) = vestingContract.call{value: amount_}("");
    if (!success) revert TransferFailed();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawContractETHBalance      A withdraw function to allow  all ETH to be withdrawn to vesting.
   * _____________________________________________________________________________________________________________________
   */
  function withdrawContractETHBalance() external onlyPlatformAdmin {
    (bool success, ) = vestingContract.call{value: address(this).balance}("");
    if (!success) revert TransferFailed();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20     A withdraw function to allow ERC20s to be withdrawn to the vesting contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_             The token to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_             The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(
    IERC20 token_,
    uint256 amount_
  ) external onlyPlatformAdmin {
    bool success = token_.transfer(vestingContract, amount_);
    if (!success) revert TransferFailed();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ACCESS
   * @dev (function) transferProjectOwner    Allows the current project owner to transfer this role to another address,
   * therefore being the equivalent of 'transfer owner'
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newProjectOwner_         The new project owner address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferProjectOwner(
    address newProjectOwner_
  ) external onlyProjectOwner {
    grantRole(PROJECT_OWNER, newProjectOwner_);
    revokeRole(PROJECT_OWNER, msg.sender);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ACCESS
   * @dev (function) transferPlatformAdmin    Allows the current platform admin to transfer this role to another address,
   * therefore being the equivalent of 'transfer owner'
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPlatformAdmin_         The new platform admin address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferPlatformAdmin(
    address newPlatformAdmin_
  ) external onlyPlatformAdmin {
    grantRole(PLATFORM_ADMIN, newPlatformAdmin_);
    revokeRole(PLATFORM_ADMIN, msg.sender);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setMetadropOracleAddress   Allow platform admin to update trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_         The new metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(
    address metadropOracleAddress_
  ) external onlyPlatformAdmin {
    if (metadropOracleAddress_ == address(0)) {
      revert CannotSetToZeroAddress();
    }
    metadropOracleAddress = metadropOracleAddress_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setVestingContractAddress     Allow platform admin to update vesting contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingContract_         The new vesting contract address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVestingContractAddress(
    address vestingContract_
  ) external onlyPlatformAdmin {
    if (vestingContract_ == address(0)) {
      revert CannotSetToZeroAddress();
    }
    vestingContract = vestingContract_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn off anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOff() external onlyPlatformAdmin {
    useOracleToAntiSybil = false;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn ON anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOn() external onlyPlatformAdmin {
    useOracleToAntiSybil = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn off EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOff() external onlyPlatformAdmin {
    useEPS = false;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn ON EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOn() external onlyPlatformAdmin {
    useEPS = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) pause    Allow platform admin to pause
   * _____________________________________________________________________________________________________________________
   */
  function pause() external onlyPlatformAdmin {
    _pause();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) unpause    Allow platform admin to unpause
   * _____________________________________________________________________________________________________________________
   */
  function unpause() external onlyPlatformAdmin {
    _unpause();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) receive   Reject eth of unkown source
   * _____________________________________________________________________________________________________________________
   */
  receive() external payable {
    if (!hasRole(PLATFORM_ADMIN, msg.sender)) {
      revert CallerIsNotPlatformAdmin(msg.sender);
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) fallback   Revert all fall backs
   * _____________________________________________________________________________________________________________________
   */
  fallback() external {
    revert();
  }
}