/**
 *Submitted for verification at Etherscan.io on 2023-08-16
*/

/**
 *Submitted for verification at Etherscan.io on 2023-08-16
*/

/*

    
    ██████  ███████ ██████  ███████     ██████   ██████  ██    ██ ██      ███████ ████████ ████████ ███████ 
    ██   ██ ██      ██   ██ ██          ██   ██ ██    ██ ██    ██ ██      ██         ██       ██    ██      
    ██████  █████   ██████  █████       ██████  ██    ██ ██    ██ ██      █████      ██       ██    █████   
    ██      ██      ██      ██          ██   ██ ██    ██ ██    ██ ██      ██         ██       ██    ██      
    ██      ███████ ██      ███████     ██   ██  ██████   ██████  ███████ ███████    ██       ██    ███████ 
                                                                                                            

* Website : https://peperoulette.xyz/
* Telegram : https://t.me/PepeRouletteEntryPortal
* Bot Telegram : https://t.me/PepeRoulette_bot
* Twitter : https://twitter.com/PepeRoulette
* Whitepaper : https://wp.peperoulette.xyz/

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Context {
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

}

abstract contract Ownable is Context {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function burn(uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TelegramPepeRoulette is Ownable {

    address public revenueWallet;

    IERC20 public Token;

    uint256 public minimumBet;

    // The amount to take as revenue, in basis points.
    uint256 public revenueBps;

    // The amount to burn forever, in basis points.
    uint256 public burnBps;

    // Map Telegram chat IDs to their games.
    mapping(int64 => Game) public games;

    // The Telegram chat IDs for each active game. Mainly used to
    // abort all active games in the event of a catastrophe.
    int64[] public activeTgGroups;

    // Stores the amount each player has bet for a game.
    event Bet(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);

    // Stores the amount each player wins for a game.
    event Win(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);

    // Stores the amount the loser lost.
    event Loss(int64 tgChatId, address player, uint16 playerIndex, uint256 amount);

    // Stores the amount collected by the protocol.
    event Revenue(int64 tgChatId, uint256 amount);

    // Stores the amount burned by the protocol.
    event Burn(int64 tgChatId, uint256 amount);

    constructor(address payable _Token, uint256 _minimumBet, uint256 _revenueBps, uint256 _burnBps, address _revenueWallet) {
        revenueWallet = _revenueWallet;
        revenueBps = _revenueBps;
        burnBps = _burnBps;
        Token = IERC20(_Token);
        minimumBet = _minimumBet;
    }

    struct Game {
        uint256 revolverSize;
        uint256 minBet;

        // This is a SHA-256 hash of the random number generated by the bot.
        bytes32 hashedBulletChamberIndex;

        address[] players;
        uint256[] bets;

        bool inProgress;
        uint16 loser;
    }

    /**
     * @dev Check if there is a game in progress for a Telegram group.
     * @param _tgChatId Telegram group to check
     * @return true if there is a game in progress, otherwise false
     */
    function isGameInProgress(int64 _tgChatId) public view returns (bool) {
        return games[_tgChatId].inProgress;
    }

    /**
     * @dev Remove a Telegram chat ID from the array.
     * @param _tgChatId Telegram chat ID to remove
     */
    function removeTgId(int64 _tgChatId) internal {
        for (uint256 i = 0; i < activeTgGroups.length; i++) {
            if (activeTgGroups[i] == _tgChatId) {
                activeTgGroups[i] = activeTgGroups[activeTgGroups.length - 1];
                activeTgGroups.pop();
            }
        }
    }

    /**
     * @dev Create a new game. Transfer funds into escrow.
     * @param _tgChatId Telegram group of this game
     * @param _revolverSize number of chambers in the revolver
     * @param _minBet minimum bet to play
     * @param _hashedBulletChamberIndex which chamber the bullet is in
     * @param _players participating players
     * @param _bets each player's bet
     * @return The updated list of bets.
     */
    function newGame(
        int64 _tgChatId,
        uint256 _revolverSize,
        uint256 _minBet,
        bytes32 _hashedBulletChamberIndex,
        address[] memory _players,
        uint256[] memory _bets) public onlyOwner returns (uint256[] memory) {
        require(_revolverSize >= 2, "Revolver size too small");
        require(_players.length <= _revolverSize, "Too many players for this size revolver");
        require(_minBet >= minimumBet, "Minimum bet too small");
        require(_players.length == _bets.length, "Players/bets length mismatch");
        require(_players.length > 1, "Not enough players");
        require(!isGameInProgress(_tgChatId), "There is already a game in progress");

        // The bets will be capped so you can only lose what other
        // players bet. The updated bets will be returned to the
        // caller.
        //
        // O(N) by doing a prepass to sum all the bets in the
        // array. Use the sum to modify one bet at a time. Replace
        // each bet with its updated value.
        uint256 betTotal = 0;
        for (uint16 i = 0; i < _bets.length; i++) {
            require(_bets[i] >= _minBet, "Bet is smaller than the minimum");
            betTotal += _bets[i];
        }
        for (uint16 i = 0; i < _bets.length; i++) {
            betTotal -= _bets[i];
            if (_bets[i] > betTotal) {
                _bets[i] = betTotal;
            }
            betTotal += _bets[i];

            require(Token.allowance(_players[i], address(this)) >= _bets[i], "Not enough allowance");
            bool isSent = Token.transferFrom(_players[i], address(this), _bets[i]);
            require(isSent, "Funds transfer failed");

            emit Bet(_tgChatId, _players[i], i, _bets[i]);
        }

        Game memory g;
        g.revolverSize = _revolverSize;
        g.minBet = _minBet;
        g.hashedBulletChamberIndex = _hashedBulletChamberIndex;
        g.players = _players;
        g.bets = _bets;
        g.inProgress = true;

        games[_tgChatId] = g;
        activeTgGroups.push(_tgChatId);

        return _bets;
    }

    /**
     * @dev Declare a loser of the game and pay out the winnings.
     * @param _tgChatId Telegram group of this game
     * @param _loser index of the loser
     *
     * There is also a string array that will be passed in by the bot
     * containing labeled strings, for historical/auditing purposes:
     *
     * beta: The randomly generated number in hex.
     *
     * salt: The salt to append to beta for hashing, in hex.
     *
     * publickey: The VRF public key in hex.
     *
     * proof: The generated proof in hex.
     *
     * alpha: The input message to the VRF.
     */
    function endGame(
        int64 _tgChatId,
        uint16 _loser,
        string[] calldata) public onlyOwner {
        require(_loser != type(uint16).max, "Loser index shouldn't be the sentinel value");
        require(isGameInProgress(_tgChatId), "No game in progress for this Telegram chat ID");

        Game storage g = games[_tgChatId];

        require(_loser < g.players.length, "Loser index out of range");
        require(g.players.length > 1, "Not enough players");

        g.loser = _loser;
        g.inProgress = false;
        removeTgId(_tgChatId);

        // Parallel arrays
        address[] memory winners = new address[](g.players.length - 1);
        uint16[] memory winnersPlayerIndex = new uint16[](g.players.length - 1);

        // The total bets of the winners.
        uint256 winningBetTotal = 0;

        // Filter out the loser and calc the total winning bets.
        {
            uint16 numWinners = 0;
            for (uint16 i = 0; i < g.players.length; i++) {
                if (i != _loser) {
                    winners[numWinners] = g.players[i];
                    winnersPlayerIndex[numWinners] = i;
                    winningBetTotal += g.bets[i];
                    numWinners++;
                }
            }
        }

        uint256 totalPaidWinnings = 0;
        require(burnBps + revenueBps < 10_1000, "Total fees must be < 100%");

        // The share of tokens to burn.
        uint256 burnShare = g.bets[_loser] * burnBps / 10_000;

        // The share left for the contract. This is an approximate
        // value. The real value will be whatever is leftover after
        // each winner is paid their share.
        uint256 approxRevenueShare = g.bets[_loser] * revenueBps / 10_000;

        bool isSent;
        {
            uint256 totalWinnings = g.bets[_loser] - burnShare - approxRevenueShare;

            for (uint16 i = 0; i < winners.length; i++) {
                uint256 winnings = totalWinnings * g.bets[winnersPlayerIndex[i]] / winningBetTotal;

                isSent = Token.transfer(winners[i], g.bets[winnersPlayerIndex[i]] + winnings);
                require(isSent, "Funds transfer failed");

                emit Win(_tgChatId, winners[i], winnersPlayerIndex[i], winnings);

                totalPaidWinnings += winnings;
            }
        }

        Token.burn(burnShare);
        emit Burn(_tgChatId, burnShare);

        uint256 realRevenueShare = g.bets[_loser] - totalPaidWinnings - burnShare;
        isSent = Token.transfer(revenueWallet, realRevenueShare);
        require(isSent, "Revenue transfer failed");
        emit Revenue(_tgChatId, realRevenueShare);

        require((totalPaidWinnings + burnShare + realRevenueShare) == g.bets[_loser], "Calculated winnings do not add up");
    }

    /**
     * @dev Abort a game and refund the bets. Use in emergencies
     *      e.g. bot crash.
     * @param _tgChatId Telegram group of this game
     */
    function abortGame(int64 _tgChatId) public onlyOwner {
        require(isGameInProgress(_tgChatId), "No game in progress for this Telegram chat ID");
        Game storage g = games[_tgChatId];

        for (uint16 i = 0; i < g.players.length; i++) {
            bool isSent = Token.transfer(g.players[i], g.bets[i]);
            require(isSent, "Funds transfer failed");
        }

        g.inProgress = false;
        removeTgId(_tgChatId);
    }

    /**
     * @dev Abort all in progress games.
     */
    function abortAllGames() public onlyOwner {
        // abortGame modifies activeTgGroups with each call, so
        // iterate over a copy
        int64[] memory _activeTgGroups = activeTgGroups;
        for (uint256 i = 0; i < _activeTgGroups.length; i++) {
            abortGame(_activeTgGroups[i]);
        }
    }

    function rescueFunds() external onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,'Payment Failed');
    }

    function rescueTokens(address _token,address recipient,uint _amount) external onlyOwner {
        (bool success, ) = address(_token).call(abi.encodeWithSignature('transfer(address,uint256)',  recipient, _amount));
        require(success, 'Token payment failed');
    }

    function setRevenueWallet(address _revenueWallet) external onlyOwner {
        revenueWallet = _revenueWallet;
    }

    function setBurnBps(uint _burnBps) external onlyOwner {
        burnBps = _burnBps;
    }

    function setToken(address _Token) external onlyOwner {
        Token = IERC20(_Token);
    }
    
    function setBetLimit(uint _minimumBet) external onlyOwner {
        minimumBet = _minimumBet;
    }

    function setRevenueBps(uint _revenueBps) external onlyOwner {
        revenueBps = _revenueBps;
    }   

    receive() external payable {}

}