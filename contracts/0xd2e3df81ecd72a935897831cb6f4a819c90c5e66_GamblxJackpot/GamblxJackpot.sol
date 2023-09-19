/**
 *Submitted for verification at Etherscan.io on 2023-08-01
*/

/**
 * GAMBLX JACKPOT CONTRACT
 *
 * Unlike traditional casinos with a house edge, at GAMBLX, our unique game mechanics system eliminates the house edge. This means (f.e.) you can enjoy up to an 80% chance to win X2 bets, depending on the round. Imagine the possibilities - with a total pool of $2800, a mere $40 bet can grant you a 50% chance to win, particularly during rounds with high bonus pools and smaller bets. Say goodbye to always losing – at GAMBLX, you have the advantage!
 * 50% of token volume tax funds are automatically added to jackpot rounds as bonus pools.
 * Additionally, 30% of total casino revenue is shared randomly into game pools, and 10% of casino revenue is used for token buyback at random interval.
 * The token is deflationary, with 5% of tokens from tax volume being burned automatically.
 * Holders of the token become part owners of the casino, receiving 30% of casino revenue and 20% of token tax fees through the Revenue Share Program.
 * Return to Player (RTP) can reach up to +1000%, depending on the round and bonus pool. Players can even apply their skills to calculate the best timing to join game.
 * Fully decentralized, winners for each round are automatically chosen using our smart contract provable fair system.
 * 10% of each game pool contributes to casino revenue, and 30% of this revenue is shared with token holders through the Revenue Share system.
 *
 *
 * At GamblX, we believe in provably fair gaming. Every game, bet, and winner can be verified, as our smart contract automatically selects winners at the end of each game, leaving no room for human intervention.
 * As we expand our offerings, players can expect a diverse range of games designed to cater to all interests and preferences. From classic casino games with a blockchain twist to groundbreaking and unique creations, each game promises a seamless and transparent gaming experience.
 * Our new games will feature provably fair mechanics, ensuring that players can verify the fairness of every outcome independently. The blockchain's decentralized nature provides added security and trust, ensuring that the integrity of the games remains uncompromised.
 * Whether you are a seasoned gambler or a newcomer to the world of blockchain gaming, our upcoming releases will captivate and entertain you. Prepare to embark on an unforgettable journey, where thrilling gameplay and blockchain technology converge to create an unparalleled gaming adventure.
 * GamblX invites players to join our revolution in the gambling world, where trust, fairness, and exhilarating gaming experiences converge. Embrace the advantage and explore the endless possibilities of winning with GamblX.
 *
 *
 * Website: https://gamblx.com
 * Twitter: https://twitter.com/gamblx_com
 * Telegram: https://t.me/gamblx_com
 * Medium: https://medium.com/@gamblx/
 * Discord: https://discord.com/invite/bFfwwTYE
 * Docs: https://gamblx.gitbook.io/info
 * 
 * 
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract GamblxJackpot {
    /**
    * @dev Write to log info about the new game.
    *
    * @param _game Game number.
    * @param _time Time when game stated.
    */
    event Game(uint _game, uint indexed _time);

    struct Bet {
        address addr;
        uint256 ticketstart;
        uint256 ticketend;
    }
    mapping (uint256 => mapping (uint256 => Bet)) public bets;
    mapping (uint256 => uint256) public totalBets;

    //winning tickets history
    mapping (uint256 => uint256) public ticketHistory;

    //winning address history
    mapping (uint256 => address) public winnerHistory;
    
    // Game fee.
    uint8 public fee = 10;
    // Current game number.
    uint public game;
    // Min eth deposit jackpot
    uint public minethjoin = 0.001 ether;

    // Game status
    // 0 = running
    // 1 = stop to show winners animation
	
    uint public gamestatus = 0;

    // All-time game jackpot.
    uint public allTimeJackpot = 0;
    // All-time game players count
    uint public allTimePlayers = 0;
    
    // Game status.
    bool public isActive = true;
    // The variable that indicates game status switching.
    bool public toogleStatus = false;
    // The array of all games
    uint[] public games;
    
    // Store game jackpot.
    mapping(uint => uint) jackpot;
    // Store game players.
    mapping(uint => address[]) players;
    // Store total tickets for each game
    mapping(uint => uint) tickets;
    // Store bonus pool jackpot.
    mapping(uint => uint) bonuspool;
    // Store game start block number.
    mapping(uint => uint) gamestartblock;

    address payable owner;

    uint counter = 1;

    /**
    * @dev Check sender address and compare it to an owner.
    */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    /**
    * @dev Initialize game.
    * @dev Create ownable and stats aggregator instances, 
    * @dev set funds distributor contract address.
    *
    */

    constructor() 
    {
        owner = payable(msg.sender);
        startGame();
    }

    /**
    * @dev The method that allows buying tickets by directly sending ether to the contract.
    */
    function addBonus() public payable {
        bonuspool[game] += msg.value;
    }

    
    function playerticketstart(uint _gameid, uint _pid) public view returns (uint256) {
        return bets[_gameid][_pid].ticketstart;
    }

    function playerticketend(uint _gameid, uint _pid) public view returns (uint256) {
        return bets[_gameid][_pid].ticketend;
    }

    function totaltickets(uint _uint) public view returns (uint256) {
        return tickets[_uint];
    }

    function playeraddr(uint _gameid, uint _pid) public view returns (address) {
        return bets[_gameid][_pid].addr;
    }


    /**
    * @dev Returns current game players.
    */
    function getPlayedGamePlayers() 
        public
        view
        returns (uint)
    {
        return getPlayersInGame(game);
    }

    /**
    * @dev Get players by game.
    *
    * @param playedGame Game number.
    */
    function getPlayersInGame(uint playedGame) 
        public 
        view
        returns (uint)
    {
        return players[playedGame].length;
    }

    /**
    * @dev Returns current game jackpot.
    */
    function getPlayedGameJackpot() 
        public 
        view
        returns (uint) 
    {
        return getGameJackpot(game);
    }
    
    /**
    * @dev Get jackpot by game number.
    *
    * @param playedGame The number of the played game.
    */
    function getGameJackpot(uint playedGame) 
        public 
        view 
        returns(uint)
    {
        return jackpot[playedGame]+bonuspool[playedGame];
    }

    /**
    * @dev Get bonus pool by game number.
    *
    * @param playedGame The number of the played game.
    */
    function getBonusPool(uint playedGame) 
        public 
        view 
        returns(uint)
    {
        return bonuspool[playedGame];
    }


    /**
    * @dev Get game start block by game number.
    *
    * @param playedGame The number of the played game.
    */
    function getGamestartblock(uint playedGame) 
        public 
        view 
        returns(uint)
    {
        return gamestartblock[playedGame];
    }

    /**
    * @dev Get total ticket for game
    */
    function getGameTotalTickets(uint playedGame) 
        public 
        view 
        returns(uint)
    {
        return tickets[playedGame];
    }
    
    /**
    * @dev Start the new game.
    */
    function start() public onlyOwner() {
        if (players[game].length > 0) {
            pickTheWinner();
        }
        gamestatus = 1;
        startGame();
    }

    /**
    * @dev Start the new game.
    */
    function setGamestatusZero() public onlyOwner() {
        gamestatus = 0;
    }

    /**
    * @dev Get random number. It cant be influenced by anyone
    * @dev Random number calculation depends on block timestamp,
    * @dev difficulty, counter and jackpot players length.
    *
    */
    function randomNumber(
        uint number
    ) 
        internal
        returns (uint) 
    {
        counter++;
        uint random = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, counter, players[game].length))) % number;
        if(random == 0){
            random = 1;
        }
       return random;
    }
    
    /**
    * @dev The payable method that accepts ether and adds the player to the jackpot game.
    */
    function enterJackpot() public payable {
        require(isActive);
        require(gamestatus == 0);
        require(msg.value >= minethjoin);

        uint newtotalstr = totalBets[game];
        bets[game][newtotalstr].addr = address(msg.sender);
        bets[game][newtotalstr].ticketstart = tickets[game]+1;
        bets[game][newtotalstr].ticketend = ((tickets[game]+1)+(msg.value/(1000000000000000)))-1;

        totalBets[game] += 1;
        jackpot[game] += msg.value;
        tickets[game] += msg.value/1000000000000000;

        
        players[game].push(msg.sender);
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
        uint toPlayer;
        if (players[game].length == 1) {
            toPlayer = jackpot[game] + bonuspool[game];
            payable(players[game][0]).transfer(toPlayer);
            winner = 0;
            ticketHistory[game] = 1;
            winnerHistory[game] = players[game][0];
        } else {
            winner = randomNumber(tickets[game]); //winning ticket
            uint256 lookingforticket = winner;
            address ticketwinner;
            for(uint8 i=0; i<= totalBets[game]; i++){
                address addr = bets[game][i].addr;
                uint256 ticketstart = bets[game][i].ticketstart;
                uint256 ticketend = bets[game][i].ticketend;
                if (lookingforticket >= ticketstart && lookingforticket <= ticketend){
                    ticketwinner = addr; //finding winner address
                }
            }

            ticketHistory[game] = lookingforticket;
            winnerHistory[game] = ticketwinner;
        
            uint distribute = (jackpot[game] + bonuspool[game]) * fee / 100; //game fee
            uint toTaxwallet = distribute * 99 / 100;
            toPlayer = (jackpot[game] + bonuspool[game]) - distribute;
            payable(address(0x54557f6873e31D4FB45562c93753936EB298c1CB)).transfer(toTaxwallet); //send 10% game fee
            payable(ticketwinner).transfer(toPlayer); //send prize to winner
        }
    

        allTimeJackpot += toPlayer;
        allTimePlayers += players[game].length;
    }


}