// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

// Import the chainlink Aggregator Interface
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

// secruity agaignst transactions for multiple request
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import 'hardhat/console.sol';

contract AMAMarket is ERC721URIStorage, ReentrancyGuard {
  using Counters for Counters.Counter;
  AggregatorV3Interface internal priceFeed;

  /* numbers of items mininting, number of transactions, tokens that have not been sold
   keep track of tokens total number - tokenId
   arrays need to know the length - help to keep track for arrays */

  Counters.Counter private _tokenIds;
  Counters.Counter private _itemsSold;

  // determine who is the owner of the contract
  // charge a listing fee so the owner makes a commission
  address payable owner;
  address payable host;

  // maps the latest message
  mapping(address => uint256) public last_msg_index;

  // returns latest questions
  mapping(address => mapping(uint256 => Question)) public questions;

  // tokenId return which marketToken - fetch which one it is
  mapping(uint256 => MarketToken) private idToMarketToken;

  //structs can act like objects
  struct MarketToken {
    uint256 tokenId;
    address payable creator;
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
    bool deleted;
    uint256 mintDate;
  }

  struct Question {
    address payable from;
    string text;
    uint256 time;
    uint256 price;
    bool sold;
    bool question_withdrawn;
    uint256 endTime;
  }

  // tells the frontend that a new message has been sent.
  event QuestionSent(
    address indexed _sender,
    address indexed _receiver,
    uint256 _time,
    string question,
    uint256 _price,
    bool _sold,
    bool question_withdrawn,
    uint256 endTime
  );

  // listen to events from front end applications
  event MarketTokenMinted(
    uint256 indexed tokenId,
    address creator,
    address seller,
    address owner,
    uint256 price,
    bool sold,
    bool deleted,
    uint256 mintDate
  );
  event ProductListed(uint256 indexed itemId);
  event Withdraw(address indexed from, uint256 price);
  event questionDeleted(address indexed owner, uint256 indexed itemId);

  constructor() ERC721('Eroteme', 'ERO') {
    //set the owner
    owner = payable(msg.sender);
    // contract host
    host = payable(0xD49d633214181a4Ad979eA0778A0FFa59f87D22f);

    /** Define the priceFeed
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
     */
    priceFeed = AggregatorV3Interface( 
      0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );
  }

  // only product owner can do this operation
  modifier onlyItemOwner(uint256 id) {
    require(
      idToMarketToken[id].owner == msg.sender,
      'Only product owner can do this operation'
    );
    _;
  }

  /**
   * Returns the latest price and # of decimals to use
   */
  function getLatestPrice() public view returns (int256, uint8) {
    // Unused returned values are left out, hence lots of ","s
    (, int256 price, , , ) = priceFeed.latestRoundData();
    uint8 decimals = priceFeed.decimals();
    return (price, decimals);
  }

  // two functions to interact with contract
  /* Mints a token and lists it in the marketplace */
  /* create a market sale for buying and selling between parties */
  function createToken(string memory tokenURI, uint256 price)
    public
    payable
    nonReentrant
    returns (uint256)
  {
    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();

    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    makeMarketItem(newTokenId, price);
    return newTokenId;
  }

  function makeMarketItem(uint256 tokenId, uint256 price) private {
    require(price > 0, 'Price must be at least 1 wei');

    //putting it up for sale - bool - no owner
    idToMarketToken[tokenId] = MarketToken(
      tokenId,
      payable(msg.sender),
      payable(msg.sender),
      payable(address(0)),
      price,
      false,
      false,
      block.timestamp
    );

    // NFT transaction
    _transfer(msg.sender, address(this), tokenId);

    emit MarketTokenMinted(
      tokenId,
      msg.sender,
      msg.sender,
      address(0),
      price,
      false,
      false,
      block.timestamp
    );
  }

  /*
    two functions to interact with contract 
    mints a token  
    create a market sale for buying and selling between parties with owner already set 
  */
  function createAnsweredToken(
    string memory tokenURI,
    uint256 price,
    address _owner,
    address _who,
    uint256 _index,
    uint256 _endTime
  ) public payable nonReentrant returns (uint256) {
    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();

    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    makeAnswerItem(newTokenId, price, _owner, _who, _index, _endTime);
    return newTokenId;
  }

  function makeAnswerItem(
    uint256 tokenId,
    uint256 price,
    address _owner,
    address _who,
    uint256 _index,
    uint256 _endTime
  ) public payable returns (bool) {
    /* nonReentrant is a modifier to prevent reentry attack */
    require(questions[_who][_index - 1].sold == false, 'Item must be unsold');
    require(block.timestamp < _endTime, 'question has passed deadline');
    require(
      questions[_who][_index - 1].question_withdrawn != true,
      'question must not be withdrawn'
    );

    /* putting it up for sale - bool - with owner */
    idToMarketToken[tokenId] = MarketToken(
      tokenId,
      payable(msg.sender),
      payable(msg.sender),
      payable(_owner),
      price,
      true,
      false,
      block.timestamp
    );

    /* NFT transaction */
    _transfer(msg.sender, _owner, tokenId);

    payable(msg.sender).transfer((price / 100) * 98);
    payable(host).transfer((price / 100) * 2);
    _itemsSold.increment();

    emit MarketTokenMinted(
      tokenId,
      msg.sender,
      msg.sender,
      _owner,
      price,
      true,
      false,
      block.timestamp
    );
    return (questions[_who][_index - 1].sold = true);
  }

  /* Delete NFT */
  function deleteQuestion(uint256 itemId) external onlyItemOwner(itemId) {
    delete (idToMarketToken[itemId]);
    idToMarketToken[itemId].tokenId = itemId;
    idToMarketToken[itemId].deleted = true;
    emit questionDeleted(msg.sender, itemId);
  }

  /* function to conduct transactions and market sales */
  function createMarketSale(uint256 itemId) public payable nonReentrant {
    uint256 price = idToMarketToken[itemId].price;
    uint256 tokenId = idToMarketToken[itemId].tokenId;
    require(
      msg.value == price,
      'Please submit the asking price in order to continue'
    );

    /* transfer the amount to the seller and creator */
    idToMarketToken[itemId].seller.transfer((msg.value / 100) * 91);
    idToMarketToken[itemId].creator.transfer((msg.value / 100) * 7);
    idToMarketToken[itemId].owner = payable(msg.sender);
    idToMarketToken[itemId].sold = true;
    _itemsSold.increment();

    /* transfer the token from contract address to the buyer */
    _transfer(address(this), msg.sender, tokenId);
    payable(host).transfer((msg.value / 100) * 2);
  }

  /* function to put transactions and market sales back on the Market */
  function putItemToResell(uint256 itemId, uint256 newPrice)
    public
    payable
    nonReentrant
    onlyItemOwner(itemId)
  {
    uint256 tokenId = idToMarketToken[itemId].tokenId;
    require(newPrice > 0, 'Price must be at least 1 wei');
    /* call the custom transfer token method */

    address payable oldOwner = idToMarketToken[itemId].owner;
    idToMarketToken[itemId].owner = payable(address(0));
    idToMarketToken[itemId].seller = oldOwner;
    idToMarketToken[itemId].price = newPrice;
    idToMarketToken[itemId].sold = false;
    _itemsSold.decrement();
    _transfer(msg.sender, address(this), tokenId);
    emit ProductListed(itemId);
  }

  /* function to fetchMarketItems - minting, buying and seling 
   return the number of unsold items */
  function fetchMarketTokens() public view returns (MarketToken[] memory) {
    uint256 itemCount = _tokenIds.current();
    uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
    uint256 currentIndex = 0;

    /* looping over the number of items created (if number has not been sold populate the array) */
    MarketToken[] memory items = new MarketToken[](unsoldItemCount);
    for (uint256 i = 0; i < itemCount; i++) {
      if (
        idToMarketToken[i + 1].owner == address(0) &&
        idToMarketToken[i + 1].deleted == false
      ) {
        uint256 currentId = i + 1;
        MarketToken storage currentItem = idToMarketToken[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* returns selected nft */
  function fetchMarketToken(uint256 itemId)
    external
    view
    returns (MarketToken memory)
  {
    return idToMarketToken[itemId];
  }

  /* return nfts that the user has purchased */
  function fetchMyNFTs() public view returns (MarketToken[] memory) {
    uint256 totalItemCount = _tokenIds.current();
    // a second counter for each individual
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketToken[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    /* second loop to loop through the amount you have purchased with itemcount
    check to see if the owner address is equal to msg.sender */
    MarketToken[] memory items = new MarketToken[](itemCount);
    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketToken[i + 1].owner == msg.sender) {
        uint256 currentId = idToMarketToken[i + 1].tokenId;
        /* current array */
        MarketToken storage currentItem = idToMarketToken[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* function for returning an array of minted nfts */
  function fetchItemsCreated() public view returns (MarketToken[] memory) {
    /* instead of .owner it will be the creator */
    uint256 totalItemCount = _tokenIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketToken[i + 1].creator == msg.sender) {
        itemCount += 1;
      }
    }

    /* second loop to loop through the amount you have purchased with itemcount
     check to see if the owner address is equal to msg.sender */
    MarketToken[] memory items = new MarketToken[](itemCount);
    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketToken[i + 1].creator == msg.sender) {
        uint256 currentId = idToMarketToken[i + 1].tokenId;
        MarketToken storage currentItem = idToMarketToken[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* function for returning an array of minted nfts */
  function fetchItemsForSale() public view returns (MarketToken[] memory) {
    /* instead of .owner it will be the seller */
    uint256 totalItemCount = _tokenIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketToken[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    /* second loop to loop through the amount you have purchased with itemcount
     check to see if the owner address is equal to msg.sender */
    MarketToken[] memory items = new MarketToken[](itemCount);
    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketToken[i + 1].seller == msg.sender) {
        uint256 currentId = idToMarketToken[i + 1].tokenId;
        /* current array */
        MarketToken storage currentItem = idToMarketToken[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* function to ask questions */
  function sendQuestion(
    address _to,
    string memory _text,
    uint256 _price,
    uint256 _number_of_days
  ) public payable nonReentrant {
    require(_price > 0, 'Price must be at least 1 wei');
    questions[_to][last_msg_index[_to]].from = payable(msg.sender);
    questions[_to][last_msg_index[_to]].text = _text;
    questions[_to][last_msg_index[_to]].time = block.timestamp;
    questions[_to][last_msg_index[_to]].price = _price;
    questions[_to][last_msg_index[_to]].sold = false;
    questions[_to][last_msg_index[_to]].question_withdrawn = false;
    questions[_to][last_msg_index[_to]].endTime =
      block.timestamp +
      _number_of_days *
      1 days;
    last_msg_index[_to]++;
    emit QuestionSent(
      msg.sender,
      _to,
      block.timestamp,
      _text,
      _price,
      false,
      false,
      _number_of_days
    );
  }

  /* function to get index of the last questions */
  function lastIndex(address _owner) public view returns (uint256) {
    return last_msg_index[_owner];
  }

  /* function to get questions by index */
  function getQuestionByIndex(address _who, uint256 _index)
    public
    view
    returns (
      address,
      string memory,
      uint256,
      uint256,
      bool,
      bool,
      uint256
    )
  {
    Question memory question = questions[_who][_index - 1];
    return (
      question.from,
      question.text,
      question.time,
      question.price,
      question.sold,
      question.question_withdrawn,
      question.endTime
    );
  }

  /* function to withdraw and cancel questions */
  function withdraw(
    address _who,
    uint256 _index,
    address from,
    uint256 price,
    uint256 _endTime
  ) external nonReentrant returns (bool) {
    require(questions[_who][_index - 1].sold == false, 'Item must be unsold');
    require(block.timestamp > _endTime, 'question has passed deadline');
    from = questions[_who][_index - 1].from;
    price = questions[_who][_index - 1].price;
    payable(from).transfer(price);
    emit Withdraw(from, price);
    return (questions[_who][_index - 1].question_withdrawn = true);
  }
}