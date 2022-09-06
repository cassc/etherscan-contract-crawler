// SPDX-License-Identifier: MIT
// ARTWORK LICENSE: CC0
// ahodler.world - Battle Royale
// Rules:
// 8818 HODLers will start with with a health status of 0
// If a grenade is thrown at a certain HODLer the health bar status decrements by a factor of -1 for each grenade
// If a shield is being used to protect a certain HODLer the health bar status increments by a factor of +1 for each shield
// If a HODLer reaches a health bar status of -1 that HODLer drops out of the game.
// 100% of the proceeds go to the prize pool and will be split across the 3 Winners
// 30% of that pool go towards the wallet that holds the last HODLer standing
// 30% will go towards the wallet that has bought most grenades
// 5% will go towards the wallet that makes the last kill
// The Battle Royale concludes automatially on Monday, 8. May 2023 12:00:00
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import './Hodler.sol';

contract HodlerBattleRoyale is ERC1155Supply, Ownable  {
    address public contractCreator;
    bool public battleRoyaleIsActive = false;
    bool public battleRoyaleConcluded = false;
    bool private locationSet = false;
    uint256 public deadLine = 1683547200;
    uint constant DOG_TAG = 1;
    uint constant MAX_SUPPLY = 8818;
    uint constant STRIKE_PRICE = 0.005 ether;

    address public battleField;
    mapping(address => uint) public walletHighscore;
    uint256 public currentHighscore = 0;
    address public lastHodlerStanding;
    address public mostGrenades;
    address public lastThrow;
    bool public payout = false;
    
    event ItemBought(
        address from,
        address currentHighscoreAddy,
        uint hodlerId,
        int256 amount
    );
    event HodlerDied(
        address from,
        uint hodlerId,
        bool isAlive
    );

    constructor(string memory uri) ERC1155(uri) {
        contractCreator = msg.sender;
    }

    function setBattleField(address _location) external {
        require(contractCreator == _msgSender(), "ACHTUNG: Only Contract Creator can call this function");
        require(!locationSet, "ACHTUNG: nobody can change this value anymore");
        battleField = _location;
        locationSet = true;
    }

    function setBrState(bool _bool) public {
        require(contractCreator == _msgSender(), "ACHTUNG: Only Contract Creator can call this function");
        require(!battleRoyaleIsActive, "ACHTUNG: nobody can change this value anymore");
        battleRoyaleIsActive = _bool;
    }

    function setHealthStatus(uint256 _tokenId, int256 _amount) public payable {
        interfaceAhodler hodler = interfaceAhodler(battleField);
        uint priceMod = 10;
        uint256 amount;
        require(!battleRoyaleConcluded, "ACHTUNG: Battle Royale has concluded");
        require(battleRoyaleIsActive, "ACHTUNG: Battle Royale must be active to start attacks/mints");
        require(_amount != 0, "ACHTUNG: No Shield or Grenade selected");
        require(totalSupply(DOG_TAG) < MAX_SUPPLY, "ACHTUNG: You can't kill the last hodler standing");
        _amount < 0 ? amount = uint256(_amount*-1) : amount = uint256(_amount); 
        if(amount>6){
            priceMod = 8;
            if(amount>12){
                priceMod = 7;
                if(amount>18){
                    priceMod = 6;
                    if(amount>24){priceMod = 5;}
                }  
            }
        }
        require((STRIKE_PRICE / 10 * priceMod * amount) <= msg.value, "ACHTUNG: Not enough Ether");
        hodler.setHealth(_tokenId, _amount);
        if (_amount < 0) {
            walletHighscore[msg.sender] += amount;
            if(walletHighscore[msg.sender] > currentHighscore) {
                currentHighscore = walletHighscore[msg.sender];
                mostGrenades = msg.sender;
            }
        }

        emit ItemBought(msg.sender,mostGrenades,_tokenId,_amount);

        if ( !hodler.isHodlerAlive(_tokenId) ) {
            _mint(msg.sender, DOG_TAG, 1, "");
            emit HodlerDied(msg.sender,_tokenId,hodler.isHodlerAlive(_tokenId));
        }

        if ( totalSupply(DOG_TAG) >= MAX_SUPPLY-1 ) {
            battleRoyaleConcluded = true;
            lastThrow = msg.sender;
            lastHodlerStanding = hodler.ownerOf(hodler.checkLastSurvivor());
        }
    }
    function withdraw() public {
        require(contractCreator == _msgSender(), "ACHTUNG: Only Contract Creator can call this function");
        require(block.timestamp >= deadLine, "ACHTUNG: The war is not over yet!");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function distributeToWinners() public {
        require(battleRoyaleConcluded, "ACHTUNG: Still too many Hodlers alive");
        require(!payout, "ACHTUNG: already paid out");
        uint256 balance = address(this).balance;
        uint256 mgSplit = balance/100*30;
        uint256 lhsSplit = balance/100*30;
        uint256 ltSplit = balance/100*5;
        payable(lastThrow).transfer(ltSplit);
        payable(lastHodlerStanding).transfer(lhsSplit);
        payable(mostGrenades).transfer(mgSplit);
        payable(contractCreator).transfer(address(this).balance);
        payout = true;
    }
}