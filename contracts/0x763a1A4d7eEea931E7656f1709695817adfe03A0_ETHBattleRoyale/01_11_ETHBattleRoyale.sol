//SPDX-License-Identifier: MIT
// https://ethbattleroyale.com
pragma solidity ^0.8.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract ETHBattleRoyale is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable{
    // Mint constants
    uint256 public MAX_SUPPLY;
    uint256 public MAX_PER_TXN;
    uint256 public MAX_PER_WALLET;
    uint256 public ALLOWLIST_MAX;
    uint256 public MINT_COST;

    // Fighting constants
    uint32 public cooldownLength;
    uint32 timeToHeal;
    uint32 timeToShield;
    bool public battleStarted;

    // Metadata + whitelist
    string public _uriPart;
    bytes32 private merkleRoot;
    uint256 private mintStage;

    struct FighterStat {
        uint8 health;
        uint8 strength;
        uint8 currentHealth;
        bool steroidOne;
        bool steroidTwo;
        uint32 shieldTime;
        uint32 fightCooldown;
        uint32 healTime;
    }

    // theres probably a better way to have this be more gas efficient but honestly - i dont care!
    mapping(uint256 => FighterStat) public fighters;

    function initialize(string memory _baseUri, uint256 _maxSupply, uint32 _cooldownLength, uint32 _timeToHeal, uint32 _timeToShield) initializerERC721A initializer public {
        __ERC721A_init("ETHBattleRoyale", "ETHBR");
        __Ownable_init();
        __ReentrancyGuard_init();

        _uriPart = _baseUri;
        MAX_SUPPLY = _maxSupply;
        cooldownLength = _cooldownLength;
        timeToHeal = _timeToHeal;
        timeToShield = _timeToShield;

        battleStarted = false;
        mintStage = 0;

        ALLOWLIST_MAX = 3;
        MAX_PER_TXN = 5;
        MAX_PER_WALLET = 10;
        MINT_COST = 0.01 ether;
    }

    // nice and simple - looking at you thunder
    function mint(uint256 quantity) external payable nonReentrant{
        // Mint started check
        require(mintStage != 0, "mint has not started");
        // Stock check
        require(_totalMinted() + quantity <= MAX_SUPPLY, "out of stock");
        // No contracts plz
        require(msg.sender == tx.origin, "minter is a contract");
        // and no surpassing the max!
        require(_numberMinted(msg.sender) <= MAX_PER_WALLET, "surpassed max per wallet");
        require(quantity <= MAX_PER_TXN, "surpassed max per txn");

        // Mint price checks
        if(_totalMinted() + 1 < 2500){
            require(quantity == 1, "exceeded free mint quantity");
            require(_numberMinted(msg.sender) == 0, "exceeded free mint");
            require(msg.value == 0, "mint price exceeded");
        }else{
            require(msg.value == (MINT_COST * quantity), "mint price not met");
        }

        // im ngl from here on out theres gotta be a better way to do this but whatever
        uint256 currentToken = _nextTokenId();
        uint256 finalToken = currentToken + quantity;

        // Now let ERC721A handle PS: i didnt look if safeMint is reentrant safe but the gas cost is so low i said fuck it
        _safeMint(msg.sender, quantity);

        // Now assign fighter stats out
        for(currentToken; currentToken < finalToken; currentToken++){
            uint32 gasPrice = uint32(tx.gasprice/1000000000);
            // safely swap this to uint8 since max value is 100
            uint8 gas = uint8(gasPrice > 100 ? 100 : gasPrice);

            // now calculate health
            uint8 health = (gas/5) == 0 ? 1 : (gas/5);

            // now we calculate strength (max is 10, so we do 10-(gas/10)
            uint8 strength = (10 - (gas/10)) == 0 ? 1 : (10 - (gas/10));
            fighters[currentToken] = FighterStat({
                health: health,
                strength: strength,
                currentHealth: health,
                steroidOne: false,
                steroidTwo: false,
                shieldTime: 0,
                fightCooldown: 0,
                healTime: 0
            });
        }
    }

    /*
    SPARTAAAAAA
    */
    function fight(uint256 fighter, uint256 target) external nonReentrant {
        // Basic checks
        require(fighter != target, "Cannot fight self");
        require(_exists(fighter), "Fighter token does not exist");
        require(_exists(target), "Target token does not exist");
        require(battleStarted, "The battle has yet to start");
        require(ownerOf(fighter) == msg.sender, "You do not own the fighter you are trying to fight with");

        // Check timers
        FighterStat memory targetStats = fighters[target];
        FighterStat memory fighterStats = fighters[fighter];

        require(targetStats.shieldTime < block.timestamp, "Target is currently shielded");
        require(fighterStats.fightCooldown < block.timestamp, "Fighter is currently on cooldown");

        // Heal target if it's been 12 hours since they fought
        if(targetStats.healTime != 0 && targetStats.healTime < block.timestamp){
            targetStats.currentHealth = targetStats.health;
            targetStats.healTime = 0;
        }

        if(fighterStats.healTime != 0 && fighterStats.healTime < block.timestamp){
            fighterStats.currentHealth = fighterStats.health;
            fighterStats.healTime = 0;
        }

        bool updateFighter = true;
        bool updateTarget = true;

        // Calculate strength of fighter
        uint256 fighterStrength = fighterStats.strength;
        if(fighterStats.steroidOne){
            fighterStrength += 10;
        }
        if(fighterStats.steroidTwo){
            fighterStrength += 10;
        }

        // Determine who wins the fight
        if(fighterStrength > targetStats.currentHealth){
            // Attacker won - determine which stat to steal
            if(fighterStats.health == 20 && fighterStats.strength == 20){
                targetStats.health = targetStats.currentHealth/2 == 0 ? 1 : targetStats.currentHealth/2;
                targetStats.strength = targetStats.strength/2 == 0 ? 1 : targetStats.strength/2;
                targetStats.currentHealth = targetStats.health;

                // Put both on cooldown and save them
                targetStats.fightCooldown = uint32(block.timestamp) + cooldownLength;
                fighterStats.fightCooldown = uint32(block.timestamp) + cooldownLength;

                // Burn target NFT, save new stats, and mint new one (god the gas cost on this LMFAO)
                updateTarget = false;
                _burn(target);
                fighters[_nextTokenId()] = targetStats;
                _safeMint(msg.sender, 1);
            }else{
                if(targetStats.strength > targetStats.health){
                    // Stealing health
                    fighterStats.health =
                    (fighterStats.health + (targetStats.health/2 == 0 ? 1 : targetStats.health/2)) > 20
                    ? 20 : (fighterStats.health + (targetStats.health/2 == 0 ? 1 : targetStats.health/2));

                    // Heal NFT because Current HP ≠ HP now
                    fighterStats.healTime = uint32(block.timestamp) + timeToHeal;
                }else{
                    // Stealing strength
                    fighterStats.strength =
                    (fighterStats.strength + (targetStats.strength/2 == 0 ? 1 : targetStats.strength/2)) > 20
                    ? 20 : (fighterStats.strength + (targetStats.strength/2 == 0 ? 1 : targetStats.strength/2));
                }

                // BURN!
                _burn(target);
                updateTarget = false;

                // Put attacker on cooldown (not defender since it's burned teehee)
                fighterStats.fightCooldown = uint32(block.timestamp) + cooldownLength;
            }
        }else{
            // Attacker lost
            if(fighterStats.currentHealth == 1){
                _burn(fighter);
                updateFighter = false;
            }else{
                fighterStats.currentHealth = 1;
                fighterStats.healTime = uint32(block.timestamp) + timeToHeal;
            }
            targetStats.currentHealth -= fighterStats.strength/2;
            targetStats.healTime = uint32(block.timestamp) + timeToHeal;
        }

        // Reset steroids
        if(fighterStats.steroidOne){
            fighterStats.steroidOne = false;
        }
        if(fighterStats.steroidTwo){
            fighterStats.steroidTwo = false;
        }

        if(updateFighter){
            fighters[fighter] = fighterStats;
        }
        if(updateTarget){
            fighters[target] = targetStats;
        }
    }

    /*
    the fun functions are below here
    */

    // including nonReentrant for fun hehehe
    function burnForShield(uint256 tokenToBurn, uint256 tokenToShield) external nonReentrant{
        // Safety checks
        require(tokenToBurn != tokenToShield, "Cannot shield self");
        require(_exists(tokenToBurn), "Burned token does not exist");
        require(_exists(tokenToShield), "Token to shield does not exist");
        require(ownerOf(tokenToBurn) == msg.sender, "Cannot burn token you do not own");

        // BURN BABY
        _burn(tokenToBurn);

        // Apply shield and extend shieldTime by 12 hours if it's applied already, otherwise make it 12 hours from now
        uint32 shieldTime = fighters[tokenToShield].shieldTime;
        fighters[tokenToShield].shieldTime =
            block.timestamp < shieldTime ? shieldTime += 43200 : uint32(block.timestamp) + 43200;
    }

    // oh whats that? nonReentrant for no reason AGAIN?!
    function burnForSteroid(uint256 tokenToBurn, uint256 tokenToSteroid) external nonReentrant{
        // Safety checks
        require(tokenToBurn != tokenToSteroid, "Cannot shield self");
        require(_exists(tokenToBurn), "Burned token does not exist");
        require(_exists(tokenToSteroid), "Token to steroid does not exist");
        require(ownerOf(tokenToBurn) == msg.sender, "Cannot burn token you do not own");

        // Let's meet again, in the next life
        _burn(tokenToBurn);

        // Decide which to update
        if(fighters[tokenToSteroid].steroidOne == false){
            fighters[tokenToSteroid].steroidOne = true;
        }else if(fighters[tokenToSteroid].steroidTwo == false){
            fighters[tokenToSteroid].steroidTwo = true;
        }else{
            revert("No steroid slots available");
        }
    }

    /*
        public functions (for off-chain and other fun stuff :) here)
    */
    function compactAllFighters(uint256 amount, uint256 offset) public view returns (bytes[] memory){
        bytes[] memory fighters1 = new bytes[](amount);
        for(uint256 i = 0; i < amount; i++){
            uint256 token = i+offset;
            if(_exists(token) == false){
                continue;
            }
            FighterStat memory fighter = fighters[token];
            fighters1[i] = abi.encode(ownerOf(token), fighter.health, fighter.strength, fighter.currentHealth,
            fighter.steroidOne, fighter.steroidTwo, fighter.shieldTime, fighter.fightCooldown, fighter.healTime, token);
        }
        return fighters1;
    }

    function getFighterStats(uint256 token) public view returns (FighterStat memory fighterStat){
        fighterStat = fighters[token];
    }

    function getShieldTime(uint256 token) public view returns (uint256 shieldTime){
        FighterStat memory fighterStat = fighters[token];
        shieldTime = fighterStat.shieldTime;
    }

    function getFightCooldown(uint256 token) public view returns (uint256 fightCooldown){
        FighterStat memory fighterStat = fighters[token];
        fightCooldown = fighterStat.fightCooldown;
    }

    function getSteroids(uint256 token) public view returns (bool steroidOne, bool steroidTwo){
        FighterStat memory fighterStat = fighters[token];
        steroidOne = fighterStat.steroidOne;
        steroidTwo = fighterStat.steroidTwo;
    }

    /*
        administrative functions here
    */

    function mintAmount(uint256 amnt) external onlyOwner {
        require(_numberMinted(owner()) == _totalMinted(), "only usable in dev environment");
        uint256 tokenId = _nextTokenId();
        for(uint256 i = 0; i < amnt; i++){
            uint8 _health = uint8((uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId+i))) % 20)+1);
            uint8 _strength = uint8((uint(keccak256(abi.encodePacked(block.timestamp, tokenId+i, tokenId+i))) % 20)+1);

            uint32 _shielded = (uint(keccak256(abi.encodePacked(tokenId+i, tokenId+i, tokenId+i))) % 1) == 1 ? uint32(block.timestamp) + 43200 : 0;

            bool _steroidOne = (uint(keccak256(abi.encodePacked(block.timestamp, block.timestamp, tokenId+i))) % 1) == 1 ? true : false;
            bool _steroidTwo = (uint(keccak256(abi.encodePacked(block.timestamp, block.timestamp, block.timestamp))) % 1) == 1 ? true : false;

            fighters[tokenId + i] = FighterStat({
                health: _health,
                strength: _strength,
                currentHealth: _health,
                steroidOne: _steroidOne,
                steroidTwo: _steroidTwo,
                shieldTime: _shielded,
                fightCooldown: 0,
                healTime: 0
            });
        }

        _safeMint(msg.sender, amnt);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function flipBattle() external onlyOwner {
        if(battleStarted){
            battleStarted = false;
        }else{
            battleStarted = true;
        }
    }

    function setMintStage(uint256 stage) external onlyOwner {
        require(stage <= 2 && stage >= 0, "Invalid stage");
        mintStage = stage;
    }

    function setURIPart(string memory part) external onlyOwner {
        _uriPart = part;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _uriPart;
    }

    function mintStats(uint8 health, uint8 strength, bool steroidOne, bool steroidTwo) external onlyOwner{
        // Stock check
        require(_totalMinted() + 1 <= MAX_SUPPLY, "out of stock");
        // No contracts plz
        require(msg.sender == tx.origin, "minter is a contract");

        fighters[_nextTokenId()] = FighterStat({
            health: health,
            strength: strength,
            currentHealth: health,
            steroidOne: steroidOne,
            steroidTwo: steroidTwo,
            shieldTime: 0,
            fightCooldown: 0,
            healTime: 0
        });

        // Now let ERC721A handle PS: i didnt look if safeMint is reentrant safe but the gas cost is so low i said fuck it
        _safeMint(msg.sender, 1);
    }

    function updateMintParameters(uint256 _MAX_PER_TXN, uint256 _MAX_PER_WALLET, uint256 _ALLOWLIST_MAX) external onlyOwner{
        if(_MAX_PER_TXN != 0){
            MAX_PER_TXN = _MAX_PER_TXN;
        }
        if(_MAX_PER_WALLET != 0){
            MAX_PER_WALLET = _MAX_PER_WALLET;
        }
        if(_ALLOWLIST_MAX != 0){
            ALLOWLIST_MAX = _ALLOWLIST_MAX;
        }
    }

    function updateMerkleRoot(bytes32 newRoot) external onlyOwner{
        merkleRoot = newRoot;
    }

    function updateTotalSupply(uint256 _newSupply) external onlyOwner{
        require(_totalMinted() == 0, "Can only change supply before mint");
        MAX_SUPPLY = _newSupply;
    }

    function updateMintCost(uint256 newMintCost) external onlyOwner{
        MINT_COST = newMintCost;
    }

    function updateFightCooldownLength(uint32 newCooldown) external onlyOwner{
        cooldownLength = newCooldown;
    }

    function updateTimeUntilHeal(uint32 healTime) external onlyOwner{
        timeToHeal = healTime;
    }

    function updateTimeForShield(uint32 shieldTime) external onlyOwner{
        timeToShield = shieldTime;
    }
}