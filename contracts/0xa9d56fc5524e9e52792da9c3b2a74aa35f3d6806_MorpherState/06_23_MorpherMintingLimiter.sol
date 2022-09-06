//SPDX-License-Identifier: GPLv3
pragma solidity 0.8.11;

import "./MorpherAccessControl.sol";
import "./MorpherState.sol";
import "./MorpherTradeEngine.sol";
import "./MorpherToken.sol";


contract MorpherMintingLimiter {

    bytes32 constant public ADMINISTRATOR_ROLE = keccak256("ADMINISTRATOR_ROLE");

    uint256 public mintingLimitPerUser;
    uint256 public mintingLimitDaily;
    uint256 public timeLockingPeriod;

    mapping(address => uint256) public escrowedTokens;
    mapping(address => uint256) public lockedUntil;
    mapping(uint256 => uint256) public dailyMintedTokens;

    address tradeEngineAddress; 
    MorpherState state;

    event MintingEscrowed(address _user, uint256 _tokenAmount);
    event EscrowReleased(address _user, uint256 _tokenAmount);
    event MintingDenied(address _user, uint256 _tokenAmount);
    event MintingLimitUpdatedPerUser(uint256 _mintingLimitOld, uint256 _mintingLimitNew);
    event MintingLimitUpdatedDaily(uint256 _mintingLimitOld, uint256 _mintingLimitNew);
    event TimeLockPeriodUpdated(uint256 _timeLockPeriodOld, uint256 _timeLockPeriodNew);
    event TradeEngineAddressSet(address _tradeEngineAddress);
    event DailyMintedTokensReset();

    modifier onlyTradeEngine() {
        require(msg.sender == state.morpherTradeEngineAddress(), "MorpherMintingLimiter: Only Trade Engine is allowed to call this function");
        _;
    }

    modifier onlyAdministrator() {
        require(MorpherAccessControl(state.morpherAccessControlAddress()).hasRole(ADMINISTRATOR_ROLE, msg.sender), "MorpherMintingLimiter: Only Administrator can call this function");
        _;
    }

    constructor(address _stateAddress, uint256 _mintingLimitPerUser, uint256 _mintingLimitDaily, uint256 _timeLockingPeriodInSeconds) {
        state = MorpherState(_stateAddress);
        mintingLimitPerUser = _mintingLimitPerUser;
        mintingLimitDaily = _mintingLimitDaily;
        timeLockingPeriod = _timeLockingPeriodInSeconds;
    }

    function setTradeEngineAddress(address _tradeEngineAddress) public onlyAdministrator {
        emit TradeEngineAddressSet(_tradeEngineAddress);
        tradeEngineAddress = _tradeEngineAddress;
    }
    

    function setMintingLimitDaily(uint256 _newMintingLimit) public onlyAdministrator {
        emit MintingLimitUpdatedDaily(mintingLimitDaily, _newMintingLimit);
        mintingLimitDaily = _newMintingLimit;
    }
    function setMintingLimitPerUser(uint256 _newMintingLimit) public onlyAdministrator {
        emit MintingLimitUpdatedPerUser(mintingLimitDaily, _newMintingLimit);
        mintingLimitPerUser = _newMintingLimit;
    }

    function setTimeLockingPeriod(uint256 _newTimeLockingPeriodInSeconds) public onlyAdministrator {
        emit TimeLockPeriodUpdated(timeLockingPeriod, _newTimeLockingPeriodInSeconds);
        timeLockingPeriod = _newTimeLockingPeriodInSeconds;
    }

    function mint(address _user, uint256 _tokenAmount) public onlyTradeEngine {
        uint256 mintingDay = block.timestamp / 1 days;
        if((mintingLimitDaily == 0 || dailyMintedTokens[mintingDay] + (_tokenAmount) <= mintingLimitDaily) && (mintingLimitPerUser == 0 || _tokenAmount <= mintingLimitPerUser )) {
            MorpherToken(state.morpherTokenAddress()).mint(_user, _tokenAmount);
            dailyMintedTokens[mintingDay] = dailyMintedTokens[mintingDay] + (_tokenAmount);
        } else {
            escrowedTokens[_user] = escrowedTokens[_user] + (_tokenAmount);
            lockedUntil[_user] = block.timestamp + timeLockingPeriod;
            emit MintingEscrowed(_user, _tokenAmount);
        }
    }

    function delayedMint(address _user) public {
        require(lockedUntil[_user] <= block.timestamp, "MorpherMintingLimiter: Funds are still time locked");
        uint256 sendAmount = escrowedTokens[_user];
        escrowedTokens[_user] = 0;
        MorpherToken(state.morpherTokenAddress()).mint(_user, sendAmount);
        emit EscrowReleased(_user, sendAmount);
    }

    function adminApprovedMint(address _user, uint256 _tokenAmount) public onlyAdministrator {
        escrowedTokens[_user] = escrowedTokens[_user] - (_tokenAmount);
        MorpherToken(state.morpherTokenAddress()).mint(_user, _tokenAmount);
        emit EscrowReleased(_user, _tokenAmount);
    }

    function adminDisapproveMint(address _user, uint256 _tokenAmount) public onlyAdministrator {
        escrowedTokens[_user] = escrowedTokens[_user] - (_tokenAmount);
        emit MintingDenied(_user, _tokenAmount);
    }

    function resetDailyMintedTokens() public onlyAdministrator {
        dailyMintedTokens[block.timestamp / 1 days] = 0;
        emit DailyMintedTokensReset();
    }

    function getDailyMintedTokens() public view returns(uint256) {
        return dailyMintedTokens[block.timestamp / 1 days];
    }
}