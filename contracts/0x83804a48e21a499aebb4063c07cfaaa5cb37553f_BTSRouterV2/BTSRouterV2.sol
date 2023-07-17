/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

/*
█▄▄ █░░ █▀█ █▀▀ █▄▀ █▀▀ █░█ ▄▀█ █ █▄░█ ▀█▀ █▀█ █▄▀ █▀▀ █▄░█ █▀ █▄░█ █ █▀█ █▀▀ █▀█
█▄█ █▄▄ █▄█ █▄▄ █░█ █▄▄ █▀█ █▀█ █ █░▀█ ░█░ █▄█ █░█ ██▄ █░▀█ ▄█ █░▀█ █ █▀▀ ██▄ █▀▄

blockchaintokensniper.github.io
t.me/blockchaintokensniper
*/

pragma solidity ^0.8;

interface IBTSExchangeWrapperV2 {
    function buyTokens(uint, address, address, address, uint) external payable;
    function getTokenValue(uint, address, address) external view returns (uint);
    function sellTokens(uint, address, address, address) external payable;
}

interface ITokenStore {
    function sendTokens(address, address, uint) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

contract TokenStore {
    address public parentContract;
    mapping(address => uint) public initialTokenBalances;

    constructor() {
        parentContract = msg.sender;
    }

    function setInitialTokenBalance(address _tokenAddress, uint _initialBalance) external {
        require(msg.sender == parentContract);
        initialTokenBalances[_tokenAddress] = _initialBalance;
    }

    function sendTokens(address _tokenAddress, address _destinationAddress, uint _sellAmount) external {
        require(msg.sender == parentContract);

        uint tokenAmount = (initialTokenBalances[_tokenAddress] * _sellAmount) / 10000;
        IERC20(_tokenAddress).transfer(_destinationAddress, tokenAmount);
    }
}

contract BTSRouterV2 {
    address public adminAddress = msg.sender;
    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint public totalNumSnipes;

    struct SnipeData {
        address sniperAddress;
        address routerAddress;
        address baseToken;
        address snipeToken;
        uint buyAmount;
        uint tokensBought;
        uint sellAmount;
        uint tokensSold;
        address tokenStore;
        uint buyTimestamp;
        uint sellTimestamp;
        uint tokenPercentageSold;
        uint snipeIndex;
    }

    mapping(address => mapping(uint => SnipeData)) public snipeInfo;
    mapping(address => uint) public userCurrentSnipeID;

    mapping(address => address) public userTokenStore;
    mapping(address => address) public exchangeWrappers;

    mapping(uint => SnipeData) public snipeIndex;

    event TokensBought(uint, uint);
    event TokensSold(uint, uint);
    event SnipeFeePaid(uint, uint);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Admin only");
        _;
    }

    receive() external payable {}

    // **** SNIPE FUNCTIONS ****

    function Snipe(address _routerAddress, address _baseToken, address _snipeToken, uint _buyAmount, uint _txDeadline) external payable {
        require(IERC20(_snipeToken).balanceOf(getTokenStore()) <= 1e6, "Already sniped token");
        
        if (_baseToken != wethAddress) IERC20(_baseToken).transferFrom(msg.sender, exchangeWrappers[_routerAddress], _buyAmount);

        IBTSExchangeWrapperV2(exchangeWrappers[_routerAddress]).buyTokens{value: _baseToken == wethAddress ? msg.value : 0}(
            _buyAmount,
            _baseToken,
            _snipeToken,
            getTokenStore(),
            _txDeadline
        );

        uint tokensBought = IERC20(_snipeToken).balanceOf(getTokenStore());
        TokenStore(getTokenStore()).setInitialTokenBalance(_snipeToken, tokensBought);

        snipeInfo[msg.sender][userCurrentSnipeID[msg.sender] + 1] = SnipeData(
            msg.sender,
            _routerAddress,
            _baseToken,
            _snipeToken,
            _buyAmount,
            tokensBought,
            0,
            0,
            getTokenStore(),
            block.timestamp,
            0,
            0,
            totalNumSnipes + 1
        );

        userCurrentSnipeID[msg.sender]++;
        totalNumSnipes++;

        snipeIndex[totalNumSnipes] = snipeInfo[msg.sender][userCurrentSnipeID[msg.sender]];

        emit TokensBought(userCurrentSnipeID[msg.sender], tokensBought);
    }

    function Sell(uint _snipeID, uint _sellPercentage, bytes32[] memory _userInfo) external {
        uint userSnipeFee = uint(bytes32(_userInfo[0]));
        address referrerAddress = address(uint160(uint(_userInfo[1])));
        uint referrerSnipeFeeCut = uint(bytes32(_userInfo[2]));

        SnipeData storage snipeData = snipeInfo[msg.sender][_snipeID];

        require(snipeData.sniperAddress == msg.sender, "Unauthorised");
        require(_sellPercentage <= 10000 - snipeData.tokenPercentageSold, "Too many tokens sold");
        require(snipeData.tokenPercentageSold < 10000, "Snipe already completed");

        ITokenStore(snipeData.tokenStore).sendTokens(snipeData.snipeToken, address(this), _sellPercentage);
        uint tokensReceived = IERC20(snipeData.snipeToken).balanceOf(address(this));

        snipeData.tokensSold += tokensReceived;

        IERC20 baseToken = IERC20(snipeData.baseToken);
        IERC20 snipeToken = IERC20(snipeData.snipeToken);

        snipeToken.transfer(exchangeWrappers[snipeData.routerAddress], snipeToken.balanceOf(address(this)));

        IBTSExchangeWrapperV2(exchangeWrappers[snipeData.routerAddress]).sellTokens(
            tokensReceived,
            snipeData.baseToken,
            snipeData.snipeToken,
            address(this)
        );

        uint sellAmount;

        if (snipeData.baseToken == wethAddress) sellAmount = address(this).balance;
        else sellAmount = baseToken.balanceOf(address(this));

        snipeData.sellAmount += sellAmount;

        emit TokensSold(_snipeID, sellAmount);

        uint partialBuyCost = (snipeData.buyAmount * _sellPercentage) / 10000;
        uint partialProfit;

        if (sellAmount > partialBuyCost) partialProfit = sellAmount - partialBuyCost; 
        else partialProfit = 0;

        if (partialProfit > 0 && userSnipeFee > 0) {
            uint totalSnipeFee = (partialProfit * userSnipeFee) / 10000;
            uint referrerEarnedFee = (totalSnipeFee * referrerSnipeFeeCut) / 10000;

            if (snipeData.baseToken == wethAddress) {
                if (referrerEarnedFee > 0) payable(referrerAddress).transfer(referrerEarnedFee);

                payable(adminAddress).transfer(totalSnipeFee - referrerEarnedFee);
                sellAmount -= totalSnipeFee;
            }

            else {
                if (referrerEarnedFee > 0) IERC20(snipeData.baseToken).transfer(referrerAddress, referrerEarnedFee);

                IERC20(snipeData.baseToken).transfer(adminAddress, totalSnipeFee - referrerEarnedFee);
                sellAmount -= totalSnipeFee;
            }

            emit SnipeFeePaid(_snipeID, totalSnipeFee);
        }

        else emit SnipeFeePaid(_snipeID, 0);

        if (snipeData.baseToken == wethAddress) payable(msg.sender).transfer(sellAmount);
        else baseToken.transfer(msg.sender, sellAmount);

        snipeData.tokenPercentageSold += _sellPercentage;

        if (snipeData.tokenPercentageSold == 10000) {
            snipeData.sellTimestamp = block.timestamp;
            snipeIndex[snipeData.snipeIndex] = snipeData;
        }

        snipeInfo[msg.sender][_snipeID] = snipeData;
    }

    function getSnipeValue(address _holderAddress, uint _snipeID) external view returns (uint) {
        return IBTSExchangeWrapperV2(exchangeWrappers[snipeInfo[_holderAddress][_snipeID].routerAddress]).getTokenValue(
            IERC20(snipeInfo[_holderAddress][_snipeID].snipeToken).balanceOf(snipeInfo[_holderAddress][_snipeID].tokenStore),
            snipeInfo[_holderAddress][_snipeID].baseToken,
            snipeInfo[_holderAddress][_snipeID].snipeToken
        );
    }

    function withdrawTokens(uint _snipeID) external {
        SnipeData memory snipeData = snipeInfo[msg.sender][_snipeID];
        require(msg.sender == snipeData.sniperAddress, "Unauthorised");

        ITokenStore(snipeData.tokenStore).sendTokens(snipeData.snipeToken, msg.sender, 10000 - snipeData.tokenPercentageSold);
    }

    // **** ADMIN ONLY FUNCTIONS ****

    function setAdminAddress(address _adminAddress) external onlyAdmin {
        adminAddress = _adminAddress;
    }

    function setExchangeWrapper(address _routerAddress, address _exchangeWrapper) external onlyAdmin {
        exchangeWrappers[_routerAddress] = _exchangeWrapper;
    }

    // **** MISC FUNCTIONS ****

    function getTokenStore() private returns (address) {
        if (userTokenStore[msg.sender] == address(0)) userTokenStore[msg.sender] = address(new TokenStore());
    
        return userTokenStore[msg.sender];
    }
}