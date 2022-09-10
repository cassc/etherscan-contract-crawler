// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ICoreEvent.sol";
import "../interfaces/ILiquidityPool.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract CoreEvent is Ownable, ICoreEvent {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Contains start block and duration
    DurationInfo public durationInfo;
    
    address public immutable treasuryAddress;

    EnumerableSet.AddressSet private supportedTokenAddresses;

    // token address -> SupportedTokenData
    mapping(address => SupportedTokenData) public supportedTokens;

    // user -> token -> AccountData
    mapping(address => mapping(address => AccountData)) public accountData;
    mapping(address => RateData) public tokenRates;

    WhitelistSettings public whitelistSettings;
    
    bool public stage1Locked;

    modifier hasEnded() {        
        require(_hasEnded(), "TOO_EARLY");
        _;
    }

    constructor(
        address treasury,
        SupportedTokenData[] memory tokensToSupport
    ) public {
        treasuryAddress = treasury;
        addSupportedTokens(tokensToSupport);
    }

    function configureWhitelist(WhitelistSettings memory settings) external override onlyOwner {
        whitelistSettings = settings;
        emit WhitelistConfigured(settings);
    }

    function setDuration(uint256 _blockDuration) external override onlyOwner {
        require(durationInfo.startingBlock == 0, "ALREADY_STARTED");

        durationInfo.startingBlock = block.number;
        durationInfo.blockDuration = _blockDuration;

        emit DurationSet(durationInfo);
    }

    function addSupportedTokens(SupportedTokenData[] memory tokensToSupport) public override onlyOwner {
        require (tokensToSupport.length > 0, "NO_TOKENS");

        for (uint256 i = 0; i < tokensToSupport.length; ++i) {
            require(
                !supportedTokenAddresses.contains(tokensToSupport[i].token),
                "DUPLICATE_TOKEN"
            );
            require(tokensToSupport[i].token != address(0), "ZERO_ADDRESS");
            require(!tokensToSupport[i].systemFinalized, "FINALIZED_MUST_BE_FALSE");

            require(supportedTokenAddresses.add(tokensToSupport[i].token), "ADD_FAIL");
            supportedTokens[tokensToSupport[i].token] = tokensToSupport[i];
        }
        emit SupportedTokensAdded(tokensToSupport);
    }


    function deposit(TokenData[] calldata tokenData, bytes32[] calldata proof) external override {
        require(durationInfo.startingBlock > 0, "NOT_STARTED");
        require(!_hasEnded(), "RATES_LOCKED");
        require(tokenData.length > 0, "NO_TOKENS");
        
        if (whitelistSettings.enabled) {            
            require(verifyDepositor(msg.sender, whitelistSettings.root, proof), "PROOF_INVALID");
        }

        for (uint256 i = 0; i < tokenData.length; ++i) {

            uint256 amount = tokenData[i].amount;
            require(amount > 0, "0_BALANCE");  
            address token = tokenData[i].token;
            require(supportedTokenAddresses.contains(token), "NOT_SUPPORTED");
            IERC20 erc20Token = IERC20(token);

            AccountData storage data = accountData[msg.sender][token];        

            /// Check that total user deposits do not exceed token limit
            require(
                data.depositedBalance.add(amount) <= supportedTokens[token].maxUserLimit,
                "OVER_LIMIT"
            );

            data.depositedBalance = data.depositedBalance.add(amount);

            data.token = token;

            erc20Token.safeTransferFrom(msg.sender, address(this), amount);
        }

        emit Deposited(msg.sender, tokenData);
    }

    function withdraw(TokenData[] calldata tokenData) external override {
        require(!_hasEnded(), "RATES_LOCKED");
        require(tokenData.length > 0, "NO_TOKENS");
        
        for (uint256 i = 0; i < tokenData.length; ++i) {  

            uint256 amount = tokenData[i].amount;
            require(amount > 0, "ZERO_BALANCE");
            address token = tokenData[i].token;
            IERC20 erc20Token = IERC20(token);

            AccountData storage data = accountData[msg.sender][token];
            
            require(data.token != address(0), "ZERO_ADDRESS");
            require(amount <= data.depositedBalance, "INSUFFICIENT_FUNDS");

            data.depositedBalance = data.depositedBalance.sub(amount);

            if (data.depositedBalance == 0) {
                delete accountData[msg.sender][token];
            }
            erc20Token.safeTransfer(msg.sender, amount);
        }

        emit Withdrawn(msg.sender, tokenData);
    }

    function increaseDuration(uint256 _blockDuration) external override onlyOwner {
        require(durationInfo.startingBlock > 0, "NOT_STARTED");
        require(_blockDuration > durationInfo.blockDuration, "INCREASE_ONLY");
        require(!stage1Locked, "STAGE1_LOCKED");

        durationInfo.blockDuration = _blockDuration;

        emit DurationIncreased(durationInfo);
    }

    
    function setRates(RateData[] calldata rates) external override onlyOwner hasEnded {
        
        //Rates are settable multiple times, but only until they are finalized.
        //They are set to finalized by either performing the transferToTreasury
        //Or, by marking them as no-swap tokens
        //Users cannot begin their next set of actions before a token finalized.
        
        uint256 length = rates.length;
        for (uint256 i = 0; i < length; ++i) {   
            RateData memory data = rates[i];
            require(supportedTokenAddresses.contains(data.token), "UNSUPPORTED_ADDRESS");
            require(!supportedTokens[data.token].systemFinalized, "ALREADY_FINALIZED");

            if (data.tokeNumerator > 0) {
                //We are allowing an address(0) pool, it means it was a winning reactor
                //but there wasn't enough to enable private farming                
                require(data.tokeDenominator > 0, "INVALID_TOKE_DENOMINATOR");            
                require(data.overNumerator > 0, "INVALID_OVER_NUMERATOR");
                require(data.overDenominator > 0, "INVALID_OVER_DENOMINATOR");            

                tokenRates[data.token] = data;
            } else {
                delete tokenRates[data.token];
            }
        }

        stage1Locked = true;

        emit RatesPublished(rates);
    }

    function transferToTreasury(address[] calldata tokens) external override onlyOwner hasEnded {
        
        uint256 length = tokens.length;
        TokenData[] memory transfers = new TokenData[](length);
        for (uint256 i = 0; i < length; ++i) {                   
            address token = tokens[i];            
            require(tokenRates[token].tokeNumerator > 0, "NO_SWAP_TOKEN");
            require(!supportedTokens[token].systemFinalized, "ALREADY_FINALIZED");
            uint256 balance = IERC20(token).balanceOf(address(this));
            (uint256 effective, , ) = getRateAdjustedAmounts(balance, token);            
            transfers[i].token = token;
            transfers[i].amount = effective;
            supportedTokens[token].systemFinalized = true;

            IERC20(token).safeTransfer(treasuryAddress, effective);
        }

        emit TreasuryTransfer(transfers);
    }

    function setNoSwap(address[] calldata tokens) external override onlyOwner hasEnded {
        
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; ++i) { 
            address token = tokens[i];
            require(supportedTokenAddresses.contains(token), "UNSUPPORTED_ADDRESS");
            require(tokenRates[token].tokeNumerator == 0, "ALREADY_SET_TO_SWAP");
            require(!supportedTokens[token].systemFinalized, "ALREADY_FINALIZED");

            supportedTokens[token].systemFinalized = true;
        }

        stage1Locked = true;

        emit SetNoSwap(tokens);
    }

    function finalize(TokenFarming[] calldata tokens) external override hasEnded {        
        require(tokens.length > 0, "NO_TOKENS");        
        
        uint256 length = tokens.length;
        FinalizedAccountData[] memory results = new FinalizedAccountData[](length);
        for(uint256 i = 0; i < length; ++i) {
            TokenFarming calldata farm = tokens[i];
            AccountData storage account = accountData[msg.sender][farm.token];
                        
            require(!account.finalized, "ALREADY_FINALIZED");
            require(farm.token != address(0), "ZERO_ADDRESS");
            require(supportedTokens[farm.token].systemFinalized, "NOT_SYSTEM_FINALIZED");    
            require(account.depositedBalance > 0, "INSUFFICIENT_FUNDS");            

            RateData storage rate = tokenRates[farm.token];
            
            uint256 amtToTransfer = 0;
            if (rate.tokeNumerator > 0) {
                //We have set a rate, which means its a winning reactor
                //which means only the ineffective amount, the amount
                //not spent on TOKE, can leave the contract.
                //Leaving to either the farm or back to the user

                //In the event there is no farming, an oversubscription rate of 1/1 
                //will be provided for the token. That will ensure the ineffective
                //amount is 0 and caught by the below require() as only assets with 
                //an oversubscription can be moved
                (, uint256 ineffectiveAmt, ) = getRateAdjustedAmounts(account.depositedBalance, farm.token);     
                amtToTransfer = ineffectiveAmt;
            } else {
                amtToTransfer = account.depositedBalance;                
            }   
            require(amtToTransfer > 0, "NOTHING_TO_MOVE");      
            account.finalized = true;

            if (farm.sendToFarming) {
                require(rate.pool != address(0), "NO_FARMING");    
                uint256 currentAllowance = IERC20(farm.token).allowance(address(this), rate.pool);
                if (currentAllowance < amtToTransfer) {                    
                    IERC20(farm.token).safeIncreaseAllowance(rate.pool, amtToTransfer.sub(currentAllowance));                        
                }                
                // Deposit to pool
                ILiquidityPool(rate.pool).depositFor(msg.sender, amtToTransfer);                
                results[i] = FinalizedAccountData({
                    token: farm.token,
                    transferredToFarm: amtToTransfer,
                    refunded: 0
                });
            } else {  // If user wants withdrawn and no private farming
                IERC20(farm.token).safeTransfer(msg.sender, amtToTransfer);
                results[i] = FinalizedAccountData({
                    token: farm.token,
                    transferredToFarm: 0,
                    refunded: amtToTransfer
                });
            }
        }

        emit AssetsFinalized(msg.sender, results);
    }

    function getRateAdjustedAmounts(uint256 balance, address token) public override view returns (uint256 effectiveAmt, uint256 ineffectiveAmt, uint256 actualReceived) {
        
        RateData memory rateInfo = tokenRates[token];
        // Amount eligible to be transferred for Toke
        uint256 effectiveTokenBalance = 
            balance.mul(rateInfo.overNumerator).div(rateInfo.overDenominator);
        // Amount to be withdrawn or sent to private farming
        uint256 ineffectiveTokenBalance =
            balance.mul(rateInfo.overDenominator.sub(rateInfo.overNumerator))
            .div(rateInfo.overDenominator);
        
        uint256 actual =
            effectiveTokenBalance.mul(rateInfo.tokeDenominator).div(rateInfo.tokeNumerator);

        return (effectiveTokenBalance, ineffectiveTokenBalance, actual);
    }

    function getRates() external override view returns (RateData[] memory rates) {
        uint256 length = supportedTokenAddresses.length();
        rates = new RateData[](length);
        for (uint256 i = 0; i < length; ++i) {   
            address token = supportedTokenAddresses.at(i);
            rates[i] = tokenRates[token];
        }        
    }

    function getAccountData(address account) external view override returns (AccountData[] memory data) {
        uint256 length = supportedTokenAddresses.length();        
        data = new AccountData[](length);
        for(uint256 i = 0; i < length; ++i) {
            address token = supportedTokenAddresses.at(i);
            data[i] = accountData[account][token];
            data[i].token = token;
        }
    }

    function getSupportedTokens() external view override returns (SupportedTokenData[] memory supportedTokensArray) {
        uint256 supportedTokensLength = supportedTokenAddresses.length();
        supportedTokensArray = new SupportedTokenData[](supportedTokensLength);

        for (uint256 i = 0; i < supportedTokensLength; ++i) {
            supportedTokensArray[i] = supportedTokens[supportedTokenAddresses.at(i)];
        }
        return supportedTokensArray;
    }

    function _hasEnded() private view returns (bool) {
        return durationInfo.startingBlock > 0 && block.number >= durationInfo.blockDuration + durationInfo.startingBlock;
    }

    function verifyDepositor(address participant, bytes32 root, bytes32[] memory proof) internal pure returns (bool) {
        bytes32 leaf = keccak256((abi.encodePacked((participant))));
        return MerkleProof.verify(proof, root, leaf);
    }    
}