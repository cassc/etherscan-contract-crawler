// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ILevelsArtERC721} from "./ILevelsArtERC721.sol";

/*\      $$$$$$$$\ $$\    $$\ $$$$$$$$\ $$\      $$$$$$\                        $$\     
$$ |     $$  _____|$$ |   $$ |$$  _____|$$ |    $$  __$$\                       $$ |    
$$ |     $$ |      $$ |   $$ |$$ |      $$ |    $$ /  \__|   $$$$$$\   $$$$$$\$$$$$$\   
$$ |     $$$$$\    \$$\  $$  |$$$$$\    $$ |    \$$$$$$\     \____$$\ $$  __$$\_$$  _|  
$$ |     $$  __|    \$$\$$  / $$  __|   $$ |     \____$$\    $$$$$$$ |$$ |  \__|$$ |    
$$ |     $$ |        \$$$  /  $$ |      $$ |    $$\   $$ |  $$  __$$ |$$ |      $$ |$$\ 
$$$$$$$$\$$$$$$$$\    \$  /   $$$$$$$$\ $$$$$$$$\$$$$$$  |$$\$$$$$$$ |$$ |      \$$$$  |
\________\________|    \_/    \________|\________\______/ \__\_______|\__|       \___*/

contract LevelsArtSaleManager is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /*
        Events
    */

    // Event fired when a purchase is made
    event Purchase(address nft, uint256 qty);
    // Event fired when a sale is created
    event SaleCreated(
        string saleType,
        address nft,
        uint64 startTime,
        uint64 lowestPriceTime,
        uint64 endTime,
        uint256[] prices,
        uint256 editions,
        uint256 maxPurchaseQuantity,
        address payee
    );
    // Event fired when a sale is updated
    event SaleUpdated(
        uint32 index,
        string saleType,
        address nft,
        uint64 startTime,
        uint64 lowestPriceTime,
        uint64 endTime,
        uint256[] prices,
        uint256 editions,
        uint256 maxPurchaseQuantity,
        address payee
    );

    /*
        Data Types
    */

    enum SaleType {
        FLAT, // Flat sale. Like "buy at this price"
        DUTCH // Dutch auction. Decreases over time.
    }

    struct Sale {
        SaleType saleType;           // Type of sale, can be DUTCH or FLAT
        address nft;                 // The address of the NFT on sale
        uint32 index;                // Each NFT has a list of sales, this is its index
        uint64 startTime;            // The start time of the sale
        uint64 lowestPriceTime;      // If it's a dutch option, it's the time of lowest price
        uint64 endTime;              // (optional) End time of the sale
        uint256[] prices;            // Prices to iterate through for dutch, single index for flat
        uint256 editions;            // Number of editions for sale
        uint256 maxPurchaseQuantity; // Max each wallet can purchase
        address payable payee;       // Address that payment goes to
        uint256 sold;                // Count of how many have sold
        bool paused;                 // Whether the sale is paused or not
    }

    struct ComplimentaryMint {
        address account; // Account that gets a complimentary mint
        uint32 amount;   // Amount that the account gets
    }

    /*
        Storage
    */

    // Keccack of FLAT and DUTCH for comparisons in the create functions
    bytes32 private constant FLAT_256 = keccak256(bytes("FLAT"));
    bytes32 private constant DUTCH_256 = keccak256(bytes("DUTCH"));

    // List of nfts and their sales
    mapping(address nft => Sale[] saleList) private _salesByNft;
    // Mapping to figure out how many purchases a user has made in each sale
    mapping(address nft => mapping(uint32 index => mapping(address account => uint256)))
        private _userPurchasesBySaleByNft;
    // List of nft addreses with sales
    address[] private _nftsWithSales;

    /*
        Constructor
    */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public virtual initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    /**
     * @notice Creates a new sale
     *
     * @param saleType_ Used to determine the saleType. Can be 'FLAT' or
     * 'DUTCH'
     * @param nft_ Address of the NFT on sale
     * @param startTime_ The start time of the sale
     * @param lowestPriceTime_ For dutch auctions, the time that the lowest
     * price will be reached. 0 otherwise
     * @param endTime_ The end time of the sale. If no end, set to 0
     * @param prices_ Tiered prices equally spaced between startTime and
     * lowestPriceTime. Should be ordered from highest to lowest. If it's a
     * FLAT sale then there should only be one value in this array.
     * @param editions_ Number of editions being sold in the sale.
     * @param maxPurchaseQuantity_ Maximum number of editions each individual
     * wallet can purchase
     * @param payee_ The address that gets paid for the sale
     */
    function createSale(
        string calldata saleType_,
        address nft_,
        uint64 startTime_,
        uint64 lowestPriceTime_,
        uint64 endTime_,
        uint256[] calldata prices_,
        uint256 editions_,
        uint256 maxPurchaseQuantity_,
        address payable payee_
    ) public onlyOwner {
            // Check that the values are all valid and get some derived values
            (Sale[] storage salesForNft, SaleType saleType) = _checkSaleValues(
                saleType_,
                nft_,
                startTime_,
                lowestPriceTime_,
                endTime_,
                prices_,
                editions_,
                payee_
            );

            // The index of the new sale in the array
            uint32 index = uint32(salesForNft.length);

            // Check to make sure that Sales are added in chronological order
            // and that no two sales can happen at the same time
            _checkSurroundingSaleValues(salesForNft, index, startTime_, endTime_);

            // Add sale to the list of sales for the NFT
            salesForNft.push(
                Sale(
                    saleType,
                    nft_,
                    index,
                    startTime_,
                    lowestPriceTime_,
                    endTime_,
                    prices_,
                    editions_,
                    maxPurchaseQuantity_,
                    payee_,
                    0,
                    false
                )
            );

        emit SaleCreated(
            saleType_,
            nft_,
            startTime_,
            lowestPriceTime_,
            endTime_,
            prices_,
            editions_,
            maxPurchaseQuantity_,
            payee_
        );
    }

    /**
     * @notice Send the complimentary mints for a sale to the respective accounts
     *
     * @param nft_ Address of the NFT on sale
     * @param index_ The index in the NFT's sales array that this sale is
     * @param complimentaryMints_ The list of accounts to mint complimentary NFTs to
     */
    function mintComplimentary(
        address nft_,
        uint32 index_,
        ComplimentaryMint[] calldata complimentaryMints_
    ) public onlyOwner {
        Sale storage sale = _salesByNft[nft_][index_];

        require(sale.nft != address(0), "Sale does not exist");
        require(
            block.timestamp < sale.startTime,
            "Cannot complimentary mint after sale has started"
        );

        for (uint256 i = 0; i < complimentaryMints_.length;) {
            uint256 amount = complimentaryMints_[i].amount;
            address account = complimentaryMints_[i].account;
            sale.sold += amount;
            ILevelsArtERC721(nft_).mint(account, amount);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Updates the values of an existing sale
     *
     * @param index_ The index in the NFT's sales array that this sale is
     * @param saleType_ Used to determine the saleType. Can be 'FLAT' or
     * 'DUTCH'
     * @param nft_ Address of the NFT on sale
     * @param startTime_ The start time of the sale
     * @param lowestPriceTime_ For dutch auctions, the time that the lowest
     * price will be reached. 0 otherwise
     * @param endTime_ The end time of the sale. If no end, set to 0
     * @param prices_ Tiered prices equally spaced between startTime and
     * lowestPriceTime. Should be ordered from highest to lowest. If it's a
     * FLAT sale then there should only be one value in this array.
     * @param editions_ Number of editions being sold in the sale.
     * @param maxPurchaseQuantity_ Maximum number of editions each individual
     * wallet acn purchase
     * @param payee_ The address that gets paid for the sale
     */
    function updateSale(
        uint32 index_,
        string calldata saleType_,
        address nft_,
        uint64 startTime_,
        uint64 lowestPriceTime_,
        uint64 endTime_,
        uint256[] calldata prices_,
        uint256 editions_,
        uint256 maxPurchaseQuantity_,
        address payable payee_
    ) public onlyOwner {
        // Validate that all of the new values are coo
        (Sale[] storage salesForNft, SaleType saleType) = _checkSaleValues(
            saleType_,
            nft_,
            startTime_,
            lowestPriceTime_,
            endTime_,
            prices_,
            editions_,
            payee_
        );

        require(salesForNft[index_].nft != address(0), "Sale does not exist");

        // Check to make sure that Sales are added in chronological order
        // and that no two sales can happen at the same time
        _checkSurroundingSaleValues(salesForNft, index_, startTime_, endTime_);

        Sale storage update = salesForNft[index_];

        // Make sure that we're not setting the max number of available
        // editions in the sale to a number less than what's already sold
        require(editions_ >= update.sold, "Already sold more than new value");

        // Do all of the updates
        update.saleType = saleType;
        update.startTime = startTime_;
        update.lowestPriceTime = lowestPriceTime_;
        update.endTime = endTime_;
        update.prices = prices_;
        update.editions = editions_;
        update.maxPurchaseQuantity = maxPurchaseQuantity_;
        update.payee = payee_;

        emit SaleUpdated(
            index_,
            saleType_,
            nft_,
            startTime_,
            lowestPriceTime_,
            endTime_,
            prices_,
            editions_,
            maxPurchaseQuantity_,
            payee_
        );
    }

    /**
     * @notice Does all of the validity checks for the values passed when
     * creating or updating a Sale
     *
     * @param saleType_ Used to determine the saleType.
     * Can be 'FLAT' or 'DUTCH'
     * @param nft_ Address of the NFT on sale
     * @param startTime_ The start time of the sale
     * @param lowestPriceTime_ For dutch auctions, the time that the lowest
     * price will be reached. 0 otherwise
     * @param endTime_ The end time of the sale. If no end, set to 0
     * @param prices_ Tiered prices equally spaced between startTime and
     * lowestPriceTime. Should be ordered from highest to
     * lowest. If it's a FLAT sale then there should only
     * be one value in this array.
     * @param editions_ Number of editions being sold in the sale.
     * @param payee_ The address that gets paid for the sale
     * @return salesForNft The Sale in storage that's being checked
     * @return saleType the enum value that _saleType maps to
     */
    function _checkSaleValues(
        string calldata saleType_,
        address nft_,
        uint64 startTime_,
        uint64 lowestPriceTime_,
        uint64 endTime_,
        uint256[] calldata prices_,
        uint256 editions_,
        address payee_
    ) internal view returns (Sale[] storage salesForNft, SaleType saleType) {
        // Revert is NFT is empty or zero
        require(nft_ != address(0), "Cannot create sale for zero address");
        // Revert if endTime exists and is less than start Time
        require(endTime_ > startTime_ || endTime_ == 0, "Invalid end time");
        // Revery if the sale won't sell anything (lol editions for sale == 0)
        require(editions_ != 0, "Cannot sell zero editions");

        // So we can check the value against FLAT_256 and DUTCH_256
        bytes32 saleType256 = keccak256(bytes(saleType_));

        // Verifies that the sale type is valid (FLAT || DUTCH)  and then runs
        // the checks for that type
        if (saleType256 == FLAT_256) {
            //   - Revert if there are more than 1 price given
            require(prices_.length == 1, "Invalid prices for flat sale");
            //   - Revert if there is lowestPriceTime
            //     (only applicable to dutch auctions)
            require(lowestPriceTime_ == 0, "Invalid lowest price time");
        } else if (saleType256 == DUTCH_256) {
            //   - Revert if there are less than 2 tiers in sale
            require(prices_.length >= 2, "Invalid price for flat sale");
            //   - Revert if the lowestPriceTime is before startTime
            require(lowestPriceTime_ > startTime_, "Invalid lowest price time");
        } else {
            // If the saleType doesn't match one of the two allowed, revert
            revert("Invalid sale type");
        }

        // Checks that the payee isn't the zero address
        require(payee_ != address(0), "Payee cannot be zero");

        // Get the sales created for the individual NFT
        salesForNft = _salesByNft[nft_];
        // Set the saleType
        saleType = saleType256 == FLAT_256 ? SaleType.FLAT : SaleType.DUTCH;
    }

    /**
     * @notice Check to make sure that Sales are added in chronological order
     * and that no two sales can happen at the same time
     *
     * @param salesForNft_ The list of sales that an NFT has
     * @param index_ The index that the currently referenced sale is in the
     * _salesForNft array
     * @param startTime_ The start time one the currently referenced sale
     * @param endTime_ The end time one the currently referenced sale
     */
    function _checkSurroundingSaleValues(
        Sale[] memory salesForNft_,
        uint32 index_,
        uint64 startTime_,
        uint64 endTime_
    ) internal pure {
        if (salesForNft_.length == 0) return;

        if (index_ > 0) {
            uint64 prevEnd = salesForNft_[index_ - 1].endTime;
            require(
                prevEnd != 0 && startTime_ >= prevEnd,
                "Cannot have two sales at once"
            );
        }

        if (index_ + 1 < salesForNft_.length - 1) {
            uint64 nextStart = salesForNft_[index_ + 1].startTime;
            require(
                endTime_ < nextStart && endTime_ != 0,
                "Cannot have two sales at once"
            );
        }
    }

    /**
     * @notice Purchase an NFT from a sale
     *
     * @param nft_ Address of the NFT on sale
     * @param index_ The index that the currently referenced sale is in the
     * _salesForNft array
     * @param qty_ The number the account is trying to purchase
     */
    function purchase(
        address nft_,
        uint32 index_,
        uint256 qty_
    ) public payable nonReentrant isNotPaused(nft_, index_) {
        // Get the sale for NFT at x index
        Sale storage sale = _salesByNft[nft_][index_];

        // Run all of the checks to make sure that the sale can happen
        _handlePurchaseVerification(sale, qty_);

        // Handle the payment for the sale
        _handlePurchasePayment(sale, qty_);

        // Increment the sold quantities
        sale.sold += qty_;
        _userPurchasesBySaleByNft[nft_][index_][msg.sender] += qty_;

        // Mint the NFT
        ILevelsArtERC721(nft_).mint(msg.sender, qty_);

        // Emit event
        emit Purchase(nft_, qty_);
    }

    /**
     * @notice Verify that the purchase is eligible to go through
     *
     * @param sale_ The sale to get the price from
     * @param qty_ The number of editions being sold
     */
    function _handlePurchaseVerification(
        Sale memory sale_,
        uint256 qty_
    ) internal view {
        // For some readability
        (uint64 startTime, uint64 endTime) = (sale_.startTime, sale_.endTime);

        // If it's currently before the start time, the sale hasn't started
        require(block.timestamp >= startTime, "Sale has not started");
        // If there's an endTime and it's past the end time, the sale has ended
        require(endTime == 0 || block.timestamp < endTime, "Sale has ended");
        // If the address is 0, then the sale does not exist
        require(sale_.nft != address(0), "Sale does not exist");
        // If this sale would go over the max limit
        require(
            sale_.sold + qty_ <= sale_.editions,
            "Would exceed max editions"
        );

        // Grab the number of previouses purchases that the user has made
        uint256 purchased = _userPurchasesBySaleByNft[sale_.nft][sale_.index][
            msg.sender
        ];

        // If the sale has a max purchase limit and this sale would drive the
        // account over that limit
        require(
            sale_.maxPurchaseQuantity == 0 ||
                purchased + qty_ <= sale_.maxPurchaseQuantity,
            "Would exceed purchase limit"
        );
    }

    /**
     * @notice Helper function to abstract payment for a sale
     *
     * @param sale_ The sale to get the price from
     * @param qty_ The number of editions being sold
     */
    function _handlePurchasePayment(Sale memory sale_, uint256 qty_) internal {
        // Get the price that the user must pay
        uint256 price = _getSalePrice(sale_) * qty_;

        // If the account sent too little ETH
        require(msg.value >= price, "Insufficient ether");

        // If the account sent too much, let's refund them
        uint256 refund = msg.value - price;
        if (refund > 0) {
            (bool refunded, ) = payable(msg.sender).call{value: refund}("");
            require(refunded, "Refund failed");
        }

        // Pay the payee wallet
        (bool success, ) = sale_.payee.call{value: price}("");
        require(success, "Payment failed");
    }

    /**
     * @notice Pauses a sale
     *
     * @param nft_ Address of the NFT on sale
     * @param index_ The index that the currently referenced sale is in the
     * _salesForNft array
     */
    function pauseSale(address nft_, uint32 index_) public onlyOwner {
        Sale storage sale = _salesByNft[nft_][index_];
        require(sale.nft != address(0), "Sale does not exist");
        sale.paused = true;
    }

    /**
     * @notice Unpauses a sale
     *
     * @param nft_ Address of the NFT on sale
     * @param index_ The index that the currently referenced sale is in the
     * _salesForNft array
     */
    function unpauseSale(address nft_, uint32 index_) public onlyOwner {
        Sale storage sale = _salesByNft[nft_][index_];
        require(sale.nft != address(0), "Sale does not exist");
        sale.paused = false;
    }

    /**
     * @notice Gets the current price of a sale
     *
     * @param sale The Sale we're getting the price for.
     */
    function _getSalePrice(Sale memory sale) internal view returns (uint256) {
        uint256[] memory prices = sale.prices;
        uint64 startTime = sale.startTime;
        uint64 lowestPriceTime = sale.lowestPriceTime;

        // If the sale is a FLAT sale, return the only price in the array
        if (prices.length == 1) {
            return prices[0];
        }

        // If the sale is a DUTCH sale, calculate which tier the current
        // timestap falls into and return that price
        uint256 maxIndex = prices.length - 1;
        uint256 range = lowestPriceTime - startTime;
        uint256 timeInEachTier = range / maxIndex;
        uint256 timeSinceStart = block.timestamp - startTime;
        uint256 tier = timeSinceStart / timeInEachTier;
        tier = tier > maxIndex ? maxIndex : tier;

        return prices[tier];
    }

    /**
     * @notice Returns the address of every NFT that there is a sale for
     */
    function getNftsWithSales() public view returns (address[] memory) {
        return _nftsWithSales;
    }

    /**
     * @notice Returns the sales for a specific NFT
     * @param nft_ The address of the NFT
     */
    function getSalesForNft(
        address nft_
    ) public view returns (Sale[] memory sales) {
        sales = _salesByNft[nft_];
    }

    /**
     * @notice Returns a specific sale for a specific NFT
     * @param nft_ The address of the NFT
     * @param index_ The index of the sale in the NFT's sale array
     */
    function getSale(
        address nft_,
        uint32 index_
    ) public view returns (Sale memory sale) {
        sale = _salesByNft[nft_][index_];
    }

    /**
     * @notice Returns a the number of editions sold for an NFT in a sale
     * @param nft_ The address of the NFT
     * @param index_ The index of the sale in the NFT's sale array
     */
    function getSoldInSale(
        address nft_,
        uint32 index_
    ) public view returns (uint256 sold) {
        sold = _salesByNft[nft_][index_].sold;
    }

    /**
     * @notice Returns a the the number of purchases a specific account has
     * made in a sale
     * @param nft_ The address of the NFT
     * @param index_ The index of the sale in the NFT's sale array
     */
    function getWalletPurchasesForSale(
        address nft_,
        uint32 index_,
        address account
    ) public view returns (uint256 purchases) {
        purchases = _userPurchasesBySaleByNft[nft_][index_][account];
    }

    /**
     * @notice Returns every sale that's been listed in this contract
     */
    function getAllSales() public view returns (Sale[] memory) {
        uint256 count = _getSalesCount();
        uint256 iterator = 0;
        Sale[] memory sales = new Sale[](count);

        for (uint i = 0; i < _nftsWithSales.length; i++) {
            address nft = _nftsWithSales[i];
            for (uint j = 0; j < _salesByNft[nft].length; j++) {
                sales[iterator++] = _salesByNft[nft][j];
            }
        }

        return sales;
    }

    /**
     * @notice Helper function that returns the number of sales that have been listed
     */
    function _getSalesCount() internal view returns (uint256 count) {
        count = 0;
        for (uint i = 0; i < _nftsWithSales.length; i++) {
            address nft = _nftsWithSales[i];
            for (uint j = 0; j < _salesByNft[nft].length; j++) {
                count++;
            }
        }
    }

    /**
     * @notice Modifier for checking whether a sale is paused before purchases
     */
    modifier isNotPaused(address nft_, uint32 index_) {
        require(!_salesByNft[nft_][index_].paused, "Sale is paused");
        _;
    }
}