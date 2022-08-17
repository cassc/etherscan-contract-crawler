//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/* ze Golemz */
/* @author: donatell0.wtf */

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBB##########&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBBBBBBBBBBBBBBBBBBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBBBBBBBBBBBBBBBBBBBBBBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G?YB&BBBBBBBBBBBBBBBB###&BBBBBBBBBBB&@@@@@@@&&@@@@@@@@@@#B&@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&J?#G##BBBBBBBBBBB##@PJ##BBBBBBBBBBBB&@@@@@@#[email protected]@@@@@@[email protected]@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BB##G&7?#&BBBBBBBB#&5JBBB&BB######BBBBB#@@@@@@@[email protected]@@@@P~J&@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BBBB&&JJ#P&BBBBB#B5#J?P&&##P?!^5J75#[email protected]@@@@@@&[email protected]@@@@?7&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BBBBB###@Y#&B##@B??#B#&&BJ^:!JYBY! 7&[email protected]@@@@@@&[email protected]@@@@[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&&@@@@@@@@@@&BBBBBBB&G?~~!7!?G&####B#P.:Y&@@@@@@P~##[email protected]@@@@@@&[email protected]@@@&G&@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&&@@@@@@@@@@#BBBBBB&? ^5B#&B? 5&BBBB#5J#@@@@&##PG&#BB#@@@@@@@&GB&@@@#G&@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&&@@@@@@@@@@#[email protected]?#@@@@@@GB#BBBBB#B?JJ?!~^^[email protected]@@@@@@@@@@
@@@@@@@@@@@@@@&&@@@&&&&&&@&BBBBBBBBBB########BBBBBBBBB#BGGBY7?B!.................Y!.:::^[email protected]&@@@@@@@@@
@@@@@@@@@@@@@@&&&#BBBBBBB&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#G^^~P:..:::::::........5^::::!#BBB#&@@@@@@
@@@@@@@@@@@@@&&&BBBBBBBB&#BBBBB#&&&&&&&&&&&&&&&&&###BBBBB&Y^^:JJ...............:J#J^:::Y&BBBBBB#&&@@
@@@@@@@@@&@&@&&BBB&&&&##&BBBBB&@@@&&&&&&&&&&&&@@@@@@&&&&@&!^^^^J?Y7JJ????????77JJ!^:::~##BBBBBBBBBB#
@@@@@@&##&&&&&&BBB#BBB&&BBBB#@@&&&&&&&&&&&&&&&&&&&&&&&&&@5^^^^^::~J~^^^:::..^[email protected]
@@@&#BB&&&@&&&#BBBBBBB&#BBB&@&&&&&&&&&&&&&&&&&@@&&&@@@@&&!^^^^^:::.........~P7!YGG777!P&BBBBBBBBBBBB
&#BBB#&&&&&BBBBBBBBBBB&BBB&@@&&&&&&&@@&&&&&&&@B#@&&#BGPGP^^^^^^:::::.....7Y?~:7G?#!::^##BBBBBBBBBBBB
BBBB#&&&&[email protected]#&&@@@@@@5~#@@@@@@#.~&5YJYPB&7^^^^^^:::::....~P~::7#JY&~^:7&BBBBBBBBBBBBB
BBBB#&#BBBBBBBBBBBBBBB&&BBBBBB##&B#? !#B###B#P:~#GGB###5^~^^^^^:::::...:P!^^^!YJY?^^:5&BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBB#&&##BBBBBB#5JBBPGGGBB#B#BBBBBB#!~~^^^^^:::::...^[email protected]#BBBBBBBBBBBBB
BBBBBBBBBBB#BBBBBBBBBBBBBBB##&##BBBBBBBBBBBBBBBBBBB##&5~~~^^^^::::::..........:::^^^[email protected]#BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#&&#BBBBBBBBBBBBBB&&####!~~^^~~~~^^::.::..........::^^[email protected]#BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#&##BBBBBBBB#&&#BBB#5~~~JJ?777775Y??7777!J~7777?7^^~&&BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB####&###&##BBBBB&7~~5?     .JJ5~   . !BP~...:57^~#&BBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&7^!G.   .!Y!57 ..  ^PPJ     Y?^~#&BBBBBBBBBB#BB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##5??GJ!!7!..!!777!!J^^[email protected]
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#BBBBBBBBBBBBB##G#Y!~^^^^^^^^^^^^^^~!!?#B5PB#BBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB####BBBBBBBBBBBBB####BB#BBBBBBBBBBBBBBBBBB
BBBBBBBBBBBBBBBB&BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#BBBBBBBBBBBB
BBBBBBBBBBBBBBBB&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#@BBBBBBBBBBBB
BBBBBBBBBBBBBBBB&#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#&BBBBBBBBBBBB
BBBBBBBBBBBBBBBB#&BBBBBBBB&&BBBBBBBBBBBBBBBBBBB##&#BBBBBBBB#&&#[email protected]#BBBBBBBBBBB
BBBBBBBBBBBBBBBB&&BBBBBBBBB#BBBBBBBBBBBBBBB##&&##BBBBBBBBBBBB##&#BBBBBBBBBBBBBBBBBBBBB&@#BBBBBBBBBBB
BBBBBBBBBBBBBBBB&@#BBBBBBBBBBBBBBBBBBGG WE ARE ZE GOLEMZ GGBBBBBBB#BBBBBBBBBBBBBBBBBB&@&#BBBBBBBBB*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Golemz is ERC721A, Ownable{

    address golemzSafu; 

    uint256 private maxGolemz = 300; // WEAREZEGOLEMZ

    bool zeGolemzAreHere = false; // WAITINGFORGOLEMZ

    mapping (uint256 => uint256) zeCopper; // GIBZEECOPPPPPERRRRR

    bool canWwaaaraaAAAaawwrrraAA = false;
    mapping (uint256 => string) private wwaaaraaAAAaawwrrraAA;  //wwaaaraaAAAaawwrrraAA

    mapping (string => uint256) private golemzPerWwaaaraaAAAaawwrrraAA;

    string private basedURI;   
    
    mapping (uint256 => string) private tokenURIs;

    mapping (address => bool) private superGolemz;
    
    event golemzAreComing(address _recipient);
    event golemzAreHere(string _GMZ);
    event golemzWwaaaraaAAAaawwrrraAA(uint256 _golemId);    
    event golemzGotZeCopper(uint256 _golemId, uint256 _zeCopper);  

    constructor() ERC721A("ze Golemz","GMZ"){
        addSuperGolemz(msg.sender);   
    }
    
    modifier izSuperGolemz
    {
        require(superGolemz[msg.sender] == true, "This Golemz is not Super Golemz.");
        _;
    }

    modifier NOTFULLGOLEM {
         require(totalSupply() < maxGolemz, "ZE GOLEMZ ARE FULL!");
        _;
    }
    
    function gmGolemz() public NOTFULLGOLEM izSuperGolemz {  
        _mint(msg.sender, maxGolemz-zeGolemzNumber());    
        emit golemzAreComing(msg.sender); 
    }   

    function tokenURI(uint256 _golemzId) public view override returns (string memory) {
        return golemzURI(_golemzId); //hehehe
    }

    function golemzURI(uint256 _golemzId) public view returns (string memory) {
        require(_golemzId <= zeGolemzNumber(), "No Golemz here!");
        require(_golemzId > 0, "No Golemz here!");
        
        string memory base = getBasedURI();

        if (bytes(base).length == 0) {
            return "";
        }
        else{
            return string(abi.encodePacked(base, Strings.toString(_golemzId)));
        }
    }

    function setWwaaaraaAAAaawwrrraAA(uint256 _golemzId, string memory _wwaaaraaAAAaawwrrraAA) public
    {
        require(ownerOf(_golemzId) == msg.sender, "Not your Golemz!");
        require(canWwaaaraaAAAaawwrrraAA, "Can't wwaaaraaAAAaawwrrraAA yet!");

        wwaaaraaAAAaawwrrraAA[_golemzId] = _wwaaaraaAAAaawwrrraAA;

        emit golemzWwaaaraaAAAaawwrrraAA(_golemzId);
    }

    function getWwaaaraaAAAaawwrrraAA(uint256 _golemzId) public view returns (string memory)
    {
        return wwaaaraaAAAaawwrrraAA[_golemzId];
    }

    function setCanWwaaaraaAAAaawwrrraAA(bool _canWwaaaraaAAAaawwrrraAA) public izSuperGolemz
    {
        canWwaaaraaAAAaawwrrraAA = _canWwaaaraaAAAaawwrrraAA;
    }

    function _baseURI() internal view override returns (string memory) {
        return basedURI;
    }

    function welcomeZeGolemz(bool _aretheyhere) public izSuperGolemz {
        zeGolemzAreHere = _aretheyhere;
        
        if(zeGolemzAreHere)
            emit golemzAreHere("g(ole)m");
    }

    function getBasedURI() public view returns (string memory) {
        return basedURI;
    }

    function setBasedURI(string memory _uri) public izSuperGolemz {
        basedURI = _uri;
    }

    function updateGolemzSafu(address _golemzSafu) public izSuperGolemz {
        golemzSafu = _golemzSafu;
    }
   
    function totalGolemz() public view returns (uint256) {
        return totalSupply();
    }

    function zeGolemzNumber() public view returns(uint)
    {
        return _totalMinted();
    }

    function addSuperGolemz(address _superGolemz) public onlyOwner
    {
        superGolemz[_superGolemz] = true;
    }

    function removeSuperGolemz(address _superGolemz) public izSuperGolemz
    {
        superGolemz[_superGolemz] = false;
    }

    function weNeedMoreGolemz(uint256 _moreGolemz) public izSuperGolemz{
        maxGolemz = _moreGolemz;
    }

    function giveGolemzZeCopper(uint256 _golemzId, uint256 _zeCopper) public izSuperGolemz{
        zeCopper[_golemzId] = _zeCopper;

        emit golemzGotZeCopper(_golemzId, _zeCopper);
    }

    function getZeCopper(uint256 _golemzId) public view returns (uint256){
        return zeCopper[_golemzId];
    }

    function killAGolemz(uint256 _golemzId) public izSuperGolemz{
       _burn(_golemzId);
    }


}