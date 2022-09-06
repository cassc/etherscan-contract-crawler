pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SaleManager is ReentrancyGuard, PullPayment {
  using SafeERC20 for IERC20;

  AggregatorV3Interface priceOracle;
  IERC20 public immutable paymentToken;
  uint8 public immutable paymentTokenDecimals;

  struct Sale {
    address payable recipient; // the address that will receive sale proceeds
    address admin; // the address administering the sale
    bytes32 merkleRoot; // the merkle root used for proving access
    address claimManager; // address where purchased tokens can be claimed (optional)
    uint256 saleBuyLimit;  // max tokens that can be spent in total
    uint256 userBuyLimit;  // max tokens that can be spent per user
    uint256 purchaseMinimum; // minimum tokens that can be spent per purchase
    uint startTime; // the time at which the sale starts (seconds past the epoch)
    uint endTime; // the time at which the sale will end, regardless of tokens raised (seconds past the epoch)
    string uri; // reference to off-chain sale configuration (e.g. IPFS URI)
    uint256 price; // the price of the asset (eg if 1.0 NCT == $1.23 of USDC: 1230000)
    uint8 decimals; // the number of decimals in the asset being sold, e.g. 18
    uint256 totalSpent; // total purchases denominated in payment token
    uint256 maxQueueTime; // what is the maximum length of time a user could wait in the queue after the sale starts?
    uint160 randomValue; // reasonably random value: xor of merkle root and blockhash for transaction setting merkle root
    mapping(address => uint256) spent;
  }

  // this struct has two many members for a public getter
  mapping (bytes32 => Sale) private sales;

  // global metrics
  uint256 public saleCount = 0;
  uint256 public totalSpent = 0;

  // public version
  string public constant VERSION = '1.3';

  event NewSale(
    bytes32 indexed saleId,
    bytes32 indexed merkleRoot,
    address indexed recipient,
    address admin,
    uint256 saleBuyLimit,
    uint256 userBuyLimit,
    uint256 purchaseMinimum,
    uint256 maxQueueTime,
    uint startTime,
    uint endTime,
    string uri,
    uint256 price,
    uint8 decimals
  );

  event Deploy(address paymentToken, uint8 paymentTokenDecimals, address priceOracle);
  event UpdateStart(bytes32 indexed saleId, uint startTime);
  event UpdateEnd(bytes32 indexed saleId, uint endTime);
  event UpdateMerkleRoot(bytes32 indexed saleId, bytes32 merkleRoot);
  event UpdateMaxQueueTime(bytes32 indexed saleId, uint256 maxQueueTime);
  event Buy(bytes32 indexed saleId, address indexed buyer, uint256 value, bool native, bytes32[] proof);
  event RegisterClaimManager(bytes32 indexed saleId, address indexed claimManager);
  event UpdateUri(bytes32 indexed saleId, string uri);

  constructor(
    address _paymentToken,
    uint8 _paymentTokenDecimals,
    address _priceOracle
  ) payable {
    paymentToken = IERC20(_paymentToken);
    paymentTokenDecimals = _paymentTokenDecimals;
    priceOracle = AggregatorV3Interface(_priceOracle);
    emit Deploy(_paymentToken, _paymentTokenDecimals, _priceOracle);
  }

  modifier validSale (bytes32 saleId) {
    // if the admin is address(0) there is no sale struct at this saleId
    require(
      sales[saleId].admin != address(0),
      "invalid sale id"
    );
    _;
  }

  modifier isAdmin(bytes32 saleId) {
    // msg.sender is never address(0) so this handles uninitialized sales
    require(
      sales[saleId].admin == msg.sender,
      "must be admin"
    );
    _;
  }

  modifier canAccessSale(bytes32 saleId, bytes32[] calldata proof) {
    // make sure the buyer is an EOA
    require((msg.sender == tx.origin), "Must buy with an EOA");

    // If the merkle root is non-zero this is a private sale and requires a valid proof
    if (sales[saleId].merkleRoot != bytes32(0)) {
      require(
        this._isAllowed(
          sales[saleId].merkleRoot,
          msg.sender,
          proof
        ) == true,
        "bad merkle proof for sale"
      );
    }

    // Reduce congestion by randomly assigning each user a delay time in a virtual queue based on comparing their address and a random value
    // if sale.maxQueueTime == 0 the delay is 0
    require(block.timestamp - sales[saleId].startTime > getFairQueueTime(saleId, msg.sender), "not your turn yet");

    _;
  }

  modifier requireOpen(bytes32 saleId) {
    require(block.timestamp > sales[saleId].startTime, "sale not started yet");
    require(block.timestamp < sales[saleId].endTime, "sale ended");
    require(sales[saleId].totalSpent < sales[saleId].saleBuyLimit, "sale over");
    _;
  }

  // Get current price from chainlink oracle
  function getLatestPrice() public view returns (uint) {
    (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceOracle.latestRoundData();

    require(price > 0, "negative price");
    return uint(price);
  }

  // Accessor functions
  function getAdmin(bytes32 saleId) public validSale(saleId) view returns(address) {
    return(sales[saleId].admin);
  }

  function getRecipient(bytes32 saleId) public validSale(saleId) view returns(address) {
    return(sales[saleId].recipient);
  }

  function getMerkleRoot(bytes32 saleId) public validSale(saleId) view returns(bytes32) {
    return(sales[saleId].merkleRoot);
  }

  function getPriceOracle() public view returns(address) {
    return address(priceOracle);
  }

  function getClaimManager(bytes32 saleId) public validSale(saleId) view returns(address) {
    return (sales[saleId].claimManager);
  }


  function getSaleBuyLimit(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].saleBuyLimit);
  }

  function getUserBuyLimit(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].userBuyLimit);
  }

  function getPurchaseMinimum(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return(sales[saleId].purchaseMinimum);
  }

  function getStartTime(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].startTime);
  }

  function getEndTime(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].endTime);
  }

  function getUri(bytes32 saleId) public validSale(saleId) view returns(string memory) {
    return sales[saleId].uri;
  }

  function getPrice(bytes32 saleId) public validSale(saleId) view returns(uint) {
    return(sales[saleId].price);
  }

  function getDecimals(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return (sales[saleId].decimals);
  }

  function getTotalSpent(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return (sales[saleId].totalSpent);
  }

  function getRandomValue(bytes32 saleId) public validSale(saleId) view returns(uint160) {
    return sales[saleId].randomValue;
  }

  function getMaxQueueTime(bytes32 saleId) public validSale(saleId) view returns(uint256) {
    return sales[saleId].maxQueueTime;
  }

  function generateRandomishValue(bytes32 merkleRoot) public view returns(uint160) {
    /**
      Generate a randomish numeric value in the range [0, 2 ^ 160 - 1]

      This is not a truly random value:
      - miners can alter the previous block's hash by holding the transaction in the mempool
      - admins can choose when to submit the transaction
      - admins can repeatedly call setMerkleRoot()
    */
    return uint160(uint256(blockhash(block.number - 1))) ^ uint160(uint256(merkleRoot));
  }

  function getFairQueueTime(bytes32 saleId, address buyer) public validSale(saleId) view returns(uint) {
    /**
      Get the delay in seconds that a specific buyer must wait after the sale begins in order to buy tokens in the sale

      Buyers cannot exploit the fair queue when:
      - The sale is private (merkle root != bytes32(0))
      - Each eligible buyer gets exactly one address in the merkle root

      Although miners and admins can minimize the delay for an arbitrary address, these are not significant threats
      - the economic opportunity to miners is zero or relatively small (only specific addresses can participate in private sales, and a better queue postion does not imply high returns)
      - admins can repeatedly set merkle roots (but admins already control the tokens being sold!)

    */
    if (sales[saleId].maxQueueTime == 0) {
      // there is no delay: all addresses may participate immediately
      return 0;
    }

    // calculate a distance between the random value and the user's address using the XOR distance metric (c.f. Kademlia)
    uint160 distance = uint160(buyer) ^ sales[saleId].randomValue;

    // calculate a speed at which the queue is exhausted such that all users complete the queue by sale.maxQueueTime
    uint160 distancePerSecond = type(uint160).max / uint160(sales[saleId].maxQueueTime);
    // return the delay (seconds)
    return distance / distancePerSecond;
  }

  function spentToBought(bytes32 saleId, uint256 spent) public view returns (uint256) {
    // Convert tokens spent (e.g. 10,000,000 USDC = $10) to tokens bought (e.g. 8.13e18) at a price of $1.23/NCT
    // convert an integer value of tokens spent to an integer value of tokens bought
    return (spent * 10 ** sales[saleId].decimals ) / (sales[saleId].price);
  }

  function nativeToPaymentToken(uint256 nativeValue) public view returns (uint256) {
    // convert a payment in the native token (eg ETH) to an integer value of the payment token
    return (nativeValue * getLatestPrice() * 10 ** paymentTokenDecimals) / (10 ** (priceOracle.decimals() + 18));
  }

  function getSpent(
      bytes32 saleId,
      address userAddress
    ) public validSale(saleId) view returns(uint256) {
    // returns the amount spent by this user in paymentToken
    return(sales[saleId].spent[userAddress]);
  }

  function getBought(
      bytes32 saleId,
      address userAddress
    ) public validSale(saleId) view returns(uint256) {
    // returns the amount bought by this user in the new token being sold
    return(spentToBought(saleId, sales[saleId].spent[userAddress]));
  }

  function isOpen(bytes32 saleId) public validSale(saleId) view returns(bool) {
    // is the sale currently open?
    return(
      block.timestamp > sales[saleId].startTime
      && block.timestamp < sales[saleId].endTime
      && sales[saleId].totalSpent < sales[saleId].saleBuyLimit
    );
  }

  function isOver(bytes32 saleId) public validSale(saleId) view returns(bool) {
    // is the sale permanently over?
    return(
      block.timestamp >= sales[saleId].endTime || sales[saleId].totalSpent >= sales[saleId].saleBuyLimit
    );
  }

  /**
  sale setup and config
  - the address calling this method is the admin: only the admin can change sale configuration
  - all payments are sent to the the recipient
  */
  function newSale(
    address payable recipient,
    bytes32 merkleRoot,
    uint256 saleBuyLimit,
    uint256 userBuyLimit,
    uint256 purchaseMinimum,
    uint startTime,
    uint endTime,
    uint160 maxQueueTime,
    string memory uri,
    uint256 price,
    uint8 decimals
  ) public returns(bytes32) {
    require(recipient != address(0), "recipient must not be zero address");
    require(startTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(endTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(startTime < endTime, "sale must start before it ends");
    require(endTime > block.timestamp, "sale must end in future");
    require(userBuyLimit <= saleBuyLimit, "userBuyLimit cannot exceed saleBuyLimit");
    require(purchaseMinimum <= userBuyLimit, "purchaseMinimum cannot exceed userBuyLimit");
    require(userBuyLimit > 0, "userBuyLimit must be > 0");
    require(saleBuyLimit > 0, "saleBuyLimit must be > 0");
    require(endTime - startTime > maxQueueTime, "sale must be open for longer than max queue time");

    // Generate a reorg-resistant sale ID
    bytes32 saleId = keccak256(abi.encodePacked(
      merkleRoot,
      recipient,
      saleBuyLimit,
      userBuyLimit,
      purchaseMinimum,
      startTime,
      endTime,
      uri,
      price,
      decimals
    ));

    // This ensures the Sale struct wasn't already created (msg.sender will never be the zero address)
    require(sales[saleId].admin == address(0), "a sale with these parameters already exists");

    Sale storage s = sales[saleId];

    s.merkleRoot = merkleRoot;
    s.admin = msg.sender;
    s.recipient = recipient;
    s.saleBuyLimit = saleBuyLimit;
    s.userBuyLimit = userBuyLimit;
    s.purchaseMinimum = purchaseMinimum;
    s.startTime = startTime;
    s.endTime = endTime;
    s.price = price;
    s.decimals = decimals;
    s.uri = uri;
    s.maxQueueTime = maxQueueTime;
    s.randomValue = generateRandomishValue(merkleRoot);

    saleCount++;

    emit NewSale(
      saleId,
      s.merkleRoot,
      s.recipient,
      s.admin,
      s.saleBuyLimit,
      s.userBuyLimit,
      s.purchaseMinimum,
      s.maxQueueTime,
      s.startTime,
      s.endTime,
      s.uri,
      s.price,
      s.decimals
    );

    return saleId;
  }

  function setStart(bytes32 saleId, uint startTime) public validSale(saleId) isAdmin(saleId) {
    // admin can update start time until the sale starts
    require(block.timestamp < sales[saleId].endTime, "disabled after sale close");
    require(startTime < sales[saleId].endTime, "sale start must precede end");
    require(startTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(sales[saleId].endTime - startTime > sales[saleId].maxQueueTime, "sale must be open for longer than max queue time");

    sales[saleId].startTime = startTime;
    emit UpdateStart(saleId, startTime);
  }

  function setEnd(bytes32 saleId, uint endTime) public validSale(saleId) isAdmin(saleId){
    // admin can update end time until the sale ends
    require(block.timestamp < sales[saleId].endTime, "disabled after sale closes");
    require(endTime > block.timestamp, "sale must end in future");
    require(endTime <= 4102444800, "max: 4102444800 (Jan 1 2100)");
    require(sales[saleId].startTime < endTime, "sale must start before it ends");
    require(endTime - sales[saleId].startTime > sales[saleId].maxQueueTime, "sale must be open for longer than max queue time");

    sales[saleId].endTime = endTime;
    emit UpdateEnd(saleId, endTime);
  }

  function setMerkleRoot(bytes32 saleId, bytes32 merkleRoot) public validSale(saleId) isAdmin(saleId){
    require(!isOver(saleId), "cannot set merkle root once sale is over");
    sales[saleId].merkleRoot = merkleRoot;
    sales[saleId].randomValue = generateRandomishValue(merkleRoot);
    emit UpdateMerkleRoot(saleId, merkleRoot);
  }

  function setMaxQueueTime(bytes32 saleId, uint160 maxQueueTime) public validSale(saleId) isAdmin(saleId) {
    // the queue time may be adjusted after the sale begins
    require(sales[saleId].endTime > block.timestamp, "cannot adjust max queue time after sale ends");
    sales[saleId].maxQueueTime = maxQueueTime;
    emit UpdateMaxQueueTime(saleId, maxQueueTime);
  }

  function setUriAndMerkleRoot(bytes32 saleId, bytes32 merkleRoot, string calldata uri) public validSale(saleId) isAdmin(saleId) {
    sales[saleId].uri = uri;
    setMerkleRoot(saleId, merkleRoot);
    emit UpdateUri(saleId, uri);
  }

  function _isAllowed(
      bytes32 root,
      address account,
      bytes32[] calldata proof
  ) external pure returns (bool) {
    // check if the account is in the merkle tree
    bytes32 leaf = keccak256(abi.encodePacked(account));
    if (MerkleProof.verify(proof, root, leaf)) {
      return true;
    }
    return false;
  }

  // pay with the payment token (eg USDC)
  function buy(
    bytes32 saleId,
    uint256 tokenQuantity,
    bytes32[] calldata proof
  ) public validSale(saleId) requireOpen(saleId) canAccessSale(saleId, proof) nonReentrant {
    // make sure the purchase would not break any sale limits
    require(
      tokenQuantity >= sales[saleId].purchaseMinimum,
      "purchase below minimum"
    );

    require(
      tokenQuantity + sales[saleId].spent[msg.sender] <= sales[saleId].userBuyLimit,
      "purchase exceeds your limit"
    );

    require(
      tokenQuantity + sales[saleId].totalSpent <= sales[saleId].saleBuyLimit,
      "purchase exceeds sale limit"
    );

    require(paymentToken.allowance(msg.sender, address(this)) >= tokenQuantity, "allowance too low");

    // move the funds
    paymentToken.safeTransferFrom(msg.sender, sales[saleId].recipient, tokenQuantity);

    // effects after interaction: we need a reentrancy guard
    sales[saleId].spent[msg.sender] += tokenQuantity;
    sales[saleId].totalSpent += tokenQuantity;
    totalSpent += tokenQuantity;

    emit Buy(saleId, msg.sender, tokenQuantity, false, proof);
  }

  // pay with the native token
  function buy(
    bytes32 saleId,
    bytes32[] calldata proof
  ) public payable validSale(saleId) requireOpen(saleId) canAccessSale(saleId, proof) nonReentrant {
    // convert to the equivalent payment token value from wei
    uint256 tokenQuantity = nativeToPaymentToken(msg.value);
  
    // make sure the purchase would not break any sale limits
    require(
      tokenQuantity >= sales[saleId].purchaseMinimum,
      "purchase below minimum"
    );

    require(
      tokenQuantity + sales[saleId].spent[msg.sender] <= sales[saleId].userBuyLimit,
      "purchase exceeds your limit"
    );

    require(
      tokenQuantity + sales[saleId].totalSpent <= sales[saleId].saleBuyLimit,
      "purchase exceeds sale limit"
    );

    // Forward eth to PullPayment escrow for withdrawal to recipient
    /**
     * @dev OZ PullPayment._asyncTransfer
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract,
     * so there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    _asyncTransfer(getRecipient(saleId), msg.value);

    // account for the purchase in equivalent payment token value
    sales[saleId].spent[msg.sender] += tokenQuantity;
    sales[saleId].totalSpent += tokenQuantity;
    totalSpent += tokenQuantity;

    // flag this payment as using the native token
    emit Buy(saleId, msg.sender, tokenQuantity, true, proof);
  }

  // Tell users where they can claim tokens
  function registerClaimManager(bytes32 saleId, address claimManager) public validSale(saleId) isAdmin(saleId) {
    require(claimManager != address(0), "Claim manager must be a non-zero address");
    sales[saleId].claimManager = claimManager;
    emit RegisterClaimManager(saleId, claimManager);
  }

  function recoverERC20(bytes32 saleId, address tokenAddress, uint256 tokenAmount) public isAdmin(saleId) {
    IERC20(tokenAddress).transfer(getRecipient(saleId), tokenAmount);
  }
}