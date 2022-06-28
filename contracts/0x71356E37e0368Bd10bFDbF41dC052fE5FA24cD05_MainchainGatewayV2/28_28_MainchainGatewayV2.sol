// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../extensions/GatewayV2.sol";
import "../extensions/WithdrawalLimitation.sol";
import "../library/Transfer.sol";
import "./IMainchainGatewayV2.sol";

contract MainchainGatewayV2 is WithdrawalLimitation, Initializable, AccessControlEnumerable, IMainchainGatewayV2 {
  using Token for Token.Info;
  using Transfer for Transfer.Request;
  using Transfer for Transfer.Receipt;

  /// @dev Withdrawal unlocker role hash
  bytes32 public constant WITHDRAWAL_UNLOCKER_ROLE = keccak256("WITHDRAWAL_UNLOCKER_ROLE");

  /// @dev Wrapped native token address
  IWETH public wrappedNativeToken;
  /// @dev Ronin network id
  uint256 public roninChainId;
  /// @dev Total deposit
  uint256 public depositCount;
  /// @dev Domain seperator
  bytes32 internal _domainSeparator;
  /// @dev Mapping from mainchain token => token address on Ronin network
  mapping(address => MappedToken) internal _roninToken;
  /// @dev Mapping from withdrawal id => withdrawal hash
  mapping(uint256 => bytes32) public withdrawalHash;
  /// @dev Mapping from withdrawal id => locked
  mapping(uint256 => bool) public withdrawalLocked;

  fallback() external payable {
    _fallback();
  }

  receive() external payable {
    _fallback();
  }

  /**
   * @dev Initializes contract storage.
   */
  function initialize(
    address _roleSetter,
    IWETH _wrappedToken,
    IWeightedValidator _validatorContract,
    uint256 _roninChainId,
    uint256 _numerator,
    uint256 _highTierVWNumerator,
    uint256 _denominator,
    // _addresses[0]: mainchainTokens
    // _addresses[1]: roninTokens
    // _addresses[2]: withdrawalUnlockers
    address[][3] calldata _addresses,
    // _thresholds[0]: highTierThreshold
    // _thresholds[1]: lockedThreshold
    // _thresholds[2]: unlockFeePercentages
    // _thresholds[3]: dailyWithdrawalLimit
    uint256[][4] calldata _thresholds,
    Token.Standard[] calldata _standards
  ) external payable virtual initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, _roleSetter);
    roninChainId = _roninChainId;

    _setWrappedNativeTokenContract(_wrappedToken);
    _setValidatorContract(_validatorContract);
    _updateDomainSeparator();
    _setThreshold(_numerator, _denominator);
    _setHighTierVoteWeightThreshold(_highTierVWNumerator, _denominator);
    _verifyThresholds();

    if (_addresses[0].length > 0) {
      // Map mainchain tokens to ronin tokens
      _mapTokens(_addresses[0], _addresses[1], _standards);
      // Sets thresholds based on the mainchain tokens
      _setHighTierThresholds(_addresses[0], _thresholds[0]);
      _setLockedThresholds(_addresses[0], _thresholds[1]);
      _setUnlockFeePercentages(_addresses[0], _thresholds[2]);
      _setDailyWithdrawalLimits(_addresses[0], _thresholds[3]);
    }

    // Grant role for withdrawal unlocker
    for (uint256 _i; _i < _addresses[2].length; _i++) {
      _grantRole(WITHDRAWAL_UNLOCKER_ROLE, _addresses[2][_i]);
    }
  }

  /**
   * @dev Receives ether without doing anything. Use this function to topup native token.
   */
  function receiveEther() external payable {}

  /**
   * @dev See {IMainchainGatewayV2-DOMAIN_SEPARATOR}.
   */
  function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
    return _domainSeparator;
  }

  /**
   * @dev See {IMainchainGatewayV2-setWrappedNativeTokenContract}.
   */
  function setWrappedNativeTokenContract(IWETH _wrappedToken) external virtual onlyAdmin {
    _setWrappedNativeTokenContract(_wrappedToken);
  }

  /**
   * @dev See {IMainchainGatewayV2-requestDepositFor}.
   */
  function requestDepositFor(Transfer.Request calldata _request) external payable virtual whenNotPaused {
    _requestDepositFor(_request, msg.sender);
  }

  /**
   * @dev See {IMainchainGatewayV2-submitWithdrawal}.
   */
  function submitWithdrawal(Transfer.Receipt calldata _receipt, Signature[] calldata _signatures)
    external
    virtual
    whenNotPaused
    returns (bool _locked)
  {
    return _submitWithdrawal(_receipt, _signatures);
  }

  /**
   * @dev See {IMainchainGatewayV2-unlockWithdrawal}.
   */
  function unlockWithdrawal(Transfer.Receipt calldata _receipt) external onlyRole(WITHDRAWAL_UNLOCKER_ROLE) {
    bytes32 _receiptHash = _receipt.hash();
    require(withdrawalHash[_receipt.id] == _receipt.hash(), "MainchainGatewayV2: invalid receipt");
    require(withdrawalLocked[_receipt.id], "MainchainGatewayV2: query for approved withdrawal");
    delete withdrawalLocked[_receipt.id];
    emit WithdrawalUnlocked(_receiptHash, _receipt);

    address _token = _receipt.mainchain.tokenAddr;
    if (_receipt.info.erc == Token.Standard.ERC20) {
      Token.Info memory _feeInfo = _receipt.info;
      _feeInfo.quantity = _computeFeePercentage(_receipt.info.quantity, unlockFeePercentages[_token]);
      Token.Info memory _withdrawInfo = _receipt.info;
      _withdrawInfo.quantity = _receipt.info.quantity - _feeInfo.quantity;

      _feeInfo.handleAssetTransfer(payable(msg.sender), _token, wrappedNativeToken);
      _withdrawInfo.handleAssetTransfer(payable(_receipt.mainchain.addr), _token, wrappedNativeToken);
    } else {
      _receipt.info.handleAssetTransfer(payable(_receipt.mainchain.addr), _token, wrappedNativeToken);
    }

    emit Withdrew(_receiptHash, _receipt);
  }

  /**
   * @dev See {IMainchainGatewayV2-mapTokens}.
   */
  function mapTokens(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards
  ) external virtual onlyAdmin {
    require(_mainchainTokens.length > 0, "MainchainGatewayV2: query for empty array");
    _mapTokens(_mainchainTokens, _roninTokens, _standards);
  }

  /**
   * @dev See {IMainchainGatewayV2-mapTokensAndThresholds}.
   */
  function mapTokensAndThresholds(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards,
    // _thresholds[0]: highTierThreshold
    // _thresholds[1]: lockedThreshold
    // _thresholds[2]: unlockFeePercentages
    // _thresholds[3]: dailyWithdrawalLimit
    uint256[][4] calldata _thresholds
  ) external virtual onlyAdmin {
    require(_mainchainTokens.length > 0, "MainchainGatewayV2: query for empty array");
    _mapTokens(_mainchainTokens, _roninTokens, _standards);
    _setHighTierThresholds(_mainchainTokens, _thresholds[0]);
    _setLockedThresholds(_mainchainTokens, _thresholds[1]);
    _setUnlockFeePercentages(_mainchainTokens, _thresholds[2]);
    _setDailyWithdrawalLimits(_mainchainTokens, _thresholds[3]);
  }

  /**
   * @dev See {IMainchainGatewayV2-getRoninToken}.
   */
  function getRoninToken(address _mainchainToken) public view returns (MappedToken memory _token) {
    _token = _roninToken[_mainchainToken];
    require(_token.tokenAddr != address(0), "MainchainGatewayV2: unsupported token");
  }

  /**
   * @dev Maps mainchain tokens to Ronin network.
   *
   * Requirement:
   * - The arrays have the same length.
   *
   * Emits the `TokenMapped` event.
   *
   */
  function _mapTokens(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards
  ) internal virtual {
    require(
      _mainchainTokens.length == _roninTokens.length && _mainchainTokens.length == _standards.length,
      "MainchainGatewayV2: invalid array length"
    );

    for (uint256 _i; _i < _mainchainTokens.length; _i++) {
      _roninToken[_mainchainTokens[_i]].tokenAddr = _roninTokens[_i];
      _roninToken[_mainchainTokens[_i]].erc = _standards[_i];
    }

    emit TokenMapped(_mainchainTokens, _roninTokens, _standards);
  }

  /**
   * @dev Submits withdrawal receipt.
   *
   * Requirements:
   * - The receipt kind is withdrawal.
   * - The receipt is to withdraw on this chain.
   * - The receipt is not used to withdraw before.
   * - The withdrawal is not reached the limit threshold.
   * - The signer weight total is larger than or equal to the minimum threshold.
   * - The signature signers are in order.
   *
   * Emits the `Withdrew` once the assets are released.
   *
   */
  function _submitWithdrawal(Transfer.Receipt calldata _receipt, Signature[] memory _signatures)
    internal
    virtual
    returns (bool _locked)
  {
    uint256 _id = _receipt.id;
    uint256 _quantity = _receipt.info.quantity;
    address _tokenAddr = _receipt.mainchain.tokenAddr;

    _receipt.info.validate();
    require(_receipt.kind == Transfer.Kind.Withdrawal, "MainchainGatewayV2: invalid receipt kind");
    require(_receipt.mainchain.chainId == block.chainid, "MainchainGatewayV2: invalid chain id");
    MappedToken memory _token = getRoninToken(_receipt.mainchain.tokenAddr);
    require(
      _token.erc == _receipt.info.erc && _token.tokenAddr == _receipt.ronin.tokenAddr,
      "MainchainGatewayV2: invalid receipt"
    );
    require(withdrawalHash[_id] == bytes32(0), "MainchainGatewayV2: query for processed withdrawal");
    require(
      _receipt.info.erc == Token.Standard.ERC721 || !_reachedWithdrawalLimit(_tokenAddr, _quantity),
      "MainchainGatewayV2: reached daily withdrawal limit"
    );

    bytes32 _receiptHash = _receipt.hash();
    bytes32 _receiptDigest = Transfer.receiptDigest(_domainSeparator, _receiptHash);
    IWeightedValidator _validatorContract = validatorContract;

    uint256 _minimumVoteWeight;
    (_minimumVoteWeight, _locked) = _computeMinVoteWeight(_receipt.info.erc, _tokenAddr, _quantity, _validatorContract);

    {
      bool _passed;
      address _signer;
      address _lastSigner;
      Signature memory _sig;
      uint256 _weight;
      for (uint256 _i; _i < _signatures.length; _i++) {
        _sig = _signatures[_i];
        _signer = ecrecover(_receiptDigest, _sig.v, _sig.r, _sig.s);
        require(_lastSigner < _signer, "MainchainGatewayV2: invalid order");
        _lastSigner = _signer;

        _weight += _validatorContract.getValidatorWeight(_signer);
        if (_weight >= _minimumVoteWeight) {
          _passed = true;
          break;
        }
      }
      require(_passed, "MainchainGatewayV2: query for insufficient vote weight");
      withdrawalHash[_id] = _receiptHash;
    }

    if (_locked) {
      withdrawalLocked[_id] = true;
      emit WithdrawalLocked(_receiptHash, _receipt);
      return _locked;
    }

    _recordWithdrawal(_tokenAddr, _quantity);
    _receipt.info.handleAssetTransfer(payable(_receipt.mainchain.addr), _tokenAddr, wrappedNativeToken);
    emit Withdrew(_receiptHash, _receipt);
  }

  /**
   * @dev Requests deposit made by `_requester` address.
   *
   * Requirements:
   * - The token info is valid.
   * - The `msg.value` is 0 while depositing ERC20 token.
   * - The `msg.value` is equal to deposit quantity while depositing native token.
   *
   * Emits the `DepositRequested` event.
   *
   */
  function _requestDepositFor(Transfer.Request memory _request, address _requester) internal virtual {
    MappedToken memory _token;
    address _weth = address(wrappedNativeToken);

    _request.info.validate();
    if (_request.tokenAddr == address(0)) {
      require(_request.info.quantity == msg.value, "MainchainGatewayV2: invalid request");
      _token = getRoninToken(_weth);
      require(_token.erc == _request.info.erc, "MainchainGatewayV2: invalid token standard");
      _request.tokenAddr = _weth;
    } else {
      require(msg.value == 0, "MainchainGatewayV2: invalid request");
      _token = getRoninToken(_request.tokenAddr);
      require(_token.erc == _request.info.erc, "MainchainGatewayV2: invalid token standard");
      _request.info.transferFrom(_requester, address(this), _request.tokenAddr);
      // Withdraw if token is WETH
      if (_weth == _request.tokenAddr) {
        IWETH(_weth).withdraw(_request.info.quantity);
      }
    }

    uint256 _depositId = depositCount++;
    Transfer.Receipt memory _receipt = _request.into_deposit_receipt(
      _requester,
      _depositId,
      _token.tokenAddr,
      roninChainId
    );

    emit DepositRequested(_receipt.hash(), _receipt);
  }

  /**
   * @dev Returns the minimum vote weight for the token.
   */
  function _computeMinVoteWeight(
    Token.Standard _erc,
    address _token,
    uint256 _quantity,
    IWeightedValidator _validatorContract
  ) internal virtual returns (uint256 _weight, bool _locked) {
    uint256 _totalWeights = _validatorContract.totalWeights();
    _weight = _minimumVoteWeight(_totalWeights);
    if (_erc == Token.Standard.ERC20) {
      if (highTierThreshold[_token] <= _quantity) {
        _weight = _highTierVoteWeight(_totalWeights);
      }
      _locked = _lockedWithdrawalRequest(_token, _quantity);
    }
  }

  /**
   * @dev Update domain seperator.
   */
  function _updateDomainSeparator() internal {
    _domainSeparator = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("MainchainGatewayV2"),
        keccak256("2"),
        block.chainid,
        address(this)
      )
    );
  }

  /**
   * @dev Sets the WETH contract.
   *
   * Emits the `WrappedNativeTokenContractUpdated` event.
   *
   */
  function _setWrappedNativeTokenContract(IWETH _wrapedToken) internal {
    wrappedNativeToken = _wrapedToken;
    emit WrappedNativeTokenContractUpdated(_wrapedToken);
  }

  /**
   * @dev Receives ETH from WETH or creates deposit request.
   */
  function _fallback() internal virtual whenNotPaused {
    if (msg.sender != address(wrappedNativeToken)) {
      Transfer.Request memory _request;
      _request.recipientAddr = msg.sender;
      _request.info.quantity = msg.value;
      _requestDepositFor(_request, _request.recipientAddr);
    }
  }
}