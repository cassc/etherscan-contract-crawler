// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

import '../Literals.sol';
import '../Recoverable.sol';
import '../interfaces/IMagics.sol';
import '../interfaces/ILottery.sol';
import '../interfaces/enums/TokenType.sol';
import '../interfaces/enums/Network.sol';
import '../interfaces/IDistributedRewardsPot.sol';

contract MarketplaceBase is
    ERC1155Holder,
    Recoverable,
    Ownable,
    AccessControl,
    Literals
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct AffiliateStatistics {
        uint256 totalDistributed;
        uint256 maxDistribution;
        uint256 affiliateRatio;
    }

    struct ReferralStatistics {
        uint256 beneficiaries;
        uint256 ayraAmountEarned;
        uint256 ithdAmountEarned;
    }

    struct DistributedRewards {
        uint256 totalClaimable;
        uint256 usersLast60Days;
        uint256 time;
    }

    struct MarketItem {
        address nftaddress;
        uint256 listId;
        uint256 nftId;
        uint256 totalAmount;
        uint256 availableAmount;
        uint256 price;
        uint256 royalty;
        TokenType tokenType;
        address creator;
        address seller;
    }

    struct LastPurchase {
        uint256 price;
        TokenType tokenType;
    }

    Counters.Counter private _listIds;

    Network internal _network;

    uint256 private _feeDenominator = 1000;

    uint256 private _platformFee = 9; // 0.9 %
    uint256 private _platformFeeToken = 5; // 0.5 %

    uint256 private _distributedRewardsFee = 31; // 3.1 %
    uint256 private _distributedRewardsFeeToken = 15; // 1.5 %

    uint256 private _swapLimitBNB = 3 ether;

    uint256 public bridgeFees = 0.05 ether;

    uint256 public maxSaleAmountForRewardsEther = 250 ether;

    bytes32 public constant BRIDGE_ADMIN = keccak256('BRIDGE_ADMIN');

    bool public affilateRewardsStarted = true;
    bool public affilateRewardsStartedPolygon = true;

    IERC20 internal _ayraToken;
    IERC20 internal _ithdToken;

    bool public swapEnabled = true;

    address public profit;
    address public distributed;
    address public bridgeAdmin;

    address internal _lottery;
    address internal _priceFeed;

    string private constant _UNSUPPORTED_TOKEN_TYPE =
        'Token type unsupported for this method';

    mapping(TokenType => AffiliateStatistics) public affiliateStatistics;

    mapping(address => ReferralStatistics) public referralStatistics;

    mapping(address => mapping(address => bool))
        private _hasPurchasedWithReferral;

    mapping(TokenType => uint256) public tokenPriceUSD;

    mapping(address => mapping(TokenType => uint256))
        public userSwappedAmountBNB;

    mapping(uint256 => MarketItem) private _marketItem;

    mapping(address => mapping(uint256 => LastPurchase)) private _lastPurchase;

    mapping(address => bool) public bridgeFeesPaid;

    event Listed(uint256 listId);

    modifier onlyNonNativeToken(TokenType tokenType) {
        require(tokenType != TokenType.Native, _UNSUPPORTED_TOKEN_TYPE);
        _;
    }

    // Receive native tokens for the cases of deficit funds in lottery
    receive() external payable {}

    function changeDistributedAddress(
        address newDistributedAddress
    ) external onlyOwner {
        distributed = newDistributedAddress;
    }

    function listItem(
        address nft,
        uint256 nftId,
        uint256 amount,
        uint256 price,
        TokenType tokenType
    ) external returns (uint256) {
        require(amount > _ZERO, 'Please deposit at least one item!');
        require(price > _ZERO, 'Price should not be zero!');

        _listIds.increment();
        uint256 listId = _listIds.current();

        ItemDetails memory itemDetails = IMagics(nft).itemDetails(nftId);

        IERC1155(nft).safeTransferFrom(
            _msgSender(),
            address(this),
            nftId,
            amount,
            ''
        );

        _marketItem[listId] = MarketItem({
            nftaddress: nft,
            listId: listId,
            nftId: nftId,
            totalAmount: amount,
            availableAmount: amount,
            price: price,
            royalty: itemDetails.royalty,
            tokenType: tokenType,
            creator: itemDetails.creator,
            seller: _msgSender()
        });

        emit Listed(listId);

        return listId;
    }

    function paybridgeFees() external payable {
        require(msg.value >= bridgeFees, _INSUFFICIENT_VALUE);

        bridgeFeesPaid[_msgSender()] = true;

        payable(bridgeAdmin).transfer(msg.value);
    }

    function setBridgeFees(uint256 newBridgeFees) external onlyOwner {
        bridgeFees = newBridgeFees;
    }

    /**
     * @dev Please use one decimal to denote fee. A value of 1 means 0.1%
     */
    function setPlatformFees(
        uint256 newFee,
        uint256 newFeeToken
    ) external onlyOwner {
        _platformFee = newFee;
        _platformFeeToken = newFeeToken;
    }

    /**
     * @dev Please use one decimal to denote fee. A value of 1 means 0.1%
     */
    function setDistributedFees(
        uint256 newFee,
        uint256 newFeeToken
    ) external onlyOwner {
        _distributedRewardsFee = newFee;
        _distributedRewardsFeeToken = newFeeToken;
    }

    function editListing(
        uint256 listId,
        uint256 price,
        TokenType tokenType
    ) external {
        MarketItem storage item = _marketItem[listId];

        require(
            _msgSender() == item.seller,
            'You are not the seller of this item!'
        );

        item.tokenType = tokenType;
        item.price = price;
    }

    function unlistItem(uint256 listId) external {
        MarketItem storage item = _marketItem[listId];

        require(
            _msgSender() == item.seller,
            'You are not the seller of this item!'
        );

        require(item.availableAmount != _ZERO, 'No quantity available');

        item.availableAmount = _ZERO;

        onERC1155Received(
            address(this),
            _msgSender(),
            item.nftId,
            item.availableAmount,
            ''
        );

        IERC1155(item.nftaddress).safeTransferFrom(
            address(this),
            _msgSender(),
            item.nftId,
            item.availableAmount,
            ''
        );
    }

    function buyItem(
        uint256 listId,
        uint256 count,
        address referrer
    ) external payable {
        MarketItem storage item = _marketItem[listId];
        ItemDetails memory itemDetails = IMagics(item.nftaddress).itemDetails(
            item.nftId
        );

        IERC1155 nftContract = IERC1155(item.nftaddress);
        address userAddress = _msgSender();

        require(count > _ZERO, 'Should buy atleast one');
        require(count <= item.availableAmount, 'Quantity unavilable');

        uint256 totalSaleAmount = item.price.mul(count);
        uint256 amountToCreator = totalSaleAmount.mul(item.royalty).div(
            _ONE_HUNDRED
        );
        uint256 amountToProfit = totalSaleAmount
            .mul(
                item.tokenType == TokenType.Native
                    ? _platformFee
                    : _platformFeeToken
            )
            .div(_feeDenominator);
        uint256 amountToDistributed = totalSaleAmount
            .mul(
                itemDetails.mintTokenType == TokenType.Native
                    ? _distributedRewardsFee
                    : _distributedRewardsFeeToken
            )
            .div(_feeDenominator);
        uint256 amountToSeller = totalSaleAmount
            .sub(amountToCreator)
            .sub(amountToProfit)
            .sub(amountToDistributed);

        item.availableAmount = item.availableAmount.sub(count);

        if (item.tokenType == TokenType.Native) {
            // BNB or MATIC
            require(msg.value >= totalSaleAmount, _INSUFFICIENT_VALUE);

            payable(item.creator).transfer(amountToCreator);
            payable(item.seller).transfer(amountToSeller);
            payable(profit).transfer(amountToProfit);
            payable(distributed).transfer(amountToDistributed);
        } else if (item.tokenType == TokenType.AYRA) {
            _ayraToken.safeTransferFrom(
                userAddress,
                item.creator,
                amountToCreator
            );
            _ayraToken.safeTransferFrom(userAddress, profit, amountToProfit);
            _ayraToken.safeTransferFrom(
                userAddress,
                distributed,
                amountToDistributed
            );
            _ayraToken.safeTransferFrom(
                userAddress,
                item.seller,
                amountToSeller
            );
        } else if (item.tokenType == TokenType.ITHD) {
            _ithdToken.safeTransferFrom(
                userAddress,
                address(this),
                totalSaleAmount
            );

            _ithdToken.safeTransfer(item.creator, amountToCreator);
            _ithdToken.safeTransfer(profit, amountToProfit);
            _ithdToken.safeTransfer(distributed, amountToDistributed);
            _ithdToken.safeTransfer(item.seller, amountToSeller);
        }

        onERC1155Received(address(this), userAddress, item.nftId, count, '');
        nftContract.safeTransferFrom(
            address(this),
            userAddress,
            item.nftId,
            count,
            ''
        );

        // solhint-disable-next-line reentrancy
        _lastPurchase[userAddress][item.nftId] = LastPurchase({
            price: totalSaleAmount,
            tokenType: item.tokenType
        });

        if (_shouldNoteAffiliateRewards(referrer))
            _noteAffiliateRewards(listId, referrer, count);

        IDistributedRewardsPot(distributed).storePurchaseStatistics(
            userAddress,
            item.tokenType,
            totalSaleAmount,
            amountToDistributed
        );
    }

    function buyToken(TokenType tokenType) external payable {
        if (!swapEnabled) revert('Sale not enabled!');

        uint256 previouslySwappedAmount = userSwappedAmountBNB[_msgSender()][
            tokenType
        ];
        if (previouslySwappedAmount.add(msg.value) > _swapLimitBNB) {
            revert('Swap limits reached');
        }

        userSwappedAmountBNB[_msgSender()][tokenType] = previouslySwappedAmount
            .add(msg.value);

        payable(profit).transfer(msg.value);

        if (tokenType == TokenType.AYRA) {
            uint256 _ayraValue = _etherToToken(msg.value, TokenType.AYRA);

            _ayraToken.safeTransfer(_msgSender(), _ayraValue);
        } else if (tokenType == TokenType.ITHD) {
            uint256 _ithdValue = _etherToToken(msg.value, TokenType.ITHD);

            _ithdToken.safeTransfer(_msgSender(), _ithdValue);
        } else {
            revert(_UNSUPPORTED_TOKEN_TYPE);
        }
    }

    function changeTokenPrice(
        uint256 newPrice,
        TokenType tokenType
    ) external onlyOwner onlyNonNativeToken(tokenType) {
        tokenPriceUSD[tokenType] = newPrice;
    }

    function changeMaxRewardableSaleAmount(
        uint256 newAmount
    ) external onlyOwner {
        maxSaleAmountForRewardsEther = newAmount;
    }

    function changeBridgeAdmin(address newBridgeAdmin) external onlyOwner {
        _revokeRole(BRIDGE_ADMIN, bridgeAdmin);

        bridgeAdmin = newBridgeAdmin;

        _grantRole(BRIDGE_ADMIN, newBridgeAdmin);
    }

    function changePriceFeedAddress(address _newPriceFeed) external onlyOwner {
        _priceFeed = _newPriceFeed;
    }

    function changeProfitAddress(address newProfitAddress) external onlyOwner {
        profit = newProfitAddress;
    }

    function changeMaxDistribution(
        TokenType tokenType,
        uint256 _newValue
    ) external onlyOwner onlyNonNativeToken(tokenType) {
        affiliateStatistics[tokenType].maxDistribution = _newValue;
    }

    function changeAffiliateRatio(
        TokenType tokenType,
        uint256 _newValue
    ) external onlyOwner onlyNonNativeToken(tokenType) {
        affiliateStatistics[tokenType].affiliateRatio = _newValue;
    }

    function setSwapStatus(bool newStatus) external onlyOwner {
        swapEnabled = newStatus;
    }

    function changeSwapLimitBNB(uint256 newLimit) external onlyOwner {
        _swapLimitBNB = newLimit;
    }

    function setAffiliateRewardsStatus(
        bool newStatus,
        Network network
    ) external onlyOwner {
        if (network == Network.Binance) {
            affilateRewardsStarted = newStatus;
        } else if (network == Network.Polygon) {
            affilateRewardsStartedPolygon = newStatus;
        }
    }

    function recoverFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        bool flag = _recoverFunds(_token, _to, _amount);

        return flag;
    }

    function withdrawUnclaimedDistributedRewards(
        uint256 month,
        TokenType tokenType
    ) external onlyOwner {
        IDistributedRewardsPot(distributed).withdrawUnclaimedRewards(
            month,
            owner(),
            tokenType
        );
    }

    function changeLotteryAddress(address newAddress) external onlyOwner {
        _lottery = newAddress;
    }

    function withdrawFixedLotteryReward(
        uint256 week,
        address userAddress,
        uint8 rank,
        TokenType tokenType
    ) external onlyRole(BRIDGE_ADMIN) {
        _consumeBridgeFeesOf(userAddress);

        ILottery(_lottery).withdrawFixedReward(
            week,
            userAddress,
            rank,
            tokenType
        );
    }

    function getLotteryAddress() external view returns (address) {
        return _lottery;
    }

    function getLastPurchaseDetails(
        address buyer,
        uint256 nftId
    ) external view returns (LastPurchase memory) {
        return _lastPurchase[buyer][nftId];
    }

    function tokenToEther(
        uint256 value,
        TokenType tokenType
    ) external view returns (uint256) {
        return _tokenToEther(value, tokenType);
    }

    function withdrawReferralBenefitsOf(address _userAddress) public {
        require(
            affilateRewardsStarted,
            'Affilate rewards distribution paused!'
        );

        if (_network == Network.Polygon) {
            require(hasRole(BRIDGE_ADMIN, _msgSender()), 'Unauthorized!');

            _consumeBridgeFeesOf(_userAddress);
        } else {
            require(
                _msgSender() == _userAddress,
                'Cannot withdraw rewards of someone else'
            );
        }

        ReferralStatistics storage _referrerStatistics = referralStatistics[
            _userAddress
        ];

        require(
            _referrerStatistics.ayraAmountEarned > _ZERO ||
                _referrerStatistics.ithdAmountEarned > _ZERO,
            'No benefits to claim'
        );

        if (_network == Network.Binance) {
            if (_referrerStatistics.ayraAmountEarned > _ZERO) {
                _ayraToken.safeTransfer(
                    _userAddress,
                    _referrerStatistics.ayraAmountEarned
                );
            }

            if (_referrerStatistics.ithdAmountEarned > _ZERO) {
                _ithdToken.safeTransfer(
                    _userAddress,
                    _referrerStatistics.ithdAmountEarned
                );
            }
        }

        _referrerStatistics.ayraAmountEarned = _ZERO;
        _referrerStatistics.ithdAmountEarned = _ZERO;
    }

    function sendAffilateBenefits(
        uint256 ayraAmountEarned,
        uint256 ithdAmountEarned,
        address userAddress
    ) public onlyRole(BRIDGE_ADMIN) {
        require(affilateRewardsStartedPolygon, 'Withdrawals not enabled.');

        _consumeBridgeFeesOf(userAddress);

        AffiliateStatistics
            storage affiliateStatisticsAYRA = affiliateStatistics[
                TokenType.AYRA
            ];
        AffiliateStatistics
            storage affiliateStatisticsITHD = affiliateStatistics[
                TokenType.ITHD
            ];

        if (
            ayraAmountEarned.add(affiliateStatisticsAYRA.totalDistributed) >
            affiliateStatisticsAYRA.maxDistribution
        ) {
            ayraAmountEarned = _ZERO;
        }

        if (
            ithdAmountEarned.add(affiliateStatisticsITHD.totalDistributed) >
            affiliateStatisticsITHD.maxDistribution
        ) {
            ithdAmountEarned = _ZERO;
        }

        affiliateStatisticsAYRA.totalDistributed = affiliateStatisticsAYRA
            .totalDistributed
            .add(ayraAmountEarned);
        affiliateStatisticsITHD.totalDistributed = affiliateStatisticsITHD
            .totalDistributed
            .add(ithdAmountEarned);

        if (ayraAmountEarned > _ZERO) {
            _ayraToken.safeTransfer(userAddress, ayraAmountEarned);
        }

        if (ithdAmountEarned > _ZERO) {
            _ithdToken.safeTransfer(userAddress, ithdAmountEarned);
        }
    }

    function fetchSingleItem(
        uint256 id
    ) public view returns (MarketItem memory) {
        return _marketItem[id];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _consumeBridgeFeesOf(address userAddress) private {
        require(
            bridgeFeesPaid[userAddress],
            _network == Network.Binance
                ? 'Please pay BSC bridge fee first'
                : 'Please pay MATIC bridge fee first'
        );

        bridgeFeesPaid[userAddress] = false;
    }

    function _noteAffiliateRewards(
        uint256 listId,
        address referrer,
        uint256 count
    ) private {
        MarketItem storage item = _marketItem[listId];

        ReferralStatistics storage _referrerStatistics = referralStatistics[
            referrer
        ];

        AffiliateStatistics
            storage affiliateStatisticsAYRA = affiliateStatistics[
                TokenType.AYRA
            ];

        AffiliateStatistics
            storage affiliateStatisticsITHD = affiliateStatistics[
                TokenType.ITHD
            ];

        _hasPurchasedWithReferral[referrer][_msgSender()] = true;

        uint256 totalSaleAmount = item.price.mul(count);
        uint256 saleAmountEther = _tokenToEther(
            totalSaleAmount,
            item.tokenType
        );

        saleAmountEther = saleAmountEther > maxSaleAmountForRewardsEther
            ? maxSaleAmountForRewardsEther
            : saleAmountEther;

        uint256 rewardInAYRA = saleAmountEther.mul(_TEN).mul(1 ether).div(
            uint256(_ONE_HUNDRED).mul(affiliateStatisticsAYRA.affiliateRatio)
        );

        uint256 rewardInITHD = saleAmountEther.mul(_TEN).mul(1 ether).div(
            uint256(_ONE_HUNDRED).mul(affiliateStatisticsITHD.affiliateRatio)
        );

        if (
            rewardInAYRA.add(affiliateStatisticsAYRA.totalDistributed) >
            affiliateStatisticsAYRA.maxDistribution
        ) {
            rewardInAYRA = _ZERO;
        }

        if (
            rewardInITHD.add(affiliateStatisticsITHD.totalDistributed) >
            affiliateStatisticsITHD.maxDistribution
        ) {
            rewardInITHD = _ZERO;
        }

        if (rewardInAYRA > _ZERO) {
            _referrerStatistics.ayraAmountEarned = _referrerStatistics
                .ayraAmountEarned
                .add(rewardInAYRA);
            affiliateStatisticsAYRA.totalDistributed = affiliateStatisticsAYRA
                .totalDistributed
                .add(rewardInAYRA);
        }

        if (rewardInITHD > _ZERO) {
            _referrerStatistics.ithdAmountEarned = _referrerStatistics
                .ithdAmountEarned
                .add(rewardInITHD);
            affiliateStatisticsITHD.totalDistributed = affiliateStatisticsITHD
                .totalDistributed
                .add(rewardInITHD);
        }

        if (rewardInAYRA > _ZERO || rewardInITHD > _ZERO) {
            _referrerStatistics.beneficiaries = _referrerStatistics
                .beneficiaries
                .add(_ONE);
        }
    }

    function _etherToToken(
        uint256 value,
        TokenType _toTokenType
    ) private view returns (uint256) {
        uint256 usdPerEther = _getLatestPriceEther();
        uint256 usdValue = value.mul(usdPerEther);

        if (_toTokenType == TokenType.Native) {
            revert(_UNSUPPORTED_TOKEN_TYPE);
        }

        return usdValue.div(tokenPriceUSD[_toTokenType]);
    }

    function _tokenToEther(
        uint256 value,
        TokenType tokenType
    ) private view returns (uint256) {
        if (tokenType == TokenType.Native) {
            return value;
        } else {
            uint256 usdPerEther = _getLatestPriceEther();

            return value.mul(tokenPriceUSD[tokenType]).div(usdPerEther);
        }
    }

    function _shouldNoteAffiliateRewards(
        address referrer
    ) private view returns (bool) {
        return
            referrer != _ZERO_ADDRESS &&
            _msgSender() != referrer &&
            !_hasPurchasedWithReferral[referrer][_msgSender()];
    }

    function _getLatestPriceEther() private view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(_priceFeed)
            .latestRoundData();

        return uint256(price).mul(1e10);
    }
}