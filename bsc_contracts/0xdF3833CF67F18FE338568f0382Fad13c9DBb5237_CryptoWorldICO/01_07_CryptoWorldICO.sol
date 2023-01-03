//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/ReentrancyGuard.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/OracleWrapper.sol";

contract CryptoWorldICO is Ownable, ReentrancyGuard {
    uint256 public totalTokenSold;
    uint256 public totalUSDRaised;
    uint128 public tokenDecimal;
    uint128 public referralBonus; // total referral bonus distributed among users
    uint64 public referralPercentage; // 15 %
    uint8 public defaultPhase;
    uint8 public totalPhases;
    address public receiverAddress;
    address constant BUSDtoUSD = 0xcBb98864Ef56E9042e7d2efef76141f15731B82f; // decimal  8
    address constant BNBtoUSD = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // decima 8

    IERC20 public BUSD;
    IERC20 public Token;

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
    mapping(address => bool) public isWalletOldUser;

    /* ================ EVENT SECTION ================ */
    // Emits when tokens are bought
    event TokensBought(
        address buyerAddress,
        uint256 buyAmount,
        uint256 tokenAmount,
        uint32 buyTime,
        uint8 buyType
    );

    //Emits when referralUsed
    event ReferralBonus(
        address referelAddres,
        address reffereAddress,
        uint256 bonusAmount
    );

    /* ================ CONSTRUCTOR SECTION ================ */
    constructor(
        address _tokenAddress,
        address _receiverAddress,
        address _BUSD
    ) {
        Token = IERC20(_tokenAddress);
        BUSD = IERC20(_BUSD);
        receiverAddress = _receiverAddress;
        totalPhases = 3;
        tokenDecimal = uint128(10 ** Token.decimals());
        referralBonus = uint128(250000000 * tokenDecimal);
        referralPercentage = 1500; //15%

        uint32 currenTimeStamp = uint32(block.timestamp);

        phaseInfo[0] = Phases({
            tokenLimit: 250_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: currenTimeStamp,
            expirationTimestamp: 1677628799,
            price: 1000000, // 0.01000000 (token price =0.010$)
            isComplete: false
        });
        phaseInfo[1] = Phases({
            tokenLimit: 500_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: phaseInfo[0].expirationTimestamp,
            expirationTimestamp: 1680307199,
            isComplete: false,
            price: 1500000 //0.01500000  (token price =0.015$)
        });
        phaseInfo[2] = Phases({
            tokenLimit: 500_000_000 * tokenDecimal,
            tokenSold: 0,
            startTime: phaseInfo[1].expirationTimestamp,
            expirationTimestamp: 1682899199,
            isComplete: false,
            price: 2000000 //0.02000000   (token price =0.020$)
        });
    }

    /* ================ BUYING TOKENS SECTION ================ */

    // Receive Function
    receive() external payable {
        // Sending deposited currency to the receiver address
        TransferHelper.safeTransferETH(receiverAddress, msg.value);
    }

    // Function lets user buy CWC tokens || Type 1 = BNB , Type = 2 for BUSD
    function buyTokens(
        uint8 _type,
        uint256 _amount,
        address _refferelAddress
    ) external payable nonReentrant {
        if (_refferelAddress != address(0)) {
            require(
                isWalletOldUser[_refferelAddress],
                "Invalid referrel Address."
            );
            require(
                !isWalletOldUser[msg.sender],
                "Referral bonus already claimed. Cannot claim anymore."
            );
        }
        require(
            block.timestamp < phaseInfo[(totalPhases - 1)].expirationTimestamp,
            "Buying Phases are over"
        );

        uint256 _buyAmount;
        uint256 _bonusAmount;

        // If type == 1
        if (_type == 1) {
            _buyAmount = msg.value;
        }
        // If type == 2
        else {
            _buyAmount = _amount;
            // Balance Check

            require(
                BUSD.balanceOf(msg.sender) >= _buyAmount,
                "User doesn't have enough balance"
            );

            // Allowance Check
            require(
                BUSD.allowance(msg.sender, address(this)) >= _buyAmount,
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
        isWalletOldUser[msg.sender] = true;

        // Transfers CryptoWorld to user
        TransferHelper.safeTransfer(address(Token), msg.sender, _tokenAmount);

        if (_type == 1) {
            // Sending deposited currency to the receiver address
            TransferHelper.safeTransferETH(receiverAddress, _buyAmount);
        } else {
            // Sending deposited currency to the receiver address
            TransferHelper.safeTransferFrom(
                address(BUSD),
                msg.sender,
                receiverAddress,
                _buyAmount
            );
        }

        // 15% of the referral bonus will be given to referrar and referral
        if (_refferelAddress != address(0)) {
            _bonusAmount = (_tokenAmount * referralPercentage) / (10 ** 4);

            if (referralBonus >= _bonusAmount) {
                // 15% Bonus to the Referrer
                TransferHelper.safeTransfer(
                    address(Token),
                    _refferelAddress,
                    _bonusAmount
                );

                referralBonus -= uint128(_bonusAmount);
            }

            // Emits event
            emit ReferralBonus(_refferelAddress, msg.sender, _bonusAmount);
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
    function calculateTokens(
        uint8 _type,
        uint256 _amount
    ) public view returns (uint256, uint8, uint256) {
        (uint256 _amountToUSD, uint256 _typeDecimal) = cryptoValues(_type);
        uint256 _amountGivenInUsd = ((_amount * _amountToUSD) / _typeDecimal);
        (uint256 tokenAmount, uint8 phaseNo) = calculateTokensInternal(
            _amountGivenInUsd,
            defaultPhase,
            0
        );
        return (tokenAmount, phaseNo, _amountGivenInUsd);
    }

    // Internal function to calculatye tokens
    function calculateTokensInternal(
        uint256 _amount,
        uint8 _phaseNo,
        uint256 _previousTokens
    ) internal view returns (uint256, uint8) {
        // Phases cannot exceed totalPhases
        require(
            _phaseNo < totalPhases,
            "Not enough tokens in the contract or Phase expired"
        );

        Phases memory pInfo = phaseInfo[_phaseNo];

        // If phase is still going on
        if (pInfo.expirationTimestamp > block.timestamp) {
            uint256 _tokensAmount = tokensUserWillGet(_amount, pInfo.price);
            uint256 _tokensLeftToSell = (pInfo.tokenLimit + _previousTokens) -
                pInfo.tokenSold;

            // If token left are 0. Next phase will be executed
            if (_tokensLeftToSell == 0) {
                return
                    calculateTokensInternal(
                        _amount,
                        _phaseNo + 1,
                        _previousTokens
                    );
            }
            // If the phase have enough tokens left
            else if (_tokensLeftToSell >= _tokensAmount) {
                return (_tokensAmount, _phaseNo);
            }
            // If the phase doesn't have enough tokens
            else {
                _tokensAmount =
                    pInfo.tokenLimit +
                    _previousTokens -
                    pInfo.tokenSold;

                uint256 _tokenPriceInPhase = tokenValueInPhase(
                    pInfo.price,
                    _tokensAmount
                );

                (
                    uint256 _remainingTokens,
                    uint8 _newPhase
                ) = calculateTokensInternal(
                        _amount - _tokenPriceInPhase,
                        _phaseNo + 1,
                        0
                    );

                return (_remainingTokens + _tokensAmount, _newPhase);
            }
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

    // Returns the value of tokens in the phase in dollors
    function tokenValueInPhase(
        uint32 _price,
        uint256 _tokenAmount
    ) internal view returns (uint256) {
        return ((_tokenAmount * uint256(_price) * (10 ** 8)) /
            ((10 ** 8) * tokenDecimal));
    }

    // Tokens user will get according to the price
    function tokensUserWillGet(
        uint256 _amount,
        uint32 _price
    ) internal view returns (uint256) {
        return ((_amount * tokenDecimal * (10 ** 8)) /
            ((10 ** 8) * uint256(_price)));
    }

    // Returns the crypto values used
    function cryptoValues(
        uint8 _type
    ) internal view returns (uint256, uint256) {
        uint256 _amountToUSD;
        uint256 _typeDecimal;

        if (_type == 1) {
            _amountToUSD = OracleWrapper(BNBtoUSD).latestAnswer();
            _typeDecimal = 10 ** 18;
        } else {
            _amountToUSD = OracleWrapper(BUSDtoUSD).latestAnswer();
            _typeDecimal = uint256(10 ** BUSD.decimals());
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
                uint256 tokensLeft = _tokensUserWillGet -
                    (pInfo.tokenLimit - pInfo.tokenSold);
                pInfo.tokenSold = pInfo.tokenLimit;
                pInfo.isComplete = true;

                setPhaseInfo(tokensLeft, _phaseNo + 1);
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

        uint256 _balance = Token.balanceOf(address(this));
        require(_balance > 0, "No tokens left to send");

        TransferHelper.safeTransfer(address(Token), receiverAddress, _balance);
    }

    /* ================ OTHER FUNCTIONS SECTION ================ */

    // Updates Receiver Address
    function updateReceiverAddress(
        address _receiverAddress
    ) external onlyOwner {
        receiverAddress = _receiverAddress;
    }

    function updateReferralPercentage(uint64 _percentage) external onlyOwner {
        referralPercentage = _percentage;
    }
}