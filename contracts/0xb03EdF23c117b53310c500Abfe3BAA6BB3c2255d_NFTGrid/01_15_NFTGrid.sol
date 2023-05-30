// SPDX-License-Identifier:  CC-BY-NC-4.0
// email "licensing [at] pyxelchain.com" for licensing information
// Pyxelchain Technologies v1.0.0 (NFTGrid.sol)

pragma solidity =0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "hardhat/console.sol";

/**
 * @title Billion Pyxel Project
 * @author Nik Cimino @ncimino
 *
 * @dev the 1 billion pixels are arranged in a 32768 x 32768 = 1,073,741,824 pixel matrix
 * to address all 1 billion pixels we break them into 256 pixel tiles which are 16 pixels x 16 pixels
 * this infers a grid based addressing sytem of dimensions: 32768 / 16 = 2048 x 2048 = 4,194,304 tiles
 *
 * @custom:websites https://billionpyxelproject.com https://billionpixelproject.net
 *   
 * @notice to _significantly_ reduce gas we require that purchases are some increment of the layers defined above
 *
 * @notice this cotnract does not make use of ERC721Enumerable as the tokenIDs are not sequential
 */

/*
 * this contract is not concerned with the individual pixels, but with the tiles that can be addressed and sold
 * each tile is represented as an NFT, but each NFT can be different dimensions in layer 1 they are 1 tile each, but in layer 4 they are 16 tiles each
 *   layer 1:    1 x    1 =         1 tile / index
 *   layer 2:    2 x    2 =         4 tiles / index
 *   layer 3:    4 x    4 =        16 tiles / index
 *   layer 4:    8 x    8 =        64 tiles / index
 *   layer 5:   16 x   16 =       256 tiles / index
 *   layer 6:   32 x   32 =     1,024 tiles / index
 *   layer 7:   64 x   64 =     4,096 tiles / index
 *   layer 8:  128 x  128 =    16,384 tiles / index
 *   layer 9:  256 x  256 =    65,536 tiles / index
 *  layer 10:  512 x  512 =   262,144 tiles / index
 *  layer 11: 1024 x 1024 = 1,048,576 tiles / index
 *  layer 12: 2048 x 2048 = 4,194,304 tiles / index
 * 
 * quad alignment:
 *
 *      layer 11    layer 12
 *      ____N___   ________
 *     /   /   /  /       /
 *   W/---+---/E /       /
 *   /___/___/  /_______/
 *       S
 */

contract NFTGrid is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    //// TYPES & STRUCTS

    /**
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice layers enum interger value is used as 2 ^ Layer e.g. 2 ^ (x4=2) = 5, 2 ^ (x16=4) = 16
     *  there are a total of 12 sizes (0-11)
     * @dev these enums are uint256 / correct?
     */
    enum Size {
        X1,
        X2,
        X4,
        X8,
        X16,
        X32,
        X64,
        X128,
        X256,
        X512,
        X1024,
        X2048
    } // 2048 = 2^11 = 1 << 11

    /**
     * @notice we model our grid system in the same what that the front-end displays are modeled, this is with 0,0 in the top left corner
     * x increases as we move to the right, but y increases as we move done
     * @dev max x and y is 2048 = 2 ^ 11 which can fit in a uint16, and since we need 4 values using 64 bits packs them all tight
     * @dev we model this so that we have logical coherency between our internal logic and the display systems of this logic
     * @dev x & y are the center of the quad
     */
    struct Rectangle {
        uint16 x;
        uint16 y;
        uint16 w;
        uint16 h;
    }

    /**
     * @notice a quad cannot be owned after it has been divided
     * @dev the quads are the tokenIds which are an encoding of x,y,w,h
     */
    struct QuadTree {
        uint64 northeast;   // quads max index is 2 ^ 64 = 18,446,744,073,709,551,616
        uint64 northwest;   // however, this allows us to pack all 4 into a 256 bit slot
        uint64 southeast;
        uint64 southwest;
        Rectangle boundary; // 16 * 4 = 64 bits
        address owner;      // address are 20 bytes = 160 bits
        bool divided;       // bools are 1 byte = 8 bits  ... should also pack into a 256 bit slot, right? so 2 total?
        uint24 ownedCount;  // need 22 bits to represent full 2048x2048 count - total number of grid tiles owned under this quad (recursively)
    }

    struct PurchaseToken {
        bool enabled;
        uint256 pricePerPixel;
    }

    //// EVENTS

    event ETHPriceChanged (
        uint256 oldPrice, uint256 newPrice
    );

    event TokenUpdated (
        address indexed tokenAddress, uint256 indexed tokenPrice, bool enabled
    );

    event BuyCreditWithETH (
        address indexed buyer, address indexed receiver, uint256 amountETH, uint256 amountPixels
    );

    event BuyCreditWithToken (
        address indexed buyer, address indexed token, address indexed receiver, uint256 amountToken, uint256 amountPixels
    );

    event TransferCredit (
        address indexed sender, address indexed receiver, uint256 amount
    );

    //// MODIFIERS

    modifier placementNotLocked() {
        require(!placementLocked, "NFTG: placement locked");
        _;
    }

    modifier reserveNotLocked() {
        require(!reserveLocked, "NFTG: reserve locked");
        _;
    }

    //// MEMBERS

    uint16 constant public GRID_W = 2048;
    uint16 constant public GRID_H = 2048;
    uint256 constant public PIXELS_PER_TILE = 256;

    bool public placementLocked;
    bool public reserveLocked;
    bool public permanentlyAllowCustomURIs;
    bool public allowCustomURIs = true;
    uint64 immutable public rootTokenId;
    uint256 public pricePerPixelInETH = 0.00004 ether;
    address[] public receivedAddresses;
    mapping (address => PurchaseToken) public tokens;// e.g. USDC can be passed in @ $0.10/pixel = $25.60 per tile
    mapping (uint64 => QuadTree) public qtrees;
    mapping (address => bool) public addressExists;
    mapping (address => uint256) public pixelCredits;
    mapping (address => uint256) public ownedPixels;
    mapping (uint256 => string) public tokenURIs;
    string public defaultURI;
    uint256 public totalPixelsOwned;

    //// CONTRACT

    /**
     * @dev the list of initially support token addresses and token prices are privded at deployment
     * @param _tokenAddresses is an array of token addresses to support purchases with 
     * @param _tokenPrices is an array of token prices and indesxes correlate with the token addresses also provided here
     */
    constructor(address[] memory _tokenAddresses, uint256[] memory _tokenPrices) ERC721("Billion Pyxel Project", "BPP") {
        require(_tokenAddresses.length == _tokenPrices.length, "NFTG: array length mismatch");
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            updateToken(_tokenAddresses[i], _tokenPrices[i], true);
        }
        uint64 qtreeTokenId = _createQTNode(address(0x0), GRID_W/2-1, GRID_H/2-1, GRID_W, GRID_H);
        rootTokenId = qtreeTokenId;
        _subdivideQTNode(qtreeTokenId);
    }

    /**
     * @notice get a tokens price and if it is enabled
     * @param _tokenAddress is the address of the token to be looked up
     * @return pricePerPixel is the price per pixel given the current token address
     * @return enabled is indicating if the current token is enabled
     */
    function getToken(address _tokenAddress) external view returns(uint256 pricePerPixel, bool enabled) {
        PurchaseToken memory purchaseToken = tokens[_tokenAddress];
        pricePerPixel = purchaseToken.pricePerPixel;
        enabled = purchaseToken.enabled;
    }

    /**
     * @notice let each token have an independent URI as these will be owned and controlled by their owner
     * @param _tokenId is the token ID to look-up the URI for 
     * @return uri is the URI for the provided token ID
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory uri) {
        require(_exists(_tokenId), "NFTG: non-existant token");
        if (!allowCustomURIs) {
            uri = _getDefaultURI(_tokenId);
        } else {
            uri = tokenURIs[_tokenId];
            if (bytes(uri).length == 0) {
                uri = _getDefaultURI(_tokenId);
            }
        }
    }

    /**
     * @notice returns the default URI given a token ID
     * @param _tokenId the token ID to lookup the default URI for
     * @return uri the URI of the token ID, which appends the token ID to the end of the default URI string
     */
    function _getDefaultURI(uint256 _tokenId) private view returns(string memory uri) {
        uri = bytes(defaultURI).length > 0 ? string(abi.encodePacked(defaultURI, _tokenId.toString())) : "";
    }

    /**
     * @notice allow the contract owner to set the default URI for the NFTs, the token ID will be appended to the end of this URI
     * @param _uri is the default base URI that is used if custom are disabled or if none has been specified for the current token
     */
    function setDefaultURI(string memory _uri) external onlyOwner {
        defaultURI = _uri;
    }

    /**
     * @notice allow the NFT owner to set a custom URI for this NFT, the token ID will _not_ be appended to the end of this URI 
     *         (it can be explicitly added to the end when set if needed as this is on a per NFT basis)
     * @param _tokenId the NFT token ID that the URI will be updated for
     * @param _tokenUri the new URI for the given token ID
     */
    function setTokenURI(uint256 _tokenId, string calldata _tokenUri) external virtual {
        require(_exists(_tokenId), "NFTG: non-existant token");
        require(allowCustomURIs, "NFTG: custom URIs disabled");
        QuadTree storage qtree = qtrees[uint64(_tokenId)];
        require(qtree.owner == msg.sender, "NFTG: only owner can set URI");
        tokenURIs[_tokenId] = _tokenUri;
    }

    /**
     * @notice add a new, disable an existing, or change the price of a token
     * @notice token price must account for the ERC20 decimals value e.g. for USDC 6 decimals, setting this value to 100000 equals: $0.10/pixel
     * @param _tokenAddress the address of the token to update
     * @param _tokenPrice the price per pixel of the token
     * @param _enabled used to enable or disable the token
     */
    function updateToken(address _tokenAddress, uint256 _tokenPrice, bool _enabled) public onlyOwner {
        require(_tokenPrice != 0, "NFTG: token price 0");
        require(_tokenAddress != address(0), "NFTG: token address 0");
        PurchaseToken storage newToken = tokens[_tokenAddress];
        newToken.enabled = _enabled;
        newToken.pricePerPixel = _tokenPrice;
        emit TokenUpdated(_tokenAddress, _tokenPrice, _enabled);
    }

    /**
     * @notice controls ability of placement
     */
    function togglePlacementLock() external onlyOwner {
        placementLocked = !placementLocked;
    }

    /**
     * @notice controls ability of users to reserve pixels
     */
    function toggleReserveLock() external onlyOwner {
        reserveLocked = !reserveLocked;
    }

    /**
     * @notice controls ability of users to set their own URI
     */
    function toggleCustomURIs() external onlyOwner {
        require(!permanentlyAllowCustomURIs, "NFTG: permanently enabled");
        allowCustomURIs = !allowCustomURIs;
    }

    /**
     * @notice controls ability of users to set their own URI, once called custom URIs can never be disabled again
     */
    function permanentlyEnableCustomURIs() external onlyOwner {
        permanentlyAllowCustomURIs = true;
        allowCustomURIs = true;
    }

    /**
     * @notice set the price per pixel in ETH
     * @param _pricePerPixel is the price per pixel in ETH
     */
    function setETHPrice(uint256 _pricePerPixel) external onlyOwner {
        emit ETHPriceChanged(pricePerPixelInETH, _pricePerPixel);
        require(_pricePerPixel > 0, "NFTG: price is 0");
        pricePerPixelInETH = _pricePerPixel;
    }

    /**
     * @notice returns a subset of the arrays of pixel credit receivers and their current balances - can be used to export credit balances 
     * @param _start the starting index of accounts/balances to start looking out
     * @param _count the number of indexes to look through from the _start forward
     * 
     */
    function getPixelCredits(uint256 _start, uint256 _count) external view returns(address[] memory addresses, uint256[] memory balances) {
        require(_count > 0, "NFTG: count is 0");
        require(_start < receivedAddresses.length, "NFTG: start too high");
        uint256 stop = _start + _count;
        stop = (stop > receivedAddresses.length) ? receivedAddresses.length : stop;
        uint256 actualCount = stop - _start;
        addresses = new address[](actualCount);
        balances = new uint256[](actualCount);
        for (uint256 i = _start; i < stop; i++) {
            address current = receivedAddresses[i];
            addresses[i - _start] = current;
            balances[i - _start] = pixelCredits[current];
        }
    }

    /**
     * @notice transfer some credits from the current owner to a new owner
     * @param _receiver the account receiving the credits
     * @param _amount the amount of credits to transfer from one account to another
     */
    function transferCredits(address _receiver, uint256 _amount) external reserveNotLocked {
        require(pixelCredits[msg.sender] >= _amount, "NFTG: not enough credit");
        require(_receiver != address(0), "NFTG: address 0");
        emit TransferCredit(msg.sender, _receiver, _amount);
        pixelCredits[msg.sender] -= _amount;
        pixelCredits[_receiver] += _amount;
    }

    /**
     * @notice purchases enough credit for and places/mints the token ID in a single operation using a token
     * @param _tokenAddress the token address to use to make the purchase
     * @param _tokenId the tokenId of the quad to buy using Tokens
     */
    function buyWithToken(address _tokenAddress, uint64 _tokenId) external nonReentrant placementNotLocked {
        _buyWithToken(_tokenAddress, _tokenId);
    }

    /**
     * @param _tokenAddress the token address to use to make the purchase
     * @param _tokenIds the token IDs of the quads to buy using Tokens
    */
    function multiBuyWithToken(address _tokenAddress, uint64[] calldata _tokenIds) external nonReentrant placementNotLocked {
        for(uint i = 0; i < _tokenIds.length; i++) {
            _buyWithToken(_tokenAddress, _tokenIds[i]);
        }
    }

    /**
     * @notice buys a specific token ID using an ERC20 token, will convert token to credits and then mint/place the NFT
     * @param _tokenAddress is the address of the token to be used to make the purchase
     * @param _tokenId is the token ID to purchase
     */
    function _buyWithToken(address _tokenAddress, uint64 _tokenId) private {
        PurchaseToken memory token = tokens[_tokenAddress];
        require(token.enabled, "NFTG: token not supported");
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint256 price = _price(token.pricePerPixel, range);
        _buyCreditWithToken(_tokenAddress, msg.sender, price);
        _placeQTNode(_tokenId);
    }

    /**
     * @notice purchases enough credit for and places/mints the token ID in a single operation using ETH
     * @param _tokenId the tokenId of the quad to buy using ETH
     */
    function buyWithETH(uint64 _tokenId) external payable nonReentrant placementNotLocked {
        _buyCreditWithETH(msg.sender);
        _placeQTNode(_tokenId);
    }

    /**
     * @param _tokenIds the tokenIds of the quads to buy using ETH
    */
    function multiBuyWithETH(uint64[] calldata _tokenIds) external payable nonReentrant placementNotLocked {
        _buyCreditWithETH(msg.sender);
        for(uint i = 0; i < _tokenIds.length; i++) {
            _placeQTNode(_tokenIds[i]);
        }
    }

    /**
     * @notice places the specified token ID via minting the NFT
     * @param _tokenId is the ID of the token to be placed/minted
     */
    function _placeQTNode(uint64 _tokenId) private {
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint256 pixelsToPlace = uint256(range.w) * uint256(range.h) * PIXELS_PER_TILE;
        uint256 pixelBalance = pixelCredits[msg.sender];
        require(pixelsToPlace <= pixelBalance, "NFTG: not enough credit");
        pixelCredits[msg.sender] -= pixelsToPlace;
        _mintQTNode(_tokenId);
    }

    /**
     * @notice the amount of {msg.value} is what will be used to convert into pixel credits
     * @param _receiveAddress is the address receiving the pixel credits
     */
    // slither-disable-next-line reentrancy-events
    function buyCreditWithETH(address _receiveAddress) external payable nonReentrant reserveNotLocked {
        _buyCreditWithETH(_receiveAddress);
    }

    function _buyCreditWithETH(address _receiveAddress) private {
        uint256 credit = msg.value / pricePerPixelInETH;
        require(credit > 0, "NFTG: not enough ETH sent");
        emit BuyCreditWithETH(msg.sender, _receiveAddress, msg.value, credit);
        pixelCredits[_receiveAddress] += credit;
        ownedPixels[_receiveAddress] += credit;
        totalPixelsOwned += credit;
        if (!addressExists[_receiveAddress]) {
            receivedAddresses.push(_receiveAddress); 
            addressExists[_receiveAddress] = true;
        }
        Address.sendValue(payable(owner()), msg.value);
    }

    /**
     * @param _tokenAddress is the address of the token being used to purchase the pixels
     * @param _receiveAddress is the address receiving the pixel credits
     * @param _amount is the amount in tokens - if using a stable like USDC, then this represent dollar value in wei
     */
    function buyCreditWithToken(address _tokenAddress, address _receiveAddress, uint256 _amount) external nonReentrant reserveNotLocked {
        _buyCreditWithToken(_tokenAddress, _receiveAddress, _amount);
    }

    /**
     * @notice buy credit with tokens
     * @param _tokenAddress is the token (ERC20) address being used to do the purchase
     * @param _receiveAddress is the account receiving the credits
     * @param _amount is the amount of tokens to use to do the purchase
     */
    function _buyCreditWithToken(address _tokenAddress, address _receiveAddress, uint256 _amount) private {
        PurchaseToken memory token = tokens[_tokenAddress];
        require(token.enabled, "NFTG: token not supported");
        uint256 credit = _amount / token.pricePerPixel;
        require(credit > 0, "NFTG: not enough tokens sent");
        emit BuyCreditWithToken(msg.sender, _tokenAddress, _receiveAddress, _amount, credit);
        pixelCredits[_receiveAddress] += credit;
        ownedPixels[_receiveAddress] += credit;
        totalPixelsOwned += credit;
        if (!addressExists[_receiveAddress]) {
            receivedAddresses.push(_receiveAddress); 
            addressExists[_receiveAddress] = true;
        }
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, owner(), _amount);
    }

    /**
     * @notice allows already purchased pixels to be allocated to specific token IDs
     * @dev will fail if pixel balance is insufficient
     * @param _tokenIds the tokenIds of the quads to place
     */
    function placePixels(uint64[] calldata _tokenIds) external nonReentrant placementNotLocked {
        for(uint i = 0; i < _tokenIds.length; i++) {
            _placeQTNode(_tokenIds[i]);
        }
    }

    /**
     * @notice mints the QuadTree node for the provided token ID and ownership goes to the caller
     * @dev only the unowned leafs can be purchased
     * @dev quads are only divided via subdivde or buyWith*
     * @param _tokenId is the token ID being minted
     */
    function _mintQTNode(uint64 _tokenId) private {
        QuadTree storage qtree = qtrees[uint64(_tokenId)];
        require(!qtree.divided, "NFTG: cannot buy if divided");
        require(qtree.owner == address(0x0), "NFTG: already owned");
        
        revertIfParentOwned(_tokenId);
        _revertIfChildOwned(qtree); // needed if burning
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        uint24 increaseCount = uint24(range.w) * uint24(range.h);
        _divideAndCount(getParentTokenId(_tokenId), increaseCount);
        
        qtree.owner = msg.sender;
        qtree.ownedCount = increaseCount;

        _safeMint(msg.sender, _tokenId);
    }

    /**
     * @notice given the price and size calculate the price of a rectangle
     * @param _pricePerPixel is the price per pixel
     * @param _rect is the rectangle we are calculating the price of
     * @return price is the price of this rectangle
     */
    function _price(uint256 _pricePerPixel, Rectangle memory _rect) private pure returns(uint256 price) {
        price = _pricePerPixel * PIXELS_PER_TILE * uint256(_rect.w) * uint256(_rect.h);
    }
    
    /**
     * @notice override the ERC720 function so that we can update user credits
     * @dev this logic only executes if pixels are being transferred from one user to another
     * @dev this contract doesn't support burning of QuadTrees so we don't need to subtract on burn (_to == 0), burning only happens on subdivide
     * @dev this contract increases the owned count on reserve not on minting (_from == 0) we ignore those as they are already added
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override {
        if ((_from != address(0)) && (_to != address(0))) {
            Rectangle memory range = getRangeFromTokenId(uint64(_tokenId));
            uint256 credit = uint256(range.w) * uint256(range.h) * PIXELS_PER_TILE;
            ownedPixels[_from] -= credit;
            ownedPixels[_to] += credit;
        }
    }

    /**
     * @notice calculates the price of a quad in ETH
     * @param _tokenId the tokenId of the quad to get the ETH price of
     * @return price the price of the token ID in ETH
     */
    function getETHPrice(uint64 _tokenId) external view returns(uint price) {
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        price = _price(pricePerPixelInETH, range);
    }

    /**
     * @notice calculates the price of a quad in tokens
     * @param _tokenAddress the token address to look up the price for
     * @param _tokenId the token ID of the quad to get the token price of
     * @return price the price of the token ID in tokens
     */
    function getTokenPrice(address _tokenAddress, uint64 _tokenId) external view returns(uint price) {
        PurchaseToken memory token = tokens[_tokenAddress];
        require(token.enabled, "NFTG: token not supported");
        Rectangle memory range = getRangeFromTokenId(_tokenId);
        price = _price(token.pricePerPixel, range);
    }

    /**
     * @notice this starts at the given node and goes up the QuadTree graph to the root, from there every node is subdivide and the amount of tiles purchased are added
     * @dev don't need to check the qtree of the root token ID (X2048) as it was divided in the ctor
     * @param _tokenId is the token ID to be divided and have count incremented on
     * @param _increaseBy is the count of the tiles (X1) currently placed under that quad - X2048 or the root node will always have the full number of placed tiles
     */
    function _divideAndCount(uint64 _tokenId, uint24 _increaseBy) private {
        QuadTree storage qtree = qtrees[_tokenId];
        if (_tokenId != rootTokenId) {
            uint64 parentTokenId = getParentTokenId(_tokenId);
            _divideAndCount(parentTokenId, _increaseBy);
        }
        if (!qtree.divided) {
            _subdivideQTNode(_tokenId);
        }
        qtree.ownedCount += _increaseBy;
    }

    /**
     * @notice useful for checking if any child is owned
     * @param _tokenId is the token ID to check if any child below it is owned
     */
    function revertIfChildOwned(uint64 _tokenId) external view {
        QuadTree memory qtree = qtrees[_tokenId];
        _revertIfChildOwned(qtree);
    }

    /**
     * @notice checks if any child tile is owned, since the QuadTree nodes track this for all children it is a simple query of the owned count
     * @param _qtree is the QuadTree node object to check
     */
    function _revertIfChildOwned(QuadTree memory _qtree) private pure {
        require(_qtree.ownedCount == 0, "NFTG: child owned");
    }

    /**
     * @notice useful for checking if any parent is owned - if it doesn't revert, then no body owns above it
     * @param _tokenId is the token ID to check if any parent above it is owned
     */
    function revertIfParentOwned(uint64 _tokenId) public view {
        uint64 parentTokenId = _tokenId;
        while (parentTokenId != rootTokenId) { // NOTE: don't need to check the parent of X2048
            parentTokenId = getParentTokenId(parentTokenId);
            QuadTree memory parent = qtrees[parentTokenId];
            require(parent.owner == address(0x0), "NFTG: parent owned");
        }
    }

    /**
     * @notice calculates a parent tile tokenId from a child - it is known that the parents w/h will be 2x the child,
     * and from that we can determine the quad using it's x/y
     * @dev symetric: should be kept up-to-date with JS implementation
     * @param _tokenId the tokenId of the quad to get the parent range of
     */
    function getParentRange(uint64 _tokenId) public pure returns(Rectangle memory parent) {
        // parent is child until assignment (to save gas)...
        parent = getRangeFromTokenId(_tokenId);
        uint16 width = 2 * parent.w;
        uint16 height = 2 * parent.h;
        uint16 tileIndexX = calculateIndex(parent.x, parent.w);
        uint16 tileIndexY = calculateIndex(parent.y, parent.h);
        // slither-disable-next-line divide-before-multiply
        parent.x = tileIndexX / 2 * width + width / 2 - 1; // note: division here truncates and this is intended when going to indexes
        // slither-disable-next-line divide-before-multiply
        parent.y = tileIndexY / 2 * height + height / 2 - 1;
        parent.w = width;
        parent.h = height;
        validate(parent);
    }

    /**
     * index layout:
     *    layer 11    layer 12
     *      _0___1__   ____0___
     *   0 /   /   /  /       /
     *    /---+---/ 0/       /
     * 1 /___/___/  /_______/
     * x=127+256,y=127 w=256   x=0,y=0 w=1  special case for dimension of 1 since we move up and left
     * x=w/2-1+index*w         x=index*w
     * index*w=x-w/2+1
     * index=(x-w/2+1)/w
     */

    /**
     * @notice calculate the index of a token given an x or y (_value) and a corresponding size (w or h as _dimension)
     * @dev this function does not check values - it is presumed that the values have already passed 'validate'
     * @param _value is x or y
     * @param _dimension is w or h (respectively)
     * @return index is the index starting at 0 and going to w/GRID_W - 1 or h/GRID_H - 1
     *      the indexes of the tiles are the tokenId of the column or row of that tile (based on dimension)
     */
    function calculateIndex(uint16 _value, uint16 _dimension) public pure returns(uint16 index) {
        index = (_dimension == 1) ? (_value / _dimension) : ((_value + 1 - _dimension/2) / _dimension);
    }

    /**
     * @notice derive the parent token ID given one of it's child token IDs
     * @dev symetric: should be kept up-to-date with JS implementation
     * @notice calculates a parent tile tokenId from a child
     * @param _tokenId the tokenId of the quad to get the parent range of
     */
    function getParentTokenId(uint64 _tokenId) public pure returns(uint64 parentTokenId) {
        parentTokenId = _getTokenIdFromRangeNoCheck(getParentRange(_tokenId));
    }

    /**
     * @notice splits a tile into a quarter (a.k.a. quad)
     * @dev there are ne, nw, se, sw quads on the QuadTrees
     * @notice the quads are stored as tokenIds here not actual other QuadTrees
     */
    function subdivide(uint256 _tokenId) external placementNotLocked { 
        QuadTree memory qtree = qtrees[uint64(_tokenId)];
        require(!qtree.divided, "NFTG: already divided");
        require(qtree.owner == msg.sender, "NFTG: only owner can subdivide");
        _subdivideQTNode(uint64(_tokenId));
    }

    /**
     * @notice this function subdivides the QuadTree node into 4 child QuadTree nodes
     * @notice quad coordinates are at the center of the quad - this makes dividing coords relative...
     * for root: x=1023, y=1023, w=2048, h=2048
     *  wChild = wParent/2 = 1024
     *  currently: xParent + wChild/2 = xParent + wParent/4 > 1023 + 512 = 1535
     * @dev special care was taken when writing this function so that this function does not transfer any ownership!
     */
    function _subdivideQTNode(uint64 _tokenId) private { 
        QuadTree storage qtree = qtrees[_tokenId];
        uint16 x = qtree.boundary.x;
        uint16 y = qtree.boundary.y;
        uint16 w = qtree.boundary.w;
        uint16 h = qtree.boundary.h;
        require(w > 1 && h > 1, "NFTG: cannot divide"); // cannot divide w or h=1 and 0 is not expected
        if (qtree.owner != address(0x0)) {
            _burn(uint256(_tokenId));
        }
        // special case for w|h=2
        // X2:0,0:x,y = 1,0 & 0,0 & 1,1 & 0,1
        // X2:1,0:x,y = 2,0 & 2,0 & 2,2 & 0,2
        // X2:1,1:x,y = 2,1 & 1,1 & 2,2 & 1,2
        // X2:2,2:x,y = 4,3 & 3,3 & 4,4 & 3,4
        if ((w == 2) || (h==2)) {
            qtree.northeast = _createQTNode(qtree.owner, x + 1, y - 0, w/2, h/2);
            qtree.northwest = _createQTNode(qtree.owner, x - 0, y - 0, w/2, h/2);
            qtree.southeast = _createQTNode(qtree.owner, x + 1, y + 1, w/2, h/2);
            qtree.southwest = _createQTNode(qtree.owner, x - 0, y + 1, w/2, h/2);
        } else {
            qtree.northeast = _createQTNode(qtree.owner, x + w/4, y - h/4, w/2, h/2);
            qtree.northwest = _createQTNode(qtree.owner, x - w/4, y - h/4, w/2, h/2);
            qtree.southeast = _createQTNode(qtree.owner, x + w/4, y + h/4, w/2, h/2);
            qtree.southwest = _createQTNode(qtree.owner, x - w/4, y + h/4, w/2, h/2);
        }
        qtree.divided = true;
        qtree.owner = address(0x0);
    }

    /**
     * @notice creates a QuadTree node - which is placement of pixels as well as mints the NFT as long as there is an actual owner
     * @param _owner is who the owner of the QuadTree and the NFT will be, this can be zero and if so then the QuadTree node is not owned and the NFT is not minted
     * @param _x is the x location
     * @param _y is the y location
     * @param _w is the width
     * @param _h is the height
     * @return tokenId the tokenId of the quad
     */
    function _createQTNode(address _owner, uint16 _x, uint16 _y, uint16 _w, uint16 _h) private returns(uint64 tokenId) {
        Rectangle memory boundary = Rectangle(_x, _y, _w, _h);
        // console.log("_x", _x, "_y", _y);
        // console.log("_w", _w, "_h", _h);
        tokenId = getTokenIdFromRange(boundary);
        QuadTree storage qtree = qtrees[tokenId];
        qtree.boundary = boundary;
        qtree.owner = _owner;
        if (_owner != address(0)) {
            _safeMint(_owner, tokenId);
        }
    }

    /**
     * @notice decodes the token ID into a rectangle
     * @dev symetric: should be kept up-to-date with JS implementation
     * entokenIdd tokenId: 0x<X:2 bytes>_<Y:2 bytes>_<W:2 bytes>_wers of 2 are 0x1 = 1, 0x10 = 2, 0x100 = 4, etc.
     *    4: 0x100 & (0x100 - 1) = 0x100 & 0x011 = 0x000
     * negative tests:
     *    7: 0x111 & (0x111 - 1) = 0x111 & 0x110 = 0x110
     *    5: 0x101 & (0x101 - 1) = 0x101 & 0x100 = 0x100
     * @dev for the x & y validation, these values are always in the middle of the first tile (0.5 * w, 0.5 * h) and are then at increments of w & h
     * therefor we can use the modulo operator and check that the remainder is precisely the offset:
     * @dev we offset x & y left one and up one so that for X1 the w=1/h=1 has x=0/y=0 and just as well for X2 w=2/h=2 has x=0,y=0
     *    the x & y values range from 0:w-1 and 0:h-1
     *    special care should be taken around w=1 and w=2 as the first tile for both is at x=0 and y=0 and
     *      for w=1 max x&y=2047 for w=2 max x&y=2046
     *<H:2 bytes> = 8 bytes = 64 bits (4 hex represent 2 bytes)
     * to get x we right shift by 6 bytes: 0x0000_0000_0000_<X:2 bytes>
     * to get y we right shift by 4 bytes & 0xFFFF: 0x0000_0000_<X:2 bytes>_<Y:2 bytes> & 0xFFFF = 0x0000_0000_0000_<Y:2 bytes>
     * @param _tokenId is the token ID to get the range of
     * @return range is the rectangle/range decoded from the NFTs token ID
     */
    function getRangeFromTokenId(uint64 _tokenId) public pure returns(Rectangle memory range) {
        uint16 mask = 0xFFFF;
        range.x = uint16((_tokenId >> 6 * 8) & mask);
        range.y = uint16((_tokenId >> 4 * 8) & mask);
        range.w = uint16((_tokenId >> 2 * 8) & mask);
        range.h = uint16(_tokenId & mask);
        validate(range);
    }

    /**
     * @notice encodes a rectangle into a token ID
     * @dev symetric: should be kept up-to-date with JS implementation
     * @dev tokenId: 0x<X:2 bytes><Y:2 bytes><W:2 bytes><H:2 bytes> = 8 bytes = 64 bits
     * @param _range is the rectangle to encode
     * @return tokenId is the token ID encoded from the rectangle
     */
    function getTokenIdFromRange(Rectangle memory _range) public pure returns(uint64 tokenId) {
        validate(_range);
        tokenId = _getTokenIdFromRangeNoCheck(_range);
    }

    /**
     * @notice performs an unchecked encoding of a rectable into a token ID (used where validate was already run)
     * @param _range is the rectangle to encode
     * @return tokenId is the token ID encoded from the rectangle
     */
    function _getTokenIdFromRangeNoCheck(Rectangle memory _range) private pure returns(uint64 tokenId) {
        tokenId = (uint64(_range.x) << 6 * 8) + (uint64(_range.y) << 4 * 8) + (uint64(_range.w) << 2 * 8) + uint64(_range.h);
    }

    /**
     * @notice validates a rectangle to make sure it conforms to the x & y placement rules as well as w & h follow the sizing rules, reverts if any rule is broken
     * @dev symetric: should be kept up-to-date with JS implementation
     * @dev the w and h must be a power of 2 and instead of comparing to all of the values in the enum, we just check it using:
     *    N & (N - 1)  this works because all powers of 2 are 0x1 = 1, 0x10 = 2, 0x100 = 4, etc.
     *    4: 0x100 & (0x100 - 1) = 0x100 & 0x011 = 0x000
     * negative tests:
     *    7: 0x111 & (0x111 - 1) = 0x111 & 0x110 = 0x110
     *    5: 0x101 & (0x101 - 1) = 0x101 & 0x100 = 0x100
     * @dev for the x & y validation, these values are always in the middle of the first tile (0.5 * w, 0.5 * h) and are then at increments of w & h
     * there for we can use the modulo operator and check that the remainder is precisely the offset:
     * @dev we offset x & y left one and up one so that for X1 the w=1/h=1 has x=0/y=0 and just as well for X2 w=2/h=2 has x=0,y=0
     *    the x & y values range from 0:w-1 and 0:h-1
     *    special care should be taken around w=1 and w=2 as the first tile for both is at x=0 and y=0 and
     *      for w=1 max x&y=2047 for w=2 max x&y=2046
     * @param _range is the rectangle to validate
     */
    function validate(Rectangle memory _range) public pure {
        require((_range.x <= GRID_W - 1), "NFTG: x is out-of-bounds");
        require((_range.y <= GRID_H - 1), "NFTG: y is out-of-bounds");
        require((_range.w > 0), "NFTG: w must be greater than 0");
        require((_range.h > 0), "NFTG: h must be greater than 0");
        require((_range.w <= GRID_W), "NFTG: w is too large");
        require((_range.h <= GRID_H), "NFTG: h is too large");
        require((_range.w & (_range.w - 1) == 0), "NFTG: w is not a power of 2"); 
        require((_range.h & (_range.h - 1) == 0), "NFTG: h is not a power of 2");
        uint16 xMidOffset = _range.w / 2; // for w=1 xmid=0, w=2 xmid=1, w=4 xmid=2, etc.
        uint16 yMidOffset = _range.h / 2;
        // for w=1 and x=2047: (2047+1)%1=0, w=2 and x=1023: (1023+1)%2=0, w=4 and x=255: (255+1)%4=0
        require(((_range.x + 1) % _range.w) == xMidOffset, "NFTG: x is not a multiple of w");
        require(((_range.y + 1) % _range.h) == yMidOffset, "NFTG: y is not a multiple of h");
    }

    //// BOILERPLATE
    
    /**
     * @notice receive ETH with no calldata
     * @dev see: https://blog.soliditylang.org/2020/03/26/fallback-receive-split/
     */ 
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @notice receive ETH with no function match
     */
    fallback() external payable {}

    /**
     * @notice allow withdraw of any ETH sent directly to the contract
     */
    function withdraw() external onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(address(this).balance);
    }

    /**
     * @notice allow withdraw of any ERC20 sent directly to the contract
     * @param _token the address of the token to use for withdraw
     * @param _amount the amount of the token to withdraw
     */
    function withdrawToken(address _token, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
    }
}