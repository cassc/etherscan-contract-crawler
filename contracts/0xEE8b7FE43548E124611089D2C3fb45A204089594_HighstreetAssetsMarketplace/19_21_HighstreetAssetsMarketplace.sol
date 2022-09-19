// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HighstreetAssets.sol";
import "./utils/PriceConverter.sol";

/** @title The primary marketplace contract of Highstreet assets */
contract HighstreetAssetsMarketplace is Context, Ownable, ReentrancyGuard, Pausable, PriceConverter {

  uint8 public constant CONST_EXCHANGE_RATE_DECIMAL = 18;

  HighstreetAssets public immutable assets;
  IERC20 public immutable high;
  address public immutable highUsdPriceFeed;
  address public immutable ethUsdPriceFeed;
  address payable private _platfomReceiver;

  enum InputType {
    PRICE,
    MAX,
    TOTAL,
    RESTRICT,
    RESET,
    START,
    END,
    COOLDOWN
  }

  struct Item {
    uint256 price;
    uint64 startTime;
    uint64 endTime;
    uint32 count;
    uint32 maxCanSell;
    uint32 maxSupply;
    uint16 restriction;
    uint16 coolDownTime;
  }

  struct ItemDisplay {
    uint256 id;
    uint256 price;
    uint64 startTime;
    uint64 endTime;
    uint32 count;
    uint32 maxCanSell;
    uint32 maxSupply;
    uint16 restriction;
    uint16 coolDownTime;
  }

  struct CoolDownTimeDisplay {
    uint256 id;
    uint256 coolDownTime;
  }

  uint256 [] public idList;

  mapping(uint256 => Item) public saleList;
  mapping(address => mapping(uint256 => uint256)) public coolDownTimer;

  event TransferReceiver(address indexed sender, address indexed newReciever);
  event Update(uint256 indexed id, InputType inputType, uint256 data);
  event Add(uint256 indexed id, Item item);
  event Received(address indexed from, uint256 amount);
  event Deal(address indexed buyer, address indexed receiver, uint256[] ids, uint256[] amounts, bool isPaidByEth, uint256 price);

  /**
   * @dev constructor function
   */
  constructor (
    address assets_,
    address receiver_,
    address high_,
    address highUsdPriceFeed_,
    address ethUsdPriceFeed_
  ) {
    require(assets_ != address(0), "invalid assets address");
    require(receiver_ != address(0), "invalid receiver address");
    require(high_ != address(0), "invalid high address");
    require(highUsdPriceFeed_ != address(0), "invalid high aggregator address");
    require(ethUsdPriceFeed_ != address(0), "invalid eth aggregator address");

    assets = HighstreetAssets(assets_);
    high = IERC20(high_);
    highUsdPriceFeed = highUsdPriceFeed_;
    ethUsdPriceFeed = ethUsdPriceFeed_;
    transferReceiver(receiver_);
  }

  function name() public view virtual returns (string memory) {
    return "Highstreet Assets Marketplace";
  }

  /**
    * @notice Transfer the receiver to new address
    *
    * @dev update the payment receiver, can refer to buy function for more detail
    * @param receiver_ new receiver address
    */
  function transferReceiver(address receiver_) public virtual onlyOwner {
    require(receiver_ != address(0), "invalid receiver address");
    _platfomReceiver = payable(receiver_);
    emit TransferReceiver(_msgSender(), receiver_);
  }

  /**
    * @notice Add new assets item to the marketplace
    *
    * @dev this function will also set the maximum supply in HighstreetAssets contract
    * @param id_ a number of id expected to create
    * @param item_ the speify token specification, more detail can refer to Item struct
    */
  function addItem(uint256 id_, Item memory item_) external onlyOwner {
    require(assets.minters(address(this)), "don't have minter role");
    require(saleList[id_].price == 0, "id have already in the list");
    require(item_.price > 0, "invalid price");
    saleList[id_] = item_;
    assets.setMaxSupply(id_, uint256(item_.maxSupply));
    idList.push(id_);
    emit Add(id_, item_);
  }

  /**
    * @notice Update the token specification based on the type and data
    *
    * @dev should be very careful about the RESET InputType, will clear the existing count
    * @param id_ a number of id expected to update
    * @param type_ specify the which type of specification
    * @param data_ the new value to be updated
    */
  function updateItem(uint256 id_, InputType type_, uint256 data_) external onlyOwner {
    require(saleList[id_].price != 0, "id isn't existing");
    // setup price
    if(type_ == InputType.PRICE) {
      require(data_ != 0, "invalid price");
      saleList[id_].price = data_;
    }
    //reset count
    if (type_ == InputType.RESET) {
      saleList[id_].count = 0;
    }
    //update max supply
    if (type_ == InputType.MAX) {
      saleList[id_].maxCanSell = uint32(data_);
    } else if (type_ == InputType.TOTAL) {
      saleList[id_].maxSupply = uint32(data_);
      assets.setMaxSupply(id_, uint256(data_));
    } else if (type_ == InputType.RESTRICT) {
      saleList[id_].restriction = uint16(data_);
    }
    //update time
    if (type_ == InputType.START) {
      saleList[id_].startTime = uint64(data_);
    } else if (type_ == InputType.END) {
      saleList[id_].endTime = uint64(data_);
    } else if (type_ == InputType.COOLDOWN) {
      saleList[id_].coolDownTime = uint16(data_);
    }
    emit Update(id_, type_, data_);
  }

  /**
    * @notice Receive the payment and mint the corresponding amount of token to the sender
    *
    * @dev the function supports both HIGH and ETH
    * @dev if msg.value is not zero will recognize ETH as payment currency
    *
    * @param ids_ array of ids to buy
    * @param amounts_ array of amounts of tokens to buy per id
    */
  function buy(uint256[] memory ids_, uint256[] memory amounts_) external payable virtual nonReentrant whenNotPaused {
    _deal(ids_, amounts_, _msgSender());
  }

  /**
    * @notice Receive the payment and mint the corresponding amount of token to the receiver
    *
    * @dev the function supports both HIGH and ETH
    * @dev if msg.value is not zero will recognize ETH as payment currency
    *
    * @param ids_ array of ids to buy
    * @param amounts_ array of amounts of tokens to buy per id
    * @param receiver_ an address to receive nft
    */
  function gifting(uint256[] memory ids_, uint256[] memory amounts_, address receiver_) external payable virtual nonReentrant whenNotPaused {
    _deal(ids_, amounts_, receiver_);
  }

  /**
    * @notice Internal function
    */
  function _deal(uint256[] memory ids_, uint256[] memory amounts_, address receiver_) internal virtual {
    uint256 eth =  msg.value;
    uint256 allowance = high.allowance(_msgSender(), address(this));
    require(eth != 0 || allowance != 0, "payment fail");
    bool isPaidByEth = eth != 0;

    uint256 totalPrice;
    uint256 priceInEth;
    for (uint256 i = 0; i < ids_.length; ++i) {
      uint256 id = ids_[i];
      uint256 amount = amounts_[i];
      Item memory item = saleList[id];
      require(item.price > 0, "id isn't existing");
      require(block.timestamp >= item.startTime, "sale haven't begin");
      require(item.endTime == 0 || block.timestamp <= item.endTime, "sale is closed");
      require(item.count + amount <= item.maxCanSell, "exceed max amount");
      if(item.restriction != 0) {
        require(amount <= item.restriction , "exceed max per buy");
        uint256 lastTime = coolDownTimer[_msgSender()][id];
        if( lastTime != 0) {
          require(block.timestamp - lastTime > item.coolDownTime, "waiting cool down");
        }
        coolDownTimer[_msgSender()][id] = block.timestamp;
      }
      totalPrice += item.price * amount;
    }

    if(isPaidByEth) {
      priceInEth = exchangeToETH(totalPrice);
      require(eth >= priceInEth, "not enough ether");
      uint256 reimburse = eth - priceInEth;
      Address.sendValue(payable(_platfomReceiver), priceInEth);
      Address.sendValue(payable(_msgSender()), reimburse);
    } else {
      SafeERC20.safeTransferFrom(high, _msgSender(), _platfomReceiver, totalPrice);
    }

    for (uint256 i = 0; i < ids_.length; ++i) {
      uint256 id = ids_[i];
      uint256 amount = amounts_[i];
      assets.mint( receiver_, id, amount, "");
      saleList[id].count += uint32(amount);
    }
    emit Deal(_msgSender(), receiver_, ids_, amounts_, isPaidByEth, isPaidByEth ? priceInEth : totalPrice);
  }

  /**
    * @notice Exchange the price from HIGH to ETH
    *
    * @param value the amount of HIGH token
    */
  function exchangeToETH(uint256 value) public view virtual returns (uint256) {
    int256 rate = getDerivedPrice(highUsdPriceFeed, ethUsdPriceFeed, CONST_EXCHANGE_RATE_DECIMAL);
    require(rate > 0, "invalid exchange rate");

    return value * uint256(rate) / 10 ** uint256(CONST_EXCHANGE_RATE_DECIMAL);
  }

  /**
    * @notice Get the exist item information in batch
    *
    * @return An array contains the information of all assets items
    */
  function getItemInfo() external view virtual returns (ItemDisplay[] memory) {
    ItemDisplay[] memory info = new ItemDisplay[](idList.length);
    for (uint256 i = 0; i < idList.length; ++i) {
      uint256 id = idList[i];
      info[i].id = id;
      info[i].price = saleList[id].price;
      info[i].startTime = saleList[id].startTime;
      info[i].endTime = saleList[id].endTime;
      info[i].count = saleList[id].count;
      info[i].restriction = saleList[id].restriction;
      info[i].maxCanSell = saleList[id].maxCanSell;
      info[i].maxSupply = saleList[id].maxSupply;
      info[i].coolDownTime = saleList[id].coolDownTime;
    }
    return info;
  }

  /**
    * @notice Get user's cool dowm time information in batch
    *
    * @return An array contains all informations
    */
  function getCoolDownInfo(address user_) external view virtual returns (CoolDownTimeDisplay[] memory) {
    CoolDownTimeDisplay[] memory info = new CoolDownTimeDisplay[](idList.length);
    for (uint256 i = 0; i < idList.length; ++i) {
      uint256 id = idList[i];
      info[i].id = id;
      info[i].coolDownTime = coolDownTimer[user_][id] + saleList[id].coolDownTime;
    }
    return info;
  }

  function pause() external virtual onlyOwner {
    _pause();
  }

  function unpause() external virtual onlyOwner {
    _unpause();
  }

  /**
    * @dev The Ether received will be logged with {Received} events. Note that these events are not fully
    * reliable: it's possible for a contract to receive Ether without triggering this function.
    */
  receive() external payable virtual {
      emit Received(_msgSender(), msg.value);
  }
}