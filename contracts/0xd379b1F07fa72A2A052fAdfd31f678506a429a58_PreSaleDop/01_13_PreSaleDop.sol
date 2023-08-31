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

    /// @notice Thrown when address in blacklisted
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

    /// @notice Thrown when round start time is less than previous round
    error InvalidStartTime();

    /// @notice Thrown when round starttime is less than or equal to previous round
    error InvalidEndTime();

    /// @notice Thrown when new round price is less than previous round
    error PriceInvalid();

    /// @notice Thrown when updating with the same value as previously stored
    error IdenticalValue();

    /// @notice Thrown when value to trasfer is zero
    error ValueZero();

    /// @notice Thrown when startTime is incorrect when updating round
    error StartTimeIncorrect();

    /// @notice Thrown when endTime is incorrect when updating round
    error EndTimeIncorrect();

    /// @notice chainlink priceFeed contract gives live Eth/Usd price
    AggregatorV3Interface internal immutable PRICE_FEED;

    /// @notice stores index of last round created
    uint8 private _roundIndex;

    /// @notice stores multiplier to handle zeros
    uint256 private constant MULTIPLIER10 = 1e10;

    /// @notice stores multiplier to handle zeros
    uint256 private constant MULTIPLIER30 = 1e30;

    /// @notice stores buying enabled or paused
    bool public buyEnable;

    /// @notice stores claiming enabled or paused
    bool public claimEnable;

    /// @notice stores wallet address of Signer
    address public signerWallet;

    /// @notice stores wallet address from which dop will be transferred
    address public dopWallet;

    /// @notice stores contract address in which investments will be transferred
    address public claimsContract;

    /// @notice stores fundsWallet address that will collect funds
    address public fundsWallet;

    /// @notice stores USDT address
    IERC20 public immutable USDT;

    /// @notice stores dopToken token address
    IERC20 public dopToken;

    /// @member amount The dop amount user purchased
    /// @member round The round in which user purchased amount
    struct ClaimInfo {
        uint256 amount;
        uint8 round;
    }

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
    mapping(address => mapping(uint8 => ClaimInfo)) public claims;

    /// @notice mapping gives info about address's permission
    mapping(address => bool) public blacklistAddress;

    /* ========== EVENTS ========== */
    event InvestedWithEth(
        address indexed by,
        string code,
        uint256 amountInvestedEth,
        uint8 indexed round,
        uint256 price,
        uint256 dopPurchased
    );
    event InvestedWithUSDT(
        address indexed by,
        string code,
        uint256 amountInUsd,
        uint8 indexed round,
        uint256 price,
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
    event fundsWalletUpdated(address oldAddress, address newAddress);
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
    /// @param pricefeed The address of chainlink pricefeed contract
    /// @param signerAddress The address of signer wallet
    /// @param dopAddress The address of Dop token
    /// @param usdt The address of usdt contract
    constructor(
        AggregatorV3Interface pricefeed,
        address fundsWalletAddress,
        address signerAddress,
        address dopAddress,
        address claimsContractAddress,
        IERC20 usdt
    ) {
        if (
            address(pricefeed) == address(0) ||
            fundsWalletAddress == address(0) ||
            signerAddress == address(0) ||
            dopAddress == address(0) ||
            claimsContractAddress == address(0) ||
            address(usdt) == address(0)
        ) {
            revert ZeroAddress();
        }
        PRICE_FEED = AggregatorV3Interface(pricefeed);
        buyEnable = true;
        fundsWallet = fundsWalletAddress;
        signerWallet = signerAddress;
        dopWallet = dopAddress;
        claimsContract = claimsContractAddress;
        USDT = usdt;
    }

    ///@notice Creates new round and set time and price in that round
    ///@param startTime The startTime of the round
    ///@param endTime The endTime of the round
    ///@param price The dop token price in the round
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

    /// @notice Updates startTime, endTime or price of existing round
    /// @param round The round that will be updated
    /// @param startTime The startTime of round, can be changed or remains unchaged
    /// @param endTime The endTime of round, can be changed or remains unchaged
    /// @param price The price of round, can be changed or remains unchaged
    function updateRound(
        uint8 round,
        uint256 startTime,
        uint256 endTime,
        uint256 price
    ) external onlyOwner {
        if (round == 0 || round > _roundIndex) {
            revert RoundIncorrect();
        }
        if (startTime < rounds[round - 1].endTime) {
            revert StartTimeIncorrect();
        }

        if (round != _roundIndex && endTime > rounds[round + 1].startTime) {
            revert EndTimeIncorrect();
        }
        _verifyRound(startTime, endTime, price);
        rounds[round] = RoundData({
            startTime: startTime,
            endTime: endTime,
            price: price
        });

        emit RoundUpdated({round: round, roundData: rounds[round]});
    }

    /// @notice Enables or disables purchasing. In the disable state all the contract interactions
    /// are suspended.
    /// @param enabled True if buying needs to be enabled, false otherwise
    function enableBuy(bool enabled) external onlyOwner {
        if (buyEnable == enabled) {
            revert IdenticalValue();
        }
        emit BuyEnableUpdated({oldAccess: buyEnable, newAccess: enabled});
        buyEnable = enabled;
    }

    /// @notice Enables or disable claiming. In the disable state all the contract interactions
    /// are suspended.
    /// @param enabled True if claiming needs to be enabled, false otherwise
    function enableClaim(bool enabled) external onlyOwner {
        if (claimEnable == enabled) {
            revert IdenticalValue();
        }
        emit ClaimEnableUpdated({oldAccess: claimEnable, newAccess: enabled});
        claimEnable = enabled;
    }

    /// @notice Changes signer wallet to a new address
    /// @param newSigner The new Signer wallet address
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

    /// @notice Changes fundsWallet to a new address
    /// @param newFundsWallet The new Signer wallet address
    function changeFundsWallet(
        address newFundsWallet
    ) external checkZeroAddress(newFundsWallet) onlyOwner {
        address oldWallet = fundsWallet;
        if (oldWallet == newFundsWallet) {
            revert IdenticalValue();
        }
        emit fundsWalletUpdated({
            oldAddress: oldWallet,
            newAddress: newFundsWallet
        });
        fundsWallet = newFundsWallet;
    }

    /// @notice Changes Dop wallet to a new address
    ///@dev dopWallet transfers Dop tokens to all the investors when claim.
    /// @param newDopWallet The new dop wallet address
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

    /// @notice Changes dop token address to a new address
    /// @param newDopAddress The new dop token address
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

    /// @notice Changes the access of address to true or false, When true , user's contract
    /// interactions will be suspended
    /// @param which The address which will be blacklisted to true or false
    /// @param access The access decision for the which address
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

    /// @notice Users will purchase dop tokens by paying Eth, only when buyEnable
    /// @param code The code that is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param deadline The deadline is validity of the signature
    /// @param minAmountDop The minAmountDop user agrees to purchase
    /// @param v The `v` signature parameter of the sign generated by signerWallet
    /// @param r The `r` signature parameter of the sign generated by signerWallet
    /// @param s The `s` signature parameter of the sign generated by signerWallet
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
        /// note that we don't expect such large msg.value `or `getLatestPriceEth() value such that this multiplication overflows and reverts.
        RoundData memory dataRound = rounds[round];

        uint256 toReturn = ((msg.value * getLatestPriceEth()) * MULTIPLIER10) /
            (dataRound.price);
        if (toReturn < minAmountDop) {
            revert UnexpectedPriceDifference();
        }
        claims[msg.sender][round] = ClaimInfo({
            amount: toReturn + claims[msg.sender][round].amount,
            round: round
        });
        uint256 claimContractAmount = (msg.value * 25) / 100;
        payable(claimsContract).sendValue(claimContractAmount);
        payable(fundsWallet).sendValue(msg.value - claimContractAmount);
        emit InvestedWithEth({
            by: msg.sender,
            code: code,
            amountInvestedEth: msg.value,
            round: round,
            price: dataRound.price,
            dopPurchased: toReturn
        });
    }

    function _verifyInRound(uint8 round) internal view {
        RoundData memory dataRound = rounds[round];
        if (block.timestamp < dataRound.startTime) {
            revert RoundNotStarted();
        }
        if (block.timestamp >= dataRound.endTime) {
            revert RoundEnded();
        }
    }

    /// @notice Users will purchase dop tokens by paying Usd, only when buyEnable
    /// @param investment The investment is the amount user invests
    /// @param code The code that is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter of the sign generated by signerWallet
    /// @param r The `r` signature parameter of the sign generated by signerWallet
    /// @param s The `s` signature parameter of the sign generated by signerWallet
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
        /// note that we don't expect such large msg.value `or `getLatestPriceEth() value such that this multiplication overflows and reverts.
        uint256 toReturn = (investment * MULTIPLIER30) / (dataRound.price);
        uint256 oldAmount = claims[msg.sender][round].amount;
        claims[msg.sender][round] = ClaimInfo({
            amount: toReturn + oldAmount,
            round: round
        });
        uint256 claimContractAmount = (investment * 25) / 100;
        USDT.safeTransferFrom(msg.sender, claimsContract, claimContractAmount);
        USDT.safeTransferFrom(
            msg.sender,
            fundsWallet,
            investment - claimContractAmount
        );
        emit InvestedWithUSDT({
            by: msg.sender,
            code: code,
            amountInUsd: investment,
            round: round,
            price: dataRound.price,
            dopPurchased: toReturn
        });
    }

    /// @notice Checks value, if zero then reverts
    function _checkValue(uint256 value) internal pure {
        if (value == 0) {
            revert ValueZero();
        }
    }

    /// @notice Users will claim their tokens, only when claimEnable
    /// @param round The round in which user has invested and wants to claim
    function claimTokens(
        uint8 round
    ) external notBlacklisted(msg.sender) canClaim {
        ClaimInfo memory claim = claims[msg.sender][round];
        _checkValue(claim.amount);
        delete claims[msg.sender][round];
        dopToken.safeTransferFrom(dopWallet, msg.sender, claim.amount);

        emit Claimed({by: msg.sender, amount: claim.amount, round: round});
    }

    /// @notice Users will claim their tokens when invested in more than one round, only when claimEnable
    /// @param roundsBatch The roundsBatch is multiple rounds in which user purchased
    function claimTokensBatch(
        uint8[] calldata roundsBatch
    ) external notBlacklisted(msg.sender) canClaim {
        uint256 totalAmount;

        for (uint256 i = 0; i < roundsBatch.length; i = uncheckedInc(i)) {
            uint256 amount = claims[msg.sender][roundsBatch[i]].amount;
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

    /// @notice The helper function which verifies signature, signed by signerWallet, reverts if invalidSignature
    /// @param code The code that is used to verify signature of the user
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter of the sign generated by signerWallet
    /// @param r The `r` signature parameter of the sign generated by signerWallet
    /// @param s The `s` signature parameter of the sign generated by signerWallet
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

    /// @notice Gives total count of rounds created
    /// @return returns Round count
    function getRoundCount() external view returns (uint8) {
        return _roundIndex;
    }
}