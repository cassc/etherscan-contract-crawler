// SPDX-License-Identifier: MIT
/*
xkxllolccllllolloooooddddddddddoddxxxdoddxxdoodddoooooxxoddddddooddxxkOO000000OOkxolllccldxxxdloxdoc
kxoollccllllloodddddddddddddddddoooddxddddxxddoddoooxxxdddoooddxxkkkkOOkkkkkkkkkkkkxdolcccloxxdolodl
dlloolllllloddddoooooooooddddddddoooooodddddxxddoddxkxddooodxxxxxxxxxxxxkkkkkkkxxxxxxxdolccccoxxollo
llodollllodddollcllllloooooddxxxdddddoloodddxxxxdxxxxxddooddxddxxxkkkkkxxxxxxxkkkkkkxxxxdoccccloxdll
ldxollloodxdlccloollllllooooodxxxdddxddoododxxxxxdddxxddddddxxxxkkkxdoolloolloooodxxkkkxxxolcc:coxdl
dkdcloloxxdlclooollllooooodddoodxxdddxkxddddddxxxdddddddddxxxxxxkxollooodddoollllloooodxkxdolc:;:ldd
kklclllxkxlccoollllooolloooodxdodxxxddxkkdoddxxxxxxxxxxxxxxxxxdxdllodddddoooolllllloolloxxddocc:;:ld
kxlcllokkolllolclooolloddoooodxdodxxxdxkkkddxxkkxkxxkxkxkkxxddxdlloddolllooooolllllloddloxxdooc:::co
kxlcoodkxollolclolllloddooolloxdodxxxddkkkxdxxkkkkxxxkkkkkkdoxxooooollloddooolloooooldxdldxdooc::::o
kkollodkkdoolllodolllllollolldxoldkkxdodkOxodxkxdxxddkOOOkxodkxdoollloddxddoooooooooodxxodxdooccc::o
xkdlldddkkdoolloddolccclooooddoodkkkxoodkOxoc:c:;;::ccldkxddxxxdololldxxkkxxkOkooddoddxxodxdolccc:cd
xkxolodddkkdolllodxdllcccllooodxkkkkxoodkko;,;,,;,..'',:cldxxddolodoloxxkkxxxxddddoddxxdoxxdoc:cccld
dxkdolodddxxxdoolloddddooodxxxkxxxxxdloddc,,,::c;''.',,:c::cdxdoooxdolddxxkxxddoooddddxddkxolcccccod
odxxxdoodoodxxxdoolllooddxxxxxddxxxdlloc;,',;cc,',''.,;',llcclddoloddoloodddddxddddddddxxxdlccccclod
xdddxxxdddoolodddddddodddddddddxxxoll:;,'',:cc;'''.'..:;.':oolllodoodxxdodddoooooddxdxxxxolccccclood
kxdoodxkkxdddoolooooooooooooddxxdol:;,,',:cc::,.......':;..';cllcllooodxxxxddddddxxxxxdolccccclooodd
dxxxdooddxxkkxxxxddddodddddxxddolc;,'',:ll:;;,.........'cc,.',,;clcclododddxxxxxxddoollcccclloddoooo
llodxdddooooddxxxkkkkxxxxxxddooc;'..':ll:,,;;'...'.......;:;,;,'';cllcloddooooooollllllllooddxdolool
lccclddxxddoooooooddddddddooo:,...,:ll;..',;;,....,'.......;l:''.'',:cccclddddddddddddddddooolllodod
dollcccllooooooooooooolllll:'...',cl:'.,;..';'......,'......;ol;...''',;:clcloddooooooolllcccclodddx
ooddollcccccllclllllooooc;..'...',,,,,;,. ..;....',..''......'coc,...''..';:cc::cllllccccclloddddodo
cclodddooollloooodoool:,..;;'...'',,,'.....;;.....;:;..,'......;ll:,'..''...':cc;;;:ccloodddollllodx
ollccloddddddoooolc;'..,:c:'..','''.......;l,......'::..,;... ...,clc;'....'...';;,,,'';:cloooodxxkk
lllllllcclloddo:,....,ccc;,'.'...''......'lc.....   .::..';'.... ..':lc;,..........';;;;,'''';::ccll
lcccllooooc:,.. ..';::,',,....','........:l'........ ..;,..,'.    ....;cc:,''''.......',;::;,'......
ooolc:;;,.. ...,;::;,'......''.......  .;l,........... ......'.  .......,:c::;;;,'..................
lc::,'...',,;;;,'',,......... ..',.. ..;l:.............    ...'.  .........,;'';;,,,'...............
'';;,',,;;,'....,;,............,;.....;cc,.............. ......'. ....'...................''........
...;::,...............................'''..','''....................................................
...',,'...............,,;;:;,,'''',;;;;;;;;:c:;,,,,;,,,,,,,,,''.'',,,;;,,,,,,''''''''''''''...'''',,
'',,,,,,'''.'''...',,;;;:ccc::::ccccccccc:cc:::;,,,,,,,,,,,,,,,;;::cccccc::;;,,,,;;:cclllllllllllccc
cclllooooooolcccc:;,,,,,,,,,,,;;;;;;;;;;;;;,,,,,,',''','''''',,;::;,,'''.....',;:cclllllooollccccccc
lllllllloooooooddddolc:;,,,,,,;;;;;:::::::::ccc::;,,,,,,,,;;:::c:;,,'''''',;:clolllooooolcccccllcccl
llcccllllllllllllllllllc:,'''',;;;;::ccc:cclllc:,,'',,,',;;;;,,,,,''',;:ccloddoolooooolllooooooooooo
dooolllcllloooodddoooooddoolc;,,,,,,,,,;;;;;;;;,''''',,,,;,,,,,;,,,;clooddddollodooooddxddoolllooood
dooddooolccllllooooollodddoolcc:;,,''''',,,,;;;;;;;;;;;;,,'''''',;:cloooollccoddooddxxxxdddddolooddd
oooooddddollloollooooolooddddoool:'.....'',,;;::::::ccc::;,,,,,;clooooooolclodxdoodxxxxxxxddddoooddd
*/
pragma solidity ^0.8.4;

import "../util/Ownable.sol";
import "../util/IERC20.sol";
import "../util/ISOUL.sol";


abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract VolcanoEmpire is Ownable, ReentrancyGuard{
    struct Tower {
        uint256 coins;
        uint256 money;
        uint256 money2;
        uint256 money3;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 ref2s;
        uint256 ref3s;
        uint8 treasury;
        uint8[6] chefs;
        bool notnew;
    }



    mapping(address => Tower) public towers;

    event Burn(address indexed _addr, uint256 _amount);
    event Buy(address indexed _addr, address _ref, uint256 _amount);

    IERC20 constant BUSD_TOKEN = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    ISOUL constant SOUL_TOKEN = ISOUL(0x811005F673f2aFB59070D2dc39F79f1717a0b3f6);
    uint256 public totalChefs;
    uint256 public totalTowers;
    uint256 public newbieCount = 0;
    uint256 public cap = 1000;
    uint256 public totalInvested;
    address public manager;
    address public marketing;
    bool soul = true;

    constructor(address _manager, address _marketing) {
       manager = _manager;
       marketing = _marketing;
    }

    function addcoins(address ref, uint256 value) external noReentrant {
        uint256 coins = value / 10e14;
        require(coins > 0, "Zero coins");
        address user = msg.sender;
        totalInvested += value;
        if (towers[user].timestamp == 0) {
            totalTowers++;
            if(towers[ref].timestamp != 0){
                towers[user].ref = ref;
                towers[ref].refs++;
                address ref2 = towers[ref].ref;
                if(towers[ref2].timestamp != 0){
                   towers[ref2].ref2s++;
                   address ref3 = towers[ref2].ref;
                   if(towers[ref3].timestamp != 0){
                      towers[ref3].ref3s++;
                  }
                }
            }
            towers[user].timestamp = block.timestamp;
            towers[user].treasury = 0;
         }
         ref = towers[user].ref;
         if (ref != address(0)){
            towers[ref].coins += (coins * 8) / 100;
            towers[ref].money += (coins * 2) / 100;
            towers[ref].money3 += (coins * 2) / 100;
            address ref2 = towers[ref].ref;
            if(ref2 != address(0)){
                towers[ref2].coins += (coins * 2) / 100;
                towers[ref2].money += (coins * 1) / 100;
                towers[ref2].money3 += (coins * 1) / 100;
                address ref3 = towers[ref2].ref;
                if(ref3 != address(0)){
                    towers[ref3].coins += (coins * 1) / 100;
                    towers[ref3].money += (coins * 1) / 100;
                    towers[ref3].money3 += (coins * 1) / 100;
                }
           }
        }
        towers[user].coins += coins;
        towers[manager].coins += (coins * 6) / 100;
        uint256 value2 = (value * 3) / 100;
        uint256 value3 = (value * 1) / 100;
        BUSD_TOKEN.transferFrom(msg.sender, marketing, value2);
        BUSD_TOKEN.transferFrom(msg.sender, manager, value3);
        BUSD_TOKEN.transferFrom(msg.sender, address(this), value - value2 - value3);
        emit Buy(msg.sender, ref, value);
    }

    function withdrawMoney(uint256 gold) external noReentrant {
        address user = msg.sender;
        require(gold <= towers[user].money && gold > 0);
        towers[user].money -= gold;
        uint256 amount = gold * 10e12;
        BUSD_TOKEN.transfer(user, BUSD_TOKEN.balanceOf(address(this)) < amount ? BUSD_TOKEN.balanceOf(address(this)) : amount);
    }

    function collectMoney() public noReentrant {
        address user = msg.sender;
        syncTower(user);
        towers[user].hrs = 0;
        towers[user].money += towers[user].money2;
        towers[user].money2 = 0;
    }

    function upgradeTower(uint256 towerId) external noReentrant {
        require(towerId < 6, "Max 6 towers");
        address user = msg.sender;
        syncTower(user);
        towers[user].chefs[towerId]++;
        totalChefs++;
        uint256 chefs = towers[user].chefs[towerId];
        towers[user].coins -= getUpgradePrice(towerId, chefs);
        towers[user].yield += getYield(towerId, chefs);
    }

    function upgradeTreasury() external noReentrant {
      address user = msg.sender;
      uint8 treasuryId = towers[user].treasury + 1;
      syncTower(user);
      require(treasuryId < 5, "Max 5 treasury");
      (uint256 price,) = getTreasure(treasuryId);
      towers[user].coins -= price;
      towers[user].treasury = treasuryId;
    }

    function getBase(address addr) external view returns (uint8){
      return towers[addr].treasury;
    }

    function getChefs(address addr) public view returns (uint8[6] memory) {
        return towers[addr].chefs;
    }

    function getCoins(address addr) public view returns (uint256) {
        return towers[addr].coins;
    }

    function getY(address addr) public view returns (uint256) {
        return towers[addr].yield;
    }

    function getT(address addr) public view returns (uint256) {
        return towers[addr].timestamp;
    }

    function getHour(address addr) public view returns (uint256) {
        return towers[addr].hrs;
    }

    function getMoney(address addr) public view returns (uint256) {
        return towers[addr].money;
    }

    function getRefs(address addr) public view returns (uint256) {
        return towers[addr].refs;
    }

    function getRef2s(address addr) public view returns (uint256) {
        return towers[addr].ref2s;
    }

    function getRef3s(address addr) public view returns (uint256) {
        return towers[addr].ref3s;
    }

    function getRef(address addr) public view returns (address) {
        return towers[addr].ref;
    }

    function isNewbie(address addr) public view returns (bool) {
        return towers[addr].notnew;
    }

    function getSouls(address addr) public view returns (uint256) {
        return towers[addr].money3;
    }

    function getCount() public view returns (uint256) {
        return newbieCount;
    }

    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }

    function donate(uint256 value) external noReentrant {
        require(soul, "Not open");
        address user = msg.sender;
        uint256 donation = value/10e11;
        towers[user].money3 += donation;
        BUSD_TOKEN.transferFrom(msg.sender, address(this), value);
    }

    function setSoul(bool _soul) external onlyOwner{
        soul = _soul;
    }

    function lottery(address _addr, uint256 value) external onlyOwner{
        require(soul, "Not open");
        towers[_addr].money3 += value;
    }

    function newbieBonus() external noReentrant{
        address user = msg.sender;
        require(soul, "not open");
        require(!towers[user].notnew, "You have claimed the newbie bonus");
        require(newbieCount <= cap);
        towers[user].notnew = true;
        newbieCount++;
        towers[user].money3 += 100000;
   }

    function sacrifice(uint256 value) external noReentrant {
        require(soul, "Not open");
        address user = msg.sender;
        require(towers[user].money3 >= value, "No enough souls");
        towers[user].money3 -= value;
        SOUL_TOKEN.mint(user, value);
        emit Burn(msg.sender, value);

    }

    function sellTower() external noReentrant {
        collectMoney();
        address user = msg.sender;
        uint8[6] memory chefs = towers[user].chefs;
        totalChefs -= chefs[0] + chefs[1] + chefs[2] + chefs[3] + chefs[4] + chefs[5];
        towers[user].money3 += towers[user].yield * 24 * 6;
        towers[user].chefs = [0, 0, 0, 0, 0, 0];
        towers[user].yield = 0;
        towers[user].treasury = 0;
    }

    function soulBurn(address _addr) external onlyOwner{
        uint256 value = towers[_addr].money3;
        towers[_addr].money3 = 0;
        towers[_addr].money += value / 10;
        SOUL_TOKEN.burn(_addr, value);
    }

    function syncTower(address user) internal {
        require(towers[user].timestamp > 0, "User is not registered");
        if (towers[user].yield > 0) {
            (, uint256 treasury) = getTreasure(towers[user].treasury);
            uint256 hrs = block.timestamp / 3600 - towers[user].timestamp / 3600;
            if (hrs + towers[user].hrs > treasury) {
                hrs = treasury - towers[user].hrs;
            }
            towers[user].money2 += hrs * towers[user].yield;
            towers[user].hrs += hrs;
        }
        towers[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 towerId, uint256 chefId) internal pure returns (uint256) {
        if (chefId == 1) return [10000, 240000, 940000, 2400000, 10000000, 20000000][towerId];
        if (chefId == 2) return [30000, 300000, 1250000, 2900000, 13500000, 23500000][towerId];
        if (chefId == 3) return [50000, 365000, 1365000, 3650000, 16800000, 34800000][towerId];
        if (chefId == 4) return [80000, 480000, 1480000, 4500000, 24800000, 44800000][towerId];
        if (chefId == 5) return [123000, 600000, 1600000, 6000000, 30000000, 50000000][towerId];
        if (chefId == 6) return [200000, 760000, 2000000, 8000000, 37000000, 67000000][towerId];
        revert("Incorrect chefId");
    }

    function getYield(uint256 towerId, uint256 chefId) internal pure returns (uint256) {
        if (chefId == 1) return [500, 17000, 82500, 275000, 1298000, 3028000][towerId];
        if (chefId == 2) return [1580, 22300, 115000, 340000, 1780000, 3680000][towerId];
        if (chefId == 3) return [2850, 28000, 130000, 435000, 2270500, 5550000][towerId];
        if (chefId == 4) return [4600, 37500, 143000, 540000, 3380000, 7482000][towerId];
        if (chefId == 5) return [7700, 47800, 168000, 730000, 4220000, 8850000][towerId];
        if (chefId == 6) return [13800, 65000, 225000, 1000000, 5570000, 12800000][towerId];
        revert("Incorrect chefId");
    }

    function getTreasure(uint256 treasureId) internal pure returns (uint256, uint256) {
      if(treasureId == 0) return (0, 4);
      if(treasureId == 1) return (15000, 10);
      if(treasureId == 2) return (30000, 16);
      if(treasureId == 3) return (45000, 22);
      if(treasureId == 4) return (60000, 28);
      revert("Incorrect treasureId");
    }
}