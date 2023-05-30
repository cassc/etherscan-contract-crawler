// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ContextMixin.sol";
import "./Base64.sol";

contract CryptoFootball2021 is ERC721Enumerable, ContextMixin, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public daoAddress;
    address payable public potAddress;

    /// Specifically whitelist an OpenSea proxy registry address.
    address public proxyRegistryAddress;

    struct PlayerMeta {
        uint256 tier;
        uint256 score;
    }

    mapping(string => PlayerMeta) private playerMeta;

    uint256 public teamPrice;
    uint256 public bulkBuyLimit;
    uint256 public maxSupply;
    uint256 public reserveTeams;

    string[] private quarterbacks = [
    "Kyler Murray", "Josh Allen", "Patrick Mahomes II", "Lamar Jackson", "Dak Prescott", "Tom Brady", "Justin Herbert", "Jalen Hurts", "Matthew Stafford", "Aaron Rodgers", "Joe Burrow", "Sam Darnold", "Kirk Cousins", "Derek Carr", "Ryan Tannehill", "Trey Lance", "Trevor Lawrence", "Daniel Jones", "Matt Ryan", "Justin Fields", "Baker Mayfield", "Russell Wilson", "Jameis Winston", "Teddy Bridgewater", "Carson Wentz", "Taylor Heinicke", "Mac Jones", "Ben Roethlisberger", "Tua Tagovailoa", "Jared Goff", "Zach Wilson", "Jimmy Garoppolo", "Geno Smith", "Davis Mills", "Tyrod Taylor"
    ];

    string[] private runningBacks = [
    "Derrick Henry", "Christian McCaffrey", "Alvin Kamara", "Aaron Jones", "Austin Ekeler", "Ezekiel Elliott", "Nick Chubb", "Dalvin Cook", "Najee Harris", "Jonathan Taylor", "Antonio Gibson", "Joe Mixon", "Saquon Barkley", "D'Andre Swift", "Darrell Henderson Jr.", "James Robinson", "Kareem Hunt", "Chris Carson", "Chase Edmonds", "Josh Jacobs", "Damien Harris", "Javonte Williams", "Cordarrelle Patterson", "Leonard Fournette", "Miles Sanders", "Clyde Edwards-Helaire", "Melvin Gordon III", "Tony Pollard", "Elijah Mitchell", "David Montgomery", "Zack Moss", "Myles Gaskin", "Mike Davis", "Jamaal Williams", "Damien Williams", "James Conner", "Latavius Murray", "Alexander Mattison", "Michael Carter", "Trey Sermon", "Kenneth Gainwell", "AJ Dillon", "Chuba Hubbard", "Nyheim Hines", "Darrel Williams", "Devin Singletary", "J.D. McKissic", "Sony Michel", "Ronald Jones II", "Alex Collins", "Devontae Booker", "Samaje Perine", "Ty'Son Williams", "Giovani Bernard", "David Johnson", "Mark Ingram II"
    ];

    string[] private tightEnds = [
    "Travis Kelce", "Darren Waller", "Kyle Pitts", "T.J. Hockenson", "Mark Andrews", "Dawson Knox", "George Kittle", "Tyler Higbee", "Dalton Schultz", "Noah Fant", "Mike Gesicki", "Rob Gronkowski", "Hunter Henry", "Jared Cook", "Dallas Goedert", "Robert Tonyan", "Logan Thomas", "Jonnu Smith", "Zach Ertz", "Evan Engram", "Gerald Everett", "Austin Hooper", "Tyler Conklin", "Cole Kmet", "Dan Arnold", "Pat Freiermuth", "Hayden Hurst", "Adam Trautman", "Blake Jarwin", "Anthony Firkser", "Jack Doyle", "David Njoku", "Mo Alie-Cox", "C.J. Uzomah", "Donald Parham Jr.", "Tommy Tremble", "Eric Ebron", "Cameron Brate", "O.J. Howard", "Juwan Johnson", "Ricky Seals-Jones", "Ian Thomas", "Will Dissly", "Jimmy Graham", "Kyle Rudolph"
    ];

    string[] private wideReceivers = [
    "Davante Adams", "Tyreek Hill", "Stefon Diggs", "Cooper Kupp", "Justin Jefferson", "DeAndre Hopkins", "D.J. Moore", "Mike Williams", "CeeDee Lamb", "D.K. Metcalf", "Terry McLaurin", "Ja'Marr Chase", "Deebo Samuel", "Keenan Allen", "Calvin Ridley", "Amari Cooper", "Chris Godwin", "Mike Evans", "Diontae Johnson", "A.J. Brown", "Tyler Lockett", "Antonio Brown", "Robert Woods", "Adam Thielen", "Tee Higgins", "Marquise Brown", "Courtland Sutton", "Chase Claypool", "DeVonta Smith", "Brandin Cooks", "Julio Jones", "Michael Pittman Jr.", "Tyler Boyd", "Allen Robinson II", "Odell Beckham Jr.", "Marvin Jones Jr.", "Corey Davis", "Kadarius Toney", "Jaylen Waddle", "Emmanuel Sanders", "Laviska Shenault Jr.", "Jakobi Meyers", "Rondale Moore", "Sterling Shepard", "Jerry Jeudy", "Michael Thomas", "Henry Ruggs III", "Darnell Mooney", "Kenny Golladay", "Tim Patrick", "Christian Kirk", "Cole Beasley", "Robby Anderson", "Hunter Renfrow", "DeVante Parker", "Brandon Aiyuk", "Will Fuller V", "Michael Gallup", "A.J. Green", "Jarvis Landry", "Mecole Hardman", "Rashod Bateman", "Curtis Samuel", "Van Jefferson", "Marquez Callaway", "Terrace Marshall Jr.", "Zach Pascal", "Nelson Agholor", "Bryan Edwards", "K.J. Osborn", "Jalen Reagor", "Elijah Moore", "Darius Slayton", "Gabriel Davis", "Jamison Crowder", "DeSean Jackson", "Marquez Valdes-Scantling", "James Washington", "Sammy Watkins", "Randall Cobb", "Kalif Raymond", "Anthony Miller", "Kendrick Bourne", "Tyrell Williams", "Amon-Ra St. Brown", "Quintez Cephus", "Allen Lazard", "Parris Campbell", "Quez Watkins", "Donovan Peoples-Jones", "T.Y. Hilton", "Deonte Harris", "Dyami Brown", "Russell Gage", "Tre'Quan Smith", "Josh Reynolds", "N'Keal Harry", "John Ross", "Rashard Higgins", "Freddie Swain", "Byron Pringle", "Chris Moore", "Josh Gordon", "D.J. Chark Jr."
    ];

    uint256 private flexLength = wideReceivers.length + runningBacks.length + tightEnds.length;

    constructor(address payable _daoAddress, address payable _potAddress, address _proxyRegistryAddress, uint256 _teamPrice, uint256 _bulkBuyLimit, uint256 _maxSupply, uint256 _reserveTeams) ERC721("CryptoFootball2021", "FOOT") {
        daoAddress = _daoAddress;
        potAddress = _potAddress;
        proxyRegistryAddress = _proxyRegistryAddress;
        teamPrice = _teamPrice;
        bulkBuyLimit = _bulkBuyLimit;
        maxSupply = _maxSupply;
        reserveTeams = _reserveTeams;

        playerMeta["Kyler Murray"] = PlayerMeta(1, 246);
        playerMeta["Josh Allen"] = PlayerMeta(1, 241);
        playerMeta["Patrick Mahomes II"] = PlayerMeta(1, 233);
        playerMeta["Lamar Jackson"] = PlayerMeta(1, 229);
        playerMeta["Dak Prescott"] = PlayerMeta(1, 222);
        playerMeta["Tom Brady"] = PlayerMeta(1, 218);
        playerMeta["Justin Herbert"] = PlayerMeta(2, 213);
        playerMeta["Jalen Hurts"] = PlayerMeta(2, 212);
        playerMeta["Matthew Stafford"] = PlayerMeta(2, 210);
        playerMeta["Aaron Rodgers"] = PlayerMeta(2, 200);
        playerMeta["Joe Burrow"] = PlayerMeta(2, 196);
        playerMeta["Sam Darnold"] = PlayerMeta(2, 187);
        playerMeta["Kirk Cousins"] = PlayerMeta(2, 185);
        playerMeta["Derek Carr"] = PlayerMeta(2, 183);
        playerMeta["Ryan Tannehill"] = PlayerMeta(3, 180);
        playerMeta["Trey Lance"] = PlayerMeta(3, 178);
        playerMeta["Trevor Lawrence"] = PlayerMeta(3, 178);
        playerMeta["Daniel Jones"] = PlayerMeta(3, 176);
        playerMeta["Matt Ryan"] = PlayerMeta(3, 174);
        playerMeta["Justin Fields"] = PlayerMeta(3, 174);
        playerMeta["Baker Mayfield"] = PlayerMeta(3, 174);
        playerMeta["Russell Wilson"] = PlayerMeta(3, 173);
        playerMeta["Jameis Winston"] = PlayerMeta(3, 168);
        playerMeta["Teddy Bridgewater"] = PlayerMeta(3, 168);
        playerMeta["Carson Wentz"] = PlayerMeta(3, 166);
        playerMeta["Taylor Heinicke"] = PlayerMeta(3, 165);
        playerMeta["Mac Jones"] = PlayerMeta(3, 162);
        playerMeta["Ben Roethlisberger"] = PlayerMeta(3, 161);
        playerMeta["Tua Tagovailoa"] = PlayerMeta(3, 160);
        playerMeta["Jared Goff"] = PlayerMeta(3, 158);
        playerMeta["Zach Wilson"] = PlayerMeta(3, 151);
        playerMeta["Jimmy Garoppolo"] = PlayerMeta(3, 142);
        playerMeta["Geno Smith"] = PlayerMeta(3, 52);
        playerMeta["Davis Mills"] = PlayerMeta(3, 47);
        playerMeta["Tyrod Taylor"] = PlayerMeta(3, 42);
        playerMeta["Derrick Henry"] = PlayerMeta(1, 216);
        playerMeta["Christian McCaffrey"] = PlayerMeta(1, 192);
        playerMeta["Alvin Kamara"] = PlayerMeta(1, 180);
        playerMeta["Aaron Jones"] = PlayerMeta(1, 176);
        playerMeta["Austin Ekeler"] = PlayerMeta(1, 158);
        playerMeta["Ezekiel Elliott"] = PlayerMeta(1, 157);
        playerMeta["Nick Chubb"] = PlayerMeta(1, 156);
        playerMeta["Dalvin Cook"] = PlayerMeta(1, 156);
        playerMeta["Najee Harris"] = PlayerMeta(2, 152);
        playerMeta["Jonathan Taylor"] = PlayerMeta(2, 151);
        playerMeta["Antonio Gibson"] = PlayerMeta(2, 149);
        playerMeta["Joe Mixon"] = PlayerMeta(2, 148);
        playerMeta["Saquon Barkley"] = PlayerMeta(2, 143);
        playerMeta["D'Andre Swift"] = PlayerMeta(2, 136);
        playerMeta["Darrell Henderson Jr."] = PlayerMeta(2, 134);
        playerMeta["James Robinson"] = PlayerMeta(2, 133);
        playerMeta["Kareem Hunt"] = PlayerMeta(2, 132);
        playerMeta["Chris Carson"] = PlayerMeta(2, 130);
        playerMeta["Chase Edmonds"] = PlayerMeta(2, 130);
        playerMeta["Josh Jacobs"] = PlayerMeta(2, 122);
        playerMeta["Damien Harris"] = PlayerMeta(2, 118);
        playerMeta["Javonte Williams"] = PlayerMeta(2, 115);
        playerMeta["Cordarrelle Patterson"] = PlayerMeta(2, 114);
        playerMeta["Leonard Fournette"] = PlayerMeta(3, 110);
        playerMeta["Miles Sanders"] = PlayerMeta(3, 108);
        playerMeta["Clyde Edwards-Helaire"] = PlayerMeta(3, 104);
        playerMeta["Melvin Gordon III"] = PlayerMeta(3, 100);
        playerMeta["Tony Pollard"] = PlayerMeta(3, 97);
        playerMeta["Elijah Mitchell"] = PlayerMeta(3, 95);
        playerMeta["David Montgomery"] = PlayerMeta(3, 86);
        playerMeta["Zack Moss"] = PlayerMeta(3, 84);
        playerMeta["Myles Gaskin"] = PlayerMeta(3, 84);
        playerMeta["Mike Davis"] = PlayerMeta(3, 83);
        playerMeta["Jamaal Williams"] = PlayerMeta(3, 82);
        playerMeta["Damien Williams"] = PlayerMeta(3, 80);
        playerMeta["James Conner"] = PlayerMeta(3, 79);
        playerMeta["Latavius Murray"] = PlayerMeta(3, 79);
        playerMeta["Alexander Mattison"] = PlayerMeta(3, 78);
        playerMeta["Michael Carter"] = PlayerMeta(3, 75);
        playerMeta["Trey Sermon"] = PlayerMeta(3, 74);
        playerMeta["Kenneth Gainwell"] = PlayerMeta(3, 73);
        playerMeta["AJ Dillon"] = PlayerMeta(3, 73);
        playerMeta["Chuba Hubbard"] = PlayerMeta(3, 71);
        playerMeta["Nyheim Hines"] = PlayerMeta(3, 71);
        playerMeta["Darrel Williams"] = PlayerMeta(3, 71);
        playerMeta["Devin Singletary"] = PlayerMeta(3, 70);
        playerMeta["J.D. McKissic"] = PlayerMeta(3, 66);
        playerMeta["Sony Michel"] = PlayerMeta(3, 63);
        playerMeta["Ronald Jones II"] = PlayerMeta(3, 62);
        playerMeta["Alex Collins"] = PlayerMeta(3, 59);
        playerMeta["Devontae Booker"] = PlayerMeta(3, 58);
        playerMeta["Samaje Perine"] = PlayerMeta(3, 55);
        playerMeta["Ty'Son Williams"] = PlayerMeta(3, 54);
        playerMeta["Giovani Bernard"] = PlayerMeta(3, 53);
        playerMeta["David Johnson"] = PlayerMeta(3, 52);
        playerMeta["Mark Ingram II"] = PlayerMeta(3, 50);
        playerMeta["Davante Adams"] = PlayerMeta(1, 177);
        playerMeta["Tyreek Hill"] = PlayerMeta(1, 174);
        playerMeta["Stefon Diggs"] = PlayerMeta(1, 162);
        playerMeta["Cooper Kupp"] = PlayerMeta(1, 157);
        playerMeta["Justin Jefferson"] = PlayerMeta(1, 154);
        playerMeta["DeAndre Hopkins"] = PlayerMeta(1, 145);
        playerMeta["D.J. Moore"] = PlayerMeta(1, 145);
        playerMeta["Mike Williams"] = PlayerMeta(1, 142);
        playerMeta["CeeDee Lamb"] = PlayerMeta(1, 140);
        playerMeta["D.K. Metcalf"] = PlayerMeta(1, 133);
        playerMeta["Terry McLaurin"] = PlayerMeta(1, 130);
        playerMeta["Ja'Marr Chase"] = PlayerMeta(1, 129);
        playerMeta["Deebo Samuel"] = PlayerMeta(1, 129);
        playerMeta["Keenan Allen"] = PlayerMeta(1, 128);
        playerMeta["Calvin Ridley"] = PlayerMeta(1, 127);
        playerMeta["Amari Cooper"] = PlayerMeta(1, 125);
        playerMeta["Chris Godwin"] = PlayerMeta(1, 124);
        playerMeta["Mike Evans"] = PlayerMeta(1, 123);
        playerMeta["Diontae Johnson"] = PlayerMeta(1, 121);
        playerMeta["A.J. Brown"] = PlayerMeta(1, 120);
        playerMeta["Tyler Lockett"] = PlayerMeta(2, 119);
        playerMeta["Antonio Brown"] = PlayerMeta(2, 115);
        playerMeta["Robert Woods"] = PlayerMeta(2, 115);
        playerMeta["Adam Thielen"] = PlayerMeta(2, 112);
        playerMeta["Tee Higgins"] = PlayerMeta(2, 112);
        playerMeta["Marquise Brown"] = PlayerMeta(2, 109);
        playerMeta["Courtland Sutton"] = PlayerMeta(2, 109);
        playerMeta["Chase Claypool"] = PlayerMeta(2, 108);
        playerMeta["DeVonta Smith"] = PlayerMeta(2, 107);
        playerMeta["Brandin Cooks"] = PlayerMeta(2, 107);
        playerMeta["Julio Jones"] = PlayerMeta(2, 107);
        playerMeta["Michael Pittman Jr."] = PlayerMeta(2, 107);
        playerMeta["Tyler Boyd"] = PlayerMeta(2, 105);
        playerMeta["Allen Robinson II"] = PlayerMeta(2, 104);
        playerMeta["Odell Beckham Jr."] = PlayerMeta(2, 102);
        playerMeta["Marvin Jones Jr."] = PlayerMeta(2, 101);
        playerMeta["Corey Davis"] = PlayerMeta(2, 100);
        playerMeta["Kadarius Toney"] = PlayerMeta(2, 99);
        playerMeta["Jaylen Waddle"] = PlayerMeta(2, 98);
        playerMeta["Emmanuel Sanders"] = PlayerMeta(2, 97);
        playerMeta["Laviska Shenault Jr."] = PlayerMeta(2, 96);
        playerMeta["Jakobi Meyers"] = PlayerMeta(2, 95);
        playerMeta["Rondale Moore"] = PlayerMeta(2, 94);
        playerMeta["Sterling Shepard"] = PlayerMeta(2, 93);
        playerMeta["Jerry Jeudy"] = PlayerMeta(2, 93);
        playerMeta["Michael Thomas"] = PlayerMeta(2, 92);
        playerMeta["Henry Ruggs III"] = PlayerMeta(2, 91);
        playerMeta["Darnell Mooney"] = PlayerMeta(2, 90);
        playerMeta["Kenny Golladay"] = PlayerMeta(2, 87);
        playerMeta["Tim Patrick"] = PlayerMeta(3, 86);
        playerMeta["Christian Kirk"] = PlayerMeta(3, 84);
        playerMeta["Cole Beasley"] = PlayerMeta(3, 84);
        playerMeta["Robby Anderson"] = PlayerMeta(3, 83);
        playerMeta["Hunter Renfrow"] = PlayerMeta(3, 82);
        playerMeta["DeVante Parker"] = PlayerMeta(3, 82);
        playerMeta["Brandon Aiyuk"] = PlayerMeta(3, 81);
        playerMeta["Will Fuller V"] = PlayerMeta(3, 80);
        playerMeta["Michael Gallup"] = PlayerMeta(3, 78);
        playerMeta["A.J. Green"] = PlayerMeta(3, 77);
        playerMeta["Jarvis Landry"] = PlayerMeta(3, 76);
        playerMeta["Mecole Hardman"] = PlayerMeta(3, 76);
        playerMeta["Rashod Bateman"] = PlayerMeta(3, 75);
        playerMeta["Curtis Samuel"] = PlayerMeta(3, 74);
        playerMeta["Van Jefferson"] = PlayerMeta(3, 71);
        playerMeta["Marquez Callaway"] = PlayerMeta(3, 71);
        playerMeta["Terrace Marshall Jr."] = PlayerMeta(3, 71);
        playerMeta["Zach Pascal"] = PlayerMeta(3, 71);
        playerMeta["Nelson Agholor"] = PlayerMeta(3, 71);
        playerMeta["Bryan Edwards"] = PlayerMeta(3, 69);
        playerMeta["K.J. Osborn"] = PlayerMeta(3, 69);
        playerMeta["Jalen Reagor"] = PlayerMeta(3, 68);
        playerMeta["Elijah Moore"] = PlayerMeta(3, 66);
        playerMeta["Darius Slayton"] = PlayerMeta(3, 64);
        playerMeta["Gabriel Davis"] = PlayerMeta(3, 64);
        playerMeta["Jamison Crowder"] = PlayerMeta(3, 62);
        playerMeta["DeSean Jackson"] = PlayerMeta(3, 61);
        playerMeta["Marquez Valdes-Scantling"] = PlayerMeta(3, 61);
        playerMeta["James Washington"] = PlayerMeta(3, 60);
        playerMeta["Sammy Watkins"] = PlayerMeta(3, 60);
        playerMeta["Randall Cobb"] = PlayerMeta(3, 59);
        playerMeta["Kalif Raymond"] = PlayerMeta(3, 58);
        playerMeta["Anthony Miller"] = PlayerMeta(3, 58);
        playerMeta["Kendrick Bourne"] = PlayerMeta(3, 57);
        playerMeta["Tyrell Williams"] = PlayerMeta(3, 57);
        playerMeta["Amon-Ra St. Brown"] = PlayerMeta(3, 55);
        playerMeta["Quintez Cephus"] = PlayerMeta(3, 54);
        playerMeta["Allen Lazard"] = PlayerMeta(3, 53);
        playerMeta["Parris Campbell"] = PlayerMeta(3, 52);
        playerMeta["Quez Watkins"] = PlayerMeta(3, 50);
        playerMeta["Donovan Peoples-Jones"] = PlayerMeta(3, 50);
        playerMeta["T.Y. Hilton"] = PlayerMeta(3, 49);
        playerMeta["Deonte Harris"] = PlayerMeta(3, 49);
        playerMeta["Dyami Brown"] = PlayerMeta(3, 49);
        playerMeta["Russell Gage"] = PlayerMeta(3, 47);
        playerMeta["Tre'Quan Smith"] = PlayerMeta(3, 46);
        playerMeta["Josh Reynolds"] = PlayerMeta(3, 46);
        playerMeta["N'Keal Harry"] = PlayerMeta(3, 46);
        playerMeta["John Ross"] = PlayerMeta(3, 44);
        playerMeta["Rashard Higgins"] = PlayerMeta(3, 42);
        playerMeta["Freddie Swain"] = PlayerMeta(3, 42);
        playerMeta["Byron Pringle"] = PlayerMeta(3, 41);
        playerMeta["Chris Moore"] = PlayerMeta(3, 41);
        playerMeta["Josh Gordon"] = PlayerMeta(3, 41);
        playerMeta["D.J. Chark Jr."] = PlayerMeta(3, 40);
        playerMeta["Travis Kelce"] = PlayerMeta(1, 160);
        playerMeta["Darren Waller"] = PlayerMeta(1, 130);
        playerMeta["Kyle Pitts"] = PlayerMeta(1, 128);
        playerMeta["T.J. Hockenson"] = PlayerMeta(2, 107);
        playerMeta["Mark Andrews"] = PlayerMeta(2, 97);
        playerMeta["Dawson Knox"] = PlayerMeta(2, 95);
        playerMeta["George Kittle"] = PlayerMeta(2, 81);
        playerMeta["Tyler Higbee"] = PlayerMeta(2, 81);
        playerMeta["Dalton Schultz"] = PlayerMeta(2, 80);
        playerMeta["Noah Fant"] = PlayerMeta(2, 78);
        playerMeta["Mike Gesicki"] = PlayerMeta(2, 78);
        playerMeta["Rob Gronkowski"] = PlayerMeta(2, 74);
        playerMeta["Hunter Henry"] = PlayerMeta(2, 72);
        playerMeta["Jared Cook"] = PlayerMeta(2, 69);
        playerMeta["Dallas Goedert"] = PlayerMeta(2, 67);
        playerMeta["Robert Tonyan"] = PlayerMeta(2, 66);
        playerMeta["Logan Thomas"] = PlayerMeta(2, 65);
        playerMeta["Jonnu Smith"] = PlayerMeta(2, 65);
        playerMeta["Zach Ertz"] = PlayerMeta(2, 63);
        playerMeta["Evan Engram"] = PlayerMeta(2, 63);
        playerMeta["Gerald Everett"] = PlayerMeta(3, 61);
        playerMeta["Austin Hooper"] = PlayerMeta(3, 60);
        playerMeta["Tyler Conklin"] = PlayerMeta(3, 58);
        playerMeta["Cole Kmet"] = PlayerMeta(3, 57);
        playerMeta["Dan Arnold"] = PlayerMeta(3, 54);
        playerMeta["Pat Freiermuth"] = PlayerMeta(3, 52);
        playerMeta["Hayden Hurst"] = PlayerMeta(3, 51);
        playerMeta["Adam Trautman"] = PlayerMeta(3, 49);
        playerMeta["Blake Jarwin"] = PlayerMeta(3, 46);
        playerMeta["Anthony Firkser"] = PlayerMeta(3, 46);
        playerMeta["Jack Doyle"] = PlayerMeta(3, 43);
        playerMeta["David Njoku"] = PlayerMeta(3, 41);
        playerMeta["Mo Alie-Cox"] = PlayerMeta(3, 41);
        playerMeta["C.J. Uzomah"] = PlayerMeta(3, 40);
        playerMeta["Donald Parham Jr."] = PlayerMeta(3, 39);
        playerMeta["Tommy Tremble"] = PlayerMeta(3, 38);
        playerMeta["Eric Ebron"] = PlayerMeta(3, 38);
        playerMeta["Cameron Brate"] = PlayerMeta(3, 37);
        playerMeta["O.J. Howard"] = PlayerMeta(3, 36);
        playerMeta["Juwan Johnson"] = PlayerMeta(3, 35);
        playerMeta["Ricky Seals-Jones"] = PlayerMeta(3, 35);
        playerMeta["Ian Thomas"] = PlayerMeta(3, 34);
        playerMeta["Will Dissly"] = PlayerMeta(3, 32);
        playerMeta["Jimmy Graham"] = PlayerMeta(3, 32);
        playerMeta["Kyle Rudolph"] = PlayerMeta(3, 31);

        _mintReserveTeams();
    }

    // Mint reserve teams with tokenIds after the publicly available tokenIds
    function _mintReserveTeams() internal {
        for (uint256 i = maxSupply + 1; i < maxSupply + reserveTeams + 1; i++) {
            _safeMint(potAddress, i);
        }
    }

    function mintTeam(uint256 numberOfTeams) external payable nonReentrant {
        require(numberOfTeams <= bulkBuyLimit, "Cannot buy more than the preset limit at a time");
        require((_tokenIds.current() + numberOfTeams) <= maxSupply, "Sold out!");

        uint256 purchasePrice = teamPrice * numberOfTeams;
        require(purchasePrice <= msg.value, "Not enough funds sent for this purchase");

        uint256 daoAmount = purchasePrice / 5;
        uint256 potAmount = daoAmount * 4;

        (bool transferStatus, ) = daoAddress.call{value: daoAmount}("");
        require(transferStatus, "Unable to send dao amount, recipient may have reverted");

        (transferStatus, ) = potAddress.call{value: potAmount}("");
        require(transferStatus, "Unable to send pot amount, recipient may have reverted");

        uint256 excessAmount = msg.value - purchasePrice;
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        for (uint256 i = 0; i < numberOfTeams; i++) {
            _tokenIds.increment();
            _safeMint(_msgSender(), _tokenIds.current());
        }
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getQuarterback(uint256 tokenId) internal view returns (uint256) {
        return pluckPlayer(tokenId, "QUARTERBACK", quarterbacks.length);
    }

    function getWideReceiver(uint256 tokenId, uint256 position) internal view returns (uint256) {
        return pluckPlayer(tokenId, string(abi.encodePacked("WIDERECEIVER", toString(position))), wideReceivers.length);
    }

    function getRunningBack(uint256 tokenId, uint256 position) internal view returns (uint256) {
        return pluckPlayer(tokenId, string(abi.encodePacked("RUNNINGBACK", toString(position))), runningBacks.length);
    }

    function getTightEnd(uint256 tokenId, uint256 position) internal view returns (uint256) {
        return pluckPlayer(tokenId, string(abi.encodePacked("TIGHTEND", toString(position))), tightEnds.length);
    }

    function getFlex(uint256 tokenId, uint256 position) internal view returns (uint256) {
        return pluckPlayer(tokenId, string(abi.encodePacked("FLEX", toString(position))), flexLength);
    }

    function pluckPlayer(uint256 tokenId, string memory keyPrefix, uint256 numPlayers) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        return rand % numPlayers;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory token = toString(tokenId);

        uint256[8] memory players;
        players[0] = getQuarterback(tokenId);
        players[1] = getWideReceiver(tokenId, 0);
        players[2] = getWideReceiver(tokenId, 1);
        for (uint256 i = 2; players[2] == players[1]; i++) {
            players[2] = getWideReceiver(tokenId, i);
        }
        players[3] = getRunningBack(tokenId, 0);
        players[4] = getRunningBack(tokenId, 1);
        for (uint256 i = 2; players[4] == players[3]; i++) {
            players[4] = getRunningBack(tokenId, i);
        }
        players[5] = getTightEnd(tokenId, 0);

        // 2nd WR needs to not be the same as the first
        // 2nd RB needs to not be the same as the first
        // first flex needs to not be the same as 2 WRs, 2 RBs, 1 TE
        // second flex needs to not be the same as the prior

        uint256 score = 0;
        uint256[3] memory tiers; // = [uint256(0), uint256(0), uint256(0)];
        string[13] memory attParts;
        string[19] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: monospace; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base" font-size="larger" font-weight="bold">';
        parts[1] = string(abi.encodePacked('Team #', token));
        parts[2] = '</text><text x="10" y="40" class="base">';
        parts[3] = quarterbacks[players[0]];
        score = score + playerMeta[parts[3]].score;
        tiers[playerMeta[parts[3]].tier - 1] = tiers[playerMeta[parts[3]].tier - 1] + 1;
        attParts[4] = string(abi.encodePacked('{"trait_type": "QB", "value": "', parts[3], '"}, '));

        parts[4] = '</text><text x="10" y="60" class="base">';
        parts[5] = wideReceivers[players[1]];
        score = score + playerMeta[parts[5]].score;
        tiers[playerMeta[parts[5]].tier - 1] = tiers[playerMeta[parts[5]].tier - 1] + 1;
        attParts[5] = string(abi.encodePacked('{"trait_type": "WR", "value": "', parts[5], '"}, '));

        parts[6] = '</text><text x="10" y="80" class="base">';
        parts[7] = wideReceivers[players[2]];
        score = score + playerMeta[parts[7]].score;
        tiers[playerMeta[parts[7]].tier - 1] = tiers[playerMeta[parts[7]].tier - 1] + 1;
        attParts[6] = string(abi.encodePacked('{"trait_type": "WR", "value": "', parts[7], '"}, '));

        parts[8] = '</text><text x="10" y="100" class="base">';
        parts[9] = runningBacks[players[3]];
        score = score + playerMeta[parts[9]].score;
        tiers[playerMeta[parts[9]].tier - 1] = tiers[playerMeta[parts[9]].tier - 1] + 1;
        attParts[7] = string(abi.encodePacked('{"trait_type": "RB", "value": "', parts[9], '"}, '));

        parts[10] = '</text><text x="10" y="120" class="base">';
        parts[11] = runningBacks[players[4]];
        score = score + playerMeta[parts[11]].score;
        tiers[playerMeta[parts[11]].tier - 1] = tiers[playerMeta[parts[11]].tier - 1] + 1;
        attParts[8] = string(abi.encodePacked('{"trait_type": "RB", "value": "', parts[11], '"}, '));

        parts[12] = '</text><text x="10" y="140" class="base">';
        parts[13] = tightEnds[players[5]];
        score = score + playerMeta[parts[13]].score;
        tiers[playerMeta[parts[13]].tier - 1] = tiers[playerMeta[parts[13]].tier - 1] + 1;
        attParts[9] = string(abi.encodePacked('{"trait_type": "TE", "value": "', parts[13], '"}, '));
        parts[14] = '</text><text x="10" y="160" class="base">';

        uint256 flex1 = getFlex(tokenId, 0);
        string memory traitType1;
        if (0 <= flex1 && flex1 < wideReceivers.length) {
            traitType1 = "WR";
            for (uint256 i = 2; flex1 == players[1] || flex1 == players[2]; i++) {
                flex1 = getWideReceiver(tokenId, i);
            }
            parts[15] = wideReceivers[flex1];
        } else if (wideReceivers.length <= flex1 && flex1 < wideReceivers.length + runningBacks.length) {
            traitType1 = "RB";
            flex1 = flex1 - wideReceivers.length;
            for (uint256 i = 2; flex1 == players[3] || flex1 == players[4]; i++) {
                flex1 = getRunningBack(tokenId, i);
            }
            parts[15] = runningBacks[flex1];
        } else {
            traitType1 = "TE";
            flex1 = flex1 - (wideReceivers.length + runningBacks.length);
            for (uint256 i = 2; flex1 == players[5]; i++) {
                flex1 = getTightEnd(tokenId, i);
            }
            parts[15] = tightEnds[flex1];
        }
        score = score + playerMeta[parts[15]].score;
        tiers[playerMeta[parts[15]].tier - 1] = tiers[playerMeta[parts[15]].tier - 1] + 1;
        attParts[10] = string(abi.encodePacked('{"trait_type": "', traitType1, '", "value": "', parts[15], '"}, '));

        parts[16] = '</text><text x="10" y="180" class="base">';
        uint256 flex2 = getFlex(tokenId, 0);
        string memory traitType2;
        if (0 <= flex2 && flex2 < wideReceivers.length) {
            traitType2 = "WR";
            for (uint256 i = 2; flex2 == players[1] || flex2 == players[2] || flex2 == flex1; i++) {
                flex2 = getWideReceiver(tokenId, i);
            }
            parts[17] = wideReceivers[flex2];
        } else if (wideReceivers.length <= flex2 && flex2 < wideReceivers.length + runningBacks.length) {
            flex2 = flex2 - wideReceivers.length;
            traitType2 = "RB";
            for (uint256 i = 2; flex2 == players[3] || flex2 == players[4] || flex2 == flex1; i++) {
                flex2 = getRunningBack(tokenId, i);
            }
            parts[17] = runningBacks[flex2];
        } else {
            traitType2 = "TE";
            flex2 = flex2 - (wideReceivers.length + runningBacks.length);
            for (uint256 i = 2; flex2 == players[5] || flex2 == flex1; i++) {
                flex2 = getTightEnd(tokenId, i);
            }
            parts[17] = tightEnds[flex2];
        }
        score = score + playerMeta[parts[17]].score;
        tiers[playerMeta[parts[17]].tier - 1] = tiers[playerMeta[parts[17]].tier - 1] + 1;
        attParts[11] = string(abi.encodePacked('{"trait_type": "', traitType2, '", "value": "', parts[17], '"}, '));
        parts[18] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1],parts[2], parts[3], parts[4]));
        output = string(abi.encodePacked(output, parts[5], parts[6], parts[7], parts[8], parts[9]));
        output = string(abi.encodePacked(output, parts[10], parts[11], parts[12], parts[13], parts[14]));
        output = string(abi.encodePacked(output, parts[15], parts[16], parts[17], parts[18]));

        // We are disregarding Draft Grade for this release
        attParts[0] = string(abi.encodePacked('{"display_type": "boost_percentage", "trait_type": "Draft Grade: B", "value": ', toString(players[1] * 7 % 101), '}, '));
        attParts[12] = string(abi.encodePacked('{"trait_type": "score", "value": ', toString(score), '}'));

        attParts[1] = string(abi.encodePacked('{"trait_type": "T1", "value": ', toString(tiers[0]), '}, '));
        attParts[2] = string(abi.encodePacked('{"trait_type": "T2", "value": ', toString(tiers[1]), '}, '));
        attParts[3] = string(abi.encodePacked('{"trait_type": "T3", "value": ', toString(tiers[2]), '}, '));

        string memory attributes = string(abi.encodePacked(attParts[1], attParts[2], attParts[3], attParts[4]));
        attributes = string(abi.encodePacked(attributes, attParts[5], attParts[6], attParts[7], attParts[8], attParts[9]));
        attributes = string(abi.encodePacked(attributes, attParts[10], attParts[11], attParts[12]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Team #', token, '", "attributes": [', attributes, '], "description": "Fantasy Football meets NFTs. By minting a Team you get an NFT that will have a random collection of 1 QB, 3 RBs, 3 WRs and 1 TE. Every week the top 5 and bottom 5 scorers (no losers in this league!) will be airdropped a prize.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /**
     * Override isApprovedForAll to auto-approve OpenSea's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        // Otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     * https://docs.opensea.io/docs/polygon-basic-integration
     */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}