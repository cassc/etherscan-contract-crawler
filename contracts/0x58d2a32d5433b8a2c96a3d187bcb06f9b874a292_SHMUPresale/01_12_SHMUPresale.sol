// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "src/openzeppelin/access/Ownable.sol";
import "src/openzeppelin/security/Pausable.sol";
import "src/openzeppelin/security/ReentrancyGuard.sol";
import "src/openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "src/interfaces/IChainlinkPriceFeed.sol";
import "src/interfaces/IPresale.sol";
import "src/interfaces/IERC20Custom.sol";

/// @title Presale contract for ShibaMemu token
/// @dev The contract is designed to work on the ethereum and binance blockchains
contract SHMUPresale is IPresale, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Custom;

    /// @notice Address of token contract
    IERC20Custom public immutable saleToken;

    /// @notice Address of USD stablecoin
    IERC20Custom public immutable usdToken;

    /// @notice Address of USD stablecoin
    bytes32 private immutable usdTokenSymbol;

    /// @notice Address of USD stablecoin
    uint8 private immutable usdTokenDecimals;

    /// @notice Address of chainlink nativeCurrency/USD price feed
    IChainlinkPriceFeed public immutable oracle;

    /// @notice Starting price for 1 token
    /// @dev Value will have same decimal places as in used USD stablecoin
    uint256 public immutable startPrice;

    /// @notice The amount by which the price changes every day
    /// @dev Value will have same decimal places as in used USD stablecoin
    uint256 public immutable priceShift;

    /// @notice Timestamp when presale starts
    uint256 public saleStartTime;

    /// @notice Timestamp when presale ends
    uint256 public saleEndTime;

    /// @notice Timestamp when purchased tokens claim starts
    uint256 public claimStartTime;

    /// @notice Total selling tokens amount
    uint256 public presaleAmount;

    /// @notice Total amount of purchased tokens
    uint256 public totalTokensSold;

    /// @notice Total amount of claimed tokens
    uint256 public totalTokensClaimed;

    /// @notice Total price of all sold tokens in USD
    uint256 public totalSoldPrice;

    /// @notice Stores the number of tokens purchased by each user that have not yet been claimed
    mapping(address => uint256) public purchasedTokens;

    /// @notice Indicates whether the user is blacklisted or not
    mapping(address => bool) public blacklist;

    /// @notice Indicates whether the user already claimed or not
    mapping(address => bool) public hasClaimed;

    /// @notice Checks that it is now possible to purchase passed amount tokens
    /// @param amount - the number of tokens to verify the possibility of purchase
    modifier verifyPurchase(uint256 amount) {
        if (block.timestamp < saleStartTime || block.timestamp >= saleEndTime) revert InvalidTimeframe();
        if (amount == 0) revert BuyAtLeastOneToken();
        if (amount + totalTokensSold > presaleAmount)
            revert PresaleAmountExceeded(presaleAmount - totalTokensSold);
        _;
    }

    /// @notice Verifies that the sender isn't blacklisted
    modifier notBlacklisted() {
        if (blacklist[_msgSender()]) revert AddressBlacklisted();
        _;
    }

    /// @notice Creates the contract
    /// @param _saleToken       - Address of preselling token
    /// @param _oracle          - Address of Chainlink nativeCurrency/USD price feed
    /// @param _usdToken        - Address of USD stablecoin
    /// @param _saleStartTime   - Sale start time
    /// @param _saleEndTime     - Sale end time
    /// @param _claimStartTime - Claim start time
    /// @param _startPrice      - Starting price for 1 token
    /// @param _priceShift      - The amount by which the price changes every day
    constructor(
        address _saleToken,
        address _oracle,
        address _usdToken,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _claimStartTime,
        uint256 _startPrice,
        uint256 _priceShift
    ) {
        if (_oracle == address(0)) revert ZeroAddress("Aggregator");
        if (_usdToken == address(0)) revert ZeroAddress("USD token");
        if (_saleToken == address(0)) revert ZeroAddress("Sale token");
        require(_saleEndTime > _saleStartTime, "Sale start after end");
        require(_claimStartTime > _saleEndTime, "Claim start after sale end");

        saleToken = IERC20Custom(_saleToken);
        oracle = IChainlinkPriceFeed(_oracle);
        usdToken = IERC20Custom(_usdToken);
        usdTokenSymbol = bytes32(bytes(usdToken.symbol()));
        usdTokenDecimals = usdToken.decimals();
        startPrice = _startPrice;
        priceShift = _priceShift;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        claimStartTime = _claimStartTime;

        emit SaleTimeUpdated(_saleStartTime, _saleEndTime, block.timestamp);
        emit ClaimTimeUpdated(_claimStartTime, block.timestamp);
    }

    /// @notice To set presale amount and transfer tokens to cover this amount
    function setPresaleAmount(uint256 _amount) external onlyOwner {
        require(presaleAmount == 0, "Presale amount already set");
        saleToken.safeTransferFrom(msg.sender, address(this), _amount * 1e18);
        presaleAmount = _amount;
        emit PresaleAmountSet(_amount, block.timestamp);
    }

    /// @notice To pause the presale
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice To unpause the presale
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice To add users to blacklist
    /// @param _users - Array of addresses to add in blacklist
    function addToBlacklist(address[] calldata _users) external onlyOwner {
        uint256 i = 0;
        while (i < _users.length) {
            blacklist[_users[i]] = true;
            emit AddedToBlacklist(_users[i], block.timestamp);
            i += 1;
        }
    }

    /// @notice To remove users from blacklist
    /// @param _users - Array of addresses to remove from blacklist
    function removeFromBlacklist(address[] calldata _users) external onlyOwner {
        uint256 i = 0;
        while (i < _users.length) {
            blacklist[_users[i]] = false;
            emit RemovedFromBlacklist(_users[i], block.timestamp);
            i += 1;
        }
    }

    /// @notice Function to transfer stuck tokens
    /// @dev You can transfer sale token only after claim is configured and only if remaining tokens are enough for the claim
    function claimUnsold() public onlyOwner {
        require(saleEndTime <= block.timestamp, "Only after sale end");
        uint256 amount = saleToken.balanceOf(address(this)) - (totalTokensSold - totalTokensClaimed) * 1e18;
        saleToken.safeTransfer(msg.sender, amount);
        emit UnsoldTokensClaimed(amount, block.timestamp);
    }

    /// @notice To claim tokens after claiming starts
    function claim() external whenNotPaused {
        if (block.timestamp < claimStartTime) revert InvalidTimeframe();
        if (hasClaimed[_msgSender()]) revert AlreadyClaimed();
        uint256 amount = purchasedTokens[_msgSender()];
        if (amount == 0) revert NothingToClaim();
        hasClaimed[_msgSender()] = true;
        totalTokensClaimed += amount;
        saleToken.safeTransfer(_msgSender(), amount * 1e18);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    /// @notice To buy into a presale using native chain currency with referrer
    /// @param _amount - Amount of tokens to buy
    /// @param _referrerId - id of the referrer
    function buyWithNativeCoin(
        uint256 _amount,
        uint256 _referrerId
    ) public payable notBlacklisted verifyPurchase(_amount) whenNotPaused nonReentrant {
        (uint256 priceInNativeCoin, uint256 priceInUSD) = getPrice(_amount);
        if (msg.value < priceInNativeCoin) revert NotEnoughNativeCoin(msg.value, priceInNativeCoin);
        uint256 excess = msg.value - priceInNativeCoin;
        totalTokensSold += _amount;
        totalSoldPrice += priceInUSD;
        purchasedTokens[_msgSender()] += _amount;
        _sendValue(payable(owner()), priceInNativeCoin);
        if (excess > 0) _sendValue(payable(_msgSender()), excess);
        emit TokensBought(_msgSender(), "Native", _amount, priceInUSD, priceInNativeCoin, _referrerId, block.timestamp);
    }

    /// @notice To buy into a presale using USD with referrer
    /// @param _amount - Amount of tokens to buy
    /// @param _referrerId - id of the referrer
    function buyWithUSD(
        uint256 _amount,
        uint256 _referrerId
    ) public notBlacklisted verifyPurchase(_amount) whenNotPaused nonReentrant {
        (uint256 priceInNativeCoin, uint256 priceInUSD) = getPrice(_amount);
        uint256 allowance = usdToken.allowance(_msgSender(), address(this));
        if (priceInUSD > allowance) revert NotEnoughAllowance(allowance, priceInUSD);
        totalTokensSold += _amount;
        totalSoldPrice += priceInUSD;
        purchasedTokens[_msgSender()] += _amount;
        usdToken.safeTransferFrom(_msgSender(), owner(), priceInUSD);
        emit TokensBought(_msgSender(), usdTokenSymbol, _amount, priceInUSD, priceInNativeCoin, _referrerId, block.timestamp);
    }

    /// @notice Returns current price in USD
    function getCurrentPrice() public view returns (uint256) {
        return startPrice + priceShift * getDaysPast();
    }

    /// @notice Returns amount of full days past from the sale start
    /// @dev If presale is ended it will count days to sale end moment
    function getDaysPast() public view returns (uint256 daysPast) {
        uint256 firstTimestamp = saleStartTime;
        if (firstTimestamp > block.timestamp) return 0;
        uint256 lastTimestamp = block.timestamp > saleEndTime ? saleEndTime : block.timestamp;
        require(firstTimestamp <= lastTimestamp, "The first timestamp is after the last");
        daysPast = (lastTimestamp - firstTimestamp) / 1 days;
    }

    /// @notice Helper function to calculate price in native coin and USD for given amount
    /// @param _amount - Amount of tokens to buy
    /// @return priceInNativeCoin - price for passed amount of tokens in native coin in 1e18 format
    /// @return priceInUSD - price for passed amount of tokens in USD
    /// @dev Price in USD will be returned with same decimals as in used usd stablecoin contract
    function getPrice(uint256 _amount) public view returns (uint256 priceInNativeCoin, uint256 priceInUSD) {
        if (_amount + totalTokensSold > presaleAmount)
            revert PresaleAmountExceeded(presaleAmount - totalTokensSold);
        priceInUSD = getCurrentPrice() * _amount;

        (uint80 roundID, int256 price, , uint256 updatedAt, uint80 answeredInRound) = oracle.latestRoundData();
        require(answeredInRound >= roundID, "Stale price");
        require(updatedAt >= block.timestamp - 3 hours, "Stale price");
        require(price > 0, "Invalid price");
        priceInNativeCoin = (priceInUSD * 10 ** (26 - usdTokenDecimals)) / uint256(price);
    }

    /// @notice For sending native coin from contract
    /// @param _recipient - Recipient address
    /// @param _amount - Amount of native coin  to send in wei
    function _sendValue(address payable _recipient, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Low balance");
        (bool success, ) = _recipient.call{ value: _amount }("");
        require(success, "Payment failed");
    }
}