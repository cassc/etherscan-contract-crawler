//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./components/WhitelistedAddresses.sol";
import "./components/IsPausable.sol";
import "./interfaces/IOuterRingNFT.sol";

//============== DIRECT BUY / SELL ==============

/// @title Direct Buy/Sell Smart Contract
/// @author eludius18lab
/// @notice Direct Buy/Sell --> MarketPlace
/// @dev This Contract will be used to Buy/Sell NFTs with fixed Price
contract BuySell is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    WhitelistedAddresses,
    IsPausable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //============== STRUCTS ==============

    struct Sales {
        uint256 buyPrice;
        address nftSeller;
        address ERC20Token;
        address feeRecipient;
        uint32 feePercentage;
    }

    //============== MAPPINGS ==============

    mapping(address => mapping(uint256 => Sales)) public nftContractSales;

    //============== VARIABLES ==============

    uint32 public defaultFeePercentages;
    address public defaultFeeRecipient;
    uint32 public firstOwnerFeePercentage;
    bool public initialized;

    //============== ERRORS ==============

    error NotNFTOwner();

    //============== CONSTRUCTOR ==============

    constructor() {
        _disableInitializers();
    }

    //============== INITIALIZE ==============

    function initialize(
        uint32 defaultFeePercentages_,
        address defaultFeeRecipient_,
        uint32 firstOwnerFeePercentage_
    )
        external
        initializer
        isPercentageInBounds(defaultFeePercentages_)
        isPercentageInBounds(firstOwnerFeePercentage_)
    {
        require(
            defaultFeeRecipient_ != address(0),
            "fee recipient must be != address(0)"
        );
        require(
            defaultFeePercentages_ + firstOwnerFeePercentage_ <= 10000,
            "Error: incorrect amount"
        );
        defaultFeePercentages = defaultFeePercentages_;
        defaultFeeRecipient = defaultFeeRecipient_;
        firstOwnerFeePercentage = firstOwnerFeePercentage_;
        __Ownable_init();
        __WhitelistedAddresses_init();
        __IsPausable_init();
        initialized = true;
    }

    //============== EVENTS ==============

    event SaleCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint256 buyPrice
    );

    event BuyPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newBuyPrice
    );

    event TokenBought(
        address nftContractAddress,
        uint256 tokenId,
        uint256 buyPrice,
        address erc20Token,
        address nftSeller,
        address nftBuyer,
        address nftRecipient
    );

    event SaleWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event ChangedDefaultFeePercentages(uint32 newFee);
    event ChangedDefaultFeeRecipient(address newFee);
    event ChangedFirstOwnerFeePercentage(uint32 newFee);
    event NFTRecovered(address nftContractAddress, uint256 tokenId);

    //============== MODIFIERS ==============

    modifier isPercentageInBounds(uint256 percentage) {
        require(
            percentage >= 0 && percentage <= 10000,
            "Error: incorrect percentage"
        );
        _;
    }

    modifier isInitialized() {
        require(initialized, "Error: contract not initialized");
        _;
    }

    modifier saleNotStarted(address nftContractAddress, uint256 tokenId) {
        require(
            nftContractSales[nftContractAddress][tokenId].nftSeller ==
                address(0),
            "Sale already started"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 price) {
        require(price > 0, "Price cannot be 0");
        _;
    }

    modifier notNftSeller(address nftContractAddress, uint256 tokenId) {
        require(
            msg.sender !=
                nftContractSales[nftContractAddress][tokenId].nftSeller,
            "Owner cannot buy on own NFT"
        );
        _;
    }
    modifier onlyNftSeller(address nftContractAddress, uint256 tokenId) {
        require(
            msg.sender ==
                nftContractSales[nftContractAddress][tokenId].nftSeller,
            "Only nft seller"
        );
        _;
    }

    modifier isNFTOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        if (spender != IERC721Upgradeable(nftAddress).ownerOf(tokenId)) {
            revert NotNFTOwner();
        }
        _;
    }

    modifier outerRingNFTHasFirstOwner(address nftAddress, uint256 tokenId) {
        if (outerRingNFTs[nftAddress]) {
            require(
                IOuterRingNFT(nftAddress).getFirstOwner(tokenId) != address(0),
                "first owner must be != 0"
            );
        }
        _;
    }

    //============== EXTERNAL FUNCTIONS ==============

    /// Creates a new sale
    /// @param nftContractAddress Contract address that will be put on sale
    /// @param tokenId Identifier of the NFT
    /// @param erc20Token Token used to pay
    /// @param buyPrice NFT price
    function createSale(
        address nftContractAddress,
        uint256 tokenId,
        address erc20Token,
        uint256 buyPrice
    )
        external
        nonReentrant
        isInitialized
        saleNotStarted(nftContractAddress, tokenId)
        priceGreaterThanZero(buyPrice)
        isNFTOwner(nftContractAddress, tokenId, msg.sender)
        whenNotPaused
        isWhitelistedToken(erc20Token)
        isWhitelistedNFT(nftContractAddress)
        outerRingNFTHasFirstOwner(nftContractAddress, tokenId)
    {
        _setupSale(nftContractAddress, tokenId, erc20Token, buyPrice);
        _transferNftToSaleContract(nftContractAddress, tokenId, msg.sender);

        emit SaleCreated(
            nftContractAddress,
            tokenId,
            msg.sender,
            erc20Token,
            buyPrice
        );
    }

    /// Updates the price of a sale
    /// @dev Price must be grater than 0
    /// @param nftContractAddress Contract address NFT on sale
    /// @param tokenId Identifier of the NFT
    /// @param newBuyPrice NFT The new price
    function updateBuyPrice(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newBuyPrice
    )
        external
        nonReentrant
        whenNotPaused
        onlyNftSeller(nftContractAddress, tokenId)
        priceGreaterThanZero(newBuyPrice)
    {
        nftContractSales[nftContractAddress][tokenId].buyPrice = newBuyPrice;
        emit BuyPriceUpdated(nftContractAddress, tokenId, newBuyPrice);
    }

    /// Buy NFT with ERC20 tokens
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    /// @param nftRecipient Recipient where the transfer will be sended
    function buyWithTokens(
        address nftContractAddress,
        uint256 tokenId,
        address nftRecipient
    ) external nonReentrant {
        require(
            nftContractSales[nftContractAddress][tokenId].buyPrice > 0,
            "BuyPrice Should be higher to 0"
        );
        require(
            nftContractSales[nftContractAddress][tokenId].ERC20Token !=
                address(0),
            "Only ERC20 Payment"
        );
        _payAndTransferNFT(nftContractAddress, tokenId, nftRecipient);
    }

    /// Buy NFT with BNB
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    /// @param nftRecipient Recipient where the transfer will be sended
    function buyWithBNB(
        address nftContractAddress,
        uint256 tokenId,
        address nftRecipient
    ) external payable nonReentrant {
        uint256 _buyPrice = nftContractSales[nftContractAddress][tokenId]
            .buyPrice;
        require(
            _buyPrice > 0 && msg.value == _buyPrice,
            "Incorrect value sent"
        );
        require(
            nftContractSales[nftContractAddress][tokenId].ERC20Token ==
                address(0),
            "Only BNB Payment"
        );
        _payAndTransferNFT(nftContractAddress, tokenId, nftRecipient);
    }

    /// Buy NFT with BNB
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    function withdrawSale(address nftContractAddress, uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyNftSeller(nftContractAddress, tokenId)
    {
        _transferNftToSeller(nftContractAddress, tokenId);
        emit SaleWithdrawn(nftContractAddress, tokenId, msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /// Change the default fee percentage
    /// @param newDefaultFeePercentages New fee percentage
    function changeDefaultFeePercentages(uint32 newDefaultFeePercentages)
        external
        onlyOwner
        isPercentageInBounds(newDefaultFeePercentages)
    {
        require(
            newDefaultFeePercentages + firstOwnerFeePercentage <= 10000,
            "Error: incorrect amount"
        );
        defaultFeePercentages = newDefaultFeePercentages;
        emit ChangedDefaultFeePercentages(defaultFeePercentages);
    }

    /// Change the default fee recipient
    /// @param newDefaultFeeRecipient New address for recipient
    function changeDefaultFeeRecipient(address newDefaultFeeRecipient)
        external
        onlyOwner
    {
        require(
            newDefaultFeeRecipient != address(0),
            "fee recipient must be != address(0)"
        );
        defaultFeeRecipient = newDefaultFeeRecipient;
        emit ChangedDefaultFeeRecipient(defaultFeeRecipient);
    }

    /// Change the first owner fee
    /// @param newFirstOwnerFeePercentage New fee percentage for first owner
    function changeFirstOwnerFeePercentage(uint32 newFirstOwnerFeePercentage)
        external
        onlyOwner
        isPercentageInBounds(newFirstOwnerFeePercentage)
    {
        require(
            newFirstOwnerFeePercentage + defaultFeePercentages <= 10000,
            "Error: incorrect amount"
        );
        firstOwnerFeePercentage = newFirstOwnerFeePercentage;
        emit ChangedFirstOwnerFeePercentage(firstOwnerFeePercentage);
    }

    /// Function used for recovery NFTs
    /// @param nftContractAddress The address of the NFT to recover
    /// @param recipient The recipient to receive the NFT
    /// @param tokenId The tokenId of the NFT
    function recoveryNFT(
        address nftContractAddress,
        address recipient,
        uint256 tokenId
    ) external onlyOwner {
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            recipient,
            tokenId
        );
        emit NFTRecovered(nftContractAddress, tokenId);
    }

    //============== INTERNAL FUNCTIONS ==============

    /// Makes payment of the NFT and transfer to the purchaser.
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    /// @param nftRecipient Recipient where the transfer will be sended
    function _payAndTransferNFT(
        address nftContractAddress,
        uint256 tokenId,
        address nftRecipient
    ) internal whenNotPaused notNftSeller(nftContractAddress, tokenId) {
        Sales memory nftContractSale = nftContractSales[nftContractAddress][
            tokenId
        ];

        _resetSale(nftContractAddress, tokenId);
        _payFeesAndSeller(
            nftContractAddress,
            tokenId,
            nftContractSale.nftSeller,
            nftContractSale.buyPrice,
            nftContractSale.ERC20Token
        );
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            nftRecipient,
            tokenId
        );
        emit TokenBought(
            nftContractAddress,
            tokenId,
            nftContractSale.buyPrice,
            nftContractSale.ERC20Token,
            nftContractSale.nftSeller,
            msg.sender,
            nftRecipient
        );
    }

    /// Transfer NFT to the seller in case of withdraw sale
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    function _transferNftToSeller(address nftContractAddress, uint256 tokenId)
        internal
    {
        address nftSeller = nftContractSales[nftContractAddress][tokenId]
            .nftSeller;
        _resetSale(nftContractAddress, tokenId);
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            nftSeller,
            tokenId
        );
    }

    /// Makes payment of the NFT fees
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    /// @param nftSeller Seller of the NFT who receives the fee
    /// @param buyPrice NFT purchase price
    function _payFeesAndSeller(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 buyPrice,
        address erc20Token
    ) internal {
        uint256 fee = _getPortionOfPush(buyPrice, defaultFeePercentages);
        uint256 firstOwnerFee;
        if (outerRingNFTs[nftContractAddress]) {
            firstOwnerFee = _getPortionOfPush(
                buyPrice,
                firstOwnerFeePercentage
            );
            _payout(
                IOuterRingNFT(nftContractAddress).getFirstOwner(tokenId),
                firstOwnerFee,
                erc20Token
            );
        }
        _payout(defaultFeeRecipient, fee, erc20Token);
        _payout(
            nftSeller,
            buyPrice - fee - firstOwnerFee,
            erc20Token
        );
    }

    /// Makes the transfer of the tokens ERC20 or BNB
    /// @param recipient Address that receives tokens
    /// @param amountPaid Amount to transfer
    function _payout(
        address recipient,
        uint256 amountPaid,
        address saleERC20Token
    ) internal {
        if (saleERC20Token != address(0)) {
            IERC20Upgradeable(saleERC20Token).safeTransferFrom(
                msg.sender,
                address(this),
                amountPaid
            );
            IERC20Upgradeable(saleERC20Token).safeTransfer(
                recipient,
                amountPaid
            );
        } else {
            (bool success, ) = payable(recipient).call{value: amountPaid}("");
            require(success, "error sending BNB");
        }
    }

    /// Deposit NFT in the contract
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    /// @param nftSeller Seller of the NFT who sends the NFT to contract
    function _transferNftToSaleContract(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller
    ) internal {
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            nftSeller,
            address(this),
            tokenId
        );
    }

    /// Reset the sale info for this NFT
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    function _resetSale(address nftContractAddress, uint256 tokenId) internal {
        nftContractSales[nftContractAddress][tokenId].buyPrice = 0;
        nftContractSales[nftContractAddress][tokenId].nftSeller = address(0);
        nftContractSales[nftContractAddress][tokenId].ERC20Token = address(0);
        nftContractSales[nftContractAddress][tokenId].feePercentage = 0;
        nftContractSales[nftContractAddress][tokenId].feeRecipient = address(0);
    }

    /// Setup a new sale
    /// @param nftContractAddress Contract address that will be put on sale
    /// @param tokenId Identifier of the NFT
    /// @param erc20Token Token used to pay
    /// @param buyPrice NFT price
    function _setupSale(
        address nftContractAddress,
        uint256 tokenId,
        address erc20Token,
        uint256 buyPrice
    ) internal {
        nftContractSales[nftContractAddress][tokenId]
            .feePercentage = defaultFeePercentages;
        nftContractSales[nftContractAddress][tokenId]
            .feeRecipient = defaultFeeRecipient;
        nftContractSales[nftContractAddress][tokenId].ERC20Token = erc20Token;
        nftContractSales[nftContractAddress][tokenId].buyPrice = buyPrice;
        nftContractSales[nftContractAddress][tokenId].nftSeller = msg.sender;
    }

    /// Calculates a precentage of the amount to paid
    /// @param amountPaid The amount used to calculate the percentage
    /// @param percentage Percentage to extract to the amount
    function _getPortionOfPush(uint256 amountPaid, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (amountPaid * (percentage)) / 10000;
    }
}