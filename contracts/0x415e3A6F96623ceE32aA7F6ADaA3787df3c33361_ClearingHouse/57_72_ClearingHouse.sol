// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ERC20Singleton.sol";
import "./Governor.sol";
import "./DonationsRouter.sol";
import "./StakingRewards.sol";
import "../interfaces/IClearingHouse.sol";
import "../library/SigRecovery.sol";

contract ClearingHouse is IClearingHouse, Ownable, Pausable {
  using SafeERC20 for ERC20;
  /*///////////////////////////////////////////////////////////////
                            STATE
  //////////////////////////////////////////////////////////////*/

  mapping(ERC20Singleton => CauseInformation) public causeInformation;

  // Mapping from CauseID to a mapping from KYC to the amount that user has withdrawn
  mapping(uint256 => mapping(bytes => uint256)) claimableAmount;

  // Mapping from CauseID to the maximum amount that a user can withdra
  mapping(uint256 => uint256) maxAmount;

  // Mapping from Cause ID to KYC ID to amount withdrawn
  mapping(uint256 => mapping(bytes => uint256)) withdrawnAmount;

  ERC20 public immutable earthToken;

  Governor public governor;

  DonationsRouter public donationsRouter;

  StakingRewards public staking;

  constructor(
    ERC20 _earthToken,
    StakingRewards _staking,
    address _owner
  ) {
    require(address(_earthToken) != address(0), "invalid earth token address");

    require(address(_staking) != address(0), "invalid staking address");

    earthToken = _earthToken;

    staking = _staking;

    _transferOwnership(_owner);
  }

  /*///////////////////////////////////////////////////////////////
                          MODIFIERS
  //////////////////////////////////////////////////////////////*/

  modifier isGovernorSet() {
    require(address(governor) != address(0), "governor not set");
    _;
  }

  modifier isGovernor() {
    require(msg.sender == address(governor), "caller is not the governor");
    _;
  }

  modifier isDonationsRouterSet() {
    require(
      address(donationsRouter) != address(0),
      "donations router is not set"
    );
    _;
  }

  modifier isChildDaoRegistered(ERC20Singleton _childDaoToken) {
    require(
      causeInformation[_childDaoToken].childDaoRegistry,
      "invalid child dao address"
    );
    _;
  }

  modifier checkInvariants(ERC20Singleton _childDaoToken, uint256 _amount) {
    require(
      _childDaoToken.totalSupply() + _amount <=
        causeInformation[_childDaoToken].maxSupply,
      "exceeds max supply"
    );
    if (msg.sender != owner()) {
      require(
        _amount <= causeInformation[_childDaoToken].maxSwap,
        "exceeds max swap per tx"
      );
    }
    _;
  }

  /*///////////////////////////////////////////////////////////////
                          SUPPLY LOGIC
  //////////////////////////////////////////////////////////////*/

  function setMaxSupply(uint256 _maxSupply, ERC20Singleton _token)
    external
    override
    whenNotPaused
    isDonationsRouterSet
  {
    checkIfCauseOwner(_token);
    causeInformation[_token].maxSupply = _maxSupply;
    emit MaxSupplySet(_maxSupply, _token);
  }

  function setMaxSwap(uint256 _maxSwap, ERC20Singleton _token)
    external
    override
    whenNotPaused
    isDonationsRouterSet
  {
    checkIfCauseOwner(_token);
    causeInformation[_token].maxSwap = _maxSwap;
    emit MaxSwapSet(_maxSwap, _token);
  }

  /*///////////////////////////////////////////////////////////////
                          REGISTER LOGIC
  //////////////////////////////////////////////////////////////*/

  function addGovernor(Governor _governor) external whenNotPaused onlyOwner {
    governor = _governor;
  }

  function addDonationsRouter(DonationsRouter _donationsRouter)
    external
    whenNotPaused
    onlyOwner
  {
    donationsRouter = _donationsRouter;
  }

  function registerChildDao(
    ERC20Singleton _childDaoToken,
    bool _autoStaking,
    bool _kycEnabled,
    uint256 _maxSupply,
    uint256 _maxSwap,
    uint256 _release
  ) external whenNotPaused isGovernorSet isGovernor {
    require(
      address(_childDaoToken) != address(earthToken),
      "cannot register 1Earth token"
    );

    require(
      _childDaoToken.owner() == address(this),
      "token not owned by contract"
    );

    require(
      causeInformation[_childDaoToken].childDaoRegistry == false,
      "child dao already registered"
    );

    require(_maxSupply != 0, "max supply cannot be 0");

    require(_maxSwap != 0, "max swap cannot be 0");

    _childDaoToken.approve(address(staking), type(uint256).max);

    causeInformation[_childDaoToken].childDaoRegistry = true;

    if (_release != 0) causeInformation[_childDaoToken].release = _release;
    causeInformation[_childDaoToken].maxSupply = _maxSupply;
    causeInformation[_childDaoToken].maxSwap = _maxSwap;
    if (_autoStaking) causeInformation[_childDaoToken].autoStaking = true;
    if (_kycEnabled) causeInformation[_childDaoToken].kycEnabled = true;

    emit ChildDaoRegistered(address(_childDaoToken));
  }

  /*///////////////////////////////////////////////////////////////
                          STAKING LOGIC
    //////////////////////////////////////////////////////////////*/

  function checkIfCauseOwner(ERC20Singleton _token) internal {
    (address causeOwner, , , ) = donationsRouter.causeRecords(
      donationsRouter.tokenCauseIds(address(_token))
    );
    require(msg.sender == causeOwner, "sender not owner");
  }

  function setAutoStake(ERC20Singleton _token, bool _state)
    external
    isDonationsRouterSet
  {
    checkIfCauseOwner(_token);
    causeInformation[_token].autoStaking = _state;
  }

  function setKYCEnabled(ERC20Singleton _token, bool _state)
    external
    isDonationsRouterSet
  {
    checkIfCauseOwner(_token);
    causeInformation[_token].kycEnabled = _state;
  }

  function setStaking(StakingRewards _staking) external onlyOwner {
    require(address(_staking) != address(0), "invalid staking address");

    staking = _staking;
  }

  /*///////////////////////////////////////////////////////////////
                            SWAP LOGIC
   //////////////////////////////////////////////////////////////*/

  function swapEarthForChildDao(
    ERC20Singleton _childDaoToken,
    uint256 _amount,
    bytes memory _KYCId,
    uint256 _expiry,
    bytes memory _signature
  )
    external
    whenNotPaused
    isChildDaoRegistered(_childDaoToken)
    checkInvariants(_childDaoToken, _amount)
  {
    require(
      block.timestamp > causeInformation[_childDaoToken].release,
      "cause release has not passed"
    );
    require(
      earthToken.balanceOf(msg.sender) >= _amount,
      "not enough 1Earth tokens"
    );
    uint256 causeId = donationsRouter.tokenCauseIds(address(_childDaoToken));
    CauseInformation memory cause = causeInformation[_childDaoToken];
    if (cause.kycEnabled) {
      if (block.timestamp > _expiry && _expiry != 0) revert ApprovalExpired();
      if (
        SigRecovery.recoverApproval(
          _KYCId,
          msg.sender,
          causeId,
          _expiry,
          _signature
        ) != owner()
      ) revert InvalidSignature();
      if ((withdrawnAmount[causeId][_KYCId] + _amount) > cause.maxSwap) {
        revert UserAmountExceeded();
      }
    }

    withdrawnAmount[causeId][_KYCId] += _amount;
    // transfer 1Earth from msg sender to this contract
    uint256 earthBalanceBefore = earthToken.balanceOf(address(this));

    earthToken.safeTransferFrom(msg.sender, address(this), _amount);

    require(
      earthBalanceBefore + _amount == earthToken.balanceOf(address(this)),
      "1Earth token transfer failed"
    );

    ERC20Singleton childDaoToken = _childDaoToken;

    uint256 childDaoTotalSupplyBefore = childDaoToken.totalSupply();

    if (causeInformation[_childDaoToken].autoStaking) {
      // mint child dao tokens to this contract
      childDaoToken.mint(address(this), _amount);

      staking.stakeOnBehalf(msg.sender, address(_childDaoToken), _amount);
    } else {
      // mint child dao tokens to the msg sender
      childDaoToken.mint(msg.sender, _amount);
    }

    require(
      childDaoTotalSupplyBefore + _amount == childDaoToken.totalSupply(),
      "child dao token mint error"
    );

    emit TokensSwapped(
      address(earthToken),
      address(childDaoToken),
      _amount,
      causeInformation[childDaoToken].autoStaking
    );
  }

  function swapChildDaoForEarth(ERC20Singleton _childDaoToken, uint256 _amount)
    external
    whenNotPaused
    isChildDaoRegistered(_childDaoToken)
  {
    ERC20Singleton childDaoToken = _childDaoToken;

    require(
      childDaoToken.balanceOf(msg.sender) >= _amount,
      "not enough child dao tokens"
    );

    // transfer 1Earth from this contract to the msg sender
    uint256 earthBalanceBefore = earthToken.balanceOf(address(this));

    earthToken.safeTransfer(msg.sender, _amount);

    require(
      earthBalanceBefore - _amount == earthToken.balanceOf(address(this)),
      "1Earth token transfer failed"
    );

    // burn msg sender's child dao tokens
    uint256 childDaoTotalSupplyBefore = childDaoToken.totalSupply();

    childDaoToken.burn(msg.sender, _amount);

    require(
      childDaoTotalSupplyBefore - _amount == childDaoToken.totalSupply(),
      "child dao token burn error"
    );

    emit TokensSwapped(
      address(childDaoToken),
      address(earthToken),
      _amount,
      false
    );
  }

  function swapChildDaoForChildDao(
    ERC20Singleton _fromChildDaoToken,
    ERC20Singleton _toChildDaoToken,
    uint256 _amount
  )
    external
    whenNotPaused
    isChildDaoRegistered(_fromChildDaoToken)
    isChildDaoRegistered(_toChildDaoToken)
    checkInvariants(_toChildDaoToken, _amount)
  {
    require(
      _fromChildDaoToken != _toChildDaoToken,
      "cannot swap the same token"
    );

    ERC20Singleton fromChildDaoToken = _fromChildDaoToken;

    ERC20Singleton toChildDaoToken = _toChildDaoToken;

    require(
      fromChildDaoToken.balanceOf(msg.sender) >= _amount,
      "not enough child dao tokens"
    );

    // burn msg sender's from child dao tokens
    uint256 fromChildDaoBalanceBefore = fromChildDaoToken.balanceOf(msg.sender);

    fromChildDaoToken.burn(msg.sender, _amount);

    require(
      fromChildDaoBalanceBefore - _amount ==
        fromChildDaoToken.balanceOf(msg.sender),
      "child dao token burn error"
    );

    // mint to child dao tokens to the msg sender
    uint256 toChildDaoBalanceBefore = toChildDaoToken.balanceOf(msg.sender);

    toChildDaoToken.mint(msg.sender, _amount);

    require(
      toChildDaoBalanceBefore + _amount ==
        toChildDaoToken.balanceOf(msg.sender),
      "child dao token mint error"
    );

    emit TokensSwapped(
      address(fromChildDaoToken),
      address(toChildDaoToken),
      _amount,
      causeInformation[toChildDaoToken].autoStaking
    );
  }

  /*///////////////////////////////////////////////////////////////
                            PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}