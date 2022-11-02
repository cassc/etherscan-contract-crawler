// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/Whitelist.sol";
import "./interfaces/IUniswapRouterV2.sol";

pragma solidity 0.8.17;

contract TokenSale is Ownable, Whitelist {
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router public swapRouter; // swap router

    struct TokenSaleRound {
        uint256 startTime; // tokenSale round start time timestamp
        uint256 endTime; // tokenSale round end time timestamp
        uint256 duration; // tokenSale round duration
        uint256 minAmount; // min purchase amount
        uint256 purchasePrice; // purchase price
        uint256 tokensSold; // number of tokens sold
        uint256 totalPurchaseAmount; // number of tokens on sale
        uint256 tokenSaleType; // 0 - pre_sale; 1 - main_sale; 2 - private_sale
        bool isPublic; // if true then round is public, else is private
        bool isEnded; // active tokenSale if true, if false vesting is end
    }

    address public usdtToken; // usdt or busd token address
    address[] public path; // path for get price eth or bnb
    address public treasury; // treasury address
    uint256 public roundsCounter; // quantity of tokeSale rounds
    uint256 public immutable PRECISSION = 1000; // 10000; // precission for math operation

    mapping(uint256 => TokenSaleRound) public rounds; // 0 pre_sale; 1 main_sale; 2 private_sale;
    mapping(address => mapping(uint256 => uint256)) public userBalance; // return user balance of planetex token
    mapping(address => mapping(uint256 => uint256)) public userSpentFunds; // return user spent funds in token sale

    //// @errors

    //// @dev - unequal length of arrays
    error InvalidArrayLengths(string err);
    /// @dev - address to the zero;
    error ZeroAddress(string err);
    /// @dev - user not in the whitelist
    error NotInTheWhitelist(string err);
    /// @dev - round not started
    error RoundNotStarted(string err);
    /// @dev - round is started
    error RoundIsStarted(string err);
    /// @dev - amount more or less than min or max
    error MinMaxPurchase(string err);
    /// @dev - tokens not enough
    error TokensNotEnough(string err);
    /// @dev - msg.value cannot be zero
    error ZeroMsgValue(string err);
    /// @dev - round with rhis id not found
    error RoundNotFound(string err);
    /// @dev - round is ended
    error RoundNotEnd(string err);

    ////@notice emitted when the user purchase token
    event PurchasePlanetexToken(
        address user,
        uint256 spentAmount,
        uint256 receivedAmount
    );
    ////@notice emitted when the owner withdraw unsold tokens
    event WithdrawUnsoldTokens(
        uint256 roundId,
        address recipient,
        uint256 amount
    );
    ////@notice emitted when the owner update round start time
    event UpdateRoundStartTime(
        uint256 roundId,
        uint256 startTime,
        uint256 endTime
    );

    constructor(
        uint256[] memory _purchasePercents, // array of round purchase percents
        uint256[] memory _minAmounts, // array of round min purchase amounts
        uint256[] memory _durations, // array of round durations in seconds
        uint256[] memory _purchasePrices, // array of round purchase prices
        uint256[] memory _startTimes, // array of round start time timestamps
        bool[] memory _isPublic, // array of isPublic bool indicators
        uint256 _planetexTokenTotalSupply, // planetex token total supply
        address _usdtToken, // usdt token address
        address _treasury, // treasury address
        address _unirouter // swap router address
    ) {
        if (
            _purchasePercents.length != _minAmounts.length ||
            _purchasePercents.length != _durations.length ||
            _purchasePercents.length != _purchasePrices.length ||
            _purchasePercents.length != _isPublic.length ||
            _purchasePercents.length != _startTimes.length
        ) {
            revert InvalidArrayLengths("TokenSale: Invalid array lengths");
        }
        if (
            _usdtToken == address(0) ||
            _treasury == address(0) ||
            _unirouter == address(0)
        ) {
            revert ZeroAddress("TokenSale: Zero Address");
        }

        for (uint256 i; i <= _purchasePercents.length - 1; i++) {
            TokenSaleRound storage tokenSaleRound = rounds[i];
            tokenSaleRound.duration = _durations[i];
            tokenSaleRound.startTime = _startTimes[i];
            tokenSaleRound.endTime = _startTimes[i] + _durations[i];
            tokenSaleRound.minAmount = _minAmounts[i];
            tokenSaleRound.purchasePrice = _purchasePrices[i];
            tokenSaleRound.tokensSold = 0;
            tokenSaleRound.totalPurchaseAmount =
                (_planetexTokenTotalSupply * _purchasePercents[i]) /
                PRECISSION;
            tokenSaleRound.isPublic = _isPublic[i];
            tokenSaleRound.isEnded = false;
            tokenSaleRound.tokenSaleType = i;
        }
        roundsCounter = _purchasePercents.length - 1;
        usdtToken = _usdtToken;
        treasury = _treasury;
        swapRouter = IUniswapV2Router(_unirouter);
        address[] memory _path = new address[](2);
        _path[0] = IUniswapV2Router(_unirouter).WETH();
        _path[1] = _usdtToken;
        path = _path;
    }

    /**
    @dev The modifier checks whether the tokenSale round has not expired.
    @param roundId tokenSale round id.
    */
    modifier isEnded(uint256 roundId) {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        require(
            tokenSaleRound.endTime > block.timestamp,
            "TokenSale: Round is ended"
        );
        _;
    }

    //// External functions

    receive() external payable {}

    /**
    @dev The function performs the purchase of tokens for usdt or busd tokens
    @param roundId tokeSale round id.
    @param amount usdt or busd amount.
    */
    function buyForErc20(uint256 roundId, uint256 amount)
        external
        isEnded(roundId)
    {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];

        if (!tokenSaleRound.isPublic) {
            if (!whitelist[msg.sender]) {
                revert NotInTheWhitelist("TokenSale: Not in the whitelist");
            }
        }

        if (!isRoundStared(roundId)) {
            revert RoundNotStarted("TokenSale: Round is not started");
        }

        if (amount < tokenSaleRound.minAmount) {
            revert MinMaxPurchase("TokenSale: Amount not allowed");
        }

        uint256 tokenAmount = _calcPurchaseAmount(
            amount,
            tokenSaleRound.purchasePrice
        );

        if (
            tokenSaleRound.tokensSold + tokenAmount >
            tokenSaleRound.totalPurchaseAmount
        ) {
            revert TokensNotEnough("TokenSale: Tokens not enough");
        }

        tokenSaleRound.tokensSold += tokenAmount;
        userSpentFunds[msg.sender][roundId] += amount;

        IERC20(usdtToken).safeTransferFrom(msg.sender, treasury, amount);

        userBalance[msg.sender][roundId] += tokenAmount;

        _endSoldOutRound(roundId);
        emit PurchasePlanetexToken(msg.sender, amount, tokenAmount);
    }

    /**
    @dev The function performs the purchase of tokens for eth or bnb tokens
    @param roundId tokeSale round id.
    */
    function buyForEth(uint256 roundId) external payable isEnded(roundId) {
        if (msg.value == 0) {
            revert ZeroMsgValue("TokenSale: Zero msg.value");
        }

        TokenSaleRound storage tokenSaleRound = rounds[roundId];

        if (!tokenSaleRound.isPublic) {
            if (!whitelist[msg.sender]) {
                revert NotInTheWhitelist("TokenSale: Not in the whitelist");
            }
        }

        if (!isRoundStared(roundId)) {
            revert RoundNotStarted("TokenSale: Round is not started");
        }

        uint256[] memory amounts = swapRouter.getAmountsOut(msg.value, path);

        if (amounts[1] < tokenSaleRound.minAmount) {
            revert MinMaxPurchase("TokenSale: Amount not allowed");
        }

        uint256 tokenAmount = _calcPurchaseAmount(
            amounts[1],
            tokenSaleRound.purchasePrice
        );

        if (
            tokenSaleRound.tokensSold + tokenAmount >
            tokenSaleRound.totalPurchaseAmount
        ) {
            revert TokensNotEnough("TokenSale: Tokens not enough");
        }

        tokenSaleRound.tokensSold += tokenAmount;
        userSpentFunds[msg.sender][roundId] += amounts[1];

        userBalance[msg.sender][roundId] += tokenAmount;

        _endSoldOutRound(roundId);

        (bool sent, ) = treasury.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit PurchasePlanetexToken(msg.sender, amounts[1], tokenAmount);
    }

    /**
    @dev The function withdraws tokens that were not sold and writes 
    them to the balance of the specified wallet.Only owner can call it. 
    Only if round is end.
    @param roundId tokeSale round id.
    @param recipient recipient wallet address
    */
    function withdrawUnsoldTokens(uint256 roundId, address recipient)
        external
        onlyOwner
    {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        if (tokenSaleRound.endTime > block.timestamp) {
            revert RoundNotEnd("TokenSale: Round not end");
        }
        if (tokenSaleRound.totalPurchaseAmount > tokenSaleRound.tokensSold) {
            uint256 unsoldTokens = tokenSaleRound.totalPurchaseAmount -
                tokenSaleRound.tokensSold;
            tokenSaleRound.tokensSold = tokenSaleRound.totalPurchaseAmount;
            userBalance[recipient][roundId] += unsoldTokens;
            emit WithdrawUnsoldTokens(roundId, recipient, unsoldTokens);
        } else {
            revert TokensNotEnough("TokenSale: Sold out");
        }

        tokenSaleRound.isEnded = true;
    }

    /**
    @dev The function update token sale round start time.Only owner can call it. 
    Only if round is not started.
    @param roundId tokeSale round id.
    @param newStartTime new start time timestamp
    */
    function updateStartTime(uint256 roundId, uint256 newStartTime)
        external
        onlyOwner
    {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        if (tokenSaleRound.startTime < block.timestamp) {
            revert RoundIsStarted("TokenSale: Round is started");
        }

        tokenSaleRound.startTime = newStartTime;
        tokenSaleRound.endTime = newStartTime + tokenSaleRound.duration;
        emit UpdateRoundStartTime(
            roundId,
            tokenSaleRound.startTime,
            tokenSaleRound.endTime
        );
    }

    //// Public Functions

    function convertToStable(uint256 amount, uint256 roundId)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 usdtAmount,
            uint256 planetexAmount
        )
    {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        if (amount > 0) {
            uint256[] memory amounts = swapRouter.getAmountsOut(amount, path);
            ethAmount = amounts[0];
            usdtAmount = amounts[1];
            planetexAmount = _calcPurchaseAmount(
                usdtAmount,
                tokenSaleRound.purchasePrice
            );
        } else {
            ethAmount = 0;
            usdtAmount = 0;
            planetexAmount = 0;
        }
    }

    function convertUsdtToPltx(uint256 roundId, uint256 amount)
        public
        view
        returns (uint256)
    {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        uint256 tokenAmount = _calcPurchaseAmount(
            amount,
            tokenSaleRound.purchasePrice
        );
        return tokenAmount;
    }

    /**
    @dev The function shows whether the round has started. Returns true if yes, false if not
    @param roundId tokeSale round id.
    */
    function isRoundStared(uint256 roundId) public view returns (bool) {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        return (block.timestamp >= tokenSaleRound.startTime &&
            block.timestamp <= tokenSaleRound.endTime);
    }

    /**
    @dev The function returns the timestamp of the end of the tokenSale round
    @param roundId tokeSale round id.
    */
    function getRoundEndTime(uint256 roundId) public view returns (uint256) {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        return tokenSaleRound.endTime;
    }

    /**
    @dev The function returns the timestamp of the start of the tokenSale round
    @param roundId tokeSale round id.
    */
    function getRoundStartTime(uint256 roundId) public view returns (uint256) {
        if (roundId > roundsCounter) {
            revert RoundNotFound("TokenSale: Round not found");
        }
        TokenSaleRound storage tokenSaleRound = rounds[roundId];
        return tokenSaleRound.startTime;
    }

    //// Internal Functions

    /**
    @dev The function ends the round if all tokens are sold out
    @param roundId tokeSale round id.
    */
    function _endSoldOutRound(uint256 roundId) internal {
        TokenSaleRound storage tokenSaleRound = rounds[roundId];

        if (tokenSaleRound.tokensSold == tokenSaleRound.totalPurchaseAmount) {
            tokenSaleRound.isEnded = true;
        }
    }

    /**
    @dev The function calculates the number of tokens to be received by the user
    @param amount usdt or busd token amount.
    @param price purchase price
    */
    function _calcPurchaseAmount(uint256 amount, uint256 price)
        internal
        pure
        returns (uint256 tokenAmount)
    {
        tokenAmount = (amount / price) * 1e18;
    }
}