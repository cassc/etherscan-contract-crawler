//  $$$$$$$$\ $$$$$$$$\  $$$$$$\  $$\      $$\       $$$$$$$$\  $$$$$$\  $$\   $$\ $$$$$$$$\ $$\   $$\
//  \__$$  __|$$  _____|$$  __$$\ $$$\    $$$ |      \__$$  __|$$  __$$\ $$ | $$  |$$  _____|$$$\  $$ |
//     $$ |   $$ |      $$ /  $$ |$$$$\  $$$$ |         $$ |   $$ /  $$ |$$ |$$  / $$ |      $$$$\ $$ |
//     $$ |   $$$$$\    $$$$$$$$ |$$\$$\$$ $$ |         $$ |   $$ |  $$ |$$$$$  /  $$$$$\    $$ $$\$$ |
//     $$ |   $$  __|   $$  __$$ |$$ \$$$  $$ |         $$ |   $$ |  $$ |$$  $$<   $$  __|   $$ \$$$$ |
//     $$ |   $$ |      $$ |  $$ |$$ |\$  /$$ |         $$ |   $$ |  $$ |$$ |\$$\  $$ |      $$ |\$$$ |
//     $$ |   $$$$$$$$\ $$ |  $$ |$$ | \_/ $$ |         $$ |    $$$$$$  |$$ | \$$\ $$$$$$$$\ $$ | \$$ |
//     \__|   \________|\__|  \__|\__|     \__|         \__|    \______/ \__|  \__|\________|\__|  \__|
//
//   Web: teamtoken.com
//   Twitter: twitter.com/TeamTokenCrypto
//   Contact Email: [email protected]
//
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ITeamNFT.sol";
import "./interfaces/ITTRewards.sol";

error MustBeSeller();
error ListingAlreadySold();
error SomeTokensAlreadySold();
error NoTokensAlreadySold();
error ListingNotEnoughTokens();
error SellerNotEnoughTokens();
error CannotTransferTokens(address _user);
error NoTokensBought();
error ArrayIncorrectLength();
error CannotBeZero();
error DeadlineMustBeOneHour();
error MarketplaceNotApproved();

contract TTMarketplace is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable public teamToken;

    ITeamNFT public teamNft;

    ITTRewards public ttRewards;

    uint256 public marketplaceFee;

    address public feeRecipient;

    mapping(uint => SellList) public sales;
    uint256 public salesId;

    // No longer used, was not efficient.  Keeping it here because of upgradaeblae contract storage slots
    mapping(address => mapping(uint256 => uint256[])) private getSales;

    uint256 public protocolListingMaxNftPerWallet;

    mapping(address => mapping(uint256 => uint256)) public userTokensForSale;

    /// @notice This is the Sell struct, the basic structures contain the owner of the selling tokens.
    struct SellList {
        address seller;
        address token;
        uint256 tokenId;
        uint256 amountOfToken;
        uint256 amountofTokenSold;
        uint256 startTime;
        uint256 deadline;
        uint256 price;
        bool isSold;
        bool protocolSell;
    }

    /// @notice This is the emitted event, when a offer for a certain amount of tokens.
    event SellEvent(
        address indexed seller,
        uint256 indexed sellId,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    /// @notice This is the emitted event, when a sell is canceled.
    event CanceledSell(
        address indexed seller,
        uint256 indexed sellId,
        uint256 tokenId,
        uint256 amountOfToken
    );

    /// @notice This is the emitted event, when a sell is removed.
    event DeletedSell(
        address indexed seller,
        uint256 indexed sellId,
        uint256 tokenId,
        uint256 amountOfToken
    );

    /// @notice This is the emitted event, when a buy is made.
    event BuyEvent(
        address indexed buyer,
        uint256 indexed sellId,
        uint256 tokenId,
        uint256 amountOfToken,
        uint256 price
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Function to be called on initial deployment
    /// @param  _teamNft The TeamToken address registry
    function initialize(
        address _admin,
        address _teamNft,
        address _teamToken
    ) public initializer {
        require(_teamNft != address(0), "TeamNFT must be deployed.");
        require(_teamToken != address(0), "TeamToken must be deployed.");
        __Ownable_init();
        transferOwnership(_admin);
        teamNft = ITeamNFT(_teamNft); // We will set the variable before we check to save gas
        teamToken = IERC20Upgradeable(_teamToken); // We will set the variable before
        feeRecipient = address(0xbac09bCd3C11168AE39028c145710Cc862E84d7C); //gnosis safe
        protocolListingMaxNftPerWallet = 10;
        marketplaceFee = 25;
    }

    /**
        @param _newFee This is new marketplace fee amount
    **/
    function updateTotalFee(uint256 _newFee) external onlyOwner {
        // Set the new Marketplace fee
        require(_newFee <= 100 && _newFee >= 0, "Fee out of range");
        marketplaceFee = _newFee;
    }

    /**
        @param _newTtRewards New TT Rewards contract
    **/
    function updateTtRewards(address _newTtRewards) external onlyOwner {
        ttRewards = ITTRewards(_newTtRewards);
        teamToken.approve(_newTtRewards, type(uint256).max);
    }

    /**
        @param _newMaxNftPerWallet This is max NFT per wallet

    **/
    function updateProtocolListingMaxBuy(
        uint256 _newMaxNftPerWallet
    ) external onlyOwner {
        protocolListingMaxNftPerWallet = _newMaxNftPerWallet;
    }

    /** 
        @param _recipient These are the updated recipient addresses of the fees.
    **/
    function updateFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function listBatchTeamNFT(
        uint256[] memory _tokenIds,
        uint256[] memory _amountOfTokens,
        uint256[] memory _prices,
        uint256 _startTime,
        uint256 _deadline
    ) external returns (bool) {
        uint256 length = _tokenIds.length;
        require(
            length == _amountOfTokens.length,
            "tokenIds and quanitys must be same length"
        );
        for (uint256 i = 0; i < length; i++) {
            _listTeamNFT(
                _msgSender(),
                address(teamNft),
                _tokenIds[i],
                _amountOfTokens[i],
                _prices[i],
                _startTime == 0 ? block.timestamp : _startTime,
                _deadline
            );
        }
        return true;
    }

    function listTeamNFT(
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _price,
        uint256 _startTime,
        uint256 _deadline
    ) external returns (bool) {
        return
            _listTeamNFT(
                _msgSender(),
                address(teamNft),
                _tokenId,
                _amountOfToken,
                _price,
                _startTime == 0 ? block.timestamp : _startTime,
                _deadline
            );
    }

    /** 
        @param _token This is the address of the ERC1155 token.
        @param _tokenId This is the ID of the token that's inside of the ERC1155 token.
        @param _amountOfToken This is the amount of tokens that are going to be sold in the offer.
        @param _deadline This is the final date in (seconds) so the offer ends.
        @param _price This is the price for each token.
        @dev We are making some require for the parameters that needs to be required.
        @return Return true if the sell is created successfully.
    **/
    function _listTeamNFT(
        address _user,
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _price,
        uint256 _startTime,
        uint256 _deadline
    ) internal returns (bool) {
        /*
            Check if amount of token is greater than 0
                full price for token  is greater than 0
                the deadline is longer than 1 hr
        */
        if (_amountOfToken == 0 || _price == 0) {
            revert CannotBeZero();
        }

        if (_deadline < 3600) {
            revert DeadlineMustBeOneHour();
        }

        uint256 usersBalance = teamNft.balanceOf(_user, _tokenId);

        // Check if the seller owns enough tokens to be able to sell.
        if (usersBalance < _amountOfToken) {
            revert SellerNotEnoughTokens();
        }

        // Check if the seller has approved the marketplace to transfer TeamNFT
        if (!teamNft.isApprovedForAll(_user, address(this))) {
            revert MarketplaceNotApproved();
        }
        bool protocolListing;
        if (_user == teamNft.teamNftManager()) {
            protocolListing = true;
        } else {
            // This is not the protocol, we will stuf the condition check in the current
            // if statement to save gas
            //
            // Make sure they aren't overselling, and remove these checks from protocol sells

            uint256 usersTokendsForSale = userTokensForSale[_user][_tokenId];

            if (usersBalance < _amountOfToken + usersTokendsForSale) {
                if (usersBalance - usersTokendsForSale > 0) {
                    _amountOfToken = usersBalance - usersTokendsForSale;
                } else {
                    revert SellerNotEnoughTokens();
                }
            }

            // Update total number of tokens for sale

            userTokensForSale[_user][_tokenId] = safeAdjustUserTokensForSale(
                userTokensForSale[_user][_tokenId],
                OperationName.ADD,
                (_amountOfToken + usersTokendsForSale)
            );
        }
        /*
            Add the salesId as increment 1
        */
        salesId++;
        /*
            Add variables to the SellList struct with tokenAddress, seller, tokenId, amountOfToken, deadline, price
        */
        sales[salesId] = SellList(
            _user,
            _token,
            _tokenId,
            _amountOfToken,
            0,
            _startTime,
            _startTime + _deadline,
            _price,
            false,
            protocolListing
        );

        /*
            Emit the event when a sell is created.
        */
        emit SellEvent(_user, salesId, _tokenId, _amountOfToken, _price);

        return true;
    }

    /**
        @param _sellId This is the ID of the SellList that's stored in mapping function.
    **/
    function buyTeamNFT(
        uint256 _sellId,
        uint256 _quantity
    ) external returns (uint256) {
        uint256 tokensBought = _buyTeamNFT(
            _msgSender(),
            _sellId,
            _quantity,
            _msgSender(),
            false
        );
        if (tokensBought == 0) {
            revert NoTokensBought();
        }
        return tokensBought;
    }

    /**
        @param _sellIds This is the ID of the SellList that's stored in mapping function.
    **/
    function buyBatchTeamNFT(
        uint256[] memory _sellIds,
        uint256[] memory _quantitys,
        bool _allowPartial
    ) external returns (uint256) {
        uint256 length = _sellIds.length;
        if (length != _quantitys.length) {
            revert ArrayIncorrectLength();
        }

        uint256 tokensBought = 0;
        for (uint256 i = 0; i < length; i++) {
            tokensBought += _buyTeamNFT(
                _msgSender(),
                _sellIds[i],
                _quantitys[i],
                _msgSender(),
                _allowPartial
            );
        }
        if (tokensBought == 0) {
            revert NoTokensBought();
        }
        return tokensBought;
    }

    function _handleProtocolListing(
        address _user,
        uint256 _tokenId,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 buyerBalance = teamNft.balanceOf(_user, _tokenId);

        if ((buyerBalance + _amount) <= protocolListingMaxNftPerWallet) {
            return _amount;
        }

        if ((buyerBalance + _amount) > protocolListingMaxNftPerWallet) {
            return protocolListingMaxNftPerWallet - buyerBalance;
        }

        return 0;
    }

    /**
        Handles the buying
        @param _sellId This is the ID of the SellList that's stored in mapping function.
        @dev this internal function will not revert, it will just return 0 if no tokens bought.
    **/
    function _buyTeamNFT(
        address _buyer,
        uint256 _sellId,
        uint256 _amount,
        address _to,
        bool _allowPartial
    ) internal returns (uint256) {
        // Store the variable in memory so we don't
        SellList memory _sale = sales[_sellId];

        // Return number of NFT bought.  Return 0 instead of revert if cannot buy.
        if (
            _sale.isSold == true ||
            block.timestamp < _sale.startTime ||
            block.timestamp > _sale.deadline
        ) {
            return 0;
        }

        // Check if seller has enough tokens to sell.
        uint256 sellerBalance = teamNft.balanceOf(_sale.seller, _sale.tokenId);

        if (sellerBalance == 0) {
            // Force cancel the sale if seller has no tokens
            if (_sale.amountofTokenSold == 0) {
                _deleteList(_sellId);
            } else {
                _cancelList(_sellId);
            }
            return 0;
        }

        // Local sell amount is the amount of tokens to be sold in this transaction.
        // It is updated later if partials are enabled and the full amount cannot be filled.
        uint256 sellAmount = _amount;

        // Check amount of tokens available for sale
        // If not enough tokens available, and partial is enabled, change sell amount
        if (
            (_sale.amountOfToken - _sale.amountofTokenSold) < _amount &&
            !_allowPartial
        ) {
            // If amount of tokens available is less than amount requested
            revert ListingNotEnoughTokens();
        }

        if (
            (_sale.amountOfToken - _sale.amountofTokenSold) < _amount &&
            _allowPartial
        ) {
            sellAmount = _sale.amountOfToken - _sale.amountofTokenSold;
        }

        // If this is a protocol listing, ensure the user isn't over the max.
        if (
            _sale.protocolSell == true &&
            _sale.startTime + (60 * 60 * 24) > block.timestamp
        ) {
            sellAmount = _handleProtocolListing(
                _buyer,
                _sale.tokenId,
                sellAmount
            );
        }

        // Handle nicely if seller does not have enough tokens
        if (sellerBalance < sellAmount) {
            if (!_allowPartial) {
                revert SellerNotEnoughTokens();
            }
            // If the seller balance is lower than total
            // We will check to see if we should do a partial sale.

            // Change sell amount to balance of seller
            sellAmount = sellerBalance;
        }

        /*
            Get salePrice and feePrice from the marketplaceFee
        */
        uint256 salePrice = _sale.price * sellAmount;
        uint256 feePrice = (salePrice * marketplaceFee) / 1000;

        if (!teamToken.transferFrom(_buyer, address(this), salePrice)) {
            revert CannotTransferTokens(_buyer);
        }

        /*
            Transfer salePrice-feePrice to the seller's wallet
        */
        if (_sale.protocolSell) {
            teamToken.transfer(address(ttRewards), salePrice - feePrice);
            ttRewards.receiveRewards(salePrice - feePrice, _sale.tokenId);
        } else {
            teamToken.transfer(_sale.seller, salePrice - feePrice);

            // Not a protocol sale so lower the users total amount
            userTokensForSale[_sale.seller][
                _sale.tokenId
            ] = safeAdjustUserTokensForSale(
                userTokensForSale[_sale.seller][_sale.tokenId],
                OperationName.REDUCE,
                (sellAmount)
            );
        }

        /*
            Distribution feePrice to the recipients' wallets
        */
        teamToken.transfer(feeRecipient, feePrice);

        /* 
            After we send the TeamToken to the seller, we send
            the amountOfToken to the _to address
        */
        teamNft.safeTransferFrom(
            _sale.seller,
            _to,
            _sale.tokenId,
            sellAmount,
            "0x0"
        );

        /* 
            Now we must mark the tokens as sold.
        */
        sales[_sellId].amountofTokenSold = _sale.amountofTokenSold + sellAmount; // We will use the storage variable rather than memory since we need this to persist.

        if (_sale.amountofTokenSold + sellAmount == _sale.amountOfToken) {
            sales[_sellId].isSold = true;
        }

        /*
            Emit the event when a buy occurs
        */
        emit BuyEvent(_to, _sellId, _sale.tokenId, sellAmount, _sale.price);

        return sellAmount;
    }

    /** 
        @param _sellId The ID of the sell that you want to cancel.
    **/
    function cancelList(uint256 _sellId) external returns (bool) {
        if (sales[_sellId].seller != _msgSender()) {
            revert MustBeSeller();
        }
        // Delete the listing if no tokens have been sold yet.
        // Note: Keeping most safety checks in child function
        // so they are only performed if we are deleting
        if (sales[_sellId].amountofTokenSold == 0) {
            return _deleteList(_sellId);
        } else {
            return _cancelList(_sellId);
        }
    }

    function _deleteList(uint256 _sellId) internal returns (bool) {
        // Use in memory variable for everything except when we need to persist data change
        // For gas savings
        SellList memory _sale = sales[_sellId];

        if (_sale.isSold == true) {
            revert ListingAlreadySold();
        }

        if (_sale.amountofTokenSold > 0) {
            revert SomeTokensAlreadySold();
        }

        userTokensForSale[_sale.seller][
            _sale.tokenId
        ] = safeAdjustUserTokensForSale(
            userTokensForSale[_sale.seller][_sale.tokenId],
            OperationName.REDUCE,
            (_sale.amountOfToken)
        );

        // Delete the listing since nothing was sold yet
        delete sales[_sellId];

        /*
            Emit the event when a sell is cancelled.
        */
        emit DeletedSell(
            _sale.seller,
            _sellId,
            _sale.tokenId,
            _sale.amountOfToken
        );

        return true;
    }

    function _cancelList(uint256 _sellId) internal returns (bool) {
        // Use in memory variable for everything except when we need to persist data change
        // For gas savings
        SellList memory _sale = sales[_sellId];

        if (_sale.isSold == true) {
            revert ListingAlreadySold();
        }

        if (_sale.amountofTokenSold == 0) {
            revert NoTokensAlreadySold();
        }

        /*
            After those checks it is now safe to cancel
        */

        // Cannot use our local variable as we need to persist state change

        // Change the amount of tokens for sale to the total sold
        sales[_sellId].amountOfToken = _sale.amountofTokenSold;

        // Mark the listing as sold.
        sales[_sellId].isSold = true;

        // TODO check to ensure this allows sales to be cancelled that have existing sales.

        userTokensForSale[_sale.seller][
            _sale.tokenId
        ] = safeAdjustUserTokensForSale(
            userTokensForSale[_sale.seller][_sale.tokenId],
            OperationName.REDUCE,
            (sales[_sellId].amountOfToken - sales[_sellId].amountofTokenSold)
        );

        /*
            Emit the event when a sell is cancelled.
        */
        emit CanceledSell(
            _sale.seller,
            _sellId,
            _sale.tokenId,
            _sale.amountOfToken
        );

        return true;
    }

    enum OperationName {
        ADD,
        REDUCE
    }

    /**
        @param currentAmount This is the current amount stored for tokens for sale
        @param operation ENUM of ADD or REDUCE 
        @param adjustmentAmount How much we should add or reduce the amount
        @dev We are making some require for the parameters that needs to be required.
        @param newAmount Return safe amount
    **/
    function safeAdjustUserTokensForSale(
        uint256 currentAmount,
        OperationName operation,
        uint256 adjustmentAmount
    ) internal pure returns (uint256 newAmount) {
        if (operation == OperationName.ADD) {
            newAmount = currentAmount + adjustmentAmount;
        } else if (operation == OperationName.REDUCE) {
            newAmount = (currentAmount >= adjustmentAmount)
                ? currentAmount - adjustmentAmount
                : 0;
        }
    }

    /**
        @param _receiver This is the address which will be receive the token.
        @param _token This is the address of the ERC1155 token.
        @param _tokenId This is the ID of the token that's inside of the ERC1155 token.
        @param _amountOfToken This is the amount of tokens that are going to be transferred.
        @dev We are making some require for the parameters that needs to be required.
        @return Return true if the sell is created successfully.
    **/
    function transfer(
        address _receiver,
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken
    ) external returns (bool) {
        /* 
            Send ERC1155 token to _receiver wallet
            _amountOfToken to the _receiver
        */
        IERC1155Upgradeable(_token).safeTransferFrom(
            _msgSender(),
            _receiver,
            _tokenId,
            _amountOfToken,
            "0x0"
        );

        return true;
    }
}