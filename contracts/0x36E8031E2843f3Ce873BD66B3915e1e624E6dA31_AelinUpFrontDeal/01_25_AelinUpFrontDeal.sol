// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./AelinERC20.sol";
import "./MinimalProxyFactory.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {AelinDeal} from "./AelinDeal.sol";
import {AelinPool} from "./AelinPool.sol";
import {AelinFeeEscrow} from "./AelinFeeEscrow.sol";
import {IAelinUpFrontDeal} from "./interfaces/IAelinUpFrontDeal.sol";
import "./libraries/AelinNftGating.sol";
import "./libraries/AelinAllowList.sol";
import "./libraries/MerkleTree.sol";

contract AelinUpFrontDeal is AelinERC20, MinimalProxyFactory, IAelinUpFrontDeal {
    using SafeERC20 for IERC20;

    uint256 constant BASE = 100 * 10**18;
    uint256 constant MAX_SPONSOR_FEE = 15 * 10**18;
    uint256 constant AELIN_FEE = 2 * 10**18;

    UpFrontDealData public dealData;
    UpFrontDealConfig public dealConfig;

    address public aelinTreasuryAddress;
    address public aelinEscrowLogicAddress;
    AelinFeeEscrow public aelinFeeEscrow;
    address public dealFactory;

    MerkleTree.TrackClaimed private trackClaimed;
    AelinAllowList.AllowList public allowList;
    AelinNftGating.NftGatingData public nftGating;
    mapping(address => uint256) public purchaseTokensPerUser;
    mapping(address => uint256) public poolSharesPerUser;
    mapping(address => uint256) public amountVested;

    uint256 public totalPurchasingAccepted;
    uint256 public totalPoolShares;
    uint256 public totalUnderlyingClaimed;

    bool private underlyingDepositComplete;
    bool private sponsorClaimed;
    bool private holderClaimed;
    bool private feeEscrowClaimed;

    bool private calledInitialize;
    address public futureHolder;

    uint256 public dealStart;
    uint256 public purchaseExpiry;
    uint256 public vestingCliffExpiry;
    uint256 public vestingExpiry;

    /**
     * @dev initializes the contract configuration, called from the factory contract when creating a new Up Front Deal
     */
    function initialize(
        UpFrontDealData calldata _dealData,
        UpFrontDealConfig calldata _dealConfig,
        AelinNftGating.NftCollectionRules[] calldata _nftCollectionRules,
        AelinAllowList.InitData calldata _allowListInit,
        address _aelinTreasuryAddress,
        address _aelinEscrowLogicAddress
    ) external initOnce {
        // pool initialization checks
        require(_dealData.purchaseToken != _dealData.underlyingDealToken, "purchase & underlying the same");
        require(_dealData.purchaseToken != address(0), "cant pass null purchase address");
        require(_dealData.underlyingDealToken != address(0), "cant pass null underlying address");
        require(_dealData.holder != address(0), "cant pass null holder address");

        require(_dealConfig.purchaseDuration >= 30 minutes && _dealConfig.purchaseDuration <= 30 days, "not within limit");
        require(_dealData.sponsorFee <= MAX_SPONSOR_FEE, "exceeds max sponsor fee");

        require(1825 days >= _dealConfig.vestingCliffPeriod, "max 5 year cliff");
        require(1825 days >= _dealConfig.vestingPeriod, "max 5 year vesting");

        require(_dealConfig.underlyingDealTokenTotal > 0, "must have nonzero deal tokens");
        require(_dealConfig.purchaseTokenPerDealToken > 0, "invalid deal price");

        uint8 underlyingTokenDecimals = IERC20Decimals(_dealData.underlyingDealToken).decimals();
        if (_dealConfig.purchaseRaiseMinimum > 0) {
            uint256 _totalIntendedRaise = (_dealConfig.purchaseTokenPerDealToken * _dealConfig.underlyingDealTokenTotal) /
                10**underlyingTokenDecimals;
            require(_totalIntendedRaise > 0, "intended raise too small");
            require(_dealConfig.purchaseRaiseMinimum <= _totalIntendedRaise, "raise min > deal total");
        }

        // store pool and deal details as state variables
        dealData = _dealData;
        dealConfig = _dealConfig;

        dealStart = block.timestamp;

        dealFactory = msg.sender;

        // the deal token has the same amount of decimals as the underlying deal token,
        // eventually making them 1:1 redeemable
        _setNameSymbolAndDecimals(
            string(abi.encodePacked("aeUpFrontDeal-", _dealData.name)),
            string(abi.encodePacked("aeUD-", _dealData.symbol)),
            underlyingTokenDecimals
        );

        aelinEscrowLogicAddress = _aelinEscrowLogicAddress;
        aelinTreasuryAddress = _aelinTreasuryAddress;

        // Allow list logic
        // check if there's allowlist and amounts,
        // if yes, store it to `allowList` and emit a single event with the addresses and amounts
        AelinAllowList.initialize(_allowListInit, allowList);

        // NftCollection logic
        // check if the deal is nft gated
        // if yes, store it in `nftCollectionDetails` and `nftId` and emit respective events for 721 and 1155
        AelinNftGating.initialize(_nftCollectionRules, nftGating);

        require(!(allowList.hasAllowList && nftGating.hasNftList), "cant have allow list & nft");
        require(!(allowList.hasAllowList && dealData.merkleRoot != 0), "cant have allow list & merkle");
        require(!(nftGating.hasNftList && dealData.merkleRoot != 0), "cant have nft & merkle");
        require(!(bytes(dealData.ipfsHash).length == 0 && dealData.merkleRoot != 0), "merkle needs ipfs hash");
    }

    function _startPurchasingPeriod(
        uint256 _purchaseDuration,
        uint256 _vestingCliffPeriod,
        uint256 _vestingPeriod
    ) internal {
        underlyingDepositComplete = true;
        purchaseExpiry = block.timestamp + _purchaseDuration;
        vestingCliffExpiry = purchaseExpiry + _vestingCliffPeriod;
        vestingExpiry = vestingCliffExpiry + _vestingPeriod;
        emit DealFullyFunded(address(this), block.timestamp, purchaseExpiry, vestingCliffExpiry, vestingExpiry);
    }

    modifier initOnce() {
        require(!calledInitialize, "can only init once");
        calledInitialize = true;
        _;
    }

    /**
     * @dev method for holder to deposit underlying deal tokens
     * all underlying deal tokens must be deposited for the purchasing period to start
     * if tokens were deposited directly, this method must still be called to start the purchasing period
     * @param _depositUnderlyingAmount how many underlying tokens the holder will transfer to the contract
     */
    function depositUnderlyingTokens(uint256 _depositUnderlyingAmount) public onlyHolder {
        address _underlyingDealToken = dealData.underlyingDealToken;

        require(IERC20(_underlyingDealToken).balanceOf(msg.sender) >= _depositUnderlyingAmount, "not enough balance");
        require(!underlyingDepositComplete, "already deposited the total");

        uint256 balanceBeforeTransfer = IERC20(_underlyingDealToken).balanceOf(address(this));
        IERC20(_underlyingDealToken).safeTransferFrom(msg.sender, address(this), _depositUnderlyingAmount);
        uint256 balanceAfterTransfer = IERC20(_underlyingDealToken).balanceOf(address(this));
        uint256 underlyingDealTokenAmount = balanceAfterTransfer - balanceBeforeTransfer;

        if (balanceAfterTransfer >= dealConfig.underlyingDealTokenTotal) {
            _startPurchasingPeriod(dealConfig.purchaseDuration, dealConfig.vestingCliffPeriod, dealConfig.vestingPeriod);
        }

        emit DepositDealToken(_underlyingDealToken, msg.sender, underlyingDealTokenAmount);
    }

    /**
     * @dev allows holder to withdraw any excess underlying deal tokens deposited to the contract
     */
    function withdrawExcess() external onlyHolder {
        address _underlyingDealToken = dealData.underlyingDealToken;
        uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;
        uint256 currentBalance = IERC20(_underlyingDealToken).balanceOf(address(this));
        require(currentBalance > _underlyingDealTokenTotal, "no excess to withdraw");

        uint256 excessAmount = currentBalance - _underlyingDealTokenTotal;
        IERC20(_underlyingDealToken).safeTransfer(msg.sender, excessAmount);

        emit WithdrewExcess(address(this), excessAmount);
    }

    /**
     * @dev accept deal by depositing purchasing tokens which is converted to a mapping which stores the amount of
     * underlying purchased. pool shares have the same decimals as the underlying deal token
     * @param _nftPurchaseList NFTs to use for accepting the deal if deal is NFT gated
     * @param _merkleData Merkle Proof data to prove investors allocation
     * @param _purchaseTokenAmount how many purchase tokens will be used to purchase deal token shares
     */
    function acceptDeal(
        AelinNftGating.NftPurchaseList[] calldata _nftPurchaseList,
        MerkleTree.UpFrontMerkleData calldata _merkleData,
        uint256 _purchaseTokenAmount
    ) external lock {
        require(underlyingDepositComplete, "deal token not deposited");
        require(block.timestamp < purchaseExpiry, "not in purchase window");

        address _purchaseToken = dealData.purchaseToken;
        uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;
        uint256 _purchaseTokenPerDealToken = dealConfig.purchaseTokenPerDealToken;
        require(IERC20(_purchaseToken).balanceOf(msg.sender) >= _purchaseTokenAmount, "not enough purchaseToken");

        if (nftGating.hasNftList || _nftPurchaseList.length > 0) {
            AelinNftGating.purchaseDealTokensWithNft(_nftPurchaseList, nftGating, _purchaseTokenAmount);
        } else if (allowList.hasAllowList) {
            require(_purchaseTokenAmount <= allowList.amountPerAddress[msg.sender], "more than allocation");
            allowList.amountPerAddress[msg.sender] -= _purchaseTokenAmount;
        } else if (dealData.merkleRoot != 0) {
            MerkleTree.purchaseMerkleAmount(_merkleData, trackClaimed, _purchaseTokenAmount, dealData.merkleRoot);
        }

        uint256 balanceBeforeTransfer = IERC20(_purchaseToken).balanceOf(address(this));
        IERC20(_purchaseToken).safeTransferFrom(msg.sender, address(this), _purchaseTokenAmount);
        uint256 balanceAfterTransfer = IERC20(_purchaseToken).balanceOf(address(this));
        uint256 purchaseTokenAmount = balanceAfterTransfer - balanceBeforeTransfer;

        totalPurchasingAccepted += purchaseTokenAmount;
        purchaseTokensPerUser[msg.sender] += purchaseTokenAmount;

        uint8 underlyingTokenDecimals = IERC20Decimals(dealData.underlyingDealToken).decimals();
        uint256 poolSharesAmount;

        // this takes into account the decimal conversion between purchasing token and underlying deal token
        // pool shares having the same amount of decimals as underlying deal tokens
        poolSharesAmount = (purchaseTokenAmount * 10**underlyingTokenDecimals) / _purchaseTokenPerDealToken;
        require(poolSharesAmount > 0, "purchase amount too small");

        // pool shares directly correspond to the amount of deal tokens that can be minted
        // pool shares held = deal tokens minted as long as no deallocation takes place
        totalPoolShares += poolSharesAmount;
        poolSharesPerUser[msg.sender] += poolSharesAmount;

        if (!dealConfig.allowDeallocation) {
            require(totalPoolShares <= _underlyingDealTokenTotal, "purchased amount > total");
        }

        emit AcceptDeal(
            msg.sender,
            purchaseTokenAmount,
            purchaseTokensPerUser[msg.sender],
            poolSharesAmount,
            poolSharesPerUser[msg.sender]
        );
    }

    /**
     * @dev purchaser calls to claim their deal tokens or refund if the minimum raise does not pass
     */
    function purchaserClaim() public lock purchasingOver {
        require(poolSharesPerUser[msg.sender] > 0, "no pool shares to claim with");

        address _purchaseToken = dealData.purchaseToken;
        uint256 _purchaseRaiseMinimum = dealConfig.purchaseRaiseMinimum;

        if (_purchaseRaiseMinimum == 0 || totalPurchasingAccepted > _purchaseRaiseMinimum) {
            uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;
            // Claim Deal Tokens
            bool deallocate = totalPoolShares > _underlyingDealTokenTotal;

            if (deallocate) {
                // adjust for deallocation and mint deal tokens
                uint256 adjustedDealTokensForUser = (((poolSharesPerUser[msg.sender] * _underlyingDealTokenTotal) /
                    totalPoolShares) * (BASE - AELIN_FEE - dealData.sponsorFee)) / BASE;
                poolSharesPerUser[msg.sender] = 0;

                // refund any purchase tokens that got deallocated
                uint256 purchasingRefund = purchaseTokensPerUser[msg.sender] -
                    ((purchaseTokensPerUser[msg.sender] * _underlyingDealTokenTotal) / totalPoolShares);
                purchaseTokensPerUser[msg.sender] = 0;

                uint256 precisionAdjustedRefund = purchasingRefund > IERC20(_purchaseToken).balanceOf(address(this))
                    ? IERC20(_purchaseToken).balanceOf(address(this))
                    : purchasingRefund;

                // mint deal tokens and transfer purchase token refund
                _mint(msg.sender, adjustedDealTokensForUser);
                IERC20(_purchaseToken).safeTransfer(msg.sender, precisionAdjustedRefund);

                emit ClaimDealTokens(msg.sender, adjustedDealTokensForUser, precisionAdjustedRefund);
            } else {
                // mint deal tokens when there is no deallocation
                uint256 adjustedDealTokensForUser = ((BASE - AELIN_FEE - dealData.sponsorFee) *
                    poolSharesPerUser[msg.sender]) / BASE;
                poolSharesPerUser[msg.sender] = 0;
                purchaseTokensPerUser[msg.sender] = 0;
                _mint(msg.sender, adjustedDealTokensForUser);
                emit ClaimDealTokens(msg.sender, adjustedDealTokensForUser, 0);
            }
        } else {
            // Claim Refund
            uint256 currentBalance = purchaseTokensPerUser[msg.sender];
            purchaseTokensPerUser[msg.sender] = 0;
            poolSharesPerUser[msg.sender] = 0;
            IERC20(_purchaseToken).safeTransfer(msg.sender, currentBalance);
            emit ClaimDealTokens(msg.sender, 0, currentBalance);
        }
    }

    /**
     * @dev sponsor calls once the purchasing period is over if the minimum raise has passed to claim
     * their share of deal tokens
     * NOTE also calls the claim for the protocol fee
     */
    function sponsorClaim() public lock purchasingOver passMinimumRaise onlySponsor {
        require(!sponsorClaimed, "sponsor already claimed");
        sponsorClaimed = true;

        address _sponsor = dealData.sponsor;
        uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;

        uint256 totalSold = totalPoolShares > _underlyingDealTokenTotal ? _underlyingDealTokenTotal : totalPoolShares;
        uint256 _sponsorFeeAmt = (totalSold * dealData.sponsorFee) / BASE;
        _mint(_sponsor, _sponsorFeeAmt);
        emit SponsorClaim(_sponsor, _sponsorFeeAmt);

        if (!feeEscrowClaimed) {
            feeEscrowClaim();
        }
    }

    /**
     * @dev holder calls once purchasing period is over to claim their raise or
     * underlying deal tokens if the minimum raise has not passed
     * NOTE also calls the claim for the protocol fee
     */
    function holderClaim() public lock purchasingOver onlyHolder {
        require(!holderClaimed, "holder already claimed");
        holderClaimed = true;

        address _holder = dealData.holder;
        address _underlyingDealToken = dealData.underlyingDealToken;
        address _purchaseToken = dealData.purchaseToken;
        uint256 _purchaseRaiseMinimum = dealConfig.purchaseRaiseMinimum;

        if (_purchaseRaiseMinimum == 0 || totalPurchasingAccepted > _purchaseRaiseMinimum) {
            uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;

            bool deallocate = totalPoolShares > _underlyingDealTokenTotal;
            if (deallocate) {
                uint256 _underlyingTokenDecimals = IERC20Decimals(_underlyingDealToken).decimals();
                uint256 _totalIntendedRaise = (dealConfig.purchaseTokenPerDealToken * _underlyingDealTokenTotal) /
                    10**_underlyingTokenDecimals;

                uint256 precisionAdjustedRaise = _totalIntendedRaise > IERC20(_purchaseToken).balanceOf(address(this))
                    ? IERC20(_purchaseToken).balanceOf(address(this))
                    : _totalIntendedRaise;

                IERC20(_purchaseToken).safeTransfer(_holder, precisionAdjustedRaise);
                emit HolderClaim(_holder, _purchaseToken, precisionAdjustedRaise, _underlyingDealToken, 0, block.timestamp);
            } else {
                // holder receives raise
                uint256 _currentBalance = IERC20(_purchaseToken).balanceOf(address(this));
                IERC20(_purchaseToken).safeTransfer(_holder, _currentBalance);
                // holder receives any leftover underlying deal tokens
                uint256 _underlyingRefund = _underlyingDealTokenTotal - totalPoolShares;
                IERC20(_underlyingDealToken).safeTransfer(_holder, _underlyingRefund);
                emit HolderClaim(
                    _holder,
                    _purchaseToken,
                    _currentBalance,
                    _underlyingDealToken,
                    _underlyingRefund,
                    block.timestamp
                );
            }
            if (!feeEscrowClaimed) {
                feeEscrowClaim();
            }
        } else {
            uint256 _currentBalance = IERC20(_underlyingDealToken).balanceOf(address(this));
            IERC20(_underlyingDealToken).safeTransfer(_holder, _currentBalance);
            emit HolderClaim(_holder, _purchaseToken, 0, _underlyingDealToken, _currentBalance, block.timestamp);
        }
    }

    /**
     * @dev transfers protocol fee of underlying deal tokens to the treasury escrow contract
     */
    function feeEscrowClaim() public purchasingOver {
        if (!feeEscrowClaimed) {
            feeEscrowClaimed = true;
            address _underlyingDealToken = dealData.underlyingDealToken;
            uint256 _underlyingDealTokenTotal = dealConfig.underlyingDealTokenTotal;

            address aelinEscrowStorageProxy = _cloneAsMinimalProxy(aelinEscrowLogicAddress, "Could not create new escrow");
            aelinFeeEscrow = AelinFeeEscrow(aelinEscrowStorageProxy);
            aelinFeeEscrow.initialize(aelinTreasuryAddress, _underlyingDealToken);

            uint256 totalSold;
            if (totalPoolShares > _underlyingDealTokenTotal) {
                totalSold = _underlyingDealTokenTotal;
            } else {
                totalSold = totalPoolShares;
            }
            uint256 aelinFeeAmt = (totalSold * AELIN_FEE) / BASE;
            IERC20(_underlyingDealToken).safeTransfer(address(aelinFeeEscrow), aelinFeeAmt);

            emit FeeEscrowClaim(aelinEscrowStorageProxy, _underlyingDealToken, aelinFeeAmt);
        }
    }

    /**
     * @dev purchaser calls after the purchasing period to claim underlying deal tokens
     * amount based on the vesting schedule
     */
    function claimUnderlying() external lock purchasingOver passMinimumRaise {
        uint256 underlyingDealTokensClaimed = claimableUnderlyingTokens(msg.sender);
        require(underlyingDealTokensClaimed > 0, "no underlying ready to claim");
        address _underlyingDealToken = dealData.underlyingDealToken;
        amountVested[msg.sender] += underlyingDealTokensClaimed;
        _burn(msg.sender, underlyingDealTokensClaimed);
        totalUnderlyingClaimed += underlyingDealTokensClaimed;
        IERC20(_underlyingDealToken).safeTransfer(msg.sender, underlyingDealTokensClaimed);
        emit ClaimedUnderlyingDealToken(msg.sender, _underlyingDealToken, underlyingDealTokensClaimed);
    }

    /**
     * @dev a view showing the amount of the underlying deal token a purchaser can claim
     * @param _purchaser address to check the quantity of claimable underlying tokens
     */
    function claimableUnderlyingTokens(address _purchaser) public view purchasingOver returns (uint256) {
        uint256 _vestingPeriod = dealConfig.vestingPeriod;
        uint256 precisionAdjustedUnderlyingClaimable;

        uint256 maxTime = block.timestamp > vestingExpiry ? vestingExpiry : block.timestamp;
        if (
            balanceOf(_purchaser) > 0 &&
            (maxTime > vestingCliffExpiry || (maxTime == vestingCliffExpiry && _vestingPeriod == 0))
        ) {
            uint256 timeElapsed = maxTime - vestingCliffExpiry;

            uint256 underlyingClaimable = _vestingPeriod == 0
                ? balanceOf(_purchaser)
                : ((balanceOf(_purchaser) + amountVested[_purchaser]) * timeElapsed) /
                    _vestingPeriod -
                    amountVested[_purchaser];
            // This could potentially be the case where the last user claims a slightly smaller amount if there is some precision loss
            // although it will generally never happen as solidity rounds down so there should always be a little bit left
            address _underlyingDealToken = dealData.underlyingDealToken;
            precisionAdjustedUnderlyingClaimable = underlyingClaimable >
                IERC20(_underlyingDealToken).balanceOf(address(this))
                ? IERC20(_underlyingDealToken).balanceOf(address(this))
                : underlyingClaimable;
        }

        return (precisionAdjustedUnderlyingClaimable);
    }

    /**
     * @dev the holder may change their address
     * @param _holder address to swap the holder role
     */
    function setHolder(address _holder) external onlyHolder {
        futureHolder = _holder;
    }

    /**
     * @dev futurHolder can call to accept the role of holder
     */
    function acceptHolder() external {
        require(msg.sender == futureHolder, "only future holder can access");
        dealData.holder = futureHolder;
        emit SetHolder(futureHolder);
    }

    /**
     * @dev a function that any Ethereum address can call to vouch for a pool's legitimacy
     */
    function vouch() external {
        emit Vouch(msg.sender);
    }

    /**
     * @dev a function that any Ethereum address can call to disavow for a pool's legitimacy
     */
    function disavow() external {
        emit Disavow(msg.sender);
    }

    /**
     * @dev returns allow list information
     * @param _userAddress address to use in returning the amountPerAddress
     * @return address[] returns array of addresses included in the allow list
     * @return uint256[] returns array of allow list amounts for the address matching the index of allowListAddresses
     * @return uint256 allow list amount for _userAddress input
     * @return bool true if this deal has an allow list
     */
    function getAllowList(address _userAddress)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256,
            bool
        )
    {
        return (
            allowList.allowListAddresses,
            allowList.allowListAmounts,
            allowList.amountPerAddress[_userAddress],
            allowList.hasAllowList
        );
    }

    /**
     * @dev returns NFT collection details for the input collection address
     * @param _collection NFT collection address to get the collection details for
     * @return uint256 purchase amount, if 0 then unlimited purchase
     * @return address collection address used for configuration
     * @return bool if true then purchase amount is per token, if false then purchase amount is per user
     * @return uint256[] for ERC1155, included token IDs for this collection
     * @return uint256[] for ERC1155, min number of tokens required for participating
     */
    function getNftCollectionDetails(address _collection)
        public
        view
        returns (
            uint256,
            address,
            bool,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            nftGating.nftCollectionDetails[_collection].purchaseAmount,
            nftGating.nftCollectionDetails[_collection].collectionAddress,
            nftGating.nftCollectionDetails[_collection].purchaseAmountPerToken,
            nftGating.nftCollectionDetails[_collection].tokenIds,
            nftGating.nftCollectionDetails[_collection].minTokensEligible
        );
    }

    /**
     * @dev returns various details about the NFT gating storage
     * @param _collection NFT collection address to check
     * @param _wallet user address to check
     * @param _nftId if _collection is ERC721 or CryptoPunks check if this ID has been used, if ERC1155 check if this ID is included
     * @return bool true if the _wallet has already been used to claim this _collection
     * @return bool if _collection is ERC721 or CryptoPunks true if this ID has been used, if ERC1155 true if this ID is included
     * @return bool returns hasNftList, true if this deal has a valid NFT gating list
     */
    function getNftGatingDetails(
        address _collection,
        address _wallet,
        uint256 _nftId
    )
        public
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return (
            nftGating.nftWalletUsedForPurchase[_collection][_wallet],
            nftGating.nftId[_collection][_nftId],
            nftGating.hasNftList
        );
    }

    /**
     * @dev getPurchaseTokensPerUser
     * @param _address address to check
     */
    function getPurchaseTokensPerUser(address _address) public view returns (uint256) {
        return (purchaseTokensPerUser[_address]);
    }

    /**
     * @dev getPoolSharesPerUser
     * @param _address address to check
     */
    function getPoolSharesPerUser(address _address) public view returns (uint256) {
        return (poolSharesPerUser[_address]);
    }

    /**
     * @dev getAmountVested
     * @param _address address to check
     */
    function getAmountVested(address _address) public view returns (uint256) {
        return (amountVested[_address]);
    }

    /**
     * @dev hasPurchasedMerkle
     * @param _index index of leaf node/ address to check
     */
    function hasPurchasedMerkle(uint256 _index) public view returns (bool) {
        return MerkleTree.hasPurchasedMerkle(trackClaimed, _index);
    }

    modifier onlyHolder() {
        require(msg.sender == dealData.holder, "must be holder");
        _;
    }

    modifier onlySponsor() {
        require(msg.sender == dealData.sponsor, "must be sponsor");
        _;
    }

    modifier purchasingOver() {
        require(underlyingDepositComplete, "underlying deposit incomplete");
        require(block.timestamp > purchaseExpiry, "purchase period not over");
        _;
    }

    modifier passMinimumRaise() {
        require(
            dealConfig.purchaseRaiseMinimum == 0 || totalPurchasingAccepted > dealConfig.purchaseRaiseMinimum,
            "does not pass min raise"
        );
        _;
    }

    modifier blockTransfer() {
        require(false, "cant transfer deal tokens");
        _;
    }

    function transfer(address _dst, uint256 _amount) public virtual override blockTransfer returns (bool) {
        return super.transfer(_dst, _amount);
    }

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amount
    ) public virtual override blockTransfer returns (bool) {
        return super.transferFrom(_src, _dst, _amount);
    }
}