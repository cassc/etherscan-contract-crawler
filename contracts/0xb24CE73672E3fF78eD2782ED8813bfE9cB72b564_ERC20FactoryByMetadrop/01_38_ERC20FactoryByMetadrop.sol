// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import {AuthorityModel} from "../../Global/AuthorityModel.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Decommissionable} from "../../Global/Decommissionable.sol";
import {IERC20ByMetadrop} from "../ERC20/IERC20ByMetadrop.sol";
import {IERC20DRIPool} from "../ERC20Pools/IERC20DRIPool.sol";
import {IERC20FactoryByMetadrop} from "./IERC20FactoryByMetadrop.sol";
import {IERC20MachineByMetadrop} from "../ERC20Machine/IERC20MachineByMetadrop.sol";
import {SafeERC20, IERC20} from "../../Global/OZ/SafeERC20.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @dev Metadrop ERC-20 factory
 */
contract ERC20FactoryByMetadrop is
  Context,
  Decommissionable,
  IERC20FactoryByMetadrop,
  AuthorityModel
{
  using SafeERC20 for IERC20;
  using Clones for address payable;

  // Uniswap router address
  address public immutable uniswapRouter;
  // Unicrypt locker address
  address public immutable unicryptLocker;
  // DRIPool template:
  address payable public immutable driPooltemplate;

  // Metadrop trusted oracle address
  address public metadropOracleAddress;
  // Address for all platform fee payments
  address public platformTreasury;
  // The oracle signed message validity period:
  // Note that maximum is 65,535, therefore 18.2 hours (which seems plenty)
  uint16 private messageValidityInSeconds = 30 minutes;

  /**
   * @dev {constructor}
   *
   * @param superAdmin_ The address that can add and remove user authority roles. Will also be added as the
   * first platform admin.
   * @param platformAdmins_ The address(es) for the platform admin(s)
   * @param platformTreasury_ The address of the platform treasury. This will be used on primary vesting
   * for the platform share of funds and on the royalty payment splitter for the platform share.
   * @param metadropOracleAddress_ The address of the metadrop oracle signer
   * @param uniswapRouter_ The address of the uniswap router
   * @param unicryptLocker_ The address of the unicrypt locker
   * @param driPooltemplate_ The address of the launch pool template
   */
  constructor(
    address superAdmin_,
    address[] memory platformAdmins_,
    address platformTreasury_,
    address metadropOracleAddress_,
    address uniswapRouter_,
    address unicryptLocker_,
    address driPooltemplate_
  ) {
    // The initial instance owner is set as the Ownable owner on all cloned contracts:
    if (superAdmin_ == address(0)) {
      _revert(SuperAdminCannotBeAddressZero.selector);
    }

    // superAdmin can grant and revoke all other roles. This address MUST be secured.
    // For the duration of this constructor only the super admin is the deployer.
    // This is so the deployer can set initial authorities.
    // We set to the configured super admin address at the end of the constructor.
    superAdmin = _msgSender();
    // Grant platform admin to the deployer for the duration of the constructor:
    grantPlatformAdmin(_msgSender());
    // By default we will revoke the temporary authority for the deployer, BUT,
    // if the deployer is in the platform admin array then we want to keep that
    // authority, as it has been explicitly set. We handle that situation using
    // a bool:
    bool revokeDeployerPlatformAdmin = true;

    grantPlatformAdmin(superAdmin_);

    for (uint256 i = 0; i < platformAdmins_.length; ) {
      // Check if the address we are granting for is the deployer. If it is,
      // then the deployer address already IS a platform admin and it would be
      // a waste of gas to grant again. Instead, we update the bool to show that
      // we DON'T want to revoke this permission at the end of this method:
      if (platformAdmins_[i] == _msgSender()) {
        revokeDeployerPlatformAdmin = false;
      } else {
        grantPlatformAdmin(platformAdmins_[i]);
      }
      unchecked {
        i++;
      }
    }

    // Set platform treasury:
    if (platformTreasury_ == address(0)) {
      _revert(PlatformTreasuryCannotBeAddressZero.selector);
    }
    platformTreasury = platformTreasury_;

    if (metadropOracleAddress_ == address(0)) {
      _revert(MetadropOracleCannotBeAddressZero.selector);
    }
    metadropOracleAddress = metadropOracleAddress_;

    uniswapRouter = uniswapRouter_;

    unicryptLocker = unicryptLocker_;

    driPooltemplate = payable(driPooltemplate_);

    // This is the factory
    factory = address(this);

    // Revoke platform admin status of the deployer and transfer superAdmin
    // and ownable owner to the superAdmin_.
    // Revoke platform admin based on the bool flag set earlier (see above
    // for an explanation of how this flag is set)
    if (revokeDeployerPlatformAdmin) {
      revokePlatformAdmin(_msgSender());
    }
    if (superAdmin_ != _msgSender()) {
      transferSuperAdmin(superAdmin_);
    }
  }

  /**
   * @dev function {decommissionFactory} onlySuperAdmin
   *
   * Make this factory unusable for creating new ERC20s, forever
   *
   */
  function decommissionFactory() external onlySuperAdmin {
    _decommission();
  }

  /**
   * @dev function {setMetadropOracleAddress} onlyPlatformAdmin
   *
   * Set the metadrop trusted oracle address
   *
   * @param metadropOracleAddress_ Trusted metadrop oracle address
   */
  function setMetadropOracleAddress(
    address metadropOracleAddress_
  ) external onlyPlatformAdmin {
    if (metadropOracleAddress_ == address(0)) {
      _revert(MetadropOracleCannotBeAddressZero.selector);
    }
    metadropOracleAddress = metadropOracleAddress_;
  }

  /**
   * @dev function {setMessageValidityInSeconds} onlyPlatformAdmin
   *
   * Set the validity period of signed messages
   *
   * @param messageValidityInSeconds_ Validity period in seconds for messages signed by the trusted oracle
   */
  function setMessageValidityInSeconds(
    uint256 messageValidityInSeconds_
  ) external onlyPlatformAdmin {
    messageValidityInSeconds = uint16(messageValidityInSeconds_);
  }

  /**
   * @dev function {setPlatformTreasury} onlySuperAdmin
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the super
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * @param platformTreasury_ New treasury address
   */
  function setPlatformTreasury(
    address platformTreasury_
  ) external onlySuperAdmin {
    if (platformTreasury_ == address(0)) {
      _revert(PlatformTreasuryCannotBeAddressZero.selector);
    }
    platformTreasury = platformTreasury_;
  }

  /**
   * @dev function {withdrawETH} onlyPlatformAdmin
   *
   * A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * @param amount_ The amount to withdraw
   */
  function withdrawETH(uint256 amount_) external onlyPlatformAdmin {
    (bool success, ) = platformTreasury.call{value: amount_}("");
    if (!success) {
      _revert(TransferFailed.selector);
    }
  }

  /**
   * @dev function {withdrawERC20} onlyPlatformAdmin
   *
   * A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * @param token_ The contract address of the token being withdrawn
   * @param amount_ The amount to withdraw
   */
  function withdrawERC20(
    IERC20 token_,
    uint256 amount_
  ) external onlyPlatformAdmin {
    token_.safeTransfer(platformTreasury, amount_);
  }

  /**
   * @dev function {createERC20}
   *
   * Create an ERC-20
   *
   * @param metaId_ The drop Id being approved
   * @param salt_ Salt for create2
   * @param erc20Config_ ERC20 configuration
   * @param signedMessage_ The signed message object
   * @param lockerFee_ The fee for the unicrypt locker
   * @param deploymentFee_ The fee for deployment, if any
   * @param machine_ The address of the instantiator machine
   * @return deployedAddress_ The deployed ERC20 contract address
   */
  function createERC20(
    string calldata metaId_,
    bytes32 salt_,
    ERC20Config calldata erc20Config_,
    SignedDropMessageDetails calldata signedMessage_,
    uint256 lockerFee_,
    uint256 deploymentFee_,
    address machine_
  ) external payable notWhenDecommissioned returns (address deployedAddress_) {
    // Check the signed message origin and time:
    _verifyMessage(signedMessage_);

    // We can only proceed if the hash of the passed configuration matches the hash
    // signed by our oracle signer:
    _checkConfigHashMatches(
      metaId_,
      salt_,
      erc20Config_,
      signedMessage_,
      lockerFee_,
      deploymentFee_
    );

    // Decode required base parameters:
    (
      string[2] memory tokenDetails,
      bool addLiquidityOnCreate,
      bool usesDRIPool
    ) = _decodeBaseData(erc20Config_.baseParameters);

    address driPool = _processDRIPool(
      usesDRIPool,
      erc20Config_.poolParameters,
      tokenDetails
    );

    // Deploy the new contract:
    address newERC20 = _deployERC20Contract(
      salt_,
      erc20Config_,
      IERC20MachineByMetadrop(machine_),
      driPool
    );

    // Process liquidity operations (if any):
    _processLiquidity(
      addLiquidityOnCreate,
      lockerFee_,
      deploymentFee_,
      newERC20,
      driPool
    );

    // Emit details of the new ERC20:
    _emitOnCreation(metaId_, newERC20, driPool, tokenDetails);

    // Return the address of the new contract up the call stack:
    return (newERC20);
  }

  /**
   * @dev function {_emitOnCreation} Emit the creation event
   *
   * @param metaId_ The string ID for this ERC-20 deployment
   * @param newERC20_ Address of the new ERC-20
   * @param driPool_ Address of the pool (if any)
   * @param tokenDetails_ The name [0] and symbol [1] of this token
   */
  function _emitOnCreation(
    string memory metaId_,
    address newERC20_,
    address driPool_,
    string[2] memory tokenDetails_
  ) internal {
    emit ERC20Created(
      metaId_,
      _msgSender(),
      newERC20_,
      driPool_,
      tokenDetails_[0],
      tokenDetails_[1]
    );
  }

  /**
   * @dev function {_processDRIPool} Process DRIPool creation, if applicable.
   *
   * @param usesDRIPool_ Are we using a DRIPool?
   * @param poolParameters_ Pool parameters in bytes.
   * @param tokenDetails_ Name and symbol of the token.
   * @return driPoolAddress_ address of the launch pool
   */
  function _processDRIPool(
    bool usesDRIPool_,
    bytes calldata poolParameters_,
    string[2] memory tokenDetails_
  ) internal returns (address driPoolAddress_) {
    if (usesDRIPool_) {
      // Create a minimal proxy DRIPool:
      driPoolAddress_ = driPooltemplate.clone();
      // Initialise it:
      IERC20DRIPool(driPoolAddress_).initialiseDRIP(
        poolParameters_,
        tokenDetails_[0],
        tokenDetails_[1]
      );
    } else {
      driPoolAddress_ = address(0);
    }
    return (driPoolAddress_);
  }

  /**
   * @dev function {_processLiquidity} Process liquidity, if relevant.
   *
   * @param addLiquidityOnCreate_ If we are adding liquidity now
   * @param lockerFee_ The fee for the unicrypt locker
   * @param deploymentFee_ The fee for deployment, if any
   * @param newERC20_ The address of the new ERC20
   * @param driPool_ The address of the launch pool

   */
  function _processLiquidity(
    bool addLiquidityOnCreate_,
    uint256 lockerFee_,
    uint256 deploymentFee_,
    address newERC20_,
    address driPool_
  ) internal {
    if (addLiquidityOnCreate_) {
      // Check the fee, we must have enough ETH for the fees, plus at least ONE wei if adding liquidity:
      if (msg.value < (lockerFee_ + deploymentFee_)) {
        _revert(IncorrectPayment.selector);
      }

      // Value to pass on (for locking fee plus liquidity, if any) is the sent
      // amount minus the deployment fee (if any)
      IERC20ByMetadrop(newERC20_).addInitialLiquidity{
        value: msg.value - deploymentFee_
      }(lockerFee_, 0);
    } else {
      // Check if we have a DRIPool for this token. If so, we need to initialise the
      // token address on the pool. We pass in the DRIPool address on the constructor
      // of the ERC-20, but as they BOTH need to know each others address we need to perform
      // this update.
      // We also fund any intial seed ETH from the project in this call.
      if (driPool_ != address(0)) {
        // We must have at least the deploymentFee. If we have more, this is ETH that the project
        // is seeding into the launch pool
        if (msg.value < deploymentFee_) {
          _revert(IncorrectPayment.selector);
        }

        uint256 ethSeedAmount = msg.value - deploymentFee_;

        address ethSeeContributor = address(0);
        if (ethSeedAmount > 0) {
          ethSeeContributor = _msgSender();
        }

        IERC20DRIPool(driPool_).loadERC20AddressAndSeedETH{
          value: ethSeedAmount
        }(newERC20_, ethSeeContributor);
      } else {
        // Check the fee, we must have ETH for ONLY the deployment fee
        if (msg.value != deploymentFee_) {
          _revert(IncorrectPayment.selector);
        }
      }
    }
  }

  /**
   * @dev function {_deployERC20Contract} Deploy the ERC20 using CREATE2
   *
   * @param salt_ Salt for create2
   * @param erc20Config_ ERC20 configuration
   * @param machine_ The machine contract
   * @param machine_ The address of the launch pool (if any)
   * @return erc20ContractAddress_ Address of the newly deployed ERC20
   */
  function _deployERC20Contract(
    bytes32 salt_,
    ERC20Config calldata erc20Config_,
    IERC20MachineByMetadrop machine_,
    address driPool_
  ) internal returns (address erc20ContractAddress_) {
    address[5] memory integrationAddresses = [
      _msgSender(),
      uniswapRouter,
      unicryptLocker,
      address(this),
      driPool_
    ];

    bytes memory args = abi.encode(
      integrationAddresses,
      erc20Config_.baseParameters,
      erc20Config_.supplyParameters,
      erc20Config_.taxParameters,
      erc20Config_.poolParameters
    );

    return (machine_.deploy(salt_, args));
  }

  /**
   * @dev function {_decodeBaseData} Create an ERC-20
   *
   * Decode the name, symbol and if we are adding liquidity on create
   *
   * @param encodedBaseParams_ Base ERC20 params
   * @return tokenDetails_ The name [0] and symbol [1] of this token
   * @return addLiquidityOnCreate_ bool to indicate we are adding liquidity on create
   * @return usesDRIPool_ bool to indicate we are using a launch pool
   */
  function _decodeBaseData(
    bytes memory encodedBaseParams_
  )
    internal
    pure
    returns (
      string[2] memory tokenDetails_,
      bool addLiquidityOnCreate_,
      bool usesDRIPool_
    )
  {
    string memory name;
    string memory symbol;

    (name, symbol, , , , , addLiquidityOnCreate_, usesDRIPool_) = abi.decode(
      encodedBaseParams_,
      (string, string, string, string, string, string, bool, bool)
    );

    // Some validation: addLiquidityOnCreate_ and usesDRIPool_ CANNOT both be true:
    if (addLiquidityOnCreate_ && usesDRIPool_) {
      _revert(CannotAddLiquidityOnCreateAndUseDRIPool.selector);
    }

    return ([name, symbol], addLiquidityOnCreate_, usesDRIPool_);
  }

  /**
   * @dev function {_verifyMessage}
   *
   * Check the signature and expiry of the passed message
   *
   * @param signedMessage_ The signed message object
   */
  function _verifyMessage(
    SignedDropMessageDetails calldata signedMessage_
  ) internal view {
    // Check that this signature is from the oracle signer:
    if (
      !_validSignature(
        signedMessage_.messageHash,
        signedMessage_.messageSignature
      )
    ) {
      _revert(InvalidOracleSignature.selector);
    }

    // Check that the signature has not expired:
    unchecked {
      if (
        (signedMessage_.messageTimeStamp + messageValidityInSeconds) <
        block.timestamp
      ) {
        _revert(OracleSignatureHasExpired.selector);
      }
    }
  }

  /**
   * @dev function {_validSignature}
   *
   * Checks the the signature on the signed message is from the metadrop oracle
   *
   * @param messageHash_ The message hash signed by the trusted oracle signer. This will be the
   * keccack256 hash of received data about this token.
   * @param messageSignature_ The signed message from the backend oracle signer for validation.
   * @return messageIsValid_ If the message is valid (or not)
   */
  function _validSignature(
    bytes32 messageHash_,
    bytes memory messageSignature_
  ) internal view returns (bool messageIsValid_) {
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

  /**
   * @dev function {_checkConfigHashMatches}
   *
   * Check the passed config against the stored config hash
   *
   * @param metaId_ The drop Id being approved
   * @param salt_ Salt for create2
   * @param erc20Config_ ERC20 configuration
   * @param signedMessage_ The signed message object
   * @param lockerFee_ The fee for the unicrypt locker
   * @param deploymentFee_ The fee for deployment, if any
   */
  function _checkConfigHashMatches(
    string calldata metaId_,
    bytes32 salt_,
    ERC20Config calldata erc20Config_,
    SignedDropMessageDetails calldata signedMessage_,
    uint256 lockerFee_,
    uint256 deploymentFee_
  ) internal view {
    // Create the hash of the passed data for comparison:
    bytes32 passedConfigHash = createConfigHash(
      metaId_,
      salt_,
      erc20Config_,
      signedMessage_.messageTimeStamp,
      lockerFee_,
      deploymentFee_,
      _msgSender()
    );

    // Must equal the stored hash:
    if (passedConfigHash != signedMessage_.messageHash) {
      _revert(PassedConfigDoesNotMatchApproved.selector);
    }
  }

  /**
   * @dev function {createConfigHash}
   *
   * Create the config hash
   *
   * @param metaId_ The drop Id being approved
   * @param salt_ Salt for create2
   * @param erc20Config_ ERC20 configuration
   * @param messageTimeStamp_ When the message for this config hash was signed
   * @param lockerFee_ The fee for the unicrypt locker
   * @param deploymentFee_ The fee for deployment, if any
   * @param deployer_ Address performing the deployment
   * @return configHash_ The bytes32 config hash
   */
  function createConfigHash(
    string calldata metaId_,
    bytes32 salt_,
    ERC20Config calldata erc20Config_,
    uint256 messageTimeStamp_,
    uint256 lockerFee_,
    uint256 deploymentFee_,
    address deployer_
  ) public pure returns (bytes32 configHash_) {
    configHash_ = keccak256(
      abi.encodePacked(
        metaId_,
        salt_,
        _createBytesParamsHash(erc20Config_),
        messageTimeStamp_,
        lockerFee_,
        deploymentFee_,
        deployer_
      )
    );

    return (configHash_);
  }

  /**
   * @dev function {_createBytesParamsHash}
   *
   * Create a hash of the bytes params objects
   *
   * @param erc20Config_ ERC20 configuration
   * @return configHash_ The bytes32 config hash
   */
  function _createBytesParamsHash(
    ERC20Config calldata erc20Config_
  ) internal pure returns (bytes32 configHash_) {
    configHash_ = keccak256(
      abi.encodePacked(
        erc20Config_.baseParameters,
        erc20Config_.supplyParameters,
        erc20Config_.taxParameters,
        erc20Config_.poolParameters
      )
    );

    return (configHash_);
  }
}