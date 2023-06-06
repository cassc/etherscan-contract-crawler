// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IBurnable is IERC20 {
    function burn(uint256 amount) external;
}

interface ILocker {
    function owner() external returns (address);
    function changeOwner(address newOwner) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract Burner {
    using SafeERC20 for IERC20;

    struct Player {
        uint16 ID;      // probably not going to have more than 65K participants
        uint128 score;   // up to 16,777,216 WHOLE tokens burned per player
    }

    struct PlayerData {
        address player;
        uint128 score;
        uint mrfBalance;
        uint mrfAllowance;
    }

    struct GameData {
        uint endTime;
        uint playerCount;
        uint totalBurnt;
    }

    address immutable token;                // the burnable token
    address immutable WETH;                 // address of the WETH contract
    address immutable locker;               // the liquidity locker acquiring ether fees
    address owner;                          // owner address
    address public frogContract;                   // address of the ownership destination for the liquidity locker
    uint16 players;                         // total amount of players, used to determine player ID
    uint public endTime;                           // the timestamp that the game absolutely ends at
    uint trackedWETH;                       // how much wrapped ether is tracked an counted towards the final prize amount
    uint totalBurnt;                        // track total amount burnt
    uint constant BONUS_TIME = 60 minutes;  // how much time to increase the end time by when someone changes the leaderboard
    uint constant public WINNER_MAX = 10;          // how many top players to pay out?
    uint constant MINIMUM_PLAY = 100e18;    // how many tokens, minimum, to play each tx?
    uint constant poolA = 511310;
    uint constant poolB = 511313;
    mapping (address => uint16) public IDs;        // mapping of player addresses to IDs
    mapping (uint16 => address) public addresses;  // mapping of player IDs to addresses
    mapping (uint16 => uint128) public score;       // mapping of player addresses to scores
    mapping (uint16 => bool) public claimed;       // mapping of player IDs to boolean indicating if they claimed already
    Player[WINNER_MAX] public top;          // store packed player data because need to load this each play()
    bool potBuilt;                          // boolean indicating final pot status

    constructor(address _token, address _WETH, address _locker) {
        token = _token;
        WETH = _WETH;
        locker = _locker;
        owner = msg.sender;
    }

    receive() external payable {}

    function gameOver()
    external view returns (bool) {
        return endTime != 0 && block.timestamp > endTime;
    }
    function leaderboard(uint _topIndex)
    external view returns (address) {
        require(_topIndex < WINNER_MAX, "Invalid index");        // index must be less than max number of winners
        return addresses[top[_topIndex].ID];
    }
    function setFrogContract(address _frogContract, uint _gameTime)
    external {
        require(msg.sender == owner, "Not owner");
        frogContract = _frogContract;
        endTime = uint(block.timestamp) + _gameTime;
    }
    function emergencyOwnershipTransfer()
    external {
        require(msg.sender == owner, "Not owner");      // in case this contract is bricked somehow...
        address this_ = address(this);                  // shorthand
        if (ILocker(locker).owner() == this_)
            ILocker(locker).changeOwner(owner);         // transfer lp ownership back to Mr F
        IERC20 WETH_ = IERC20(WETH);                    // load WETH interface
        uint wethBal = WETH_.balanceOf(this_);          // load WETH balance
        if (wethBal > 0)
            IWETH(WETH).withdraw(wethBal);              // withdraw ETH from WETH contract
        if (this_.balance > 0)
            payable(owner).transfer(this_.balance);     // transfer the ether out to Mr F
    }
    function getData()
    external view returns (GameData memory game) {
        game.endTime = endTime;
        game.totalBurnt = totalBurnt;
        game.playerCount = players;
        return game;
    }
    function getPlayers(uint16 start, uint16 max)
    external view returns (PlayerData[] memory) {
        uint16 last = start + max;
        if (last > players) {
            last = players;
        }
        PlayerData[] memory data = new PlayerData[](last-start);
        uint i;
        for(uint16 x = start; x < last; x++) {
            data[i] = getPlayer(addresses[x+1]);    // IDs are stored 1-indexed but accessed via 0-index
            i++;
        }
        return data;
    }
    function getPlayer(address addr)
    public view returns (PlayerData memory player) {
        uint16 x = IDs[addr];
        player.player = addr;
        player.mrfBalance = IERC20(token).balanceOf(addr);
        player.mrfAllowance = IERC20(token).allowance(addr, address(this));
        player.score = score[x];
        return player;
    }
    function _burn(address _from, uint _amount)
    internal {
        totalBurnt += _amount;                                           // increment total burnt
        IERC20(token).safeTransferFrom(_from, address(this), _amount);   // transfer tokens to this contract
        IBurnable(token).burn(_amount);                                  // burn tokens
    }
    function _rank(uint16 _playerID, uint128 _score)
    internal {
        Player[WINNER_MAX] memory data = top;   // load data into memory
        uint place = WINNER_MAX;                // initial placement
        for(uint x = WINNER_MAX; x > 0; x--)        // loop backwards
            if(_score > data[x-1].score)            // if their score is more than the placed score
                place = x-1;                            // update their placement
            else                                    // otherwise
                break;                                  // break out of loop
        if(place != WINNER_MAX) {               // if they have a valid placement
            if (place != WINNER_MAX - 1) {
                uint start = WINNER_MAX - 1;            // start looping from the second to last player
                uint end = place + 1;

                for(uint x = start; x >= end; x--) {  // loop backwards up to their placement
                    data[x].ID = data[x-1].ID;              // replace old data
                    data[x].score = data[x-1].score;        // replace old data
                    top[x] = data[x];                   // write to storage
                }
            }

            data[place].ID = _playerID;             // replace the current rank data
            data[place].score = _score;             // replace the current rank data
            top[place] = data[place];               // write to storage
            if(endTime > 0)   // if game has started
                endTime += BONUS_TIME;
        }
    }

    function _pullFees()
    internal {
        bool ignoreMe;
        (ignoreMe,) = address(locker).call(abi.encodeWithSignature("withdrawTradingFees(uint256)", poolA));  // attempt to pull liquidity fees from poolA
        (ignoreMe,) = address(locker).call(abi.encodeWithSignature("withdrawTradingFees(uint256)", poolB));  // attempt to pull liquidity fees from poolB
        ILocker(locker).changeOwner(frogContract);       // transfer ownership to Mr Frog
    }
    function _buildPot()
    internal {
        address this_ = address(this);          // shorthand
        uint Ebal = this_.balance;              // load current ether balance into memory
        if(Ebal > 0)                            // if current ether balance is greater than zero
            IWETH(WETH).deposit{value: Ebal}(); // deposit ether balance into WETH contract
        IERC20 WETH_ = IERC20(WETH);            // load WETH interface
        if(ILocker(locker).owner() == this_)    // if this contract still has ownership of the liquidity locker
            _pullFees();                            // pull fees from LP - this comes in the form of WETH
        trackedWETH = WETH_.balanceOf(this_);   // what is the current WETH balance?
        potBuilt = true;                        // the final pot is now built
    }
    function receiveApproval(address _receiveFrom, uint256 _amount, address _token, bytes memory _data)
    public {
        require(msg.sender == token, "Invalid token");
        _play(_amount, _receiveFrom);
    }
    function play(uint _amount)
    external {
        _play(_amount, msg.sender);
    }
    function _play(uint256 _amount, address _caller)
    internal {
        require(endTime == 0 || block.timestamp <= endTime, "Game over");  // only proceed if we are before the end time
        require(_amount >= MINIMUM_PLAY, "Amount too low");                // only proceed if the intended play amount is greater than or equal to the minimum
        uint16 playerID = IDs[_caller];                                     // load player ID into memory
        if(playerID == 0) {                                                // if the caller is not tracked as a player yet
            players += 1;                                                      // increase player count
            playerID = players;                                                // determine their player ID
            IDs[_caller] = playerID;                                           // assign their player ID to their address
            addresses[playerID] = _caller;                                     // assign their player address to their ID
        }
        uint128 newScore = score[playerID] + uint128(_amount);
        score[playerID] = newScore;           // increase the all-time score for the caller
        _rank(IDs[_caller], newScore);         // attempt to modify the top player placement
        _burn(_caller, _amount);                 // transfer and burn whole token amount
    }
    function claim(uint _topIndex)
    external {
        require(_topIndex < WINNER_MAX, "Invalid index");        // index must be less than max number of winners
        require(endTime != 0, "Game not started");               // game must have begun
        require(block.timestamp > endTime, "Game not over");     // only proceed if the game is actually over
        address caller = msg.sender;                             // shorthand
        uint16 playerID = IDs[caller];                           // load player ID into memory
        require(playerID > 0, "Invalid ID");                     // only proceed if they actually played
        require(playerID == top[_topIndex].ID, "Invalid ID");    // only proceed if the player ID matches that of a top player
        require(claimed[playerID] == false, "Already claimed");  // only proceed if the player hasn't claimed before
        claimed[playerID] = true;                                // the caller has claimed
        require(score[playerID] > 0, "Not a winner");            // only proceed if the player score is greater than zero
        if(potBuilt == false)                                    // if the final pot hasn't been built yet
            _buildPot();                                         // build it
        uint prize = trackedWETH / WINNER_MAX;                   // calculate prize amount
        IWETH(WETH).withdraw(prize);                             // withdraw ETH from WETH contract
        payable(caller).transfer(prize);                         // transfer the claimed ether out to the caller
    }
}