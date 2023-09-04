/**
 *Submitted for verification at Etherscan.io on 2020-05-30
*/

pragma solidity ^0.4.23;

/// @title A facet of MonsterCore that manages special access privileges.
/// @dev See the MonsterCore contract documentation to understand how the various contract facets are arranged.
contract MonsterAccessControl {
    // This facet controls access control for MonsterBit. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the MonsterCore constructor.
    //
    //     - The CFO: The CFO can withdraw funds from MonsterCore and its auction contracts.
    //
    //     - The COO: The COO can release gen0 monsters to auction, and mint promo monsters.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn't have the ability to act in those roles. This
    // restriction is intentional so that we aren't tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address ceoBackupAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress || msg.sender == ceoBackupAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == ceoBackupAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}

interface SaleClockAuction {
    function isSaleClockAuction() external view returns (bool);
    function createAuction(uint, uint, uint, uint, address) external;
    function withdrawBalance() external;
}
interface SiringClockAuction {
    function isSiringClockAuction() external view returns (bool);
    function createAuction(uint, uint, uint, uint, address) external;
    function withdrawBalance() external;
    function getCurrentPrice(uint256) external view returns (uint256);
    function bid(uint256) external payable;
}
interface MonsterBattles {
    function isBattleContract() external view returns (bool);
    function prepareForBattle(address, uint, uint, uint) external payable returns(uint);
    function withdrawFromBattle(address, uint, uint, uint) external returns(uint);
    function finishBattle(address, uint, uint, uint) external returns(uint, uint, uint);
    function withdrawBalance() external;
}
interface MonsterFood {
    function isMonsterFood() external view returns (bool);
    function feedMonster(address, uint, uint, uint, uint) external payable  returns(uint, uint, uint);
    function withdrawBalance() external;
}
// interface MonsterStorage {
//     function isMonsterStorage() external view returns (bool);
//     function ownershipTokenCount(address) external view returns (uint);
//     function setOwnershipTokenCount(address, uint) external;
//     function setActionCooldown(uint, uint, uint, uint, uint, uint) external;
//     function createMonster(uint, uint, uint) external returns (uint);
//     function getMonsterBits(uint) external view returns(uint, uint, uint);
//     function monsterIndexToOwner(uint256) external view returns(address);
//     function setMonsterIndexToOwner(uint, address) external;
//     function monsterIndexToApproved(uint256) external view returns(address);
//     function setMonsterIndexToApproved(uint, address) external;
//     function getMonstersCount() external view returns(uint);
//     function sireAllowedToAddress(uint256) external view returns(address);
//     function setSireAllowedToAddress(uint, address) external;
//     function setSiringWith(uint, uint) external;
    
// }
interface MonsterConstants {
    function isMonsterConstants() external view returns (bool);
    function actionCooldowns(uint) external view returns (uint32);
    function actionCooldownsLength() external view returns(uint);
    
    function growCooldowns(uint) external view returns (uint32);
    function genToGrowCdIndex(uint) external view returns (uint8);
    function genToGrowCdIndexLength() external view returns(uint);
    
}
contract MonsterGeneticsInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isMonsterGenetics() public pure returns (bool);

    /// @dev given genes of monster 1 & 2, return a genetic combination - may have a random factor
    /// @param genesMatron genes of mom
    /// @param genesSire genes of sire
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(uint256 genesMatron, uint256 genesSire, uint256 targetBlock) public view returns (uint256 _result);
    
    function mixBattleGenes(uint256 genesMatron, uint256 genesSire, uint256 targetBlock) public view returns (uint256 _result);
}

library MonsterLib {
    
    //max uint constant for bit operations
    uint constant UINT_MAX = uint(2) ** 256 - 1;
    
    function getBits(uint256 source, uint offset, uint count) public pure returns(uint256 bits_)
    {
        uint256 mask = (uint(2) ** count - 1) * uint(2) ** offset;
        return (source & mask) / uint(2) ** offset;
    }
    
    function setBits(uint target, uint bits, uint size, uint offset) public pure returns(uint)
    {
        //ensure bits do not exccess declared size
        uint256 truncateMask = uint(2) ** size - 1;
        bits = bits & truncateMask;
        
        //shift in place
        bits = bits * uint(2) ** offset;
        
        uint clearMask = ((uint(2) ** size - 1) * (uint(2) ** offset)) ^ UINT_MAX;
        target = target & clearMask;
        target = target | bits;
        return target;
        
    }
    
    /// @dev The main Monster struct. Every monster in MonsterBit is represented by a copy
    ///  of this structure, so great care was taken to ensure that it fits neatly into
    ///  exactly two 256-bit words. Note that the order of the members in this structure
    ///  is important because of the byte-packing rules used by Ethereum.
    ///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Monster {
        // The Monster's genetic code is packed into these 256-bits, the format is
        // sooper-sekret! A monster's genes never change.
        uint256 genes;
        
        // The timestamp from the block when this monster came into existence.
        uint64 birthTime;
        
        // The "generation number" of this monster. Monsters minted by the CK contract
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other monsters is the larger of the two generation
        // numbers of their parents, plus one.
        // (i.e. max(matron.generation, sire.generation) + 1)
        uint16 generation;
        
        // The minimum timestamp after which this monster can engage in breeding
        // activities again. This same timestamp is used for the pregnancy
        // timer (for matrons) as well as the siring cooldown.
        uint64 cooldownEndTimestamp;
        
        // The ID of the parents of this monster, set to 0 for gen0 monsters.
        // Note that using 32-bit unsigned integers limits us to a "mere"
        // 4 billion monsters. This number might seem small until you realize
        // that Ethereum currently has a limit of about 500 million
        // transactions per year! So, this definitely won't be a problem
        // for several years (even as Ethereum learns to scale).
        uint32 matronId;
        uint32 sireId;
        
        // Set to the ID of the sire monster for matrons that are pregnant,
        // zero otherwise. A non-zero value here is how we know a monster
        // is pregnant. Used to retrieve the genetic material for the new
        // monster when the birth transpires.
        uint32 siringWithId;
        
        // Set to the index in the cooldown array (see below) that represents
        // the current cooldown duration for this monster. This starts at zero
        // for gen0 cats, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding action, regardless
        // of whether this monster is acting as matron or sire.
        uint16 cooldownIndex;
        
        // Monster genetic code for battle attributes
        uint64 battleGenes;
        
        uint8 activeGrowCooldownIndex;
        uint8 activeRestCooldownIndex;
        
        uint8 level;
        
        uint8 potionEffect;
        uint64 potionExpire;
        
        uint64 cooldownStartTimestamp;
        
        uint8 battleCounter;
    }
    

    function encodeMonsterBits(Monster mon) internal pure returns(uint p1, uint p2, uint p3)
    {
        p1 = mon.genes;
        
        p2 = 0;
        p2 = setBits(p2, mon.cooldownEndTimestamp, 64, 0);
        p2 = setBits(p2, mon.potionExpire, 64, 64);
        p2 = setBits(p2, mon.cooldownStartTimestamp, 64, 128);
        p2 = setBits(p2, mon.birthTime, 64, 192);
        
        p3 = 0;
        p3 = setBits(p3, mon.generation, 16, 0);
        p3 = setBits(p3, mon.matronId, 32, 16);
        p3 = setBits(p3, mon.sireId, 32, 48);
        p3 = setBits(p3, mon.siringWithId, 32, 80);
        p3 = setBits(p3, mon.cooldownIndex, 16, 112);
        p3 = setBits(p3, mon.battleGenes, 64, 128);
        p3 = setBits(p3, mon.activeGrowCooldownIndex, 8, 192);
        p3 = setBits(p3, mon.activeRestCooldownIndex, 8, 200);
        p3 = setBits(p3, mon.level, 8, 208);
        p3 = setBits(p3, mon.potionEffect, 8, 216);
        p3 = setBits(p3, mon.battleCounter, 8, 224);
    }
    
    function decodeMonsterBits(uint p1, uint p2, uint p3) internal pure returns(Monster mon)
    {
        mon = MonsterLib.Monster({
            genes: 0,
            birthTime: 0,
            cooldownEndTimestamp: 0,
            matronId: 0,
            sireId: 0,
            siringWithId: 0,
            cooldownIndex: 0,
            generation: 0,
            battleGenes: 0,
            level: 0,
            activeGrowCooldownIndex: 0,
            activeRestCooldownIndex: 0,
            potionEffect: 0,
            potionExpire: 0,
            cooldownStartTimestamp: 0,
            battleCounter: 0
        });
        
        mon.genes = p1;
        
        mon.cooldownEndTimestamp = uint64(getBits(p2, 0, 64));
        mon.potionExpire = uint64(getBits(p2, 64, 64));
        mon.cooldownStartTimestamp = uint64(getBits(p2, 128, 64));
        mon.birthTime = uint64(getBits(p2, 192, 64));
        mon.generation = uint16(getBits(p3, 0, 16));
        mon.matronId = uint32(getBits(p3, 16, 32));
        mon.sireId = uint32(getBits(p3, 48, 32));
        mon.siringWithId = uint32(getBits(p3, 80, 32));
        mon.cooldownIndex = uint16(getBits(p3, 112, 16));
        mon.battleGenes = uint64(getBits(p3, 128, 64));
        mon.activeGrowCooldownIndex = uint8(getBits(p3, 192, 8));
        mon.activeRestCooldownIndex = uint8(getBits(p3, 200, 8));
        mon.level = uint8(getBits(p3, 208, 8));
        mon.potionEffect = uint8(getBits(p3, 216, 8));
        mon.battleCounter = uint8(getBits(p3, 224, 8));
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract MonsterStorage is Ownable
{
    ERC721 public nonFungibleContract;
    
    bool public isMonsterStorage = true;
    
    constructor(address _nftAddress) public
    {
        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
        MonsterLib.Monster memory mon = MonsterLib.decodeMonsterBits(uint(-1), 0, 0);
        _createMonster(mon);
        monsterIndexToOwner[0] = address(0);
    }
    
    function setTokenContract(address _nftAddress) external onlyOwner
    {
        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
    }
    
    modifier onlyCore() {
        require(msg.sender != address(0) && msg.sender == address(nonFungibleContract));
        _;
    }
    
    /*** STORAGE ***/

    /// @dev An array containing the Monster struct for all Monsters in existence. The ID
    ///  of each monster is actually an index into this array. Note that ID 0 is a negamonster,
    ///  the unMonster, the mythical beast that is the parent of all gen0 monsters. A bizarre
    ///  creature that is both matron and sire... to itself! Has an invalid genetic code.
    ///  In other words, monster ID 0 is invalid... ;-)
    MonsterLib.Monster[] monsters;
    
    uint256 public pregnantMonsters;
    
    function setPregnantMonsters(uint newValue) onlyCore public
    {
        pregnantMonsters = newValue;
    }
    
    function getMonstersCount() public view returns(uint) 
    {
        return monsters.length;
    }
    
    
    /// @dev A mapping from monster IDs to the address that owns them. All monsters have
    ///  some valid owner address, even gen0 monsters are created with a non-zero owner.
    mapping (uint256 => address) public monsterIndexToOwner;
    
    function setMonsterIndexToOwner(uint index, address owner) onlyCore public
    {
        monsterIndexToOwner[index] = owner;
    }

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) public ownershipTokenCount;
    
    function setOwnershipTokenCount(address owner, uint count) onlyCore public
    {
        ownershipTokenCount[owner] = count;
    }

    /// @dev A mapping from MonsterIDs to an address that has been approved to call
    ///  transferFrom(). Each Monster can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public monsterIndexToApproved;
    
    function setMonsterIndexToApproved(uint index, address approved) onlyCore public
    {
        if(approved == address(0))
        {
            delete monsterIndexToApproved[index];
        }
        else
        {
            monsterIndexToApproved[index] = approved;
        }
    }
    
    /// @dev A mapping from MonsterIDs to an address that has been approved to use
    ///  this monster for siring via breedWith(). Each monster can only have one approved
    ///  address for siring at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public sireAllowedToAddress;
    
    function setSireAllowedToAddress(uint index, address allowed) onlyCore public
    {
        if(allowed == address(0))
        {
            delete sireAllowedToAddress[index];
        }
        else 
        {
            sireAllowedToAddress[index] = allowed;
        }
    }
    
    /// @dev An internal method that creates a new monster and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.

    function createMonster(uint p1, uint p2, uint p3)
        onlyCore
        public
        returns (uint)
    {

        MonsterLib.Monster memory mon = MonsterLib.decodeMonsterBits(p1, p2, p3);


        uint256 newMonsterId = _createMonster(mon);

        // It's probably never going to happen, 4 billion monsters is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newMonsterId == uint256(uint32(newMonsterId)));

        return newMonsterId;
    }
    
    function _createMonster(MonsterLib.Monster mon) internal returns(uint)
    {
        uint256 newMonsterId = monsters.push(mon) - 1;
        
        return newMonsterId;
    }
    
    function setLevel(uint monsterId, uint level) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        mon.level = uint8(level);
    }
    
    function setPotion(uint monsterId, uint potionEffect, uint potionExpire) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        mon.potionEffect = uint8(potionEffect);
        mon.potionExpire = uint64(potionExpire);
    }
    

    function setBattleCounter(uint monsterId, uint battleCounter) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        mon.battleCounter = uint8(battleCounter);
    }
    
    function setActionCooldown(uint monsterId, 
    uint cooldownIndex, 
    uint cooldownEndTimestamp, 
    uint cooldownStartTimestamp,
    uint activeGrowCooldownIndex, 
    uint activeRestCooldownIndex) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        mon.cooldownIndex = uint16(cooldownIndex);
        mon.cooldownEndTimestamp = uint64(cooldownEndTimestamp);
        mon.cooldownStartTimestamp = uint64(cooldownStartTimestamp);
        mon.activeRestCooldownIndex = uint8(activeRestCooldownIndex);
        mon.activeGrowCooldownIndex = uint8(activeGrowCooldownIndex);
    }
    
    function setSiringWith(uint monsterId, uint siringWithId) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        if(siringWithId == 0)
        {
            delete mon.siringWithId;
        }
        else
        {
            mon.siringWithId = uint32(siringWithId);
        }
    }
    
    
    function getMonsterBits(uint monsterId) public view returns(uint p1, uint p2, uint p3)
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        (p1, p2, p3) = MonsterLib.encodeMonsterBits(mon);
    }
    
    function setMonsterBits(uint monsterId, uint p1, uint p2, uint p3) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        MonsterLib.Monster memory mon2 = MonsterLib.decodeMonsterBits(p1, p2, p3);
        mon.cooldownIndex = mon2.cooldownIndex;
        mon.siringWithId = mon2.siringWithId;
        mon.activeGrowCooldownIndex = mon2.activeGrowCooldownIndex;
        mon.activeRestCooldownIndex = mon2.activeRestCooldownIndex;
        mon.level = mon2.level;
        mon.potionEffect = mon2.potionEffect;
        mon.cooldownEndTimestamp = mon2.cooldownEndTimestamp;
        mon.potionExpire = mon2.potionExpire;
        mon.cooldownStartTimestamp = mon2.cooldownStartTimestamp;
        mon.battleCounter = mon2.battleCounter;
        
    }
    
    function setMonsterBitsFull(uint monsterId, uint p1, uint p2, uint p3) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        MonsterLib.Monster memory mon2 = MonsterLib.decodeMonsterBits(p1, p2, p3);
        mon.birthTime = mon2.birthTime;
        mon.generation = mon2.generation;
        mon.genes = mon2.genes;
        mon.battleGenes = mon2.battleGenes;
        mon.cooldownIndex = mon2.cooldownIndex;
        mon.matronId = mon2.matronId;
        mon.sireId = mon2.sireId;
        mon.siringWithId = mon2.siringWithId;
        mon.activeGrowCooldownIndex = mon2.activeGrowCooldownIndex;
        mon.activeRestCooldownIndex = mon2.activeRestCooldownIndex;
        mon.level = mon2.level;
        mon.potionEffect = mon2.potionEffect;
        mon.cooldownEndTimestamp = mon2.cooldownEndTimestamp;
        mon.potionExpire = mon2.potionExpire;
        mon.cooldownStartTimestamp = mon2.cooldownStartTimestamp;
        mon.battleCounter = mon2.battleCounter;
        
    }
}


/// @title Base contract for MonsterBit. Holds all common structs, events and base variables.
/// @dev See the MonsterCore contract documentation to understand how the various contract facets are arranged.
contract MonsterBase is MonsterAccessControl {
    /*** EVENTS ***/

    /// @dev The Birth event is fired whenever a new monster comes into existence. This obviously
    ///  includes any time a monster is created through the giveBirth method, but it is also called
    ///  when a new gen0 monster is created.
    event Birth(address owner, uint256 monsterId, uint256 genes);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a monster
    ///  ownership is assigned, including births.
    event Transfer(address from, address to, uint256 tokenId);


    /// @dev The address of the ClockAuction contract that handles sales of Monsters. This
    ///  same contract handles both peer-to-peer sales as well as the gen0 sales which are
    ///  initiated every 15 minutes.
    SaleClockAuction public saleAuction;
    SiringClockAuction public siringAuction;
    MonsterBattles public battlesContract;
    MonsterFood public monsterFood;
    MonsterStorage public monsterStorage;
    MonsterConstants public monsterConstants;
    
    /// @dev The address of the sibling contract that is used to implement the sooper-sekret
    ///  genetic combination algorithm.
    MonsterGeneticsInterface public geneScience;
    
    function setMonsterStorageAddress(address _address) external onlyCEO {
        MonsterStorage candidateContract = MonsterStorage(_address);

        // NOTE: verify that a contract is what we expect
        require(candidateContract.isMonsterStorage());

        // Set the new contract address
        monsterStorage = candidateContract;
    }
    
    function setMonsterConstantsAddress(address _address) external onlyCEO {
        MonsterConstants candidateContract = MonsterConstants(_address);

        // NOTE: verify that a contract is what we expect
        require(candidateContract.isMonsterConstants());

        // Set the new contract address
        monsterConstants = candidateContract;
    }
    
    /// @dev Sets the reference to the battles contract.
    /// @param _address - Address of battles contract.
    function setBattlesAddress(address _address) external onlyCEO {
        MonsterBattles candidateContract = MonsterBattles(_address);

        // NOTE: verify that a contract is what we expect
        require(candidateContract.isBattleContract());

        // Set the new contract address
        battlesContract = candidateContract;
    }


    /// @dev Assigns ownership of a specific Monster to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of monsters is capped to 2^32 we can't overflow this
        uint count = monsterStorage.ownershipTokenCount(_to);
        monsterStorage.setOwnershipTokenCount(_to, count + 1);
        
        // transfer ownership
        monsterStorage.setMonsterIndexToOwner(_tokenId, _to);
        // When creating new monsters _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            count =  monsterStorage.ownershipTokenCount(_from);
            monsterStorage.setOwnershipTokenCount(_from, count - 1);
            // clear any previously approved ownership exchange
            monsterStorage.setMonsterIndexToApproved(_tokenId, address(0));
        }
        
        if(_from == address(saleAuction))
        {
            MonsterLib.Monster memory monster = readMonster(_tokenId);
            if(monster.level == 0)
            {
                monsterStorage.setActionCooldown(_tokenId, 
                    monster.cooldownIndex, 
                    uint64(now + monsterConstants.growCooldowns(monster.activeGrowCooldownIndex)), 
                    now,
                    monster.activeGrowCooldownIndex, 
                    monster.activeRestCooldownIndex);
            }
        }
        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new monster and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    /// @param _generation The generation number of this monster, must be computed by caller.
    /// @param _genes The monster's genetic code.
    /// @param _owner The inital owner of this monster, must be non-zero (except for the unMonster, ID 0)
    function _createMonster(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        uint256 _battleGenes,
        uint256 _level,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));
        
        
        
        MonsterLib.Monster memory _monster = MonsterLib.Monster({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndTimestamp: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: uint32(0),
            cooldownIndex: uint16(0),
            generation: uint16(_generation),
            battleGenes: uint64(_battleGenes),
            level: uint8(_level),
            activeGrowCooldownIndex: uint8(0),
            activeRestCooldownIndex: uint8(0),
            potionEffect: uint8(0),
            potionExpire: uint64(0),
            cooldownStartTimestamp: 0,
            battleCounter: uint8(0)
        });
        
        
        setMonsterGrow(_monster);
        (uint p1, uint p2, uint p3) = MonsterLib.encodeMonsterBits(_monster);
        
        uint monsterId = monsterStorage.createMonster(p1, p2, p3);

        // emit the birth event
        emit Birth(
            _owner,
            monsterId,
            _genes
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, monsterId);

        return monsterId;
    }
    
    function setMonsterGrow(MonsterLib.Monster monster) internal view
    {
         //New monster starts with the same cooldown as parent gen/2
        uint16 cooldownIndex = uint16(monster.generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }
        
        monster.cooldownIndex = uint16(cooldownIndex);
        
        if(monster.level == 0)
        {
            uint gen = monster.generation;
            if(gen > monsterConstants.genToGrowCdIndexLength())
            {
                gen = monsterConstants.genToGrowCdIndexLength();
            }
            
            monster.activeGrowCooldownIndex = monsterConstants.genToGrowCdIndex(gen);
            monster.cooldownEndTimestamp = uint64(now + monsterConstants.growCooldowns(monster.activeGrowCooldownIndex));
            monster.cooldownStartTimestamp = uint64(now);
        }
    }
    
    function readMonster(uint monsterId) internal view returns(MonsterLib.Monster)
    {
        (uint p1, uint p2, uint p3) = monsterStorage.getMonsterBits(monsterId);
       
        MonsterLib.Monster memory mon = MonsterLib.decodeMonsterBits(p1, p2, p3);
         
        return mon;
    }
}


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <[email protected]> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

/// @title The facet of the MonsterBit core contract that manages ownership, ERC-721 (draft) compliant.
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721
///  See the MonsterCore contract documentation to understand how the various contract facets are arranged.
contract MonsterOwnership is MonsterBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "MonsterBit";
    string public constant symbol = "MB";

    /// @dev Checks if a given address is the current owner of a particular Monster.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId monster id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterStorage.monsterIndexToOwner(_tokenId) == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Monster.
    /// @param _claimant the address we are confirming monster is approved for.
    /// @param _tokenId monster id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterStorage.monsterIndexToApproved(_tokenId) == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting Monsters on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        monsterStorage.setMonsterIndexToApproved(_tokenId, _approved);
    }

    /// @notice Returns the number of Monsters owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return monsterStorage.ownershipTokenCount(_owner);
    }

    /// @notice Transfers a Monster to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  MonsterBit specifically) or your Monster may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Monster to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any monsters (except very briefly
        // after a gen0 monster is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of monsters
        // through the allow + transferFrom flow.
        require(_to != address(saleAuction));

        // You can only send your own monster.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific Monster via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Monster that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Monster owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Monster to be transfered.
    /// @param _to The address that should take ownership of the Monster. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Monster to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any monsters (except very briefly
        // after a gen0 monster is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Monsters currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return monsterStorage.getMonstersCount() - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given Monster.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = monsterStorage.monsterIndexToOwner(_tokenId);

        require(owner != address(0));
    }

    /// @notice Returns a list of all Monster IDs assigned to an address.
    /// @param _owner The owner whose Monsters we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire Monster array looking for monsters belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMonsters = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all monsters have IDs starting at 1 and increasing
            // sequentially up to the totalMonsters count.
            uint256 monsterId;

            for (monsterId = 1; monsterId <= totalMonsters; monsterId++) {
                if (monsterStorage.monsterIndexToOwner(monsterId) == _owner) {
                    result[resultIndex] = monsterId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

/// @title A facet of MosterBitCore that manages Monster siring, gestation, and birth.
contract MonsterBreeding is MonsterOwnership {

    /// @dev The Pregnant event is fired when two monster successfully breed and the pregnancy
    ///  timer begins for the matron.
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndTimestamp);

    /// @notice The minimum payment required to use breedWithAuto(). This fee goes towards
    ///  the gas cost paid by whatever calls giveBirth(), and can be dynamically updated by
    ///  the COO role as the gas price changes.
    uint256 public autoBirthFee = 2 finney;
    uint256 public birthCommission = 5 finney;
    
    

    

    /// @dev Update the address of the genetic contract, can only be called by the CEO.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    function setGeneScienceAddress(address _address) external onlyCEO {
        MonsterGeneticsInterface candidateContract = MonsterGeneticsInterface(_address);

        // NOTE: verify that a contract is what we expect
        require(candidateContract.isMonsterGenetics());

        // Set the new contract address
        geneScience = candidateContract;
    }
    
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSiringClockAuction());

        // Set the new contract address
        siringAuction = candidateContract;
    }

    /// @dev Checks that a given monster is able to breed. Requires that the
    ///  current cooldown is finished (for sires) and also checks that there is
    ///  no pending pregnancy.
    function _isReadyToBreed(MonsterLib.Monster _monster) internal view returns (bool) {
        // In addition to checking the cooldownEndTimestamp, we also need to check to see if
        // the cat has a pending birth; there can be some period of time between the end
        // of the pregnacy timer and the birth event.
        return (_monster.siringWithId == 0) && (_monster.cooldownEndTimestamp <= uint64(now) && (_monster.level >= 1));
    }

    /// @dev Check if a sire has authorized breeding with this matron. True if both sire
    ///  and matron have the same owner, or if the sire has given siring permission to
    ///  the matron's owner (via approveSiring()).
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = monsterStorage.monsterIndexToOwner(_matronId);
        address sireOwner = monsterStorage.monsterIndexToOwner(_sireId);

        // Siring is okay if they have same owner, or if the matron's owner was given
        // permission to breed with this sire.
        return (matronOwner == sireOwner || monsterStorage.sireAllowedToAddress(_sireId) == matronOwner);
    }

    /// @dev Set the cooldownEndTime for the given monster, based on its current cooldownIndex.
    ///  Also increments the cooldownIndex (unless it has hit the cap).
    /// @param _monster A reference to the monster in storage which needs its timer started.
    function _triggerCooldown(uint monsterId, MonsterLib.Monster _monster, uint increaseIndex) internal {

        uint activeRestCooldownIndex = _monster.cooldownIndex;
        uint cooldownEndTimestamp = uint64(monsterConstants.actionCooldowns(activeRestCooldownIndex) + now);
        uint newCooldownIndex = _monster.cooldownIndex;
        // Increment the breeding count, clamping it at 13, which is the length of the
        // cooldowns array. We could check the array size dynamically, but hard-coding
        // this as a constant saves gas. Yay, Solidity!
        if(increaseIndex > 0)
        {
            if (newCooldownIndex + 1 < monsterConstants.actionCooldownsLength()) {
                newCooldownIndex += 1;
            }
        }
        
        monsterStorage.setActionCooldown(monsterId, newCooldownIndex, cooldownEndTimestamp, now, 0, activeRestCooldownIndex);
    }
    
    

    /// @notice Grants approval to another user to sire with one of your monsters.
    /// @param _addr The address that will be able to sire with your monster. Set to
    ///  address(0) to clear all siring approvals for this monster.
    /// @param _sireId A monster that you own that _addr will now be able to sire with.
    function approveSiring(address _addr, uint256 _sireId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        monsterStorage.setSireAllowedToAddress(_sireId, _addr);
    }

    /// @dev Updates the minimum payment required for calling giveBirthAuto(). Can only
    ///  be called by the COO address. (This fee is used to offset the gas cost incurred
    ///  by the autobirth daemon).
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }
    
    function setBirthCommission(uint val) external onlyCOO{
        birthCommission = val;
    }

    /// @dev Checks to see if a given monster is pregnant and (if so) if the gestation
    ///  period has passed.
    function _isReadyToGiveBirth(MonsterLib.Monster _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndTimestamp <= now);
    }

    /// @notice Checks that a given monster is able to breed (i.e. it is not pregnant or
    ///  in the middle of a siring cooldown).
    /// @param _monsterId reference the id of the monster, any user can inquire about it
    function isReadyToBreed(uint256 _monsterId)
        public
        view
        returns (bool)
    {
        require(_monsterId > 0);
        MonsterLib.Monster memory monster = readMonster(_monsterId);
        return _isReadyToBreed(monster);
    }
    
    /// @dev Internal check to see if a given sire and matron are a valid mating pair. DOES NOT
    ///  check ownership permissions (that is up to the caller).
    /// @param _matron A reference to the monster struct of the potential matron.
    /// @param _matronId The matron's ID.
    /// @param _sire A reference to the monster struct of the potential sire.
    /// @param _sireId The sire's ID
    function _isValidMatingPair(
        MonsterLib.Monster _matron,
        uint256 _matronId,
        MonsterLib.Monster _sire,
        uint256 _sireId
    )
        internal
        pure
        returns(bool)
    {
        // A monster can't breed with itself!
        if (_matronId == _sireId) {
            return false;
        }

        // monsters can't breed with their parents.
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        // We can short circuit the sibling check (below) if either cat is
        // gen zero (has a matron ID of zero).
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        // monster can't breed with full or half siblings.
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        // Everything seems cool! Let's get DTF.
        return true;
    }

    /// @dev Checks whether a monster is currently pregnant.
    /// @param _monsterId reference the id of the monster, any user can inquire about it
    function isPregnant(uint256 _monsterId)
        public
        view
        returns (bool)
    {
        require(_monsterId > 0);
        // A monster is pregnant if and only if this field is set
        MonsterLib.Monster memory monster = readMonster(_monsterId);
        return monster.siringWithId != 0;
    }

    

    /// @dev Internal check to see if a given sire and matron are a valid mating pair for
    ///  breeding via auction (i.e. skips ownership and siring approval checks).
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        MonsterLib.Monster memory matron = readMonster(_matronId);
        MonsterLib.Monster memory sire = readMonster(_sireId);
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    /// @notice Checks to see if two monsters can breed together, including checks for
    ///  ownership and siring approvals. Does NOT check that both cats are ready for
    ///  breeding (i.e. breedWith could still fail until the cooldowns are finished).
    /// @param _matronId The ID of the proposed matron.
    /// @param _sireId The ID of the proposed sire.
    function canBreedWith(uint256 _matronId, uint256 _sireId)
        external
        view
        returns(bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        MonsterLib.Monster memory matron = readMonster(_matronId);
        MonsterLib.Monster memory sire = readMonster(_sireId);
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
            _isSiringPermitted(_sireId, _matronId);
    }

    /// @dev Internal utility function to initiate breeding, assumes that all breeding
    ///  requirements have been checked.
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        // Grab a reference to the Kitties from storage.
        MonsterLib.Monster memory sire = readMonster(_sireId);
        MonsterLib.Monster memory matron = readMonster(_matronId);

        // Mark the matron as pregnant, keeping track of who the sire is.
        monsterStorage.setSiringWith(_matronId, _sireId);
        

        // Trigger the cooldown for both parents.
        _triggerCooldown(_sireId, sire, 1);
        _triggerCooldown(_matronId, matron, 1);

        // Clear siring permission for both parents. This may not be strictly necessary
        // but it's likely to avoid confusion!
        monsterStorage.setSireAllowedToAddress(_matronId, address(0));
        monsterStorage.setSireAllowedToAddress(_sireId, address(0));

        uint pregnantMonsters = monsterStorage.pregnantMonsters();
        monsterStorage.setPregnantMonsters(pregnantMonsters + 1);

        // Emit the pregnancy event.
        emit Pregnant(monsterStorage.monsterIndexToOwner(_matronId), _matronId, _sireId, matron.cooldownEndTimestamp);
    }

    /// @notice Breed a monster you own (as matron) with a sire that you own, or for which you
    ///  have previously been given Siring approval. Will either make your monster pregnant, or will
    ///  fail entirely. Requires a pre-payment of the fee given out to the first caller of giveBirth()
    /// @param _matronId The ID of the monster acting as matron (will end up pregnant if successful)
    /// @param _sireId The ID of the monster acting as sire (will begin its siring cooldown if successful)
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
        external
        payable
        whenNotPaused
    {
        // Checks for payment.
        require(msg.value >= autoBirthFee + birthCommission);

        // Caller must own the matron.
        require(_owns(msg.sender, _matronId));

        // Neither sire nor matron are allowed to be on auction during a normal
        // breeding operation, but we don't need to check that explicitly.
        // For matron: The caller of this function can't be the owner of the matron
        //   because the owner of a Kitty on auction is the auction house, and the
        //   auction house will never call breedWith().
        // For sire: Similarly, a sire on auction will be owned by the auction house
        //   and the act of transferring ownership will have cleared any oustanding
        //   siring approval.
        // Thus we don't need to spend gas explicitly checking to see if either cat
        // is on auction.

        // Check that matron and sire are both owned by caller, or that the sire
        // has given siring permission to caller (i.e. matron's owner).
        // Will fail for _sireId = 0
        require(_isSiringPermitted(_sireId, _matronId));

        // Grab a reference to the potential matron
        MonsterLib.Monster memory matron = readMonster(_matronId);

        // Make sure matron isn't pregnant, or in the middle of a siring cooldown
        require(_isReadyToBreed(matron));

        // Grab a reference to the potential sire
        MonsterLib.Monster memory sire = readMonster(_sireId);

        // Make sure sire isn't pregnant, or in the middle of a siring cooldown
        require(_isReadyToBreed(sire));

        // Test that these cats are a valid mating pair.
        require(_isValidMatingPair(
            matron,
            _matronId,
            sire,
            _sireId
        ));

        // All checks passed, kitty gets pregnant!
        _breedWith(_matronId, _sireId);
    }

    /// @notice Have a pregnant monster give birth!
    /// @param _matronId A monster ready to give birth.
    /// @return The monster ID of the new monster.
    /// @dev Looks at a given monster and, if pregnant and if the gestation period has passed,
    ///  combines the genes of the two parents to create a new monster. The new monster is assigned
    ///  to the current owner of the matron. Upon successful completion, both the matron and the
    ///  new monster will be ready to breed again. Note that anyone can call this function (if they
    ///  are willing to pay the gas!), but the new monster always goes to the mother's owner.
    function giveBirth(uint256 _matronId)
        external
        whenNotPaused
        returns(uint256)
    {
        // Grab a reference to the matron in storage.
        MonsterLib.Monster memory matron = readMonster(_matronId);

        // Check that the matron is a valid cat.
        require(matron.birthTime != 0);

        // Check that the matron is pregnant, and that its time has come!
        require(_isReadyToGiveBirth(matron));

        // Grab a reference to the sire in storage.
        uint256 sireId = matron.siringWithId;
        MonsterLib.Monster memory sire = readMonster(sireId);

        // Determine the higher generation number of the two parents
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        // Call the sooper-sekret gene mixing operation.
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, block.number - 1);
        uint256 childBattleGenes = geneScience.mixBattleGenes(matron.battleGenes, sire.battleGenes, block.number - 1);

        // Make the new kitten!
        address owner = monsterStorage.monsterIndexToOwner(_matronId);
        uint256 monsterId = _createMonster(_matronId, matron.siringWithId, parentGen + 1, childGenes, childBattleGenes, 0, owner);

        // Clear the reference to sire from the matron (REQUIRED! Having siringWithId
        // set is what marks a matron as being pregnant.)
        monsterStorage.setSiringWith(_matronId, 0);

        uint pregnantMonsters = monsterStorage.pregnantMonsters();
        monsterStorage.setPregnantMonsters(pregnantMonsters - 1);

        
        // Send the balance fee to the person who made birth happen.
        msg.sender.transfer(autoBirthFee);

        // return the new kitten's ID
        return monsterId;
    }
}


contract MonsterFeeding is MonsterBreeding {
    
    event MonsterFed(uint monsterId, uint growScore);
    
    
    function setMonsterFoodAddress(address _address) external onlyCEO {
        MonsterFood candidateContract = MonsterFood(_address);

        // NOTE: verify that a contract is what we expect
        require(candidateContract.isMonsterFood());

        // Set the new contract address
        monsterFood = candidateContract;
    }
    
    function feedMonster(uint _monsterId, uint _foodCode) external payable{

        (uint p1, uint p2, uint p3) = monsterStorage.getMonsterBits(_monsterId);
        
        (p1, p2, p3) = monsterFood.feedMonster.value(msg.value)( msg.sender, _foodCode, p1, p2, p3);
        
        monsterStorage.setMonsterBits(_monsterId, p1, p2, p3);

        emit MonsterFed(_monsterId, 0);
        
    }
}

/// @title Handles creating auctions for sale and siring of monsters.
contract MonsterFighting is MonsterFeeding {
    
    
      function prepareForBattle(uint _param1, uint _param2, uint _param3) external payable returns(uint){
        require(_param1 > 0);
        require(_param2 > 0);
        require(_param3 > 0);
        
        for(uint i = 0; i < 5; i++){
            uint monsterId = MonsterLib.getBits(_param1, uint8(i * 32), uint8(32));
            require(_owns(msg.sender, monsterId));
            _approve(monsterId, address(battlesContract));
        }
        
        return battlesContract.prepareForBattle.value(msg.value)(msg.sender, _param1, _param2, _param3);
    }
    
    function withdrawFromBattle(uint _param1, uint _param2, uint _param3) external returns(uint){
        return battlesContract.withdrawFromBattle(msg.sender, _param1, _param2, _param3);
    }
    
    function finishBattle(uint _param1, uint _param2, uint _param3) external returns(uint) {
        (uint return1, uint return2, uint return3) = battlesContract.finishBattle(msg.sender, _param1, _param2, _param3);
        uint[10] memory monsterIds;
        uint i;
        uint monsterId;
        
        require(return3>=0);
        
        for(i = 0; i < 8; i++){
            monsterId = MonsterLib.getBits(return1, uint8(i * 32), uint8(32));
            monsterIds[i] = monsterId;
        }
        
        for(i = 0; i < 2; i++){
            monsterId = MonsterLib.getBits(return2, uint8(i * 32), uint8(32));
            monsterIds[i+8] = monsterId;
        }
        
        for(i = 0; i < 10; i++){
            monsterId = monsterIds[i];
            MonsterLib.Monster memory monster = readMonster(monsterId);
            uint bc = monster.battleCounter + 1;
            uint increaseIndex = 0;
            if(bc >= 10)
            {
                bc = 0;
                increaseIndex = 1;
            }
            monster.battleCounter = uint8(bc);
            _triggerCooldown(monsterId, monster, increaseIndex);
        }
        
        
    }
}

/// @title Handles creating auctions for sale and siring of monsters.
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract MonsterAuction is MonsterFighting {

    // @notice The auction contract variables are defined in MonsterBase to allow
    //  us to refer to them in MonsterOwnership to prevent accidental transfers.
    // `saleAuction` refers to the auction for gen0 and p2p sale of monsters.
    // `siringAuction` refers to the auction for siring rights of monsters.

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }


    /// @dev Put a monster up for auction.
    ///  Does some ownership trickery to create auctions in one tx.
    function createSaleAuction(
        uint256 _monsterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If monster is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _monsterId));
        // Ensure the monster is not pregnant to prevent the auction
        // contract accidentally receiving ownership of the child.
        // NOTE: the monster IS allowed to be in a cooldown.
        require(!isPregnant(_monsterId));
        _approve(_monsterId, saleAuction);
        // Sale auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the monster.
        saleAuction.createAuction(
            _monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
    
    /// @dev Put a monster up for auction to be sire.
    ///  Performs checks to ensure the monster can be sired, then
    ///  delegates to reverse auction.
    function createSiringAuction(
        uint256 _monsterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        // Auction contract checks input sizes
        // If monster is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(_owns(msg.sender, _monsterId));
        require(isReadyToBreed(_monsterId));
        _approve(_monsterId, siringAuction);
        // Siring auction throws if inputs are invalid and clears
        // transfer and sire approval after escrowing the kitty.
        siringAuction.createAuction(
            _monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
    
    /// @dev Completes a siring auction by bidding.
    ///  Immediately breeds the winning matron with the sire on auction.
    /// @param _sireId - ID of the sire on auction.
    /// @param _matronId - ID of the matron owned by the bidder.
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
        // Auction contract checks input sizes
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        // Define the current price of the auction.
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

        // Siring auction will throw if the bid fails.
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }


    
}

/// @title all functions related to creating monsters
contract MonsterMinting is MonsterAuction {

    // Limits the number of monsters the contract owner can ever create.
    uint256 public constant PROMO_CREATION_LIMIT = 1000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;

    uint256 public constant GEN0_STARTING_PRICE = 1 ether;
    uint256 public constant GEN0_ENDING_PRICE = 0.1 ether;
    uint256 public constant GEN0_AUCTION_DURATION = 30 days;


    // Counts the number of monsters the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;


    /// @dev we can create promo monsters, up to a limit. Only callable by COO
    /// @param _genes the encoded genes of the monster to be created, any value is accepted
    /// @param _owner the future owner of the created monsters. Default to contract COO
    function createPromoMonster(uint256 _genes, uint256 _battleGenes, uint256 _level, address _owner) external onlyCOO {
        address monsterOwner = _owner;
        if (monsterOwner == address(0)) {
             monsterOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createMonster(0, 0, 0, _genes, _battleGenes, _level, monsterOwner);
    }
    
    /// @dev Creates a new gen0 monster with the given genes and
    ///  creates an auction for it.
    function createGen0AuctionCustom(uint _genes, uint _battleGenes, uint _level, uint _startingPrice, uint _endingPrice, uint _duration) external onlyCOO {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint256 monsterId = _createMonster(0, 0, 0, _genes, _battleGenes, _level, address(this));
        _approve(monsterId, saleAuction);

        saleAuction.createAuction(
            monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            address(this)
        );

        gen0CreatedCount++;
    }
}

/// @title MonsterBit: Collectible, breedable, and monsters on the Ethereum blockchain.
/// @dev The main MonsterBit contract, keeps track of monsters so they don't wander around and get lost.
contract MonsterCore is MonsterMinting {

    // This is the main MonsterBit contract. In order to keep our code seperated into logical sections,
    // we've broken it up in two ways. First, we have several seperately-instantiated sibling contracts
    // that handle auctions and our super-top-secret genetic combination algorithm. The auctions are
    // seperate since their logic is somewhat complex and there's always a risk of subtle bugs. By keeping
    // them in their own contracts, we can upgrade them without disrupting the main contract that tracks
    // monster ownership. The genetic combination algorithm is kept seperate so we can open-source all of
    // the rest of our code without making it _too_ easy for folks to figure out how the genetics work.
    // Don't worry, I'm sure someone will reverse engineer it soon enough!
    //
    // Secondly, we break the core contract into multiple files using inheritence, one for each major
    // facet of functionality of CK. This allows us to keep related code bundled together while still
    // avoiding a single giant file with everything in it. The breakdown is as follows:
    //
    //      - MonsterBase: This is where we define the most fundamental code shared throughout the core
    //             functionality. This includes our main data storage, constants and data types, plus
    //             internal functions for managing these items.
    //
    //      - MonsterAccessControl: This contract manages the various addresses and constraints for operations
    //             that can be executed only by specific roles. Namely CEO, CFO and COO.
    //
    //      - MonsterOwnership: This provides the methods required for basic non-fungible token
    //             transactions, following the draft ERC-721 spec (https://github.com/ethereum/EIPs/issues/721).
    //
    //      - MonsterBreeding: This file contains the methods necessary to breed monsters together, including
    //             keeping track of siring offers, and relies on an external genetic combination contract.
    //
    //      - MonsterAuctions: Here we have the public methods for auctioning or bidding on monsters or siring
    //             services. The actual auction functionality is handled in two sibling contracts (one
    //             for sales and one for siring), while auction creation and bidding is mostly mediated
    //             through this facet of the core contract.
    //
    //      - MonsterMinting: This final facet contains the functionality we use for creating new gen0 monsters.
    //             We can make up to 5000 "promo" monsters that can be given away (especially important when
    //             the community is new), and all others can only be created and then immediately put up
    //             for auction via an algorithmically determined starting price. Regardless of how they
    //             are created, there is a hard limit of 50k gen0 monsters. After that, it's all up to the
    //             community to breed, breed, breed!

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main MonsterBit smart contract instance.
    constructor(address _ceoBackupAddress) public {
        require(_ceoBackupAddress != address(0));
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;
        ceoBackupAddress = _ceoBackupAddress;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It's up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it's from one of the
    ///  two auction contracts. (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(
            msg.sender == address(saleAuction)
            ||
            msg.sender == address(siringAuction)
            ||
            msg.sender == address(battlesContract)
            ||
            msg.sender == address(monsterFood)
        );
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(monsterFood != address(0));
        require(battlesContract != address(0));
        require(geneScience != address(0));
        require(monsterStorage != address(0));
        require(monsterConstants != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    // @dev Allows the CFO to capture the balance available to the contract.
    function withdrawBalance() external onlyCFO {
        uint256 balance = address(this).balance;
        
        uint256 subtractFees = (monsterStorage.pregnantMonsters() + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.transfer(balance - subtractFees);
        }

    }
    
    /// @dev Transfers the balance of the sale auction contract
    /// to the MonsterCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawDependentBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
        battlesContract.withdrawBalance();
        monsterFood.withdrawBalance();
    }
}