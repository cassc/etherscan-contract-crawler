// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.17;
import "./DelegateRegister.sol";
import "./ProxyRegister.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 *
 * @dev The EPS Register contract, implementing the proxy and deligate registers
 *
 */
contract EPSRegister is ProxyRegister, DelegateRegister {
  using SafeERC20 for IERC20;

  // ======================================================
  // VARIABLES
  // ======================================================

  // EPS treasury address:
  address public treasury;

  // Count of active ETH addresses for total supply
  uint256 public activeEthAddresses = 1;

  // 'Air drop' of EPSAPI to every address
  uint256 public epsAPIBalance = 10000;

  error ColdWalletCannotInteractUserHot();
  error EthWithdrawFailed();
  error UnknownAmount();

  /**
   * @dev Constructor initialises the parameters for the proxy and delegate registers.
   */
  constructor(
    uint256 proxyRegisterFee_,
    address treasury_,
    uint96 delegationRegisterFee_,
    uint32 delegationFeePercentage_,
    address weth_,
    uint256 deletionNominalEth_
  )
    ProxyRegister(proxyRegisterFee_, deletionNominalEth_)
    DelegateRegister(delegationRegisterFee_, delegationFeePercentage_, weth_)
  {
    setTreasuryAddress(treasury_);
  }

  // ======================================================
  // VIEW METHODS
  // ======================================================

  /**
   * @dev beneficiaryOf: Returns the beneficiary of the `tokenId` token.
   */
  function beneficiaryOf(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address beneficiary_) {
    // 1 Check for an active delegation. We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }
    beneficiary_ = getBeneficiaryByRight(
      tokenContract_,
      tokenId_,
      rightsIndex_
    );

    if (beneficiary_ == address(0)) {
      // 2 No delegation. Get the owner:
      beneficiary_ = IERC721(tokenContract_).ownerOf(tokenId_);

      // 3 Check if this is a proxied benefit
      if (coldIsLive(beneficiary_)) {
        beneficiary_ = coldToHot[beneficiary_];
      }
    }
  }

  /**
   * @dev beneficiaryBalance: Returns the beneficiary balance of ETH.
   */
  function beneficiaryBalance(address queryAddress_)
    external
    view
    returns (uint256 balance_)
  {
    // Get any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - include the balance
      // held natively by this address and the cold:
      balance_ += queryAddress_.balance;

      balance_ += hotToRecord[queryAddress_].cold.balance;
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += queryAddress_.balance;
      }
    }
  }

  /**
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance for an ERC721, ERC20 or ERC777 contract.
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_) {
    // 1a If this is a delegation container the balance is always 0, as the balance associated
    // will be for the benefit of either the original asset owner or the delegate, depending
    // on the delegation parameters:
    if (containerToDelegationId[queryAddress_] != 0) {
      return (0);
    }

    // 1b We need a concept of a 'senior right', which we have elected to be airdrop rights,
    // being the right of the holder to receive free benefits associated with being a beneficiary.
    // If we are looking for a beneficiary rights index out of bounds default to an airdrop
    // rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    // 2 Get delegated balances:
    balance_ = getBalanceByRight(tokenContract_, queryAddress_, rightsIndex_);

    // 3 Add any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - add on the balances
      // held natively by this address and the cold:
      balance_ += (IERC721(tokenContract_).balanceOf(queryAddress_));

      address cold = hotToRecord[queryAddress_].cold;

      balance_ += IERC721(tokenContract_).balanceOf(cold);
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += IERC721(tokenContract_).balanceOf(queryAddress_);
      }
    }
  }

  /**
   * @dev beneficiaryBalanceOf1155: Returns the beneficiary balance for an ERC1155.
   */
  function beneficiaryBalanceOf1155(
    address queryAddress_,
    address tokenContract_,
    uint256 id_
  ) external view returns (uint256 balance_) {
    // Add any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - add on the balances
      // held natively by this address and the cold:
      balance_ += (IERC1155(tokenContract_).balanceOf(queryAddress_, id_));

      address cold = hotToRecord[queryAddress_].cold;

      balance_ += IERC1155(tokenContract_).balanceOf(cold, id_);
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += IERC1155(tokenContract_).balanceOf(queryAddress_, id_);
      }
    }
  }

  /**
   * @dev getAddresses: Returns the register address details (cold and delivery address) for a passed hot address
   */
  function getAddresses(address _receivedAddress)
    public
    view
    returns (
      address cold,
      address delivery,
      bool isProxied
    )
  {
    if (coldIsLive(_receivedAddress)) revert ColdWalletCannotInteractUserHot();

    if (hotIsLive(_receivedAddress)) {
      return (
        hotToRecord[_receivedAddress].cold,
        hotToRecord[_receivedAddress].delivery,
        true
      );
    } else {
      return (_receivedAddress, _receivedAddress, false);
    }
  }

  // ======================================================
  // ADMIN FUNCTIONS
  // ======================================================
  /**
   * @dev setTreasuryAddress: set the treasury address:
   */
  function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
    treasury = _treasuryAddress;
  }

  /**
   * @dev setActiveEthAddresses: used in the psuedo total supply calc:
   */
  function setNNumberOfEthAddressesAndAirdropAmount(
    uint256 count_,
    uint256 air_
  ) public onlyOwner {
    activeEthAddresses = count_;
    epsAPIBalance = air_;
  }

  /**
   * @dev withdrawETH: withdraw eth to the treasury:
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = treasury.call{value: amount_}("");

    if (!success) revert EthWithdrawFailed();
  }

  /**
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn Note, this is provided to enable the
   * withdrawal of any assets sent here in error
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external onlyOwner {
    token_.safeTransfer(owner(), amount_);
  }

  /**
   * @dev withdrawERC721: Allow any ERC721s to be withdrawn. Note, all delegated ERC721s are in their
   * own contract, NOT on this contract. This is provided to enable the withdrawal of
   * any assets sent here in error using transferFrom not safeTransferFrom.
   */

  function withdrawERC721(IERC721 token_, uint256 tokenId_) external onlyOwner {
    token_.transferFrom(address(this), owner(), tokenId_);
  }

  // ======================================================
  // ETH CALL ENTRY POINT
  // ======================================================

  /**
   *
   * @dev receive: Wallets need never connect directly to add to EPS register, rather they can
   * interact through ETH or ERC20 transfers. This 'air gaps' your wallet(s) from
   * EPS. ETH transfers can be used to pay the fee or delete a record (sent from either
   * the hot or the cold wallet).
   *
   */
  receive() external payable {
    if (
      msg.value != proxyRegisterFee &&
      msg.value != deletionNominalEth &&
      containerToDelegationId[msg.sender] == 0 &&
      msg.sender != owner()
    ) revert UnknownAmount();

    if (msg.value == proxyRegisterFee) {
      _payFee(msg.sender);
    } else if (msg.value == deletionNominalEth) {
      // Either hot or cold requesting a deletion:
      _deleteRecord(msg.sender, 0);
    }
  }

  /**
   * @dev _payFee: process receipt of payment
   */
  function _payFee(address from_) internal {
    // 1) If our from address is a hot address and the proxy is pending payment we
    // can record this as paid and put the record live:
    if (hotToRecord[from_].status == ProxyStatus.PendingPayment) {
      _recordLive(
        from_,
        hotToRecord[from_].cold,
        hotToRecord[from_].delivery,
        hotToRecord[from_].provider
      );
    } else if (
      // 2) If our from address is a cold address and the proxy is pending payment we
      // can record this as paid and put the record live:
      hotToRecord[coldToHot[from_]].status == ProxyStatus.PendingPayment
    ) {
      _recordLive(
        coldToHot[from_],
        from_,
        hotToRecord[coldToHot[from_]].delivery,
        hotToRecord[coldToHot[from_]].provider
      );
    } else revert NoPaymentPendingForAddress();
  }

  // ======================================================
  // ERC20 METHODS (to expose API)
  // ======================================================

  /**
   * @dev Returns the name of the token.
   */
  function name() public pure returns (string memory) {
    return "EPS API";
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public pure returns (string memory) {
    return "EPSAPI";
  }

  function decimals() public pure returns (uint8) {
    return 0;
  }

  function balanceOf(address) public view returns (uint256) {
    return epsAPIBalance;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view returns (uint256) {
    return activeEthAddresses * epsAPIBalance;
  }

  /**
   * @dev Doesn't move tokens at all. There was no spoon and there are no tokens.
   * Rather the quantity being 'sent' denotes the action the user is taking
   * on the EPS register, and the address they are 'sent' to is the address that is
   * being referenced by this request.
   */
  function transfer(address to, uint256 amount) public returns (bool) {
    _tokenAPICall(msg.sender, to, amount);

    return (true);
  }
}