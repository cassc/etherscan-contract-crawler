// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

import "./strings.sol";
import "./GarageToken.sol";
import "./GaragePreOrder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GarageFactory is Ownable {
    using strings for *;

    uint256 public constant ONE_DAY = 86400;

    uint256 public mintedGarages = 0;
    address preOrderAddress;
    GarageToken token;

    struct CategoryData {
        uint256 totalGaragesMinted;
        uint256 totalLimit;
        uint256 dailyLimit;
        uint256 currentDayEnd;
        uint256 currentDayTotal;
    }

    mapping(uint16 => CategoryData) public categoryData;

    modifier onlyPreOrder() {
        require(msg.sender == preOrderAddress, "Not authorized");
        _;
    }

    modifier isInitialized() {
        require(preOrderAddress != address(0), "No linked preorder");
        require(address(token) != address(0), "No linked token");
        _;
    }

    constructor() {
        categoryData[1] = CategoryData(0, 0, 0, block.timestamp + ONE_DAY, 0);
        categoryData[2] = CategoryData(0, 0, 0, block.timestamp + ONE_DAY, 0);
        categoryData[3] = CategoryData(0, 0, 0, block.timestamp + ONE_DAY, 0);
    }

    function mintFor(
        address newOwner,
        uint16 size,
        uint16 category
    ) public onlyPreOrder isInitialized {
        GaragePreOrder preOrder = GaragePreOrder(preOrderAddress);
        require(preOrder.categoryExists(category), "Invalid category");
        CategoryData storage data = categoryData[category];
        require(data.dailyLimit > 0, "No daily limit set for this category");

        mintedGarages++;

        data.totalGaragesMinted += size;
        data.currentDayTotal += size;

        require(
            !hasReachedLimit(category),
            "The daily limit for this garage location has been reached"
        );

        token.mintFor(newOwner, size, category);
    }

    function hasReachedDailyLimit(uint16 category)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        CategoryData storage data = categoryData[category];

        uint256 currentTime = block.timestamp;

        uint256 dayEnd = data.currentDayEnd;

        return (
            currentTime <= dayEnd && data.currentDayTotal > data.dailyLimit,
            data.currentDayTotal,
            data.dailyLimit
        );
    }

    function hasReachedLimit(uint16 category) internal returns (bool) {
        CategoryData storage data = categoryData[category];

        uint256 currentTime = block.timestamp;
        uint256 dailyLimit = data.dailyLimit;

        uint256 dayEnd = data.currentDayEnd;

        if (currentTime >= dayEnd) {
            data.totalLimit += dailyLimit;
            data.currentDayTotal = 0;

            while (currentTime >= dayEnd) {
                dayEnd = dayEnd + ONE_DAY;
            }

            data.currentDayEnd = dayEnd;
        }

        return data.currentDayTotal > data.dailyLimit;
    }

    function setCategoryLimit(uint16 category, uint256 categoryLimit)
        public
        onlyOwner
    {
        CategoryData storage data = categoryData[category];
        require(
            data.totalGaragesMinted == 0,
            "This category already started minting tokens"
        );

        data.dailyLimit = categoryLimit;
    }

    /**
    Attach the preOrder that will be receiving tokens being marked for sale by the
    sellCar function
    */
    function attachPreOrder(address dst) public onlyOwner {
        require(preOrderAddress == address(0));
        require(dst != address(0));

        //Enforce that address is indeed a preorder
        GaragePreOrder preOrder = GaragePreOrder(dst);

        preOrderAddress = address(preOrder);
    }

    /**
    Attach the token being used for things
    */
    function attachToken(address dst) public onlyOwner {
        require(address(token) == address(0));
        require(dst != address(0));

        //Enforce that address is indeed a preorder
        GarageToken ct = GarageToken(dst);

        token = ct;
    }
}