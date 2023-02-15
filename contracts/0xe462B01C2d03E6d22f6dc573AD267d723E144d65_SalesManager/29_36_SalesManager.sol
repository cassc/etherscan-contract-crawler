// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../interfaces/ISalesManager.sol";
import "./libraries/LibIMPT.sol";

import "./libraries/SigRecovery.sol";

contract SalesManager is ISalesManager, PausableUpgradeable, UUPSUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  IERC20Upgradeable public override IMPTAddress;
  IERC20Upgradeable public override USDCAddress;
  IWETH public override WETHAddress;
  ICarbonCreditNFT public override CarbonCreditNFTContract;
  ISoulboundToken public override SoulboundToken;
  IAccessManager public override AccessManager;

  address public override IMPTTreasuryAddress;

  //Request ID (from back-end) => used
  mapping(bytes24 => bool) public override usedRequests;

  modifier onlyIMPTRole(bytes32 _role, IAccessManager _AccessManager) {
    LibIMPT._hasIMPTRole(_role, msg.sender, AccessManager);
    _;
  }

  function initialize(ConstructorParams memory _params) public initializer {
    PausableUpgradeable.__Pausable_init();
    LibIMPT._checkZeroAddress(address(_params.IMPTAddress));
    LibIMPT._checkZeroAddress(address(_params.USDCAddress));
    LibIMPT._checkZeroAddress(address(_params.WETHAddress));
    LibIMPT._checkZeroAddress(address(_params.CarbonCreditNFTContract));
    LibIMPT._checkZeroAddress(address(_params.AccessManager));
    LibIMPT._checkZeroAddress(address(_params.SoulboundToken));
    LibIMPT._checkZeroAddress(_params.IMPTTreasuryAddress);
    __UUPSUpgradeable_init();

    IMPTAddress = _params.IMPTAddress;
    USDCAddress = _params.USDCAddress;
    WETHAddress = _params.WETHAddress;
    IMPTTreasuryAddress = _params.IMPTTreasuryAddress;
    CarbonCreditNFTContract = _params.CarbonCreditNFTContract;
    AccessManager = _params.AccessManager;
    SoulboundToken = _params.SoulboundToken;
  }

  //############################
  //#### INTERNAL-FUNCTIONS ####

  /// @dev Verifies the purchase signature of the given authorisation parameters.
  /// @param _authorisationParams Authorisation parameters to verify the signature of.
  function _verifyPurchaseSignature(
    AuthorisationParams memory _authorisationParams
  ) internal {
    bytes memory encodedTransferRequest = abi.encode(
      _authorisationParams.requestId,
      _authorisationParams.expiry,
      msg.sender,
      _authorisationParams.sellAmount,
      _authorisationParams.amount
    );
    if (_authorisationParams.expiry < block.timestamp) {
      revert LibIMPT.SignatureExpired();
    }
    if (usedRequests[_authorisationParams.requestId]) {
      revert LibIMPT.InvalidSignature();
    }

    address recoveredAddress = SigRecovery.recoverAddressFromMessage(
      encodedTransferRequest,
      _authorisationParams.signature
    );

    if (!AccessManager.hasRole(LibIMPT.IMPT_BACKEND_ROLE, recoveredAddress)) {
      revert LibIMPT.InvalidSignature();
    }

    usedRequests[_authorisationParams.requestId] = true;
  }

  /// @dev Calls the given DEX swap contract with the given parameters and audits the results.
  /// @param _swapParams Swap parameters to pass to the DEX contract.
  /// @return  swapReturn The resulting swap data.
  function _callDEXSwap(
    SwapParams calldata _swapParams
  ) internal returns (SwapReturnData memory swapReturn) {
    //Sticking these in memory so we don't repetitively read storage
    IERC20Upgradeable USDCToken = USDCAddress;
    IERC20Upgradeable IMPTToken = IMPTAddress;

    if (
      !(
        AccessManager.hasRole(LibIMPT.IMPT_APPROVED_DEX, _swapParams.swapTarget)
      )
    ) {
      revert UnauthorisedSwapTarget();
    }
    //If the DEX being utilised for the swap will take the funds from an address other than the call target, grant it a temporary allowance
    if (_swapParams.swapTarget != _swapParams.spender) {
      IMPTToken.approve(_swapParams.spender, type(uint256).max);
    }

    uint256 USDCBefore = USDCToken.balanceOf(address(this));
    uint256 IMPTBefore = IMPTToken.balanceOf(address(this));

    (bool success, ) = _swapParams.swapTarget.call(_swapParams.swapCallData);

    if (!success) {
      revert ZeroXSwapFailed();
    }
    swapReturn.USDCDelta = USDCToken.balanceOf(address(this)) - USDCBefore;
    swapReturn.IMPTDelta = IMPTBefore - IMPTToken.balanceOf(address(this));

    if (_swapParams.swapTarget != _swapParams.spender) {
      IMPTToken.approve(_swapParams.spender, uint256(0));
    }
  }

  /// @dev Audits the results of a swap to ensure that the correct amounts of sell and buy tokens were transferred.
  /// @param _swapReturnData Swap data to audit.
  /// @param _sellAmount Amount of sell tokens that should have been transferred.
  function _auditSwap(
    SwapReturnData memory _swapReturnData,
    uint256 _sellAmount
  ) internal pure {
    if (_swapReturnData.IMPTDelta != _sellAmount) {
      revert WrongSellTokenChange();
    }
    if (!(_swapReturnData.USDCDelta > 0)) {
      revert WrongBuyTokenChange();
    }
  }

  //###################
  //#### FUNCTIONS ####
  /// @dev This function is to check that the upgrade functions in UUPSUpgradeable are being called by an address with the correct role
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {}

  receive() external payable override {}

  function purchaseWithIMPT(
    AuthorisationParams calldata _authorisationParams,
    SwapParams calldata _swapParams
  ) external whenNotPaused {
    _verifyPurchaseSignature(_authorisationParams);

    IMPTAddress.safeTransferFrom(
      msg.sender,
      IMPTTreasuryAddress,
      _authorisationParams.sellAmount
    );

    SwapReturnData memory swapReturn = _callDEXSwap(_swapParams);
    _auditSwap(swapReturn, _authorisationParams.sellAmount);

    emit PurchaseCompleted(
      _authorisationParams.requestId,
      swapReturn.USDCDelta
    );

    USDCAddress.transfer(IMPTTreasuryAddress, swapReturn.USDCDelta);

    CarbonCreditNFTContract.mint(
      msg.sender,
      _authorisationParams.tokenId,
      _authorisationParams.amount,
      _authorisationParams.signature
    );
  }

  function purchaseWithIMPTWithoutSwap(
    AuthorisationParams calldata _authorisationParams
  ) external whenNotPaused {
    _verifyPurchaseSignature(_authorisationParams);
    IMPTAddress.safeTransferFrom(
      msg.sender,
      IMPTTreasuryAddress,
      _authorisationParams.sellAmount
    );
    emit PurchaseCompleted(
      _authorisationParams.requestId,
      _authorisationParams.sellAmount
    );
    CarbonCreditNFTContract.mint(
      msg.sender,
      _authorisationParams.tokenId,
      _authorisationParams.amount,
      _authorisationParams.signature
    );
  }

  function purchaseSoulboundToken(
    AuthorisationParams memory _authorisationParams,
    string memory _imageURI
  ) external whenNotPaused {
    uint256 tokenId = SoulboundToken.getCurrentTokenId();

    _verifyPurchaseSignature(
      AuthorisationParams({
        requestId: _authorisationParams.requestId,
        expiry: _authorisationParams.expiry,
        sellAmount: _authorisationParams.sellAmount,
        tokenId: tokenId,
        amount: 1,
        signature: _authorisationParams.signature
      })
    );

    IMPTAddress.safeTransferFrom(
      msg.sender,
      IMPTTreasuryAddress,
      _authorisationParams.sellAmount
    );

    SoulboundToken.mint(msg.sender, _imageURI);
    emit SoulboundTokenMinted(msg.sender, tokenId);
  }

  function withdraw(uint256 _amount) external onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    _withdraw(_amount);
  }

  function _withdraw(uint256 _amount) internal {
    IMPTAddress.safeTransfer(
      IMPTTreasuryAddress,
      _amount
    );
  }

  //##########################
  //#### SETTER-FUNCTIONS ####
  function pause()
    external
    override
    onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager)
  {
    _pause();
  }

  function unpause()
    external
    override
    onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager)
  {
    _unpause();
  }

  function setPlatformToken(
    IERC20Upgradeable _implementation
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_implementation));
    IMPTAddress = _implementation;
    emit PlatformTokenChanged(_implementation);
  }

  function setUSDC(
    IERC20Upgradeable _implementation
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_implementation));
    USDCAddress = _implementation;
    emit USDCChanged(_implementation);
  }

  function setWETH(
    IWETH _implementation
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_implementation));
    WETHAddress = _implementation;
    emit WETHChanged(_implementation);
  }

  function addSwapTarget(
    address _implementation
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_implementation));
    AccessManager.grantRole(LibIMPT.IMPT_APPROVED_DEX, _implementation);
    IMPTAddress.approve(_implementation, type(uint256).max);
  }

  function removeSwapTarget(
    address _implementation
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_implementation));
    AccessManager.revokeRole(LibIMPT.IMPT_APPROVED_DEX, _implementation);
    IMPTAddress.approve(_implementation, uint256(0));
  }

  function setIMPTTreasury(
    address _implementation
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(_implementation);
    IMPTTreasuryAddress = _implementation;
    emit LibIMPT.IMPTTreasuryChanged(_implementation);
  }

  function setCarbonCreditNFT(
    ICarbonCreditNFT _carbonCreditNFT
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_carbonCreditNFT));
    CarbonCreditNFTContract = _carbonCreditNFT;
    emit CarbonCreditNFTContractChanged(_carbonCreditNFT);
  }

  function setSoulboundToken(
    ISoulboundToken _soulboundToken
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_soulboundToken));
    SoulboundToken = _soulboundToken;
    emit SoulboundTokenContractChanged(_soulboundToken);
  }
}