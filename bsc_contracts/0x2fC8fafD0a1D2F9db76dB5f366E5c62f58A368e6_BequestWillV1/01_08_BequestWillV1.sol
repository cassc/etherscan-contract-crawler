// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title BequestWillV1
 * @author Bequest Finance Inc.
 * @notice Bequest uses a Dead Man's switch to distribute tokens and NFTs to
 *         selected recipients. Bequest allows decentralized, trustless and
 *         anonymous crypto wills and asset recovery backed by the blockchain.
 */
contract BequestWillV1 is Ownable, ReentrancyGuard {
  /*
   * @dev: Stores all details about a Bequest
   */
  struct Bequest {
    address owner;
    address[] recipients;
    address[] nftRecipients;
    address executor;
    IERC20[] tokens;
    IERC165[] nfts;
    uint256 timestamp;
    uint256 renewalRate;
    uint256[] percentages;
    uint256[] nftIds;
    uint256[] nftAmounts;
  }

  /*
   * @dev: Stores all details about a referral
   */
  struct Referral {
    uint256 usesLeft;
    uint256 profit;
    uint8 discount;
    uint8 profitShare;
    address profitAddress;
  }

  /*
   * @dev: Event emitted when Bequest is created
   * @param owner: The owner of the Bequest
   * @param referral: Referral code used
   */
  event CreatedBequest(address indexed owner, string indexed referral);

  /*
   * @dev: Event emitted when Bequest is renewed
   * @param owner: The owner of the Bequest
   * @param executor: The executor of the renewal
   */
  event RenewedBequest(address indexed owner, address executor);

  /*
   * @dev: Event emitted when Bequest recipient distributes a Bequest
   * @param owner: The owner of the Bequest
   * @param executor: The recipient of the Bequest
   */
  event DistributedBequest(address indexed owner, address indexed recipient);

  /*
   * @dev: Event emitted when Bequest owner sets a recipient,
   *       used for gas-efficent storage.
   * @param recipient: The recipient added to a Bequest
   * @param owner: The owner of the Bequest
   */
  event AddedRecipient(address indexed recipient, address owner);

  /*
   * @dev: Event emitted when Bequest owner sets an executor,
   *       used for gas-efficent storage.
   * @param executor: The executor added to a Bequest
   * @param owner: The owner of the Bequest
   */
  event SetExecutor(address indexed executor, address owner);

  /*
   * @dev: Event emitted when referral code is created
   * @param code: Referral code
   */
  event CreatedReferral(string code);

  /*
   * @dev: Event emitted when yearly fee is edited
   * @param code: New yearly fee
   */
  event ChangedYearlyFee(uint256 newYearlyFee);

  // Stores all Bequests
  mapping(address => Bequest) private addressToBequest;
  // Stores if a Bequest owner has paid their distribution fee
  mapping(address => bool) private paidDistributionFee;
  // Stores the last
  mapping(address => uint256) private lastPaidYearlyFee;

  // Stores all referral codes
  mapping(string => Referral) public referralCodes;
  // Current profit to be withdrawn for referrers
  uint256 public referralProfit;

  uint256 private constant ONE_YEAR = 365 days;
  uint256 public bequestYearlyFee;
  uint256 private constant BEQUEST_FEE_DIVISOR = 100; // CONSTANT 1%

  constructor(uint256 _bequestYearlyFee) {
    bequestYearlyFee = _bequestYearlyFee;
  }

  /*
   * @dev: Ensures called is a Bequest owner
   */
  modifier onlyBequestOwner() {
    require(isOwner(msg.sender), "Not Bequest owner");
    _;
  }

  /*
   * @dev: Ensures Bequest is up to date on renewal payments
   */
  modifier notClaimable() {
    require(!isClaimable(msg.sender), "Renew Bequest");
    _;
  }

  modifier onlyExecutor(address _owner) {
    require(
      msg.sender == addressToBequest[_owner].executor ||
        msg.sender == addressToBequest[_owner].owner,
      "Not executor"
    );
    _;
  }

  /*
   * @notice: Creates a Bequest
   * @param _owner: To be owner of Bequest
   * @param _referral: Referral code, if any
   */
  function createBequest(address _owner, string memory _referral)
    external
    payable
  {
    require(!isOwner(_owner), "Already owner");

    uint256 creationFee = getCreationFee(_referral);
    require(msg.value == creationFee, "Invalid fee");

    if (bytes(_referral).length != 0) {
      Referral storage referralDetails = referralCodes[_referral];

      if (referralDetails.profitShare > 0) {
        uint256 profit = (creationFee * referralDetails.profitShare) / 100;

        referralDetails.profit += profit;
        referralProfit += profit;
      }

      referralDetails.usesLeft--;
    }

    Bequest storage bequest = addressToBequest[_owner];
    bequest.owner = _owner;
    bequest.timestamp = block.timestamp;
    bequest.renewalRate = ONE_YEAR;

    emit CreatedBequest(_owner, _referral);
  }

  /*
   * @notice: Lets Bequest owners renew their Bequest
   * @dev: Similar to Dead Man's Switch
   */
  function renewBequest(address _owner) external payable onlyExecutor(_owner) {
    (uint256 renewalFee, uint256 yearsPassed) = getRenewalFee(_owner);
    require(msg.value == renewalFee, "Invalid fee");

    if (yearsPassed > 0) {
      if (lastPaidYearlyFee[_owner] == 0) {
        lastPaidYearlyFee[_owner] =
          addressToBequest[_owner].timestamp +
          ONE_YEAR *
          yearsPassed;
      } else {
        lastPaidYearlyFee[_owner] += ONE_YEAR * yearsPassed;
      }
    }

    addressToBequest[_owner].timestamp = block.timestamp;
    emit RenewedBequest(_owner, msg.sender);
  }

  /*
   * @notice: Transfers all assets in _owner's Bequest to _recipient
   * @param _owner: Owner of Bequest
   * @param _recipient: Recipient of assets
   * @dev: Nonreentrant to avoid malicious code when calling external contracts
   */
  function distribute(address _owner, address _recipient)
    external
    nonReentrant
  {
    require(isRecipient(_owner, _recipient), "Not recipient");
    require(isClaimable(_owner), "Cannot distribute now");

    Bequest storage bequest = addressToBequest[_owner];

    if (bequest.recipients.length != 0) {
      if (!paidDistributionFee[_owner]) {
        safeSendERC20s(_owner, owner(), 1, BEQUEST_FEE_DIVISOR);
        paidDistributionFee[_owner] = true;
      }

      uint256 recipientPercentage;
      uint256 index;

      for (uint256 i; i < bequest.recipients.length; i++) {
        if (bequest.recipients[i] == _recipient) {
          recipientPercentage = bequest.percentages[i];
          index = i;
          break;
        }
      }

      uint256 cumulativePercentage;

      for (uint256 i; i < bequest.percentages.length; i++) {
        cumulativePercentage += bequest.percentages[i];
      }

      safeSendERC20s(
        _owner,
        _recipient,
        recipientPercentage,
        cumulativePercentage
      );

      delete bequest.recipients[index];
      delete bequest.percentages[index];
    }

    for (uint256 i; i < bequest.nftRecipients.length; i++) {
      if (bequest.nftRecipients[i] == _recipient) {
        safeSendNFT(
          _owner,
          _recipient,
          bequest.nfts[i],
          bequest.nftIds[i],
          bequest.nftAmounts[i]
        );
        delete bequest.nftRecipients[i];
      }
    }

    emit DistributedBequest(_owner, _recipient);

    for (uint256 i; i < bequest.recipients.length; i++) {
      if (bequest.recipients[i] != address(0)) {
        return;
      }
    }

    for (uint256 i; i < bequest.nftRecipients.length; i++) {
      if (bequest.nftRecipients[i] != address(0)) {
        return;
      }
    }

    delete addressToBequest[_owner];
    delete paidDistributionFee[_owner];
    delete lastPaidYearlyFee[_owner];
  }

  /*
   * @notice sets recipients, tokens, and renewal rate for a will
   * @param _recipients: Address of token recipients
   * @param _percentages: Percentage alloted to each recipient by index match
   * @param _tokens: ERC20 contract addresses
   * @param _renewal_rate: New renewal rate
   */
  function setBequest(
    address[] memory _recipients,
    uint256[] memory _percentages,
    IERC20[] memory _tokens,
    uint256 _renewalRate
  ) external notClaimable {
    setRecipients(_recipients, _percentages);
    setTokens(_tokens);
    setRenewalRate(_renewalRate);
  }

  /*
   * @notice: Lets Bequest owner set tokens in Bequest
   * @param _nfts: NFT contract addresses
   * @param _nftIds: NFT tokenIds, index-matched
   * @param _nftRecipients: NFT recipient address, index-matched
   */
  function setNFTs(
    IERC165[] memory _nfts,
    uint256[] memory _nftIds,
    address[] memory _nftRecipients,
    uint256[] memory _nftAmounts
  ) external onlyBequestOwner notClaimable {
    require(_nfts.length == _nftIds.length, "Invalid input");
    require(_nfts.length == _nftRecipients.length, "Invalid input");
    require(_nfts.length == _nftAmounts.length, "Invalid input");

    for (uint256 i; i < _nfts.length; i++) {
      require(isERC721(_nfts[i]) || isERC1155(_nfts[i]), "Not ERC721/ERC1155");
      require(_nftAmounts[i] > 0, "Invalid input");
    }

    addressToBequest[msg.sender].nfts = _nfts;
    addressToBequest[msg.sender].nftIds = _nftIds;
    addressToBequest[msg.sender].nftRecipients = _nftRecipients;
    addressToBequest[msg.sender].nftAmounts = _nftAmounts;
  }

  /*
   * @notice: Lets Executor or Bequest owner set executor to renew will on owner's behalf
   * @param _owner: Bequest owner's address
   * @param _executor: Exeuctor's address
   */
  function setExecutor(address _owner, address _executor)
    external
    onlyExecutor(_owner)
  {
    require(!isClaimable(_owner), "Renew Bequest");
    addressToBequest[_owner].executor = _executor;
    emit SetExecutor(_executor, _owner);
  }

  /*
   * @notice: Creates a referral code
   * @param _code: Referral code name
   * @param _usesLeft: The amount of uses of the referral code
   * @param _discount: The percent of discount
   * @param _profitShare: The percent of profit to give to _profitAddress
   * @param _profitAddress: Address to send profit to
   * @dev: Possible to edit referral code
   */
  function createReferral(
    string memory _code,
    uint256 _usesLeft,
    uint8 _discount,
    uint8 _profitShare,
    address _profitAddress
  ) external onlyOwner {
    require(bytes(_code).length > 0, "Invalid code");
    require(_discount <= 100, "Invalid discount");
    require(_profitShare <= 100, "Invalid profit share");
    if (_profitShare != 0) {
      require(_profitAddress != address(0), "Invalid address");
    }

    referralCodes[_code].usesLeft = _usesLeft;
    referralCodes[_code].discount = _discount;
    referralCodes[_code].profitShare = _profitShare;
    referralCodes[_code].profitAddress = _profitAddress;

    emit CreatedReferral(_code);
  }

  /*
   * @notice: Transfers all profit, if any, to the profit address
   * @param _code: Referrer code name
   * @dev: Profit set to 0 before transfer to prevent re-entrancy
   */
  function withdrawReferralProfits(string memory _code) external {
    Referral storage referralDetails = referralCodes[_code];
    uint256 profit = referralDetails.profit;
    require(profit > 0, "No profit");

    referralProfit -= profit;
    referralDetails.profit = 0;
    (bool success, ) = referralDetails.profitAddress.call{ value: profit }("");
    require(success, "Transaction failed");
  }

  /*
   * @notice: Deletes caller's Bequest
   */
  function deleteBequest() external onlyBequestOwner {
    delete addressToBequest[msg.sender];
    delete paidDistributionFee[msg.sender];
    delete lastPaidYearlyFee[msg.sender];
  }

  /*
   * @notice: Lets contract admin extract fees paid by users
   * @dev: Does not let referral profit be withdrawn
   */
  function extractFees() external onlyOwner {
    uint256 amount = address(this).balance - referralProfit;
    (bool success, ) = owner().call{ value: amount }("");
    require(success, "Transaction failed");
  }

  /*
   * @notice: Sets Bequest yearly fee, admin function
   * @param _fee: New yearly fee
   */
  function setYearlyFee(uint256 _fee) external onlyOwner {
    bequestYearlyFee = _fee;
    emit ChangedYearlyFee(_fee);
  }

  /*
   * @param _owner: Address
   * @returns: _owner's Bequest details
   */
  function getBequest(address _owner) external view returns (Bequest memory) {
    return addressToBequest[_owner];
  }

  /*
   * @notice: Lets Bequest owner set renewal rate
   * @param _rate: New renewal rate
   */
  function setRenewalRate(uint256 _rate) public onlyBequestOwner notClaimable {
    require(_rate >= 1 days, "Invalid input");
    addressToBequest[msg.sender].renewalRate = _rate;
  }

  /*
   * @notice: Lets Bequest owner set token's recipients
   * @param _recipients: Address of token recipients
   * @param _percentages: Percentage alloted to each recipient by index match
   */
  function setRecipients(
    address[] memory _recipients,
    uint256[] memory _percentages
  ) public onlyBequestOwner notClaimable {
    for (uint256 i; i < _recipients.length; i++) {
      for (uint256 j = i + 1; j < _recipients.length; j++) {
        if (_recipients[i] == _recipients[j]) {
          revert("Duplicate recipient");
        }
      }
    }

    require(_recipients.length == _percentages.length, "Invalid input");

    uint256 sum;
    for (uint256 i; i < _recipients.length; i++) {
      sum += _percentages[i];
      require(_recipients[i] != address(0), "Invalid recipient");
    }
    require(sum == 100, "Must sum to 100%");

    for (uint256 i; i < _recipients.length; i++) {
      emit AddedRecipient(_recipients[i], msg.sender);
    }

    addressToBequest[msg.sender].recipients = _recipients;
    addressToBequest[msg.sender].percentages = _percentages;
  }

  /*
   * @notice: Lets Bequest owner set tokens in Bequest
   * @param _tokens: ERC20 contract addresses
   * @dev: Tokens are pre-approved in frontend
   */
  function setTokens(IERC20[] memory _tokens)
    public
    onlyBequestOwner
    notClaimable
  {
    addressToBequest[msg.sender].tokens = _tokens;
  }

  /*
   * @param _owner: Bequest owner
   * @returns: True if _owner's Bequest is claimable
   */
  function isClaimable(address _owner) public view returns (bool) {
    Bequest memory bequest = addressToBequest[_owner];
    return block.timestamp >= bequest.renewalRate + bequest.timestamp;
  }

  /*
   * @param _referral: Address
   * @returns: The current creation fee with a possible
   *           referral discount
   */
  function getCreationFee(string memory _referral)
    public
    view
    returns (uint256)
  {
    uint256 creationFee = bequestYearlyFee;
    if (bytes(_referral).length != 0) {
      Referral memory referralDetails = referralCodes[_referral];

      require(referralDetails.usesLeft > 0, "Referral code expired");
      creationFee = (bequestYearlyFee * (100 - referralDetails.discount)) / 100;
    }
    return creationFee;
  }

  /*
   * @param _owner: Address
   * @returns: The current renewal fee for _owner and the number
   *           of years passed since last renewal
   */
  function getRenewalFee(address _owner)
    public
    view
    returns (uint256, uint256)
  {
    uint256 timePassed;
    if (lastPaidYearlyFee[_owner] == 0) {
      timePassed = block.timestamp - addressToBequest[_owner].timestamp;
    } else {
      timePassed = block.timestamp - lastPaidYearlyFee[_owner];
    }

    uint256 yearsPassed = timePassed / ONE_YEAR;
    uint256 renewalFee = yearsPassed * bequestYearlyFee;

    return (renewalFee, yearsPassed);
  }

  /*
   * @param _owner: Address
   * @returns A boolean indicatting whether the _owner owns a Bequest
   */
  function isOwner(address _owner) public view returns (bool) {
    return addressToBequest[_owner].owner == _owner;
  }

  /*
   * @param _owner: Bequest owner address
   * @param _recipient: Recipient address
   * @returns A boolean indicatting whether the _recipent is a recipient
   *          of the _owner's Bequest
   */
  function isRecipient(address _owner, address _recipient)
    public
    view
    returns (bool)
  {
    if (_recipient == address(0)) return false;

    Bequest memory bequest = addressToBequest[_owner];

    for (uint256 i; i < bequest.recipients.length; i++) {
      if (bequest.recipients[i] == _recipient) {
        return true;
      }
    }

    for (uint256 i; i < bequest.nftRecipients.length; i++) {
      if (bequest.nftRecipients[i] == _recipient) {
        return true;
      }
    }

    return false;
  }

  /*
   * @notice Distributes all ERC20s
   * @param _owner: Owner of Bequest
   * @param _recipient: Recipient address
   * @param _percentage: Percentage alloted to _recipient
   * @param _percentageSum: Sum of percentages alloted to all
   *                        recipients in _owner's Bequest
   */
  function safeSendERC20s(
    address _owner,
    address _recipient,
    uint256 _percentage,
    uint256 _percentageSum
  ) internal {
    Bequest memory bequest = addressToBequest[_owner];

    for (uint256 i; i < bequest.tokens.length; i++) {
      uint256 amount = min(
        getTokenAllowance(bequest.owner, bequest.tokens[i]),
        getBalance(bequest.owner, bequest.tokens[i])
      );

      uint256 share = (_percentage * amount) / _percentageSum;

      if (share != 0) {
        try bequest.tokens[i].transferFrom(_owner, _recipient, share) {} catch (
          bytes memory
        ) {}
      }
    }
  }

  /*
   * @notice Sends an NFT
   * @param _owner: Owner of Bequest
   * @param _recipient: Recipient address
   * @param _nft: Address of NFT Contract
   * @param _nft: NFT token ID
   * @dev Only supports ERC721 and ERC1155
   */
  function safeSendNFT(
    address _owner,
    address _recipient,
    IERC165 _nft,
    uint256 _nftId,
    uint256 _amount
  ) internal {
    if (isERC721(_nft)) {
      IERC721 nft = IERC721(address(_nft));
      try nft.safeTransferFrom(_owner, _recipient, _nftId) {} catch (
        bytes memory
      ) {}
    } else if (isERC1155(_nft)) {
      IERC1155 nft = IERC1155(address(_nft));
      uint256 nftBalance;

      try nft.balanceOf(_owner, _nftId) returns (uint256 balance) {
        nftBalance = balance;
      } catch (bytes memory) {}

      nftBalance = min(nftBalance, _amount);

      if (nftBalance > 0) {
        try
          nft.safeTransferFrom(_owner, _recipient, _nftId, nftBalance, "")
        {} catch (bytes memory) {}
      }
    }
  }

  /*
   * @param _nft: NFT address
   * @returns Whether _nft is ERC721
   */
  function isERC721(IERC165 _nft) internal view returns (bool) {
    try _nft.supportsInterface(0x80ac58cd) returns (bool erc721) {
      return erc721;
    } catch (bytes memory) {
      return false;
    }
  }

  /*
   * @param _nft: NFT address
   * @returns Whether _nft is ERC1155
   */
  function isERC1155(IERC165 _nft) internal view returns (bool) {
    try _nft.supportsInterface(0xd9b67a26) returns (bool erc1155) {
      return erc1155;
    } catch (bytes memory) {
      return false;
    }
  }

  /*
   * @param _owner: Bequest owner
   * @param _token: Token contract address
   * @returns: Token allowance
   */
  function getTokenAllowance(address _owner, IERC20 _token)
    internal
    view
    returns (uint256)
  {
    try _token.allowance(_owner, address(this)) returns (uint256 allowance) {
      return allowance;
    } catch (bytes memory) {
      return 0;
    }
  }

  /*
   * @param _owner: Bequest owner
   * @param _token: Token contract address
   * @returns: Token balance
   */
  function getBalance(address _owner, IERC20 _token)
    internal
    view
    returns (uint256)
  {
    try _token.balanceOf(_owner) returns (uint256 balance) {
      return balance;
    } catch (bytes memory) {
      return 0;
    }
  }

  /*
   * @param a: First integer
   * @param b: Second integer
   * @returns Smaller integer
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a <= b ? a : b;
  }
}