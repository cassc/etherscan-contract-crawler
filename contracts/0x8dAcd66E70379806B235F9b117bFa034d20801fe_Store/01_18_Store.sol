// constracts/Store.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./Collection.sol";

/*
 *     ▄▄▄·  ▐ ▄  ▄▄ • ▄▄▄   ▄· ▄▌
 *    ▐█ ▀█ •█▌▐█▐█ ▀ ▪▀▄ █·▐█▪██▌
 *    ▄█▀▀█ ▐█▐▐▌▄█ ▀█▄▐▀▀▄ ▐█▌▐█▪
 *    ▐█ ▪▐▌██▐█▌▐█▄▪▐█▐█•█▌ ▐█▀·.
 *     ▀  ▀ ▀▀ █▪·▀▀▀▀ .▀  ▀  ▀ •
 *    ·▄▄▄▄   ▄· ▄▌ ▐ ▄       • ▌ ▄ ·. ▪ ▄▄▄▄▄▄▄▄ ..▄▄ ·
 *    ██▪ ██ ▐█▪██▌•█▌▐█▪     ·██ ▐███▪██•██  ▀▄.▀·▐█ ▀.
 *    ▐█· ▐█▌▐█▌▐█▪▐█▐▐▌ ▄█▀▄ ▐█ ▌▐▌▐█·▐█·▐█.▪▐▀▀▪▄▄▀▀▀█▄
 *    ██. ██  ▐█▀·.██▐█▌▐█▌.▐▌██ ██▌▐█▌▐█▌▐█▌·▐█▄▄▌▐█▄▪▐█
 *    ▀▀▀▀▀•   ▀ • ▀▀ █▪ ▀█▄▀▪▀▀  █▪▀▀▀▀▀▀▀▀▀  ▀▀▀  ▀▀▀▀
 *    ▄▄▌   ▄▄▄· ▄▄▄▄·
 *    ██•  ▐█ ▀█ ▐█ ▀█▪
 *    ██▪  ▄█▀▀█ ▐█▀▀█▄
 *    ▐█▌▐▌▐█ ▪▐▌██▄▪▐█
 *    .▀▀▀  ▀  ▀ ·▀▀▀▀
 */

contract Store is Ownable, ReentrancyGuard {
    struct Discounts {
        uint8 twentyFive;
        uint8 fifty;
        uint8 oneHundred;
    }

    enum Status {
        NO_SALE,
        ALLOW_LIST_SALE,
        PUBLIC_SALE
    }

    uint256 public immutable MAX_PER_TX = 5;
    uint256 public immutable RETAIL_PRICE = 0.07 ether;
    Status public state = Status.NO_SALE;

    Collection private _collection;
    address private _beneficiary;

    mapping(address => uint256) private _allowListSpots;
    mapping(address => Discounts) private _discounts;

    constructor(address collection) {
        _collection = Collection(collection);
        _beneficiary = _msgSender();
    }

    modifier onlyAllowListSale() {
        require(
            state == Status.ALLOW_LIST_SALE,
            "STORE: ALLOW_LIST_SALE_NOT_STARTED"
        );
        _;
    }

    modifier onlyPublicSale() {
        require(state == Status.PUBLIC_SALE, "STORE: PUBLIC_SALE_NOT_STARTED");
        _;
    }

    function allowListSpots(address receiver) public view returns (uint256) {
        return _allowListSpots[receiver];
    }

    function discounts(address receiver)
        public
        view
        returns (Discounts memory)
    {
        return _discounts[receiver];
    }

    function totalCost(address receiver, uint256 quantity)
        public
        view
        returns (uint256)
    {
        return _totalCost(receiver, quantity);
    }

    function mintAllowListSale(uint256 quantity)
        external
        payable
        onlyAllowListSale
        nonReentrant
    {
        require(quantity > 0, "STORE: QUANTITY_CANNOT_BE_ZERO");
        require(quantity <= MAX_PER_TX, "STORE: EXCEEDS_MAX_PER_TX");

        uint256 totalSupply = _collection.totalSupply();
        uint256 maxSupply = _collection.MAX_SUPPLY();

        require(totalSupply < maxSupply, "STORE: SOLD_OUT");
        require(
            totalSupply + quantity <= maxSupply,
            "STORE: EXCEEDS_MAX_SUPPLY"
        );

        address receiver = _msgSender();

        require(
            _allowListSpots[receiver] >= quantity,
            "STORE: EXCEEDS_ALLOW_LIST_SPOTS"
        );

        uint256 calculatedTotalCost = _totalCost(receiver, quantity);

        require(calculatedTotalCost <= msg.value, "STORE: INVALID_ETH_AMOUNT");

        _internalMint(_msgSender(), quantity);
        _reduceDiscounts(receiver, quantity);
        _reduceAllowListSpots(receiver, quantity);
    }

    function mintPublicSale(uint256 quantity)
        external
        payable
        onlyPublicSale
        nonReentrant
    {
        require(quantity > 0, "STORE: QUANTITY_CANNOT_BE_ZERO");
        require(quantity <= MAX_PER_TX, "STORE: EXCEEDS_MAX_PER_TX");

        uint256 totalSupply = _collection.totalSupply();
        uint256 maxSupply = _collection.MAX_SUPPLY();

        require(totalSupply < maxSupply, "STORE: SOLD_OUT");
        require(
            totalSupply + quantity <= maxSupply,
            "STORE: EXCEEDS_MAX_SUPPLY"
        );

        address receiver = _msgSender();
        uint256 calculatedTotalCost = _totalCost(receiver, quantity);

        require(calculatedTotalCost <= msg.value, "STORE: INVALID_ETH_AMOUNT");

        _internalMint(receiver, quantity);
        _reduceDiscounts(receiver, quantity);
    }

    function mintOwner(address receiver, uint256 quantity) external onlyOwner {
        _internalMint(receiver, quantity);
    }

    function startAllowListSale() external onlyOwner {
        state = Status.ALLOW_LIST_SALE;
    }

    function startPublicSale() external onlyOwner {
        state = Status.PUBLIC_SALE;
    }

    function stopSale() external onlyOwner {
        state = Status.NO_SALE;
    }

    function setBeneficiary(address beneficiary) public onlyOwner {
        _beneficiary = beneficiary;
    }

    function setAllowListSpots(
        address[] calldata keys,
        uint256[] calldata values
    ) external onlyOwner {
        require(
            keys.length == values.length,
            "STORE: KEYS_VALUES_LENGTH_MISMATCH"
        );
        uint256 length = keys.length;
        for (uint256 i = 0; i < length; i++) {
            _allowListSpots[keys[i]] = values[i];
        }
    }

    function setDiscounts(address[] calldata keys, Discounts[] calldata values)
        external
        onlyOwner
    {
        require(
            keys.length == values.length,
            "STORE: KEYS_VALUES_LENGTH_MISMATCH"
        );
        uint256 length = keys.length;
        for (uint256 i = 0; i < length; i++) {
            _discounts[keys[i]] = values[i];
        }
    }

    function withdraw() external onlyOwner {
        payable(_beneficiary).transfer(address(this).balance);
    }

    function _internalMint(address receiver, uint256 quantity) private {
        _collection.mint(receiver, quantity);
    }

    function _totalCost(address receiver, uint256 quantity)
        private
        view
        returns (uint256)
    {
        uint256 remaining = quantity;
        uint256 cost = 0;

        Discounts memory discounts = _discounts[receiver];
        if (remaining >= discounts.oneHundred) {
            remaining = remaining - discounts.oneHundred;
        } else {
            remaining = 0;
        }

        if (remaining >= discounts.fifty) {
            remaining = remaining - discounts.fifty;
            cost = cost + (RETAIL_PRICE * discounts.fifty) / 2;
        } else {
            cost = cost + (RETAIL_PRICE * remaining) / 2;
            remaining = 0;
        }

        if (remaining >= discounts.twentyFive) {
            remaining = remaining - discounts.twentyFive;
            cost = cost + ((RETAIL_PRICE * discounts.twentyFive) / 4) * 3;
        } else {
            cost = cost + ((RETAIL_PRICE * remaining) / 4) * 3;
            remaining = 0;
        }

        return cost + remaining * RETAIL_PRICE;
    }

    function _reduceDiscounts(address receiver, uint256 quantity) private {
        uint256 remaining = quantity;

        Discounts storage discounts = _discounts[receiver];
        Discounts memory newDiscounts = Discounts({
            oneHundred: 0,
            fifty: 0,
            twentyFive: 0
        });
        if (remaining >= discounts.oneHundred) {
            newDiscounts.oneHundred = 0;
            remaining = remaining - discounts.oneHundred;
        } else {
            newDiscounts.oneHundred = discounts.oneHundred - uint8(remaining);
            remaining = 0;
        }

        if (remaining >= discounts.fifty) {
            newDiscounts.fifty = 0;
            remaining = remaining - discounts.fifty;
        } else {
            newDiscounts.fifty = discounts.fifty - uint8(remaining);
            remaining = 0;
        }

        if (remaining >= discounts.twentyFive) {
            newDiscounts.twentyFive = 0;
            remaining = remaining - discounts.twentyFive;
        } else {
            newDiscounts.twentyFive = discounts.twentyFive - uint8(remaining);
            remaining = 0;
        }

        _discounts[receiver] = newDiscounts;
    }

    function _reduceAllowListSpots(address receiver, uint256 quantity) private {
        _allowListSpots[receiver] = _allowListSpots[receiver] - quantity;
    }
}