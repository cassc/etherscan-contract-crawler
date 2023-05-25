// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IDefiRound.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract DefiRound is IDefiRound, Ownable {
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    // solhint-disable-next-line
    address public immutable WETH;
    address public override immutable treasury;
    OversubscriptionRate public overSubscriptionRate;    
    mapping(address => uint256) public override totalSupply;
    // account -> accountData
    mapping(address => AccountData) private accountData;
    mapping(address => RateData) private tokenRates;
    
    //Token -> oracle, genesis
    mapping(address => SupportedTokenData) private tokenSettings;
    
    EnumerableSet.AddressSet private supportedTokens;
    EnumerableSet.AddressSet private configuredTokenRates;
    STAGES public override currentStage;

    WhitelistSettings public whitelistSettings;
    uint256 public lastLookExpiration  = type(uint256).max;
    uint256 private immutable maxTotalValue;
    bool private stage1Locked;

    constructor(
        // solhint-disable-next-line
        address _WETH,
        address _treasury,
        uint256 _maxTotalValue
    ) public {
        require(_WETH != address(0), "INVALID_WETH");
        require(_treasury != address(0), "INVALID_TREASURY");
        require(_maxTotalValue > 0, "INVALID_MAXTOTAL");

        WETH = _WETH;
        treasury = _treasury;
        currentStage = STAGES.STAGE_1;
        
        maxTotalValue = _maxTotalValue;
    }

    function deposit(TokenData calldata tokenInfo, bytes32[] memory proof) external payable override {
        require(currentStage == STAGES.STAGE_1, "DEPOSITS_NOT_ACCEPTED");
        require(!stage1Locked, "DEPOSITS_LOCKED");

        if (whitelistSettings.enabled) {            
            require(verifyDepositor(msg.sender, whitelistSettings.root, proof), "PROOF_INVALID");
        }

        TokenData memory data = tokenInfo;
        address token = data.token;
        uint256 tokenAmount = data.amount;
        require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
        require(tokenAmount > 0, "INVALID_AMOUNT");

        // Convert ETH to WETH if ETH is passed in, otherwise treat WETH as a regular ERC20
        if (token == WETH && msg.value > 0) {
            require(tokenAmount == msg.value, "INVALID_MSG_VALUE"); 
            IWETH(WETH).deposit{value: tokenAmount}();
        } else {
            require(msg.value == 0, "NO_ETH");
        }

        AccountData storage tokenAccountData = accountData[msg.sender];
    
        if (tokenAccountData.token == address(0)) {
            tokenAccountData.token = token;
        }
        
        require(tokenAccountData.token == token, "SINGLE_ASSET_DEPOSITS");

        tokenAccountData.initialDeposit = tokenAccountData.initialDeposit.add(tokenAmount);
        tokenAccountData.currentBalance = tokenAccountData.currentBalance.add(tokenAmount);
        
        require(tokenAccountData.currentBalance <= tokenSettings[token].maxLimit, "MAX_LIMIT_EXCEEDED");       

        // No need to transfer from msg.sender since is ETH was converted to WETH
        if (!(token == WETH && msg.value > 0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);    
        }
        
        if(_totalValue() > maxTotalValue) {
            stage1Locked = true;
        }

        emit Deposited(msg.sender, tokenInfo);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable 
    { 
        require(msg.sender == WETH);
    }

    function withdraw(TokenData calldata tokenInfo, bool asETH) external override {
        require(currentStage == STAGES.STAGE_2, "WITHDRAWS_NOT_ACCEPTED");
        require(!_isLastLookComplete(), "WITHDRAWS_EXPIRED");

        TokenData memory data = tokenInfo;
        address token = data.token;
        uint256 tokenAmount = data.amount;
        require(supportedTokens.contains(token), "UNSUPPORTED_TOKEN");
        require(tokenAmount > 0, "INVALID_AMOUNT");        
        AccountData storage tokenAccountData = accountData[msg.sender];
        require(token == tokenAccountData.token, "INVALID_TOKEN");
        tokenAccountData.currentBalance = tokenAccountData.currentBalance.sub(tokenAmount);
        // set the data back in the mapping, otherwise updates are not saved
        accountData[msg.sender] = tokenAccountData;

        // Don't transfer WETH, WETH is converted to ETH and sent to the recipient
        if (token == WETH && asETH) {
            IWETH(WETH).withdraw(tokenAmount);
            msg.sender.sendValue(tokenAmount);            
        }  else {
            IERC20(token).safeTransfer(msg.sender, tokenAmount);
        }
        
        emit Withdrawn(msg.sender, tokenInfo, asETH);
    }

    function configureWhitelist(WhitelistSettings memory settings) external override onlyOwner {
        whitelistSettings = settings;
        emit WhitelistConfigured(settings);
    }

    function addSupportedTokens(SupportedTokenData[] calldata tokensToSupport)
        external
        override
        onlyOwner
    {
        uint256 tokensLength = tokensToSupport.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            SupportedTokenData memory data = tokensToSupport[i];
            require(supportedTokens.add(data.token), "TOKEN_EXISTS");
            
            tokenSettings[data.token] = data;
        }
        emit SupportedTokensAdded(tokensToSupport);
    }

    function getSupportedTokens() external view override returns (address[] memory tokens) {
        uint256 tokensLength = supportedTokens.length();
        tokens = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            tokens[i] = supportedTokens.at(i);
        }
    }

    function publishRates(RateData[] calldata ratesData, OversubscriptionRate memory oversubRate, uint256 lastLookDuration) external override onlyOwner {
        // check rates havent been published before
        require(currentStage == STAGES.STAGE_1, "RATES_ALREADY_SET");
        require(lastLookDuration > 0, "INVALID_DURATION");
        require(oversubRate.overDenominator > 0, "INVALID_DENOMINATOR");
        require(oversubRate.overNumerator > 0, "INVALID_NUMERATOR");        
        
        uint256 ratesLength = ratesData.length;
        for (uint256 i = 0; i < ratesLength; i++) {
            RateData memory data = ratesData[i];
            require(data.numerator > 0, "INVALID_NUMERATOR");
            require(data.denominator > 0, "INVALID_DENOMINATOR");
            require(tokenRates[data.token].token == address(0), "RATE_ALREADY_SET");
            require(configuredTokenRates.add(data.token), "ALREADY_CONFIGURED");
            tokenRates[data.token] = data;            
        }

        require(configuredTokenRates.length() == supportedTokens.length(), "MISSING_RATE");

        // Stage only moves forward when prices are published
        currentStage = STAGES.STAGE_2;
        lastLookExpiration = block.number + lastLookDuration;
        overSubscriptionRate = oversubRate;

        emit RatesPublished(ratesData);
    }

    function getRates(address[] calldata tokens) external view override returns (RateData[] memory rates) {
        uint256 tokensLength = tokens.length;
        rates = new RateData[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            rates[i] = tokenRates[tokens[i]];
        }
    }

    function getTokenValue(address token, uint256 balance) internal view returns (uint256 value) {
        uint256 tokenDecimals = ERC20(token).decimals();
        (, int256 tokenRate, , , ) = AggregatorV3Interface(tokenSettings[token].oracle).latestRoundData();       
        uint256 rate = tokenRate.toUint256();        
        value = (balance.mul(rate)).div(10**tokenDecimals); //Chainlink USD prices are always to 8            
    }

    function totalValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256 value) {
        uint256 tokensLength = supportedTokens.length();
        for (uint256 i = 0; i < tokensLength; i++) {
            address token = supportedTokens.at(i);
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            value = value.add(getTokenValue(token, tokenBalance));
        }
    }

    function accountBalance(address account) external view override returns (uint256 value) {
        uint256 tokenBalance = accountData[account].currentBalance;
        value = value.add(getTokenValue(accountData[account].token, tokenBalance));   
    }

    function finalizeAssets(bool depositToGenesis) external override {
        require(currentStage == STAGES.STAGE_3, "NOT_SYSTEM_FINAL");
         
        AccountData storage data = accountData[msg.sender];
        address token = data.token;

        require(token != address(0), "NO_DATA");

        ( , uint256 ineffective, ) = _getRateAdjustedAmounts(data.currentBalance, token);
        
        require(ineffective > 0, "NOTHING_TO_MOVE");

        // zero out balance
        data.currentBalance = 0;
        accountData[msg.sender] = data;

        if (depositToGenesis) {  
            address pool = tokenSettings[token].genesis;         
            uint256 currentAllowance = IERC20(token).allowance(address(this), pool);
            if (currentAllowance < ineffective) {
                IERC20(token).safeIncreaseAllowance(pool, ineffective.sub(currentAllowance));    
            }            
            ILiquidityPool(pool).depositFor(msg.sender, ineffective);
            emit GenesisTransfer(msg.sender, ineffective);
        } else {
            // transfer ineffectiveTokenBalance back to user
            IERC20(token).safeTransfer(msg.sender, ineffective);
        }    

        emit AssetsFinalized(msg.sender, token, ineffective);        
    }

    function getGenesisPools(address[] calldata tokens)
        external
        view
        override
        returns (address[] memory genesisAddresses)
    {
        uint256 tokensLength = tokens.length;
        genesisAddresses = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
            genesisAddresses[i] = tokenSettings[supportedTokens.at(i)].genesis;            
        }
    }

    function getTokenOracles(address[] calldata tokens)
        external
        view
        override
        returns (address[] memory oracleAddresses)
    {
        uint256 tokensLength = tokens.length;
        oracleAddresses = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            require(supportedTokens.contains(tokens[i]), "TOKEN_UNSUPPORTED");
            oracleAddresses[i] = tokenSettings[tokens[i]].oracle;
        }
    }

    function getAccountData(address account) external view override returns (AccountDataDetails[] memory data) {
        uint256 supportedTokensLength = supportedTokens.length();
        data = new AccountDataDetails[](supportedTokensLength);
        for (uint256 i = 0; i < supportedTokensLength; i++) {
            address token = supportedTokens.at(i);
            AccountData memory accountTokenInfo = accountData[account];
            if (currentStage >= STAGES.STAGE_2 && accountTokenInfo.token != address(0)) {
                (uint256 effective, uint256 ineffective, uint256 actual) = _getRateAdjustedAmounts(accountTokenInfo.currentBalance, token);
                AccountDataDetails memory details = AccountDataDetails(
                    token, 
                    accountTokenInfo.initialDeposit, 
                    accountTokenInfo.currentBalance, 
                    effective, 
                    ineffective, 
                    actual
                );
                data[i] = details;
            } else {
                data[i] = AccountDataDetails(token, accountTokenInfo.initialDeposit, accountTokenInfo.currentBalance, 0, 0, 0);
            }          
        }
    }

    function transferToTreasury() external override onlyOwner {
        require(_isLastLookComplete(), "CURRENT_STAGE_INVALID");
        require(currentStage == STAGES.STAGE_2, "ONLY_TRANSFER_ONCE");

        uint256 supportedTokensLength = supportedTokens.length();
        TokenData[] memory tokens = new TokenData[](supportedTokensLength);
        for (uint256 i = 0; i < supportedTokensLength; i++) {       
            address token = supportedTokens.at(i);  
            uint256 balance = IERC20(token).balanceOf(address(this));
            (uint256 effective, , ) = _getRateAdjustedAmounts(balance, token);
            tokens[i].token = token;
            tokens[i].amount = effective;
            IERC20(token).safeTransfer(treasury, effective);
        }

        currentStage = STAGES.STAGE_3;

        emit TreasuryTransfer(tokens);
    }
    
   function getRateAdjustedAmounts(uint256 balance, address token) external override view returns (uint256,uint256,uint256) {
        return _getRateAdjustedAmounts(balance, token);
    }

    function getMaxTotalValue() external view override returns (uint256) {
        return maxTotalValue;
    }

    function _getRateAdjustedAmounts(uint256 balance, address token) internal view returns (uint256,uint256,uint256) {
        require(currentStage >= STAGES.STAGE_2, "RATES_NOT_PUBLISHED");

        RateData memory rateInfo = tokenRates[token];
        uint256 effectiveTokenBalance = 
            balance.mul(overSubscriptionRate.overNumerator).div(overSubscriptionRate.overDenominator);
        uint256 ineffectiveTokenBalance =
            balance.mul(overSubscriptionRate.overDenominator.sub(overSubscriptionRate.overNumerator))
            .div(overSubscriptionRate.overDenominator);
        
        uint256 actualReceived =
            effectiveTokenBalance.mul(rateInfo.denominator).div(rateInfo.numerator);

        return (effectiveTokenBalance, ineffectiveTokenBalance, actualReceived);
    }

    function verifyDepositor(address participant, bytes32 root, bytes32[] memory proof) internal pure returns (bool) {
        bytes32 leaf = keccak256((abi.encodePacked((participant))));
        return MerkleProof.verify(proof, root, leaf);
    }

    function _isLastLookComplete() internal view returns (bool) {
        return block.number >= lastLookExpiration;
    }
}