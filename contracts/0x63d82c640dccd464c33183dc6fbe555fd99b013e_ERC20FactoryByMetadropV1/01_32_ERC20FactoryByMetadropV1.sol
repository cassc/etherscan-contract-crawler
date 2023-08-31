// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.19;

import {AuthorityModel} from "../../Global/AuthorityModel.sol";
import {SafeERC20, IERC20} from "../../Global/OZ/SafeERC20.sol";
import {IERC20FactoryByMetadropV1} from "./IERC20FactoryByMetadropV1.sol";
import {IERC20ByMetadropV1} from "../ERC20/IERC20ByMetadropV1.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20ByMetadropV1, ERC20ByMetadropV1} from "../ERC20/ERC20ByMetadropV1.sol";

/**
 * @dev Metadrop ERC-20 factory
 */
contract ERC20FactoryByMetadropV1 is
  Context,
  IERC20FactoryByMetadropV1,
  AuthorityModel
{
  using SafeERC20 for IERC20;

  // Uniswap router address
  address public immutable uniswapRouter;
  // Unicrypt locker address
  address public immutable unicryptLocker;

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
   */
  constructor(
    address superAdmin_,
    address[] memory platformAdmins_,
    address platformTreasury_,
    address metadropOracleAddress_,
    address uniswapRouter_,
    address unicryptLocker_
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
   * @return deployedAddress_ The deployed ERC20 contract address
   */
  function createERC20(
    string calldata metaId_,
    bytes32 salt_,
    ERC20Config calldata erc20Config_,
    SignedDropMessageDetails calldata signedMessage_,
    uint256 lockerFee_,
    uint256 deploymentFee_
  ) external payable returns (address deployedAddress_) {
    // Check the signed message origin and time:
    _verifyMessage(signedMessage_);

    // We can only proceed if the hash of the passed configuration matches the hash
    // signed by our oracle signer:
    if (
      !_configHashMatches(
        metaId_,
        salt_,
        erc20Config_,
        signedMessage_,
        lockerFee_,
        deploymentFee_,
        _msgSender()
      )
    ) {
      _revert(PassedConfigDoesNotMatchApproved.selector);
    }

    (, , , , , , bool addLiquidityOnCreate, , ) = abi.decode(
      erc20Config_.supplyParameters,
      (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        bool,
        address,
        address
      )
    );

    address[3] memory integrationAddresses = [
      msg.sender,
      uniswapRouter,
      unicryptLocker
    ];

    bytes memory deploymentData = abi.encodePacked(
      type(ERC20ByMetadropV1).creationCode,
      abi.encode(
        integrationAddresses,
        erc20Config_.baseParameters,
        erc20Config_.supplyParameters,
        erc20Config_.taxParameters
      )
    );

    address newERC20;

    assembly {
      newERC20 := create2(
        0,
        add(deploymentData, 0x20),
        mload(deploymentData),
        salt_
      )
      if iszero(extcodesize(newERC20)) {
        revert(0, 0)
      }
    }

    if (addLiquidityOnCreate) {
      // Check the fee, we must have enough ETH for the fees, plus at least ONE wei if adding liquidity:
      if (msg.value < (lockerFee_ + deploymentFee_)) {
        _revert(IncorrectPayment.selector);
      }

      // Value to pass on (for locking fee plus liquidity, if any) is the sent
      // amount minus the deployment fee (if any)
      IERC20ByMetadropV1(newERC20).addInitialLiquidity{
        value: msg.value - deploymentFee_
      }(lockerFee_);
    } else {
      // Check the fee, we must have ETH for ONLY the deployment fee
      if (msg.value != deploymentFee_) {
        _revert(IncorrectPayment.selector);
      }
    }

    (string memory tokenName, string memory tokenSymbol) = _getNameAndSymbol(
      erc20Config_.baseParameters
    );

    emit ERC20Created(metaId_, msg.sender, newERC20, tokenName, tokenSymbol);

    return (newERC20);
  }

  /**
   * @dev function {_getNameAndSymbol} Create an ERC-20
   *
   * Decode the name and symbol
   *
   * @param encodedBaseParams_ Base ERC20 params
   * @return name_ The name
   * @return symbol_ The symbol
   */
  function _getNameAndSymbol(
    bytes memory encodedBaseParams_
  ) internal pure returns (string memory name_, string memory symbol_) {
    (name_, symbol_, , , , ) = abi.decode(
      encodedBaseParams_,
      (string, string, string, string, string, string)
    );
    return (name_, symbol_);
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

  /**
   * @dev function {_configHashMatches}
   *
   * Check the passed config against the stored config hash
   *
   * @param metaId_ The drop Id being approved
   * @param salt_ Salt for create2
   * @param erc20Config_ ERC20 configuration
   * @param signedMessage_ The signed message object
   * @param lockerFee_ The fee for the unicrypt locker
   * @param deploymentFee_ The fee for deployment, if any
   * @param deployer_ Address performing the deployment
   * @return matches_ Whether the hash matches (true) or not (false)
   */
  function _configHashMatches(
    string calldata metaId_,
    bytes32 salt_,
    ERC20Config calldata erc20Config_,
    SignedDropMessageDetails calldata signedMessage_,
    uint256 lockerFee_,
    uint256 deploymentFee_,
    address deployer_
  ) internal pure returns (bool matches_) {
    // Create the hash of the passed data for comparison:
    bytes32 passedConfigHash = createConfigHash(
      metaId_,
      salt_,
      erc20Config_,
      signedMessage_.messageTimeStamp,
      lockerFee_,
      deploymentFee_,
      deployer_
    );

    // Must equal the stored hash:
    return (passedConfigHash == signedMessage_.messageHash);
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
        erc20Config_.baseParameters,
        erc20Config_.supplyParameters,
        erc20Config_.taxParameters,
        messageTimeStamp_,
        lockerFee_,
        deploymentFee_,
        deployer_
      )
    );

    return (configHash_);
  }
}