//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/UtilityHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICOEvents.sol";
import "./interfaces/OracleWrapper.sol";

contract ICO is Ownable, ICOEvents, ReentrancyGuard {
    uint256 public totalTokenSold;
    uint256 public totalTokenClaimed;
    uint256 public totalAmountRaisedUSD;
    uint256 public minBuyAmount = 350 * 10**8; //350USD
    uint256 public maxBuyAmount = 25000 * 10**8; //25000USD
    uint32 public constant price = 7700; //in 10**5
    uint32 public constant lockInTime = 270 days; //270 days for tresting 9 months
    address public receiverAddress = 0xFF83C32Aa753dc3C006744D5b451C9bD1fdaE201;
    address public constant USDTOracleAddress =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public constant ETHOracleAddress =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    bool public enable;

    struct VestingData {
        uint256 totalAmountBought;
        uint256 totalClaimedAmount;
        uint32 investmentCounter;
        bytes email;
    }

    struct UserData {
        uint256 amount;
        uint32 vestingStartTime;
        bool success;
    }

    // User data Mapping for maintain the users accounts
    mapping(bytes => bool) public isVerified;
    mapping(address => VestingData) public userBuyMapping;
    mapping(address => mapping(uint256 => UserData)) public userMapping;

    IERC20 public tokenInstance; //Ukiyo token instance
    IERC20 public usdtInstance; //USDT token instance
    OracleWrapper public USDTOracle = OracleWrapper(USDTOracleAddress);
    OracleWrapper public ETHOracle = OracleWrapper(ETHOracleAddress);

    constructor(address _tokenAddress, address _usdtAddress) {
        tokenInstance = IERC20(_tokenAddress);
        usdtInstance = IERC20(_usdtAddress);
    }

    // Receive Function
    receive() external payable {
        // Sending deposited currency to the receiver address
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    /* =================== Buy Token Functions ==================== */
    /**
     * buyTokens function is used for buy the tokens
     * That User buy from USDT or ETH
     */
    function buyTokens(
        uint256 amount,
        uint8 _type,
        bytes memory _email
    ) external payable nonReentrant {
        require(enable, "ICO is Disable.");
        require(isVerified[_email], "Your KYC is not done yet.");

        VestingData storage user = userBuyMapping[msg.sender];
        ++user.investmentCounter;

        if (user.investmentCounter > 1) {
            require(
                keccak256(userBuyMapping[msg.sender].email) ==
                    keccak256(_email),
                "Invalid E-mail"
            );
        } else {
            user.email = _email;
        }

        uint256 _buyAmount;

        // If type == 1
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        // If type == 2
        else {
            _buyAmount = amount;
            // Balance Check
            require(
                usdtInstance.balanceOf(msg.sender) >= _buyAmount,
                "User doesn't have enough balance"
            );

            // Allowance Check
            require(
                usdtInstance.allowance(msg.sender, address(this)) >= _buyAmount,
                "Allowance provided is low"
            );
        }

        require(_buyAmount > 0, "Please enter value more than 0");
        // Token calculation
        (uint256 _tokenAmount, uint256 _amountInUSD) = calculateTokens(
            _type,
            _buyAmount
        );

        require(_amountInUSD >= minBuyAmount,"You can't purchase under minimum limit");
        require(_amountInUSD <= maxBuyAmount,"You can't purchase above maximum limit");

        require(
            (totalTokenSold + _tokenAmount) <=
                (tokenInstance.balanceOf(address(this)) + totalTokenClaimed),
            "ICO does't have enough tokens"
        );
        // updating the user account with the total amount that He/She purchases
        UserData storage userIDData = userMapping[msg.sender][
            user.investmentCounter
        ];
        userIDData.amount = (_tokenAmount);
        userIDData.vestingStartTime = uint32(block.timestamp);

        user.totalAmountBought += _tokenAmount;

        totalTokenSold += _tokenAmount;
        totalAmountRaisedUSD += _amountInUSD;

        if (_type == 1) {
            // Sending deposited currency to the receiver address
            TransferHelper.safeTransferETH(receiverAddress, _buyAmount);
        } else {
            // Sending deposited currency to the receiver address
            TransferHelper.safeTransferFrom(
                address(usdtInstance),
                msg.sender,
                receiverAddress,
                _buyAmount
            );
        }

        emit BuyTokenDetail(
            _buyAmount,
            _amountInUSD,
            userIDData.amount,
            user.investmentCounter,
            userIDData.vestingStartTime,
            _email,
            _type,
            msg.sender
        );
    }

    /* =============== Token Calculations =============== */
    /**
     * calculateTokens function is used for calculating the amount of token
     * That User buy from USDT or ETH
     */
    function calculateTokens(uint8 _type, uint256 _amount)
        public
        view
        returns (uint256 _totalTokens, uint256 _amountUsd)
    {
        //_type==1===> ETH, _type==2===> USDT
        uint256 _amountToUsd;
        uint256 _typeDecimals;

        if (_type == 1) {
            _amountToUsd = ETHOracle.latestAnswer();
            _typeDecimals = 10**18;
        } else if (_type == 2) {
            _amountToUsd = USDTOracle.latestAnswer();
            _typeDecimals = 10**(usdtInstance.decimals());
        }

        _totalTokens =
            (_amount *
                _amountToUsd *
                (10**tokenInstance.decimals()) *
                (10**5)) /
            (_typeDecimals * (10**8) * price);

        _amountUsd = (_amountToUsd * _amount) / _typeDecimals;
    }

    /* =============== Token Claiming Functions =============== */
    /**
     * User can claim the tokens with claimTokens function.
     * after start the vesting.
     */
    function claimTokens(uint32 _IDCounter) public nonReentrant {
        UserData storage user = userMapping[msg.sender][_IDCounter];

        require(
            block.timestamp >= (user.vestingStartTime + lockInTime),
            "You can't claim before nine months"
        );

        require(!user.success, "You already claimed all the tokens.");

        require(user.amount > 0, "User is not registered with vesting");

        uint256 amount = user.amount;

        require(amount > 0, "Amount should be greater then Zero");

        userBuyMapping[msg.sender].totalClaimedAmount += amount;
        user.success = true;
        totalTokenClaimed += amount;

        TransferHelper.safeTransfer(address(tokenInstance), msg.sender, amount);

        emit ClaimedToken(amount, _IDCounter, msg.sender);
    }

    // Function sends the left over tokens to the receiving address, only after phases are over
    function sendLeftoverTokensToReceiver() external onlyOwner {
        require(!enable, "ICO is enabled yet");

        uint256 _balance = tokenInstance.balanceOf(address(this)) -
            (totalTokenSold - totalTokenClaimed);
        require(_balance > 0, "No tokens left to send");

        TransferHelper.safeTransfer(
            address(tokenInstance),
            receiverAddress,
            _balance
        );
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */
    // Updates Receiver Address
    function updateReceiverAddress(address _receiverAddress)
        external
        onlyOwner
    {
        receiverAddress = _receiverAddress;
    }

    function updateEnableOrDisable() external onlyOwner {
        enable = !enable;
    }

    function updateUserKYC(bytes memory _email) external onlyOwner {
        isVerified[_email] = true;
        emit userKYC(_email);
    }

    function updateMinimumBuyAmount(uint256 _minBuyAmount) external onlyOwner {
        minBuyAmount = _minBuyAmount;
    }

    function updateMaximumBuyAmount(uint256 _maxBuyAmount) external onlyOwner {
        maxBuyAmount = _maxBuyAmount;
    }
}