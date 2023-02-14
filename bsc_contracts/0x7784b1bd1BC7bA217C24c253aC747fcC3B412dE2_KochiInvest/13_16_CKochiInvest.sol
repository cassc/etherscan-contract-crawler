// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// openzeppelin contracts
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// IKochiInvest
import "../interfaces/IKochiInvest.sol";
import "../libraries/LTransfers.sol";
import "./CVerifySignature.sol";

// Lock and Vesting. (TODO: can be optimized to interfaces for lower creation gas fees, even though the optimizer does a pretty good job at removing unused code)
import "../interfaces/IKochiLock.sol";
import "../interfaces/IKochiVest.sol";

// hardhat tools
// DEV ENVIRONMENT ONLY
import "hardhat/console.sol";

// This contract allows clients  and manage presale and fairlaunch sales.
contract KochiInvest is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IKochiInvest, Verifiable {
  // constants
  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

  // fees
  uint256 public presaleBuyFee; // buy fee is in per 1000 (123 is 12.3%)
  uint256 public creationFee; // in tokens
  address public feeToken; // token addr
  address public feeWallet; // fee wallet is a gnosis multisig

  // lock & vest utilities
  IKochiLock private lockContract;
  IKochiVest private vestingContract;

  // variables
  mapping(uint256 => SPresale) presales;
  mapping(uint256 => mapping(address => mapping(EUserMetadata => uint256))) userMetadata;
  mapping(uint256 => mapping(address => address)) userReferrer;
  mapping(uint256 => mapping(EPresaleMetadata => uint256)) presaleMetadata;

  // upgradable gap
  uint256[50] private _gap;

  // constructor
  function initialize(
    uint256 presale_buying_fee,
    uint256 presale_creation_fee,
    address fees_wallet,
    address fees_token,
    address expected_signer,
    address lock_contract,
    address vesting_contract
  ) external initializer {
    presaleBuyFee = presale_buying_fee;
    creationFee = presale_creation_fee;
    feeWallet = fees_wallet;
    feeToken = fees_token;
    signer = expected_signer;
    lockContract = IKochiLock(lock_contract);
    vestingContract = IKochiVest(vesting_contract);

    __Context_init();
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
  }

  //////////////////////////////////////////////////////////////////////////////
  // Launchpad Creation
  //////////////////////////////////////////////////////////////////////////////

  // the presale creation is quite intensive for the local stack, so we use a struct to pass the data around
  // without this workaround, the stack would be too deep.
  struct SCreateLaunchpadParameters {
    SSecurity security_verification;
    uint256 _id;
    EPresaleType presale_type;
    address user_token;
    address buy_token;
    uint256 referral_tokens;
    uint256 soft_cap;
    uint256 hard_cap;
    uint256 total_tokens;
    uint256 lp_tokens;
    uint256 lp_per_mille;
    uint256 lp_locked_per_mille;
    uint256 lp_unlock_ts;
    uint256 total_vested;
    uint256 vested_deadline;
    string dex;
    bool base_currency;
    bool burn_after_sale;
  }

  function createLaunchpad(IKochiInvest.SVerify memory verification) external override verify(verification) whenNotPaused {
    SCreateLaunchpadParameters memory parameters = abi.decode(verification.encoded_message, (SCreateLaunchpadParameters));
    checkMessageValidity(EOPCode.CREATE, parameters.security_verification);

    if (parameters.presale_type == EPresaleType.fairlaunch) require(parameters.soft_cap > 0);
    else require(parameters.soft_cap > 0 && parameters.hard_cap > 0 && parameters.soft_cap <= parameters.hard_cap, "ERROR: SoftCap or HardCap are not valid");

    // should not overflow, safe.
    uint256 required_amount = parameters.total_tokens + parameters.referral_tokens + parameters.total_vested + parameters.lp_tokens;

    // check the userToken and buyToken are different, and valid IERC20 tokens
    require(parameters.user_token != parameters.buy_token, "ERROR: userToken and buyToken must be different");
    require(IERC20(parameters.user_token).balanceOf(_msgSender()) >= required_amount, "ERROR: you must hold the required amount of your tokens");
    require(IERC20(parameters.user_token).allowance(_msgSender(), address(this)) >= required_amount, "ERROR: userToken must be approved"); // CKI-05
    require(presaleMetadata[parameters._id][EPresaleMetadata.finished] == 0, "ERROR: this presale has already finished");

    // create the launchpad struct, and add it to the datamapping

    SPresale memory launchpad = SPresale(
      parameters._id,
      parameters.presale_type,
      _msgSender(),
      parameters.user_token,
      parameters.buy_token,
      parameters.soft_cap,
      parameters.presale_type == EPresaleType.fairlaunch ? 0 : parameters.hard_cap,
      parameters.referral_tokens,
      parameters.total_tokens,
      parameters.lp_tokens,
      parameters.lp_per_mille,
      parameters.lp_locked_per_mille,
      parameters.lp_unlock_ts,
      parameters.total_vested,
      parameters.vested_deadline,
      parameters.dex,
      parameters.base_currency,
      parameters.burn_after_sale
    );
    presales[parameters._id] = launchpad;

    // pay the presale creation fee
    require(IERC20(feeToken).balanceOf(_msgSender()) >= creationFee, "ERROR: you don't have enough tokens to pay the fee (presale creation fee)");
    require(IERC20(feeToken).allowance(_msgSender(), address(this)) >= creationFee, "ERROR: tokens must be approved (presale creation fee)");
    if (creationFee != 0) LTransfers.internalTransferFrom(_msgSender(), feeWallet, creationFee, IERC20(feeToken));

    uint256 user_tokens_before_transaction = IERC20(parameters.user_token).balanceOf(address(this)); // CKI-03

    // transfer the userToken to the contract for the presale
    LTransfers.internalTransferFrom(_msgSender(), address(this), required_amount, IERC20(parameters.user_token));

    // is deflationary token ?
    // the user is supposed to have whitelisted the contract before creating the presale. If the whitelist is removed or activated later down the line, this contract will have issues. the responsability is on the user.
    require(
      IERC20(parameters.user_token).balanceOf(address(this)) == required_amount + user_tokens_before_transaction,
      "ERROR: Looks like your token may be deflationary, taxed, or otherwise not compatible with this contract. Please whitelist your token with us and try again." // CKI-03
    );

    // emit the event
    emit SaleCreated(parameters._id);
  }

  //////////////////////////////////////////////////////////////////////////////
  // buy presale
  //////////////////////////////////////////////////////////////////////////////

  function buy(uint256 amount, IKochiInvest.SVerify memory verification) external payable override verify(verification) nonReentrant whenNotPaused {
    // abi.decode message (uint256 min, uint256 max, uint256 ttl)
    (SSecurity memory security_verification, uint256 id, uint256 min, uint256 max, uint256 conversion) = abi.decode(verification.encoded_message, (SSecurity, uint256, uint256, uint256, uint256));
    checkMessageValidity(EOPCode.BUY, security_verification);

    // should be overflow safe.
    uint256 current_investment = userMetadata[id][_msgSender()][EUserMetadata.invested] + amount;

    // require(block.number <= ttl, "this signature has expired.");
    require(amount >= min, "ERROR: this transaction is too small.");
    require(current_investment <= max, "ERROR: this transaction would exceed the maximum amount you are authorized to buy.");
    require(presaleMetadata[id][EPresaleMetadata.finished] == 0, "ERROR: this presale has already finished");
    require(presaleMetadata[id][EPresaleMetadata.total_claimed] == 0, "the claiming has already started"); // CKI-01

    // overflow is hard but not impossible in this case.
    uint256 tokens = amount * conversion;

    if (presales[id].presale_type != EPresaleType.fairlaunch) // modify the presale & user metadata
    {
      // amount is safe, tokens could not be overflowing.
      require(amount + presaleMetadata[id][EPresaleMetadata.total_invested] <= presales[id].hard_cap, "ERROR: this presale would exceed the hard cap.");
      require(tokens + presaleMetadata[id][EPresaleMetadata.total_tokens] <= presales[id].total_tokens, "ERROR: this presale would exceed the total tokens allowed");
      userMetadata[id][_msgSender()][EUserMetadata.tokens] += tokens;
      presaleMetadata[id][EPresaleMetadata.total_tokens] += tokens;
    }
    userMetadata[id][_msgSender()][EUserMetadata.invested] = current_investment;
    presaleMetadata[id][EPresaleMetadata.total_invested] += amount;

    // pay the transaction
    if (presales[id].base_currency) require(amount == msg.value, "ERROR: this transaction is not the same as the amount parameter");
    else LTransfers.internalTransferFrom(_msgSender(), address(this), amount, IERC20(presales[id].buy_token));

    // emit the event
    emit UserBuy(id, _msgSender(), amount, tokens);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Claiming functions
  //////////////////////////////////////////////////////////////////////////////

  function claim(IKochiInvest.SVerify memory verification) external override nonReentrant verify(verification) {
    (SSecurity memory security_verification, uint256 id, bool stale) = abi.decode(verification.encoded_message, (SSecurity, uint256, bool));
    checkMessageValidity(EOPCode.CLAIM, security_verification);

    uint256 invested = userMetadata[id][_msgSender()][EUserMetadata.invested];
    require(userMetadata[id][_msgSender()][EUserMetadata.invested] > 0, "ERROR: you haven't invested in this presale");

    if (stale || presaleMetadata[id][EPresaleMetadata.stale] == 1) {
      require(userMetadata[id][_msgSender()][EUserMetadata.claimed] == 0, "ERROR: you have already claimed your tokens");

      // reset the tokens bought by the user
      presaleMetadata[id][EPresaleMetadata.total_invested] -= invested;
      presaleMetadata[id][EPresaleMetadata.total_tokens] -= userMetadata[id][_msgSender()][EUserMetadata.tokens];
      userMetadata[id][_msgSender()][EUserMetadata.invested] = 0;
      userMetadata[id][_msgSender()][EUserMetadata.tokens] = 0;

      // send the tokens
      if (presales[id].base_currency) LTransfers.internalTransferToETH(_msgSender(), invested);
      else LTransfers.internalTransferTo(_msgSender(), invested, IERC20(presales[id].buy_token));

      return;
    }

    require(presaleMetadata[id][EPresaleMetadata.total_invested] >= presales[id].soft_cap, "ERROR: the softcap has not been reached");
    require(presaleMetadata[id][EPresaleMetadata.finished] == 1, "ERROR: the presale has not finished yet");

    uint256 tokens = 0;

    // fairlaunch: total_tokens * (invested / total invested)
    if (presales[id].presale_type == EPresaleType.fairlaunch) tokens = (presales[id].total_tokens * invested) / presaleMetadata[id][EPresaleMetadata.total_invested]; // CKI-02

    // normal launch: tokens bought by the user
    if (presales[id].presale_type == EPresaleType.launchpad) tokens = userMetadata[id][_msgSender()][EUserMetadata.tokens];

    // possibility for future improvements ?
    // if (presales[id].presale_type == EPresaleType.dutchauction) ?

    // referral forumla = (total_referrals_tokens * user_number_of_referrals / total_number_of_referrals)
    // this is seperated to prevent division by zero
    if (userMetadata[id][_msgSender()][EUserMetadata.referrals] > 0)
      tokens += (presales[id].referral_tokens * userMetadata[id][_msgSender()][EUserMetadata.referrals]) / presaleMetadata[id][EPresaleMetadata.total_referrals];

    tokens -= userMetadata[id][_msgSender()][EUserMetadata.claimed];

    require(tokens > 0, "you have no tokens to claim.");

    // setup the metadata, should be overflow-safe.
    userMetadata[id][_msgSender()][EUserMetadata.claimed] += tokens;
    presaleMetadata[id][EPresaleMetadata.total_claimed] += tokens;

    // send the tokens
    LTransfers.internalTransferTo(_msgSender(), tokens, IERC20(presales[id].user_token));

    // emit the event
    emit UserClaim(id, _msgSender(), userMetadata[id][_msgSender()][EUserMetadata.tokens]);
  }

  function ownerClaim(IKochiInvest.SVerify memory verification) external override nonReentrant verify(verification) {
    (SSecurity memory security_verification, uint256 id) = abi.decode(verification.encoded_message, (SSecurity, uint256));
    checkMessageValidity(EOPCode.OWNER_CLAIM, security_verification);

    require(_msgSender() == presales[id].owner, "you are not the owner of this presale");
    require(presaleMetadata[id][EPresaleMetadata.total_invested] > 0, "there are no tokens to claim");
    require(presaleMetadata[id][EPresaleMetadata.total_invested] >= presales[id].soft_cap, "the softcap has not been reached");
    require(presaleMetadata[id][EPresaleMetadata.finished] == 0, "this presale has already finished");

    require(presaleMetadata[id][EPresaleMetadata.total_tokens] > 0 || presales[id].presale_type == EPresaleType.fairlaunch, "there are no tokens to claim");

    // set the presale to finished, prevents complex reentrency.
    presaleMetadata[id][EPresaleMetadata.finished] = 1;

    // calculate tax and remainder tokens
    uint256 tax = (presaleBuyFee * presaleMetadata[id][EPresaleMetadata.total_invested]) / 1000;
    uint256 tokens = presaleMetadata[id][EPresaleMetadata.total_invested] - tax;

    // send the tax tokens
    if (presales[id].base_currency) {
      bool sent = false;
      (sent, ) = feeWallet.call{value: tax}("");
      require(sent, "Failed to send Ether");
    } else LTransfers.internalTransferTo(feeWallet, tax, IERC20(presales[id].buy_token));

    uint256 to_lp = (presales[id].lp_per_mille * tokens) / 1000;

    // lock the tokens. (the locking contract creates the pool, and send back the inverse of "lp_lock_per_mille" to the owner)
    IERC20(presales[id].user_token).approve(address(lockContract), presales[id].lp_tokens);
    if (presales[id].base_currency)
      lockContract.lpLockETH{value: to_lp}(presales[id].user_token, presales[id].lp_tokens, presales[id].lp_lock_per_mille, presales[id].owner, presales[id].dex, presales[id].lp_unlock_ts);
    else {
      IERC20(presales[id].buy_token).approve(address(lockContract), to_lp);
      lockContract.lpLock(
        presales[id].buy_token,
        presales[id].user_token,
        to_lp,
        presales[id].lp_tokens,
        presales[id].lp_lock_per_mille,
        presales[id].owner,
        presales[id].dex,
        presales[id].lp_unlock_ts
      );
    }

    // send the remaining buy_tokens to the owner
    uint256 to_owner = tokens - to_lp;
    if (presales[id].base_currency) LTransfers.internalTransferToETH(presales[id].owner, to_owner);
    else LTransfers.internalTransferTo(presales[id].owner, to_owner, IERC20(presales[id].buy_token));

    // vesting tokens
    if (presales[id].total_vested > 0) {
      IERC20(presales[id].user_token).approve(address(vestingContract), presales[id].total_vested);
      vestingContract.vest(IKochiVest.EVestType.linear, presales[id].owner, presales[id].user_token, presales[id].total_vested, block.timestamp, presales[id].vested_deadline);
    }

    // send back the unsold tokens to the owner; or burn them.
    if (presales[id].presale_type != EPresaleType.fairlaunch && presaleMetadata[id][EPresaleMetadata.total_tokens] < presales[id].total_tokens) {
      LTransfers.internalTransferTo(
        presales[id].burn_after_sale ? DEAD : presales[id].owner, // burn the tokens if the presale is set to burn_after_sale
        presales[id].total_tokens - presaleMetadata[id][EPresaleMetadata.total_tokens], // unsold tokens
        IERC20(presales[id].user_token) // user token
      );
    }

    // emit the event
    emit OwnerClaim(id, tokens, presales[id].total_tokens - presaleMetadata[id][EPresaleMetadata.total_tokens], tax);
  }

  function ownerCancel(uint256 id) external override nonReentrant {
    require(_msgSender() == presales[id].owner, "you are not the owner of this presale");
    require(presaleMetadata[id][EPresaleMetadata.finished] == 0, "this presale has already finished");
    require(presaleMetadata[id][EPresaleMetadata.total_claimed] == 0, "some of your tokens have been claimed already");

    // set the presale to finished, prevents complex reentrency. and stops further owner actions.
    presaleMetadata[id][EPresaleMetadata.finished] = 1;
    presaleMetadata[id][EPresaleMetadata.stale] = 1;

    // send back the unsold tokens to the owner
    LTransfers.internalTransferTo(presales[id].owner, presales[id].total_tokens + presales[id].referral_tokens + presales[id].total_vested + presales[id].lp_tokens, IERC20(presales[id].user_token));

    // emit the event
    emit PresaleTerminated(id);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Kochi Referrals
  //////////////////////////////////////////////////////////////////////////////

  function setReferrer(IKochiInvest.SVerify memory verification) external override verify(verification) {
    (SSecurity memory security_verification, uint256 id, address referrer) = abi.decode(verification.encoded_message, (SSecurity, uint256, address));
    checkMessageValidity(EOPCode.SET_REFERRER, security_verification);

    require(presales[id].referral_tokens > 0, "this presale does not have any referral tokens.");
    require(presaleMetadata[id][EPresaleMetadata.total_claimed] == 0, "the claiming has already started"); // CKI-01

    _setReferrer(id, _msgSender(), referrer);
  }

  function _setReferrer(uint256 id, address user, address referrer) private {
    require(userReferrer[id][_msgSender()] != referrer, "you have already set your referrer to this address.");
    require(referrer != _msgSender(), "you cannot refer to yourself.");

    // not worried for overflow, since the number of referrals is small.

    // referrer isn't set
    bool replace = userReferrer[id][_msgSender()] == address(0);
    if (replace) {
      // increment the presale total and the referrer's total
      presaleMetadata[id][EPresaleMetadata.total_referrals]++;
      userMetadata[id][referrer][EUserMetadata.referrals]++;
    }
    // referrer is already set
    else {
      // decrement the old referrer, and increment the new one
      userMetadata[id][userReferrer[id][_msgSender()]][EUserMetadata.referrals]--;
      userMetadata[id][referrer][EUserMetadata.referrals]++;
    }

    // set the referrer
    userReferrer[id][_msgSender()] = referrer;
    emit UserReferral(id, _msgSender(), referrer, userMetadata[id][referrer][EUserMetadata.referrals], !replace);
  }

  //////////////////////////////////////////////////////////////////////////////
  // KOCHI SUPPORT
  //////////////////////////////////////////////////////////////////////////////

  // Kochi reserves itself the right to terminate a presale if it is not following the rules.
  function terminate(uint256 id) external onlyOwner {
    require(presaleMetadata[id][EPresaleMetadata.finished] == 0, "this presale has already finished");
    require(presaleMetadata[id][EPresaleMetadata.total_claimed] == 0, "some of your tokens have been claimed already");

    presaleMetadata[id][EPresaleMetadata.finished] = 1;
    presaleMetadata[id][EPresaleMetadata.stale] = 1;

    // send back the unsold tokens to the owner
    LTransfers.internalTransferTo(presales[id].owner, presales[id].total_tokens + presales[id].referral_tokens + presales[id].total_vested + presales[id].lp_tokens, IERC20(presales[id].user_token));

    emit PresaleTerminated(id);
  }

  // Kochi reserves itself the right to pause the contract is case of extreme emergency to stop further purchases. Users can still remove their funds from the contract with backend authorization.
  function setPaused(bool pause) external onlyOwner {
    if (pause) _pause();
    else _unpause();
  }

  function setPresaleBuyFee(uint256 fee) external onlyOwner {
    presaleBuyFee = fee;
    emit PresaleBuyFeeUpdated(fee);
  }

  function setPresaleCreationFee(uint256 fee) external onlyOwner {
    creationFee = fee;
    emit PresaleCreationFeeUpdated(fee);
  }

  function setFeeWallet(address wallet) external onlyOwner {
    feeWallet = wallet;
    emit FeeWalletUpdated(wallet);
  }

  function setFeeToken(address token) external onlyOwner {
    feeToken = token;
    emit FeeTokenUpdated(token);
  }

  function modifySignature(address new_signature) external onlyOwner {
    signer = new_signature;
    emit SignerModified(_msgSender(), new_signature);
  }

  function setReferrals(uint256 id, address[] calldata users, address[] calldata referrers) external onlyOwner {
    require(users.length == referrers.length, "users and referrers must be the same length");
    require(presales[id].referral_tokens > 0, "this presale does not have any referral tokens.");
    require(presaleMetadata[id][EPresaleMetadata.total_claimed] == 0, "the claiming has already started");

    for (uint256 i = 0; i < users.length; i++) _setReferrer(id, users[i], referrers[i]);
  }

  function setPresaleMetadata(
    uint256 id,
    uint256 lp_per_mille,
    uint256 lp_lock_per_mille,
    uint256 lp_unlock_ts,
    uint256 vested_deadline,
    string calldata dex,
    bool burn_after_sale
  ) external onlyOwner {
    require(presaleMetadata[id][EPresaleMetadata.total_claimed] == 0, "the claiming has already started");

    presales[id].lp_per_mille = lp_per_mille;
    presales[id].lp_lock_per_mille = lp_lock_per_mille;
    presales[id].lp_unlock_ts = lp_unlock_ts;
    presales[id].vested_deadline = vested_deadline;
    presales[id].dex = dex;
    presales[id].burn_after_sale = burn_after_sale;
  }

  //////////////////////////////////////////////////////////////////////////////
  // GETTERS
  //////////////////////////////////////////////////////////////////////////////

  function getReferrer(uint256 presale_id, address user) external view override returns (address) {
    return userReferrer[presale_id][user];
  }

  function getUserMetadata(uint256 presale_id, address user) external view override returns (uint256 invested, uint256 tokens, uint256 claimed, uint256 referrals) {
    return (
      userMetadata[presale_id][user][EUserMetadata.invested],
      userMetadata[presale_id][user][EUserMetadata.tokens],
      userMetadata[presale_id][user][EUserMetadata.claimed],
      userMetadata[presale_id][user][EUserMetadata.referrals]
    );
  }

  function getPresaleMetadata(uint256 presale_id) external view override returns (uint256 total_invested, uint256 total_tokens, uint256 total_referrals, uint256 finished) {
    return (
      presaleMetadata[presale_id][EPresaleMetadata.total_invested],
      presaleMetadata[presale_id][EPresaleMetadata.total_tokens],
      presaleMetadata[presale_id][EPresaleMetadata.total_referrals],
      presaleMetadata[presale_id][EPresaleMetadata.finished]
    );
  }

  function getCreationFeeMetadata() external view override returns (uint256, address) {
    return (creationFee, feeToken);
  }

  function getCreationFee() external view override returns (uint256) {
    return creationFee;
  }

  function getFeeWallet() external view override returns (address) {
    return feeWallet;
  }

  function getUserInvestment(uint256 presale_id, address user) external view override returns (uint256) {
    return userMetadata[presale_id][user][EUserMetadata.invested];
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}

  //////////////////////////////////////////////////////////////////////////////
  // HELPERS
  //////////////////////////////////////////////////////////////////////////////

  function checkMessageValidity(EOPCode expected_opcode, SSecurity memory security_verification) private view returns (bool) {
    require(security_verification.opcode == expected_opcode, "this is not the correct signature.");
    require(security_verification.account == _msgSender(), "this is not the correct signature.");
    require(security_verification.ttl >= block.number, "this signature has expired.");
    return true;
  }
}