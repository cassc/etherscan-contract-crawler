// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interfaces/IPancakePair.sol';
import '../interfaces/IPancakeFactory.sol';
import '../interfaces/IPancakeRouter.sol';
import '../interfaces/IPRC20.sol';
import '../interfaces/IBNBP.sol';

// File: PotContract.sol

contract PotLottery is ReentrancyGuard {
    /*
     ***Start of function, Enum, Variables, array and mappings to set and edit the Pot State such that accounts can enter the pot
     */

    struct Token {
        address tokenAddress;
        bool swapToBNB;
        bool isStable;
        string tokenSymbol;
        uint256 tokenDecimal;
    }

    enum POT_STATE {
        WAITING,
        STARTED,
        LIVE,
        CALCULATING_WINNER
    }

    address public owner;
    address public admin;

    // This is for bnb testnet
    address public wbnbAddr;
    address public busdAddr;
    address public pancakeswapV2FactoryAddr;
    IPancakeRouter02 public router;

    POT_STATE public pot_state;

    mapping(string => Token) public tokenWhiteList;
    string[] public tokenWhiteListNames;
    uint256 public minEntranceInUsd;
    uint256 public potCount;
    uint256 public potDuration;
    uint256 public percentageFee;
    uint256 public PotEntryCount;
    uint256 public entriesCount;
    address public BNBP_Address;
    uint256 public BNBP_Standard;

    mapping(string => uint256) public tokenLatestPriceFeed;

    uint256 public potLiveTime;
    uint256 public potStartTime;
    uint256 public timeBeforeRefund;
    uint256 public participantCount;
    address[] public participants;
    string[] public tokensInPotNames;
    address[] public entriesAddress;
    uint256[] public entriesUsdValue;
    string[] public entriesTokenName;
    uint256[] public entriesTokenAmount;
    address public LAST_POT_WINNER;

    // Tokenomics
    uint256 public airdropInterval;
    uint256 public burnInterval;
    uint256 public lotteryInterval;

    uint8 public airdropPercentage;
    uint8 public burnPercentage;
    uint8 public lotteryPercentage;

    uint256 public airdropPool;
    uint256 public burnPool;
    uint256 public lotteryPool;

    uint256 public stakingMinimum;
    uint256 public minimumStakingTime;

    string[] public adminFeeToken;
    mapping(string => uint256) public adminFeeTokenValues;

    mapping(string => uint256) public tokenTotalEntry;

    address public hotWalletAddress;
    uint256 public hotWalletMinBalance;
    uint256 public hotWalletMaxBalance;

    mapping(address => bool) public allowedContracts;

    constructor(address _owner) {
        owner = _owner;
        admin = _owner;
        pot_state = POT_STATE.WAITING;
        potDuration = 180; // 5 minutes
        minEntranceInUsd = 49000000000; //9900000000 cents ~ 1$
        percentageFee = 3;
        potCount = 1;
        timeBeforeRefund = 86400; //24 hours
        PotEntryCount = 0;
        entriesCount = 0;

        // Need to change
        airdropInterval = 86400 * 30;
        burnInterval = 86400;
        lotteryInterval = 86400 * 7;

        airdropPercentage = 75;
        burnPercentage = 20;
        lotteryPercentage = 5;

        stakingMinimum = 5 * 10**18; // 5 BNBP
        minimumStakingTime = 100 * 86400; // 100 days

        wbnbAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        busdAddr = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        pancakeswapV2FactoryAddr = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        BNBP_Address = 0x4D9927a8Dc4432B93445dA94E4084D292438931F;
        BNBP_Standard = 100;
        hotWalletAddress = 0xCf4560A9c128B844F139581A75218e757cc1bbb2 ;
        hotWalletMinBalance = 5 * 10**18;
        hotWalletMaxBalance = 10 * 10**18;

        // Change addresses before go live
        addToken('BUSD', 'BUSD', 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, true, true, 18);
        addToken('USDT', 'USDT', 0x55d398326f99059fF775485246999027B3197955, true, true, 18);
        addToken('USDC', 'USDC', 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, true, true, 18);
        addToken('BNB', 'BNB', 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, false, false, 18);
        addToken('Wrapped BNB', 'WBNB', 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, true, false, 18);
        addToken('BNBP', 'BNBP', 0x4D9927a8Dc4432B93445dA94E4084D292438931F, true, false, 18);
        addToken('Cake', 'CAKE', 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82, true, false, 18);
        addToken('Ethereum', 'ETH', 0x2170Ed0880ac9A755fd29B2688956BD959F933F8, true, false, 18);
        addToken('Cardano Token', 'ADA', 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47, true, false, 18);
        addToken('SHIBA INU', 'SHIBA', 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D, true, false, 18);
        UpdatePrice();
        changeAdmin(0x5E12E3D87dfD69ed40862c8e58027C83A07E40Fd);
        changeOwner(0x7804f2Bf970C857c8252Bd6d5eFaBDBc77F63011);

    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner, '!admin');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, '!owner');
        _;
    }

    modifier validBNBP() {
        require(BNBP_Address != address(0), '!BNBP Addr');
        _;
    }

    //-----I added a new event
    event BalanceNotEnough(address indexed userAddress, string tokenName);

    event EnteredPot(
        string tokenName, //
        address indexed userAddress, //
        uint256 indexed potRound,
        uint256 usdValue,
        uint256 amount,
        uint256 indexed enteryCount, //
        bool hasEntryInCurrentPot
    );

    event CalculateWinner(
        address indexed winner,
        uint256 indexed potRound,
        uint256 potValue,
        uint256 amount,
        uint256 amountWon,
        uint256 participants
    );

    event TokenSwapFailedString(string tokenName, string reason);
    event TokenSwapFailedBytes(string tokenName, bytes reason);
    event BurnSuccess(uint256 amount);
    event AirdropSuccess(uint256 amount);
    event LotterySuccess(address indexed winner);
    event HotWalletSupplied(address addr, uint256 amount);

    /**   @dev returns the usd value of a token amount
     * @param _tokenName the name of the token
     * @param _amount the amount of the token
     * @return usdValue usd value of the token amount
     */
    function getTokenUsdValue(string memory _tokenName, uint256 _amount) public view returns (uint256) {
        return ((tokenLatestPriceFeed[_tokenName] * _amount) / 10**tokenWhiteList[_tokenName].tokenDecimal);
    }

    /**   @dev changes contract owner address
     * @param _owner the new owner
     * @notice only the owner can call this function
     */
    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    /**   @dev changes contract admin address
     * @param _adminAddress the new admin
     * @notice only the owner can call this function
     */
    function changeAdmin(address _adminAddress) public onlyOwner {
        admin = _adminAddress;
    }

    /**   @dev set the BNBP address
     * @param _address the BNBP address
     * @notice only the admin or owner can call this function
     */
    function setBNBPAddress(address _address) public onlyAdmin {
        BNBP_Address = _address;
    }

    /**   @dev set the BNBP minimum balance to get 50% reduction in fee
     * @param _amount the BNBP minimum balance for 50% reduction in fee
     * @notice only the admin or owner can call this function
     */
    function setBNBP_Standard(uint256 _amount) public onlyAdmin {
        BNBP_Standard = _amount;
    }

    /**   @dev add token to list of white listed token
     * @param _tokenName the name of the token
     * @param _tokenSymbol the symbol of the token
     * @param _tokenAddress the address of the token
     * @param _decimal the token decimal
     * @notice only the admin or owner can call this function
     */
    function addToken(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _tokenAddress,
        bool _swapToBNB,
        bool _isStable,
        uint256 _decimal
    ) public onlyAdmin {
        require(_tokenAddress != address(0), '0x');
        if (tokenWhiteList[_tokenName].tokenAddress == address(0)) {
            tokenWhiteListNames.push(_tokenName);
        }
        tokenWhiteList[_tokenName] = Token(_tokenAddress, _swapToBNB, _isStable, _tokenSymbol, _decimal);
        if (_isStable) {
            updateTokenUsdValue(_tokenName, 10**10);
        }
    }

    /**   @dev remove token from the list of white listed token
     * @param _tokenName the name of the token
     * @notice only the admin or owner can call this function
     */
    function removeToken(string memory _tokenName) public onlyAdmin {
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (keccak256(bytes(_tokenName)) == keccak256(bytes(tokenWhiteListNames[index]))) {
                delete tokenWhiteList[_tokenName];
                delete tokenLatestPriceFeed[_tokenName];
                tokenWhiteListNames[index] = tokenWhiteListNames[tokenWhiteListNames.length - 1];
                tokenWhiteListNames.pop();
            }
        }
    }

    /**   @dev set token usd value
     * @param _tokenName the name of the token
     * @param _valueInUsd the usd value to set token price to
     * @notice set BNBP price to 30usd when price is below 30usd on dex
     * @notice add extra 10% to price of BNBP when price above 30usd on dex
     */
    function updateTokenUsdValue(string memory _tokenName, uint256 _valueInUsd) internal tokenInWhiteList(_tokenName) {
        if (keccak256(bytes(_tokenName)) == keccak256(bytes('BNBP'))) {
            tokenLatestPriceFeed[_tokenName] = _valueInUsd < 30 * 10**10 ? 30 * 10**10 : (_valueInUsd * 11) / 10;
        } else {
            tokenLatestPriceFeed[_tokenName] = _valueInUsd;
        }
    }

    modifier tokenInWhiteList(string memory _tokenName) {
        bool istokenWhiteListed = false;
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (keccak256(bytes(tokenWhiteListNames[index])) == keccak256(bytes(_tokenName))) {
                istokenWhiteListed = true;
            }
        }
        require(istokenWhiteListed, '!supp');
        _;
    }

    /**   @dev Attempts to enter pot with an array of values
     * @param _tokenNames an array of token names to enter pot with
     * @param _amounts an array of token amount to enter pot with
     * @param _participants an array of participant address to enter pot with
     * @notice attempts to calculate winner firstly if pot duration is over
     * @notice only callable by the admin or owner account
     * @notice entry will not be allowed if contract token balance is not enough or entry is less than minimum usd value
     * @notice entry with native token is not allowed
     */
    ///This is the Centralized enterPot function
    function EnterPot(
        string[] memory _tokenNames,
        uint256[] memory _amounts,
        address[] memory _participants
    ) external {
        require(msg.sender == hotWalletAddress, '!hot wallet');

        for (uint256 index = 0; index < _tokenNames.length; index++) {
            if (
                (keccak256(bytes(_tokenNames[index])) == keccak256(bytes('BNB'))) ||
                (getTokenUsdValue(_tokenNames[index], _amounts[index]) < minEntranceInUsd)
            ) {
                continue;
            }
            if (
                IPRC20(tokenWhiteList[(_tokenNames[index])].tokenAddress).balanceOf(address(this)) <
                (_amounts[index] + adminFeeTokenValues[_tokenNames[index]]) + tokenTotalEntry[_tokenNames[index]]
            ) {
                emit BalanceNotEnough(_participants[index], _tokenNames[index]);
                continue;
            }
            _EnterPot(_tokenNames[index], _amounts[index], _participants[index]);
        }
    }

    /**   @dev Attempts to enter pot with an array of values
     * @param _tokenName an array of token names to enter pot with
     * @param _amount an array of token amount to enter pot with
     * @param _participant an array of participant address to enter pot with
     * @notice attempts to calculate winner firstly if pot duration is over
     * @notice publicly callable by any address
     * @notice entry will not be allowed if approved value is less than _amounts or entry is less than minimum usd value
     * @notice entry with native token is not allowed
     */
    ///This is the Decentralized enterPot function
    function enterPot(
        string memory _tokenName,
        uint256 _amount,
        address _participant
    ) external {
        require(keccak256(bytes(_tokenName)) != keccak256(bytes('BNB')), 'BNB');
        require(getTokenUsdValue(_tokenName, _amount) >= minEntranceInUsd, 'Min');

        IPRC20(tokenWhiteList[_tokenName].tokenAddress).transferFrom(_participant, address(this), _amount);
        _EnterPot(_tokenName, _amount, _participant);
    }

    /**   @dev Attempts to enter a single pot entry
     * @param _tokenName token name to enter pot with
     * @param _amount token amount to enter pot with
     * @param _participant participant address to enter pot with
     */
    function _EnterPot(
        string memory _tokenName,
        uint256 _amount,
        address _participant
    ) internal {
        if ((potLiveTime + potDuration) <= block.timestamp && (participantCount > 1) && (potStartTime != 0)) {
            calculateWinner();
        }
        if (participantCount == 1 && keccak256(bytes(_tokenName)) != keccak256(bytes('BNB'))) {
            UpdatePrice();
        }
        if (participantsTotalEntryInUsd(_participant) == 0) {
            _addToParticipants(_participant);
        }
        if (tokenTotalEntry[_tokenName] == 0) {
            tokensInPotNames.push(_tokenName);
        }

        tokenTotalEntry[_tokenName] += _amount;

        //@optimize
        if (entriesAddress.length == PotEntryCount) {
            entriesAddress.push(_participant);
            entriesUsdValue.push(getTokenUsdValue(_tokenName, _amount));
            entriesTokenName.push(_tokenName);
            entriesTokenAmount.push(_amount);
        } else {
            entriesAddress[PotEntryCount] = _participant;
            entriesUsdValue[PotEntryCount] = getTokenUsdValue(_tokenName, _amount);
            entriesTokenName[PotEntryCount] = _tokenName;
            entriesTokenAmount[PotEntryCount] = _amount;
        }

        if (participantCount == 2 && pot_state != POT_STATE.LIVE) {
            potLiveTime = block.timestamp;
            pot_state = POT_STATE.LIVE;
        }
        if (PotEntryCount == 0) {
            pot_state = POT_STATE.STARTED;
            potStartTime = block.timestamp;
        }
        PotEntryCount++;
        entriesCount++;
        emit EnteredPot(
            _tokenName,
            _participant,
            potCount,
            getTokenUsdValue(_tokenName, _amount),
            _amount,
            entriesCount,
            participantsTotalEntryInUsd(_participant) == 0
        );
    }

    /**   @dev Attempts to calculate pot round winner
     */
    function calculateWinner() public nonReentrant {
        if ((potLiveTime + potDuration) <= block.timestamp && (participantCount > 1) && (potStartTime != 0)) {
            uint256 _totalPotUsdValue = totalPotUsdValue();
            address pot_winner = determineWinner(_totalPotUsdValue);
            string memory _getPotTokenWithHighestValue = getPotTokenWithHighestValue();
            uint256 _getAmountToPayAsFees = getAmountToPayAsFees(
                pot_winner,
                _getPotTokenWithHighestValue,
                _totalPotUsdValue
            );
            deductAmountToPayAsFees(_getPotTokenWithHighestValue, _getAmountToPayAsFees);

            tokenTotalEntry[_getPotTokenWithHighestValue] -= _getAmountToPayAsFees;
            for (uint256 index = 0; index < tokensInPotNames.length; index++) {
                _payAccount(tokensInPotNames[index], pot_winner, tokenTotalEntry[tokensInPotNames[index]]);
            } //Transfer all required tokens to the Pot winner
            LAST_POT_WINNER = pot_winner;

            emit CalculateWinner(
                pot_winner,
                potCount,
                _totalPotUsdValue,
                participantsTotalEntryInUsd(pot_winner),
                (_totalPotUsdValue * (100 - percentageFee)) / 100,
                participantCount
            );
            startNewPot();
            //Start the new Pot and set calculating winner to true
            //After winner has been sent the token then set calculating winner to false
        }
    }

    /**   @dev Attempts to select a random winner
     */
    function determineWinner(uint256 totalUsdValue) internal view returns (address winner) {
        uint256 winning_point = fullFillRandomness() % totalUsdValue;
        for (uint256 index = 0; index < PotEntryCount; index++) {
            if (winning_point <= entriesUsdValue[index]) {
                //That means that the winner has been found here
                winner = entriesAddress[index];
                return winner;
            }
            winning_point -= entriesUsdValue[index];
        }
    }

    /** @dev returns the totalUsd value of an address in the latest pot
    @return usdValue commulative usd value of a particular address in current pot
 */
    function participantsTotalEntryInUsd(address _address) public view returns (uint256 usdValue) {
        usdValue = 0;
        for (uint256 index = 0; index < PotEntryCount; index++) {
            if (_address == entriesAddress[index]) {
                usdValue += entriesUsdValue[index];
            }
        }
    }

    function totalPotUsdValue() public view returns (uint256 totalUsd) {
        for (uint256 index = 0; index < PotEntryCount; index++) {
            totalUsd += entriesUsdValue[index];
        }
    }

    // /** @dev returns a particular token amount in pot
    //     @return tokenValue the amount on a particular token in pot
    //  */
    //     function _tokenTotalEntry(string memory _tokenName) public view returns (uint256 tokenValue){
    //         tokenValue = 0;
    //         for (uint256 index = 0; index < PotEntryCount; index++) {
    //             if (keccak256(bytes(_tokenName)) == keccak256(bytes(entriesTokenName[index]))) {
    //                tokenValue += entriesTokenAmount[index] ;
    //             }
    //         }
    //     }

    /**   @dev process a refund for user if there is just one participant for 24 hrs
     */
    function getRefund() public nonReentrant {
        if (timeBeforeRefund + potStartTime < block.timestamp && participantCount == 1 && (potStartTime != 0)) {
            uint256 _totalPotUsdValue = totalPotUsdValue();
            string memory _getPotTokenWithHighestValue = getPotTokenWithHighestValue();
            uint256 _getAmountToPayAsFees = getAmountToPayAsFees(
                participants[0],
                _getPotTokenWithHighestValue,
                _totalPotUsdValue
            );
            deductAmountToPayAsFees(_getPotTokenWithHighestValue, _getAmountToPayAsFees);

            tokenTotalEntry[_getPotTokenWithHighestValue] -= _getAmountToPayAsFees;
            for (uint256 index = 0; index < tokensInPotNames.length; index++) {
                _payAccount(tokensInPotNames[index], participants[0], tokenTotalEntry[tokensInPotNames[index]]);
            }
            startNewPot();
        }
    }

    /**   @dev remove the amount to pay as fee
     * @param _tokenName the name of the token to remove the fee from
     * @param _value the amount to remove as fee
     */
    function deductAmountToPayAsFees(string memory _tokenName, uint256 _value) internal {
        bool tokenInFee = false;
        for (uint256 index = 0; index < adminFeeToken.length; index++) {
            if (keccak256(bytes(_tokenName)) == keccak256(bytes(adminFeeToken[index]))) {
                tokenInFee = true;
            }
        }
        if (!tokenInFee) {
            adminFeeToken.push(_tokenName);
        }
        adminFeeTokenValues[_tokenName] += _value;
        if (keccak256(bytes(_tokenName)) == keccak256(bytes('BNBP'))) {
            _distributeToTokenomicsPools(_value);
        }
    }

    /**   @dev remove the amount to pay as fee
     * @param _address the name of the token to remove the fee from
     * @return amountToPay the amount to remove as fee
     * @notice _address current BNBP holding determine how much fee reduction you get
     */
    function getAmountToPayAsFees(
        address _address,
        string memory _TokenWithHighestValue,
        uint256 _potUsdValue
    ) internal view returns (uint256 amountToPay) {
        uint256 baseFee = (
            (percentageFee * _potUsdValue * 10**tokenWhiteList[_TokenWithHighestValue].tokenDecimal) /
                (100 * tokenLatestPriceFeed[_TokenWithHighestValue]) >=
                tokenTotalEntry[_TokenWithHighestValue]
                ? tokenTotalEntry[_TokenWithHighestValue]
                : (percentageFee * _potUsdValue * 10**tokenWhiteList[_TokenWithHighestValue].tokenDecimal) /
                    (100 * tokenLatestPriceFeed[_TokenWithHighestValue])
        );
        amountToPay = ((IPRC20(BNBP_Address).balanceOf(_address) / BNBP_Standard) >= 1)
            ? baseFee / 2
            : (baseFee - ((IPRC20(BNBP_Address).balanceOf(_address) / BNBP_Standard) * baseFee) / 2);
    }

    /**   @dev attempt to update token price from dex
          @notice price is only updated when there are no participant in pot
    */
    function UpdatePrice() public nonReentrant {
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (tokenWhiteList[tokenWhiteListNames[index]].isStable) {
                continue;
            }
            (uint256 Res0, uint256 Res1) = _getTokenReserves(
                tokenWhiteList[tokenWhiteListNames[index]].tokenAddress,
                busdAddr
            );
            if (Res0 == 0 && Res1 == 0) {
                (Res0, Res1) = _getTokenReserves(tokenWhiteList[tokenWhiteListNames[index]].tokenAddress, wbnbAddr);
                uint256 res1 = Res1 * (10**tokenWhiteList[tokenWhiteListNames[index]].tokenDecimal);
                uint256 price = res1 / Res0;
                updateTokenUsdValue(
                    tokenWhiteListNames[index],
                    ((price * 10**10) * getBNBPrice()) /
                        10**(tokenWhiteList['BNB'].tokenDecimal + tokenWhiteList['BUSD'].tokenDecimal)
                );
            } else {
                uint256 res1 = Res1 * (10**tokenWhiteList[tokenWhiteListNames[index]].tokenDecimal);
                uint256 price = res1 / Res0;
                updateTokenUsdValue(
                    tokenWhiteListNames[index],
                    (price * 10**10) / 10**tokenWhiteList['BUSD'].tokenDecimal
                );
            }
        }
        updateTokenUsdValue('BUSD', 10**10);
    }

    /**
     * @dev gets token reserves for given token pair
     */
    function _getTokenReserves(address token0, address token1) internal view returns (uint256, uint256) {
        IPancakePair pair = IPancakePair(IPancakeFactory(pancakeswapV2FactoryAddr).getPair(token0, token1));

        if (address(pair) == address(0)) {
            return (0, 0);
        }

        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        if (token0 == pair.token0()) {
            return (Res0, Res1);
        }
        return (Res1, Res0);
    }

    /**   @dev returns the token name with the highest usd value in pot
          @return tokenWithHighestValue price is only updated when there are no participant in pot
    */
    function getPotTokenWithHighestValue() internal view returns (string memory tokenWithHighestValue) {
        tokenWithHighestValue = tokensInPotNames[0];
        for (uint256 index = 0; index < tokensInPotNames.length - 1; index++) {
            if (
                tokenTotalEntry[tokensInPotNames[index + 1]] * tokenLatestPriceFeed[tokensInPotNames[index + 1]] >=
                tokenTotalEntry[tokensInPotNames[index]] * tokenLatestPriceFeed[tokensInPotNames[index]]
            ) {
                tokenWithHighestValue = tokensInPotNames[index + 1];
            }
        }
    }

    /**   @dev reset the pot round
          @notice should be removed on launch on bsc
    */
    function resetPot() public onlyAdmin {
        startNewPot();
    }

    /**   @dev reset pot state to start a new round
     */
    function startNewPot() internal {
        for (uint256 index1 = 0; index1 < tokensInPotNames.length; index1++) {
            delete tokenTotalEntry[tokensInPotNames[index1]];
        }
        //@optimize
        // delete participants;
        delete participantCount;
        delete tokensInPotNames;

        // @optimize
        // delete entriesAddress;
        // delete entriesUsdValue;
        delete PotEntryCount;

        pot_state = POT_STATE.WAITING;
        delete potLiveTime;
        delete potStartTime;
        potCount++;
    }

    /**   @dev pays a specify address the specified token
          @param _tokenName name of the token to send
          @param _accountToPay address of the account to send token to
          @param _tokenValue the token value to send
    */
    function _payAccount(
        string memory _tokenName,
        address _accountToPay,
        uint256 _tokenValue
    ) internal returns (bool paid) {
        if (_tokenValue <= 0) return paid;
        if (keccak256(bytes(_tokenName)) == keccak256(bytes('BNB'))) {
            paid = payable(_accountToPay).send(_tokenValue);
        } else {
            paid = IPRC20(tokenWhiteList[_tokenName].tokenAddress).transfer(_accountToPay, _tokenValue);
        }
    }

    /**   @dev generates a random number
     */
    function fullFillRandomness() public view returns (uint256) {
        return uint256(uint128(bytes16(keccak256(abi.encodePacked(getBNBPrice(), block.difficulty, block.timestamp)))));
    }

    /**
     * @dev add new particiant to particiants list, optimzing gas fee
     */
    function _addToParticipants(address participant) internal {
        if (participantCount == participants.length) {
            participants.push(participant);
        } else {
            participants[participantCount] = participant;
        }
        participantCount++;
    }

    /**
     * @dev Gets current BNB price in comparison with BNB and USDT
     */
    function getBNBPrice() public view returns (uint256 price) {
        (uint256 Res0, uint256 Res1) = _getTokenReserves(wbnbAddr, busdAddr);
        uint256 res1 = Res1 * (10**IPRC20(wbnbAddr).decimals());
        price = res1 / Res0;
    }

    /**
     * @dev Swaps accumulated fees into BNB, or BUSD first, and then to BNBP
     */
    function swapAccumulatedFees() external validBNBP nonReentrant {
        require(tokenWhiteListNames.length > 0, 'whitelisted = 0');
        address[] memory path2 = new address[](2);
        address[] memory path3 = new address[](3);
        path2[1] = router.WETH();
        path3[1] = busdAddr;
        path3[2] = router.WETH();

        // Swap each token to BNB
        for (uint256 i = 0; i < adminFeeToken.length; i++) {
            uint256 balance = adminFeeTokenValues[adminFeeToken[i]];
            if (balance == 0) {
                continue;
            }

            string storage tokenName = adminFeeToken[i];
            Token storage tokenInfo = tokenWhiteList[tokenName];
            ERC20 token = ERC20(tokenInfo.tokenAddress);

            if (keccak256(bytes(tokenName)) == keccak256(bytes('BNB'))) continue;
            if (tokenInfo.tokenAddress == BNBP_Address) continue;

            if (balance > 0) {
                token.approve(address(router), balance);

                if (tokenInfo.swapToBNB) {
                    path2[0] = tokenInfo.tokenAddress;
                } else {
                    path3[0] = tokenInfo.tokenAddress;
                }

                try
                    router.swapExactTokensForETH(
                        balance,
                        0,
                        tokenInfo.swapToBNB ? path2 : path3,
                        address(this),
                        block.timestamp
                    )
                returns (uint256[] memory swappedAmounts) {
                    adminFeeTokenValues[tokenName] -= swappedAmounts[0];
                    adminFeeTokenValues['BNB'] += swappedAmounts[swappedAmounts.length - 1];
                } catch Error(string memory reason) {
                    emit TokenSwapFailedString(tokenName, reason);
                } catch (bytes memory reason) {
                    emit TokenSwapFailedBytes(tokenName, reason);
                }
            }
        }

        // Swap converted BNB to BNBP
        uint256 BNBFee = adminFeeTokenValues['BNB'];
        uint256 hotWalletFee;

        if (hotWalletAddress != address(0)) {
            uint256 hotWalletBalance = hotWalletAddress.balance;

            if (hotWalletBalance <= hotWalletMinBalance) {
                hotWalletFee = hotWalletMaxBalance - hotWalletBalance;
                if (hotWalletFee > (BNBFee * 8) / 10) {
                    hotWalletFee = (BNBFee * 8) / 10;
                }
            }
            if (hotWalletFee > 0) {
                bool sent = payable(hotWalletAddress).send(hotWalletFee);
                if (!sent) {
                    hotWalletFee = 0;
                } else {
                    emit HotWalletSupplied(hotWalletAddress, hotWalletFee);
                }
            }
        }

        if (adminFeeTokenValues['BNB'] > 0) {
            path2[0] = router.WETH();
            path2[1] = BNBP_Address;

            uint256[] memory bnbSwapAmounts = router.swapExactETHForTokens{ value: BNBFee - hotWalletFee }(
                0,
                path2,
                address(this),
                block.timestamp
            );
            adminFeeTokenValues['BNB'] -= (bnbSwapAmounts[0] + hotWalletFee);
            adminFeeTokenValues['BNBP'] += bnbSwapAmounts[1];
            _distributeToTokenomicsPools(bnbSwapAmounts[1]);
        }
    }

    /**
     * @dev sets hot wallet address
     */
    function setHotWalletAddress(address addr) external onlyAdmin {
        hotWalletAddress = addr;
    }

    /**
     * @dev sets hot wallet min and max balance
     */
    function setHotWalletSettings(uint256 min, uint256 max) external onlyAdmin {
        require(min < max, 'Min !< Max');
        hotWalletMinBalance = min;
        hotWalletMaxBalance = max;
    }

    /**
     * @dev Burns accumulated BNBP fees
     *
     * NOTE can't burn before the burn interval
     */
    function burnAccumulatedBNBP() external validBNBP {
        IBNBP BNBPToken = IBNBP(BNBP_Address);
        uint256 BNBP_Balance = BNBPToken.balanceOf(address(this));

        require(BNBP_Balance > 0, 'No BNBP');
        require(burnPool > 0, 'No burn amt');
        require(burnPool <= BNBP_Balance, 'Wrong BNBP Fee');

        BNBPToken.performBurn();
        adminFeeTokenValues['BNBP'] -= burnPool;
        burnPool = 0;
        emit BurnSuccess(burnPool);
    }

    /**
     * @dev call for an airdrop on the BNBP token contract
     */
    function airdropAccumulatedBNBP() external validBNBP returns (uint256) {
        IBNBP BNBPToken = IBNBP(BNBP_Address);
        uint256 amount = BNBPToken.performAirdrop();

        airdropPool -= amount;
        adminFeeTokenValues['BNBP'] -= amount;

        emit AirdropSuccess(amount);
        return amount;
    }

    /**
     * @dev call for an airdrop on the BNBP token contract
     */
    function lotteryAccumulatedBNBP() external validBNBP returns (address) {
        IBNBP BNBPToken = IBNBP(BNBP_Address);
        uint256 BNBP_Balance = BNBPToken.balanceOf(address(this));

        require(BNBP_Balance > 0, 'No BNBP');
        require(lotteryPool > 0, 'No lott amt');
        require(lotteryPool <= BNBP_Balance, 'Wrg BNBP Fee');

        address winner = BNBPToken.performLottery();
        adminFeeTokenValues['BNBP'] -= lotteryPool;
        lotteryPool = 0;

        emit LotterySuccess(winner);
        return winner;
    }

    /**
     * @dev updates percentages for airdrop, lottery, and burn
     *
     * NOTE The sum of 3 params should be 100, otherwise it reverts
     */
    function setTokenomicsPercentage(
        uint8 _airdrop,
        uint8 _lottery,
        uint8 _burn
    ) external onlyAdmin {
        require(_airdrop + _lottery + _burn == 100, 'Shld be 100');

        airdropPercentage = _airdrop;
        lotteryPercentage = _lottery;
        burnPercentage = _burn;
    }

    /**
     * @dev distribute BNBP balance changes to tokenomics pools
     *
     */
    function _distributeToTokenomicsPools(uint256 value) internal {
        uint256 deltaAirdropAmount = (value * airdropPercentage) / 100;
        uint256 deltaLotteryAmount = (value * lotteryPercentage) / 100;
        uint256 deltaBurnAmount = value - deltaAirdropAmount - deltaLotteryAmount;

        airdropPool += deltaAirdropAmount;
        lotteryPool += deltaLotteryAmount;
        burnPool += deltaBurnAmount;
    }

    /**
     * @dev Sets Airdrop interval
     *
     */
    function setAirdropInterval(uint256 interval) external onlyAdmin {
        airdropInterval = interval;
    }

    /**
     * @dev Sets Burn interval
     *
     */
    function setBurnInterval(uint256 interval) external onlyAdmin {
        burnInterval = interval;
    }

    /**
     * @dev Sets Lottery interval
     *
     */
    function setLotteryInterval(uint256 interval) external onlyAdmin {
        lotteryInterval = interval;
    }

    /**
     * @dev Sets minimum BNBP value to get airdrop and lottery
     *
     */
    function setStakingMinimum(uint256 value) external onlyAdmin {
        stakingMinimum = value;
    }

    /**
     * @dev Sets minimum BNBP value to get airdrop and lottery
     *
     */
    function setMinimumStakingTime(uint256 value) external onlyAdmin {
        minimumStakingTime = value;
    }

    /**
     * @dev add accumulated BNBP fees to the pool (can be only called by allowed contracts)
     */
    function addAdminTokenValue(uint256 value) external {
        require(allowedContracts[msg.sender], 'N');

        IPRC20(BNBP_Address).transferFrom(msg.sender, address(this), value);
        _distributeToTokenomicsPools(value);
    }

    /**
     * @dev Allows a contract to send BNBP to the pool
     */
    function allowFeeContract(address addr) external onlyAdmin {
        allowedContracts[addr] = true;
    }

    receive() external payable {
        if (msg.sender == address(router)) return;
        if (participantCount == 1) {
            UpdatePrice();
        }
        require((tokenLatestPriceFeed['BNB'] * msg.value) / 10**18 >= minEntranceInUsd, '< min');
        _EnterPot('BNB', msg.value, msg.sender);
    }
}