// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VersusWager {

    struct Game {
        address payable playerA;
        address payable playerB;
        uint256 stake;
        bool isFlipped;
        address winner;
    }

    mapping(string => Game) public games;
    mapping(address => string[]) public playerGames;
    string[] public allGames;
    string[] public openGames;

    address public owner;
    address private constant WIN_DECLARER = 0x06E618E5fc0eF690EB75D93e44bf98a3D4109c27;

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Sender is not an EOA");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyWinDeclarer() {
        require(msg.sender == WIN_DECLARER, "Not the authorized winner declarer");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createGame(string memory gameID) public payable onlyEOA {
        require(bytes(gameID).length <= 10, "Invalid gameID length");
        require(games[gameID].playerA == address(0), "gameID already exists");
        require(msg.value > 0, "Must send ETH to create a game");
        
        games[gameID] = Game({
            playerA: payable(msg.sender),
            playerB: payable(address(0)),
            stake: msg.value,
            isFlipped: false,
            winner: address(0)
        });
        
        playerGames[msg.sender].push(gameID);
        allGames.push(gameID);
        openGames.push(gameID);
    }

    function joinGame(string memory gameID) public payable onlyEOA {
        require(games[gameID].playerA != address(0), "Game doesn't exist");
        require(games[gameID].playerB == address(0), "Game already has two players");
        require(msg.value == games[gameID].stake, "Must send the exact stake amount");

        games[gameID].playerB = payable(msg.sender);
        playerGames[msg.sender].push(gameID);

        for (uint i = 0; i < openGames.length; i++) {
            if (keccak256(abi.encodePacked(openGames[i])) == keccak256(abi.encodePacked(gameID))) {
                openGames[i] = openGames[openGames.length - 1];
                openGames.pop();
                break;
            }
        }
    }

    function declareWinner(string memory gameID, address winnerAddress) public onlyWinDeclarer {
        require(games[gameID].playerA != address(0) && games[gameID].playerB != address(0), "Game is not fully initialized");
        require(!games[gameID].isFlipped, "Game already flipped");
        require(winnerAddress == games[gameID].playerA || winnerAddress == games[gameID].playerB, "Declared winner is not a player in this game");

        games[gameID].isFlipped = true;
        games[gameID].winner = winnerAddress;
        
        payable(winnerAddress).transfer(games[gameID].stake * 2);
    }

    function getGame(string memory gameID) public view returns (Game memory) {
        return games[gameID];
    }

    function getOpenGames() public view returns (string[] memory) {
        return openGames;
    }

    function getAllGames() public view returns (string[] memory) {
        return allGames;
    }

    function getUnflippedGames(address playerAddress) public view returns (string[] memory) {
        string[] memory gamesForPlayer = playerGames[playerAddress];
        uint count = 0;

        for (uint i = 0; i < gamesForPlayer.length; i++) {
            if (!games[gamesForPlayer[i]].isFlipped) {
                count++;
            }
        }

        string[] memory unflippedGames = new string[](count);
        uint j = 0;

        for (uint i = 0; i < gamesForPlayer.length; i++) {
            if (!games[gamesForPlayer[i]].isFlipped) {
                unflippedGames[j] = gamesForPlayer[i];
                j++;
            }
        }

        return unflippedGames;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}