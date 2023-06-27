// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../lib/TransferHelper.sol";
import "../Validatable.sol";

contract PreSale is Validatable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    /**
     *  @notice _preSaleCounter uint256 (counter). This is the counter for store
     *          current presale ID value in storage.
     */
    CountersUpgradeable.Counter private _preSaleCounter;

    struct PreSaleInfo {
        address collection;
        address paymentToken;
        uint256 id;
        uint256 maximum;
        uint256 boughtQty;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        bool status;
    }

    /**
     *  @notice treasury is address of treasury manager
     */
    address public treasury;

    /**
     *  @notice mapping id => preSaleInfo
     */
    mapping(uint256 => PreSaleInfo) public preSales;

    /**
     *  @notice mapping user address => id > uint256 is claimable of user
     */
    mapping(address => mapping(uint256 => uint256)) public claimable;

    /**
     *  @notice mapping user address => id => amount of each user bought
     */
    mapping(address => mapping(uint256 => uint256)) public boughtAmountOf;

    event CreatedPreSale(uint256 indexed id, PreSaleInfo preSaleInfo);
    event UpdatedPreSale(uint256 indexed id, PreSaleInfo preSaleInfo);
    event Bought(uint256 indexed id, address indexed user, uint256 times);
    event SetWhitelist(uint256 indexed id, address[] users, uint256[] amounts);
    event CancelledPreSale(uint256 indexed id);

    /**
     * @notice Init contract
     * @dev    Replace for contructor
     * @param _admin Address of admin contract
     */
    function initialize(IAdmin _admin) public initializer {
        __Validatable_init(_admin);
        __ReentrancyGuard_init();
        treasury = admin.treasury();
    }

    /**
     * Throw an exception if public id is not valid
     */
    modifier validPreSaleId(uint256 id) {
        require(id > 0 && id <= _preSaleCounter.current(), "Invalid id");
        _;
    }

    /**
     * @notice create preSale
     * @dev    Only admin can call this function
     * @param collection Address of collection contract
     * @param paymentToken Address of the payment token
     * @param maximum Max nft can buy
     * @param startTime Time to start
     * @param endTime Time to end
     * @param price Price of NFT
     * @param receivers List of receivers
     * @param amounts List of amount
     *
     * emit {CreatePreSale} events
     */
    function createPreSale(
        address collection,
        address paymentToken,
        uint256 maximum,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyAdmin validGenesis(collection) notZero(maximum) {
        require(startTime > 0 && startTime < endTime, "Invalid time");
        require(admin.isPermittedPaymentToken(paymentToken), "Invalid payment token");

        _preSaleCounter.increment();
        preSales[_preSaleCounter.current()] = PreSaleInfo({
            id: _preSaleCounter.current(),
            collection: collection,
            paymentToken: paymentToken,
            maximum: maximum,
            boughtQty: 0,
            startTime: startTime,
            endTime: endTime,
            price: price,
            status: true
        });

        _setWhitelist(_preSaleCounter.current(), receivers, amounts);

        emit CreatedPreSale(_preSaleCounter.current(), preSales[_preSaleCounter.current()]);
    }

    /**
     * @notice update preSale
     * @dev    Only admin can call this function
     * @param id Id of preSale
     * @param paymentToken Address of the payment token
     * @param maximum Max nft can buy
     * @param startTime Time to start
     * @param endTime Time to end
     * @param price Price of NFT
     *
     * emit {UpdatedPreSale} events
     */
    function updatePreSale(
        uint256 id,
        address paymentToken,
        uint256 maximum,
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyAdmin validPreSaleId(id) notZero(maximum) {
        require(startTime > 0 && startTime < endTime, "Invalid time");
        require(admin.isPermittedPaymentToken(paymentToken), "Invalid payment token");

        PreSaleInfo storage preSaleInfo = preSales[id];
        require(preSaleInfo.status, "PreSale was cancel");

        preSaleInfo.paymentToken = paymentToken;
        preSaleInfo.maximum = maximum;
        preSaleInfo.startTime = startTime;
        preSaleInfo.endTime = endTime;
        preSaleInfo.price = price;

        emit UpdatedPreSale(id, preSaleInfo);
    }

    /**
     * @notice Set whitelist that will be able to buy NFT
     * @dev    Only admin can call this function
     * @param id Id of preSale
     * @param receivers List of receivers
     * @param amounts List of amount
     *
     * emit {SetWhitelist} events
     */
    function setWhitelist(uint256 id, address[] memory receivers, uint256[] memory amounts) external onlyAdmin {
        _setWhitelist(id, receivers, amounts);
        emit SetWhitelist(id, receivers, amounts);
    }

    /**
     * @notice User buy nft
     * @param id Id of preSale
     * @param times Number nft that user want to buy
     *
     * emit {Bought} events
     */
    function buy(uint256 id, uint256 times) external payable nonReentrant notZero(times) {
        require(claimable[_msgSender()][id] >= times, "Insufficient claim amount");
        PreSaleInfo storage preSaleInfo = preSales[id];
        require(preSaleInfo.status, "PreSale was cancel");
        require(
            preSaleInfo.startTime <= block.timestamp && block.timestamp <= preSaleInfo.endTime,
            "Can not buy at this time"
        );

        require(preSaleInfo.boughtQty + times <= preSaleInfo.maximum, "Exceed the allowed qty");

        uint256 amount = times * preSaleInfo.price;
        if (preSaleInfo.paymentToken == address(0)) {
            require(msg.value == amount, "Invalid amount");
        }

        boughtAmountOf[_msgSender()][id] += times;
        preSaleInfo.boughtQty += times;
        claimable[_msgSender()][id] -= times;

        // Payment
        TransferHelper._transferToken(preSaleInfo.paymentToken, amount, _msgSender(), treasury);

        //slither-disable-next-line unused-return
        IHLPeaceGenesisAngel(preSaleInfo.collection).mintBatch(_msgSender(), times);

        // Emit events
        emit Bought(id, _msgSender(), times);
    }

    /**
     * @notice cancel preSale
     * @param id Id of preSale
     *
     * emit {CancelledPreSale} events
     */
    function cancelPreSale(uint256 id) external onlyAdmin validPreSaleId(id) {
        require(preSales[id].status, "PreSale was cancel");
        preSales[id].status = false;

        // Emit events
        emit CancelledPreSale(id);
    }

    /**
     * @notice setWhitelist
     */
    function _setWhitelist(
        uint256 id,
        address[] memory receivers,
        uint256[] memory amounts
    ) private validPreSaleId(id) {
        require(preSales[id].status, "PreSale was cancel");
        require(receivers.length > 0 && receivers.length == amounts.length, "Invalid length");
        for (uint256 i = 0; i < receivers.length; i++) {
            require(receivers[i] != address(0), "Invalid address");
            claimable[receivers[i]][id] = amounts[i];
        }
    }

    /**
     *
     *  @notice Get preSale counter
     *
     *  @dev    All caller can call this function.
     */
    function getPreSaleCounter() external view returns (uint256) {
        return _preSaleCounter.current();
    }
}