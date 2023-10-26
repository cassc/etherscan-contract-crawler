// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IChainlinkPriceConsumer} from "./interfaces/IChainlinkPriceConsumer.sol";
import {Tiers} from "./Tiers.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {SD59x18, sd, unwrap, ln, gt, frac} from "../lib/prb-math/src/SD59x18.sol";
import {UnrenounceableOwnable2Step} from "../lib/pizza/src/UnrenounceableOwnable2Step.sol";
import {Pausable} from "../lib/pizza/src/Pausable.sol";

// import {Pausable}
// import {Un}

contract PurchasingCenter is
    UnrenounceableOwnable2Step,
    Pausable,
    Tiers,
    ReentrancyGuard
{
    IChainlinkPriceConsumer eth_pricer;

    address public eth_usd_consumer_address;

    // Just for reading.
    mapping(Tier => TierDetails) public tier_to_tierDetails;

    // The following mappings are concerned with accounting.

    /** @dev tier_to_amountSold shows how much a tier is sold, and for determining oversubscription. */
    mapping(Tier => uint256) public tier_to_amountSold;

    /** @dev address_to_tier_to_contribution shows how much eth a user has contributed to a tier. */
    mapping(address => mapping(Tier => uint256))
        public address_to_tier_to_contribution;

    /** @dev tier_to_totalContribution shows how much eth in total has been contributed to a tier. */
    mapping(Tier => uint256) public tier_to_totalContribution;

    /** @dev address_to_tier_to_pwc shows the pwc - price weighted contribution - of an address.
     * The pwc is used to calculate the average price of eth.
     */
    mapping(address => mapping(Tier => uint256)) public address_to_tier_to_pwc;
    /** @dev tier_to_tierPwc shows the pwc aggregated across an entire tier.
     */
    mapping(Tier => uint256) public tier_to_tierPwc;
    /** @dev tier_oversubscribed tells whether a tier is oversubscribed
     * A tier is marked oversubscribed when the amountSold of a tier is higher than its purchaseCap.
     * The mapping gives a cleaner and less gas intensive way to determine whether a tier is oversubscribed.
     */
    mapping(Tier => bool) public tier_oversubscribed;

    /** @dev address_to_tier_to_boughtAlready is used to mark if someone has already bought.
     * If he has already bought, when he buys again, he will not be added to the address[] arrays that follow.
     */
    mapping(address => mapping(Tier => bool))
        public address_to_tier_to_boughtAlready;

    address[] public tier1_buyers;
    address[] public tier2_buyers;
    address[] public tier3_buyers;
    address[] public tier4_buyers;

    uint256 public startTime;
    uint256 public purchaseWindow;
    uint256 public commodityPrice;

    /** @dev sd59x18_decimals is used to pad the int256 numbers so that they will be integers.
     * For instance, sd(int256(1)) would actually correspond to 0.000000000000000001.
     * Whereas sd(int256(1) * sd59x18_decimals) would correspond to 1.
     * Always multiply int256(x) with sd59x18_decimals before wrapping them into SD59x18 with sd(),
     * and always divide a unwrapped SD59x18 with sd59x18_decimals before converting to uint256.
     */
    int256 public immutable sd59x18_decimals = 1e18;

    bool public started;

    event PurchaseStarted(uint256 startTime);
    event NewPurchaseWindowSet(uint256 newPurchaseWindow);
    event NewCommodityPriceSet(uint256 newPrice);
    event NewEthUsdConsumerAddressSet(address newEthUsdConsumerAddress);
    event NewTierDetailsSet(
        uint256 newTier,
        uint256 newSellAmount,
        uint256 newDiscount,
        uint256 newLockupTime,
        uint256 newPurchaseCap
    );
    event TierContributionUpdated(uint256 tier, uint256 newContribution);
    event PwcUpdated(uint256 tier, uint256 pwc);
    event Oversubscribed(uint256 tier, address guyWhoPushedItOver);
    event BoughtTokens(uint256 tier, address guy, uint256 eth_in);
    event EthWithdrawn(address to, uint256 balance);
    event Log(string func, uint gas);

    // @notice for the sale to commence you need the following initialized
    // 1. commodity_price
    // 2. the eth_usd_consumer_address
    // 3. the purchaseWindow
    // 4. the tiers
    // @param _commodityPrice you need to enter it with the right decimals
    constructor(
        uint256 _purchaseWindow,
        uint256 _commodityPrice,
        address _eth_usd_consumer_address
    ) {
        started = false;

        // default values
        purchaseWindow = _purchaseWindow;
        commodityPrice = _commodityPrice;
        eth_usd_consumer_address = _eth_usd_consumer_address;
        eth_pricer = IChainlinkPriceConsumer(_eth_usd_consumer_address);

        tier_to_tierDetails[Tier.tier1] = TierDetails( // Initialize tiers
            87500 * 1e18, // 1e18 being the number of decimals of tokens. Not to be confused with sd59x18_decimals
            0,
            2 weeks,
            100 ether
        );
        tier_to_tierDetails[Tier.tier2] = TierDetails(
            75000 * 1e18,
            10,
            4 weeks, // 1 month
            100 ether
        );
        tier_to_tierDetails[Tier.tier3] = TierDetails(
            50000 * 1e18,
            20,
            12 weeks, // 3 months
            75 ether
        );
        tier_to_tierDetails[Tier.tier4] = TierDetails(
            37500 * 1e18,
            30,
            24 weeks, // 6 months
            50 ether
        );
    }

    modifier everythingSet() {
        require(purchaseWindow != 0, "purchaseWindow not set!");
        require(commodityPrice != 0, "commodityPrice not set!");
        require(
            eth_usd_consumer_address != address(0),
            "eth_usd_consumer_address not set!"
        );
        _;
    }

    modifier whenNotStarted() {
        require(started == false, "Started already!");
        _;
    }
    modifier whenStarted() {
        require(started == true, "Not started yet!");
        _;
    }

    function startPurchase() public onlyOwner whenNotStarted everythingSet {
        // once started it's impossible unstart / pause.
        startTime = block.timestamp;
        started = true;
        emit PurchaseStarted(startTime);
    }

    /**
     * ╭────────────────────────────────────────────────────────────────╮
     * │  * * * Functions to configure the params of the sale.  * * *   │
     * ╰────────────────────────────────────────────────────────────────╯
     */

    /**  @dev Function to (re)set the purchaseWindow.
     * 1 = 1 sec.
     */
    function setPurchaseWindow(
        uint256 _purchaseWindow
    ) external onlyOwner whenNotStarted {
        purchaseWindow = _purchaseWindow;
        emit NewPurchaseWindowSet(purchaseWindow);
    }

    /** @dev Function to (re)set the commodityPrice.
     * Once the sale has started you cannot change the commodity price.
     * commodityPrice must be set with 8 decimals, which is the amount of decimals
     * For the price of eth returned by the Chainlink:
     * ETH/USD Price Feed https://etherscan.io/address/0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
     */
    function setCommodityPrice(
        uint256 price
    ) external onlyOwner whenNotStarted {
        commodityPrice = price;
        emit NewCommodityPriceSet(price);
    }

    /** @dev Function to (re)set EthUsdConsumerAddress.
     */
    function setEthUsdConsumerAddress(
        address _eth_usd_consumer_address
    ) external onlyOwner whenPaused {
        require(
            _eth_usd_consumer_address != address(0),
            "Address cannot be zero"
        );
        eth_usd_consumer_address = _eth_usd_consumer_address;
        eth_pricer = IChainlinkPriceConsumer(_eth_usd_consumer_address);
        emit NewEthUsdConsumerAddressSet(_eth_usd_consumer_address);
    }

    /**  @dev Once the sale has started you cannot change the details of the tiers.
     */
    function setTierDetails(
        uint256 tier,
        uint256 sellAmount,
        uint256 discount,
        uint256 lockupTime,
        uint256 purchaseCap
    ) external onlyOwner whenNotStarted {
        Tier _tier = _t(tier);
        tier_to_tierDetails[_tier] = TierDetails(
            sellAmount,
            discount,
            lockupTime,
            purchaseCap
        );
        emit NewTierDetailsSet(
            tier,
            sellAmount,
            discount,
            lockupTime,
            purchaseCap
        );
    }

    /**
     * ╭────────────────────────────────────────────────╮
     * │  * * * Purchase & accounting functions. * * *  │
     * ╰────────────────────────────────────────────────╯
     */

    function ethPrice() public view returns (int256) {
        int256 price = eth_pricer.getLatestData();
        require(price != 0, "Stale price data");
        return price;
    }

    /** @dev Used for internal calculations.
     * Return value _discounted_price is to be unwrapped for public display.
     */
    function _discountedPrice(Tier tier) internal view returns (SD59x18) {
        uint256 d;

        if (tier == Tier.tier1) {
            d = tier_to_tierDetails[Tier.tier1].discount;
        } else if (tier == Tier.tier2) {
            d = tier_to_tierDetails[Tier.tier2].discount;
        } else if (tier == Tier.tier3) {
            d = tier_to_tierDetails[Tier.tier3].discount;
        } else if (tier == Tier.tier4) {
            d = tier_to_tierDetails[Tier.tier4].discount;
        }

        SD59x18 _commodity_price = sd(
            (int256(commodityPrice) * sd59x18_decimals)
        );
        SD59x18 _discounted = sd(int256(100 - d) * sd59x18_decimals);
        SD59x18 _discounted_price = (_commodity_price.mul(_discounted)).div(
            sd(int256(100) * sd59x18_decimals)
        );
        return _discounted_price;
    }

    function discountedPrice(uint256 tier) public view returns (uint256) {
        Tier _tier = _t(tier);
        SD59x18 _discounted_price = _discountedPrice(_tier);
        uint256 price = uint256(unwrap(_discounted_price) / sd59x18_decimals);
        return price;
    }

    /** @dev This function simply returns how much commodity
     * would have been bought by a certain amount of eth at a tier.
     * It does not pay any attention whether a tier is oversubscribed.
     */
    function _ethInCommodityOut(
        Tier tier,
        uint256 eth_in
    ) internal view returns (SD59x18) {
        SD59x18 _eth_price = sd(ethPrice() * sd59x18_decimals);
        SD59x18 _price = _discountedPrice(tier);
        SD59x18 _commodity_per_eth = _eth_price.div(_price);
        SD59x18 _eth_in = sd(int256(eth_in) * sd59x18_decimals);
        SD59x18 _commodityOut = _eth_in.mul(_commodity_per_eth);
        return _commodityOut;
    }

    function ethInCommodityOut(
        uint256 tier,
        uint256 eth_in
    ) public view returns (uint256) {
        Tier _tier = _t(tier);
        SD59x18 _commodityOut = _ethInCommodityOut(_tier, eth_in);
        uint256 commodityOut = uint256(
            unwrap(_commodityOut) / sd59x18_decimals
        );
        return commodityOut;
    }

    /** @dev Price weighted contribution - pwc - is basically the dollar amount of all the eth contributed,
     * calculated with the price of eth at the moment of contribution.
     * One will note that eth_price will return something like 200100000000,
     * which corresponds to 2001 usd (i.e. with 8 decimals).
     * The price returned by eth_price therefore corresponds to the price of 1 ether.
     * This calculation therefore introduces a 10 ** 8 decimal shift.
     * In downstream functions, when we record the pwc, we do not divide the pwc with 10 ** 8.
     * This is because when pwc is used to calculate pro_rata amounts, that 10 ** 8 is cancelled out.
     * We will therefore only remove the 10 ** 8 in the external view functions of pwc.
     */
    function _price_weighted_contribution(
        uint256 new_contribution,
        uint256 eth_price
    ) internal pure returns (SD59x18) {
        SD59x18 _new_contribution = sd(
            int256(new_contribution) * sd59x18_decimals
        );
        SD59x18 _eth_price = sd(int256(eth_price) * sd59x18_decimals);
        SD59x18 _pwc = _new_contribution.mul(_eth_price);
        return _pwc;
    }

    /** @dev This function, calculates how much someone is to have if the sale was conducted in a pro-rata manner.
     * Pro-rata in this context means the amount of commodities you will get is equal to
     * the amount of tokens on sale in a tier proportionate to the dollar cost of your
     * eth contribution (pwc) relative to the total eth contribution of that tier.
     */

    function _pro_rata_amount(
        address guy,
        Tier tier
    ) internal view returns (SD59x18 _out) {
        TierDetails memory details = tier_to_tierDetails[tier];
        uint256 amountOnSale = details.amountOnSale;
        SD59x18 _amountOnSale = sd(int256(amountOnSale) * sd59x18_decimals);
        uint256 pwc = address_to_tier_to_pwc[guy][tier];
        uint256 tier_pwc = tier_to_tierPwc[tier];
        SD59x18 _pwc = sd(int256(pwc) * sd59x18_decimals);
        SD59x18 _tier_pwc = sd(int256(tier_pwc) * sd59x18_decimals);
        _out = _amountOnSale.mul(_pwc).div(_tier_pwc);
        return _out;
    }

    /**
     * @dev This function calculates the tokens owed given an amount of
     * contribution, accounting for oversubscription.
     * This is in contrast to the _ethInCommodityOut() function,
     * which simply calculates the amount of commodity that
     * an amount of eth would buy given an eth price.
     * If a tier is not oversubscribed, he will simply get the _commodityOut amount
     * that _ethInCommodityOut outputs.
     * If a tier *is* oversubscribed, then everyone gets _pro_rata_amount(), which splits
     * the amountOnSale of a tier pro-rata in terms of eth contribution
     */
    function _amountToGet(
        address guy,
        Tier tier
    ) internal view returns (SD59x18 out) {
        // if (tier_oversubscribed[tier]) {
        //     out = _pro_rata_amount(guy, tier);
        //     return out;
        // } else {
        //     uint256 eth_in = address_to_tier_to_contribution[guy][tier];
        //     return _ethInCommodityOut(tier, eth_in);
        // }

        uint256 amountSold = tier_to_amountSold[tier];

        if (amountSold == 0) {
            return sd(int256(0));
        }

        uint256 tier_pwc = tier_to_tierPwc[tier];
        if (tier_pwc == 0) {
            return sd(int256(0));
        }

        SD59x18 _amountSold = sd(int256(amountSold) * sd59x18_decimals);
        uint256 pwc = address_to_tier_to_pwc[guy][tier];

        SD59x18 _pwc = sd(int256(pwc) * sd59x18_decimals);
        SD59x18 _tier_pwc = sd(int256(tier_pwc) * sd59x18_decimals);
        out = _amountSold.mul(_pwc).div(_tier_pwc);
        return out;
    }

    function amountToGet(
        address guy,
        uint256 tier
    ) public view returns (uint256) {
        Tier _tier = _t(tier);
        SD59x18 _commodityYouGet = _amountToGet(guy, _tier);
        uint256 commodityYouGet = uint256(
            unwrap(_commodityYouGet) / sd59x18_decimals
        );
        return commodityYouGet;
    }

    /**
     * ╭──────────────────────────────╮
     * │  * * * Buy function  * * *   │
     * ╰──────────────────────────────╯
     */
    /** @dev Function for commodity purchases. */
    function buyTokens(
        uint256 tier
    )
        external
        payable
        whenStarted
        whenNotPaused
        nonReentrant
        returns (bool success)
    {
        Tier _tier = _t(tier);

        address guy = msg.sender;
        uint256 eth_in = msg.value;
        require(eth_in > 0, "Eth deposit cannot be 0");

        uint256 purchaseCap = tier_to_tierDetails[_tier].purchaseCap;
        uint256 eth_spent = address_to_tier_to_contribution[guy][_tier];
        require(
            eth_in + eth_spent <= purchaseCap,
            "buyTokens(): over the purchaseCap!"
        );

        SD59x18 _commodityOut = _ethInCommodityOut(_tier, eth_in);
        uint256 amountOut = uint256(unwrap(_commodityOut) / sd59x18_decimals);
        uint256 amountSold = tier_to_amountSold[_tier];
        uint256 amountOnSale = tier_to_tierDetails[_tier].amountOnSale;

        require(
            block.timestamp <= purchaseWindow + startTime,
            "buyTokens(): sales over!"
        );
        // If tier is oversubscribed.
        if (amountSold + amountOut >= amountOnSale) {
            tier_to_amountSold[_tier] = amountOnSale; // set amountSold to tier limit.
            tier_oversubscribed[_tier] = true; // set tier overscription to true.
            emit Oversubscribed(tier, guy);
        } else {
            tier_to_amountSold[_tier] += amountOut; // add amountOut to amountSold.
        }
        address_to_tier_to_contribution[guy][_tier] += eth_in; // add new contribution to personal contribution account.
        tier_to_totalContribution[_tier] += eth_in; // add new contribution to tier contribution account.
        emit TierContributionUpdated(tier, eth_in);
        uint256 pwc = uint256(
            unwrap(_price_weighted_contribution(eth_in, uint256(ethPrice()))) /
                sd59x18_decimals
        ); // Calculate the pwc of the new contribution.

        address_to_tier_to_pwc[guy][_tier] += pwc; // add the new pwc of the new contribution to the personal pwc.
        tier_to_tierPwc[_tier] += pwc; // add the new pwc of the new contribution to the tier pwc.
        emit PwcUpdated(tier, pwc);
        bool didBuy = _bought(guy, tier); // update the buy details.
        emit BoughtTokens(tier, guy, eth_in);
        return didBuy;
    }

    /** @dev This function marks whether someone has bought. 
    If someone has already bought in a particular tier, it returns true. 
    If not, it pushes its address into the relevant array. 
    This kind of data is used for retainable eth and refund calculations.
     */
    function _bought(address guy, uint256 tier) internal returns (bool didBuy) {
        Tier _tier = _t(tier);
        bool _bought_already = address_to_tier_to_boughtAlready[guy][_tier];

        if (_bought_already) {
            return _bought_already;
        } else {
            if (tier == 1) {
                tier1_buyers.push(guy);
            } else if (tier == 2) {
                tier2_buyers.push(guy);
            } else if (tier == 3) {
                tier3_buyers.push(guy);
            } else if (tier == 4) {
                tier4_buyers.push(guy);
            } else {
                revert("Not valid tier");
            }
            address_to_tier_to_boughtAlready[guy][_tier] = true; // Mark guy as bought
        }
        return true; // Return true to indicate that guy has bought
    }

    /**
     * ╭─────────────────────────────────────────╮
     * │  Eth payable & refund accounting logic  │
     * ╰─────────────────────────────────────────╯
     */

    /** @dev This function calculates how much a person is to pay. It takes account of
     * whether a tier is oversubscribed.
     * If a tier is oversubscribed, then the payable amout is the amount he will get,
     * multiplied by the commodity price of that tier, divided by the average price
     * of eth of his contributions. The average price of his eth contribution is the
     * dollar cost of his eth contributions (pwc) divided his eth contributions.
     * If a tier is not oversubscribed, then he simply pays what he contributed.
     */
    function _ethPayable(
        address guy,
        Tier tier
    ) internal view returns (SD59x18) {
        SD59x18 _payableAmount;
        if (tier_oversubscribed[tier]) {
            uint256 contribution = address_to_tier_to_contribution[guy][tier];
            if (contribution == 0) {
                return sd(int256(0));
            }

            SD59x18 _commodityYouGet = _amountToGet(guy, tier);
            SD59x18 _price = _discountedPrice(tier);
            uint256 pwc = address_to_tier_to_pwc[guy][tier];

            SD59x18 _pwc = sd(int256(pwc) * sd59x18_decimals);
            SD59x18 _contribution = sd(int256(contribution) * sd59x18_decimals);
            _payableAmount = _commodityYouGet.mul(_price).div(
                _pwc.div(_contribution)
            );
        } else {
            uint256 payableAmount = address_to_tier_to_contribution[guy][tier];
            _payableAmount = sd(int256(payableAmount) * sd59x18_decimals);
        }
        return _payableAmount;
    }

    function ethPayable(
        address guy,
        uint256 tier
    ) public view returns (uint256) {
        Tier _tier = _t(tier);
        SD59x18 _payableAmount = _ethPayable(guy, _tier);
        uint256 payableAmount = uint256(
            unwrap(_payableAmount) / sd59x18_decimals
        );
        return payableAmount;
    }

    /** @dev This function calculates how much a guy is entitled to be refunded.
     * This contract will be read by the claimingCenter for refund dispersements.
     * The refund amount is basically the difference between one's contribution
     * and the ethPayable amount. Marked public because used in other functions in this contract.
     */
    function refundAmount(
        address guy,
        uint256 tier
    ) public view returns (uint256) {
        Tier _tier = _t(tier);

        uint256 contribution = address_to_tier_to_contribution[guy][_tier];
        uint256 payableAmount = ethPayable(guy, tier);
        if (contribution == 0) {
            return 0;
        } else if (contribution <= payableAmount) {
            return 0;
        } else {
            uint256 amount_to_refund = contribution - payableAmount;
            return amount_to_refund;
        }
    }

    /** @dev This calculates how much eth is refundable for a given tier
     * by lopping through its list of buyers and querying its refundAmount.
     */
    function ethRefundable(uint256 tier) public view returns (uint256) {
        uint256 totalRefund;
        _t(tier);
        uint256 _buyers = (tier == 1) ? tier1_buyers.length : (tier == 2)
            ? tier2_buyers.length
            : (tier == 3)
            ? tier3_buyers.length
            : (tier == 4)
            ? tier4_buyers.length
            : 0;
        require(_buyers != 0, "no buyers yet");
        if (tier == 1) {
            for (uint256 i = 0; i < _buyers; i++) {
                address buyer = tier1_buyers[i];
                uint256 refund = refundAmount(buyer, tier);
                totalRefund += refund;
            }
        } else if (tier == 2) {
            for (uint256 i = 0; i < _buyers; i++) {
                address buyer = tier2_buyers[i];
                uint256 refund = refundAmount(buyer, tier);

                totalRefund += refund;
            }
        } else if (tier == 3) {
            for (uint256 i = 0; i < _buyers; i++) {
                address buyer = tier3_buyers[i];
                uint256 refund = refundAmount(buyer, tier);
                totalRefund += refund;
            }
        } else if (tier == 4) {
            for (uint256 i = 0; i < _buyers; i++) {
                address buyer = tier4_buyers[i];
                uint256 refund = refundAmount(buyer, tier);
                totalRefund += refund;
            }
        }
        return totalRefund;
    }

    /** @dev This function calculates how much eth is a tier told so for
     accumulatively. Marked external because only for exteranl views.
     */
    function ethRetainable(uint256 tier) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 totalTierContribution = tier_to_totalContribution[_tier];
        uint256 totalRefund = ethRefundable(tier);
        uint256 retainable = totalTierContribution - totalRefund;
        return retainable;
    }

    /**
     * ╭──────────────────────────────────────────╮
     * │ * * * Miscellaneous view functions * * * │
     * ╰──────────────────────────────────────────╯
     */

    function salesOver() public view returns (bool) {
        if (!started) {
            return false;
        } else if (block.timestamp <= purchaseWindow + startTime) {
            return false;
        } else {
            return true;
        }
    }

    function getContributionByUserAndTier(
        address guy,
        uint256 tier
    ) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 contribution = address_to_tier_to_contribution[guy][_tier];
        return contribution;
    }

    function getTokensBoughtByUserAndTier(
        address guy,
        uint256 tier
    ) external view returns (uint256) {
        uint256 commodityYouGet = amountToGet(guy, tier);
        return commodityYouGet;
    }

    function getOversubscribed(
        uint256 tier
    ) external view returns (bool isOversubscribed) {
        Tier _tier = _t(tier);
        isOversubscribed = tier_oversubscribed[_tier];
        return isOversubscribed;
    }

    function getAmountSoldByTier(uint256 tier) external view returns (uint256) {
        Tier _tier = _t(tier);
        return tier_to_amountSold[_tier];
    }

    function getRemainingAmountByTier(
        uint256 tier
    ) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 amountSold = tier_to_amountSold[_tier];
        TierDetails memory details = tier_to_tierDetails[_tier];
        uint256 amountOnSale = details.amountOnSale;
        uint256 remaining = amountOnSale - amountSold;
        return remaining;
    }

    function getTierDetails(
        uint256 tier
    )
        external
        view
        returns (
            uint256 amountOnSale,
            uint256 discount,
            uint256 lockupTime,
            uint256 purchaseCap
        )
    {
        Tier _tier = _t(tier);
        TierDetails memory details = tier_to_tierDetails[_tier];
        return (
            details.amountOnSale,
            details.discount,
            details.lockupTime,
            details.purchaseCap
        );
    }

    function totalContribution(address guy) external view returns (uint256) {
        uint256 tier1_contribution = address_to_tier_to_contribution[guy][
            Tier.tier1
        ];
        uint256 tier2_contribution = address_to_tier_to_contribution[guy][
            Tier.tier2
        ];
        uint256 tier3_contribution = address_to_tier_to_contribution[guy][
            Tier.tier3
        ];
        uint256 tier4_contribution = address_to_tier_to_contribution[guy][
            Tier.tier4
        ];
        uint256 aggregateContribution = tier1_contribution +
            tier2_contribution +
            tier3_contribution +
            tier4_contribution;
        return aggregateContribution;
    }

    function getPwcByUserAndTier(
        address guy,
        uint256 tier
    ) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 pwc = address_to_tier_to_pwc[guy][_tier] / 10 ** 8;
        return pwc;
    }

    function getTierPwc(uint256 tier) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 tierPwc = tier_to_tierPwc[_tier] / 10 ** 8;
        return tierPwc;
    }

    /** @dev
     * This function returns the total amount a person bought at a given time.
     */
    function totalAmountBought(address guy) external view returns (uint256) {
        uint256 tier1_amount = amountToGet(guy, 1);
        uint256 tier2_amount = amountToGet(guy, 2);
        uint256 tier3_amount = amountToGet(guy, 3);
        uint256 tier4_amount = amountToGet(guy, 4);
        uint256 amount = tier1_amount +
            tier2_amount +
            tier3_amount +
            tier4_amount;
        return amount;
    }

    function tierContribution(uint tier) external view returns (uint256) {
        Tier _tier = _t(tier);
        uint256 amount = tier_to_totalContribution[_tier];
        return amount;
    }

    function everythingIsSet() external view returns (bool) {
        if (
            commodityPrice != 0 &&
            purchaseWindow != 0 &&
            eth_usd_consumer_address != address(0)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function getBoughtAlreadyByUserAndTier(
        address guy,
        uint256 tier
    ) external view returns (bool) {
        Tier _tier = _t(tier);
        bool boughtAlready = address_to_tier_to_boughtAlready[guy][_tier];
        return boughtAlready;
    }

    function buyers(
        uint256 tier
    ) external view returns (address[] memory buyersArray) {
        if (tier == 1) {
            return tier1_buyers;
        } else if (tier == 2) {
            return tier2_buyers;
        } else if (tier == 3) {
            return tier3_buyers;
        } else if (tier == 4) {
            return tier4_buyers;
        } else {
            revert("Not valid tier");
        }
    }

    /**
     * ╭───────────────────────────────────────────────────╮
     * │ * * * Eth deposit and withdrawal functions. * * * │
     * ╰───────────────────────────────────────────────────╯
     */

    function withdrawEth(
        address to
    ) external nonReentrant onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(to).call{value: balance}("");
        require(success, "Eth not withdrawn!");
        emit EthWithdrawn(to, balance);
        return success;
    }

    // Helper function to check the balance of this contract
    function ethBalance() public view returns (uint256 balance) {
        balance = address(this).balance;
        return balance;
    }

    // Fallback function must be declared as external.
    fallback() external payable {
        emit Log("receive", gasleft());
    }

    // Receive is a variant of fallback that is triggered when msg.data is empty.
    receive() external payable {
        emit Log("receive", gasleft());
    }
}