// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../external/IWETH9.sol";
import "./NftToken.sol";

abstract contract SmartCommunityWallet is NftToken {
  enum WithdrawalType {
    REGULAR,
    INACTIVE_FUNDS,
    MINT_FUNDS
  }

  struct TokenData {
    uint256 tokenId;
    address ownerAddress;
    uint64 ownershipStartTimestamp;
    uint256 tokenBalance;
    uint64 ownerLatestActivityTimestamp;
  }

  uint256 public immutable DIAMOND_HANDS_HOLDER_TIME_FRAME;
  uint256 public immutable WHALE_ROLE_THRESHOLD;
  uint256 public immutable ADDRESS_INACTIVITY_TIME_FRAME;
  uint256 public immutable TRANSFER_COOLDOWN_AFTER_WITHDRAWAL;

  IWETH9 public immutable WETH_CONTRACT;

  address public immutable HASHLIPS_LAB_ADDRESS;
  uint256 public immutable HASHLIPS_LAB_MINT_SHARE;
  address public immutable MEP_ADDRESS;

  uint256 public communityBalance = 0;
  uint256 public mintFundsBalance = 0;
  uint256 public totalFundsRaisedByCommunity = 0;

  address public allowedAddressForCustomErc20TokensWithdrawal;

  bool public canUpdateAllowedAddressForCustomErc20TokensWithdrawal = true;

  mapping(uint256 => uint256) public tokenIdToWithdrawnAmount;

  event UntrackedFundsReceived(address indexed from, uint256 amount);
  event Donation(address indexed from, uint256 amount);
  event Withdrawal(WithdrawalType indexed withrawalType, address indexed to, uint256 amount);
  event CustomErc20Withdrawal(address indexed tokenContractAddress, address indexed to, uint256 amount);
  event UpdatedAllowedAddressForCustomErc20TokensWithdrawal(address newAllowedAddress);

  error InsufficientFunds();
  error FailedWithdrawingFunds();
  error TokenOwnershipDoesNotMatch();
  error InvalidDiamondHandsHolderToken();
  error TransferringTooEarlyAfterWithdrawal();
  error InvalidTokenId();
  error OnlyWhalesCanWithdrawOnBehalfOfInactiveAddresses();
  error TokenIsOwnedByAnActiveAddress();
  error CustomErc20TokensWithdrawalDenied();
  error CannotWithdrawWethFundsDirectly();
  error AllowedAddressForCustomErc20TokensWithdrawalIsFrozen();

  constructor(
    uint256 _diamondHandsHolderTimeFrame,
    uint256 _whaleRoleThreshold,
    uint256 _transferCooldownAfterWithdrawal,
    uint256 _addressInactivityTimeFrame,
    address _wethContractAddress,
    uint256 _hashLipsLabMintShare,
    address _hashLipsLabAddress,
    address _mepAddress
  ) {
    DIAMOND_HANDS_HOLDER_TIME_FRAME = _diamondHandsHolderTimeFrame;
    WHALE_ROLE_THRESHOLD = _whaleRoleThreshold;
    TRANSFER_COOLDOWN_AFTER_WITHDRAWAL = _transferCooldownAfterWithdrawal;
    ADDRESS_INACTIVITY_TIME_FRAME = _addressInactivityTimeFrame;

    WETH_CONTRACT = IWETH9(payable(_wethContractAddress));

    HASHLIPS_LAB_MINT_SHARE = _hashLipsLabMintShare;
    HASHLIPS_LAB_ADDRESS = _hashLipsLabAddress;

    MEP_ADDRESS = _mepAddress;

    allowedAddressForCustomErc20TokensWithdrawal = address(0);
  }

  receive() external payable {
    /*
     * Newly received funds are treated as "untracked" until
     * refreshWalletBalance() is run.
     */

     emit UntrackedFundsReceived(msg.sender, msg.value);
  }

  function donate() public payable {
    refreshWalletBalance();

    emit Donation(msg.sender, msg.value);
  }

  function getUntrackedFunds() public view returns (uint256) {
    uint256 rawUntrackedFunds = address(this).balance - communityBalance - mintFundsBalance;

    return rawUntrackedFunds - (rawUntrackedFunds % MAX_SUPPLY);
  }

  function refreshWalletBalance() public {
    _unwrapEth();

    uint256 untrackedFunds = getUntrackedFunds();
    uint256 totalSupply = totalSupply();

    totalFundsRaisedByCommunity += untrackedFunds;

    if (MAX_SUPPLY == totalSupply) {
      communityBalance += untrackedFunds;

      return;
    }

    uint256 communityShare = (untrackedFunds / MAX_SUPPLY) * totalSupply;
    communityBalance += communityShare;
    mintFundsBalance += untrackedFunds - communityShare;
  }

  function getLatestWithdrawalTimestamp(address _owner) public view returns (uint64) {
    return _getAux(_owner);
  }

  function refreshLatestWithdrawalTimestamp() public {
    _setAux(msg.sender, uint64(block.timestamp));
  }

  function getBalanceOfToken(uint256 _tokenId) public view returns (uint256) {
    if (!_exists(_tokenId)) {
      revert InvalidTokenId();
    }

    return _getBalanceOfToken(_tokenId);
  }

  function isDiamondHandsHolder(address _holder, uint256 _diamondHandsHolderTokenId) public view returns (bool) {
    TokenOwnership memory diamondHandsHolderTokenOwnership = _ownershipOf(_diamondHandsHolderTokenId);

    if (diamondHandsHolderTokenOwnership.addr != _holder) {
      revert TokenOwnershipDoesNotMatch();
    }

    if (diamondHandsHolderTokenOwnership.startTimestamp + DIAMOND_HANDS_HOLDER_TIME_FRAME > block.timestamp) {
      return false;
    }

    return true;
  }

  function isWhale(address _holder, uint256 _diamondHandsHolderTokenId) public view returns (bool) {
    return balanceOf(_holder) >= WHALE_ROLE_THRESHOLD && isDiamondHandsHolder(_holder, _diamondHandsHolderTokenId);
  }

  function withdraw(uint256 _diamondHandsHolderTokenId, uint256[] memory _tokenIds) public {
    uint256 withdrawableAmount = 0;

    if (!isDiamondHandsHolder(msg.sender, _diamondHandsHolderTokenId)) {
      revert InvalidDiamondHandsHolderToken();
    }

    refreshLatestWithdrawalTimestamp();

    for (uint16 i = 0; i < _tokenIds.length; i++) {
      if (ownerOf(_tokenIds[i]) != msg.sender) {
        revert TokenOwnershipDoesNotMatch();
      }

      withdrawableAmount += _resetWithdrawableAmount(_tokenIds[i]);
    }

    communityBalance -= withdrawableAmount;

    (bool transferSuccess, ) = payable(msg.sender).call{value: withdrawableAmount}('');

    if (!transferSuccess) {
      revert FailedWithdrawingFunds();
    }

    emit Withdrawal(WithdrawalType.REGULAR, msg.sender, withdrawableAmount);
  }

  function withdrawInactiveFunds(uint256 _diamondHandsHolderTokenId, uint256[] memory _tokenIds) public {
    uint256 withdrawableAmount = 0;

    if (!isWhale(msg.sender, _diamondHandsHolderTokenId)) {
      revert OnlyWhalesCanWithdrawOnBehalfOfInactiveAddresses();
    }

    refreshLatestWithdrawalTimestamp();

    for (uint16 i = 0; i < _tokenIds.length; i++) {
      /*
       * In order to avoid unauthorized withdrawals of new holders' funds we
       * have to make sure that both the latest withdrawal timestamp and the
       * ownership start timestamp are considered when verifying the latest
       * wallet activity.
       */
      uint64 latestWithdrawalTimestamp = getLatestWithdrawalTimestamp(ownerOf(_tokenIds[i]));
      uint64 ownershipStartTimestamp = _ownershipOf(_tokenIds[i]).startTimestamp;
      uint64 latestActivityTimestamp = latestWithdrawalTimestamp > ownershipStartTimestamp ? latestWithdrawalTimestamp : ownershipStartTimestamp;

      if (latestActivityTimestamp + ADDRESS_INACTIVITY_TIME_FRAME > block.timestamp) {
        revert TokenIsOwnedByAnActiveAddress();
      }

      withdrawableAmount += _resetWithdrawableAmount(_tokenIds[i]);
    }

    communityBalance -= withdrawableAmount;

    (bool transferSuccess, ) = payable(msg.sender).call{value: withdrawableAmount}('');

    if (!transferSuccess) {
      revert FailedWithdrawingFunds();
    }

    emit Withdrawal(WithdrawalType.INACTIVE_FUNDS, msg.sender, withdrawableAmount);
  }

  function withdrawMintFunds(uint256 _amount) public onlyOwner {
    if (_amount > mintFundsBalance) {
      revert InsufficientFunds();
    }

    uint256 hashLipsLabAmount = _amount * HASHLIPS_LAB_MINT_SHARE / 100;
    uint256 mepAmount = _amount - hashLipsLabAmount;
    mintFundsBalance -= _amount;

    // HashLips Lab
    // =============================================================================
    (bool transferSuccess, ) = payable(HASHLIPS_LAB_ADDRESS).call{value: hashLipsLabAmount}('');

    if (!transferSuccess) {
      revert FailedWithdrawingFunds();
    }

    emit Withdrawal(WithdrawalType.MINT_FUNDS, HASHLIPS_LAB_ADDRESS, hashLipsLabAmount);
    // =============================================================================

    // MEP
    // =============================================================================
    (transferSuccess, ) = payable(MEP_ADDRESS).call{value: mepAmount}('');

    if (!transferSuccess) {
      revert FailedWithdrawingFunds();
    }

    emit Withdrawal(WithdrawalType.MINT_FUNDS, MEP_ADDRESS, mepAmount);
    // =============================================================================
  }

  function withdrawCustomErc20Funds(address[] memory _erc20TokenAddresses) public {
    if (msg.sender != allowedAddressForCustomErc20TokensWithdrawal) {
      revert CustomErc20TokensWithdrawalDenied();
    }

    for (uint8 i = 0; i < _erc20TokenAddresses.length; i++) {
      address erc20TokenAddress = _erc20TokenAddresses[i];

      if (address(WETH_CONTRACT) == erc20TokenAddress) {
        revert CannotWithdrawWethFundsDirectly();
      }

      IERC20 erc20Token = IERC20(erc20TokenAddress);
      uint256 tokenBalance = erc20Token.balanceOf(address(this));

      if (!erc20Token.transfer(allowedAddressForCustomErc20TokensWithdrawal, tokenBalance)) {
        revert FailedWithdrawingFunds();
      }

      emit CustomErc20Withdrawal(erc20TokenAddress, msg.sender, tokenBalance);
    }
  }

  function updateAllowedAddressForCustomErc20TokensWithdrawal(address _newAllowedAddress) public onlyOwner {
    if (!canUpdateAllowedAddressForCustomErc20TokensWithdrawal) {
      revert AllowedAddressForCustomErc20TokensWithdrawalIsFrozen();
    }

    allowedAddressForCustomErc20TokensWithdrawal = _newAllowedAddress;

    emit UpdatedAllowedAddressForCustomErc20TokensWithdrawal(_newAllowedAddress);
  }

  function freezeAllowedAddressForCustomErc20TokensWithdrawal() public onlyOwner {
    canUpdateAllowedAddressForCustomErc20TokensWithdrawal = false;
  }

  function getTokenData(uint256 _tokenId) public view returns (TokenData memory) {
    TokenOwnership memory ownership = _ownershipOf(_tokenId);

    return TokenData(
      _tokenId,
      ownership.addr,
      ownership.startTimestamp,
      _getBalanceOfToken(_tokenId),
      getLatestWithdrawalTimestamp(ownership.addr)
    );
  }

  function getTokensData(uint256[] memory _tokenIds) public view returns (TokenData[] memory) {
    TokenData[] memory tokensData = new TokenData[](_tokenIds.length);

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokensData[i] = getTokenData(_tokenIds[i]);
    }

    return tokensData;
  }

  function getTokensDataInRange(uint256 _startId, uint256 _stopId) public view returns (TokenData[] memory) {
    if (_startId < _startTokenId() || _stopId > totalSupply() || _startId > _stopId) {
      revert InvalidQueryRange();
    }

    _stopId++;

    TokenData[] memory tokensData = new TokenData[](_stopId - _startId);

    for (uint256 i = _startId; i < _stopId; i++) {
      tokensData[i - _startId] = getTokenData(i);
    }

    return tokensData;
  }

  function _getBalanceOfToken(uint256 _tokenId) internal view returns (uint256) {
    return (totalFundsRaisedByCommunity / MAX_SUPPLY) - tokenIdToWithdrawnAmount[_tokenId];
  }

  function _unwrapEth() private {
    uint256 wEthBalance = WETH_CONTRACT.balanceOf(address(this));

    if (wEthBalance != 0) {
      WETH_CONTRACT.withdraw(wEthBalance);
    }
  }

  function _resetWithdrawableAmount(uint256 _tokenId) internal returns (uint256) {
    uint256 withdrawableAmount = _getBalanceOfToken(_tokenId);

    tokenIdToWithdrawnAmount[_tokenId] += withdrawableAmount;

    return withdrawableAmount;
  }

  function _beforeMint(uint256 _startTokenId, uint256 _quantity) internal override {
    refreshWalletBalance();

    uint256 stopId = _startTokenId + _quantity;

    // Withdrawn funds of new tokens must be reset at mint
    for (uint256 i = _startTokenId; i < stopId; i++) {
      _resetWithdrawableAmount(i);
    }

    return;
  }

  function _beforeTokenTransfers(
    address _from,
    address /* _to */,
    uint256 /* _startTokenId */,
    uint256 /* _quantity */
  ) internal view override {
    if (getLatestWithdrawalTimestamp(_from) + TRANSFER_COOLDOWN_AFTER_WITHDRAWAL > block.timestamp) {
      revert TransferringTooEarlyAfterWithdrawal();
    }
  }
}