pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITokenSaleCreator.sol";
import "./helpers/TransferHelper.sol";

contract TokenSaleCreator is ReentrancyGuard, Pausable, Ownable, AccessControl, ITokenSaleCreator {
  using Address for address;
  using SafeMath for uint256;

  bytes32[] public allTokenSales;
  bytes32 public pauserRole = keccak256(abi.encodePacked("PAUSER_ROLE"));
  bytes32 public withdrawerRole = keccak256(abi.encodePacked("WITHDRAWER_ROLE"));
  bytes32 public finalizerRole = keccak256(abi.encodePacked("FINALIZER_ROLE"));
  uint256 public withdrawable;

  uint8 public feePercentage;
  uint256 public saleCreationFee;

  mapping(bytes32 => TokenSaleItem) private tokenSales;
  mapping(bytes32 => uint256) private totalEtherRaised;
  mapping(bytes32 => mapping(address => bool)) private isNotAllowedToContribute;
  mapping(bytes32 => mapping(address => uint256)) public amountContributed;
  mapping(bytes32 => mapping(address => uint256)) public balance;

  modifier whenParamsSatisfied(bytes32 saleId) {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(!tokenSale.interrupted, "token_sale_paused");
    require(block.timestamp >= tokenSale.saleStartTime, "token_sale_not_started_yet");
    require(!tokenSale.ended, "token_sale_has_ended");
    require(!isNotAllowedToContribute[saleId][_msgSender()], "you_are_not_allowed_to_participate_in_this_sale");
    require(totalEtherRaised[saleId] < tokenSale.hardCap, "hardcap_reached");
    _;
  }

  constructor(uint8 _feePercentage, uint256 _saleCreationFee) {
    _grantRole(pauserRole, _msgSender());
    _grantRole(withdrawerRole, _msgSender());
    _grantRole(finalizerRole, _msgSender());
    feePercentage = _feePercentage;
    saleCreationFee = _saleCreationFee;
  }

  function initTokenSale(
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 daysToLast,
    address proceedsTo,
    address admin
  ) external payable whenNotPaused nonReentrant returns (bytes32 saleId) {
    {
      require(msg.value >= saleCreationFee, "fee");
      require(token.isContract(), "must_be_contract_address");
      require(saleStartTime > block.timestamp && saleStartTime.sub(block.timestamp) >= 24 hours, "sale_must_begin_in_at_least_24_hours");
      require(IERC20(token).allowance(_msgSender(), address(this)) >= tokensForSale, "not_enough_allowance_given");
      TransferHelpers._safeTransferFromERC20(token, _msgSender(), address(this), tokensForSale);
    }
    saleId = keccak256(
      abi.encodePacked(
        token,
        _msgSender(),
        block.timestamp,
        tokensForSale,
        hardCap,
        softCap,
        presaleRate,
        minContributionEther,
        maxContributionEther,
        saleStartTime,
        daysToLast,
        proceedsTo
      )
    );
    // Added to prevent 'stack too deep' error
    uint256 endTime;
    {
      endTime = saleStartTime.add(daysToLast.mul(1 days));
      tokenSales[saleId] = TokenSaleItem(
        token,
        tokensForSale,
        hardCap,
        softCap,
        presaleRate,
        saleId,
        minContributionEther,
        maxContributionEther,
        saleStartTime,
        endTime,
        false,
        proceedsTo,
        admin,
        tokensForSale,
        false
      );
    }
    allTokenSales.push(saleId);
    withdrawable = msg.value;
    emit TokenSaleItemCreated(
      saleId,
      token,
      tokensForSale,
      hardCap,
      softCap,
      presaleRate,
      minContributionEther,
      maxContributionEther,
      saleStartTime,
      endTime,
      proceedsTo,
      admin
    );
  }

  function contribute(bytes32 saleId) external payable whenNotPaused nonReentrant whenParamsSatisfied(saleId) {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(
      msg.value >= tokenSaleItem.minContributionEther && msg.value <= tokenSaleItem.maxContributionEther,
      "contribution_must_be_within_min_and_max_range"
    );
    uint256 val = tokenSaleItem.presaleRate.mul(msg.value).div(1 ether);
    require(tokenSaleItem.availableTokens >= val, "tokens_available_for_sale_is_less");
    balance[saleId][_msgSender()] = balance[saleId][_msgSender()].add(val);
    amountContributed[saleId][_msgSender()] = amountContributed[saleId][_msgSender()].add(msg.value);
    totalEtherRaised[saleId] = totalEtherRaised[saleId].add(msg.value);
    tokenSaleItem.availableTokens = tokenSaleItem.availableTokens.sub(val);
  }

  function normalWithdrawal(bytes32 saleId) external whenNotPaused nonReentrant {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(tokenSaleItem.ended || block.timestamp >= tokenSaleItem.saleEndTime, "sale_has_not_ended");
    TransferHelpers._safeTransferERC20(tokenSaleItem.token, _msgSender(), balance[saleId][_msgSender()]);
    delete balance[saleId][_msgSender()];
  }

  function emergencyWithdrawal(bytes32 saleId) external nonReentrant {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(!tokenSaleItem.ended, "sale_has_already_ended");
    TransferHelpers._safeTransferEther(_msgSender(), amountContributed[saleId][_msgSender()]);
    tokenSaleItem.availableTokens = tokenSaleItem.availableTokens.add(balance[saleId][_msgSender()]);
    totalEtherRaised[saleId] = totalEtherRaised[saleId].sub(amountContributed[saleId][_msgSender()]);
    delete balance[saleId][_msgSender()];
    delete amountContributed[saleId][_msgSender()];
  }

  function interruptTokenSale(bytes32 saleId) external whenNotPaused onlyOwner {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    require(!tokenSale.ended, "token_sale_has_ended");
    tokenSale.interrupted = true;
  }

  function uninterruptTokenSale(bytes32 saleId) external whenNotPaused onlyOwner {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    tokenSale.interrupted = false;
  }

  function finalizeTokenSale(bytes32 saleId) external whenNotPaused {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    require(hasRole(finalizerRole, _msgSender()) || tokenSale.admin == _msgSender(), "only_finalizer_or_admin");
    require(!tokenSale.ended, "sale_has_ended");
    uint256 launchpadProfit = (totalEtherRaised[saleId] * uint256(feePercentage)).div(100);
    TransferHelpers._safeTransferEther(tokenSale.proceedsTo, totalEtherRaised[saleId].sub(launchpadProfit));
    withdrawable = withdrawable.add(launchpadProfit);

    if (tokenSale.availableTokens > 0) {
      TransferHelpers._safeTransferERC20(tokenSale.token, tokenSale.proceedsTo, tokenSale.availableTokens);
    }

    tokenSale.ended = true;
  }

  function barFromParticiption(bytes32 saleId, address account) external {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(tokenSale.admin == _msgSender(), "only_admin");
    require(!tokenSale.ended, "sale_has_ended");
    require(!isNotAllowedToContribute[saleId][account], "already_barred");
    isNotAllowedToContribute[saleId][account] = true;
  }

  function rescindBar(bytes32 saleId, address account) external {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(tokenSale.admin == _msgSender(), "only_admin");
    require(!tokenSale.ended, "sale_has_ended");
    require(isNotAllowedToContribute[saleId][account], "not_barred");
    isNotAllowedToContribute[saleId][account] = false;
  }

  function pause() external whenNotPaused {
    require(hasRole(pauserRole, _msgSender()), "must_have_pauser_role");
    _pause();
  }

  function unpause() external whenPaused {
    require(hasRole(pauserRole, _msgSender()), "must_have_pauser_role");
    _unpause();
  }

  function getTotalEtherRaisedForSale(bytes32 saleId) external view returns (uint256) {
    return totalEtherRaised[saleId];
  }

  function getExpectedEtherRaiseForSale(bytes32 saleId) external view returns (uint256) {
    TokenSaleItem memory tokenSaleItem = tokenSales[saleId];
    return tokenSaleItem.hardCap;
  }

  function getSoftCap(bytes32 saleId) external view returns (uint256) {
    TokenSaleItem memory tokenSaleItem = tokenSales[saleId];
    return tokenSaleItem.softCap;
  }

  function withdrawProfit(address to) external {
    require(hasRole(withdrawerRole, _msgSender()) || _msgSender() == owner(), "only_withdrawer_or_owner");
    TransferHelpers._safeTransferEther(to, withdrawable);
    withdrawable = 0;
  }

  function setFeePercentage(uint8 _feePercentage) external onlyOwner {
    feePercentage = _feePercentage;
  }

  function setSaleCreationFee(uint256 _saleCreationFee) external onlyOwner {
    saleCreationFee = _saleCreationFee;
  }

  receive() external payable {
    withdrawable = withdrawable.add(msg.value);
  }
}