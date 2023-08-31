//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        require(token != address(0), "TransferHelper: token empty address");
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        require(token != address(0), "TransferHelper: token empty address");
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PresaleV3 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    address public saleToken;
    uint256 public baseDecimals;
    uint256 public maxTokensToBuy;
    uint256 public saleTokenAmount;
    uint256 public saleTokenPrice;
    uint256 public usdRaised;
    address public paymentWallet;
    bool public whitelistClaimOnly;

    IERC20Upgradeable public USDTInterface;
    Aggregator public aggregatorInterface;
    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public wertWhitelisted;

    mapping(address => uint256) public swapToken;
    uint256 public inviteRewardRatio; // 30/ 1000
    mapping(address => uint256) public totalInviteReward;
    mapping(address => address) public inviter;
    mapping(address => uint256) public inviterCount;
    mapping(address => mapping(address => uint256)) public inviteRewardOf;

    event BindInviter(address indexed inviter, address indexed account);
    event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
    event SaleTimeUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event TokensBought(
        address indexed user,
        uint256 indexed tokensBought,
        address indexed purchaseToken,
        uint256 amountPaid,
        uint256 usdEq,
        uint256 timestamp
    );
    event TokensAdded(
        address indexed token,
        uint256 noOfTokens,
        uint256 timestamp
    );
    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event ClaimStartUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );
    event MaxTokensUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() external initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /**
     * @dev Initializes the contract and sets key parameters
     * @param _oracle Oracle contract to fetch ETH/USDT price
     * @param _usdt USDT token contract address
     * @param _startTime start time of the presale
     * @param _endTime end time of the presale
     * @param _maxTokensToBuy amount of max tokens to buy
     * @param _paymentWallet address to recive payments
     */
    function init(
        address _oracle,
        address _usdt,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxTokensToBuy,
        address _paymentWallet,
        uint256 _tokenAmount,
        uint256 _tokenPrice
    ) external onlyOwner {
        require(startTime == 0, "aready initialized");
        require(_oracle != address(0), "Zero aggregator address");
        require(_usdt != address(0), "Zero USDT address");
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "Invalid time"
        );
        baseDecimals = (10 ** 18);
        inviteRewardRatio = 30;
        aggregatorInterface = Aggregator(_oracle);
        USDTInterface = IERC20Upgradeable(_usdt);
        startTime = _startTime;
        endTime = _endTime;
        saleTokenAmount = _tokenAmount;
        saleTokenPrice = _tokenPrice;
        maxTokensToBuy = _maxTokensToBuy;
        paymentWallet = _paymentWallet;
        emit SaleTimeSet(startTime, endTime, block.timestamp);
    }

    /**
     * @dev To pause the presale
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev To unpause the presale
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setSaleOptions(
        uint256 _amount,
        uint256 _tokenPrice
    ) external onlyOwner {
        require(
            _amount >= saleTokenAmount && _tokenPrice > 0,
            "Invalid sale options"
        );
        saleTokenAmount = _amount;
        saleTokenPrice = _tokenPrice;
    }

    function setSwapToken(address _token, uint256 _price) external onlyOwner {
        swapToken[_token] = _price;
    }

    function setInviteRewardRatio(uint256 _ratio) external onlyOwner {
        require(_ratio <= 1000, "ratio range error");
        inviteRewardRatio = _ratio;
    }

    function bindInviter(address _inviter) external {
        require(inviter[msg.sender] == address(0), "Error: Repeat binding");
        require(_inviter != msg.sender, "Error: Binding self");
        require(
            _inviter != address(0),
            "Error: Binding inviter is zero address"
        );

        require(
            inviter[_inviter] != msg.sender,
            "Error: Do not allow mutual binding"
        );
        _bindInviter(_inviter, msg.sender);
    }

    function _bindInviter(address _inviter, address _account) private {
        if (
            _inviter != address(0) &&
            _inviter != _account &&
            inviter[_account] == address(0) &&
            inviter[_inviter] != _account
        ) {
            inviter[_account] = _inviter;
            inviterCount[_inviter] += 1;
            emit BindInviter(_inviter, _account);
        }
    }

    function _giveInviteReward(
        address _token,
        address _account,
        uint256 _amount
    ) internal returns (uint256) {
        if (_account != address(0) && _amount > 0) {
            inviteRewardOf[_token][_account] += _amount;
            totalInviteReward[_token] += _amount;

            if (_token == address(0)) {
                sendValue(payable(_account), _amount);
            } else {
                TransferHelper.safeTransferFrom(
                    _token,
                    _msgSender(),
                    _account,
                    _amount
                );
            }
            return _amount;
        }
        return 0;
    }

    /**
     * @dev To calculate the price in USD for given amount of tokens.
     * @param _amount No of tokens
     */
    function calculatePrice(uint256 _amount) public view returns (uint256) {
        require(_amount <= maxTokensToBuy, "Amount exceeds max tokens to buy");
        require(
            _amount + totalTokensSold <= saleTokenAmount,
            "Amount exceeds max tokens sold"
        );
        return _amount * saleTokenPrice;
    }

    /**
     * @dev To update the sale times
     * @param _startTime New start time
     * @param _endTime New end time
     */
    function changeSaleTimes(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, "Invalid parameters");
        if (_startTime > 0) {
            require(block.timestamp < startTime, "Sale already started");
            require(block.timestamp < _startTime, "Sale time in past");
            uint256 prevValue = startTime;
            startTime = _startTime;
            emit SaleTimeUpdated(
                bytes32("START"),
                prevValue,
                _startTime,
                block.timestamp
            );
        }

        if (_endTime > 0) {
            require(block.timestamp < endTime, "Sale already ended");
            require(_endTime > startTime, "Invalid endTime");
            uint256 prevValue = endTime;
            endTime = _endTime;
            emit SaleTimeUpdated(
                bytes32("END"),
                prevValue,
                _endTime,
                block.timestamp
            );
        }
    }

    /**
     * @dev To get latest ETH price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    modifier checkSaleState(uint256 amount) {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid time for buying"
        );
        require(amount > 0, "Invalid sale amount");
        _;
    }

    function buyWithSwapToken(
        address _token,
        address _inviter,
        uint256 amount
    ) external checkSaleState(amount) whenNotPaused returns (bool) {
        require(swapToken[_token] > 0, "Token not found");
        uint256 usdPrice = calculatePrice(amount);
        uint256 tokenAmount = (usdPrice * baseDecimals) / swapToken[_token];
        totalTokensSold += amount;
        userDeposits[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;

        _bindInviter(_inviter, _msgSender());
        uint256 inviteReward = _giveInviteReward(
            _token,
            inviter[_msgSender()],
            (tokenAmount * inviteRewardRatio) / 1000
        );

        TransferHelper.safeTransferFrom(
            _token,
            _msgSender(),
            paymentWallet,
            tokenAmount - inviteReward
        );

        emit TokensBought(
            _msgSender(),
            amount,
            address(USDTInterface),
            tokenAmount,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev To buy into a presale using USDT
     * @param amount No of tokens to buy
     */
    function buyWithUSDT(
        address _inviter,
        uint256 amount
    ) external checkSaleState(amount) whenNotPaused returns (bool) {
        uint256 usdPrice = calculatePrice(amount);
        totalTokensSold += amount;
        userDeposits[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;
        uint256 ourAllowance = USDTInterface.allowance(
            _msgSender(),
            address(this)
        );
        uint256 price = usdPrice / (10 ** 12);
        require(price <= ourAllowance, "Make sure to add enough allowance");

        _bindInviter(_inviter, _msgSender());
        uint256 inviteReward = _giveInviteReward(
            address(USDTInterface),
            inviter[_msgSender()],
            (price * inviteRewardRatio) / 1000
        );

        TransferHelper.safeTransferFrom(
            address(USDTInterface),
            _msgSender(),
            paymentWallet,
            price - inviteReward
        );

        emit TokensBought(
            _msgSender(),
            amount,
            address(USDTInterface),
            price,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev To buy into a presale using ETH
     * @param amount No of tokens to buy
     */
    function buyWithEth(
        address _inviter,
        uint256 amount
    )
        external
        payable
        checkSaleState(amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        uint256 usdPrice = calculatePrice(amount);
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        totalTokensSold += amount;
        userDeposits[_msgSender()] += (amount * baseDecimals);
        usdRaised += usdPrice;
        _bindInviter(_inviter, _msgSender());
        uint256 inviteReward = _giveInviteReward(
            address(0),
            inviter[_msgSender()],
            (ethAmount * inviteRewardRatio) / 1000
        );

        sendValue(payable(paymentWallet), ethAmount - inviteReward);
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        emit TokensBought(
            _msgSender(),
            amount,
            address(0),
            ethAmount,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev To buy ETH directly from wert .*wert contract address should be whitelisted if wertBuyRestrictionStatus is set true
     * @param _user address of the user
     * @param _amount No of ETH to buy
     */
    function buyWithETHWert(
        address _user,
        uint256 _amount
    )
        external
        payable
        checkSaleState(_amount)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(
            wertWhitelisted[_msgSender()],
            "User not whitelisted for this tx"
        );
        uint256 usdPrice = calculatePrice(_amount);
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        totalTokensSold += _amount;
        userDeposits[_user] += (_amount * baseDecimals);
        usdRaised += usdPrice;

        uint256 inviteReward = _giveInviteReward(
            address(0),
            inviter[_user],
            (ethAmount * inviteRewardRatio) / 1000
        );
        sendValue(payable(paymentWallet), ethAmount - inviteReward);
        if (excess > 0) sendValue(payable(_user), excess);
        emit TokensBought(
            _user,
            _amount,
            address(0),
            ethAmount,
            usdPrice,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev Helper funtion to get ETH price for given amount
     * @param amount No of tokens to buy
     */
    function ethBuyHelper(
        uint256 amount
    ) external view returns (uint256 ethAmount) {
        uint256 usdPrice = calculatePrice(amount);
        ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    }

    /**
     * @dev Helper funtion to get USDT price for given amount
     * @param amount No of tokens to buy
     */
    function usdtBuyHelper(
        uint256 amount
    ) external view returns (uint256 usdPrice) {
        usdPrice = calculatePrice(amount);
        usdPrice = usdPrice / (10 ** 12);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev To set the claim start time and sale token address by the owner
     * @param _claimStart claim start time
     * @param noOfTokens no of tokens to add to the contract
     * @param _saleToken sale toke address
     */
    function startClaim(
        uint256 _claimStart,
        uint256 noOfTokens,
        address _saleToken
    ) external onlyOwner returns (bool) {
        require(
            _claimStart > endTime && _claimStart > block.timestamp,
            "Invalid claim start time"
        );
        require(
            noOfTokens >= (totalTokensSold * baseDecimals),
            "Tokens less than sold"
        );
        require(_saleToken != address(0), "Zero token address");
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        saleToken = _saleToken;
        bool success = IERC20Upgradeable(_saleToken).transferFrom(
            _msgSender(),
            address(this),
            noOfTokens
        );
        require(success, "Token transfer failed");
        emit TokensAdded(saleToken, noOfTokens, block.timestamp);
        return true;
    }

    /**
     * @dev To change the claim start time by the owner
     * @param _claimStart new claim start time
     */
    function changeClaimStart(
        uint256 _claimStart
    ) external onlyOwner returns (bool) {
        require(claimStart > 0, "Initial claim data not set");
        require(_claimStart > endTime, "Sale in progress");
        require(_claimStart > block.timestamp, "Claim start in past");
        uint256 prevValue = claimStart;
        claimStart = _claimStart;
        emit ClaimStartUpdated(prevValue, _claimStart, block.timestamp);
        return true;
    }

    /**
     * @dev To claim tokens after claiming starts
     */
    function claim() external whenNotPaused returns (bool) {
        require(saleToken != address(0), "Sale token not added");
        require(!isBlacklisted[_msgSender()], "This Address is Blacklisted");
        if (whitelistClaimOnly) {
            require(
                isWhitelisted[_msgSender()],
                "User not whitelisted for claim"
            );
        }
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        bool success = IERC20Upgradeable(saleToken).transfer(
            _msgSender(),
            amount
        );
        require(success, "Token transfer failed");
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        return true;
    }

    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(_maxTokensToBuy > 0, "Zero max tokens to buy value");
        uint256 prevValue = maxTokensToBuy;
        maxTokensToBuy = _maxTokensToBuy;
        emit MaxTokensUpdated(prevValue, _maxTokensToBuy, block.timestamp);
    }

    /**
     * @dev To add wert contract addresses to whitelist
     * @param _addressesToWhitelist addresses of the contract
     */
    function whitelistUsersForWERT(
        address[] calldata _addressesToWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _addressesToWhitelist.length; i++) {
            wertWhitelisted[_addressesToWhitelist[i]] = true;
        }
    }

    /**
     * @dev To remove wert contract addresses to whitelist
     * @param _addressesToRemoveFromWhitelist addresses of the contracts
     */
    function removeFromWhitelistForWERT(
        address[] calldata _addressesToRemoveFromWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _addressesToRemoveFromWhitelist.length; i++) {
            wertWhitelisted[_addressesToRemoveFromWhitelist[i]] = false;
        }
    }

    /**
     * @dev To add users to blacklist which restricts blacklisted users from claiming
     * @param _usersToBlacklist addresses of the users
     */
    function blacklistUsers(
        address[] calldata _usersToBlacklist
    ) external onlyOwner {
        for (uint256 i = 0; i < _usersToBlacklist.length; i++) {
            isBlacklisted[_usersToBlacklist[i]] = true;
        }
    }

    /**
     * @dev To remove users from blacklist which restricts blacklisted users from claiming
     * @param _userToRemoveFromBlacklist addresses of the users
     */
    function removeFromBlacklist(
        address[] calldata _userToRemoveFromBlacklist
    ) external onlyOwner {
        for (uint256 i = 0; i < _userToRemoveFromBlacklist.length; i++) {
            isBlacklisted[_userToRemoveFromBlacklist[i]] = false;
        }
    }

    /**
     * @dev To add users to whitelist which restricts users from claiming if claimWhitelistStatus is true
     * @param _usersToWhitelist addresses of the users
     */
    function whitelistUsers(
        address[] calldata _usersToWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _usersToWhitelist.length; i++) {
            isWhitelisted[_usersToWhitelist[i]] = true;
        }
    }

    /**
     * @dev To remove users from whitelist which restricts users from claiming if claimWhitelistStatus is true
     * @param _userToRemoveFromWhitelist addresses of the users
     */
    function removeFromWhitelist(
        address[] calldata _userToRemoveFromWhitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _userToRemoveFromWhitelist.length; i++) {
            isWhitelisted[_userToRemoveFromWhitelist[i]] = false;
        }
    }

    /**
     * @dev To set status for claim whitelisting
     * @param _status bool value
     */
    function setClaimWhitelistStatus(bool _status) external onlyOwner {
        whitelistClaimOnly = _status;
    }

    /**
     * @dev To set payment wallet address
     * @param _newPaymentWallet new payment wallet address
     */
    function changePaymentWallet(address _newPaymentWallet) external onlyOwner {
        require(_newPaymentWallet != address(0), "address cannot be zero");
        paymentWallet = _newPaymentWallet;
    }

    /**
     * @dev to update userDeposits for purchases made on BSC
     * @param _users array of users
     * @param _userDeposits array of userDeposits associated with users
     */
    function updateFromBSC(
        address[] calldata _users,
        uint256[] calldata _userDeposits
    ) external onlyOwner {
        require(_users.length == _userDeposits.length, "Length mismatch");
        for (uint256 i = 0; i < _users.length; i++) {
            userDeposits[_users[i]] += _userDeposits[i];
        }
    }
}