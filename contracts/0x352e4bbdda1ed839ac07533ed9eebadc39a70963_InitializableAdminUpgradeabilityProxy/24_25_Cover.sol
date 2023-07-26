// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./proxy/InitializableAdminUpgradeabilityProxy.sol";
import "./utils/Create2.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./utils/SafeERC20.sol";
import "./interfaces/ICover.sol";
import "./interfaces/ICoverERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IProtocolFactory.sol";

/**
 * @title Cover contract
 * @author [email protected]
 *
 * The contract
 *  - Holds collateral funds
 *  - Mints and burns CovTokens (CoverERC20)
 *  - Allows redeem from collateral pool with or without an accepted claim
 */
contract Cover is ICover, Initializable, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes4 private constant COVERERC20_INIT_SIGNITURE = bytes4(keccak256("initialize(string)"));
  uint48 public override expirationTimestamp;
  address public override collateral;
  ICoverERC20 public override claimCovToken;
  ICoverERC20 public override noclaimCovToken;
  string public override name;
  uint256 public override claimNonce;

  modifier onlyNotExpired() {
    require(block.timestamp < expirationTimestamp, "COVER: cover expired");
    _;
  }

  /// @dev Initialize, called once
  function initialize (
    string calldata _name,
    uint48 _timestamp,
    address _collateral,
    uint256 _claimNonce
  ) public initializer {
    name = _name;
    expirationTimestamp = _timestamp;
    collateral = _collateral;
    claimNonce = _claimNonce;

    initializeOwner();

    claimCovToken = _createCovToken("CLAIM");
    noclaimCovToken = _createCovToken("NOCLAIM");
  }

  function getCoverDetails()
    external view override returns (string memory _name, uint48 _expirationTimestamp, address _collateral, uint256 _claimNonce, ICoverERC20 _claimCovToken, ICoverERC20 _noclaimCovToken)
  {
    return (name, expirationTimestamp, collateral, claimNonce, claimCovToken, noclaimCovToken);
  }

  /// @notice only owner (covered protocol) can mint, collateral is transfered in Protocol
  function mint(uint256 _amount, address _receiver) external override onlyOwner onlyNotExpired {
    _noClaimAcceptedCheck(); // save gas than modifier

    claimCovToken.mint(_receiver, _amount);
    noclaimCovToken.mint(_receiver, _amount);
  }

  /// @notice redeem CLAIM covToken, only if there is a claim accepted and delayWithClaim period passed
  function redeemClaim() external override {
    IProtocol protocol = IProtocol(owner());
    require(protocol.claimNonce() > claimNonce, "COVER: no claim accepted");

    (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _claimEnactedTimestamp) = _claimDetails();
    require(_incidentTimestamp <= expirationTimestamp, "COVER: cover expired before incident");
    require(block.timestamp >= uint256(_claimEnactedTimestamp) + protocol.claimRedeemDelay(), "COVER: not ready");

    _paySender(
      claimCovToken,
      uint256(_payoutNumerator),
      uint256(_payoutDenominator)
    );
  }

  /**
   * @notice redeem NOCLAIM covToken, accept
   * - if no claim accepted, cover is expired, and delayWithoutClaim period passed
   * - if claim accepted, but payout % < 1, and delayWithClaim period passed
   */
  function redeemNoclaim() external override {
    IProtocol protocol = IProtocol(owner());
    if (protocol.claimNonce() > claimNonce) {
      // protocol has an accepted claim

      (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _claimEnactedTimestamp) = _claimDetails();

      if (_incidentTimestamp > expirationTimestamp) {
        // incident happened after expiration date, redeem back full collateral

        require(block.timestamp >= uint256(expirationTimestamp) + protocol.noclaimRedeemDelay(), "COVER: not ready");
        _paySender(noclaimCovToken, 1, 1);
      } else {
        // incident happened before expiration date, pay 1 - payout%

        // If claim payout is 100%, nothing is left for NOCLAIM covToken holders
        require(_payoutNumerator < _payoutDenominator, "COVER: claim payout 100%");

        require(block.timestamp >= uint256(_claimEnactedTimestamp) + protocol.claimRedeemDelay(), "COVER: not ready");
        _paySender(
          noclaimCovToken,
          uint256(_payoutDenominator).sub(uint256(_payoutNumerator)),
          uint256(_payoutDenominator)
        );
      }
    } else {
      // protocol has no accepted claim

      require(block.timestamp >= uint256(expirationTimestamp) + protocol.noclaimRedeemDelay(), "COVER: not ready");
      _paySender(noclaimCovToken, 1, 1);
    }
  }

  /// @notice redeem collateral, only when no claim accepted and not expired
  function redeemCollateral(uint256 _amount) external override onlyNotExpired {
    require(_amount > 0, "COVER: amount is 0");
    _noClaimAcceptedCheck(); // save gas than modifier

    ICoverERC20 _claimCovToken = claimCovToken; // save gas
    ICoverERC20 _noclaimCovToken = noclaimCovToken; // save gas

    require(_amount <= _claimCovToken.balanceOf(msg.sender), "COVER: low CLAIM balance");
    require(_amount <= _noclaimCovToken.balanceOf(msg.sender), "COVER: low NOCLAIM balance");

    _claimCovToken.burnByCover(msg.sender, _amount);
    _noclaimCovToken.burnByCover(msg.sender, _amount);
    _payCollateral(msg.sender, _amount);
  }

  /**
   * @notice set CovTokenSymbol, will update symbols for both covTokens, only dev account (factory owner)
   * For example:
   *  - COVER_CURVE_2020_12_31_DAI_0
   */
  function setCovTokenSymbol(string calldata _name) external override {
    require(_dev() == msg.sender, "COVER: not dev");

    claimCovToken.setSymbol(string(abi.encodePacked(_name, "_CLAIM")));
    noclaimCovToken.setSymbol(string(abi.encodePacked(_name, "_NOCLAIM")));
  }

  /// @notice the owner of this contract is Protocol contract, the owner of Protocol is ProtocolFactory contract
  function _factory() private view returns (address) {
    return IOwnable(owner()).owner();
  }

  // get the claim details for the corresponding nonce from protocol contract
  function _claimDetails() private view returns (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _claimEnactedTimestamp) {
    return IProtocol(owner()).claimDetails(claimNonce);
  }

  /// @notice the owner of ProtocolFactory contract is dev, also see {_factory}
  function _dev() private view returns (address) {
    return IOwnable(_factory()).owner();
  }

  /// @notice make sure no claim is accepted
  function _noClaimAcceptedCheck() private view {
    require(IProtocol(owner()).claimNonce() == claimNonce, "COVER: claim accepted");
  }

  /// @notice transfer collateral (amount - fee) from this contract to recevier, transfer fee to COVER treasury
  function _payCollateral(address _receiver, uint256 _amount) private {
    IProtocolFactory factory = IProtocolFactory(_factory());
    uint256 redeemFeeNumerator = factory.redeemFeeNumerator();
    uint256 redeemFeeDenominator = factory.redeemFeeDenominator();
    uint256 fee = _amount.mul(redeemFeeNumerator).div(redeemFeeDenominator);
    address treasury = factory.treasury();
    IERC20 collateralToken = IERC20(collateral);

    collateralToken.transfer(_receiver, _amount.sub(fee));
    collateralToken.transfer(treasury, fee);
  }

  /// @notice burn covToken and pay sender
  function _paySender(
    ICoverERC20 _covToken,
    uint256 _payoutNumerator,
    uint256 _payoutDenominator
  ) private {
    require(_payoutNumerator <= _payoutDenominator, "COVER: payout % is > 100%");
    require(_payoutNumerator > 0, "COVER: payout % < 0%");

    uint256 amount = _covToken.balanceOf(msg.sender);
    require(amount > 0, "COVER: low covToken balance");

    _covToken.burnByCover(msg.sender, amount);

    uint256 payoutAmount = amount.mul(_payoutNumerator).div(_payoutDenominator);
    _payCollateral(msg.sender, payoutAmount);
  }

  /// @dev Emits NewCoverERC20
  function _createCovToken(string memory _suffix) private returns (ICoverERC20) {
    bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(IProtocol(owner()).name(), expirationTimestamp, collateral, claimNonce, _suffix));
    address payable proxyAddr = Create2.deploy(0, salt, bytecode);

    bytes memory initData = abi.encodeWithSelector(COVERERC20_INIT_SIGNITURE, string(abi.encodePacked(name, "_", _suffix)));
    address coverERC20Implementation = IProtocolFactory(_factory()).coverERC20Implementation();
    InitializableAdminUpgradeabilityProxy(proxyAddr).initialize(
      coverERC20Implementation,
      IProtocolFactory(_factory()).governance(),
      initData
    );

    emit NewCoverERC20(proxyAddr);
    return ICoverERC20(proxyAddr);
  }
}