// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*
        _   _ ______ _______ 
       | \ | |  ____|__   __|
   __ _|  \| | |__     | |   
  / _` | . ` |  __|    | |   
 | (_| | |\  | |       | |   
  \__, |_| \_|_|       |_|   
     | |                     
     |_|     
*/
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RugSupply is
  Initializable,
  UUPSUpgradeable,
  AccessControlUpgradeable,
  OwnableUpgradeable,
  ERC721EnumerableUpgradeable
{
  event OptionsModified(
    string category,
    uint256 option,
    uint256 price,
    uint256 qty,
    bool _paused,
    bool exist,
    bool qtyLimited
  );
  event ClaimedReferral(address userClaim, uint256 amount);
  event RugBought(
    address userClaim,
    uint256 tokenId,
    string[] category,
    uint256[] selection,
    uint256 price,
    address referral,
    bytes backHash
  );
  using Strings for uint256;
  using Counters for Counters.Counter;
  struct OptionDetails {
    uint256 price;
    uint256 qty;
    bool paused;
    bool exist;
    bool qtyLimited;
  }
  struct Referral {
    uint256 amount;
    uint256 refRewards;
    uint256 limit;
    uint256 withdrawn;
    uint256 firstWithdrawal;
    uint256 refDiscount;
    bool useZero;
  }
  bytes32 public constant TECH = keccak256("TECH");
  address public currency;
  address public splitWallet;
  address public signer;
  string public baseURI;
  Counters.Counter _tokenID;
  uint256 public constant REFLIMIT = 500 * 10**6;
  uint256 public globalRefRewards;
  mapping(string => mapping(uint256 => OptionDetails)) public options;
  mapping(address => Referral) public referrals;
  mapping(address => uint256) public credits;
  mapping(bytes => bool) public blacklist;

  uint256 public globalRefDiscount;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address payable _splitWallet,
    string memory _uri,
    address _signer,
    address _currency
  ) public initializer {
    __ERC721_init("RUG.SUPPLY", "RUG (SBT)");
    __Ownable_init();
    __UUPSUpgradeable_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(TECH, msg.sender);
    splitWallet = _splitWallet;
    baseURI = _uri;
    signer = _signer;
    currency = _currency;
    globalRefRewards = 5 * 10**6;
    globalRefDiscount = 5;
    transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
  }

  //proxy requirement
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(TECH)
  {}

  function recover(
    bytes memory backHash,
    uint256[] memory _options,
    uint256 timestamp,
    bytes memory signature
  ) public view returns (bool) {
    bytes32 hash = keccak256(
      abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(backHash, _options, timestamp))
      )
    );
    return SignatureChecker.isValidSignatureNow(signer, hash, signature);
  }

  function mint(
    address to,
    uint256 overridePrice,
    string[] calldata category,
    bytes calldata sigData,
    address referrer
  ) external payable virtual {
    (
      bytes memory backHash,
      uint256[] memory _options,
      uint256 timestamp,
      bytes memory signature
    ) = abi.decode(sigData, (bytes, uint256[], uint256, bytes));
    require(recover(backHash, _options, timestamp, signature), "Wrong sigData");
    require(!blacklist[sigData], "sigData already used");
    blacklist[sigData] = true;
    uint256 total;
    if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) total = overridePrice;
    else {
      total = computePriceBeforeDiscount(category, _options);
      total = computePriceAfterDiscount(to, referrer, total);
    }
    if (total > 0) {
      if (referrer != address(0) && overridePrice == 0) {
        uint256 txRefReward;
        if (referrals[referrer].useZero) {
          txRefReward = 0;
        } else {
          txRefReward = referrals[referrer].refRewards != 0
            ? referrals[referrer].refRewards
            : globalRefRewards;
        }
        IERC20(currency).transferFrom(to, address(this), txRefReward);
        IERC20(currency).transferFrom(to, splitWallet, total - txRefReward);
        referrals[referrer].amount += txRefReward;
      } else {
        IERC20(currency).transferFrom(to, splitWallet, total);
      }
    }
    --options["s"][_options[0]].qty;
    uint256 tokenId = _tokenID.current();
    _mint(to, tokenId);
    _tokenID.increment();
    emit RugBought(to, tokenId, category, _options, total, referrer, backHash);
  }

  function claimReferral(bytes memory signature) external {
    bytes32 hash = keccak256(
      abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(msg.sender))
      )
    );
    require(SignatureChecker.isValidSignatureNow(signer, hash, signature));
    uint256 toClaim = referrals[msg.sender].amount;
    uint256 currentLimit = referrals[msg.sender].limit == 0
      ? REFLIMIT
      : referrals[msg.sender].limit;
    require(
      referrals[msg.sender].withdrawn < currentLimit ||
        block.timestamp > referrals[msg.sender].firstWithdrawal + 365 days
    );
    // reset the withdrawn amount for the limit calculation
    if (block.timestamp > referrals[msg.sender].firstWithdrawal + 365 days) {
      referrals[msg.sender].withdrawn = 0;
      referrals[msg.sender].firstWithdrawal = block.timestamp;
    }
    uint256 toBeSent = toClaim > currentLimit - referrals[msg.sender].withdrawn
      ? currentLimit - referrals[msg.sender].withdrawn
      : toClaim;
    require(toBeSent > 0, "Nothing to Claim");
    referrals[msg.sender].amount -= toBeSent;
    referrals[msg.sender].withdrawn += toBeSent;
    referrals[msg.sender].firstWithdrawal = block.timestamp;
    IERC20(currency).transfer(msg.sender, toBeSent);
    emit ClaimedReferral(msg.sender, toBeSent);
  }

  function walletInventory(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function emergencyWithdrawERC20(address _currency)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    uint256 contractBalance = IERC20(_currency).balanceOf(address(this));
    IERC20(_currency).transfer(
      0xa126d74de3623734100F2c15F497F35D576FB0bf,
      contractBalance
    );
  }

  function computePriceBeforeDiscount(
    string[] memory category,
    uint256[] memory selection
  ) public view returns (uint256) {
    require(category.length == selection.length, "not matching");
    uint256 total;
    bool size;
    for (uint256 index = 0; index < category.length; index++) {
      if (
        keccak256(abi.encodePacked(category[index])) ==
        keccak256(abi.encodePacked("s"))
      ) {
        if (size) revert();
        size = true;
      }
      require(
        options[category[index]][selection[index]].exist,
        "Option not available"
      );
      require(
        options[category[index]][selection[index]].qty > 0 ||
          !options[category[index]][selection[index]].qtyLimited,
        "Out of stock"
      );
      require(!options[category[index]][selection[index]].paused, "Paused");
      total += options[category[index]][selection[index]].price;
    }
    require(size);
    return total;
  }

  function computePriceAfterDiscount(
    address to,
    address referrer,
    uint256 currentPrice
  ) public returns (uint256) {
    if (credits[to] > 0) {
      uint256 tmpCredit = credits[to];
      credits[to] = tmpCredit > currentPrice ? tmpCredit - currentPrice : 0;
      currentPrice = tmpCredit > currentPrice ? 0 : currentPrice - tmpCredit;
    }
    if (referrer != address(0)) {
      uint256 txRefDiscount = referrals[referrer].refDiscount != 0
        ? referrals[referrer].refDiscount
        : globalRefDiscount;
      currentPrice = (currentPrice * (100 - txRefDiscount)) / 100;
    }
    return currentPrice;
  }

  function setBaseURI(string memory _newURI) external onlyRole(TECH) {
    baseURI = _newURI;
  }

  /**
   * @notice Set the discount that the user will get if the referee doesnt have custom values (between 0 and 100)
   * @param _newRewards value in $
   */
  function setGlobalRefRewards(uint256 _newRewards) external onlyRole(TECH) {
    //flat fee, pass a value * 10**6;
    globalRefRewards = _newRewards;
  }

  /**
   * @notice Change the currency accepted by the contract
   * @param _currency address of the currency contract
   */
  function setCurrency(address _currency) external onlyRole(TECH) {
    require(_currency != address(0));
    currency = _currency;
  }

  /**
   * @notice Set the discount that the user will get if the referee doesnt have custom values (between 0 and 100)
   * @param _newDiscount Value in % (* between 0 and 100)
   */
  function setGlobalRefDiscount(uint256 _newDiscount) external onlyRole(TECH) {
    require(_newDiscount < 101);
    globalRefDiscount = _newDiscount;
  }

  /**
   * @notice Set the custom values for a referer
   * @param _newRewards How much the referer will receive per referral in $ must have the right decimal
   * @param _newDiscount % discount that the referee will receive on the order must be between 0 and 100
   * @param useZero Bool value if true will allow a reward of 0 for the referrer
   * @param limit How much can be withdrawn per year
   * @param user Address of the referrer
   */
  function setUserRefSettings(
    uint256 _newRewards,
    uint256 _newDiscount,
    uint256 limit,
    bool useZero,
    address user
  ) external onlyRole(TECH) {
    referrals[user].refRewards = _newRewards;
    referrals[user].limit = limit;
    referrals[user].useZero = useZero;
    require(_newDiscount < 101);
    referrals[user].refDiscount = _newDiscount;
  }

  function setSplitWallet(address _newSplit)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    splitWallet = _newSplit;
  }

  function setSigner(address _newSigner) external onlyRole(TECH) {
    signer = _newSigner;
  }

  function setOptions(
    string memory category,
    uint256 option,
    uint256 price,
    uint256 qty,
    bool _paused,
    bool exist,
    bool qtyLimited
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    options[category][option] = OptionDetails(
      price,
      qty,
      _paused,
      exist,
      qtyLimited
    );
    emit OptionsModified(
      category,
      option,
      price,
      qty,
      _paused,
      exist,
      qtyLimited
    );
  }

  function editUserCredit(
    address _user,
    uint256 amount,
    bool add
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    add ? credits[_user] += amount : credits[_user] -= amount;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _transfer(
    address,
    address,
    uint256
  ) internal pure override {
    revert();
  }

  function burn(uint256 tokenId) external {
    require(this.ownerOf(tokenId) == msg.sender);
    _burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlUpgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IAccessControlUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}