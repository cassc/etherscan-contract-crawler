// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Interfaces/ICaster.sol";
import "./Curse.sol";


contract SpellBook is AccessControl, Pausable {
    using Address for address;
    using SafeERC20 for IERC20;

    struct IEffectData {
        uint256 countdown;
        uint8 effectId;
    }

    struct ISpellConfig {
        uint256 costBase;
        uint256 costDiscountPerLvl;

        uint256 cooldownBase;
        uint256 cooldownDiscountPerLvl;

        uint256 effectBase;
        uint256 effectMultiplierPerLvl;

        uint8 minLvlToCast;
        uint8 xpRewardPerCast;
    }
    // Generic constants
    uint8 public constant MAX_LEVEL = 3;
    // ACL constants
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Spell constants
    uint8 public constant SPELL_FREEZE = 0;
    uint8 public constant SPELL_PROTECT = 1;
    uint8 public constant SPELL_DISPEL = 2;
    uint8 public constant SPELL_MINT = 3;
    uint8 public constant SPELL_BURN = 4;
    uint8 public constant SPELL_STEAL = 5;
    uint8 public constant SPELL_INFLATE = 6;
    uint8 public constant SPELL_DEFLATE = 7;
    uint8 public constant SPELL_DOMINATE = 8;

    uint8 public constant NUM_OF_SPELLS = 9;

    // Effect constants
    uint8 public constant EFFECT_COOLDOWN = 0;
    uint8 public constant EFFECT_FREEZE = 1;
    uint8 public constant EFFECT_PROTECT = 2;
    uint8 public constant EFFECT_STOLEN = 3;
    uint8 public constant EFFECT_IMMUNE = 4; // Only for dev, to protect UniswapPair and contract address

    uint8 public constant EFFECT_TOTAL = 5;

    // Price selector
    uint8 public constant PRICE_SPELLBOOK_ETH = 0;
    uint8 public constant PRICE_SPELLBOOK_CURSE = 1;

    // Generic config variables
    address public _feeWallet;
    address public _curseBeneficiary;

    uint256 public refreshPrice;
    
    uint256[MAX_LEVEL] public lvlUpPrice;
    uint256[MAX_LEVEL] public lvlUpXp;

    uint256[2] public baseSpellBookPrice;

    // Spell config variables
    ISpellConfig[NUM_OF_SPELLS] public spellConfig;

    IERC20 public CURSE;
    ICaster public CASTER;

    event SpellConfigUpdated(uint8 indexed spellId);
    event SpellCasted(address indexed caster, address indexed target, uint8 indexed spellId, uint256 effect);
    event LevelUp(address indexed caster, uint8 newLevel);
    event SpellBookBought(address indexed owner);

    constructor(address casterData) {
        address _owner = _msgSender();
        _grantRole(ADMIN_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        CASTER = ICaster(casterData);

        _feeWallet = _owner;
        // Default CURSE holder is spellbook
        _curseBeneficiary = address(this);

        // Default spellbook price
        baseSpellBookPrice[PRICE_SPELLBOOK_ETH] = 0.025 ether; // 0.025 ETHER
        baseSpellBookPrice[PRICE_SPELLBOOK_CURSE] = 500 ether; // 500 CURSE

        // Default cooldown refresh price
        refreshPrice = 0.015 ether;

        // Default level up prices
        lvlUpPrice[0] = 0.025 ether; // lvl 0 -> 1
        lvlUpPrice[1] = 0.05 ether; // lvl 1 -> 2
        lvlUpPrice[2] = 0.075 ether; // lvl 2 -> 3

        // Default level up XP required
        lvlUpXp[0] = 100; // lvl 0 -> 1
        lvlUpXp[1] = 200; // lvl 1 -> 2
        lvlUpXp[2] = 400; // lvl 2 -> 3

    }
    /**
      * Modifiers
     */
    modifier onlySpellBook(address caster) {
        require(hasSpellBook(caster), "Spellbook missing");
        _;
    }
    
    modifier notProtected(address target) {
        require(!isProtected(target), "Target protected");
        _;
    }

    modifier noCooldown(address caster) {
        require(!hasCooldown(caster), "On cooldown");
        _;
    }

    /**
      Internal helpers
     */
    function getCooldown(ISpellConfig memory spell, uint8 level) internal pure returns (uint256) {
        uint256 discount = (uint256(level) * spell.cooldownDiscountPerLvl);
        return spell.cooldownBase > discount? spell.cooldownBase - discount : spell.cooldownBase;
    }

    function getEffect(ISpellConfig memory spell, uint8 level) internal pure returns  (uint256) {
        uint256 multiplier = (uint256(level) * spell.effectMultiplierPerLvl);
        return spell.effectBase + multiplier;
    }
    
    function getPrice(ISpellConfig memory spell, uint8 level) internal pure returns (uint256){
        uint256 discount = (uint256(level) * spell.costDiscountPerLvl);
        return spell.costBase > discount? spell.costBase - discount : spell.costBase;
    }

    function setCooldown(address caster, ISpellConfig memory spell, uint8 level) internal returns (uint256) {
        uint256 duration = getCooldown(spell, level);
        CASTER.setEffect(caster, EFFECT_COOLDOWN, duration);
        return duration;
    }

    function setEffect(address caster, uint8 effectId, ISpellConfig memory spell, uint8 level) internal returns (uint256) {
        uint256 duration = getEffect(spell, level);
        CASTER.setEffect(caster, effectId, duration);
        return duration;
    }

    function ensureCurseBalance(uint256 price, address caster) internal view {
        if (price > 0) {
            require(CURSE.balanceOf(caster) >= price, "Insufficient balance");
        }
    }

    function takeCurseFee(uint256 price, address caster) internal {
        if (price > 0) {
            require(CURSE.balanceOf(caster) >= price, "Insufficient balance");
            // Transfer the amount
            CURSE.safeTransferFrom(caster, _curseBeneficiary, price);
        }
    }

    function clearEffect(address caster, uint8 effectId) internal {
        if (CASTER.hasEffect(caster, effectId)) CASTER.clearEffect(caster, effectId);
    }

    /**
      * Management functions
     */
    
    function pause() public onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function setCurseToken(address addr) external onlyRole(ADMIN_ROLE) {
        CURSE = IERC20(addr);
        setPermanentProtection(addr, true);
    }
    
    function promoteAdmin(address newAdmin) public onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, newAdmin);
        //_setRoleAdmin(DEFAULT_ADMIN_ROLE, newAdmin);
        // TODO: remove the old admin
        setPermanentProtection(newAdmin, true);
    }

    function setLvlUpConfig(uint256[MAX_LEVEL] memory price, uint256[MAX_LEVEL] memory xpRequired) external onlyRole(ADMIN_ROLE) {
        lvlUpPrice = price;
        lvlUpXp = xpRequired;
    }

    function setFeeWallet(address addr) external onlyRole(ADMIN_ROLE) {
        _feeWallet = addr;
        
    }

    function setCurseBeneficiary(address addr) external onlyRole(ADMIN_ROLE) {
        _curseBeneficiary = addr;
    }

    function setSpellConfig(
        uint8 spellId,
        uint256 costBase,
        uint256 costDiscountPerLvl,
        uint256 cooldownBase,
        uint256 cooldownDiscountPerLvl,
        uint256 effectBase,
        uint256 effectMultiplierPerLvl,
        uint8 minLvlToCast,
        uint8 xpRewardPerCast
    ) public onlyRole(ADMIN_ROLE) {
        require(spellId < NUM_OF_SPELLS, "Out of range");

        spellConfig[spellId].costBase = costBase;
        spellConfig[spellId].costDiscountPerLvl = costDiscountPerLvl;
        spellConfig[spellId].cooldownBase = cooldownBase;
        spellConfig[spellId].cooldownDiscountPerLvl = cooldownDiscountPerLvl;
        spellConfig[spellId].effectBase = effectBase;
        spellConfig[spellId].effectMultiplierPerLvl = effectMultiplierPerLvl;
        spellConfig[spellId].minLvlToCast = minLvlToCast;
        spellConfig[spellId].xpRewardPerCast = xpRewardPerCast;

        emit SpellConfigUpdated(spellId);
    }

    function setSpellBookBasePrice(uint256 ethPrice, uint256 cursePrice) external onlyRole(ADMIN_ROLE) {
        baseSpellBookPrice[PRICE_SPELLBOOK_ETH] = ethPrice;
        baseSpellBookPrice[PRICE_SPELLBOOK_CURSE] = cursePrice;
    }

    function setRefreshPrice(uint256 price) external onlyRole(ADMIN_ROLE) {
        refreshPrice = price;
    }

    function setPermanentProtection(address addr, bool enabled) public onlyRole(ADMIN_ROLE) {
        if (enabled) {
            // Permanent protection is ~10 year
            CASTER.setEffect(addr, EFFECT_IMMUNE, 315360000);
        } else {
            CASTER.clearEffect(addr, EFFECT_IMMUNE);
        }

    }

    function sendEth() external {
        payable(_feeWallet).transfer(address(this).balance);
    }

    function sendCurse(address receiver) external onlyRole(ADMIN_ROLE) {   
        require(receiver != address(this), "Invalid receiver");
        uint256 balance = CURSE.balanceOf(address(this));
        if (balance > 0) {
            CURSE.transfer(receiver, balance);
        }
    }



    /**
      * Public getter functions
     */

    function totalSpells() public pure returns (uint8) {
        return NUM_OF_SPELLS;
    }

    function canLevelUp(address caster) public view returns (bool) {
        ICaster.SpellBookData memory book = CASTER.get(caster);
        uint8 level = CASTER.getLevel(caster);
        if (
            hasSpellBook(caster) &&
            level < MAX_LEVEL &&
            book.currentXp >= lvlUpXp[level]
        ) {
            return true;
        }
        return false;
    }

    function getLevel(address caster) public view returns (uint8) {
        return CASTER.getLevel(caster);
    }

    function getLevelUpPriceXp(address caster) public view returns (uint256, uint256) {
        uint8 level = CASTER.getLevel(caster);
        uint8 correctedLevel = level < MAX_LEVEL? level : level - 1;
        return (
            lvlUpPrice[correctedLevel],
            lvlUpXp[correctedLevel]
        );
    }

    function getSpell(address caster, uint8 spellId) public view returns (
        uint256 cost,
        uint256 cooldown,
        uint256 effect,
        uint256 xpReward,
        bool canCast
    ) {
        ISpellConfig memory spell = spellConfig[spellId];
        uint8 level = CASTER.getLevel(caster);

        cost = getPrice(spell, level);
        cooldown = getCooldown(spell, level);
        effect = getEffect(spell, level);
        xpReward = spell.xpRewardPerCast;
        canCast = level >= spell.minLvlToCast;
    }

    function hasSpellBook(address caster) public view returns (bool) {
        ICaster.SpellBookData memory book = CASTER.get(caster);
        return book.createdAt > 0;
    }

    function getSpellBook(address caster) external view returns (
        uint256 currentXp,
        uint256 createdAt,
        uint8 level
    ) {
        ICaster.SpellBookData memory book = CASTER.get(caster);

        currentXp = book.currentXp;
        createdAt = book.createdAt;
        level = book.level;
    }
    
    /**
      Public setter
     */

    function buySpellBookEth() external payable whenNotPaused {
        address caster = _msgSender();
        require(!hasSpellBook(caster), "Already have");
        require(msg.value >= baseSpellBookPrice[PRICE_SPELLBOOK_ETH], "SB: insufficient amount");        
        // Create the new SpellBook
        CASTER.create(caster);

        emit SpellBookBought(caster);
        
    }
    
    function buySpellBookCurse() external whenNotPaused {
        address caster = _msgSender();
        require(!hasSpellBook(caster), "Already have");
        uint256 price = baseSpellBookPrice[PRICE_SPELLBOOK_CURSE];

        if (price > 0) {
            require(CURSE.balanceOf(caster) >= price, "Insufficient balance");
            // Transfer the amount
            CURSE.safeTransferFrom(caster, _curseBeneficiary, price);
        }
        // Create the new SpellBook
        CASTER.create(caster);
        
        emit SpellBookBought(caster);
    }

    function levelUp() external payable onlySpellBook(_msgSender()) whenNotPaused {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);

        require(canLevelUp(caster), "Cannot level up");        
        (uint256 price,) = getLevelUpPriceXp(caster);
        require(msg.value >= price, "Insufficient amount");
        // XP is alredy check in canLevelUp, so it has to be greater or equal with the required XP level, not possible to overflow
        uint8 newLevel = book.level + 1;
        CASTER.setXp(caster, book.currentXp - lvlUpXp[book.level]);
        CASTER.setLevel(caster, newLevel);

        emit LevelUp(caster, newLevel);
    }

    function refresh() external payable onlySpellBook(_msgSender()) whenNotPaused {
        address caster = _msgSender();
        require(hasCooldown(caster), "On cooldown");
        require(msg.value >= refreshPrice, "Insufficient amount");     
        clearEffect(caster, EFFECT_COOLDOWN);
    }

    /**
        Effects
     */
    function getEffects(address caster) public view returns (IEffectData[] memory) {
        uint8 activeEffects = 0;
        for(uint8 i = 0; i < EFFECT_TOTAL; ++i) if (CASTER.hasEffect(caster, i)) activeEffects++;

        IEffectData[] memory effects = new IEffectData[](activeEffects);

        uint8 counter = 0;
        for(uint8 i = 0; i < EFFECT_TOTAL; ++i) {
            if (CASTER.hasEffect(caster, i)) {
                (uint256 timestamp, uint256 duration) = CASTER.getEffect(caster, i);
                effects[counter].effectId = i;
                effects[counter].countdown = (timestamp + duration) - block.timestamp;
                counter ++;
            }            
        }
        return effects;
    }

    function hasCooldown(address caster) public view returns (bool) {
        return CASTER.hasEffect(caster, EFFECT_COOLDOWN);
    }


    function isProtected(address target) public view returns (bool) {
        return CASTER.hasEffect(target, EFFECT_PROTECT) || CASTER.hasEffect(target, EFFECT_IMMUNE);
    }


    // This spell will froze an account balance for a certain time (unable to sell/transfer), can be cured by buying some token
    // Payed by token
    function castFreeze(address target) public onlySpellBook(_msgSender()) whenNotPaused notProtected(target) noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_FREEZE];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Freeze the target
        uint256 duration = setEffect(target, EFFECT_FREEZE, spell, book.level);

        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, target, SPELL_FREEZE, duration);
    }

    function castProtect() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_PROTECT];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Protect the caster
        uint256 duration = setEffect(caster, EFFECT_PROTECT, spell, book.level);

        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, caster, SPELL_PROTECT, duration);
    }

    function castDispel(address target) public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_DISPEL];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Remove effects from target
        clearEffect(target, EFFECT_FREEZE);
        clearEffect(target, EFFECT_PROTECT);
        clearEffect(target, EFFECT_STOLEN);

        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, target, SPELL_DISPEL, 0);
    }
    
    function castMint() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_MINT];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.conjuration(caster, percentage);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, caster, SPELL_MINT, percentage);
    }

    function castBurn(address target) public onlySpellBook(_msgSender()) whenNotPaused notProtected(target) noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_BURN];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.invocation(target, percentage);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, target, SPELL_BURN, percentage);
    }

    function castSteal(address target) public onlySpellBook(_msgSender()) whenNotPaused notProtected(target) noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_STEAL];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.necromancy(target, caster, percentage);

        // Steal will give a unique effect to the caster for 1 hour
        CASTER.setEffect(caster, EFFECT_STOLEN, 1 hours);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, target, SPELL_STEAL, percentage);
    }
    
    function castInflate() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_INFLATE];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.alteration(percentage);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, address(0), SPELL_INFLATE, percentage);
    }

    function castDeflate() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_DEFLATE];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        uint256 percentage = getEffect(spell, book.level);
        curse.divination(percentage);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, address(0), SPELL_DEFLATE, percentage);
    }

    function castDominate() public onlySpellBook(_msgSender()) whenNotPaused noCooldown(_msgSender()) {
        address caster = _msgSender();
        ICaster.SpellBookData memory book = CASTER.get(caster);
        ISpellConfig memory spell = spellConfig[SPELL_DOMINATE];

        // Calculate the price, and give discount based on level
        uint256 price = getPrice(spell, book.level);

        require(book.level >= spell.minLvlToCast, "Insufficient level");
        ensureCurseBalance(price, caster);

        // Cast the address to a specific instance interface
        address payable curseAddr = payable(address(CURSE));
        Curse curse = Curse(curseAddr);

        curse.illusion(caster);
        
        CASTER.setXp(caster, book.currentXp + spell.xpRewardPerCast);
        // Calculate the cooldown based on level
        setCooldown(caster, spell, book.level);

        emit SpellCasted(caster, caster, SPELL_DOMINATE, 0);
    }

    receive() external payable {}
}