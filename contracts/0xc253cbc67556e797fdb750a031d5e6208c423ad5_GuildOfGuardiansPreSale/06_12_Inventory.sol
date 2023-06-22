pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Constants.sol";
import "./Dice.sol";
import "./ExchangeRate.sol";
import "./Referral.sol";

contract Inventory is Constants, AccessControl, Dice, ExchangeRate, Referral {
    address[cNumHeroTypes] public mythicOwner;
    Settings settings;
    uint256[numProduct] public originalStock;
    uint256[numProduct] public stockAvailable;
    bool public stockFixed = false;
    uint256[2][numProduct] public productPrices;

    struct Settings {
        uint256 firstChromaChance;
        uint256 secondChromaChance;
        uint256 rareToEpicUpgradeChance;
        uint256 rareToLegendaryUpgradeChance;
        uint256 epicToLegendaryUpgradeChance;
        uint256 petRareChance;
        uint256 petEpicChance;
        uint256 petLegendaryChance;
        uint256 rareHeroMythicChance;
        uint256 epicHeroMythicChance;
        uint256 legendaryHeroMythicChance;
    }

    struct AllocatedOrder {
        uint256 firstDiceRoll;
        uint16[] order;
    }

    struct DetailedAllocation {
        Product product;
        Rarity rarity;
        uint8 heroPetType;
        uint8 chroma;
        bool potentialMythic;
    }

    event AllocateOrder(
        AllocatedOrder _allocatedOrder,
        address indexed _owner,
        uint256 _orderPrice
    );
    event PermanentlyLockStock();
    event GiftOrder(address indexed _giftRecipient);
    event ClaimMythic(
        AllocatedOrder _allocatedOrder,
        uint256 _mythicOrderLine,
        address indexed _customerAddr
    );

    constructor(address _usdEthPairAddress)
        Dice(cMaxRandom, cFutureBlockOffset)
        ExchangeRate(_usdEthPairAddress)
        Referral(cReferralDiscount, cReferrerBonus)
    {}

    /// STOCK:

    /// @notice Allows product owner to add additional waves of stock
    /// @param _stockToAdd Additional stock as an array indexed by product id
    function addStock(uint16[] memory _stockToAdd) public {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        require(!stockFixed, "No more stock can be added");
        for (uint256 i = 0; i < numProduct; i++) {
            originalStock[i] += _stockToAdd[i];
            stockAvailable[i] += _stockToAdd[i];
        }
    }

    /// @notice Allows product owner to lock stock so that buyers know nomore will be created
    function permanentlyLockStock() public {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        require(!stockFixed, "Stock already locked");
        stockFixed = true;
        emit PermanentlyLockStock();
    }

    function _updateStockLevels(uint16[] memory _order) internal {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        stockAvailable[uint8(Product.RareHeroPack)] -= _order[
            uint8(Product.RareHeroPack)
        ];
        stockAvailable[uint8(Product.EpicHeroPack)] -= _order[
            uint8(Product.EpicHeroPack)
        ];
        stockAvailable[uint8(Product.LegendaryHeroPack)] -= _order[
            uint8(Product.LegendaryHeroPack)
        ];
        stockAvailable[uint8(Product.PetPack)] -= _order[
            uint8(Product.PetPack)
        ];
        stockAvailable[uint8(Product.EnergyToken)] -= _order[
            uint8(Product.EnergyToken)
        ];
        stockAvailable[uint8(Product.BasicGuildToken)] -= _order[
            uint8(Product.BasicGuildToken)
        ];
        stockAvailable[uint8(Product.Tier1GuildToken)] -= _order[
            uint8(Product.Tier1GuildToken)
        ];
        stockAvailable[uint8(Product.Tier2GuildToken)] -= _order[
            uint8(Product.Tier2GuildToken)
        ];
        stockAvailable[uint8(Product.Tier3GuildToken)] -= _order[
            uint8(Product.Tier3GuildToken)
        ];
    }

    function _countStock() internal view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < numProduct; i++) {
            count += stockAvailable[i];
        }
        return count;
    }

    /// ALLOCATION:

    /// @param _allocatedOrder The order and allocated random number
    /// @param _secondDiceRoll random number as result of `getSecondDiceRoll`
    /// @return the allocated rarity, type, chroma, and mythic status for each order line
    function decodeAllocation(
        AllocatedOrder memory _allocatedOrder,
        uint256 _secondDiceRoll
    ) public view returns (DetailedAllocation[] memory) {
        uint256 numLines = _calcNumOrderLines(_allocatedOrder.order);
        // DetailedAllocation[uint(numLines)] detailedAllocation;
        DetailedAllocation[] memory detailedAllocation =
            new DetailedAllocation[](numLines);
        uint16 orderLineNumber;
        // Process Rare hero packs
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.RareHeroPack)];
            i++
        ) {
            Rarity rarity =
                _rarityAllocation(
                    Rarity.Rare,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(3),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 chroma =
                _chromaAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(2),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 heroType =
                _heroTypeAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(1),
                                orderLineNumber
                            )
                        )
                    )
                );
            bool potentialMythic =
                _mythicAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(4),
                                orderLineNumber
                            )
                        )
                    )
                );
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.RareHeroPack,
                rarity: rarity,
                heroPetType: heroType,
                chroma: chroma,
                potentialMythic: potentialMythic
            });
            orderLineNumber++;
        }
        // Process Epic hero packs
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.EpicHeroPack)];
            i++
        ) {
            Rarity rarity =
                _rarityAllocation(
                    Rarity.Epic,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(3),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 chroma =
                _chromaAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(2),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 heroType =
                _heroTypeAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(1),
                                orderLineNumber
                            )
                        )
                    )
                );
            bool potentialMythic =
                _mythicAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(4),
                                orderLineNumber
                            )
                        )
                    )
                );
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.EpicHeroPack,
                rarity: rarity,
                heroPetType: heroType,
                chroma: chroma,
                potentialMythic: potentialMythic
            });
            orderLineNumber++;
        }
        // Process Legendary hero packs
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.LegendaryHeroPack)];
            i++
        ) {
            Rarity rarity =
                _rarityAllocation(
                    Rarity.Legendary,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(3),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 chroma =
                _chromaAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(2),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 heroType =
                _heroTypeAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(1),
                                orderLineNumber
                            )
                        )
                    )
                );
            bool potentialMythic =
                _mythicAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(4),
                                orderLineNumber
                            )
                        )
                    )
                );
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.LegendaryHeroPack,
                rarity: rarity,
                heroPetType: heroType,
                chroma: chroma,
                potentialMythic: potentialMythic
            });
            orderLineNumber++;
        }
        // Process pet packs
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.PetPack)];
            i++
        ) {
            uint8 petType =
                _petTypeAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(1),
                                orderLineNumber
                            )
                        )
                    )
                );
            Rarity petRarity =
                _petRarityAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(2),
                                orderLineNumber
                            )
                        )
                    )
                );
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.PetPack,
                rarity: petRarity,
                heroPetType: petType,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }

        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.BasicGuildToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.BasicGuildToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.Tier1GuildToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.Tier1GuildToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.Tier2GuildToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.Tier2GuildToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.Tier3GuildToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.Tier3GuildToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.EnergyToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.EnergyToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        return detailedAllocation;
    }

    /// @notice If a customer is allocated a potential mythic, Immutable will call this function to claim it for them. Only one mythic exists for each hero type hence cannot be claimed by more than one customer
    /// @param _allocatedOrder The allocated order purchased by the customer
    /// @param _mythicOrderLine The order line containing the potential mythic
    /// @param _secondDiceRoll random number as result of `getSecondDiceRoll`
    function claimMythicForCustomer(
        AllocatedOrder memory _allocatedOrder,
        uint256 _mythicOrderLine,
        address _customerAddr,
        uint256 _secondDiceRoll
    ) public {
        require(
            hasRole(IMMUTABLE_SYSTEM_ROLE, msg.sender),
            "Caller is not immutable"
        );
        if (
            _confirmMythic(_allocatedOrder, _mythicOrderLine, _secondDiceRoll)
        ) {
            uint256 heroType =
                _getMythicHeroType(
                    _allocatedOrder,
                    _mythicOrderLine,
                    _secondDiceRoll
                );
            mythicOwner[heroType] = _customerAddr;
        }
        emit ClaimMythic(_allocatedOrder, _mythicOrderLine, _customerAddr);
    }

    /// @notice If a customer is allocated a potential mythic, they need to call this function to confirm it is still available. Only one mythic exists for each hero type hence cannot be claimed by more than one customer
    /// @param _allocatedOrder The allocated order purchased by the customer
    /// @param _mythicOrderLine The order line containing the potential mythic
    /// @param _secondDiceRoll random number as result of `getSecondDiceRoll`
    /// @return true if the mythic is still available, false if already sold
    function confirmMythic(
        AllocatedOrder memory _allocatedOrder,
        uint256 _mythicOrderLine,
        uint256 _secondDiceRoll
    ) public view returns (bool) {
        return
            _confirmMythic(_allocatedOrder, _mythicOrderLine, _secondDiceRoll);
    }

    function _confirmMythic(
        AllocatedOrder memory _allocatedOrder,
        uint256 _mythicOrderLine,
        uint256 _secondDiceRoll
    ) internal view returns (bool) {
        DetailedAllocation[] memory detailedAllocations =
            decodeAllocation(_allocatedOrder, _secondDiceRoll);
        DetailedAllocation memory potentialMythicAllocation =
            detailedAllocations[_mythicOrderLine];
        uint256 heroType = potentialMythicAllocation.heroPetType;
        if (
            potentialMythicAllocation.potentialMythic &&
            mythicOwner[heroType] == address(0)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function _getMythicHeroType(
        AllocatedOrder memory _allocatedOrder,
        uint256 _mythicOrderLine,
        uint256 _secondDiceRoll
    ) internal view returns (uint256) {
        DetailedAllocation[] memory detailedAllocations =
            decodeAllocation(_allocatedOrder, _secondDiceRoll);
        DetailedAllocation memory potentialMythicAllocation =
            detailedAllocations[_mythicOrderLine];
        return potentialMythicAllocation.heroPetType;
    }

    /// @notice Allocate stock
    /// @dev Function will throw underflow exception if insufficient stock
    function _allocateStock(
        uint16[] memory _order,
        address _owner,
        uint256 _orderPrice
    ) internal {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        _updateStockLevels(_order);

        uint256 firstDiceRoll = getFirstDiceRoll(_countStock());

        AllocatedOrder memory ao =
            AllocatedOrder({firstDiceRoll: firstDiceRoll, order: _order});
        emit AllocateOrder(ao, _owner, _orderPrice);
    }

    function _rarityAllocation(Rarity _originalRarity, uint256 _random)
        internal
        view
        returns (Rarity finalRarity)
    {
        uint256 score = _random % cMaxRandom;
        if (_originalRarity == Rarity.Rare) {
            if (
                _diceWinRanged(
                    score,
                    0,
                    settings.rareToLegendaryUpgradeChance,
                    cMaxRandom
                )
            ) {
                return Rarity.Legendary;
            } else if (
                _diceWinRanged(
                    score,
                    settings.rareToLegendaryUpgradeChance,
                    settings.rareToLegendaryUpgradeChance +
                        settings.rareToEpicUpgradeChance,
                    cMaxRandom
                )
            ) {
                return Rarity.Epic;
            } else {
                return Rarity.Rare;
            }
        }
        if (_originalRarity == Rarity.Epic) {
            if (
                _diceWin(
                    score,
                    settings.epicToLegendaryUpgradeChance,
                    cMaxRandom
                )
            ) {
                return Rarity.Legendary;
            } else {
                return Rarity.Epic;
            }
        }
        return _originalRarity;
    }

    function _mythicAllocation(Rarity _rarity, uint256 _random)
        internal
        view
        returns (bool)
    {
        uint256 score = _random % cMaxRandom;
        if (
            _rarity == Rarity.Rare &&
            _diceWin(score, settings.rareHeroMythicChance, cMaxRandom)
        ) {
            return true;
        }
        if (
            _rarity == Rarity.Epic &&
            _diceWin(score, settings.epicHeroMythicChance, cMaxRandom)
        ) {
            return true;
        }
        if (
            _rarity == Rarity.Legendary &&
            _diceWin(score, settings.legendaryHeroMythicChance, cMaxRandom)
        ) {
            return true;
        }
        return false;
    }

    function _chromaAllocation(uint256 _random) internal view returns (uint8) {
        uint256 score = _random % cMaxRandom;
        if (_diceWin(score, settings.secondChromaChance, cMaxRandom)) {
            return 2;
        }
        if (_diceWin(score, settings.firstChromaChance, cMaxRandom)) {
            return 1;
        }
        return 0;
    }

    //[email protected] See https://docs.google.com/spreadsheets/d/1etc3RR2LN_mXRnbvh54p9ZYPrwtqKhGymdqUna_MJzY/edit#gid=142152434 for explanation
    function _heroTypeAllocation(Rarity _heroRarity, uint256 _random)
        internal
        view
        returns (uint8)
    {
        uint8 heroType;
        uint256 score = _random % cMaxRandom;

        if (_heroRarity == Rarity.Legendary) {
            // Assign a hero type between 1 and 8
            heroType = uint8((score % cNumLegendaryHeroTypes) + 1);
        } else if (_heroRarity == Rarity.Epic) {
            // Assign a hero type between 9 and 19
            heroType = uint8(
                (score % cNumEpicHeroTypes) + cNumLegendaryHeroTypes + 1
            );
        } else if (_heroRarity == Rarity.Rare) {
            // Assign a hero type between 20 and 35
            heroType = uint8(
                (score % cNumRareHeroTypes) +
                    cNumEpicHeroTypes +
                    cNumLegendaryHeroTypes +
                    1
            );
        }
        return heroType;
    }

    function _petTypeAllocation(uint256 _random) internal view returns (uint8) {
        return uint8((_random % 3) + 1);
    }

    function _petRarityAllocation(uint256 _random)
        internal
        view
        returns (Rarity)
    {
        uint256 score = _random % cMaxRandom;
        uint256 startLimit = 0;
        if (_diceWinRanged(score, 0, settings.petLegendaryChance, cMaxRandom)) {
            return Rarity.Legendary;
        }
        startLimit += settings.petLegendaryChance;
        if (
            _diceWinRanged(
                score,
                startLimit,
                settings.petEpicChance,
                cMaxRandom
            )
        ) {
            return Rarity.Epic;
        }
        startLimit += settings.petEpicChance;
        if (
            _diceWinRanged(
                score,
                startLimit,
                settings.petRareChance,
                cMaxRandom
            )
        ) {
            return Rarity.Rare;
        }
        return Rarity.Common;
    }

    function _calcNumOrderLines(uint16[] memory _order)
        internal
        view
        returns (uint256)
    {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        uint256 numLines;
        for (uint256 i = 0; i < numProduct; i++) {
            numLines += _order[i];
        }
        return numLines;
    }

    /// COST:

    /// @param _productId Product ID
    /// @return Dynamic cost of specified product in USD
    function getProductCostUsd(uint8 _productId) public view returns (uint256) {
        uint256 multiplier = 1 * 10**6;
        uint256 firstPrice =
            productPrices[_productId][uint256(Price.FirstSale)];
        uint256 lastPrice = productPrices[_productId][uint256(Price.LastSale)];

        uint256 itemsSold =
            originalStock[uint8(_productId)] -
                stockAvailable[uint8(_productId)];

        if (itemsSold == 0) {
            return firstPrice;
        }

        uint256 relativePriceMovement =
            (itemsSold * multiplier) / originalStock[uint8(_productId)];

        uint256 maxPriceChange = lastPrice - firstPrice;

        uint256 actualPriceChange =
            (maxPriceChange * relativePriceMovement) / multiplier;

        return firstPrice + actualPriceChange;
    }

    /// @param _productId Product ID
    /// @return Dynamic cost of specified product in ETH
    function getProductCostWei(uint8 _productId) public view returns (uint256) {
        return getWeiPrice(getProductCostUsd(_productId));
    }

    /// @param _order Ordered quantity of each product type
    /// @return Total order cost in USD
    function calcOrderCostUsd(uint16[] memory _order)
        public
        view
        returns (uint256)
    {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        uint256 orderCost;
        for (uint8 i = 0; i < _order.length; i++) {
            orderCost += _calcOrderLineCost(i, _order[i]);
        }
        return orderCost;
    }

    /// @param _order Ordered quantity of each product type
    /// @return Total order cost in WEI
    function calcOrderCostWei(uint16[] memory _order)
        public
        view
        returns (uint256)
    {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        return getWeiPrice(calcOrderCostUsd(_order));
    }

    function _calcOrderLineCost(uint8 _productId, uint16 _quantity)
        internal
        view
        returns (uint256)
    {
        return getProductCostUsd(_productId) * _quantity;
    }

    /// CART:

    /// @notice Allows a purchase to be made, allocates a random number determine product allocation, and adjusts stock levels
    function purchase(uint16[] memory _order, address _referrer)
        public
        payable
    {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        _enforceOrderLimits(_order);

        uint256 orderCostUsd = calcOrderCostUsd(_order);
        uint256 referrerBonusUsd;
        uint256 discountUsd;

        if (_referrer != address(0)) {
            (referrerBonusUsd, discountUsd) = _calcReferrals(orderCostUsd);
        }

        (uint112 usdReserve, uint112 ethReserve, uint32 blockTimestampLast) =
            usdEthPair.getReserves();

        if (referrerBonusUsd > 0) {
            referrerBonuses[_referrer] += _calcWeiFromUsd(
                usdReserve,
                ethReserve,
                referrerBonusUsd
            );
        }
        uint256 discountWei =
            _calcWeiFromUsd(usdReserve, ethReserve, discountUsd);
        uint256 netWei =
            _calcWeiFromUsd(usdReserve, ethReserve, orderCostUsd) - discountWei;

        require(msg.value >= netWei, "Insufficient funds");

        _allocateStock(
            _order,
            msg.sender,
            orderCostUsd - referrerBonusUsd - discountUsd
        );
        if (msg.value - netWei > 0) {
            (bool success, ) =
                payable(msg.sender).call{value: msg.value - netWei}("");
            require(success, "Transfer failed");
        }
    }

    /// @notice Gift packs
    /// @param _giftOrder Products to gift
    /// @param _giftRecipient Address of gift recipient
    function giftPack(uint16[] memory _giftOrder, address _giftRecipient)
        public
    {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        _enforceOrderLimits(_giftOrder);
        _allocateStock(_giftOrder, _giftRecipient, 0);
        emit GiftOrder(_giftRecipient);
    }

    /// @notice Add stock and immediately gift it
    /// @param _giftOrder Products to gift
    /// @param _giftRecipient Address of gift recipient
    function addStockAndGift(uint16[] memory _giftOrder, address _giftRecipient)
        public
    {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        require(!stockFixed, "No more stock can be added");
        _enforceOrderLimits(_giftOrder);
        addStock(_giftOrder);
        _allocateStock(_giftOrder, _giftRecipient, 0);
        emit GiftOrder(_giftRecipient);
    }

    function _enforceOrderLimits(uint16[] memory _order) internal {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        for (uint256 i = 0; i < numProduct; i++) {
            require(_order[i] <= 100, "Max limit 100 per item");
        }
    }
}