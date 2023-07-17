// SPDX-License-Identifier: GPL-3.0

/*
             ░┴W░
             ▒m▓░
           ╔▄   "╕
         ╓▓╣██,   '
       ,▄█▄▒▓██▄    >
      é╣▒▒▀███▓██▄
     ▓▒▒▒▒▒▒███▓███         ███╗   ██╗███████╗████████╗    ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗██╗   ██╗
  ,╢▓▀███▒▒▒██▓██████       ████╗  ██║██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝
 @╢╢Ñ▒╢▒▀▀▓▓▓▓▓██▓████▄     ██╔██╗ ██║█████╗     ██║       ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║    ╚████╔╝
╙▓╢╢╢╢╣Ñ▒▒▒▒██▓███████▀▀    ██║╚██╗██║██╔══╝     ██║       ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║     ╚██╔╝
   "╩▓╢╢╢╣╣▒███████▀▀       ██║ ╚████║██║        ██║       ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║      ██║
      `╨▓╢╢╢████▀           ╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝
          ╙▓█▀

*/

pragma solidity ^0.8.17;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC721EnumerableSlim} from "./ERC721EnumerableSlim.sol";
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "./IDescriptor.sol";
import {Tools} from "./Tools.sol";

contract NfinityToken is ERC721EnumerableSlim, Ownable, ReentrancyGuard {
    uint256 constant DIVIDER = 1_000_000;
    uint256 public constant WINNER_GAP_SECONDS = 24 * 3600;
    uint256 constant MAX_REVEAL_COUNT = 3;

    IDescriptor public descriptor;
    address public gameContractAddress;

    // game configs
    uint256 public mintCostRate;
    uint256 public jackpotRate = 310_000;
    uint256 public gamepotRate = 0;
    uint256 public constant fomopotRate = 430_000;

    mapping(address => uint256) public otherPoolRate; // n/1000000, current rate

    // game status
    struct GameStatus {
        // The internal noun ID tracker
        uint32 lastMintNftId;
        uint32 lastMintTs;
        uint32 lastRevealedNftId;
        uint32 lastUnlockedNftId;
        uint128 currentPrice;
        uint128 fomoPer; // fomo per nft starts from 1 till the end, wei
    }

    GameStatus public gameStatus;

    // moneys
    uint256 public initPrice;
    uint256 public jackpotPoolSink; // jackpot pool (before jackpot rate changed)
    uint256 public gamepotPoolSink;
    uint256 public mintPool; // all income from mint
    uint256 public mintPoolSink; // jackpot + gamepot (sink by mint)

    // user status
    mapping(uint256 => uint256) public fomoExpired; // wei
    mapping(uint256 => uint256) public fomoClaimed; // wei
    mapping(address => uint256) public userClaimed; // wei
    mapping(uint256 => uint256) public jackpotClaimed; // wei
    uint256 public gamepotClaimed; // wei
    mapping(uint256 => uint256) public cardSeeds;

    uint[5] probabilities = [720_000, 880_000, 979_000, 999_000, 1_000_000];


    //    uint256 public py = 0;  // previous 100 time duration
    uint256 public yts = 0; // current 100 start timestamp

    event Claimed(uint256 indexed tokenId, address indexed claimer, uint256 amount);

    struct CardStats {
        uint256 claimableFomo;
        uint256 claimedFomo;
        uint256 tokenId;
        uint256 price;
        IDescriptor.CardInfo card;
    }

    struct UserStats {
        uint256 totalClaimableFomo;
        uint256 totalClaimedFomo;
        uint256 totalClaimableJackpot;
        uint256 totalClaimedJackpot;
        uint256 totalClaimableUser;
        uint256 totalClaimedUser;
    }

    constructor(IDescriptor _descriptor, uint128 _initPrice) ERC721('NfinityToken', 'NfinityToken') {
        descriptor = _descriptor;
        gameStatus.currentPrice = _initPrice;
        initPrice = _initPrice;
        mintCostRate = 1000200;
        otherPoolRate[address(0xc668023e7d0fb8cC28339011979d563AFAbd6630)] = 100000;
        otherPoolRate[address(0xB2F63f284515Aaf013d9CFa553cf32A314De13A6)] = 60000;
        otherPoolRate[address(0x2685E91A7e3D8336F5e3dD9e3C07F869fE350B9a)] = 100000;
    }

    function deposit() external payable {
        jackpotPoolSink += msg.value;
    }

    fallback() external payable {jackpotPoolSink += msg.value;}

    receive() external payable {jackpotPoolSink += msg.value;}

    function unchecked_inc(uint i) internal pure returns (uint) {
    unchecked {
        return i + 1;
    }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'non-exists token');
        IDescriptor.CardInfo memory card = getCardInfo(tokenId);
        return descriptor.renderMeta(card, tokenId);
    }

    function _publicMintable() internal view returns (bool){
        uint lastMintTs = gameStatus.lastMintTs;
        return lastMintTs > 0 && block.timestamp < lastMintTs + WINNER_GAP_SECONDS;
    }

    function publicMintable() external view returns (bool){
        return _publicMintable();
    }

    function winTs() external view returns (uint){
        return gameStatus.lastMintTs + WINNER_GAP_SECONDS;
    }

    function lastMintNftId() external view returns (uint){
        return gameStatus.lastMintNftId;
    }

    function currentPrice() external view returns (uint){
        return gameStatus.currentPrice;
    }

    function startMint() external onlyOwner payable {
        require(gameStatus.lastMintNftId == 0, "already started");
        return _mint(1);
    }

    function settleGame(address _gameContractAddress) external onlyOwner {
        gameContractAddress = _gameContractAddress;
        jackpotPoolSink += (mintPool - mintPoolSink) * jackpotRate / DIVIDER;
        gamepotPoolSink += (mintPool - mintPoolSink) * gamepotRate / DIVIDER;
        mintPoolSink = mintPool;
        if (gameContractAddress == address(0)) {
            jackpotRate = 300_000;
            gamepotRate = 0;
        } else {
            jackpotRate = 200_000;
            gamepotRate = 100_000;
        }
    }

    function revealCards(uint256 start, uint256 end) external onlyOwner {
        for (uint256 tokenId = start; tokenId <= end; tokenId = unchecked_inc(tokenId)) {
            cardSeeds[tokenId] = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, tokenId)));
        }
        gameStatus.lastRevealedNftId = uint32(end);
        gameStatus.lastUnlockedNftId = uint32(end);
    }

    function revealPreviousCards(uint256 lastRevealedNftId, uint256 lastUnlockedNftId) internal returns (uint256 newLastRevealedNftId){

    unchecked{
        uint256 tokenId = lastRevealedNftId + 1;
        uint256 count = 0;
        while (tokenId <= lastUnlockedNftId) {
            cardSeeds[tokenId] = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, tokenId)));
            ++count;
            ++tokenId;
            if (count >= MAX_REVEAL_COUNT) {
                break;
            }
        }
        return tokenId - 1;
    }
    }

    function updateProbability() internal {
        if (yts != 0) {
            // starts from 5000
            uint y = block.timestamp - yts;
            if (y > 168 * 3600) {
                probabilities = [430_000, 730_000, 930_000, 990_000, 1000_000];
            } else if (y > 48 * 3600) {
                probabilities = [560_000, 800_000, 960_000, 995_000, 1000_000];
            } else if (y > 12 * 3600) {
                probabilities = [620_000, 840_000, 970_000, 997_000, 1000_000];
            } else {
                probabilities = [720_000, 880_000, 979_000, 999_000, 1000_000];
            }
        }

        yts = block.timestamp;
    }

    function getCardInfo(uint256 tokenId) public view returns (IDescriptor.CardInfo memory cardInfo){
        uint256 seed = cardSeeds[tokenId];
        uint cardClassSeed = ((seed >> (256 - 16)) & 0xFFFF) * DIVIDER / 0x10000;
        uint rarity;

        //  73  [40, 55, 75,]
        for (uint i = 0; i < 5; i = unchecked_inc(i)) {
            if (cardClassSeed <= probabilities[i]) {
                rarity = i;
                break;
            }
        }
        cardInfo.rarity = uint8(rarity);
        cardInfo.seed = seed;

        uint8 v1;
        uint8 v2;

        if (rarity == 0) {
            v1 = 10;
            v2 = 40;
        } else if (rarity == 1) {
            v1 = 20;
            v2 = 50;
        } else if (rarity == 2) {
            v1 = 40;
            v2 = 80;
        } else if (rarity == 3) {
            v1 = 60;
            v2 = 100;
        } else if (rarity == 4) {
            v1 = 90;
            v2 = 120;
        }

        cardInfo.nation = Tools.Random8Bits(seed, 0, 0, 31);
        cardInfo.attack = Tools.Random8Bits(seed, 2, v1, v2);
        cardInfo.defensive = Tools.Random8Bits(seed, 3, v1, v2);
        cardInfo.physical = Tools.Random8Bits(seed, 4, v1, v2);
        cardInfo.tactical = Tools.Random8Bits(seed, 5, v1, v2);
        cardInfo.luck = Tools.Random8Bits(seed, 6, v1, v2);
    }

    function _mint(uint256 mintCount) internal nonReentrant {
        require(tx.origin == msg.sender, "eoa");
        // fail fast if value not enough
        uint256 minPrice = _mintPrice(mintCount);
        require(msg.value >= minPrice, "pay it");

        GameStatus memory oldGameStatus = gameStatus;
        uint256 newLastMintNftId = oldGameStatus.lastMintNftId;
        uint256 newLastMintTs = oldGameStatus.lastMintTs;
        uint256 newLastRevealedNftId = oldGameStatus.lastRevealedNftId;
        uint256 newLastUnlockedNftId = oldGameStatus.lastUnlockedNftId;

        uint256 newCurrentPrice = oldGameStatus.currentPrice;
        uint256 newFomoPer = oldGameStatus.fomoPer;

        if (block.timestamp != newLastMintTs) {
            // advance unlocked block
            newLastUnlockedNftId = newLastMintNftId;
        }

        for (uint256 i = 0; i < mintCount; i = unchecked_inc(i)) {
            newLastMintNftId = unchecked_inc(newLastMintNftId);
            _safeMint(msg.sender, newLastMintNftId);
            if (newLastMintNftId % 100 == 0) {
                if (newLastMintNftId >= 5000) {
                    updateProbability();
                }
            }

            // reveal previous cards only after block + 1;
            // to prevent flashbots bundle attack (to some extent)
            if (newLastRevealedNftId < newLastUnlockedNftId) {
                newLastRevealedNftId = revealPreviousCards(newLastRevealedNftId, newLastUnlockedNftId);
            }

            if (newLastMintNftId > 1) {
                //  for token id = 2, per = 1
                newFomoPer += newCurrentPrice * fomopotRate / (newLastMintNftId - 1) / DIVIDER;
                fomoExpired[newLastMintNftId] = newFomoPer;
            }
            newCurrentPrice = newCurrentPrice * mintCostRate / DIVIDER;
        }

        oldGameStatus.lastMintNftId = uint32(newLastMintNftId);
        oldGameStatus.lastMintTs = uint32(block.timestamp);
        oldGameStatus.lastRevealedNftId = uint32(newLastRevealedNftId);
        oldGameStatus.lastUnlockedNftId = uint32(newLastUnlockedNftId);
        oldGameStatus.currentPrice = uint128(newCurrentPrice);
        oldGameStatus.fomoPer = uint128(newFomoPer);

        gameStatus = oldGameStatus;

        mintPool += minPrice;

        // change
        payable(msg.sender).transfer(msg.value - minPrice);
    }

    function mint(uint256 mintCount) public payable {
        require(_publicMintable(), "cannot mint");
        require(mintCount != 0, "bad mint");
        require(mintCount <= 10, "too much");
        return _mint(mintCount);
    }

    function _mintPrice(uint256 mintCount) internal view returns (uint256 price){
        uint256 nextPrice = gameStatus.currentPrice;
        for (uint256 i = 0; i < mintCount; i = unchecked_inc(i)) {
            price += nextPrice;
            nextPrice = nextPrice * mintCostRate / DIVIDER;
        }
    }

    function mintPrice(uint256 mintCount) external view returns (uint256 price){
        return _mintPrice(mintCount);
    }

    function setMintCostRate(uint256 rate) external onlyOwner {
        mintCostRate = rate;
    }

    function setDescriptor(address _descriptor) external onlyOwner {
        descriptor = IDescriptor(_descriptor);
    }

    function jackpot() public view returns (uint256 value){
        return jackpotPoolSink + (mintPool - mintPoolSink) * jackpotRate / DIVIDER;
    }

    function claimNftProfit(uint256 tokenId) public nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "not owned");
        uint256 jackpotProfit = claimableJackpotProfit(tokenId);
        uint256 fomoProfit = claimableFomoProfit(tokenId);

        fomoClaimed[tokenId] += fomoProfit;
        jackpotClaimed[tokenId] += jackpotProfit;
        payable(msg.sender).transfer(fomoProfit + jackpotProfit);
        emit Claimed(tokenId, msg.sender, fomoProfit + jackpotProfit);
    }

    function claimNftProfitBatch(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i = unchecked_inc(i)) {
            claimNftProfit(tokenIds[i]);
        }
    }

    function claimUserProfit() external nonReentrant {
        uint256 distributeValue = claimableUserProfit(msg.sender);
        userClaimed[msg.sender] += distributeValue;
        payable(msg.sender).transfer(distributeValue);
        emit Claimed(0, msg.sender, distributeValue);
    }

    function claimGameProfit() external nonReentrant {
        require(msg.sender == gameContractAddress, "not game");
        uint256 distributeValue = gamepotPoolSink + (mintPool - mintPoolSink) * gamepotRate / DIVIDER - gamepotClaimed;
        gamepotClaimed += distributeValue;
        payable(msg.sender).transfer(distributeValue);
        emit Claimed(0, msg.sender, distributeValue);
    }

    function claimableUserProfit(address user) public view returns (uint256 distributeValue){
        distributeValue = otherPoolRate[user] * mintPool / DIVIDER;
        // otherPool
        distributeValue -= userClaimed[user];
    }

    function claimableJackpotProfit(uint256 tokenId) public view returns (uint256 distributeValue){
        distributeValue = 0;
        uint _lastMintNftId = gameStatus.lastMintNftId;
        uint lastMintTs = gameStatus.lastMintTs;

        if (lastMintTs != 0 && block.timestamp >= lastMintTs + WINNER_GAP_SECONDS && _lastMintNftId == tokenId) {
            distributeValue += jackpot();
        }
        // do not count the profit user already claimed
        distributeValue -= jackpotClaimed[tokenId];
    }

    function claimableFomoProfit(uint256 tokenId) public view returns (uint256 distributeValue){
        // fomo
        distributeValue = gameStatus.fomoPer;
        // do not count the profit before user in
        distributeValue -= fomoExpired[tokenId];
        // do not count the profit user already claimed
        distributeValue -= fomoClaimed[tokenId];
    }

    function historyMintPrice(uint256 tokenId) public view returns (uint256 price){
        uint _lastMintNftId = gameStatus.lastMintNftId;
        require(tokenId <= _lastMintNftId, "future id");
        if (tokenId == 1) {
            return initPrice;
        }
        return (fomoExpired[tokenId] - fomoExpired[tokenId - 1]) * (tokenId - 1) * DIVIDER / fomopotRate;
    }

    function cardStats(uint256 tokenId) public view returns (CardStats memory stats){
        stats = CardStats({
        claimableFomo : claimableFomoProfit(tokenId),
        claimedFomo : fomoClaimed[tokenId],
        tokenId : tokenId,
        price : historyMintPrice(tokenId),
        card : getCardInfo(tokenId)
        });
    }

    function batchCardStats(address user, uint256 offset, uint256 limit) external view returns (CardStats[] memory stats){
        uint256 balance = balanceOf(user);
        uint256 right = balance;
        if (offset + limit < right) {
            right = offset + limit;
        }
        stats = new CardStats[](right - offset);
        for (uint256 i = offset; i < right; i = unchecked_inc(i)) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            stats[i - offset] = cardStats(tokenId);
        }
    }

    function userStats(address user) external view returns (UserStats memory stats){
        uint256 totalClaimableFomo;
        uint256 totalClaimedFomo;
        uint256 totalClaimableJackpot;
        uint256 totalClaimedJackpot;
        uint256 totalClaimableUser;
        uint256 totalClaimedUser;
        uint256 balance = balanceOf(user);

        for (uint256 i = 0; i < balance; i = unchecked_inc(i)) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            totalClaimableFomo += claimableFomoProfit(tokenId);
            totalClaimedFomo += fomoClaimed[tokenId];
            totalClaimableJackpot += claimableJackpotProfit(tokenId);
            totalClaimedJackpot += jackpotClaimed[tokenId];
        }
        totalClaimableUser = claimableUserProfit(user);
        totalClaimedUser = userClaimed[user];

        stats = UserStats({
        totalClaimableFomo : totalClaimableFomo,
        totalClaimedFomo : totalClaimedFomo,
        totalClaimableJackpot : totalClaimableJackpot,
        totalClaimedJackpot : totalClaimedJackpot,
        totalClaimableUser : totalClaimableUser,
        totalClaimedUser : totalClaimedUser
        });
    }
}