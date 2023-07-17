/*                                                                                                                                                                                                                                                                                                        
________                            ________            ___ ___          ____                                   ___                                 
`MMMMMMMb.                          `MMMMMMMb.          `MM `MM         6MMMMb/                                 `MM 68b                             
 MM    `Mb                           MM    `Mb           MM  MM        8P    YM                                  MM Y89                             
 MM     MM ___   ___   __            MM     MM ___   ___ MM  MM       6M      Y ___   ___    ___   ___  __   ____MM ___    ___   ___  __     ____   
 MM     MM `MM    MM  6MMbMMM        MM     MM `MM    MM MM  MM       MM        `MM    MM  6MMMMb  `MM 6MM  6MMMMMM `MM  6MMMMb  `MM 6MMb   6MMMMb\ 
 MM    .M9  MM    MM 6M'`Mb          MM    .M9  MM    MM MM  MM       MM         MM    MM 8M'  `Mb  MM69 " 6M'  `MM  MM 8M'  `Mb  MMM9 `Mb MM'    ` 
 MMMMMMM9'  MM    MM MM  MM          MMMMMMM9'  MM    MM MM  MM       MM     ___ MM    MM     ,oMM  MM'    MM    MM  MM     ,oMM  MM'   MM YM.      
 MM  \M\    MM    MM YM.,M9          MM         MM    MM MM  MM       MM     `M' MM    MM ,6MM9'MM  MM     MM    MM  MM ,6MM9'MM  MM    MM  YMMMMb  
 MM   \M\   MM    MM  YMM9           MM         MM    MM MM  MM       YM      M  MM    MM MM'   MM  MM     MM    MM  MM MM'   MM  MM    MM      `Mb 
 MM    \M\  YM.   MM (M              MM         YM.   MM MM  MM        8b    d9  YM.   MM MM.  ,MM  MM     YM.  ,MM  MM MM.  ,MM  MM    MM L    ,MM 
_MM_    \M\_ YMMM9MM_ YMMMMb.       _MM_         YMMM9MM_MM__MM_        YMMMM9    YMMM9MM_`YMMM9'Yb_MM_     YMMMMMM__MM_`YMMM9'Yb_MM_  _MM_MYMMMM9  
                     6M    Yb                                                                                                                       
                     YM.   d9                                                                                                                       
                      YMMMM9                                                                                                                        
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RugPullGuardian is ERC721A, ReentrancyGuard, Ownable {

    using Address for address;
    using Strings for uint256;
    
    uint256 public RugPullTreasure; // Rugpull has treasures plundered from the world.
    uint256 public GuardianSummonEnergy = 0.001 ether;
    uint256 public ResisterSummonEnergy = 0.001 ether;
    uint256 public GuardianWins;
    uint256 public ResisterWins;
    uint256 public PowerGain;
    uint256 public GuardianCount;
    uint256 public ResisterCount;
    uint256 public GuardianIncrease = 0;
    uint256 public ResisterIncrease = 0;
    uint256 public WatchersEnergy;
    uint256 public RugPullEndsAt;
    uint256 public ConscriptionStartsAt;
    uint256 public winner;
    uint256 public imageValid = 10000; // Not everyone is happy to show their faces, but after a while they will.
    bool public activated_ = false;
    bool public gameover = false;
    string private _summonURI;
    string private _guardianURI;
    string private _resisterURI;
    bytes32 private _root;

    // The Rule
    uint256 constant private _RugPullLPInit = 12 hours;    
    uint256 constant private _guardianLPInc = 10 minutes;              
    uint256 constant private _resistersLPInc = 5 minutes;
    uint256 constant private _RugPullLPMax = 24 hours;
    uint256 constant private _lootTime = 1 hours;
    uint256 constant private _guardianTreasure = 16;
    uint256 constant private _resisterTreasure = 26;
    uint256 constant private _summonEnergyInc = 0.00008 ether;
    uint256 constant private _watcherEXP = 4;
    uint256 constant private _increaseCount = 9;
    uint256 constant private _maxMint = 10;

    mapping (uint256 => bool) public isGuardian;
    mapping (uint256 => bool) public claimed;

    event onCharacterSummon (
        uint256 indexed startId,
        uint256 indexed teamId,
        uint256 indexed quantity,
        uint256 energy,
        bool guardian,
        string signal,
        address summoner
    );


    event onEndGame (
        uint256 indexed winnerId,
        address indexed owner,
        bool guardian,
        uint256 treasure
    );

    event onWithdraw (
        uint256 tokenId,
        address owner,
        uint256 exp
    );

    modifier isActivated() 
    {
        require(activated_ == true, "Rugpull wasn't summoned."); 
        _;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "Watchers defend the power from another world.");
        _;
    }

    constructor() ERC721A("RugPullGuardian", "RPG") {
    }

    // Advent ceremony
    function activate()
        payable
        external
        onlyOwner
    {        
        require(activated_ == false, "Rugpull is summoned.");
        
        // Watchers thought it was too boring, and created the devil Rug Pull, so that the devil wants to destroy this boring world.
        activated_ = true; 
        // Although the time in this world is limited, its power is enough to destroy the world.
        RugPullEndsAt = block.timestamp + _RugPullLPInit; 
        ConscriptionStartsAt = block.timestamp + _lootTime;
        RugPullTreasure += msg.value;

        _safeMint(msg.sender, 1);
        // Rug Pull The Dread kept summoning his ferocious space troops "Guardian" from The Void and dealt a devastating blow to mankind.
        _initCharacter(0, true);
    }

    // Rugpull has a strong army, guardians. They make Rugpull more powerful.
    function summonGuardians(uint256 quantity, string calldata inviteCode, bytes32[] calldata proof) 
        public
        payable
        isActivated()
        isHuman()
        nonReentrant
    {
        if (getRugpullLP() > 0) {
            require(quantity <= _maxMint, "Exceeded max summon limit. There was no response in the dark.");
            require(msg.value == GuardianSummonEnergy * quantity, "Energy not match. There was no response in the dark.");
            if (block.timestamp <= ConscriptionStartsAt){
                require(_verify(_leaf(msg.sender), proof), "Not the pioneer.");
            }
            
            // Rugpull keep looting.
            RugPullTreasure += msg.value * _guardianTreasure / 100;
            // Guardians gain power.
            uint256 startTokenId = _currentIndex;
            // Its LP increase.
            _increaseRugpullLP(_guardianLPInc * quantity);

            if ( GuardianIncrease < _increaseCount ) {
                GuardianIncrease++;
            }    
            else {
                GuardianIncrease = 0;
                // The energy required for summoning has been increased.
                GuardianSummonEnergy += _summonEnergyInc;
            }
            
            emit onCharacterSummon(startTokenId, GuardianCount, quantity, msg.value, true, inviteCode, msg.sender);
            // The guardians come from the darkness.
            for (uint256 i; i < quantity; i++) {
                _initCharacter(startTokenId + i, true);
            } 
            _safeMint(msg.sender, quantity);
        }
        else {  // RugPull is defeated
            require(gameover == false, "Game Over");
            Address.sendValue(payable(msg.sender), msg.value);
            endGame();
        }
    }

    // Resisters, it's time to unite.
    function summonResisters(uint256 quantity, string calldata inviteCode, bytes32[] calldata proof) 
        public
        payable
        isActivated()
        isHuman()
        nonReentrant
    {
        if (getRugpullLP() > 0) {
            require(quantity <= _maxMint, "Exceeded max summon limit. There was no response from the altar.");
            require(msg.value == ResisterSummonEnergy * quantity, "Energy not match. There was no response from the altar.");
            if (block.timestamp <= ConscriptionStartsAt){
                require(_verify(_leaf(msg.sender), proof), "Not the pioneer.");
            }
            
            // Rugpull keep looting.
            RugPullTreasure += msg.value * _resisterTreasure / 100;
            // Resisters gain power.
            uint256 startTokenId = _currentIndex;
            // Its LP increase.
            _increaseRugpullLP(_resistersLPInc * quantity);

            if ( ResisterIncrease < _increaseCount ) {
                ResisterIncrease++;
            }    
            else {
                ResisterIncrease = 0;
                // The energy required for summoning has been increased.
                ResisterSummonEnergy += _summonEnergyInc;
            }

            emit onCharacterSummon(startTokenId, ResisterCount, quantity, msg.value, false, inviteCode, msg.sender);

            // The resisters assemble.
            for (uint256 i; i < quantity; i++) {
                _initCharacter(startTokenId + i, false);
            } 
            _safeMint(msg.sender, quantity);
        }
        else {  // RugPull is defeated
            require(gameover == false, "Game Over");
            Address.sendValue(payable(msg.sender), msg.value);
            endGame();
        }
    }



    function _leaf(address account)
        internal 
        pure 
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal 
        view 
        returns (bool)
    {
        return MerkleProof.verify(proof, _root, leaf);
    }

    function endGame()
        private
    {
        uint256 winnerID = totalSupply() - 1;
        winner = winnerID;
        uint256 treasure = 0;
        gameover = true;
        if(isGuardian[winnerID] == true) { // Although RugPull was defeated, the Guardians triumphed and divided the treasure.
            treasure = RugPullTreasure / GuardianCount;
            GuardianWins += treasure;
        }
        else {  // The last resister defeated RugPull and obtained all the treasures.
            treasure = RugPullTreasure;
            ResisterWins += treasure;
        }

        emit onEndGame(winnerID, ownerOf(winnerID), getTeam(winnerID), treasure);
    }
    
    /*---Request The Oracle---*/
    function getTeam(uint256 tokenId)
        public
        view
        returns(bool)
    {
        return isGuardian[tokenId];
    }

    function getRugpullLP()
        public
        view
        returns(uint256)
    {        
        uint256 _now = block.timestamp;
        
        if (_now < RugPullEndsAt)
            return( RugPullEndsAt - _now );
        else
            return(0);
    }

    function getOwnCharacters(address summoner)
        public
        view
        returns(uint256[] memory)
    {
        uint256[] memory characters = new uint256[](balanceOf(summoner));
        uint256 mobIndex = 0;
        for (uint256 i; i < totalSupply(); i++) {
            if (ownerOf(i) == summoner) {
                characters[mobIndex] = i;
                mobIndex++;
            }
        }
        return characters;
    }

    function getPower(uint256 tokenId)
        public
        view
        returns(uint256)
    {    
        uint256 power = 0;
        if(isGuardian[tokenId] == true) {
            power = GuardianWins;
        }else {
            power = tokenId == winner?ResisterWins:0;
        }
        return power;
    }

    function gainEnergy(uint256 tokenId)
        external
        isActivated()
        isHuman()
        nonReentrant
    {
        require(ownerOf(tokenId) == msg.sender, "Not the summoner.");
        require(gameover == true, "Game is not over.");
        gainEnergyCore(tokenId);
    }

    function gainEnergyCore(uint256 tokenId)
        private
        isActivated()
        isHuman()
    {
        uint256 power = getPower(tokenId);
        Address.sendValue(payable(msg.sender), power);
        emit onWithdraw(tokenId, msg.sender, power);
        claimed[tokenId] = true;
    }

    function _initCharacter(uint256 id, bool guardian)
        private
    {
        isGuardian[id] = guardian;

        if(guardian)
            GuardianCount++;
        else
            ResisterCount++;
        
    }

    function _increaseRugpullLP(uint256 inc)
        private
    {
        if( RugPullEndsAt + inc - block.timestamp > _RugPullLPMax ) 
            RugPullEndsAt = block.timestamp + _RugPullLPMax;
        else 
            RugPullEndsAt = RugPullEndsAt + inc;
    }

    

    function tokenURI(uint256 tokenId) 
        public 
        override 
        view 
        returns (string memory) 
    {
        if(tokenId > imageValid)
            return _summonURI;
        else if(getTeam(tokenId) == true)  // Guardian's form
            return string(abi.encodePacked(_guardianURI, tokenId.toString()));
        else  // if he is a resister
            return string(abi.encodePacked(_resisterURI, tokenId.toString()));
    }

    /*---Watchers power---*/
    function setImageValid(uint256 inc)
        external
        onlyOwner
    {
        imageValid += inc;
    }

    function setSummonURI(string calldata uri)
        external
        onlyOwner
    {
        _summonURI = uri;
    }

    function setGuardianURI(string calldata uri)
        external
        onlyOwner
    {
        _guardianURI = uri;
    }

    function setResisterURI(string calldata uri)
        external
        onlyOwner
    {
        _resisterURI = uri;
    }

    function setRoot(bytes32 merkleroot)
        external
        onlyOwner
    {
        _root = merkleroot;
    }

    function watcherEnergy() 
        external 
        onlyOwner
        nonReentrant
    {
        require(address(this).balance>=RugPullTreasure, "Watcher can't touch the treasure.");
        Address.sendValue(payable(msg.sender), address(this).balance-RugPullTreasure);
        emit onWithdraw(0, msg.sender, address(this).balance-RugPullTreasure);
    }

}