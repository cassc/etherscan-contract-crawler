// SPDX-License-Identifier: MIT
// ____                            ___       ______                                           
///\  _`\   __                    /\_ \     /\__  _\   __                                     
//\ \ \L\ \/\_\    __  _     __   \//\ \    \/_/\ \/  /\_\      __        __    _ __    ____  
// \ \ ,__/\/\ \  /\ \/'\  /'__`\   \ \ \      \ \ \  \/\ \   /'_ `\    /'__`\ /\`'__\ /',__\ 
//  \ \ \/  \ \ \ \/>  </ /\  __/    \_\ \_     \ \ \  \ \ \ /\ \L\ \  /\  __/ \ \ \/ /\__, `\
//   \ \_\   \ \_\ /\_/\_\\ \____\   /\____\     \ \_\  \ \_\\ \____ \ \ \____\ \ \_\ \/\____/
//    \/_/    \/_/ \//\/_/ \/____/   \/____/      \/_/   \/_/ \/___L\ \ \/____/  \/_/  \/___/ 
//                                                              /\____/                       
//                                                              \_/__/    
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface iPixelTigers {
    function ownerGenesisCount(address owner) external view returns(uint256);
    function numberOfLegendaries(address owner) external view returns(uint256);
    function numberOfUniques(address owner) external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function tokenGenesisOfOwner(address owner) external view returns(uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract PixelERC20 is ERC20, Ownable {

    uint256 constant public BASE_RATE = 7 ether;
    uint256 constant public OG_RATE = 10 ether;
    uint256 constant public LEGENDARY_UNIQUE_RATE = 15 ether;
    uint256 constant public BONUS_RATE = 1 ether;
    uint256 constant public TICKET_PRICE = 10 ether;

    uint256 public amountLeftForReserve = 145000 ether;
    uint256 public amountTakenFromReserve;
    uint256 public numEntriesMain;
    uint256 public numEntriesSub;
    uint256 public numEntriesEvent;
    uint256 public numEntriesSpend;
    uint256 public START = 1643130000;
    uint256 public priceEvents;
    uint256 public maxEventEntries;
    uint256 public priceSpend;

    bool public rewardPaused = false;
    bool public mainRaffleActive = false;
    bool public subRaffleActive = false;
    bool public eventsActive = false;

    mapping(address => uint256) public minttime;
    mapping(address => uint256) private storeRewards;
    mapping(address => uint256) private lastUpdate;

    mapping(address => bool) public allowedAddresses;

    iPixelTigers public PixelTigers;

    constructor(address nftAddress) ERC20("PIXEL", "PXL") {
        PixelTigers = iPixelTigers(nftAddress);
    }

    function airdrop(address[] calldata to, uint256 amount) external onlyOwner {
        uint256 totalamount = to.length * amount * 1000000000000000000;
        require(totalamount <= amountLeftForReserve, "No more reserved");
        for(uint256 i; i < to.length; i++){
            _mint(to[i], amount * 1000000000000000000);
        }
        amountLeftForReserve -= totalamount;
        amountTakenFromReserve += totalamount;
    }

    function timeStamp(address user) external {
        require(msg.sender == address(PixelTigers));
        storeRewards[user] += pendingReward(user);
        minttime[user] = block.timestamp;
        lastUpdate[user] = block.timestamp;
    }

    function enterMainRaffle(uint256 numTickets) external {
        require(PixelTigers.balanceOf(msg.sender) > 0, "Do not own any Tigers");
        require(mainRaffleActive, "Main Raffle not active");
        _burn(msg.sender, (numTickets*TICKET_PRICE));

        numEntriesMain += numTickets;
    }

    function enterSubRaffle(uint256 numTickets) external {
        require(PixelTigers.balanceOf(msg.sender) > 0, "Do not own any Tigers");
        require(subRaffleActive, "Sub Raffle not active");
        _burn(msg.sender, (numTickets*TICKET_PRICE));

        numEntriesSub += numTickets;
    }

    function enterEvents(uint256 count) external {
        require(PixelTigers.balanceOf(msg.sender) > 0, "Do not own any Tigers");
        require(eventsActive, "Sub Raffle not active");
        require(numEntriesEvent + count <= maxEventEntries, "No more slots");
        _burn(msg.sender, (count*priceEvents));

        numEntriesEvent += count;
    }

    function spend(uint256 count) external {
        require(PixelTigers.balanceOf(msg.sender) > 0, "Do not own any Tigers");
        _burn(msg.sender, (count*priceSpend));

        numEntriesSpend += count;
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(PixelTigers), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function claimReward() external {
        require(!rewardPaused, "Claiming of $pixel has been paused"); 
        _mint(msg.sender, pendingReward(msg.sender) + storeRewards[msg.sender]);
        storeRewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    //called when transfers happened, to ensure new users will generate tokens too
    function rewardSystemUpdate(address from, address to) external {
        require(msg.sender == address(PixelTigers));
        if(from != address(0)){
            storeRewards[from] += pendingReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            storeRewards[to] += pendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function totalTokensClaimable(address user) external view returns(uint256) {    
        return pendingReward(user) + storeRewards[user];
    }

    function numberOG(address user) external view returns(uint256){
        return PixelTigers.numberOfUniques(user) - PixelTigers.numberOfLegendaries(user);
    }

    function numLegendaryAndUniques(address user) external view returns(uint256){
        return PixelTigers.numberOfLegendaries(user);
    }

    function numNormalTigers(address user) external view returns(uint256){
        return PixelTigers.ownerGenesisCount(user) - PixelTigers.numberOfUniques(user);
    }

    function userRate(address user) external view returns(uint256){
        uint256 numberNormal = PixelTigers.ownerGenesisCount(user) - PixelTigers.numberOfUniques(user);
        uint256 numOG = PixelTigers.numberOfUniques(user) - PixelTigers.numberOfLegendaries(user);
        return PixelTigers.numberOfLegendaries(user) * LEGENDARY_UNIQUE_RATE + numOG * OG_RATE + (PixelTigers.ownerGenesisCount(user) - PixelTigers.numberOfUniques(user)) * BASE_RATE + (2 <= numberNormal ? 2 : numberNormal) * BONUS_RATE * numOG;
    }

    function pendingReward(address user) internal view returns(uint256) {
        uint256 numOG = PixelTigers.numberOfUniques(user) - PixelTigers.numberOfLegendaries(user);
        uint256 numberNormal = PixelTigers.ownerGenesisCount(user) - PixelTigers.numberOfUniques(user);
        if (minttime[user] == 0) {
            return PixelTigers.numberOfLegendaries(user) * LEGENDARY_UNIQUE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400 + numOG * OG_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400 + numberNormal * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400 + (2 <= numberNormal ? 2 : numberNormal) * BONUS_RATE * numOG * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) /86400;
        } else{
            return PixelTigers.numberOfLegendaries(user) * LEGENDARY_UNIQUE_RATE * (block.timestamp - (lastUpdate[user] >= minttime[user] ? lastUpdate[user] : minttime[user])) /86400 + numOG * OG_RATE * (block.timestamp - (lastUpdate[user] >= minttime[user] ? lastUpdate[user] : minttime[user])) /86400 + numberNormal * BASE_RATE * (block.timestamp - (lastUpdate[user] >= minttime[user] ? lastUpdate[user] : minttime[user])) /86400 + (2 <= numberNormal ? 2 : numberNormal) * BONUS_RATE * numOG * (block.timestamp - (lastUpdate[user] >= minttime[user] ? lastUpdate[user] : minttime[user])) /86400;
        }
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function setERC721(address ERC721Address) external onlyOwner {
        PixelTigers = iPixelTigers(ERC721Address);
    }

    function setEvent(uint256 price, uint256 maxentries) external onlyOwner {
        priceEvents = price * 1000000000000000000;
        maxEventEntries = maxentries;
    }

    function setSpend(uint256 price) external onlyOwner {
        priceSpend = price * 1000000000000000000;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }

    function clearMainRaffleList() external onlyOwner{
        numEntriesMain = 0;
    }

    function clearSubRaffleList() external onlyOwner{
        numEntriesSub = 0;
    }

    function clearEvents() external onlyOwner{
        numEntriesEvent = 0;
    }

    function toggleMainRaffle() public onlyOwner {
        mainRaffleActive = !mainRaffleActive;
    }

    function toggleSubRaffle() public onlyOwner {
        subRaffleActive = !subRaffleActive;
    }

    function toggleEvents() public onlyOwner {
        eventsActive = !eventsActive;
    }
}