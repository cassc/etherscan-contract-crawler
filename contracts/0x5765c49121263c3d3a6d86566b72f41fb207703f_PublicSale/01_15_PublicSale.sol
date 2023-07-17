// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../Validatable.sol";
import "../lib/TransferHelper.sol";

contract PublicSale is Validatable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    /**
     *  @notice _publicSaleCounter uint256 (counter). This is the counter for store
     *          current public sale ID value in storage.
     */
    CountersUpgradeable.Counter private _publicSaleCounter;

    struct PublicSaleInfo {
        address collection;
        address paymentToken;
        uint256 id;
        uint256 boughtQty;
        uint256 maxPerUser;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        bool status;
        uint256 maximum;
    }

    /**
     *  @notice treasury is address of treasury manager
     */
    address public treasury;

    /**
     *  @notice mapping id => preSaleInfo
     */
    mapping(uint256 => PublicSaleInfo) public publicSales;

    /**
     *  @notice mapping user address => id => amount of each user bought
     */
    mapping(address => mapping(uint256 => uint256)) public boughtAmountOf;

    event Bought(uint256 indexed id, address indexed user, uint256 times);
    event CreatedPublicSale(uint256 indexed id, PublicSaleInfo publicSaleInfo);
    event UpdatedPublicSale(uint256 indexed id, PublicSaleInfo publicSaleInfo);
    event CancelledPublicSale(uint256 indexed id);

    /**
     * @notice Init contract
     * @dev    Replace for contructor
     * @param _admin Address of admin contract
     */
    function initialize(IAdmin _admin) public initializer {
        __Validatable_init(_admin);
        treasury = admin.treasury();
    }

    /**
     * Throw an exception if public sale id is not valid
     */
    modifier validPublicSaleId(uint256 id) {
        require(id > 0 && id <= _publicSaleCounter.current(), "Invalid id");
        _;
    }

    /**
     * @notice create publicSale
     * @dev    Only admin can call this function
     * @param collection Address of collection contract
     * @param paymentToken Address of the payment token
     * @param maximum Max nft can buy
     * @param maxPerUser Max nft that one user can buy
     * @param startTime Time to start
     * @param endTime Time to end
     * @param price Price of NFT
     *
     * emit {CreatePublicSale} events
     */
    function createPublicSale(
        address collection,
        address paymentToken,
        uint256 maximum,
        uint256 maxPerUser,
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyAdmin validGenesis(collection) notZero(maximum) notZero(price) {
        require(admin.isPermittedPaymentToken(paymentToken), "Invalid payment token");
        require(startTime > 0, "Invalid time");
        if (endTime > 0) {
            require(startTime < endTime, "Invalid end time");
        }

        _publicSaleCounter.increment();
        publicSales[_publicSaleCounter.current()] = PublicSaleInfo({
            id: _publicSaleCounter.current(),
            collection: collection,
            paymentToken: paymentToken,
            boughtQty: 0,
            maximum: maximum,
            maxPerUser: maxPerUser,
            startTime: startTime,
            endTime: endTime,
            price: price,
            status: true
        });

        emit CreatedPublicSale(_publicSaleCounter.current(), publicSales[_publicSaleCounter.current()]);
    }

    /**
     * @notice update publicSale
     * @dev    Only admin can call this function
     * @param id Id of public sale
     * @param paymentToken Address of the payment token
     * @param maximum Max nft can buy
     * @param maxPerUser Max nft that one user can buy
     * @param startTime Time to start
     * @param endTime Time to end
     * @param price Price of NFT
     *
     * emit {UpdatedPublicSale} events
     */
    function updatePublicSale(
        uint256 id,
        address paymentToken,
        uint256 maximum,
        uint256 maxPerUser,
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyAdmin validPublicSaleId(id) notZero(maximum) notZero(price) {
        require(admin.isPermittedPaymentToken(paymentToken), "Invalid payment token");
        require(startTime > 0, "Invalid time");
        if (endTime > 0) {
            require(startTime < endTime, "Invalid end time");
        }

        PublicSaleInfo storage publicSaleInfo = publicSales[id];
        require(publicSaleInfo.status, "Public sale was cancel");

        publicSaleInfo.paymentToken = paymentToken;
        publicSaleInfo.maximum = maximum;
        publicSaleInfo.maxPerUser = maxPerUser;
        publicSaleInfo.startTime = startTime;
        publicSaleInfo.endTime = endTime;
        publicSaleInfo.price = price;

        emit UpdatedPublicSale(id, publicSaleInfo);
    }

    /**
     * @notice User buy nft
     * @param id Id of public sale
     * @param times Number nft that user want to buy
     *
     * emit {Bought} events
     */
    function buy(uint256 id, uint256 times) external payable nonReentrant notZero(times) {
        PublicSaleInfo storage publicSaleInfo = publicSales[id];
        require(publicSaleInfo.status, "Public sale was cancel");
        require(publicSaleInfo.startTime <= block.timestamp, "Can not buy at this time");
        if (publicSaleInfo.endTime > 0) {
            require(block.timestamp <= publicSaleInfo.endTime, "Can not buy at this time");
        }

        require(publicSaleInfo.boughtQty + times <= publicSaleInfo.maximum, "Exceed the allowed qty");

        if (publicSaleInfo.maxPerUser > 0) {
            require(boughtAmountOf[_msgSender()][id] + times <= publicSaleInfo.maxPerUser, "Limit times each user");
        }

        uint256 amount = times * publicSaleInfo.price;
        if (publicSaleInfo.paymentToken == address(0)) {
            require(msg.value == amount, "Invalid amount");
        }

        boughtAmountOf[_msgSender()][id] += times;
        publicSaleInfo.boughtQty += times;

        // Payment
        TransferHelper._transferToken(publicSaleInfo.paymentToken, amount, _msgSender(), treasury);

        // Mint
        //slither-disable-next-line unused-return
        IHLPeaceGenesisAngel(publicSaleInfo.collection).mintBatch(_msgSender(), times);

        // Emit events
        emit Bought(id, _msgSender(), times);
    }

    /**
     * @notice Cancel public sale
     * @param id Id of public sale
     *
     * emit {CancelledPublicSale} events
     */
    function cancelPublicSale(uint256 id) external onlyAdmin validPublicSaleId(id) {
        require(publicSales[id].status, "Public sale was cancel");
        publicSales[id].status = false;

        // Emit events
        emit CancelledPublicSale(id);
    }

    /**
     *
     *  @notice Get public sale counter
     *
     *  @dev    All caller can call this function.
     */
    function getPublicSaleCounter() external view returns (uint256) {
        return _publicSaleCounter.current();
    }
}