// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NoShitSherlock is ERC20 {
    bytes32[] private suspects;
    bytes32[] private weapons;
    bytes32[] private rooms;
    bytes32[] private motives;

    uint256 private mysteryPrevrandao;
    uint256 private mysteryBlockNumber;

    uint256 public constant guessCost = 6969 * 10**18;
    uint256 public pooledFunds;
    address public teamWallet = 0xA07f15D9c6aFD0f846606A635E0a39e0a5235BDc;
    address public treasury = 0x15Bf49EC76205BD2B89af7E31b8859559e6189c6;

    event GuessResult(address indexed player, uint256 correctGuesses);

    constructor() ERC20("No Shit Sherlock", "NSS") {
        _mint(msg.sender, 6969696969 * 10**decimals());

        suspects = [
            keccak256(bytes("Craig 'Faketoshi' Wright")),
            keccak256(bytes("Sam Bankman-Fried")),
            keccak256(bytes("Do Kwon")),
            keccak256(bytes("Justin Sun")),
            keccak256(bytes("Arthur Hayes")),
            keccak256(bytes("Charlie Shrem")),
            keccak256(bytes("Brock Pierce")),
            keccak256(bytes("Shitboy Brypto")),
            keccak256(bytes("Gary Gensler")),
            keccak256(bytes("Roger Ver"))
        ];

        weapons = [
            keccak256(bytes("Hopium")),
            keccak256(bytes("Rugpull")),
            keccak256(bytes("Falling Knives")),
            keccak256(bytes("Rekt Rocket")),
            keccak256(bytes("Liquidation Laser")),
            keccak256(bytes("FUD Flame")),
            keccak256(bytes("Technically you kinda lost your money")),
            keccak256(bytes("Short Squeeze")),
            keccak256(bytes("Shillfest")),
            keccak256(bytes("SEC whistleblower"))
        ];

        rooms = [
            keccak256(bytes("Tether Treasury")),
            keccak256(bytes("Bitfinex Basement")),
            keccak256(bytes("Pump Palace")),
            keccak256(bytes("Moon Mission Control")),
            keccak256(bytes("Satoshi's Secret Lab")),
            keccak256(bytes("Binance HQ (location unknown)")),
            keccak256(bytes("FOMO Factory")),
            keccak256(bytes("Crypto Castle")),
            keccak256(bytes("Wassie murder fridge")),
            keccak256(bytes("Ruins of Cryptopia"))
        ];

        motives = [
            keccak256(bytes("Greed")),
            keccak256(bytes("Fear")),
            keccak256(bytes("Jealousy")),
            keccak256(bytes("Revenge")),
            keccak256(bytes("Power")),
            keccak256(bytes("Control")),
            keccak256(bytes("Deception")),
            keccak256(bytes("Manipulation")),
            keccak256(bytes("Hypocrisy")),
            keccak256(bytes("Misdirection"))
        ];

        generateMystery();
    }

    function generateMystery() private {
        mysteryPrevrandao = block.prevrandao;
        mysteryBlockNumber = block.number;
    }

        function makeGuess(uint256 suspect, uint256 weapon, uint256 room, uint256 motive) public {
        require(balanceOf(msg.sender) >= guessCost, "Not enough NSS to make a guess.");
        _transfer(msg.sender, address(this), guessCost);
        pooledFunds += guessCost;
        uint256 correctGuesses = 0;

        // Ensure the block number for the mystery has passed
        require(block.number > mysteryBlockNumber, "The mystery is still unfolding");

        // Calculate randomness based on the saved mystery values
        uint256 suspectRand = uint256(keccak256(abi.encodePacked(mysteryPrevrandao, mysteryBlockNumber))) % suspects.length;
        uint256 weaponRand = uint256(keccak256(abi.encodePacked(mysteryBlockNumber, mysteryPrevrandao, suspectRand))) % weapons.length;
        uint256 roomRand = uint256(keccak256(abi.encodePacked(mysteryPrevrandao, mysteryBlockNumber, weaponRand))) % rooms.length;
        uint256 motiveRand = uint256(keccak256(abi.encodePacked(mysteryBlockNumber, mysteryPrevrandao, roomRand))) % motives.length;

        // Check the guesses
        if (suspects[suspect] == suspects[suspectRand]) correctGuesses++;
        if (weapons[weapon] == weapons[weaponRand]) correctGuesses++;
        if (rooms[room] == rooms[roomRand]) correctGuesses++;
        if (motives[motive] == motives[motiveRand]) correctGuesses++;

        if (correctGuesses == 4) {
        uint256 reward = pooledFunds * 831 / 1000;
        uint256 nextRound = pooledFunds * 69 / 1000;
        uint256 treasuryReward = pooledFunds * 75 / 1000;
        uint256 teamReward = pooledFunds * 25 / 1000;

        _transfer(address(this), msg.sender, reward);
        _transfer(address(this), treasury, treasuryReward);
        _transfer(address(this), teamWallet, teamReward);

        pooledFunds = nextRound;
        generateMystery();
    }


        emit GuessResult(msg.sender, correctGuesses);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}