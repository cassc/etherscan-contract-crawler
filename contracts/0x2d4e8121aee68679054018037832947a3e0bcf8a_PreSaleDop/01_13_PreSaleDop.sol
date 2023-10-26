// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Utils} from "./Utils.sol";

/// @title PreSaleDop contract
/// @author Dop
/// @notice Implements the preSale of Dop Token
/// @dev The presale contract allows you to purchase dop token with ETH and USD, and there will be certain rounds, user will be able to claim tokens after completion of all rounds

contract PreSaleDop is Ownable, Utils {
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

    /// @notice Thrown when Eth price suddenly drops while purchasing with ETH
    error UnexpectedPriceDifference();

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

    /// @notice Thrown when value to transfer is zero
    error ValueZero();

    /// @notice Thrown when startTime is incorrect when updating round
    error StartTimeIncorrect();

    /// @notice Thrown when endTime is incorrect when updating round
    error EndTimeIncorrect();

    /// @notice Thrown when round price is greater than next round while updating
    error PriceGreaterThanNextRound();

    /// @notice Thrown when caller is not claimsContract
    error OnlyClaimsContract();

    /// @notice Returns the chainlink PriceFeed contract address
    AggregatorV3Interface internal immutable PRICE_FEED;

    /// @notice Returns the round index of last round created
    uint8 private immutable _startRound;

    /// @notice Returns the Count of rounds created
    uint8 private _roundIndex;

    /// @notice Returns the multiplier to handle zeros
    uint256 private constant MULTIPLIER10 = 1e10;

    /// @notice Returns the multiplier to handle zeros
    uint256 private constant MULTIPLIER30 = 1e30;

    /// @notice Returns that BuyEnable or not
    bool public buyEnable;

    /// @notice Returns that claimEnable or not
    bool public claimEnable;

    /// @notice Returns the address of signerWallet
    address public signerWallet;

    /// @notice Returns the address of DopWallet
    address public dopWallet;

    /// @notice Returns the address of claimsContract
    address public claimsContract;

    /// @notice Returns the address of fundsWallet
    address public fundsWallet;

    /// @notice Returns the USDT address
    IERC20 public immutable USDT;

    /// @notice Returns the dopToken address
    IERC20 public dopToken;

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

    /// @notice mapping gives claim info of user in every round
    mapping(address => mapping(uint8 => uint256)) public claims;

    /// @notice mapping gives info about address's permission
    mapping(address => bool) public blacklistAddress;

    /* ========== EVENTS ========== */

    event InvestedWithEth(
        address indexed by,
        string code,
        uint256 amountInvestedEth,
        uint8 indexed round,
        uint256 indexed price,
        uint256 dopPurchased
    );
    event InvestedWithUSDT(
        address indexed by,
        string code,
        uint256 amountInUsd,
        uint8 indexed round,
        uint256 indexed price,
        uint256 dopPurchased
    );
    event InvestedWithClaimAmount(
        address indexed by,
        uint256 amountEth,
        uint256 amountUsd,
        uint8 indexed round,
        uint256 indexed price,
        uint256 dopPurchased
    );
    event Claimed(address indexed by, uint256 amount, uint8 indexed round);
    event ClaimedBatch(
        address indexed by,
        uint256 amount,
        uint8[] indexed rounds
    );
    event SignerUpdated(address oldSigner, address newSigner);
    event DopWalletUpdated(address oldAddress, address newAddress);
    event DopTokenUpdated(address oldDopAddress, address newDopAddress);
    event FundsWalletUpdated(address oldAddress, address newAddress);
    event BlacklistUpdated(address which, bool accessNow);
    event RoundCreated(uint8 newRound, RoundData roundData);
    event RoundUpdated(uint8 round, RoundData roundData);
    event BuyEnableUpdated(bool oldAccess, bool newAccess);
    event ClaimEnableUpdated(bool oldAccess, bool newAccess);

    /* ========== MODIFIERS ========== */

    /// @notice restricts blacklisted addresses
    modifier notBlacklisted(address which) {
        if (blacklistAddress[which]) {
            revert Blacklisted();
        }
        _;
    }

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
    /// @param priceFeed The address of chainlink price feed contract
    /// @param fundsWalletAddress The address of funds wallet
    /// @param signerAddress The address of signer wallet
    /// @param dopAddress The address of Dop token
    /// @param claimsContractAddress The address of claim contract
    /// @param usdt The address of usdt contract
    /// @param lastRound The last round created
    constructor(
        AggregatorV3Interface priceFeed,
        address fundsWalletAddress,
        address signerAddress,
        address dopAddress,
        address claimsContractAddress,
        IERC20 usdt,
        uint8 lastRound
    ) {
        if (
            address(priceFeed) == address(0) ||
            fundsWalletAddress == address(0) ||
            signerAddress == address(0) ||
            dopAddress == address(0) ||
            claimsContractAddress == address(0) ||
            address(usdt) == address(0)
        ) {
            revert ZeroAddress();
        }
        PRICE_FEED = AggregatorV3Interface(priceFeed);
        buyEnable = true;
        fundsWallet = fundsWalletAddress;
        signerWallet = signerAddress;
        dopWallet = dopAddress;
        claimsContract = claimsContractAddress;
        USDT = usdt;
        _startRound = lastRound;
        _roundIndex = lastRound;
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

    /// @notice Changes dop wallet to a new address
    /// @param newDopWallet The address of the new dop wallet
    function changeDopWallet(
        address newDopWallet
    ) external checkZeroAddress(newDopWallet) onlyOwner {
        address dopWalletOld = dopWallet;
        if (dopWalletOld == newDopWallet) {
            revert IdenticalValue();
        }
        emit DopWalletUpdated({
            oldAddress: dopWalletOld,
            newAddress: newDopWallet
        });
        dopWallet = newDopWallet;
    }

    /// @notice Changes dop token contract to a new address
    /// @param newDopAddress The address of the new dop token
    function updateDopToken(
        IERC20 newDopAddress
    ) external checkZeroAddress(address(newDopAddress)) onlyOwner {
        IERC20 oldDop = dopToken;
        if (oldDop == newDopAddress) {
            revert IdenticalValue();
        }
        emit DopTokenUpdated({
            oldDopAddress: address(oldDop),
            newDopAddress: address(newDopAddress)
        });
        dopToken = newDopAddress;
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

    /// @notice Purchases dopToken with Eth
    /// @param code The code is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param minAmountDop The minAmountDop user agrees to purchase
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseWithEth(
        string memory code,
        uint8 round,
        uint256 deadline,
        uint256 minAmountDop,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable notBlacklisted(msg.sender) canBuy {
        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
        _verifyInRound(round);
        _checkValue(msg.value);
        _verifyCode(code, deadline, v, r, s);
        uint256 roundPrice = rounds[round].price;
        // we don't expect such large msg.value `or `getLatestPriceEth() value such that this multiplication overflows and reverts.
        uint256 toReturn = ((msg.value * getLatestPriceEth()) * MULTIPLIER10) /
            (roundPrice);
        if (toReturn < minAmountDop) {
            revert UnexpectedPriceDifference();
        }
        _updateDopPurchased(msg.sender, round, toReturn);
        payable(fundsWallet).sendValue(msg.value);
        emit InvestedWithEth({
            by: msg.sender,
            code: code,
            amountInvestedEth: msg.value,
            round: round,
            price: roundPrice,
            dopPurchased: toReturn
        });
    }

    /// @notice Purchases dopToken with Usdt token
    /// @param investment The Investment amount
    /// @param code The code is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseWithUsdt(
        uint256 investment,
        string memory code,
        uint8 round,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external notBlacklisted(msg.sender) canBuy {
        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
        _verifyInRound(round);
        _checkValue(investment);
        _verifyCode(code, deadline, v, r, s);
        RoundData memory dataRound = rounds[round];
        // we don't expect such large value such that this multiplication overflows and reverts.
        uint256 toReturn = (investment * MULTIPLIER30) / (dataRound.price);
        _updateDopPurchased(msg.sender, round, toReturn);
        USDT.safeTransferFrom(msg.sender, fundsWallet, investment);
        emit InvestedWithUSDT({
            by: msg.sender,
            code: code,
            amountInUsd: investment,
            round: round,
            price: dataRound.price,
            dopPurchased: toReturn
        });
    }

    function purchaseWithClaim(
        address recipient,
        uint8 round,
        uint256 amountUsd
    ) external payable notBlacklisted(recipient) canBuy {
        if (msg.sender != claimsContract) {
            revert OnlyClaimsContract();
        }
        RoundData memory dataRound = rounds[round];
        uint256 dopPurchasedWithEth;
        uint256 dopPurchasedWithUsd;
        if (msg.value > 0) {
            dopPurchasedWithEth =
                ((msg.value * getLatestPriceEth()) * MULTIPLIER10) /
                (dataRound.price);
        }
        if (amountUsd > 0) {
            dopPurchasedWithUsd =
                (amountUsd * MULTIPLIER30) /
                (dataRound.price);
        }
        _updateDopPurchased(
            recipient,
            round,
            (dopPurchasedWithEth + dopPurchasedWithUsd)
        );
        payable(fundsWallet).sendValue(msg.value);
        USDT.safeTransferFrom(claimsContract, fundsWallet, amountUsd);
        emit InvestedWithClaimAmount({
            by: recipient,
            amountEth: msg.value,
            amountUsd: amountUsd,
            round: round,
            price: dataRound.price,
            dopPurchased: dopPurchasedWithEth + dopPurchasedWithUsd
        });
    }

    /// @notice Claim dopToken purchased in a round
    /// @param round The round in which user want to claim
    function claimTokens(
        uint8 round
    ) external notBlacklisted(msg.sender) canClaim {
        uint amountClaim = claims[msg.sender][round];
        _checkValue(amountClaim);
        delete claims[msg.sender][round];
        dopToken.safeTransferFrom(dopWallet, msg.sender, amountClaim);
        emit Claimed({by: msg.sender, amount: amountClaim, round: round});
    }

    /// @notice Users will claim their tokens when invested in more than one round, only when claimEnable
    /// @param roundsBatch The roundsBatch is multiple rounds in which user purchased
    function claimTokensBatch(
        uint8[] calldata roundsBatch
    ) external notBlacklisted(msg.sender) canClaim {
        uint256 totalAmount;
        for (uint256 i = 0; i < roundsBatch.length; i = uncheckedInc(i)) {
            uint256 amount = claims[msg.sender][roundsBatch[i]];
            if (amount > 0) {
                delete claims[msg.sender][roundsBatch[i]];
                totalAmount += amount;
            }
        }
        if (totalAmount > 0) {
            dopToken.safeTransferFrom(dopWallet, msg.sender, totalAmount);
            emit ClaimedBatch({
                by: msg.sender,
                amount: totalAmount,
                rounds: roundsBatch
            });
        }
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

    /// @notice Updates dop purchased in the contract
    function _updateDopPurchased(
        address recipient,
        uint8 round,
        uint256 amount
    ) internal {
        claims[recipient][round] += amount;
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
}