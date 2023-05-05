//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

error PriceTooLow();
error MustApproveContractForNFT();
error ContractNotAllowed();
error InvalidItemId();
error ItemNotListed();
error SellerNotOwner();
error FeeTooHigh();
error NoChangeInApproval();
error ItemAlreadyListed();
error NotCreator();
error SaleToItemCreatorForbidden();

contract GtrNftMarketplaceV2 is ReentrancyGuard, Ownable {
    enum State {
        Created,
        Sold,
        Inactive
    }

    struct MarketItem {
        uint256 id;
        address nftContract;
        uint256 tokenID;
        address payable seller;
        address payable buyer;
        uint256 price;
        State state;
    }

    uint256 public immutable DENOMINATOR = 10000;
    uint256 public itemCounter = 1;
    uint256 public itemSoldCounter;
    uint256 public activeItems;
    uint256 public saleFee;
    uint256 public minimumPrice = 1 ether;
    address public feeCollector;
    IERC20 public saleToken;

    mapping(address => uint256[]) private userPurchases;
    mapping(address => uint256[]) private userListings;
    mapping(uint256 => MarketItem) private marketItems;
    mapping(address => mapping(address => mapping(uint256 => uint256))) userToContractToTokenToItemId;
    mapping(address => bool) public approvedNFTs;

    constructor(
        uint256 _saleFee,
        address _saleToken,
        address _feeCollector
    ) {
        saleFee = _saleFee;
        saleToken = IERC20(_saleToken);
        feeCollector = _feeCollector;
    }

    /**
     * @dev update a listing if the caller is the seller/owner and the item has not been sold or removed
     */
    function updateMarketItem(uint256 _id, uint256 _price)
        external
        payable
        nonReentrant
    {
        MarketItem memory item = marketItems[_id];
        if (_price < minimumPrice) revert PriceTooLow(); // 1 saleToken
        if (
            IERC721(item.nftContract).ownerOf(item.tokenID) != msg.sender ||
            item.seller != msg.sender
        ) revert SellerNotOwner();
        if (
            IERC721(item.nftContract).getApproved(item.tokenID) !=
            address(this) &&
            !IERC721(item.nftContract).isApprovedForAll(
                msg.sender,
                address(this)
            )
        ) revert MustApproveContractForNFT();
        if (item.state != State.Created) revert ItemNotListed();

        item.price = _price;
        marketItems[_id] = item;

        emit MarketItemUpdated(
            item.id,
            item.nftContract,
            item.tokenID,
            item.seller,
            _price,
            saleToken.decimals()
        );
    }

    /**
     * @dev create a MarketItem for NFT sale on the marketplace.
     * List an NFT.
     */
    function createMarketItem(
        address _nftContract,
        uint256 _tokenID,
        uint256 _price
    ) external payable nonReentrant {
        if (_price < minimumPrice) revert PriceTooLow(); // 1 saleToken
        if (!approvedNFTs[_nftContract]) revert ContractNotAllowed();
        if (IERC721(_nftContract).ownerOf(_tokenID) != msg.sender)
            revert SellerNotOwner();
        if (
            IERC721(_nftContract).getApproved(_tokenID) != address(this) &&
            !IERC721(_nftContract).isApprovedForAll(msg.sender, address(this))
        ) revert MustApproveContractForNFT();

        uint256 itemId = userToContractToTokenToItemId[msg.sender][
            _nftContract
        ][_tokenID];
        if (itemId != 0) revert ItemAlreadyListed();

        uint256 id = itemCounter;
        userListings[msg.sender].push(id);
        userToContractToTokenToItemId[msg.sender][_nftContract][_tokenID] = id;
        activeItems += 1;

        marketItems[itemCounter++] = MarketItem(
            id,
            _nftContract,
            _tokenID,
            payable(msg.sender),
            payable(address(0)),
            _price,
            State.Created
        );

        emit MarketItemCreated(id, _nftContract, _tokenID, msg.sender, _price, saleToken.decimals());
    }

    /**
     * @dev delete a MarketItem from the marketplace.
     *
     * de-List an NFT.
     */
    function removeMarketItem(uint256 _itemId) external nonReentrant {
        if (_itemId >= itemCounter) revert InvalidItemId();
        MarketItem memory item = marketItems[_itemId];

        if (item.state != State.Created) revert ItemNotListed();
        if (item.seller != msg.sender) revert NotCreator();

        item.state = State.Inactive;
        marketItems[_itemId] = item;
        userToContractToTokenToItemId[msg.sender][item.nftContract][
            item.tokenID
        ] = 0;
        activeItems -= 1;

        emit MarketItemRemoved(
            _itemId,
            item.nftContract,
            item.tokenID,
            item.seller,
            0,
            saleToken.decimals()
        );
    }

    /**
     * @dev (buyer) buy a MarketItem from the marketplace.
     * Transfers ownership of the item, as well as funds
     * NFT:         seller    -> buyer
     * value:       buyer     -> seller
     * saleFee:  contract  -> marketowner
     */
    function createMarketSale(uint256 _itemId) external nonReentrant {
        if (_itemId >= itemCounter) revert InvalidItemId();

        MarketItem memory item = marketItems[_itemId];

        if (item.seller == msg.sender) revert SaleToItemCreatorForbidden();
        if (item.state != State.Created) revert ItemNotListed();

        item.buyer = payable(msg.sender);
        item.state = State.Sold;
        itemSoldCounter++;
        marketItems[_itemId] = item;
        userPurchases[msg.sender].push(item.id);
        userToContractToTokenToItemId[item.seller][item.nftContract][
            item.tokenID
        ] = 0;
        activeItems -= 1;

        (uint256 marketplaceFee, uint256 sellerFee) = _calculateFee(item.price);

        IERC721(item.nftContract).transferFrom(
            item.seller,
            msg.sender,
            item.tokenID
        );
        require(
            saleToken.transferFrom(msg.sender, feeCollector, marketplaceFee),
            "Transfer failed"
        );
        require(
            saleToken.transferFrom(msg.sender, item.seller, sellerFee),
            "Transfer failed"
        );

        emit MarketItemSold(
            item.id,
            item.nftContract,
            item.tokenID,
            item.seller,
            msg.sender,
            item.price,
            saleToken.decimals()
        );
    }

    /*********** Restricted ***********/

    /**
     * @dev Closes a listing, meant for cleanup
     */
    function closeListing(uint256 _itemId) external onlyOwner {
        MarketItem memory item = marketItems[_itemId];
        if (item.state != State.Created || item.seller == address(0))
            revert ItemNotListed();

        item.state = State.Inactive;
        marketItems[_itemId] = item;
        userToContractToTokenToItemId[item.seller][item.nftContract][
            item.tokenID
        ] = 0;
        activeItems -= 1;

        emit MarketItemRemoved(
            _itemId,
            item.nftContract,
            item.tokenID,
            item.seller,
            0,
            saleToken.decimals()
        );
    }

    /**
     * @dev Sets the % of sale that goes to marketplace
     */
    function setSaleFee(uint256 _fee) external onlyOwner {
        if (_fee > 2000) revert FeeTooHigh();
        saleFee = _fee;
    }

    /**
     * @dev Sets if an NFT contract is approved for listing or not
     */
    function setContractApproval(address _contract, bool _state)
        external
        onlyOwner
    {
        if (approvedNFTs[_contract] == _state) revert NoChangeInApproval();
        approvedNFTs[_contract] = _state;
    }

    /**
     * @dev Sets the address where the fees will be collected
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    /**
     * @dev Sets the saleToken token contract
     */
    function setBUSD(address _saleToken) external onlyOwner {
        saleToken = IERC20(_saleToken);
    }

    /**
     * @dev Sets the minimum price for listings
     */
    function setMinimumPrice(uint256 _price) external onlyOwner {
        minimumPrice = _price;
    }

    /*********** View ***********/

    // !ADD active item counter

    /**
     * @dev Returns all unsold market items
     * condition:
     *  1) state == Created
     *  2) buyer = 0x0
     *  3) still have approve
     *  4) still owned by seller
     */
    function fetchItems(
        uint256 offset,
        uint256 limit,
        bool fetchAll
    ) public view returns (MarketItem[] memory) {
        uint256 total = (offset + limit + 1 > itemCounter || limit == 0)
            ? itemCounter
            : limit + 1;
        uint256 index = 0;
        uint256 itemCount = 0;

        for (uint256 i = 1 + offset; i < total; i++) {
            MarketItem memory item = marketItems[i];
            IERC721 nftContract = IERC721(item.nftContract);
            if (fetchAll || _checkCondition(item, nftContract)) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 1 + offset; i < total; i++) {
            MarketItem memory item = marketItems[i];
            IERC721 nftContract = IERC721(item.nftContract);
            if (fetchAll || _checkCondition(item, nftContract)) {
                items[index] = marketItems[i];
                index++;
            }
        }

        return items;
    }

    /**
     * @dev Returns only market items a user has listed
     * Filtering can be done on the frontend
     */
    function fetchUserListings(
        uint256 offset,
        uint256 limit,
        address _user
    ) public view returns (MarketItem[] memory) {
        uint256[] memory array = userListings[_user];

        uint256 total = (offset + limit > array.length || limit == 0)
            ? array.length
            : limit;
        uint256 index;

        MarketItem[] memory items = new MarketItem[](total - offset);

        for (uint256 i = offset; i < total; i++) {
            items[index++] = marketItems[array[i]];
        }
        return items;
    }

    /**
     * @dev Returns only market items a user has purchased
     * Any filtering should be done on the frontend
     */
    function fetchUserPurchasedItems(
        uint256 offset,
        uint256 limit,
        address _user
    ) public view returns (MarketItem[] memory) {
        uint256[] memory array = userPurchases[_user];

        uint256 total = (offset + limit > array.length || limit == 0)
            ? array.length
            : limit;
        uint256 index;

        MarketItem[] memory items = new MarketItem[](total - offset);

        for (uint256 i = offset; i < total; i++) {
            items[index++] = marketItems[array[i]];
        }
        return items;
    }

    /**
     * @dev Returns the total amount of items the user has purchased
     * Repeat purchases of the same tokenID are counted
     */
    function fetchTotalUserPurchased(address _user)
        public
        view
        returns (uint256)
    {
        return userPurchases[_user].length;
    }

    /**
     * @dev Returns the total amount of items the user has listed
     * Repeat listings of the same tokenID are counted
     */
    function fetchTotalUserListed(address _user) public view returns (uint256) {
        return userListings[_user].length;
    }

    /*********** Internal ***********/

    /**
     * @dev helper to calculate market and seller fees
     */
    function _calculateFee(uint256 _price)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 marketplaceFee = (_price * 10**18 * saleFee) /
            (DENOMINATOR * 10**18);
        uint256 sellerFee = _price - marketplaceFee;
        return (marketplaceFee, sellerFee);
    }

    function _checkCondition(MarketItem memory _item, IERC721 _nftContract)
        internal
        view
        returns (bool)
    {
        if (
            _item.buyer == address(0) &&
            _item.state == State.Created &&
            (_nftContract.ownerOf(_item.tokenID) == _item.seller) &&
            (_nftContract.getApproved(_item.tokenID) == address(this) ||
                _nftContract.isApprovedForAll(_item.seller, address(this)))
        ) return true;
        else return false;
    }

    /*********** Events ***********/

    event MarketItemCreated(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenID,
        address seller,
        uint256 price,
        uint256 decimals
    );

    event MarketItemUpdated(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenID,
        address seller,
        uint256 price,
        uint256 decimals
    );

    event MarketItemRemoved(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenID,
        address seller,
        uint256 price,
        uint256 decimals
    );

    event MarketItemSold(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenID,
        address seller,
        address buyer,
        uint256 price,
        uint256 decimals
    );
}