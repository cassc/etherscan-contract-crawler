// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

abstract contract Ownable is Context {
    address internal _owner;
    mapping(address => bool) private _proxies;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender() || _proxies[_msgSender()] == true, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyProxy() {
        require(_proxies[_msgSender()] == true, "Not allowed to call the function");
        _;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function addProxy(address newProxy) internal virtual onlyOwner {
        _proxies[newProxy] = true;
    }
}

/*
    buy 5 nfts get 10% off ----  buy 10 nfts get 15% off ----- buy 25 nfts get 25% off

    pre-sale 400 nfts = $500 each
    phase 1 - 1200 nfts = $1000 each
    final phase 400 nfts = $1500 each 
*/
contract BoredApeWatchCoin is Ownable, ERC1155Supply, ReentrancyGuard {

    struct Group { 
      string title;
      uint256 qty;
      uint256 price;
      uint256 currency; // 0-USD, 1-ETH
    }

    using Strings for uint256;
    using ECDSA for bytes32;

    string private _name;
    string private _symbol;

    uint256 public constant TYPE_GOLD   = 1;
    uint256 public constant TYPE_SILVER = 2;
    uint256 public constant TYPE_BRONZE = 3;
    
    uint256 public constant TYPE_BAYC = 1;
    uint256 public constant TYPE_MAYC = 2;



    uint256 public currentGroupId = 1;
    uint256 public constant TOTAL_GROUPS = 3;
    mapping(uint256 => Group) private  _groups;

    uint256 public  ITEM_PER_MINT = 25;
    
    mapping(address => mapping(uint256 => uint256)) public buyerListPurchases; // address -> group : count
    mapping(uint256 => mapping(uint256 => bool)) public watchOrdered; //address -> token type (BAYC, MAYC) : bool
    //
    string private _contractURI;
    string private _tokenBaseURI = "https://baseuri.com/";
    address private _fAddr = address(0);
    address private _sgnAddr = address(0);

    string public proof;
    uint256 public amountMinted;
    bool public saleLive = true;
    bool public locked = false;
    bool private _initialized = false;
    AggregatorV3Interface internal priceFeed;
    bool public priceFeedLive = false;

    
    /**
     * Chainlink for Oracle in BSC
     * Network: Binance Smart Chain
     * Aggregator: BNB/USD
     * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE (Mainnet)
     * Address: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526 (Testnet)
     * Reference: https://docs.chain.link/docs/binance-smart-chain-addresses/
     
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 (Mainnet)
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e (Rinkeby Testnet)
     * Reference: https://docs.chain.link/docs/ethereum-addresses/
    */
    address private mainPriceAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address private testPriceAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    constructor() ERC1155("") {}
    function name() public view  returns (string memory) {
        return _name;
    }
    function symbol() public view  returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return amountMinted;
    }
    function etherPrice(int _usd) public view returns (int) 
    {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return _usd * (10 ** 18) / price;
    }
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        _tokenBaseURI = newuri;
    }
    function uri(uint256 typeId) public view override returns (string memory) {
        return string(abi.encodePacked(_tokenBaseURI, typeId.toString()));
    }
    /*
    *   Define Modifiers
    */
    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
    /*
    *  Define public and external functions
    */
    function togglePriceFeedSource() external onlyOwner {
        priceFeedLive = !priceFeedLive;
        if(priceFeedLive) {
            priceFeed = AggregatorV3Interface(mainPriceAddress);
        } else {
            priceFeed = AggregatorV3Interface(testPriceAddress);
        }
    } 
    function currentGroup() public view returns(Group memory) {
        return _groups[currentGroupId];
    }

    function initialize(string memory name_, string memory symbol_, address ownerAddr, address signerAddr, bool feedLive) external onlyOwner {
        require(ownerAddr  != address(0), "INVALID_FADDR");
        require(signerAddr  != address(0), "INVALID_SNGADDR");
        require(!_initialized , "Already initialized");

        _name = name_;
        _symbol = symbol_;

        _fAddr = ownerAddr;
        _sgnAddr = signerAddr;
        addProxy(_fAddr);
        addProxy(_sgnAddr);

        _groups[1] = Group({ qty:100, price: 0.001 ether , title:"Gold", currency: 1 });
        _groups[2] = Group({ qty:300, price: 0.002 ether , title:"Silver", currency: 1 });
        _groups[3] = Group({ qty:600, price: 0.003 ether, title:"Bronze", currency: 1 });
        
        if(feedLive) {
            priceFeed = AggregatorV3Interface(mainPriceAddress);
        } else {
            priceFeed = AggregatorV3Interface(testPriceAddress);
        }

        _initialized = true;

    }
    function setGroup(uint256 _groupId, uint256 _qty, uint256 _price, string memory _title, uint256 currency) external onlyOwner {
        require(_initialized , "Not initialized");
        require(_groupId >= 1 && _groupId <= TOTAL_GROUPS, "OUT_OF_PHASE_INDEX");
        _groups[_groupId].qty = _qty;
        _groups[_groupId].price = _price;
        _groups[_groupId].title = _title;
        _groups[_groupId].currency = currency;
        
    }
    function getGroup(uint256 _groupId) external view returns(Group memory) {
        require(_groupId >= 1 && _groupId <= TOTAL_GROUPS, "OUT_OF_PHASE_INDEX");
        return _groups[_groupId];
    }
    function availableBalance(uint256 _groupId)  public view returns(uint256) {
        uint256 maxSupply = 0;
        uint256 supplied = totalSupply(_groupId);
        maxSupply = _groups[_groupId].qty;
        uint256 availableSupply = maxSupply >= supplied ? maxSupply - supplied : 0;
        return availableSupply;
    }
  //------------------
    function addBuyerList(address[] calldata entries, uint[] calldata groups, uint[] calldata qty) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            require(entries[i] != address(0), "NULL_ADDRESS");
            buyerListPurchases[entries[i]][groups[i]] = qty[i];
        }   
    }

    function removeBuyerList(address[] calldata entries, uint[] calldata groups) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            require(entries[i] != address(0), "NULL_ADDRESS");
            buyerListPurchases[entries[i]][groups[i]] = 0;
        }
    }
    function buyOrder(uint256 tokenQuantity, uint256 orderTokenType, uint256 orderTokenId) external nonReentrant payable {
        require(saleLive, "SALE_CLOSED");
        require(tokenQuantity > 0, "ZERO_QUANTITY");
        require(!watchOrdered[orderTokenType][orderTokenId], "ALREADY_ORDERED");
        uint256 currentGroupBalance = availableBalance(currentGroupId);
        if(currentGroupBalance == 0)
        {
            if(currentGroupId >= TOTAL_GROUPS)
            {
                saleLive = false;
                revert("SALE_CLOSED");
            } else {
                currentGroupId++;
                currentGroupBalance = availableBalance(currentGroupId);
            }
        } else {
            currentGroupBalance = availableBalance(currentGroupId);
        }
        require(currentGroupBalance >= tokenQuantity,
                string(abi.encodePacked("Remaining Tokens: ", currentGroupBalance.toString(), " in this phase"))
                );

        uint256 theFee = 0.0005 ether;
        require(buyPrice(tokenQuantity) <= msg.value + theFee, "INSUFFICIENT_ETH");

        _mint(msg.sender, currentGroupId, tokenQuantity, "");
        amountMinted += tokenQuantity;
        buyerListPurchases[msg.sender][currentGroupId]+=tokenQuantity;
        watchOrdered[orderTokenType][orderTokenId] = true;
    }
    function mintByOwner(uint256 groupId, uint256 tokenQuantity) external onlyOwner {
        require(tokenQuantity > 0, "ZERO_QUANTITY");
        require(totalSupply(groupId) + tokenQuantity<= _groups[groupId].qty, "OUT_OF_STOCK");
        _mint(msg.sender, groupId, tokenQuantity, "");
        amountMinted += tokenQuantity;
        buyerListPurchases[msg.sender][groupId]+=tokenQuantity;
    }
    function buyPrice(uint256 tokenQuantity) public view returns(uint256) {
        Group memory phase = _groups[currentGroupId];
        uint256 orgPrice = phase.price;
        uint256 currency = phase.currency;
        if(currency < 1) {
            int eth = etherPrice(int(orgPrice));
            return uint256(eth) * tokenQuantity * 10 ** 8;
        }
        return orgPrice * tokenQuantity;
    }
    
    function withdraw() external onlyOwner {
        if(_owner == _msgSender()) {
            require(!saleLive, "Not allowed to call: saleLive");
        }
        require(_owner != _msgSender(), "The operation is in-progress");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function buyerPurchasedCount(address addr, uint256 groupId) external view returns (uint256) {
        return buyerListPurchases[addr][groupId];
    }
    function alreadyOrdered(uint256 orderTokenType, uint256 orderTokenId) external view returns (bool) {
        return watchOrdered[orderTokenType][orderTokenId];
    }
    
    // Owner functions for enabling presale, sale, revealing and setting the provenance hash
    function toggleLockMetadata() external onlyOwner {
        locked = !locked;
    }
    
    function toggleSaleStatus() external onlyProxy {
        saleLive = !saleLive;
    }
    
    function setSignerAddress(address addr) external onlyOwner {
        _sgnAddr = addr;
    }
    
    function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
        proof = hash;
    }
    
    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }
    
    // aWYgeW91IHJlYWQgdGhpcywgc2VuZCBGcmVkZXJpayMwMDAxLCAiZnJlZGR5IGlzIGJpZyI=
    function contractURI() public view returns (string memory) {
        
        return _contractURI;
    }
    /*
    * Define Private and Internal Functions
    */
    function _hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce)))
          );
          
          return hash;
    }
    
    function _matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _sgnAddr == hash.recover(signature);
    }

    // The following functions are overrides required by Solidity.
}