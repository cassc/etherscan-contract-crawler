// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Utils} from "./Utils.sol";

interface IDopNft {
    function mintBatch(
        address recipient,
        uint256 count,
        uint256 nftType,
        uint256 dopAmount
    ) external;
}

/// @title PreSaleDopNFT contract
/// @author Dop
/// @notice Implements the preSale of Dop Token
/// @dev The presale contract allows you to purchase dop token with NFTs

contract PreSaleDopNFT is Ownable, Utils {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Thrown when address is blacklisted
    error Blacklisted();

    /// @notice Thrown when updating an address with zero address
    error ZeroAddress();

    /// @notice Thrown when buy is disabled
    error BuyNotEnable();

    /// @notice Thrown when claim is disabled
    error ClaimNotEnable();

    /// @notice Thrown when sign deadline is expired
    error DeadlineExpired();

    /// @notice Thrown when round time is not started
    error RoundNotStarted();

    /// @notice Thrown when round time is ended
    error RoundEnded();

    /// @notice Thrown when Sign is invalid
    error InvalidSignature();

    /// @notice Thrown when Round is not created
    error RoundIncorrect();

    /// @notice Thrown when new round price is less than previous round price
    error PriceLessThanOldRound();

    /// @notice Thrown when round start time is invalid
    error InvalidStartTime();

    /// @notice Thrown when round end time is invalid
    error InvalidEndTime();

    /// @notice Thrown when new price is invalid
    error PriceInvalid();

    /// @notice Thrown when updating with the same value as previously stored
    error IdenticalValue();

    /// @notice Thrown when value is zero
    error ValueZero();

    /// @notice Thrown when startTime is incorrect when updating round
    error StartTimeIncorrect();

    /// @notice Thrown when endTime is incorrect when updating round
    error EndTimeIncorrect();

    /// @notice Thrown when round price is greater than next round while updating
    error PriceGreaterThanNextRound();

    /// @notice Thrown investment is less than nft prices combined
    error InvalidInvestment();

    /// @notice Thrown Pricing is set with array with no arguments
    error ZeroLengthArray();

    /// @notice Thrown Indexes Array length mismatch
    error ArrayLengthMismatch();

    /// @notice Returns the round index of last round created
    uint8 private immutable _startRound;

    /// @notice Returns the Count of rounds created
    uint8 private _roundIndex;

    /// @notice Returns the multiplier to handle zeros
    uint256 private constant MULTIPLIER20 = 1e20;

    /// @notice Returns the multiplier to handle zeros
    uint256 private constant MULTIPLIER30 = 1e30;

    /// @notice Returns that BuyEnable or not
    bool public buyEnable = true;

    /// @notice Returns that claimEnable or not
    bool public claimEnable;

    /// @notice Returns the address of signerWallet
    address public signerWallet;

    /// @notice Returns the address of fundsWallet
    address public fundsWallet;

    /// @notice Returns the array of prices of each nft
    uint256[] public pricing;

    /// @notice Returns the dopNft address
    IDopNft public dopNft;

    /// @notice Returns the USDT address
    IERC20 public immutable USDT;

    /// @notice Returns the chainlink PriceFeed contract address
    AggregatorV3Interface internal immutable PRICE_FEED;

    /// @member startTime The start time of round
    /// @member endTime The end time of round
    /// @member price The price in usd per dop
    struct RoundData {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    /// @notice mapping gives Round Data of each round
    mapping(uint8 => RoundData) public rounds;

    /// @notice mapping gives claim info of user nft in every round
    mapping(address => mapping(uint8 => uint256[])) public claim;

    /// @notice mapping gives info about address's permission
    mapping(address => bool) public blacklistAddress;

    /* ========== EVENTS ========== */

    event InvestedWithEthForNFT(
        address indexed by,
        string code,
        uint256 amountInEth,
        uint8 indexed round,
        uint256[] nftAmounts
    );
    event InvestedWithUSDTForNFT(
        address indexed by,
        string code,
        uint256 amountInUsd,
        uint8 indexed round,
        uint256[] nftAmounts
    );
    event NFTsClaimed(
        address indexed by,
        uint256[] nftAmounts,
        uint8 indexed round,
        uint256 roundPrice,
        uint256[] dopAmount
    );
    event PricingUpdated(uint256[] oldPricing, uint256[] newPricing);
    event SignerUpdated(address oldSigner, address newSigner);
    event DopNFTUpdated(address oldDopNFT, address newDopNFT);
    event FundsWalletUpdated(address oldAddress, address newAddress);
    event BlacklistUpdated(address which, bool accessNow);
    event RoundCreated(uint8 newRound, RoundData roundData);
    event RoundUpdated(uint8 round, RoundData roundData);
    event BuyEnableUpdated(bool oldAccess, bool newAccess);
    event ClaimEnableUpdated(bool oldAccess, bool newAccess);

    /* ========== MODIFIERS ========== */

    /// @notice restricts when updating wallet/contract address to zero address
    modifier checkZeroAddress(address which) {
        if (which == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @notice ensures that buy is enabled when buying
    modifier canBuy() {
        if (!buyEnable) {
            revert BuyNotEnable();
        }
        _;
    }

    /// @notice ensures that claim is enabled when claiming
    modifier canClaim() {
        if (!claimEnable) {
            revert ClaimNotEnable();
        }
        _;
    }

    /// @dev Constructor.
    /// @param priceFeed The address of chainlink pricefeed contract
    /// @param fundsWalletAddress The address of funds wallet
    /// @param signerAddress The address of signer wallet
    /// @param usdt The address of usdt contract
    /// @param lastRound The last round created
    constructor(
        AggregatorV3Interface priceFeed,
        address fundsWalletAddress,
        address signerAddress,
        IERC20 usdt,
        uint8 lastRound,
        uint256[] memory prices
    ) {
        if (
            address(priceFeed) == address(0) ||
            fundsWalletAddress == address(0) ||
            signerAddress == address(0) ||
            address(usdt) == address(0)
        ) {
            revert ZeroAddress();
        }
        PRICE_FEED = AggregatorV3Interface(priceFeed);
        fundsWallet = fundsWalletAddress;
        signerWallet = signerAddress;
        USDT = usdt;
        _startRound = lastRound;
        _roundIndex = lastRound;
        if (prices.length == 0) {
            revert ZeroLengthArray();
        }
        for (uint256 i = 0; i < prices.length; i = uncheckedInc(i)) {
            _checkValue(prices[i]);
        }
        pricing = prices;
    }

    /// @notice Creates a new Round
    /// @param startTime The startTime of the round
    /// @param endTime The endTime of the round
    /// @param price The dopToken price in the round
    function createNewRound(
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyOwner {
        RoundData memory roundData = rounds[_roundIndex];
        uint8 newRound = ++_roundIndex;
        if (price < roundData.price) {
            revert PriceLessThanOldRound();
        }
        if (startTime < roundData.endTime) {
            revert InvalidStartTime();
        }
        _verifyRound(startTime, endTime, price);
        roundData = RoundData({
            startTime: startTime,
            endTime: endTime,
            price: price
        });
        rounds[newRound] = roundData;
        emit RoundCreated({newRound: newRound, roundData: roundData});
    }

    /// @notice Updates round data
    /// @param round The Round that will be updated
    /// @param startTime The StartTime of the round
    /// @param endTime The EndTime of the round
    /// @param price The price of the round
    function updateRound(
        uint8 round,
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyOwner {
        if (round <= _startRound || round > _roundIndex) {
            revert RoundIncorrect();
        }
        RoundData memory roundPrevious = rounds[round - 1];
        RoundData memory roundNext = rounds[round + 1];
        if (startTime < roundPrevious.endTime) {
            revert StartTimeIncorrect();
        }
        if (round != _roundIndex && endTime > roundNext.startTime) {
            revert EndTimeIncorrect();
        }
        if (price < roundPrevious.price) {
            revert PriceLessThanOldRound();
        }
        if (round != _roundIndex && price > roundNext.price) {
            revert PriceGreaterThanNextRound();
        }
        _verifyRound(startTime, endTime, price);
        rounds[round] = RoundData({
            startTime: startTime,
            endTime: endTime,
            price: price
        });
        emit RoundUpdated({round: round, roundData: rounds[round]});
    }

    /// @notice Changes access of buying
    /// @param enabled The decision about buying
    function enableBuy(bool enabled) external onlyOwner {
        if (buyEnable == enabled) {
            revert IdenticalValue();
        }
        emit BuyEnableUpdated({oldAccess: buyEnable, newAccess: enabled});
        buyEnable = enabled;
    }

    /// @notice Changes access of claiming
    /// @param enabled The decision about claiming
    function enableClaim(bool enabled) external onlyOwner {
        if (claimEnable == enabled) {
            revert IdenticalValue();
        }
        emit ClaimEnableUpdated({oldAccess: claimEnable, newAccess: enabled});
        claimEnable = enabled;
    }

    /// @notice Changes signer wallet address
    /// @param newSigner The address of the new signer wallet
    function changeSigner(
        address newSigner
    ) external checkZeroAddress(newSigner) onlyOwner {
        address oldSigner = signerWallet;
        if (oldSigner == newSigner) {
            revert IdenticalValue();
        }
        emit SignerUpdated({oldSigner: oldSigner, newSigner: newSigner});
        signerWallet = newSigner;
    }

    /// @notice Changes funds wallet to a new address
    /// @param newFundsWallet The address of the new funds wallet
    function changeFundsWallet(
        address newFundsWallet
    ) external checkZeroAddress(newFundsWallet) onlyOwner {
        address oldWallet = fundsWallet;
        if (oldWallet == newFundsWallet) {
            revert IdenticalValue();
        }
        emit FundsWalletUpdated({
            oldAddress: oldWallet,
            newAddress: newFundsWallet
        });
        fundsWallet = newFundsWallet;
    }

    /// @notice Changes dop NFT contract to a new address
    /// @param newDopNFT The address of the new dop NFT contract
    function updateDopNFT(
        IDopNft newDopNFT
    ) external checkZeroAddress(address(newDopNFT)) onlyOwner {
        IDopNft oldDopNft = dopNft;
        if (oldDopNft == newDopNFT) {
            revert IdenticalValue();
        }
        emit DopNFTUpdated({
            oldDopNFT: address(oldDopNft),
            newDopNFT: address(newDopNFT)
        });
        dopNft = newDopNFT;
    }

    /// @notice Changes the access of any address in contract interaction
    /// @param which The address for which access is updated
    /// @param access The access decision of `which` address
    function updateBlackListedUser(
        address which,
        bool access
    ) external checkZeroAddress(which) onlyOwner {
        bool oldAccess = blacklistAddress[which];
        if (oldAccess == access) {
            revert IdenticalValue();
        }
        emit BlacklistUpdated({which: which, accessNow: access});
        blacklistAddress[which] = access;
    }

    /// @notice Changes the access of any address in contract interaction
    /// @param newPrices The new prices of NFTs
    function updatePricing(uint256[] memory newPrices) external onlyOwner {
        uint256[] memory oldPrices = pricing;
        if (newPrices.length != oldPrices.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i = 0; i < newPrices.length; i = uncheckedInc(i)) {
            _checkValue(newPrices[i]);
        }
        emit PricingUpdated({oldPricing: oldPrices, newPricing: newPrices});
        pricing = newPrices;
    }

    /// @notice Purchases NFT with Eth
    /// @param code The code is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param nftAmounts The nftAmounts is array of nfts selected
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseNFTWithEth(
        string memory code,
        uint8 round,
        uint256[] calldata nftAmounts,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable canBuy {
        uint256[] memory prices = pricing;
        _checkValue(msg.value);
        _validatePurchaseNFT(
            deadline,
            nftAmounts.length,
            prices.length,
            round,
            code,
            v,
            r,
            s
        );
        uint256 value = _processPurchaseNFT(round, nftAmounts, prices, true);
        if (msg.value < value) {
            revert InvalidInvestment();
        }
        _checkValue(value);
        uint256 amountUnused = msg.value - value;
        if (amountUnused > 0) {
            payable(msg.sender).sendValue(amountUnused);
        }
        payable(fundsWallet).sendValue(value);
        emit InvestedWithEthForNFT({
            by: msg.sender,
            code: code,
            amountInEth: value,
            round: round,
            nftAmounts: nftAmounts
        });
    }

    /// @notice Purchases NFT with Usdt token
    /// @param code The code is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param nftAmounts The nftAmounts is array of nfts selected
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseNFTWithUsdt(
        string memory code,
        uint8 round,
        uint256[] calldata nftAmounts,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external canBuy {
        uint256[] memory prices = pricing;
        _validatePurchaseNFT(
            deadline,
            nftAmounts.length,
            prices.length,
            round,
            code,
            v,
            r,
            s
        );
        uint256 value = _processPurchaseNFT(round, nftAmounts, prices, false);
        _checkValue(value);
        USDT.safeTransferFrom(msg.sender, fundsWallet, value);
        emit InvestedWithUSDTForNFT({
            by: msg.sender,
            code: code,
            amountInUsd: value,
            round: round,
            nftAmounts: nftAmounts
        });
    }

    /// @notice Claims all NFTs purchased
    /// @param round The round in which you want to claim NFT
    function claimNFT(uint8 round) external canClaim {
        _checkBlacklist(msg.sender);
        uint256[] memory nftsClaims = claim[msg.sender][round];
        uint256[] memory prices = pricing;
        uint256 roundPrice = rounds[round].price;
        if (round > _roundIndex || round < _startRound + 1) {
            revert RoundIncorrect();
        }
        delete claim[msg.sender][round];
        uint256[] memory dopAmount = new uint256[](nftsClaims.length);
        for (uint256 i = 0; i < nftsClaims.length; i = uncheckedInc(i)) {
            if (nftsClaims[i] > 0) {
                uint256 amount = (prices[i] * nftsClaims[i] * MULTIPLIER30) /
                    roundPrice;
                dopNft.mintBatch(msg.sender, nftsClaims[i], i, amount);
                dopAmount[i] = amount;
            }
        }
        emit NFTsClaimed({
            by: msg.sender,
            nftAmounts: nftsClaims,
            round: round,
            roundPrice: roundPrice,
            dopAmount: dopAmount
        });
    }

    /// @notice The chainlink inherited function, gives ETH/USD live price
    function getLatestPriceEth() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int price /*uint256 startedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = /*uint256 timeStamp*/ PRICE_FEED.latestRoundData();

        return uint256(price); // returns value 8 decimals
    }

    /// @notice Returns total rounds created
    /// @return The Round count
    function getRoundCount() external view returns (uint8) {
        return _roundIndex;
    }

    /// @notice Returns claim count of NFTs in given round
    /// @return The array of NFTs count
    function getClaim(
        address user,
        uint8 round
    ) external view returns (uint256[] memory) {
        return claim[user][round];
    }

    /// @notice The helper function which verifies signature, signed by signerWallet, reverts if invalidSignature
    function _verifyCode(
        string memory code,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 encodedMessageHash = keccak256(
            abi.encodePacked(msg.sender, code, deadline)
        );
        if (
            signerWallet !=
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(encodedMessageHash),
                v,
                r,
                s
            )
        ) {
            revert InvalidSignature();
        }
    }

    /// @notice Checks value, if zero then reverts
    function _checkValue(uint256 value) internal pure {
        if (value == 0) {
            revert ValueZero();
        }
    }

    /// @notice Checks round start and end time, reverts if Invalid
    function _verifyInRound(uint8 round) internal view {
        RoundData memory dataRound = rounds[round];
        if (block.timestamp < dataRound.startTime) {
            revert RoundNotStarted();
        }
        if (block.timestamp >= dataRound.endTime) {
            revert RoundEnded();
        }
    }

    /// @notice checks the validity of startTime, endTime and price
    function _verifyRound(
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) internal view {
        if (startTime < block.timestamp) {
            revert InvalidStartTime();
        }
        if (endTime <= startTime) {
            revert InvalidEndTime();
        }
        if (price == 0) {
            revert PriceInvalid();
        }
    }

    /// @notice checks the validity of deadline, array length, round, and signature
    function _validatePurchaseNFT(
        uint256 deadline,
        uint256 nftAmountsLength,
        uint256 pricesLength,
        uint8 round,
        string memory code,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        _checkBlacklist(msg.sender);

        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
        if (nftAmountsLength != pricesLength) {
            revert ArrayLengthMismatch();
        }
        _verifyInRound(round);
        _verifyCode(code, deadline, v, r, s);
    }

    /// @notice process nft purchase by calculating nft prices and investment amount
    function _processPurchaseNFT(
        uint8 round,
        uint256[] calldata nftAmounts,
        uint256[] memory prices,
        bool isEth
    ) internal returns (uint256) {
        uint256[] memory amounts = claim[msg.sender][round];
        if (amounts.length == 0) {
            amounts = new uint256[](prices.length);
        }
        uint256 value = 0;
        uint256 ethPrice = getLatestPriceEth();
        for (uint256 i = 0; i < prices.length; i = uncheckedInc(i)) {
            isEth
                ? value += (nftAmounts[i] * MULTIPLIER20 * prices[i]) / ethPrice
                : value += nftAmounts[i] * prices[i];
            amounts[i] += nftAmounts[i];
        }
        claim[msg.sender][round] = amounts;
        return value;
    }

    /// @notice checks that address is blacklisted or not
    function _checkBlacklist(address which) internal view {
        if (blacklistAddress[which]) {
            revert Blacklisted();
        }
    }
}