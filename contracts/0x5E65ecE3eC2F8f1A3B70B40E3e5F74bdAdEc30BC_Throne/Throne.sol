/**
 *Submitted for verification at Etherscan.io on 2022-10-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0<0.9.0;

interface IERC20 {
    function burn(uint256 _tokens) external;
    function allowance(address, address) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address _spender, uint256 _tokens) external returns (bool);
    function totalSupply() external view returns (uint256);
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function setApprovalForAll(address _operator, bool _approved) external;
}

interface IClaimable {
	function claim() external;
    function rewardsOf(address _user) external view returns (uint256);
    function allInfoFor(address _owner) external view returns (uint256 supply, uint256 whales, uint256 balance, uint256 ownerWhales, uint256 fmRewards, uint256 whRewards, uint256 dailyKrill);
    function getIsWhale(uint256 _tokenId) external view returns (bool);
    function fishermenRewardsOf(address _owner) external view returns (uint256);
    function whaleRewardsOf(address _owner) external view returns (uint256);
    function deposit(uint256 _amount) external;
    function withdraw() external returns (uint256);
	function dividendsOf(address _user) external view returns (uint256);
    function depositedOf(address _user) external view returns (uint256);
    function withdrawAll() external;
}

interface IGuildRegistry {
    function isGuild(address _who) external view returns (bool);
    function throneChest(address _guild, address _throne) external view returns (address);
}

contract RewardEngine {
    bool public wrapperClaimOverride;

    function _claimRewardsFromAll(address _staking, address _liquidity, address _whalesGame, address _wFM, address _wWH, address _cKRILL, uint _minimumKRILL, uint _minimumLP)
    internal {
        address _this = address(this);                                                          // shorthand
        uint wgRewards =                                                                        // wg rewards are the sum of
            IClaimable(_whalesGame).fishermenRewardsOf(_this) +                                     // fishermen rewards
                IClaimable(_whalesGame).whaleRewardsOf(_this);                                          // whale rewards
        uint LPBalance = IERC20(_liquidity).balanceOf(_this);                                   // load LP balance into memory
        if(LPBalance >= _minimumLP)                                                             // are there any LP tokens?
            IClaimable(_staking).deposit(LPBalance);                                                // deposit the entire amount into the StakingRewards contract
        if(IClaimable(_staking).rewardsOf(_this) >= _minimumKRILL)                              // if there are pending LP staking rewards greater than or equal to the MINIMUM
            IClaimable(_staking).claim();                                                            // Claim rewards from the LP staking contract
        if(wgRewards >= _minimumKRILL)                                                          // if the pending rewards from the whales game contract is greater than or equal to MINIMUM
		    IClaimable(_whalesGame).claim();                                                        // Claim rewards from the whales game contract
        if(IClaimable(_wFM).rewardsOf(_this) >= _minimumKRILL || wrapperClaimOverride == true)  // if the pending rewards from the whales game contract is greater than or equal to MINIMUM OR if the wrapper claim override is true
		    IClaimable(_wFM).claim();                                                               // Claim rewards from the fishermen wrapper contract
        if(IClaimable(_wWH).rewardsOf(_this) >= _minimumKRILL || wrapperClaimOverride == true)  // if the pending rewards from the whales game contract is greater than or equal to MINIMUM OR if the wrapper claim override is true
		    IClaimable(_wWH).claim();                                                               // Claim rewards from the whales wrapper contract
		if(IClaimable(_cKRILL).dividendsOf(_this) >= _minimumKRILL)                             // If this contract has rewards to claim
			IClaimable(_cKRILL).withdraw();                                                         // Claim rewards from the cKRILL held by this contract
    }
    function _calculateKRILLToClaim(address _staking, address _whalesGame, address _wFM, address _wWH, address _cKRILL, address _KRILL, uint _minimum)
    internal view returns (uint) {
        address _this = address(this);                                                      // shorthand
        uint total = IERC20(_KRILL).balanceOf(_this);                                       // current krill balance of this contract                                                      
        uint wgRewards =                                                                    // wg rewards are the sum of
            IClaimable(_whalesGame).fishermenRewardsOf(_this) +                                 // fishermen rewards
                IClaimable(_whalesGame).whaleRewardsOf(_this);                                      // whale rewards
        if(wgRewards >= _minimum)                                                           // if the pending rewards from the whales game contract is greater than or equal to MINIMUM
            total += wgRewards;                                                                 // add the pending rewards to the total
        if(IClaimable(_staking).rewardsOf(_this) >= _minimum)                               // if there are pending LP staking rewards greater than or equal to the MINIMUM
            total += IClaimable(_staking).rewardsOf(_this);                                     // add the pending rewards to the total
        if(IClaimable(_wFM).rewardsOf(_this) >= _minimum || wrapperClaimOverride == true)   // if the pending rewards from the wFM contract is greater than or equal to MINIMUM OR if the wrapper claim override is true
            total += IClaimable(_wFM).rewardsOf(_this);                                         // rewards from wFM held
        if(IClaimable(_wWH).rewardsOf(_this) >= _minimum || wrapperClaimOverride == true)   // if the pending rewards from the wWH contract is greater than or equal to MINIMUM OR if the wrapper claim override is true
            total += IClaimable(_wWH).rewardsOf(_this);                                         // rewards from wWH held
        if(IClaimable(_cKRILL).dividendsOf(_this) >= _minimum)                              // If this contract has rewards to claim
            total += IClaimable(_cKRILL).dividendsOf(_this);                                    // pending compounder dividends
        return total;                                                                       // return grand total
    }
}

contract Ownable {
    address public owner;

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _owner)
    external _onlyOwner {
        owner = _owner;
    }
}

interface IWG {
    function krillAddress() external view returns (address);
    function pairAddress() external view returns (address);
    function stakingRewardsAddress() external view returns (address);
    function fishermenOf(address _owner) external view returns (uint256);
    function whalesOf(address _owner) external view returns (uint256);
}

interface IIsland {
    function wrappedFishermenAddress() external view returns (address);
    function wrappedWhalesAddress() external view returns (address);
}

interface IKRILL2 {
    function whalesGameAddress() external view returns (address);
}

contract KRILLCommon is Ownable, RewardEngine {
    address immutable public BURNER = address(0x000000000000000000000000000000000000dEaD);  // address of the BURNER - this is where burned tokens go
    address immutable public KRILL;             // address of the KRILL token
    address immutable public cKRILL;            // address of the cKRILL token
    address immutable public wFM;               // address of the wFM token
    address immutable public wWH;               // address of the wWH token                                                        
    address immutable public whalesGame;        // address of the whales game contract
    address immutable public staking;           // address of the LP staking contract
    address immutable public liquidity;         // address of the LP token
    uint public MINIMUM_KRILL = 1e18;           // minimum token threshold of 1 krill
    uint public MINIMUM_LP = 1e18;              // minimum LP token threshold of 1 token

    modifier claiming() {
        _claimRewardsFromAll(staking, liquidity, whalesGame, wFM, wWH, cKRILL, MINIMUM_KRILL, MINIMUM_LP);  // claim rewards from reward sources 
        _;
    }

    constructor (address _cKRILL, address _KRILL, address _ISLAND) {
        address whalesGame_ = IKRILL2(_KRILL).whalesGameAddress();      // get the address of the whales game contract
        KRILL = IWG(whalesGame_).krillAddress();                        // get the KRILL address from the whales game contract
        cKRILL = _cKRILL;                                               // address of the cKRILL token
        wFM = IIsland(_ISLAND).wrappedFishermenAddress();               // address of the wFM token
        wWH = IIsland(_ISLAND).wrappedWhalesAddress();                  // address of the wWH token
        whalesGame = whalesGame_;                                       // set the whales game contract
        address staking_ = IWG(whalesGame_).stakingRewardsAddress();    // get the LP staking contract address from the whales game contract
        staking = staking_;                                             // set the LP staking contract
        address liquidity_ = IWG(whalesGame_).pairAddress();            // get the LP address from the whales game contract
        liquidity = liquidity_;                                         // set the LP token
        IERC20(liquidity_).approve(staking_, type(uint256).max);        // approve the maximum amount of LP tokens for the staking contract
    }

    function _claimRewards()
    internal claiming {}

    function setMinimums(uint _krillMinimum, uint _LPMinimum)
    external _onlyOwner {
        require(_krillMinimum > 0);     // require that the krill minimum amount is greater than zero
        require(_LPMinimum > 0);        // require that the LP minimum amount is greater than zero
        MINIMUM_KRILL = _krillMinimum;  // set the minimum krill threshold
        MINIMUM_LP = _LPMinimum;        // set the minimum LP threshold
    }

    function setWrapperClaimOverride(bool _override)
    external _onlyOwner {
        wrapperClaimOverride = _override;
    }
}

interface IWrapper {
    function unwrap(uint256[] calldata _tokenIds) external returns (uint256 totalUnwrapped);
}

interface IPermissionGate {
    function viewGate(address _what) external view returns (bool);
}

contract WrappedTokenBurner is KRILLCommon {
    constructor (address _cKRILL, address _KRILL, address _ISLAND)
    KRILLCommon(_cKRILL, _KRILL, _ISLAND) {}

    function _unwrap(address _what)
    internal {
        uint[] memory IDs = new uint[](1);                                  // create array
        uint tokenID = IERC721(whalesGame).tokenOfOwnerByIndex(_what, 0);   // get the token ID of the NFT
        IDs[0] = tokenID;                                                   // add the token ID to the array
        IWrapper(_what).unwrap(IDs);                                        // unwrap the tokens using the array of IDs
    }

    function burn(address _what)
    external claiming {
        require(_what == wFM || _what == wWH);                              // only allow burning of wFM or wWH tokens
        address _this = address(this);                                      // shorthand
        uint balance = IERC20(_what).balanceOf(_this);                      // load wFM balance into memory
        require(balance >= 1e18);                                           // require that the balance is greater than or equal to the requested amount
        _unwrap(_what);                                                     // unwrap the tokens
        uint tokenID = IERC721(whalesGame).tokenOfOwnerByIndex(_this, 0);   // get the token ID of the NFT
        IERC721(whalesGame).transferFrom(_this, BURNER, tokenID);           // transfer the NFT to the burn address
        uint KRILLBalance = IERC20(KRILL).balanceOf(_this);                 // load the KRILL balance into memory
        if(KRILLBalance > 0)                                                // if the KRILL balance is greater than 0
            IERC20(KRILL).transfer(msg.sender, KRILLBalance);                   // transfer the KRILL balance to the sender as reward
    }
}

contract PermissionGate is Ownable {
    address immutable public registry;          // address of the guild registry contract

    mapping(address => bool) public allowed;    // mapping of addresses to boolean values indicating whether or not they are allowed by the permissiongate

    constructor(address _registry) {
        registry = _registry;
        owner = msg.sender;
    }

    function toggleGate(address _what)
    external _onlyOwner {
        allowed[_what] = !allowed[_what];
    }
    function viewGate(address _what)
    external view returns (bool) {
        return (IGuildRegistry(registry).isGuild(_what) || allowed[_what]);
    }
}

contract ThroneCore is KRILLCommon {
    struct EpochData {
        address player;
        address caller;
        uint96 stamp;
    }
    
    address immutable public input;                                 // address of the token to be burned
    address public winner;                                          // address of the winner
    address public permissionGate;                                  // address of the permission gate - a contract that determines which contracts can be granted permission to use other accounts' approvals to play
    address public wrapperBurner;                                   // address of the wrapper burner
    address public registry;                                        // address of the guild registry contract
    address public feeDestination;                                  // address of the fee destination
    address public secondThrone;                                    // address of the other Throne that this Throne feeds
    address public islandThrone;                                    // address of the island Throne that this Throne feeds
    bool public shutDown;                                           // flag to indicate if the throne is shut down - can only be shut down within two weeks of the throne starting
    uint public startStamp;                                         // timestamp of when the throne is playable
    uint public decayRate;                                          // decay rate of the throne input
    uint public potFee = 0;                                         // fee percentage of the total reward
    uint public epochCounter;                                       // current epoch counter
    uint public playAmountCap;                                      // maximum amount of tokens that can be used to play per transaction
    uint public totalRawScores;                                     // all-time total raw scores from all players
    uint public totalBurned;                                        // all-time total burns
    uint public totalPlayers;                                       // all-time total players
    uint public winnerSlashRate;                                    // the score penalty to apply to the winner's score when non-winners play, based on the amount played by non-winners
    uint public krillSupplyAtLaunch;                                // the total krill supply, tracked at launch
    address[] public players;                                       // array of all players

    mapping(address => uint) public entered;                        // total amount of tokens burned for a given address
    mapping(address => uint) public last;                           // lastUsed timestamp of interaction for a given address
    mapping(uint => EpochData) public epochs;                       // epoch data for a given epoch
    mapping(address => uint) public rawScores;                      // "raw" score which has no decay and also includes score from playing "for" an entity such as a guild etc
    mapping(address => mapping(address => bool)) public permission; // mapping of addresses to mapping of addresses to boolean values indicating whether or not they are allowed to use a player's tokens to play
    mapping(address => mapping(address => uint)) public winnings;   // mapping of addresses to asset addresses to total winnings for that asset
    mapping(address => uint) public totalWinnings;                  // mapping of assets to all-time total winnings for that asset
    mapping(address => bool) public tracked;                        // mapping of addresses to boolean indicating if they are tracked as a player or not
    mapping(address => uint) public controlTime;                    // mapping of addresses to uint tracking how long they've maintained control over the throne
    mapping(address => uint) public rawScorePlayedForOthers;        // mapping of addresses to uint tracking the amount of their raw score that came from playing for others (guilds etc)

    event ThroneTaken(uint indexed _epoch, address indexed _takenFrom, address indexed _takenBy);
    event Played(uint indexed _epoch, address indexed _who, address indexed _from, uint _amount);

    modifier onlyPlayable() {
        require(decayRate > 0);                 // require that the decay rate is configured
        require(startStamp > 0);                // require that the start stamp is configured
        require(block.timestamp >= startStamp); // require that the block timestamp is greater than the start stamp
        require(shutDown == false);             // require that the throne is not shut down
        _;
    }

    constructor(address _input, address _cKRILL, address _KRILL, address _ISLAND)
    KRILLCommon(_cKRILL, _KRILL, _ISLAND) {
        input = _input;
        krillSupplyAtLaunch = IERC20(_KRILL).totalSupply();
    }

    function _calcScore(address _who, uint _time)
    internal view returns (uint) {
        uint decayed = _time * decayRate;                               // linear decay
        return decayed >= entered[_who] ? 0 : entered[_who] - decayed;  // the result can't be less than zero
    }
    function _calcTime(uint _now, uint _lastUsed, uint _winnerStamp)
    internal pure returns (uint, uint) {
        uint whoTime = _now - _lastUsed;        // the difference between now and when the contract was last used by an arbitrary account
        uint winnerTime = _now - _winnerStamp;  // the difference between now and when the contract was last used by the winner
        return (whoTime, winnerTime);           // return the differences
    }
    function _slashWinner(uint _amount)
    internal {
        uint time;                                                          // time delta for winner interaction
        uint score;                                                         // winner score calculation
        uint slashAmount;                                                   // how many tokens to remove from the winner's score
        uint _now = block.timestamp;                                        // shorthand
        (,time) = _calcTime(_now, 0, last[winner]);                         // calculate time delta for interaction
        score = _calcScore(winner, time);                                   // calculate score
        slashAmount = (_amount / 100) * winnerSlashRate;                    // calculate amount to slash from winner score (x/100% of input)
        entered[winner] = score <= slashAmount ? 0 : score - slashAmount;   // update the winner's score - check for underflow
        last[winner] = _now;                                                // update the winner's last interaction timestamp
    }
    function _calculateFee(uint _amount)
    internal view returns (uint, uint) {
        uint feeAmount;                         // amount to send to the fee destination
        uint postFeeAmount;                     // amount after fee
        feeAmount = (_amount / 100) * potFee;   // calculate fee amount
        postFeeAmount = _amount - feeAmount;    // calculate post-fee amount
        return (feeAmount, postFeeAmount);      // return the fee and post-fee amounts
    }
    function _nonZeroTransferAll(address _asset, address _to)
    internal {
        address _this = address(this);                                          // shorthand
        uint balance = IERC20(_asset).balanceOf(_this);                         // load current token balance into memory
        if(registry != address(0)) {                                            // if the guild registry is configured 
            bool isGuild = IGuildRegistry(registry).isGuild(_to);                   // determine if _to is a guild
            _to = isGuild ? IGuildRegistry(registry).throneChest(_to, _this) : _to; // override _to if the destination address is a guild, the reward should go to the chest for that guild instead
        }
        if(balance > 100) {                                                     // if token balance can be taxed/is non-zero
            if(potFee > 0) {                                                        // if the fee is enabled
                (uint feeAmount, uint postFeeAmount) = _calculateFee(balance);          // calculate the fee amount
                IERC20(_asset).transfer(_to, postFeeAmount);                            // transfer out current token balance to the winner
                IERC20(_asset).transfer(feeDestination, feeAmount);                     // transfer the fee to the fee destination
                winnings[_to][_asset] += postFeeAmount;                                 // update the winner's winnings
                totalWinnings[_asset] += postFeeAmount;                                 // update the all-time total winnings
            } else {                                                                // otherwise, the fee is disabled
                IERC20(_asset).transfer(_to, balance);                                  // transfer out current token balance to the winner
                winnings[_to][_asset] += balance;                                       // update the winner's winnings
                totalWinnings[_asset] += balance;                                       // update the all-time total winnings
            }
        }
    }
    function _handleBurnTransfer(address _input, address _from, uint _amount)
    internal {
        if(_input == KRILL) {                                       // if the input is KRILL
            address _this = address(this);                              // shorthand
            uint burnAmount = _amount;                                  // amount to burn
            if(_from != _this) {                                        // if this isnt being done via claimAndBurn()
                uint before = IERC20(KRILL).balanceOf(_this);               // record current balance
                IERC20(_input).transferFrom(_from, _this, _amount);         // transfer it to this contract
                uint delta = IERC20(KRILL).balanceOf(_this) - before;       // record change in balance to take fee-on-transfer into account
                burnAmount = delta;                                         // update the burn amount to be equal to the change in balance
            }
            IERC20(_input).burn(burnAmount);                            // burn the burn amount
            totalBurned += burnAmount;                                  // increase the all-time total burned amount
        } else if(_input == wFM || _input == wWH) {                     // otherwise, is the input a wrapped token?
            IERC20(_input).transferFrom(_from, wrapperBurner, _amount);     // transfer to wraperburner address (to be burned)
            totalBurned += _amount;                                         // increase the all-time total burned amount
        } else {                                                        // otherwise
            IERC20(_input).transferFrom(_from, BURNER, _amount);            // transfer to dead address (equivalent to burning)
            totalBurned += _amount;                                         // increase the all-time total burned amount
        }
    }
    function _handleOtherTransfers(address[2] memory _thrones, address _input, address _from, uint _amountEach)
    internal {
        address _this = address(this);                                                  // shorthand
        for(uint x = 0; x < 2; x++)                                                     // for each throne address
            if(_thrones[x] == address(0) || _thrones[x] == BURNER || _thrones[x] == _this)  // if the throne address is not configured, set to the burner, or this contract
                _handleBurnTransfer(_input, _from, _amountEach);                                // handle the transfer as a burn
            else                                                                            // otherwise
                IERC20(_input).transferFrom(_from, _thrones[x], _amountEach);                   // transfer the tokens
    }
    function _handleFee(address _from, uint _totalAmount)
    internal virtual {
        address input_ = input;                                 // shorthand - save gas since it doesnt need to be loaded from storage more than once
        uint burned = _totalAmount / 2;                         // burn 50%
        uint other = burned / 2;                                // 25% to secondary Throne winner, 25% to island Throne winner
        _handleBurnTransfer(input_, _from, burned);             // burn the input amount from _from
        address[2] memory thrones;                              // create an array to hold the throne addresses
        thrones[0] = secondThrone;                              // set the first element to the second throne address
        thrones[1] = islandThrone;                              // set the second element to the island throne address
        _handleOtherTransfers(thrones, input_, _from, other);   // transfer the other amount to the secondary and island throne
    }
    function _disperseRewards(address _winner)
    internal virtual {
        _nonZeroTransferAll(KRILL, _winner);    // transfer out all KRILL to _winner
    }
    function _enterFor(address _who, address _from, uint _amount, bool _ignoreTokens)
    internal {
        require(_amount <= playAmountCap);                              // require that the amount is less than or equal to the current play amount cap
        address _this = address(this);                                  // shorthand
        require(_who != address(0) && _who != _this && _who != BURNER); // require that _who is not the zero address, this contract, AND the 0x000...dEaD address
        require(_amount > 0);                                           // require that the amount being entered is non-zero
        if(_ignoreTokens == false)                                      // if we are not ignoring tokens
            _handleFee(_from, _amount);                                     // handle the fee
        _assumeControl(_who, _from, _amount);                           // attempt to assume control for _who
        if(_who == _from || _from == _this)                             // if _who and _from are the same address OR if _from is this contract (claimAndBurn() is being called)
            rawScores[_who] += _amount;                                     // log the raw score increase for _who
        else {                                                          // otherwise, they are not (user is playing for another guild or entity)
            rawScores[_from] += _amount;                                    // log the raw score increase for _from
            rawScorePlayedForOthers[_from] += _amount;                      // log the raw score played for others for _from
        }
        totalRawScores += _amount;                                      // increase the all-time total raw scores
        if(tracked[_who] == false) {                                    // if they arent tracked as a player yet
            tracked[_who] = true;                                           // indicate that they are tracked
            players.push(_who);                                             // add them to the player list
            totalPlayers++;                                                 // increment total player tracker
        }
    }
    function _logEpoch(address _who, address _from, uint _stamp)
    internal {
        if(epochCounter > 0) {                                      // if we are past the first epoch
            EpochData memory data = epochs[epochCounter-1];             // load epoch data into memory
            controlTime[data.player] += block.timestamp - data.stamp;   // increment their controlTime, which tracks the total amount of recorded time an entity has maintained control over the throne
        }
        epochs[epochCounter] = EpochData({                          // create a new epoch
            player: _who,
            caller: _from,
            stamp: uint96(_stamp)
        });
        epochCounter++;                                             // increment the epoch counter
    }
    function _assumeControl(address _who, address _from, uint _amount)
    internal {
        uint whoTime;                                                       // time difference between last interaction and now for _who
        uint winnerTime;                                                    // time difference between last interaction and now for winner
        uint _now = block.timestamp;                                        // shorthand
        if(last[_who] == 0)                                                 // if this is their first time interacting with the contract
            last[_who] = _now;                                                  // their lastUsed timestamp needs to be set before calculating their current score to check against the requirement
        (whoTime, winnerTime) = _calcTime(_now, last[_who], last[winner]);  // save the time differences for both _who and the winner in memory
        entered[_who] = _calcScore(_who, whoTime) + _amount;                // increment the amount entered by _who based on the score calculation
        last[_who] = _now;                                                  // update _who's timestamp indicating when they last used this contract
        if(_who != winner) {                                                // if _who is not the winner
            if(_amount > 10)                                                    // if the amount is greater than ten wei (10% slash rate)
                _slashWinner(_amount);                                              // slash the winner's score                  
            if(entered[_who] > _calcScore(winner, winnerTime)) {                // if they are the top player
                if(winner != address(0))                                            // if the current winner is not 0x0
                    claimForWinner();                                                   // claim for the "old" winner
                emit ThroneTaken(epochCounter, winner, _who);                       // emit an event for the UI
                winner = _who;                                                      // the winner is now _who
                _logEpoch(_who, _from, _now);                                       // log the epoch, passing in the player (_from) and current timestamp
            }                                                                       // ... this allows guild members to progress their own questline while playing for a guild
        }
        emit Played(epochCounter, _who, _from, _amount);                            // emit an event for the UI
    }

    function claimForWinner()
    public onlyPlayable {
        _claimRewards();            // claim rewards from all sources
        _disperseRewards(winner);   // disperse the rewards for the winner
    }
}

contract ManagedThrone is ThroneCore {
    constructor(address _input, address _cKRILL, address _KRILL, address _ISLAND)
    ThroneCore(_input, _cKRILL, _KRILL, _ISLAND) {}

    modifier andSweepKrill(address _to) {
        _;
        uint KRILLBalance = IERC20(KRILL).balanceOf(address(this)); // load KRILL balance
        if(KRILLBalance > 0)                                        // if KRILL balance is greater than zero
            IERC20(KRILL).transfer(_to, KRILLBalance);                  // transfer out the balance
    }

    function setGuildRegistry(address _registry)
    external _onlyOwner {
        registry = _registry;   // set the guild registry contract
    }
    function sweepOut(address _to)
    external claiming _onlyOwner andSweepKrill(_to) {
        require(shutDown == true);                              // require that the throne is shut down (due to misconfiguration etc)
        address _this = address(this);                          // shorthand
        uint wFMBalance = IERC20(wFM).balanceOf(_this);         // load wrapped fishermen balance
        if(wFMBalance > 0)                                      // if wrapped fishermen balance is greater than zero
            IERC20(wFM).transfer(_to, wFMBalance);                  // transfer out the balance
        uint wWHBalance = IERC20(wWH).balanceOf(_this);         // load wrapped whales balance
        if(wWHBalance > 0)                                      // if wrapped whales balance is greater than zero
            IERC20(wWH).transfer(_to, wWHBalance);                  // transfer out the balance
        uint cKRILLBalance = IERC20(cKRILL).balanceOf(_this);   // load cKRILL balance
        if(cKRILLBalance > 0)                                   // if cKRILL balance is greater than zero
            IERC20(cKRILL).transfer(_to, cKRILLBalance);            // transfer out the balance
        uint LPStaked = IClaimable(staking).depositedOf(_this); // load LP tokens staked
        if(LPStaked > 0)                                        // if LP token stake amount is greater than zero
            IClaimable(staking).withdrawAll();                      // withdraw the balance
        uint LPBalance = IERC20(liquidity).balanceOf(_this);    // load LP token balance
        if(LPBalance > 0)                                       // if LP token balance is greater than zero
            IERC20(liquidity).transfer(_to, LPBalance);             // transfer out the balance
    }
    function sweepOutNFTs(address _to)
    external claiming _onlyOwner andSweepKrill(_to) {
        require(shutDown == true);                                              // require that the throne is shut down (due to misconfiguration etc)
        address _this = address(this);                                          // shorthand
        uint NFTBalance = IERC20(whalesGame).balanceOf(_this);                  // load amount of NFTs held
        for(uint x = 0; x < NFTBalance; x++) {                                  // for every NFT
            uint tokenID = IERC721(whalesGame).tokenOfOwnerByIndex(_this, 0);       // load its ID
            IERC721(whalesGame).transferFrom(_this, _to, tokenID);                  // transfer it out
        }
    }
    function setFee(address _feeDestination, uint _feePercent)
    external _onlyOwner {
        require(_feeDestination != address(0)); // fee destination cannot be the zero address
        require(_feePercent <= 100);            // fee percentage cannot be greater than 100%
        feeDestination = _feeDestination;       // set the fee destination
        potFee = _feePercent;                   // set the fee percentage
    }
    function setWrapperBurner(address _wrapperBurner)
    external _onlyOwner {
        require(wrapperBurner == address(0));   // require that the wrapper burner is not set yet
        require(input == wFM || input == wWH);  // require that the input is either wFM or wWH
        wrapperBurner = _wrapperBurner;         // set the wrapper burner
    }
    function setPermissionGate(address _permissionGate)
    external _onlyOwner {
        permissionGate = _permissionGate;   // set the permission gate, updatable at any time to maintain flexibility
    }
    function setStartStamp()
    external _onlyOwner {
        if(input == wFM || input == wWH)        // if the input is wFM or wWH     
            require(wrapperBurner != address(0));   // require that the wrapper burner is set
        require(startStamp == 0);               // cannot configure more than once
        startStamp = block.timestamp;           // set the start stamp to now
    }
    function setDecayRate(uint _decayRate)
    external _onlyOwner {
        require(decayRate == 0);    // cannot configure more than once
        decayRate = _decayRate;     // set the decay rate
    }
    function flipShutdownSwitch()
    external _onlyOwner {
        require(block.timestamp <= (startStamp + 30 days)); // cannot shutdown after 30 days. this should be enough time to tell if the throne is misconfigured or not (decay rate can be too high or too low etc)
        shutDown = true;                                    // flip the shutdown switch
    }
    function setThrone(bool _secondOrIsland, address _throne)
    external _onlyOwner {
        if(_secondOrIsland == true) // if the throne is the second throne
            secondThrone = _throne;     // set the second throne
        else                        // if the throne is the island throne
            islandThrone = _throne;     // set the island throne
    }
    function setPlayAmountCap(uint _amountCap)
    external _onlyOwner {
        playAmountCap = _amountCap;             // store the new value
    }
    function setWinnerSlashRate(uint _slashRate)
    external _onlyOwner {
        require(_slashRate <= 100);     // slash rate is 0-100%
        winnerSlashRate = _slashRate;   // set the slash rate
    }
}

contract Throne is ManagedThrone {
    address immutable public ISLAND;    // address of the ISLAND token

    constructor(address _input, address _cKRILL, address _KRILL, address _ISLAND)
    ManagedThrone(_input, _cKRILL, _KRILL, _ISLAND) {
        address _this = address(this);  // shorthand
        ISLAND = _ISLAND;               // set the ISLAND address
        secondThrone = _this;           // set the second throne address
        islandThrone = _this;           // set the island throne address
    }

    function _calcTotalPot()
    internal view returns (uint) {
        uint totalPot = _calculateKRILLToClaim(staking, whalesGame, wFM, wWH, cKRILL, KRILL, MINIMUM_KRILL);    // calculate the total pot
        uint postFee;                                                                                           // post-fee total pot
        if(potFee > 0) {                                                                                        // if the fee is enabled
            (, postFee) = _calculateFee(totalPot);                                                                  // calculate the post-fee total pot
            return postFee;                                                                                         // return the post-fee total pot
        } else                                                                                                  // otherwise, the fee is disabled
            return totalPot;                                                                                        // return the total pot
    }
    function _mostInfoFor(address _who)
    internal view returns (uint userBalance, uint userAllowance, uint userScore, address currentWinner, uint winnerScore, uint dailyKrill, uint decayPerSecond) {
        uint whoTime;                                                                   // time difference between last interaction and now for _who
        uint winnerTime;                                                                // time difference between last interaction and now for winner
        address _this = address(this);                                                  // shorthand
        (whoTime, winnerTime) = _calcTime(block.timestamp, last[_who], last[winner]);   // save the time differences for both _who and the winner in memory
        userBalance = IERC20(input).balanceOf(_who);                                    // the current balance of the input token for _who
        userAllowance = IERC20(input).allowance(_who, _this);                           // the current allowance for the input token granted by _who to this contract
        if(last[_who] > 0)                                                              // if _who has ever interacted with this contract
            userScore = _calcScore(_who, whoTime);                                          // get the current score of _who
        if(last[winner] > 0) {                                                          // if the winner has ever interacted with this contract
            currentWinner = winner;                                                         // the address of the current winner
            winnerScore = _calcScore(winner, winnerTime);                                   // get the current score of the winner
        }
        dailyKrill += (8000 ether * IWG(whalesGame).fishermenOf(_this));                // every fisherman NFT brings in 8K/day
        dailyKrill += (16000 ether * IWG(whalesGame).whalesOf(_this));                  // every whale NFT brings in 16K/day
        if(input != ISLAND) {                                                           // if the input token is NOT the island token (otherwise the wfm/wwh earning krill goes to the winner)
            dailyKrill += (8000 ether * IERC20(wFM).balanceOf(_this) / 1 ether);            // add the daily krill generation rate from the wFM held by this contract
            dailyKrill += (16000 ether * IERC20(wWH).balanceOf(_this) / 1 ether);           // add the daily krill generation rate from the wWH held by this contract
        }
        if(potFee > 0)                                                                  // if the fee is enabled
            (,dailyKrill) = _calculateFee(dailyKrill);                                      // calculate the daily krill generation rate after the fee is applied
        decayPerSecond = decayRate;                                                     // the decay per second for the krill
    }
    function assumeControl()
    external onlyPlayable {
        address caller = msg.sender;        // shorthand
        claimForWinner();                   // claim rewards from all sources, for the winner
        _assumeControl(caller, caller, 0);  // atttempt to assume control
    }
    function claimAndBurn()
    external onlyPlayable {
        address _this = address(this);                  // shorthand
        address caller = msg.sender;                    // shorthand
        require(caller == winner);                      // only allow calling this if the caller is the winner
        require(input == KRILL);                        // only allow calling this if the input token is KRILL
        _claimRewards();                                // claim rewards
        uint balance = IERC20(KRILL).balanceOf(_this);  // load current KRILL balance
        winnings[caller][KRILL] += balance;             // increment the winnings for the caller
        totalWinnings[KRILL] += balance;                // increment the total winnings
        _enterFor(caller, _this, balance, false);       // enter the difference in balance for the caller (the current winner)
    }
    function enter(uint _amount)
    external onlyPlayable {
        _enterFor(msg.sender, msg.sender, _amount, false);  // enter the amount for the caller, taking tokens from the caller
    }
    function enterFor(address _who, uint _amount)
    external onlyPlayable {
        _enterFor(_who, msg.sender, _amount, false);    // enter the amount for _who, taking tokens from the caller
    }
    function enterFrom(address _who, uint _amount)
    external onlyPlayable {
        address caller = msg.sender;                // shorthand
        require(permission[_who][caller] == true);  // only allow calling this if the caller has permission to use _who's tokens
        _enterFor(caller, _who, _amount, false);    // enter the amount for the caller, taking tokens from _who
    }
    function setPermission(address _to, bool _value)
    external {
        address caller = msg.sender;                                    // shorthand
        if(permission[caller][_to] == false)                            // if the caller is currently not allowed to use _to's tokens
            require(IPermissionGate(permissionGate).viewGate(_to) == true); // only proceed if the permission gate is configured to allow _to to use caller's tokens
        permission[caller][_to] = _value;                               // set the permission for _to to _value
    }
    function allInfoFor(address _who)
    external view returns (uint playCap, uint userBalance, uint userAllowance, uint userScore, address currentWinner, uint winnerScore, uint potTotal, uint dailyKrill, uint decayPerSecond) {
        playCap = playAmountCap;
        (userBalance, userAllowance, userScore, currentWinner, winnerScore, dailyKrill, decayPerSecond) = _mostInfoFor(_who);   // load most info for _who into memory
        potTotal = _calcTotalPot();                                                                                             // load the total pot into memory
    }
    function viewEpoch(uint _epoch)
    external view returns (address, address, uint) {
        EpochData memory data = epochs[_epoch];                 // load the epoch data for _epoch into memory
        return (data.player, data.caller, uint(data.stamp));    // return the player and timestamp of the epoch
    }
    function viewStatsFor(address _who, address _asset)
    external view returns (uint, uint, uint, uint, uint, uint, uint) {
        return (rawScores[_who], totalWinnings[_asset], totalBurned, totalRawScores, winnings[_who][_asset], totalPlayers, startStamp);
    }
    function viewExtraInfo()
    external view returns (uint, uint, uint, uint, uint, uint) {
        uint totalSupply = IERC20(whalesGame).totalSupply();                                                                    // load total NFT supply
        uint activeSupply = totalSupply - IERC20(whalesGame).balanceOf(BURNER);                                                 // deactivated NFTs do not mint KRILL
        uint dailyInflationEstimate = ((10000e18 * activeSupply) / 100) * 90;                                                   // 10k * supply * 0.9 per day
        uint currentKrillSupply = IERC20(KRILL).totalSupply();                                                                  // load the current krill supply
        return (winnerSlashRate, totalSupply, activeSupply, dailyInflationEstimate, krillSupplyAtLaunch, currentKrillSupply);   // return the data
    }
}