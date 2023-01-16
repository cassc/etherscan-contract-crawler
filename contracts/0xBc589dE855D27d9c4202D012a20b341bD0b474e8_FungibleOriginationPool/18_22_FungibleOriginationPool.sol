//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interface/IFungibleOriginationPool.sol";
import "./interface/IVestingEntryNFT.sol";

import "./VestingEntryNFT.sol";

/**
 * Origination pool representing a fungible token sale
 * Users buy an ERC-20 token using ETH or other ERC-20 token
 */
contract FungibleOriginationPool is
    IFungibleOriginationPool,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20Metadata;

    //--------------------------------------------------------------------------
    // Constants
    //--------------------------------------------------------------------------

    uint256 constant MAX_SALE_DURATION = 365 days;

    //--------------------------------------------------------------------------
    // State variables
    //--------------------------------------------------------------------------

    // the token being offered for sale
    IERC20Metadata public offerToken;
    // the token used to purchase the offered token
    IERC20Metadata public purchaseToken;
    // equal to 10^offerTokenDecimals
    uint256 private offerTokenUnits;
    // equal to 10^purchaseTokenDecimals
    uint256 private purchaseTokenUnits;

    // Token sale params
    // the public sale starting price (in purchase token)
    uint256 public publicStartingPrice;
    // the public sale ending price (in purchase token)
    uint256 public publicEndingPrice;
    // the whitelist sale starting price (in purchase token)
    uint256 public whitelistStartingPrice;
    // the whitelist sale ending price (in purchase token)
    uint256 public whitelistEndingPrice;
    // the public sale duration (in seconds)
    uint256 public publicSaleDuration;
    // whitelist sale duration (in seconds)
    uint256 public whitelistSaleDuration;
    // the total sale duration (in seconds)
    uint256 public saleDuration;
    // the total amount of offer tokens for sale
    uint256 public totalOfferingAmount;
    // amount of purchase tokens needed to be raised for sale completion
    uint256 public reserveAmount;
    // minimum amount of purchase tokens needed to be invested to participate in the sale
    uint256 public minContributionAmount;
    // the vesting period - in seconds (can be 0 if the sale has no vesting period)
    uint256 public vestingPeriod;
    // the vesting cliff period - in seconds (must be <= vesting period)
    uint256 public cliffPeriod;
    // the whitelist merkle root - used to verify whitelist proofs
    bytes32 public whitelistMerkleRoot;

    // the fee owed to the origination core when purchasing tokens (ex: 1e16 = 1% fee)
    uint256 public originationFee;
    // the origination core contract
    IOriginationCore public originationCore;
    // the nft representing vesting entries for users
    VestingEntryNFT public vestingEntryNFT;

    // address with manager capabilities
    address public manager;

    // true if sale has started, false otherwise
    bool public saleInitiated;
    // the timestamp of the beginning of the sale
    uint256 public saleInitiatedTimestamp;
    // the timestamp of the end of the sale
    // sale can end when the offer tokens are purchased or when sale duration has passed
    uint256 public saleEndTimestamp;

    // the amount of offer tokens which are reserved for vesting
    uint256 public vestableTokenAmount;
    // id to keep track of vesting positions
    uint256 public vestingID;

    // Sale trackers
    // address to vesting entry nft id tracker (not accurate if nft is transferred)
    // only used for internal tracking of the vestings
    mapping(address => uint256) public userToVestingId;
    // purchaser address to amount purchased
    mapping(address => uint256) public offerTokenAmountPurchased;
    // purchaser address to amount contributed
    mapping(address => uint256) public purchaseTokenContribution;
    // the total amount of offer tokens sold
    uint256 public offerTokenAmountSold;
    // the total amount of purchase tokens acquired
    uint256 public purchaseTokensAcquired;
    // the total amount of origination fees
    uint256 public originationCoreFees;
    // true if the sponsor has claimed purchase tokens / remaining offer tokens at conclusion of sale, false otherwise
    bool public sponsorTokensClaimed;

    //--------------------------------------------------------------------------
    // Events
    //--------------------------------------------------------------------------

    // Management events
    event InitiateSale(uint256 totalOfferingAmount);
    event ManagerSet(address indexed manager);
    event WhitelistSet(bytes32 indexed whitelistMerkleRoot);
    // Token retrieval events
    event PurchaseTokensRetrieved(
        address indexed user,
        uint256 amountRetrieved
    );
    event OfferTokensRetrieved(address indexed owner, uint256 amountRetrieved);
    // Token claim events
    event PurchaseTokenClaim(address indexed owner, uint256 amountClaimed);
    event TokensClaimed(address indexed user, uint256 amountClaimed);
    event ClaimVested(
        address indexed purchaser,
        uint256 tokenAmountClaimed,
        uint256 tokenAmountRemaining
    );
    // Token purchase events
    event Purchase(
        address indexed purchaser,
        uint256 contributionAmount,
        uint256 offerAmount,
        uint256 purchaseFee
    );
    event CreateVestingEntry(
        address indexed purchaser,
        uint256 vestingId,
        uint256 offerTokenAmount
    );

    //--------------------------------------------------------------------------
    // Modifiers
    //--------------------------------------------------------------------------

    modifier onlyOwnerOrManager() {
        require(isOwnerOrManager(msg.sender), "Not owner or manager");
        _;
    }

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    // Initialize the implementation
    constructor() initializer {}

    /**
     * @dev Initializes the origination pool contract
     *
     * @param _originationFee The fee owed to the origination core when purchasing tokens. E.g. 1e16 = 1% fee
     * @param _originationCore The origination core contract
     * @param _admin The address of admin/owner of the pool
     * @param _saleParams The sale params
     */
    function initialize(
        uint256 _originationFee,
        IOriginationCore _originationCore,
        address _admin,
        address _vestingEntryNFT,
        SaleParams calldata _saleParams
    ) external override initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        offerToken = IERC20Metadata(_saleParams.offerToken);
        purchaseToken = IERC20Metadata(_saleParams.purchaseToken);
        uint8 offerDecimals = offerToken.decimals();
        uint8 purchaseDecimals = _saleParams.purchaseToken == address(0)
            ? 18
            : purchaseToken.decimals();
        offerTokenUnits = 10**offerDecimals;
        purchaseTokenUnits = 10**purchaseDecimals;

        publicStartingPrice = _saleParams.publicStartingPrice;
        publicEndingPrice = _saleParams.publicEndingPrice;
        whitelistStartingPrice = _saleParams.whitelistStartingPrice;
        whitelistEndingPrice = _saleParams.whitelistEndingPrice;

        minContributionAmount = 10**(purchaseDecimals / 2);

        require(
            address(_originationCore) != address(0),
            "Invalid origination core contract address"
        );
        require(
            _saleParams.publicSaleDuration <= MAX_SALE_DURATION,
            "Invalid sale duration"
        );
        require(
            _saleParams.whitelistSaleDuration <= MAX_SALE_DURATION,
            "Invalid whitelist sale duration"
        );
        publicSaleDuration = _saleParams.publicSaleDuration;
        whitelistSaleDuration = _saleParams.whitelistSaleDuration;
        saleDuration = whitelistSaleDuration + publicSaleDuration;

        totalOfferingAmount = _saleParams.totalOfferingAmount;
        reserveAmount = _saleParams.reserveAmount;
        vestingPeriod = _saleParams.vestingPeriod;
        cliffPeriod = _saleParams.cliffPeriod;
        originationFee = _originationFee;
        originationCore = _originationCore;

        if (_vestingEntryNFT != address(0)) {
            vestingEntryNFT = VestingEntryNFT(_vestingEntryNFT);
            vestingEntryNFT.initialize("VestingNFT", "VNFT", address(this));
        }

        _transferOwnership(_admin);
    }

    //--------------------------------------------------------------------------
    // Investor Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Whitelist purchase function
     * @dev Purchases an offer token amount with a contribution amount of purchase tokens
     * @dev If purchasing with ETH, the contribution amount must equal ETH sent
     *
     * @param merkleProof The merkle proof associated with msg.sender to prove whitelisted
     * @param contributionAmount The contribution amount in purchase tokens
     * @param maxContributionAmount The max contribution amount of the msg.sender address
     */
    function whitelistPurchase(
        bytes32[] calldata merkleProof,
        uint256 contributionAmount,
        uint256 maxContributionAmount
    ) external payable {
        require(isWhitelistMintPeriod(), "Not whitelist period");
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, maxContributionAmount)
        );
        // Verify address is whitelisted
        // Requires address and max contribution amount for that address
        require(
            MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf),
            "Address not whitelisted"
        );
        uint256 currentContribution = purchaseTokenContribution[msg.sender];
        // If contribution amount is exceeded invest as much as possible
        if (currentContribution + contributionAmount > maxContributionAmount) {
            contributionAmount = maxContributionAmount - currentContribution;
            // If user has reached his limit completely revert
            require(
                contributionAmount != 0,
                "User has reached their max contribution amount"
            );
        }

        _purchase(contributionAmount);
    }

    /**
     * @dev Purchases an offer token amount with a contribution amount of purchase tokens
     * @dev If purchasing with ETH, the contribution amount must equal ETH sent
     *
     * @param contributionAmount The contribution amount in purchase tokens
     */
    function purchase(uint256 contributionAmount) external payable {
        require(isPublicMintPeriod(), "Not public mint period");

        _purchase(contributionAmount);
    }

    function _purchase(uint256 contributionAmount) internal nonReentrant {
        require(saleInitiated, "Sale not open");
        require(block.timestamp <= saleEndTimestamp, "Sale over");
        require(
            contributionAmount >= minContributionAmount,
            "Need to contribute at least min contribution amount"
        );

        if (address(purchaseToken) == address(0)) {
            // purchase token is eth
            require(msg.value == contributionAmount);
        } else {
            purchaseToken.safeTransferFrom(
                msg.sender,
                address(this),
                contributionAmount
            );
        }

        uint256 offerTokenAmount = getCurrentMintAmount(contributionAmount);
        uint256 feeInPurchaseToken = _mulDiv(
            contributionAmount,
            originationFee,
            1e18
        );

        // Check if over the total offering amount
        if (offerTokenAmountSold + offerTokenAmount > totalOfferingAmount) {
            // Refund sender for the extra amount sent
            uint256 refundAmountInOfferTokens = offerTokenAmountSold +
                offerTokenAmount -
                totalOfferingAmount;
            uint256 refundAmount = getPurchaseAmountFromOfferAmount(
                refundAmountInOfferTokens
            );

            require(
                refundAmount < contributionAmount,
                "Refund should be smaller than contribution amount"
            );
            _returnPurchaseTokens(msg.sender, refundAmount);

            // Modify token amount, contribution amount and fee amount
            contributionAmount -= refundAmount;
            offerTokenAmount = totalOfferingAmount - offerTokenAmountSold;
            feeInPurchaseToken = _mulDiv(
                contributionAmount,
                originationFee,
                1e18
            );
        }

        // Update the sale trackers
        offerTokenAmountPurchased[msg.sender] += offerTokenAmount;
        purchaseTokenContribution[msg.sender] += contributionAmount;
        offerTokenAmountSold += offerTokenAmount;
        purchaseTokensAcquired += contributionAmount;
        originationCoreFees += feeInPurchaseToken;

        // Check if total offering amount is reached with current contribution
        if (offerTokenAmountSold == totalOfferingAmount) {
            // Indicate sale is over
            saleEndTimestamp = block.timestamp;
        }

        // Make sure offer token amount sold is not greater than the sale offering
        require(
            offerTokenAmountSold <= totalOfferingAmount,
            "Sale amount greater than offering"
        );

        if (vestingPeriod > 0) {
            _createVestingEntry(msg.sender, offerTokenAmount);
        }

        emit Purchase(
            msg.sender,
            contributionAmount,
            offerTokenAmount,
            feeInPurchaseToken
        );

        if (vestingPeriod == 0 && reserveAmount == 0) {
            // immediately distribute offer tokens
            _claimPurchasedOfferTokens(msg.sender);
        }
    }

    /**
     * @dev Private function that creates or modifies a vesting entry for the purchaser
     * @dev The function mints a nft which represents the user's vesting entry
     * @dev The NFT contains data about the purchased offer token amount and the claimed offer token amount
     * @param _sender The purchaser address
     * @param _offerTokenAmount The offer token amount purchased by the _sender address
     */
    function _createVestingEntry(address _sender, uint256 _offerTokenAmount)
        private
    {
        // Add user address to vesting id mapping
        userToVestingId[_sender] = vestingID;

        vestingEntryNFT.mint(
            _sender,
            vestingID,
            IVestingEntryNFT.VestingAmounts({
                tokenAmount: _offerTokenAmount,
                tokenAmountClaimed: 0
            })
        );

        emit CreateVestingEntry(_sender, vestingID, _offerTokenAmount);
        vestingID++;

        vestableTokenAmount += _offerTokenAmount;
    }

    /**
     * @dev Claims vesting entries
     * @dev If sale did not reach the reserve amount, the vesting entries are canceled
     * @dev Users claiming their vestings must hold the nft representing the vesting entry
     * @param _nftIds Array containing the vesting entries ids owned by the msg.sender
     */
    function claimVested(uint256[] calldata _nftIds) external nonReentrant {
        require(_nftIds.length > 0, "No vesting entry NFT id provided");
        require(
            saleEndTimestamp + cliffPeriod < block.timestamp,
            "Not past cliff period"
        );
        require(
            purchaseTokensAcquired >= reserveAmount,
            "Sale reserve amount not met"
        );

        for (uint256 i = 0; i < _nftIds.length; i++) {
            uint256 entryId = _nftIds[i];
            (uint256 tokenAmount, uint256 tokenAmountClaimed) = vestingEntryNFT
                .tokenIdVestingAmounts(entryId);
            address ownerOfEntry = vestingEntryNFT.ownerOf(entryId);
            require(ownerOfEntry == msg.sender, "User not owner of vest id");
            require(
                tokenAmount != tokenAmountClaimed,
                "User has already claimed their token vesting"
            );

            uint256 offerTokenPayout = calculateClaimableVestedAmount(
                tokenAmount,
                tokenAmountClaimed
            );
            uint256 tokenAmountRemaining = tokenAmount - tokenAmountClaimed;
            vestingEntryNFT.setVestingAmounts(
                entryId,
                tokenAmount,
                tokenAmountClaimed + offerTokenPayout
            );

            offerToken.safeTransfer(msg.sender, offerTokenPayout);
            vestableTokenAmount -= offerTokenPayout;

            emit ClaimVested(
                msg.sender,
                offerTokenPayout,
                tokenAmountRemaining
            );
        }
    }

    /**
     * @dev User callable function
     * @dev If the reserve amount was not reached, it sends back the caller's contribution in purchase tokens
     * @dev otherwise, it returns the acquired offer tokens amount to the caller
     * @dev Can only be called at the conclusion of the sale
     */
    function claimTokens() external nonReentrant {
        require(block.timestamp > saleEndTimestamp, "Sale has not ended");
        require(
            vestingPeriod != 0 || reserveAmount != 0,
            "Tokens already claimed once purchased"
        );

        if (purchaseTokensAcquired >= reserveAmount) {
            // Sale reached the reserve amount therefore send acquired offer tokens
            require(
                vestingPeriod == 0,
                "Tokens must be claimed using claimVested"
            );

            _claimPurchasedOfferTokens(msg.sender);
        } else {
            // Sale did not reach reserve amount therefore return purchase tokens
            require(
                purchaseTokenContribution[msg.sender] > 0,
                "No contribution made"
            );
            uint256 tokenAmount = purchaseTokenContribution[msg.sender];
            purchaseTokenContribution[msg.sender] = 0;
            _returnPurchaseTokens(msg.sender, tokenAmount);
            emit PurchaseTokensRetrieved(msg.sender, tokenAmount);
        }
    }

    function _claimPurchasedOfferTokens(address purchaser) internal {
        uint256 purchasedAmount = offerTokenAmountPurchased[purchaser];

        require(purchasedAmount > 0, "No purchase made");

        offerTokenAmountPurchased[purchaser] = 0;
        offerToken.safeTransfer(purchaser, purchasedAmount);
        emit TokensClaimed(purchaser, purchasedAmount);
    }

    function _returnPurchaseTokens(address purchaser, uint256 tokenAmount)
        internal
    {
        if (address(purchaseToken) == address(0)) {
            // send eth
            (bool success, ) = payable(purchaser).call{value: tokenAmount}("");
            require(success);
        } else {
            purchaseToken.safeTransfer(purchaser, tokenAmount);
        }
    }

    //--------------------------------------------------------------------------
    // View Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Calculates the amount of tokens mintable by a given purchase token amount
     *
     * @param contributionAmount The contribution amount in purchase tokens
     * @return offerTokenAmount The token amount mintable in offer tokens
     */
    function getCurrentMintAmount(uint256 contributionAmount)
        public
        view
        returns (uint256 offerTokenAmount)
    {
        uint256 offerTokenPrice = getOfferTokenPrice();

        // Convert contribution amount to Offer Tokens (contribution / price)
        offerTokenAmount = _mulDiv(
            contributionAmount,
            offerTokenUnits,
            offerTokenPrice
        );
    }

    /**
     * @dev Get purchase token amount from offer token amount
     * @param offerAmount offer token amount needed to be converted
     * @return purchaseAmount Calculated purchase token amount
     * needed to purchase the offerAmount specified as parameter
     */
    function getPurchaseAmountFromOfferAmount(uint256 offerAmount)
        public
        view
        returns (uint256 purchaseAmount)
    {
        uint256 offerTokenPrice = getOfferTokenPrice();

        purchaseAmount = _mulDiv(offerAmount, offerTokenPrice, offerTokenUnits);
    }

    /**
     * Return offer token price in purchase tokens (eth or erc-20)
     */
    function getOfferTokenPrice()
        public
        view
        returns (uint256 offerTokenPrice)
    {
        // Token sale was not initiated yet
        if (!saleInitiated) {
            return
                whitelistSaleDuration > 0
                    ? whitelistStartingPrice
                    : publicStartingPrice;
        }

        // Token sale has ended
        if (block.timestamp > saleEndTimestamp) {
            return
                publicSaleDuration > 0
                    ? publicEndingPrice
                    : whitelistEndingPrice;
        }

        bool isWhitelistPeriod = isWhitelistMintPeriod();
        uint256 offeringPeriodInitiatedTimestamp = isWhitelistPeriod
            ? saleInitiatedTimestamp
            : saleInitiatedTimestamp + whitelistSaleDuration;
        uint256 offeringPeriodDuration = isWhitelistPeriod
            ? whitelistSaleDuration
            : publicSaleDuration;

        uint256 timeElapsed = block.timestamp -
            offeringPeriodInitiatedTimestamp;
        // Whitelist mint period has different start and end prices
        uint256 _startingPrice = isWhitelistPeriod
            ? whitelistStartingPrice
            : publicStartingPrice;
        uint256 _endingPrice = isWhitelistPeriod
            ? whitelistEndingPrice
            : publicEndingPrice;

        return
            (_startingPrice *
                (offeringPeriodDuration - timeElapsed) +
                _endingPrice *
                timeElapsed) / offeringPeriodDuration;
    }

    /**
     * @dev Calculates the claimable vested offer token
     *
     * @param tokenAmount the total offer token amount available to be claimed by the caller
     * @param tokenAmountClaimed the offer token amount already claimed by the caller
     * @return claimableTokenAmount The claimable offer token amount of the total, represented by tokenAmount
     */
    function calculateClaimableVestedAmount(
        uint256 tokenAmount,
        uint256 tokenAmountClaimed
    ) public view returns (uint256 claimableTokenAmount) {
        require(
            saleEndTimestamp + cliffPeriod < block.timestamp,
            "Not past cliff period"
        );

        uint256 timeSinceInit = block.timestamp - saleEndTimestamp;

        claimableTokenAmount = timeSinceInit >= vestingPeriod
            ? tokenAmount - tokenAmountClaimed
            : ((timeSinceInit * tokenAmount) / vestingPeriod) -
                tokenAmountClaimed;
    }

    function isWhitelistMintPeriod() public view returns (bool) {
        return
            block.timestamp > saleInitiatedTimestamp &&
            block.timestamp <= (saleInitiatedTimestamp + whitelistSaleDuration);
    }

    function isPublicMintPeriod() public view returns (bool) {
        uint256 endOfWhitelistPeriod = saleInitiatedTimestamp +
            whitelistSaleDuration;
        return
            block.timestamp > endOfWhitelistPeriod &&
            block.timestamp <= (endOfWhitelistPeriod + publicSaleDuration);
    }

    /**
     * @dev Checks to see if address is an admin (owner or manager)
     *
     * @param _address The address to be verified
     * @return True if it correspons to an owner or manager, false otherwise
     */
    function isOwnerOrManager(address _address) public view returns (bool) {
        return _address == owner() || _address == manager;
    }

    //--------------------------------------------------------------------------
    // Admin Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Admin function used to initiate the sale
     * @dev The function will transfer the total offer tokens amount available to sell
     * from the admin address to this contract
     */
    function initiateSale() external onlyOwnerOrManager {
        require(!saleInitiated, "Sale already initiated");

        offerToken.safeTransferFrom(
            msg.sender,
            address(this),
            totalOfferingAmount
        );
        saleInitiated = true;
        saleInitiatedTimestamp = block.timestamp;
        saleEndTimestamp = saleInitiatedTimestamp + saleDuration;

        emit InitiateSale(totalOfferingAmount);
    }

    /**
     * @dev Admin function to claim the purchase tokens raised during the sale
     * @dev Returns unsold offer tokens or all offer tokens if reserve amount was not met
     */
    function claimPurchaseToken() external nonReentrant onlyOwnerOrManager {
        require(!sponsorTokensClaimed, "Tokens already claimed");

        if (vestingPeriod == 0 && reserveAmount == 0) {
            // purchase tokens can be claimed even if the sale has not ended
            _transferPurchaseTokenToOwner();

            // if the sale has ended
            if (block.timestamp > saleEndTimestamp) {
                // return the unsold offerTokens
                if (offerTokenAmountSold < totalOfferingAmount) {
                    offerToken.safeTransfer(
                        owner(),
                        totalOfferingAmount - offerTokenAmountSold
                    );
                }

                sponsorTokensClaimed = true;
            }

            // end execution
            return;
        }

        require(block.timestamp > saleEndTimestamp, "Sale has not ended");
        sponsorTokensClaimed = true;

        // check if reserve amount was reached
        if (purchaseTokensAcquired >= reserveAmount) {
            _transferPurchaseTokenToOwner();

            // return the unsold offerTokens
            if (offerTokenAmountSold < totalOfferingAmount) {
                offerToken.safeTransfer(
                    owner(),
                    totalOfferingAmount - offerTokenAmountSold
                );
            }
        } else {
            // return all offer tokens back to owner
            uint256 retrieveAmount = offerToken.balanceOf(address(this));
            offerToken.safeTransfer(owner(), retrieveAmount);
            emit OfferTokensRetrieved(owner(), retrieveAmount);
        }
    }

    /**
     * @dev Admin function to set a whitelist
     *
     * @param _whitelistMerkleRoot The whitelist merkle root
     */
    function setWhitelist(bytes32 _whitelistMerkleRoot)
        external
        onlyOwnerOrManager
    {
        require(!saleInitiated, "Cannot set whitelist after sale initiated");

        whitelistMerkleRoot = _whitelistMerkleRoot;
        emit WhitelistSet(_whitelistMerkleRoot);
    }

    /**
     * @dev Admin function to set a manager
     * @dev Manager has same rights as owner (except setting a manager)
     *
     * @param _manager The manager address
     */
    function setManager(address _manager) external onlyOwner {
        manager = _manager;
        emit ManagerSet(manager);
    }

    function _transferPurchaseTokenToOwner() internal {
        uint256 transferAmount;
        if (address(purchaseToken) == address(0)) {
            // purchaseToken = eth
            transferAmount = address(this).balance - originationCoreFees;
            (bool success, ) = owner().call{value: transferAmount}("");
            require(success);
            // send fees to core
            originationCore.receiveFees{value: originationCoreFees}();
            // reset accrued origination fees amount
            originationCoreFees = 0;
        } else {
            transferAmount =
                purchaseToken.balanceOf(address(this)) -
                originationCoreFees;
            purchaseToken.safeTransfer(owner(), transferAmount);
            // handle timelocked tokens
            try
                purchaseToken.transfer(
                    address(originationCore),
                    originationCoreFees
                )
            {
                // reset accrued origination fees amount
                originationCoreFees = 0;
            } catch {
                // if transfer to core fails don't reset the fee amount
                // approve tokens to origination core to be transferred
                purchaseToken.safeIncreaseAllowance(
                    address(originationCore),
                    originationCoreFees
                );
            }
        }

        emit PurchaseTokenClaim(owner(), transferAmount);
    }

    //--------------------------------------------------------------------------
    // Utils Functions
    //--------------------------------------------------------------------------

    /// @notice Calculates floor(a×b÷denominator) with full precision.
    /// @notice Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function _mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}