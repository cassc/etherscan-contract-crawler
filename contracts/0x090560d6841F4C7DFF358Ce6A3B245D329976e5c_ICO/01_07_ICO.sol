//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./utils/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/OracleWrapper.sol";

contract ICO is Ownable, ReentrancyGuard {
    uint256 public totalTokenSold;
    uint256 public totalUSDRaised;
    uint256 public tokenDecimal;
    uint8 public defaultPhase;
    uint8 public totalPhases;

    address public receiverAddress = 0x3D0f5CB4Cd496F8F41a2cCd44ffa2545377E6793;

    //ETH
    address public USDTOracleAddress =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public ETHOracleAddress =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    /* ================ STRUCT SECTION ================ */
    // Stores phases
    struct Phases {
        uint256 tokenSold;
        uint256 tokenLimit;
        uint32 startTime;
        uint32 expirationTimestamp;
        uint32 price; // 10 ** 8
        bool isComplete;
    }
    mapping(uint256 => Phases) public phaseInfo;

    IERC20 public tokenInstance; //SDG token instance
    IERC20 public usdtInstance; //USDT token instance
    OracleWrapper public USDTOracle = OracleWrapper(USDTOracleAddress);
    OracleWrapper public ETHOracle = OracleWrapper(ETHOracleAddress);

    /* ================ EVENT SECTION ================ */
    // Emits when tokens are bought
    event TokensBought(
        address buyerAddress,
        uint256 buyAmount,
        uint256 tokenAmount,
        uint32 buyTime,
        uint8 buyType
    );

    /* ================ CONSTRUCTOR SECTION ================ */
    constructor(address _tokenAddress, address _usdtAddress) {
        tokenInstance = IERC20(_tokenAddress);
        usdtInstance = IERC20(_usdtAddress);

        totalPhases = 5;
        tokenDecimal = uint256(10**tokenInstance.decimals());

        phaseInfo[0] = Phases({
            tokenLimit: 121_200_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1670630400,
            expirationTimestamp: 1673395199,
            price: 49500, //0.00049500
            isComplete: false
        });
        phaseInfo[1] = Phases({
            tokenLimit: 646_400_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1682121600,
            expirationTimestamp: 1684799999,
            isComplete: false,
            price: 74300 //0.00074300
        });
        phaseInfo[2] = Phases({
            tokenLimit: 282_800_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1695859200,
            expirationTimestamp: 1696809599,
            isComplete: false,
            price: 104000 //0.00104000
        });
        phaseInfo[3] = Phases({
            tokenLimit: 282_800_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1697414400,
            expirationTimestamp: 1700179199,
            isComplete: false,
            price: 145500 //0.00145500
        });
        phaseInfo[4] = Phases({
            tokenLimit: 282_800_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: 1729123200,
            expirationTimestamp: 1731887999,
            isComplete: false,
            price: 174700 //0.00174700
        });
    }

    /* ================ BUYING TOKENS SECTION ================ */

    // Receive Function
    receive() external payable {
        // Sending deposited currency to the receiver address
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    // Function lets user buy SDG tokens || Type 1 = BNB or ETH, Type = 2 for USDT
    function buyTokens(uint8 _type, uint256 _usdtAmount)
        external
        payable
        nonReentrant
    {
        require(
            block.timestamp < phaseInfo[(totalPhases - 1)].expirationTimestamp,
            "Buying Phases are over"
        );

        uint256 _buyAmount;

        // If type == 1
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        // If type == 2
        else {
            _buyAmount = _usdtAmount;
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
        (
            uint256 _tokenAmount,
            uint8 _phaseNo,
            uint256 _amountToUSD
        ) = calculateTokens(_type, _buyAmount);

        // Phase info setting
        setPhaseInfo(_tokenAmount, defaultPhase);

        // Update Phase number and add token amount
        if (phaseInfo[_phaseNo].tokenLimit == phaseInfo[_phaseNo].tokenSold) {
            defaultPhase = _phaseNo + 1;
        } else {
            defaultPhase = _phaseNo;
        }

        totalTokenSold += _tokenAmount;
        totalUSDRaised += _amountToUSD;

        // Transfers SDG to user
        TransferHelper.safeTransfer(
            address(tokenInstance),
            msg.sender,
            _tokenAmount
        );

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
        // Emits event
        emit TokensBought(
            msg.sender,
            _buyAmount,
            _tokenAmount,
            uint32(block.timestamp),
            _type
        );
    }

    // Function calculates tokens according to user's given amount
    function calculateTokens(uint8 _type, uint256 _amount)
        public
        view
        returns (
            uint256,
            uint8,
            uint256
        )
    {
        (uint256 _amountToUSD, uint256 _typeDecimal) = cryptoValues(_type);
        uint256 _amountGivenInUsd = ((_amount * _amountToUSD) / _typeDecimal);

        return calculateTokensInternal(_amountGivenInUsd, defaultPhase, 0);
    }

    // Internal function to calculate tokens
    function calculateTokensInternal(
        uint256 _amount,
        uint8 _phaseNo,
        uint256 _previousTokens
    )
        internal
        view
        returns (
            uint256,
            uint8,
            uint256
        )
    {
        // Phases cannot exceed totalPhases
        require(
            _phaseNo < totalPhases,
            "Not enough tokens in the contract or Phase expired"
        );
        Phases memory pInfo = phaseInfo[_phaseNo];

        // If phase is still going on
        if (block.timestamp < pInfo.expirationTimestamp) {
            require(
                uint32(block.timestamp) > pInfo.startTime,
                "Phase has not started yet"
            );
            // If phase is still going on
            uint256 _tokensAmount = tokensUserWillGet(_amount, pInfo.price);
            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) -
                pInfo.tokenSold;
            require(
                _tokensLeftToSell >= _tokensAmount,
                "Insufficient tokens available in phase"
            );
            return (_tokensAmount, _phaseNo, _amount);
        }
        // In case the phase is expired. New will begin after sending the left tokens to the next phase
        else {
            uint256 _remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;

            return
                calculateTokensInternal(
                    _amount,
                    _phaseNo + 1,
                    _remainingTokens + _previousTokens
                );
        }
    }

    // Tokens user will get according to the price
    function tokensUserWillGet(uint256 _amount, uint32 _price)
        internal
        view
        returns (uint256)
    {
        return ((_amount * tokenDecimal * (10**8)) /
            ((10**8) * uint256(_price)));
    }

    // Returns the crypto values used
    function cryptoValues(uint8 _type)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 _amountToUSD;
        uint256 _typeDecimal;

        if (_type == 1) {
            _amountToUSD = ETHOracle.latestAnswer();
            _typeDecimal = 10**18;
        } else {
            _amountToUSD = USDTOracle.latestAnswer();
            _typeDecimal = uint256(10**usdtInstance.decimals());
        }
        return (_amountToUSD, _typeDecimal);
    }

    // Sets phase info according to the tokens bought
    function setPhaseInfo(uint256 _tokensUserWillGet, uint8 _phaseNo) internal {
        require(_phaseNo < totalPhases, "All tokens have been exhausted");

        Phases storage pInfo = phaseInfo[_phaseNo];

        if (block.timestamp < pInfo.expirationTimestamp) {
            //  when phase has more tokens than reuired
            if ((pInfo.tokenLimit - pInfo.tokenSold) > _tokensUserWillGet) {
                pInfo.tokenSold += _tokensUserWillGet;
            }
            //  when  phase has equal tokens as reuired
            else if (
                (pInfo.tokenLimit - pInfo.tokenSold) == _tokensUserWillGet
            ) {
                pInfo.tokenSold = pInfo.tokenLimit;
                pInfo.isComplete = true;
            }
            // when tokens required are more than left tokens in phase
            else {
                revert("Phase doesn't enough tokens");
            }
        }
        // if tokens left in phase afterb completion of expiration time
        else {
            uint256 remainingTokens = pInfo.tokenLimit - pInfo.tokenSold;
            pInfo.tokenLimit = pInfo.tokenSold;
            pInfo.isComplete = true;

            phaseInfo[_phaseNo + 1].tokenLimit += remainingTokens;
            setPhaseInfo(_tokensUserWillGet, _phaseNo + 1);
        }
    }

    // Function sends the left over tokens to the receiving address, only after phases are over
    function sendLeftoverTokensToReceiver() external onlyOwner {
        require(
            block.timestamp > phaseInfo[(totalPhases - 1)].expirationTimestamp,
            "Phases are not over yet"
        );

        uint256 _balance = tokenInstance.balanceOf(address(this));
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
}