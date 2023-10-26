// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Roller.sol";
import "./ENSReverseRegistration.sol";

interface BingoCardsNFT {
    function boardArray(uint tokenId) external view returns (uint8[5][5] memory);
    function boardString(uint tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract GameFactory is ERC1155Receiver, IERC721Receiver, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    enum TokenType { NONE, ERC721, ERC1155 }

    struct Game {
        address     owner;
        address     tokenAddress;
        uint256     tokenId;
        uint256     startingBlock;
        TokenType   tokenType;
    }

    mapping(address => mapping(uint => uint)) gameIndexByOwnerAndId;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Roller  public roller;
    uint    public defaultBlockPeriod = 3;
    uint    public constant MAX_BLOCK_PERIOD = 24;
    BingoCardsNFT               public bingoCardsNFT;
    mapping(uint => Game)       public games;
    mapping (address => uint[]) public gameIdsByOwner;
    mapping(uint => address)    public winners;
    Counters.Counter            private gameCounter;
    mapping(uint => uint)       private blockPeriods;

    event GameCreated(uint indexed gameId, address indexed owner, address indexed tokenAddress, uint256 tokenId);
    event GameDeleted(uint indexed gameId, address indexed owner, address caller);
    event Deposited(address indexed user, address indexed tokenContract, uint256 tokenId);
    event Withdrawn(address indexed user, address indexed tokenContract, uint256 tokenId);
    event BINGO(uint indexed gameId, uint tokenId, address indexed winner);

    constructor() {
        roller = new Roller();
        bingoCardsNFT = BingoCardsNFT(0x731450431af5e6218603ad42591531c9Ce565f58); // goerli
    }

// NFT Transfer

    function newGameERC721(address tokenAddress, uint256 tokenId, uint rollFreq) external {
        require(IERC721(tokenAddress).ownerOf(tokenId) == msg.sender, "Not the owner.");
        require(rollFreq <= MAX_BLOCK_PERIOD, "Invalid block period");
        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        if (rollFreq > 0 && rollFreq != defaultBlockPeriod) {
            blockPeriods[gameCounter.current()] = rollFreq;
        }   
        _newGame(msg.sender, tokenAddress, tokenId, TokenType.ERC721);
    }

    function newGameERC1155(address tokenAddress, uint256 tokenId, uint rollFreq) external {
        require(IERC1155(tokenAddress).balanceOf(msg.sender, tokenId) > 0, "Not the owner.");
        require(rollFreq <= MAX_BLOCK_PERIOD, "Invalid block period");
        IERC1155(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        if (rollFreq > 0 && rollFreq != defaultBlockPeriod) {
            blockPeriods[gameCounter.current()] = rollFreq;
        }   
        _newGame(msg.sender, tokenAddress, tokenId, TokenType.ERC1155);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        require(msg.sender == address(IERC721(msg.sender)), "Only genuine ERC721 transfers allowed.");
        _newGame(from, msg.sender, tokenId, TokenType.ERC721);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address from, uint256 id, uint256 value, bytes calldata) external override returns(bytes4) {
        require(value == 1, "Can only deposit 1 token at a time.");
        require(msg.sender == address(IERC1155(msg.sender)), "Only genuine ERC1155 transfers allowed.");
        _newGame(from, msg.sender, id, TokenType.ERC1155);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata) external override returns(bytes4) {
        require(msg.sender == address(IERC1155(msg.sender)), "Only genuine ERC1155 batch transfers allowed.");
        for (uint256 i = 0; i < ids.length; i++) {
            _newGame(from, msg.sender, ids[i], TokenType.ERC1155);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function withdraw(uint gameId) external nonReentrant {
        require(games[gameId].owner == msg.sender, "Not the owner.");
        Game storage _game = games[gameId];
        if (_game.tokenType == TokenType.ERC1155) {
            IERC1155(_game.tokenAddress).safeTransferFrom(address(this), msg.sender, _game.tokenId, 1, "");
        } else if (_game.tokenType == TokenType.ERC721) {
            IERC721(_game.tokenAddress).transferFrom(address(this), msg.sender, _game.tokenId);
        }
        emit Withdrawn(msg.sender, _game.tokenAddress, _game.tokenId);
        deleteGame(gameId);
    }

// Game Management

    function _newGame(address gameOwner, address tokenAddress, uint256 tokenId, TokenType tokenType) private whenNotPaused returns (uint) {
        uint currentGameId = gameCounter.current();
        games[currentGameId] = Game(gameOwner, tokenAddress, tokenId, 0, tokenType);
        uint[] storage ownerGames = gameIdsByOwner[gameOwner]; 
        uint indexInOwnerList = ownerGames.length;
        ownerGames.push(currentGameId);
        gameIndexByOwnerAndId[gameOwner][currentGameId] = indexInOwnerList; 
        gameCounter.increment();
        emit GameCreated(currentGameId, gameOwner, tokenAddress, tokenId); 
        return currentGameId; 
    }

    function deleteGame(uint _gameId) private  {
        require(_gameId < gameCounter.current(), "Invalid game ID"); 
        address _owner = games[_gameId].owner;
        uint[] storage ownerGameIds = gameIdsByOwner[_owner];
        uint indexToDelete = gameIndexByOwnerAndId[_owner][_gameId];
        require(ownerGameIds[indexToDelete] == _gameId, "Data inconsistency!");  
        ownerGameIds[indexToDelete] = ownerGameIds[ownerGameIds.length - 1];
        gameIndexByOwnerAndId[_owner][ownerGameIds[indexToDelete]] = indexToDelete;
        ownerGameIds.pop();
        emit GameDeleted(_gameId, _owner, msg.sender);
        delete gameIndexByOwnerAndId[_owner][_gameId];  // Clean up
    }

    function startGame(uint _gameId) public whenNotPaused {
        require(_gameId < gameCounter.current(), "Invalid game ID"); 
        require(games[_gameId].owner == msg.sender, "Only owner can start game");
        require(games[_gameId].startingBlock == 0, "Game already started");
        games[_gameId].startingBlock = block.number;
    }

    function listGames(address _owner) external view returns (uint[] memory) {
        return gameIdsByOwner[_owner];
    }

    function gameCount() public view returns (uint) {
        return gameCounter.current();
    }

    function gameCountByOwner(address _owner) public view returns (uint) {
        return gameIdsByOwner[_owner].length;
    }

    function setBlockFreq(uint _gameId, uint _numBlocks) public {
        require(_gameId < gameCounter.current(), "Invalid game ID"); 
        require(games[_gameId].owner == msg.sender, "Only owner can set block freq");
        require(games[_gameId].startingBlock == 0, "Game already started");
        blockPeriods[_gameId] = _numBlocks;
    }

// Rolled Numbers

    function rollCounts(uint _gameId) public view returns (uint, uint) {
        require(games[_gameId].startingBlock > 0, "Game not started");
        require(_gameId < gameCounter.current(), "Invalid game ID"); 
        return rollCountsInternal(_gameId);
    }

    function rollCountsInternal(uint _gameId) internal view returns (uint, uint) {
        uint _blockPeriod = blockPeriods[_gameId] > 0 ? blockPeriods[_gameId] : defaultBlockPeriod;
        return roller.count(games[_gameId].startingBlock, _blockPeriod);
    }

    function isActive(uint _gameId) public view returns (bool) {
        (uint _rolls, uint _total) = rollCountsInternal(_gameId);
        return (_rolls <= _total);
    }

    function getBlockNumbers(uint _gameId) public view returns (uint[] memory) {
        require(_gameId < gameCounter.current(), "Invalid game ID"); 
        require(games[_gameId].startingBlock > 0, "Game not started");
        uint _blockPeriod = blockPeriods[_gameId] > 0 ? blockPeriods[_gameId] : defaultBlockPeriod;
        return roller.getBlockNumbers(games[_gameId].startingBlock, _blockPeriod);
    }

    function getRolls(uint _gameId) public view returns (uint[] memory) {
        require(_gameId < gameCounter.current(), "Invalid game ID"); 
        require(games[_gameId].startingBlock > 0, "Game not started");
        uint _blockPeriod = blockPeriods[_gameId] > 0 ? blockPeriods[_gameId] : defaultBlockPeriod;
        return roller.getRolls(games[_gameId].startingBlock, _blockPeriod, makeSeed(_gameId));
    }
    
    function currentBlockNumber() public view returns (uint) {
        return block.number;
    }

    function makeSeed(uint _gameId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_gameId, games[_gameId].owner, games[_gameId].startingBlock));
    }

// Bingo Cards

    function boardNumbersArray(uint tokenId) external view returns (uint8[5][5] memory){
        return bingoCardsNFT.boardArray(tokenId);
    }

    function boardNumbersString(uint tokenId) external view returns (string memory){
        return bingoCardsNFT.boardString(tokenId);
    }

    function fiveFromBoard(uint tokenId, uint orientation, uint index) public view returns (uint[5] memory) {
        require(index < 5, "Invalid index");
        uint[5] memory result;
        uint8[5][5] memory board = bingoCardsNFT.boardArray(tokenId);
        if (orientation == 0) { // HORIZONTAL
            result[0] = board[index][0];
            result[1] = board[index][1];
            result[2] = board[index][2];
            result[3] = board[index][3];
            result[4] = board[index][4];
            return result;
        } else if (orientation == 1) { // VERTICAL
            result[0] = board[0][index];
            result[1] = board[1][index];
            result[2] = board[2][index];
            result[3] = board[3][index];
            result[4] = board[4][index];
            return result;
        } else if (orientation == 2) { // DIAGONAL UP
            result[0] = board[4][0];
            result[1] = board[3][1];
            result[2] = 0;
            result[3] = board[1][3];
            result[4] = board[0][4];
            return result;
        } else if (orientation == 3) { // REVERSE DOWN
            result[0] = board[0][0];
            result[1] = board[1][1];
            result[2] = 0;
            result[3] = board[3][3];
            result[4] = board[4][4];
            return result;
        } else if (orientation == 4) { // FOUR CORNERS
            result[0] = board[0][0];
            result[1] = board[0][4];
            result[2] = board[4][0];
            result[3] = board[4][4];
            result[4] = 0; 
            return result;
        } else
            revert("Invalid orientation");
    }

    function fiveRolls(uint gameId, uint[5] memory indexes) public view returns (uint[5] memory) {
        require(isActive(gameId), "Game is not active");
        uint[5] memory result;
        uint[] memory rolls = getRolls(gameId);
        result[0] = rolls[indexes[0]];
        result[1] = rolls[indexes[1]];
        result[2] = rolls[indexes[2]];
        result[3] = rolls[indexes[3]];
        result[4] = rolls[indexes[4]];
        return result;
    }

    function fiveRollsCheap(uint gameId, uint[5] memory indexes) public view returns (uint[5] memory){
        require(isActive(gameId), "Game is not active");
        require(gameId < gameCounter.current(), "Invalid game ID"); 
        require(games[gameId].startingBlock > 0, "Game not started");
        uint _blockPeriod = blockPeriods[gameId] > 0 ? blockPeriods[gameId] : defaultBlockPeriod;
        return roller.fiveRollsByIndex(indexes, games[gameId].startingBlock, _blockPeriod, makeSeed(gameId));
    }

    //  PARAMS: 
    //  ----------------------------    
    //  gameId       game ID
    //  tokenId      gameBoard NFT
    //  orientation  0=horizontal, 1=vertical, 2=diagonal up, 3=diagonal down, 4=four corners
    //  index        0-4 to specify position of the 5 numbers on the game board
    //  indexes      5 indexes of the rolls to check

    function claimWinner(uint gameId, uint tokenId, uint orientation, uint index, uint[5] memory indexes) public whenNotPaused {
        require(isActive(gameId), "Game is not active");
        uint[5] memory fromBoard = fiveFromBoard(tokenId, orientation, index);
        uint[5] memory rolls = fiveRolls(gameId, indexes);
        require(winners[gameId] == address(0), "Game already won");
        require(fromBoard[0] == rolls[0], "Roll 0 doesn't match");
        require(fromBoard[1] == rolls[1], "Roll 1 doesn't match");
        require(fromBoard[2] == rolls[2] || fromBoard[2] == 0, "Roll 2 doesn't match"); // Center can be 0
        require(fromBoard[3] == rolls[3], "Roll 3 doesn't match");
        require(fromBoard[4] == rolls[4], "Roll 4 doesn't match");
        address _owner = bingoCardsNFT.ownerOf(tokenId);
        winners[gameId] = _owner;
    
        // Send NFT to winner
        Game storage _game = games[gameId];
        if (_game.tokenType == TokenType.ERC1155) {
            IERC1155(_game.tokenAddress).safeTransferFrom(address(this), _owner, _game.tokenId, 1, "");
        } else if (_game.tokenType == TokenType.ERC721) {
            IERC721(_game.tokenAddress).transferFrom(address(this), _owner, _game.tokenId);
        }
        emit Withdrawn(_owner, _game.tokenAddress, _game.tokenId);
        emit BINGO(gameId, tokenId, _owner);
        deleteGame(gameId); // delete from users list of games  
    }

    function checkWinner(uint gameId, uint tokenId, uint orientation, uint index, uint[5] memory indexes) public view returns (bool) {
        require(isActive(gameId), "Game is not active");
        uint[5] memory fromBoard = fiveFromBoard(tokenId, orientation, index);
        uint[5] memory rolls = fiveRolls(gameId, indexes);
        require(winners[gameId] == address(0), "Game already won");
        require(fromBoard[0] == rolls[0], "Roll 0 doesn't match");
        require(fromBoard[1] == rolls[1], "Roll 1 doesn't match");
        require(fromBoard[2] == rolls[2] || fromBoard[2] == 0, "Roll 2 doesn't match"); // Center can be 0
        require(fromBoard[3] == rolls[3], "Roll 3 doesn't match");
        require(fromBoard[4] == rolls[4], "Roll 4 doesn't match");
        return true;
    }

// Contract Admin

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setRoller(address _roller) public onlyOwner {
        require(address(roller) == address(0), "Roller already set");
        roller = Roller(_roller);
    }

    function setDefaultBlockPeriod(uint _blockPeriod) public onlyOwner {
        defaultBlockPeriod = _blockPeriod;
    }

    function setBingoCardAddr(address _bingoCardsNFT) public onlyOwner {
        bingoCardsNFT = BingoCardsNFT(_bingoCardsNFT);
    }

    function setName(address ensRegistry, string calldata ensName) external onlyOwner {
        ENSReverseRegistration.setName(ensRegistry, ensName);
    }


}