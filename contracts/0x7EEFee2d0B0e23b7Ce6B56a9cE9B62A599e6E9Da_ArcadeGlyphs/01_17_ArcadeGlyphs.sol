// SPDX-License-Identifier: CC-BY-4.0

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IArcadeBackend.sol";
import "./IPrizeAssets.sol";
import "./BiCounter.sol";

contract ArcadeGlyphs is ERC721Enumerable, Ownable, ReentrancyGuard {
    using BiCounters for BiCounters.BiCounter;
    BiCounters.BiCounter private prizeIds;


    struct Game {
        bool initialized;
        uint maxSupply;
        uint startTokenId;
        uint startingPrice;
        uint bulkMintingAmount;
        IArcadeBackend backend;
        BiCounters.BiCounter counter;
    }

    struct Prize {
        uint minScore;
        uint maxScore;
        uint ranking;
        bool created;
        uint winningToken;
        uint tokenId;
        address winningWallet;
        IPrizeAssets prizeAssets;
    }

    address payable public artistWallet;
    
    mapping(uint => uint) pointsToPrizeTokenId;

    mapping(string => Game) gameNameToGame;

    mapping(uint => Prize) tokenIdToPrize;
    mapping(uint => bool) tokenIdToVictory;

    mapping(uint => Game) indexToGame;
    uint gameCount; 

    modifier onlyTokenOwner(uint tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner");

        _;
    }

    constructor () ERC721 ("ArcadeGlyphs", "ARCADE") {
        prizeIds.reset((1 << 256) - 1);
        artistWallet = payable(msg.sender);
    }

    function setArtistWallet(address payable wallet) public onlyOwner {
        artistWallet = wallet;
    }

    function setPrizes(string memory name, uint ranks, uint[5] memory minScores, uint[5] memory maxScores, address prizeAssets) public onlyOwner {
        for(uint i = 0; i < ranks; i++) {
            addPrize(name, i, minScores[i], maxScores[i], prizeAssets);
        }
    }

    function addPrize(string memory name, uint rank, uint minScore, uint maxScore, address prizeAssets) public onlyOwner {
        require(gameNameToGame[name].initialized, "Not existing game");

        prizeIds.decrement();
        uint prizeTokenId = prizeIds.current();
        tokenIdToPrize[prizeTokenId] = Prize(minScore, maxScore, rank, true, 0, prizeTokenId, address(0), IPrizeAssets(prizeAssets));
        _mint(address(this), prizeTokenId);
    }

    function setGame(string memory name, uint supply, uint startingPrice, uint bulkMintingAmount, address backendAddress) public onlyOwner {
        uint startTokenId = 1;
        if(gameCount != 0) {
            startTokenId = indexToGame[gameCount - 1].startTokenId + indexToGame[gameCount - 1].maxSupply;
        }

        gameNameToGame[name] = Game(true, supply, startTokenId, startingPrice, bulkMintingAmount, IArcadeBackend(backendAddress), BiCounters.BiCounter(startTokenId));
        indexToGame[gameCount] = gameNameToGame[name];
        gameCount++;
    }

    function backendFromTokenId(uint tokenId) internal view returns (IArcadeBackend _backend) {
        for (uint i = 0; i < gameCount; i++) {
            if(indexToGame[i].startTokenId + indexToGame[i].maxSupply > tokenId) {
                return indexToGame[i].backend;
            }
        }
    }

    function validateRequest(Game storage game, uint amount) internal view {
        require(game.initialized, "Game does not exist");
        require(game.startingPrice * amount <= msg.value, "Too few ETH.");
        require(game.counter.current() + amount <= game.startTokenId + game.maxSupply, "No more mintable tokens");
    }

    // -- Public interface
    function alreadyMinted(string memory name) external view returns (uint _count) {
        Game storage game = gameNameToGame[name];
        return game.counter.current() - game.startTokenId;
    }

    function supplyForGame(string memory name) external view returns (uint _supply) {
        Game memory game = gameNameToGame[name];
        return game.maxSupply;
    }

    function currentPrice(string memory name) external view returns (uint _price) {
        return gameNameToGame[name].startingPrice;
    }

    function currentBulkPrice(string memory name) external view returns (uint _price) {
        return gameNameToGame[name].startingPrice * gameNameToGame[name].bulkMintingAmount;
    }

    // Prize logic

    function claimPrize(uint tokenId, uint prizeId) external onlyTokenOwner(tokenId) {
        checkEligibility(tokenId, prizeId);

        Prize storage prize = tokenIdToPrize[prizeId];
        _safeTransfer(address(this), msg.sender, prize.tokenId, "");
        prize.winningToken = tokenId;
        prize.winningWallet = msg.sender;
        tokenIdToVictory[tokenId] = true;
    }

    function checkEligibility(uint tokenId, uint prizeId) public view onlyTokenOwner(tokenId) {
        Prize memory prize = tokenIdToPrize[prizeId];
        require(prize.winningWallet == address(0), "Prize already won");
        require(!tokenIdToVictory[tokenId], "Token already used");
        backendFromTokenId(tokenId).verifyPoints(prize.minScore, prize.maxScore, tokenId);
    }

    function getPrizeIdData(uint prizeId) external view returns (uint ranking, address winner, uint winningToken) {
        Prize memory prize = tokenIdToPrize[prizeId];
        if(prize.created) {
            return (prize.ranking, prize.winningWallet, prize.winningToken);
        }
    }

    // Minting

    function mintGlyphs(Game storage game, uint amount) internal {
        validateRequest(game, amount);
        bool success = false;
        (success, ) = artistWallet.call{value:msg.value}("");
        require(success, "Artist failed to receive");

        for(uint i = 0; i < amount; i++) {
            uint tokenId = game.counter.current();
            game.counter.increment();
            
            game.backend.insertCoin(tokenId, block.number - i);
            
            _mint(msg.sender, tokenId);
        }
        
    }

    function insertNote(string memory name) external payable nonReentrant {
        Game storage game = gameNameToGame[name];
        uint amount = game.bulkMintingAmount;
        
        mintGlyphs(game, amount);
    }

    function insertCoin(string memory name) external payable nonReentrant {
        Game storage game = gameNameToGame[name];
           
        mintGlyphs(game, 1);
    }

    // Interaction

    function restart(uint tokenId) external onlyTokenOwner(tokenId) {
        backendFromTokenId(tokenId).restart(tokenId);
    }

    function interact(uint tokenId, uint[6] memory intActions, string[6] memory stringActions) external onlyTokenOwner(tokenId) {
        backendFromTokenId(tokenId).interact(tokenId, intActions, stringActions);
    }

    // -- ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        Prize memory prize = tokenIdToPrize[tokenId];
        if(prize.created) {
            return prize.prizeAssets.getPrize(prize.ranking, prize.winningWallet, prize.winningToken);
        }

        return backendFromTokenId(tokenId).tokenURI(tokenId);
    }
}