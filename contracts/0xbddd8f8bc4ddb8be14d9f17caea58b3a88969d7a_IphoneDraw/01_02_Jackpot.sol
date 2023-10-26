/**
 *Submitted for verification at Etherscan.io on 2023-08-24
 */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IphoneDraw {
    /**
     * @dev Write to log info about the new game.
     *
     * @param _game Game number.
     * @param _time Time when game stated.
     
     */
    event Game(uint _game, uint indexed _time);

    struct Round {
        address addr;
        uint256 ticketstart;
        uint256 ticketend;
    }
    struct StakingInfo {
        uint depositTime;
        uint balance;
    }

    mapping(uint256 => mapping(uint256 => Round)) public rounds;
    mapping(address => StakingInfo) public stakeInfo;
    mapping(uint256 => uint256) public totalRounds;

    //winning tickets history
    mapping(uint256 => uint256) public ticketHistory;

    //winning address history
    mapping(uint256 => address) public winnerHistory;

    IERC20 public token;

    // Game fee.
    uint8 public fee = 10;
    // Current game number.
    uint public game;
    // Min eth deposit round
    uint public constant minethjoin = 100 * 10 ** 9;

    uint public gamestatus = 0;

    // All-time game round.
    uint public allTimeRound = 0;
    // All-time game players count
    uint public allTimePlayers = 0;

    // Game status.
    bool public isActive = true;
    // The variable that indicates game status switching.
    bool public toogleStatus = false;
    // The array of all games
    uint[] public games;

    // Store game round.
    mapping(uint => uint) round;
    // Store game players.
    mapping(uint => address[]) players;
    // Store total tickets for each game
    mapping(uint => uint) tickets;
    // Store bonus pool round.
    mapping(uint => uint) bonuspool;
    // Store game start block number.
    mapping(uint => uint) gamestartblock;

    address payable public owner;
    address payable taxWallet;

    uint counter = 1;

    /**
     * @dev Check sender address and compare it to an owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    /**
     * @dev Initialize game.
     * @dev Create ownable and stats aggregator instances,
     * @dev set funds distributor contract address.
     *
     */

    constructor() {
        owner = payable(msg.sender);
        startGame();
    }

    /**
     * @dev The method that allows buying tickets by directly sending ether to the contract.
     */

    function setToken(address _address) external onlyOwner {
        require(address(token) == address(0));
        token = IERC20(_address);
    }

    function addBonus() public payable {
        bonuspool[game] += msg.value;
    }

    function playerticketstart(
        uint _gameid,
        uint _pid
    ) public view returns (uint256) {
        return rounds[_gameid][_pid].ticketstart;
    }

    function playerticketend(
        uint _gameid,
        uint _pid
    ) public view returns (uint256) {
        return rounds[_gameid][_pid].ticketend;
    }

    function totaltickets(uint _uint) public view returns (uint256) {
        return tickets[_uint];
    }

    function playeraddr(uint _gameid, uint _pid) public view returns (address) {
        return rounds[_gameid][_pid].addr;
    }

    /**
     * @dev Returns current game players.
     */
    function getPlayedGamePlayers() public view returns (uint) {
        return getPlayersInGame(game);
    }

    /**
     * @dev Get players by game.
     *
     * @param playedGame Game number.
     */
    function getPlayersInGame(uint playedGame) public view returns (uint) {
        return players[playedGame].length;
    }

    /**
     * @dev Returns current game round.
     */
    function getPlayedGameRound() public view returns (uint) {
        return getGameRound(game);
    }

    /**
     * @dev Get round by game number.
     *
     * @param playedGame The number of the played game.
     */
    function getGameRound(uint playedGame) public view returns (uint) {
        return round[playedGame] + bonuspool[playedGame];
    }

    /**
     * @dev Get bonus pool by game number.
     *
     * @param playedGame The number of the played game.
     */
    function getBonusPool(uint playedGame) public view returns (uint) {
        return bonuspool[playedGame];
    }

    /**
     * @dev Get game start block by game number.
     *
     * @param playedGame The number of the played game.
     */
    function getGamestartblock(uint playedGame) public view returns (uint) {
        return gamestartblock[playedGame];
    }

    /**
     * @dev Get total ticket for game
     */
    function getGameTotalTickets(uint playedGame) public view returns (uint) {
        return tickets[playedGame];
    }

    /**
     * @dev Start the new game.
     */
    function start() public onlyOwner {
        if (players[game].length > 0) {
            pickTheWinner();
        } else {
            bonuspool[game + 1] = bonuspool[game];
        }
        startGame();
    }

    /**
     * @dev Start the new game.
     */
    function setGamestatusZero() public onlyOwner {
        gamestatus = 0;
    }

    /**
     * @dev Get random number. It cant be influenced by anyone
     * @dev Random number calculation depends on block timestamp,
     * @dev difficulty, counter and round players length.
     *
     */
    function randomNumber(uint number) internal returns (uint) {
        counter++;
        uint random = uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    counter,
                    players[game].length,
                    gasleft()
                )
            )
        ) % number;
        return random + 1;
    }

    /**
     * @dev adds the player to the round game.
     */

    function deposit(address from, uint amount) public {
        require(
            msg.sender == address(token),
            "Stake by sending token to this contract"
        );
        require(isActive);
        require(gamestatus == 0);
        require(amount >= minethjoin, "Amount must be greater than 100 token");

        stakeInfo[from].depositTime = block.timestamp;
        stakeInfo[from].balance += amount;

        uint newtotalstr = totalRounds[game];
        rounds[game][newtotalstr].addr = address(from);
        rounds[game][newtotalstr].ticketstart = tickets[game] + 1;
        rounds[game][newtotalstr].ticketend =
            ((tickets[game] + 1) + (amount / (100 * 10 ** 9))) -
            1;

        totalRounds[game] += 1;
        round[game] += amount;
        tickets[game] += (amount / (100 * 10 ** 9));

        players[game].push(from);
    }

    /**
     * @dev Withdraw token
     */
    function withdraw() public onlyOwner {
        address _receive = payable(owner);
        _receive.call{value: address(this).balance}("");
    }

    /**
     * @dev Start the new game.
     * @dev Checks game status changes, if exists request for changing game status game status
     * @dev will be changed.
     */
    function startGame() internal {
        require(isActive);

        game += 1;
        if (toogleStatus) {
            isActive = !isActive;
            toogleStatus = false;
        }
        gamestartblock[game] = block.timestamp;
        emit Game(game, block.timestamp);
    }

    /**
     * @dev Pick the winner using random number provably fair function.
     */
    function pickTheWinner() internal {
        uint winner;
        uint toPlayer = address(this).balance;
        if (players[game].length == 1) {
            payable(players[game][0]).transfer(toPlayer);
            winner = 0;
            ticketHistory[game] = 1;
            winnerHistory[game] = players[game][0];
        } else {
            winner = randomNumber(tickets[game]); //winning ticket
            uint256 lookingforticket = winner;
            address ticketwinner;
            for (uint8 i = 0; i <= totalRounds[game]; i++) {
                address addr = rounds[game][i].addr;
                uint256 ticketstart = rounds[game][i].ticketstart;
                uint256 ticketend = rounds[game][i].ticketend;
                if (
                    lookingforticket >= ticketstart &&
                    lookingforticket <= ticketend
                ) {
                    ticketwinner = addr; //finding winner address
                }
            }

            ticketHistory[game] = lookingforticket;
            winnerHistory[game] = ticketwinner;

            payable(ticketwinner).transfer(toPlayer); //send prize to winner
        }

        allTimeRound += toPlayer;
        allTimePlayers += players[game].length;
    }

    receive() external payable {}

    fallback() external payable {}
}