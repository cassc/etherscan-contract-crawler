// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IERC4906.sol";

/// @title Base NFT contract for dispatch ecommerce stores
/// @author Dispatch.co
/// @dev 1 store contract per org
contract DispatchStore is ERC721, IERC4906, Ownable, Pausable, ReentrancyGuard {
  // used to set our prices in USD
  AggregatorV3Interface internal priceFeed;
  // the fee as a percentage
  // 10 percent is the default
  uint8 public DISPATCH_FEE = 10;
  // math in solidity is annoying because decimals don't work. We set ours to a precision range of 4, or
  uint8 public PRECISION_DECIMALS = 1e2;
  // because overflows are scary
  using SafeMath for uint256;
  // because strongly typed languages are also scary
  using Strings for uint256;
  using Strings for address;
  // dispatch wallet to which we send funds
  address payable public dispatchTreasuryAddress;
  // merchant wallet to which we send funds
  address payable public merchantTreasuryAddress;
  // whitelisted addresses can burn + transfer + set prices
  mapping(address => bool) public whiteListedAddress;
  // optional store property which limits the number of NFTs a given address can hold from this collection
  // used to prevent 1 address from buying up all the supply as an optional safety measure
  uint256 public maxStoreBalanceAllowance = 0;
  // base NFT API uri
  string public productBaseURI;
  // we use numerical productIdCounters which map to TokenIds to create "Product associations"
  uint256 public productIdCounter;
  // we use numerical tokenIdCounters which map to productIds to create "Product associations"
  uint256 public tokenIdCounter;
  // maps the nftID to a particular tokenURI
  mapping(uint256 => uint256) public tokenIDtoproductIdCounterMap;

  // productIdCounter to ProductDetails mapping
  mapping(uint256 => ProductDetails) public product;

  // metadata for any product
  struct ProductDetails {
    uint256 productPrice; // optional
    uint256 productTotalSupply; // cannot be set
    uint256 productMaxSupply; // required
    uint256 productBurns; // cannot be set
    string productCollectionUri; // required
    address productTokenGateAddress; // optional
    uint256 productTokenGateTokenId; // optional
  }

  // used when leveraging optional token gating
  IERC1155 private ERC1155TokenGate;
  IERC721 private ERC721TokenGate;

  // fires when address whitelist status changes
  event WhitelistChanged(address indexed _address, bool _isWhitelisted);
  // fires event when the rate changes
  event DispatchRateChanged(uint256 indexed _newRate);
  // fires when an product's details change
  event ProductDetailsChanged(
    uint256 indexed _productId,
    uint256 _productPrice,
    uint256 _productTotalSupply,
    uint256 _productMaxSupply,
    uint256 _productBurns,
    address _productTokenGateAddress,
    uint256 _productTokenGateTokenId
  );
  // fires when a sale is made
  event SaleEvent(
    uint256 indexed _productId, // id of the product
    address _receiver, // who receives the product
    uint256 _amountInBatch, // quantity of the product received
    uint256 _tokenId, // tokenId
    ProductDetails _product, // details of the product purchased
    uint256 _l1Price, // price quoted by the oracle
    string _data // arbitrary string data
  );

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    address payable dispatchTreasuryAddress_,
    address payable merchantTreasuryAddress_,
    ProductDetails[] memory inventory,
    address[] memory toWhitelist,
    address _priceContractAddr
  ) ERC721(name_, symbol_) {
    // chainklink oracle to convert USD to ETH
    priceFeed = AggregatorV3Interface(_priceContractAddr);
    // set where the money goes
    setTreasuryAddresses(dispatchTreasuryAddress_, merchantTreasuryAddress_);
    // set base URI
    productBaseURI = baseURI_;
    // create an initial set of products
    createNewProductBulk(inventory);
    // whitelist a set of initial addresses
    for (uint256 i; i < toWhitelist.length; i++) {
      setWhitelistedAddress(toWhitelist[i], true);
    }
  }

  // --------------------- MODIFIERS ---------------------

  modifier _isValidAmount(uint256 _amount, uint256 _productId) {
    // checks that the user is holding the NFT
    require(
      _amount >= 1 && product[_productId].productTotalSupply.add(_amount) <= product[_productId].productMaxSupply,
      "Cannot exceed product total supply."
    );
    _;
  }

  modifier _isWhitelistedAddress() {
    // checks that the user is the owner or is whitelisted
    require(
      msg.sender == owner() || whiteListedAddress[msg.sender] == true,
      "Must be the owner or be whitelisted address."
    );
    _;
  }

  /**
      @notice Verifies the product exists by checking the URI definition
      @param _productId new product base URI
   */
  function _isValidProduct(uint256 _productId) private view {
    // checks that the user is holding the NFT
    require(bytes(product[_productId].productCollectionUri).length > 0, "This product does not exist.");
  }

  /**
      @notice Verifies the product exists by checking the URI definition
      @param _amount amount of tokens
      @param _addr address to accept the tokens
   */
  function _isValidTransferOfSum(uint256 _amount, address _addr) private view {
    // checks that the user is holding the NFT
    if (maxStoreBalanceAllowance > 0 && _addr != address(0)) {
      require(
        balanceOf(_addr).add(_amount) <= maxStoreBalanceAllowance,
        "Cannot exceed the maxStoreBalanceAllowance for a given address."
      );
    }
  }

  // --------------------- OWNER FUNCTIONS ---------------------

  /**
      @notice Allows owner to set the products base URI.
      @param _newUri new product base URI
   */
  function setBaseURI(string memory _newUri) external onlyOwner {
    productBaseURI = _newUri;
  }

  /**
      @notice Allows owner can pause the contract
      @param _shouldPause bool if contract should be paused
   */
  function togglePaused(bool _shouldPause) external onlyOwner {
    if (_shouldPause) {
      _pause();
    } else {
      _unpause();
    }
  }

  /**
      @notice Allows owner to request an update of all metadata
   */
  function refreshAllMetadata() external onlyOwner {
    emit BatchMetadataUpdate(0, tokenIdCounter);
  }

  /**
      @notice Allows owner to restrict max NFT ownership - is optional and the value 0 disables it.
      @dev note that setting this value doesnt affect users holding over the new limit
      @param _newMaxStoreBalanceAllowance new max balance an address can hold - setting to 0 disables it
   */
  function setMaxStoreBalanceAllowance(uint256 _newMaxStoreBalanceAllowance) external onlyOwner {
    maxStoreBalanceAllowance = _newMaxStoreBalanceAllowance;
  }

  /**
      @notice Allows owner to set payment addresses.
      @param _newDispatchAddress new address to send dispatch funds
      @param _newMerchantAddress new address to send merchant funds
   */
  function setTreasuryAddresses(address payable _newDispatchAddress, address payable _newMerchantAddress)
    public
    onlyOwner
  {
    require(_newDispatchAddress != address(0), "Dispatch address cannot be null address");
    dispatchTreasuryAddress = _newDispatchAddress;
    merchantTreasuryAddress = _newMerchantAddress;
  }

  /**
      @notice Returns the products base URI. Overrides 721 default function. Only owner can call this function. Emits WhitelistChanged event.
      @param _address address of which we change whitelist status
      @param _bool true or false 
   */
  function setWhitelistedAddress(address _address, bool _bool) public onlyOwner {
    // resets the metadata uri
    whiteListedAddress[_address] = _bool;
    emit WhitelistChanged(_address, _bool);
  }

  /**
      @notice Allows owner to set the dispatchFee percentage take rate. Emits DispatchRateChanged event.
      @param _dispatchFee a value 0 - 99
   */
  function setFees(uint8 _dispatchFee) external onlyOwner {
    require(_dispatchFee < 100, "cannot set a fee above 99");
    DISPATCH_FEE = _dispatchFee;
    emit DispatchRateChanged(_dispatchFee);
  }

  // --------------------- OWNER/ADMIN FUNCTIONS ---------------------

  /**
      @notice Allows whitelisted addresses or owner to edit a product configuration
      @param _productIdCounter product identifier
      @param _productPrice product price
      @param _productMaxSupply product maxSupply
      @param _productCollectionUri productCollectionUri
   */
  function setProductDetails(
    uint256 _productIdCounter,
    uint256 _productPrice,
    uint256 _productMaxSupply,
    string memory _productCollectionUri,
    address _productTokenGateAddress,
    uint256 _productTokenGateTokenId
  ) public _isWhitelistedAddress whenNotPaused nonReentrant {
    // productIDs must be incremental
    require(_productIdCounter <= productIdCounter, "new products must use createNewProduct function.");
    // productCollectionUris are a necessary condition for any product
    require(bytes(_productCollectionUri).length > 0, "productCollectionUri is a necessary condition for any product.");
    // checks that the optional tokenGate is implemented correctly; using a tokenId requires the 1155 interface, otherwise 721 is used
    if (_productTokenGateTokenId > 0) {
      require(
        IERC1155(_productTokenGateAddress).supportsInterface(type(IERC1155).interfaceId),
        "Must use ERC1155 address with a tokenID."
      );
    } else if (_productTokenGateAddress != address(0)) {
      require(
        IERC721(_productTokenGateAddress).supportsInterface(type(IERC721).interfaceId),
        "Must use ERC721 address without a tokenID."
      );
    }
    // set the tokenID as the Product Key for the ProductDetails
    product[_productIdCounter] = ProductDetails(
      _productPrice,
      product[_productIdCounter].productTotalSupply,
      _productMaxSupply,
      product[_productIdCounter].productBurns,
      _productCollectionUri,
      _productTokenGateAddress,
      _productTokenGateTokenId
    );
    // emit the details which changed
    emit ProductDetailsChanged(
      _productIdCounter,
      _productPrice,
      product[_productIdCounter].productTotalSupply,
      _productMaxSupply,
      product[_productIdCounter].productBurns,
      _productTokenGateAddress,
      _productTokenGateTokenId
    );
  }

  /**
      @notice Allows whitelisted addresses or owner to create a product configuration
      @param _productPrice product price
      @param _productMaxSupply product maxSupply
      @param _productCollectionUri productCollectionUri
   */
  function createNewProduct(
    uint256 _productPrice,
    uint256 _productMaxSupply,
    string memory _productCollectionUri,
    address _productTokenGateAddress,
    uint256 _productTokenGateTokenId
  ) public _isWhitelistedAddress whenNotPaused {
    productIdCounter++;
    setProductDetails(
      productIdCounter,
      _productPrice,
      _productMaxSupply,
      _productCollectionUri,
      _productTokenGateAddress,
      _productTokenGateTokenId
    );
  }

  /**
      @notice Allows whitelisted addresses or owner to create a product configuration in bulk
      @dev A struct is used here to make looping through an array easier (otherwise we would need 4 separate arrays as arguments)
      @param _inventory ProductDetails - uint256 productPrice; uint256 productTotalSupply; uint256 productMaxSupply; string productCollectionUri;
   */
  function createNewProductBulk(ProductDetails[] memory _inventory) public _isWhitelistedAddress whenNotPaused {
    for (uint256 i = 0; i < _inventory.length; i++) {
      createNewProduct(
        _inventory[i].productPrice,
        _inventory[i].productMaxSupply,
        _inventory[i].productCollectionUri,
        _inventory[i].productTokenGateAddress,
        _inventory[i].productTokenGateTokenId
      );
    }
  }

  // --------------------- GETTER FUNCTIONS ---------------------

  function totalSupply() public view returns (uint256) {
    return tokenIdCounter;
  }

  /// @notice Returns the price of X tokens
  /// @dev Chainlink returns int256 values; converted to uint in this function
  /// @return uint256
  function getL1PriceForProduct(uint256 _amount, uint256 _productId) public view returns (uint256) {
    _isValidProduct(_productId);
    // get the raw int256 price from the chainlink oracle
    (, int256 oraclePrice, , , ) = priceFeed.latestRoundData();
    // protect against overflows from the priceFeed since int can be negative
    require(oraclePrice >= 0, "price cannot be negative");
    // convert it to uint so we can compare to msg.value
    uint256 ethToUsdPrice = uint256(oraclePrice);
    // get the price for 1 token
    uint256 priceFor1Product = (((product[_productId].productPrice.mul(1e18)).div(ethToUsdPrice)).mul(1e8)).div(
      PRECISION_DECIMALS
    );
    // and then multiply that price by _numTokens and then by 1e18 which converts eth to wei
    return priceFor1Product.mul(_amount);
  }

  /**
      @notice Returns the token's URI which is a combination of the baseUri, the contract address, the productCollectionUri, and the tokenId
      @param _tokenId NFT _tokenId
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    _requireMinted(_tokenId);
    _isValidProduct(tokenIDtoproductIdCounterMap[_tokenId]);
    ProductDetails memory foundProduct = product[tokenIDtoproductIdCounterMap[_tokenId]];
    return
      string(
        abi.encodePacked(
          productBaseURI,
          "/",
          address(this).toHexString(),
          "/",
          foundProduct.productCollectionUri,
          "/",
          tokenIDtoproductIdCounterMap[_tokenId].toString(),
          "/",
          _tokenId.toString()
        )
      );
  }

  /**
      @notice Returns the productDetails of a given tokenId. TokenIds are assigned to productIds which are assigned to productDetails.
      @param _tokenId NFT _tokenId
   */
  function getTokenProductDetails(uint256 _tokenId) public view returns (ProductDetails memory) {
    _isValidProduct(tokenIDtoproductIdCounterMap[_tokenId]);
    return product[tokenIDtoproductIdCounterMap[_tokenId]];
  }

  // --------------------- SETTER / LOGIC FUNCTIONS ---------------------

  /**
      @notice distributes the msg.value between relevant parties
      @dev private function
   */
  function _distributeFunds() private {
    // no merchant address? No problem! We will take it all.
    if (merchantTreasuryAddress == address(0)) {
      (bool sent, ) = (dispatchTreasuryAddress).call{ value: msg.value }("");
      require(sent, "Failed to send funds");
    } else {
      // get the dispatchTotal by calculating the relative % value of the msg.value
      uint256 dispatchTotal = (msg.value.mul(DISPATCH_FEE)).div(uint256(100));
      // get the merchantTotal by subtracting the dispatchTotal from the msg.value
      uint256 merchantTotal = msg.value.sub(dispatchTotal);
      (bool dSent, ) = (dispatchTreasuryAddress).call{ value: dispatchTotal }("");
      (bool mSent, ) = (merchantTreasuryAddress).call{ value: merchantTotal }("");
      require(dSent && mSent, "Failed to send funds to dispatch and merchant");
    }
  }

  /**
      @notice Purchase a product with the L1 token
      @param _amount product amount to purchase
      @param _productId product numerical ID
      @param _data additional data passed to event for logging purposes
   */
  function mint(
    uint256 _amount,
    uint256 _productId,
    string memory _data
  ) external payable _isValidAmount(_amount, _productId) nonReentrant whenNotPaused {
    _handleMint(_amount, _productId, msg.sender, _data);
  }

  /**
      @notice Purchase a product with the L1 token
      @param _amount product amount to purchase
      @param _productId product numerical ID
      @param _data additional data passed to event for logging purposes
      @param _receiver address to receiveNFT
   */
  function mintTo(
    uint256 _amount,
    uint256 _productId,
    string memory _data,
    address _receiver
  ) external payable _isValidAmount(_amount, _productId) nonReentrant whenNotPaused {
    _handleMint(_amount, _productId, _receiver, _data);
  }

  /**
      @notice Purchase a product with the L1 token
      @param _amount product amount to purchase
      @param _productId product numerical ID
      @param _receiver address to receiveNFT
      @param _data additional data passed to event for logging purposes
      @dev private function
   */
  function _handleMint(
    uint256 _amount,
    uint256 _productId,
    address _receiver,
    string memory _data
  ) private {
    uint256 l1Price = getL1PriceForProduct(_amount, _productId);
    // check that the user sent enough ETH
    require(msg.value >= l1Price, "Invalid amount paid.");
    // optional check that the user holds the required token when the product is tokenGated
    if (product[_productId].productTokenGateAddress != address(0)) {
      if (product[_productId].productTokenGateTokenId > 0) {
        require(
          IERC1155(product[_productId].productTokenGateAddress).balanceOf(
            _receiver,
            product[_productId].productTokenGateTokenId
          ) > 0,
          "Address lacks the required 1155 token gate balance > 1."
        );
      } else {
        require(
          IERC721(product[_productId].productTokenGateAddress).balanceOf(_receiver) > 0,
          "Address lacks the required 721 token gate balance > 1."
        );
      }
    }

    if (msg.value > 0) {
      // distribute all the money
      _distributeFunds();
    }
    // add to the product totalSupply
    product[_productId].productTotalSupply = product[_productId].productTotalSupply.add(_amount);
    for (uint256 i = 0; i < _amount; i++) {
      // add to the overall totalSupply
      tokenIdCounter++;
      // map the tokenID to the productID
      tokenIDtoproductIdCounterMap[tokenIdCounter] = _productId;
      // mint token to sender * amount
      _safeMint(_receiver, tokenIdCounter);
      emit SaleEvent(_productId, _receiver, _amount, tokenIdCounter, product[_productId], l1Price.div(_amount), _data);
    }
  }

  /**
      @notice Permissions transfers / burns of a given tokenID
      @dev This function overrides the default behavior
      @param _owner of the asset
      @param _operator msg.sender of the req
   */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    if (whiteListedAddress[_operator] == true) {
      return true;
    }
    // otherwise, use the default ERC1155.isApprovedForAll()
    return ERC721.isApprovedForAll(_owner, _operator);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId, /* firstTokenId */
    uint256 batchSize
  ) internal virtual override {
    // check that the address will not hold more than the maxStoreBalanceAllowance if
    // it's not a burn transfer and maxStoreBalanceAllowance is set above 0
    _isValidTransferOfSum(batchSize, to);
    ERC721._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  /**
      @notice Sends a token to the NULL address
      @dev Only whitelisted can burn
      @param _tokenId of the asset
   */
  function burn(uint256 _tokenId) public _isWhitelistedAddress whenNotPaused {
    _requireMinted(_tokenId);
    _isValidProduct(tokenIDtoproductIdCounterMap[_tokenId]);
    product[tokenIDtoproductIdCounterMap[_tokenId]].productBurns = product[tokenIDtoproductIdCounterMap[_tokenId]]
      .productBurns
      .add(1);
    _burn(_tokenId);
  }

  /**
      @notice Sends a token to the NULL address AND decrements the supply AND refunds the user
      @dev Only whitelisted can refund
      @param _tokenId of the asset
   */
  function refund(uint256 _tokenId) external payable _isWhitelistedAddress whenNotPaused nonReentrant {
    address currOwner = _ownerOf(_tokenId);
    burn(_tokenId);
    product[tokenIDtoproductIdCounterMap[_tokenId]].productTotalSupply = product[tokenIDtoproductIdCounterMap[_tokenId]]
      .productTotalSupply
      .sub(1);
    (bool sent, ) = (currOwner).call{ value: msg.value }("");
    require(sent, "Failed to send funds");
  }

  /**
      @notice Sends a token to the NULL address
      @dev Only whitelisted can burn
      @param _ids[] of the asset
   */
  function burnBatch(uint256[] memory _ids) public _isWhitelistedAddress whenNotPaused {
    for (uint256 i = 0; i < _ids.length; i++) {
      burn(_ids[i]);
    }
  }
}