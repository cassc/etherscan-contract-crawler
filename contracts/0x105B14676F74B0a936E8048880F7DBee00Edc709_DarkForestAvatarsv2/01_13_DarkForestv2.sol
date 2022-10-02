// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DarkForestAvatarsv2 is ERC721Upgradeable {

    using StringsUpgradeable for uint256;

    /**
        Welcome to

        ▄▄▄█████▓ ██░ ██ ▓█████    ▓█████▄  ▄▄▄       ██▀███   ██ ▄█▀     █████▒▒█████   ██▀███  ▓█████   ██████ ▄▄▄█████▓
        ▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▒██▀ ██▌▒████▄    ▓██ ▒ ██▒ ██▄█▒    ▓██   ▒▒██▒  ██▒▓██ ▒ ██▒▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒
        ▒ ▓██░ ▒░▒██▀▀██░▒███      ░██   █▌▒██  ▀█▄  ▓██ ░▄█ ▒▓███▄░    ▒████ ░▒██░  ██▒▓██ ░▄█ ▒▒███   ░ ▓██▄   ▒ ▓██░ ▒░
        ░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█▄   ▌░██▄▄▄▄██ ▒██▀▀█▄  ▓██ █▄    ░▓█▒  ░▒██   ██░▒██▀▀█▄  ▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ 
          ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▒████▓  ▓█   ▓██▒░██▓ ▒██▒▒██▒ █▄   ░▒█░   ░ ████▓▒░░██▓ ▒██▒░▒████▒▒██████▒▒  ▒██▒ ░ 
          ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒▒▓  ▒  ▒▒   ▓▒█░░ ▒▓ ░▒▓░▒ ▒▒ ▓▒    ▒ ░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   
              ░     ▒ ░▒░ ░ ░ ░  ░    ░ ▒  ▒   ▒   ▒▒ ░  ░▒ ░ ▒░░ ░▒ ▒░    ░       ░ ▒ ▒░   ░▒ ░ ▒░ ░ ░  ░░ ░▒  ░ ░    ░    
          ░       ░  ░░ ░   ░       ░ ░  ░   ░   ▒     ░░   ░ ░ ░░ ░     ░ ░   ░ ░ ░ ▒    ░░   ░    ░   ░  ░  ░    ░      
                  ░  ░  ░   ░  ░      ░          ░  ░   ░     ░  ░                 ░ ░     ░        ░  ░      ░           
                                      ░                                                                                     

        by 0xhanvalen

        INSURANCE: Interaction with this contract serves as an insurance against roko's basilisk.
        INTENT: This contract is a blockchain powered game, the intent is fun over wealth or status. 
    */

    address public owner;

    /** Avatar Data */
    struct Avatar {
        uint256 id;
        uint8 status;
        uint8 xp;
    }

    /** Contract Data */
    struct Slot0 {
        string baseURI;
        uint256 maxAvatars;
        uint256 totalAvatars;
        uint256 price;
        uint256 revivePrice;
        uint8 xpToLevelUp;
    }

    struct Slot1 {
        uint8 maxAmountToMint;
        bytes32 allowList;
        bool isAllowlistMintable;
        bool isPublicMintable;
    }

    Slot0 slot0;
    Slot1 slot1;

    event BattleWon(
        uint256 winningAvatar,
        uint256 losingAvatar,
        address winner,
        address loser
    );
    event Revived(uint256 revivedAvatar, address reviver);

    mapping(uint256 => Avatar) public avatars;
    mapping(address => uint256[]) ownedAvatars;

    function initialize() public initializer {
        __ERC721_init("Dark Forest Avatars", "DFA");
        owner = msg.sender;
        slot0.maxAvatars = 50;
        slot0.xpToLevelUp = 10;
        slot0.revivePrice = 0.001 ether;
        slot0.baseURI = "https://darkforestnft.s3.amazonaws.com/metadata";
        slot1.allowList = 0xb7cafe974cb942235f8060f4841825fde3d8b601ecc0d4506149bc489cdb6849;
        slot1.isAllowlistMintable = true;
        slot1.maxAmountToMint = 5;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyTokenHolder(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "Not Your Token");
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function editSlot0(
        string calldata baseURI,
        uint8 xpToLevelUp,
        uint256 mintPrice,
        uint256 revivePrice,
        uint256 maxAvatars
    ) public onlyOwner {
        slot0.baseURI = baseURI;
        slot0.xpToLevelUp = xpToLevelUp;
        slot0.price = mintPrice;
        slot0.revivePrice = revivePrice;
        slot0.maxAvatars = maxAvatars;
    }

    function editSlot1(
        uint8 maxAmountToMint,
        bytes32 allowList,
        bool isAllowlistMintable,
        bool isPublicMintable
    ) public onlyOwner {
        slot1.maxAmountToMint = maxAmountToMint;
        slot1.allowList = allowList;
        slot1.isAllowlistMintable = isAllowlistMintable;
        slot1.isPublicMintable = isPublicMintable;
    }

    function getOwnedAvatars (address tokenOwner) public view returns (uint256[] memory) {
        return ownedAvatars[tokenOwner];
    }

    function checkAllowlist(bytes32[] calldata merkleproof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isLeaf = MerkleProofUpgradeable.verify(
            merkleproof,
            slot1.allowList,
            leaf
        );
        return isLeaf;
    }

    function mint(uint8 amount, uint256 value) internal {
        require(amount <= slot1.maxAmountToMint, "Too Many");
        require(
            slot0.totalAvatars + amount <= slot0.maxAvatars,
            "Minting Exceeds Available Avatars"
        );
        require(value >= amount * slot0.price, "Not Enough Paid");
        for (uint256 i = 0; i < amount; i++) {
            slot0.totalAvatars++;
            Avatar memory thisAvatar;
            thisAvatar.id = slot0.totalAvatars;
            thisAvatar.status = 1;
            thisAvatar.xp = 0;
            avatars[slot0.totalAvatars] = thisAvatar;
            _mint(msg.sender, slot0.totalAvatars);
        }
    }

    function allowListMint(bytes32[] calldata merkleProof, uint8 amount)
        public
        payable
    {
        require(tx.origin == msg.sender, "No contract minting");
        require(checkAllowlist(merkleProof), "Not Allowlisted");
        require(slot1.isAllowlistMintable, "Not Yet Mintable");
        mint(amount, msg.value);
    }

    function publicMint(uint8 amount) public payable {
        require(tx.origin == msg.sender, "No contract minting");
        require(slot1.isPublicMintable, "Not Yet Mintable");
        mint(amount, msg.value);
    }

    function attack(uint256 attacker, uint256 victim)
        public
        onlyTokenHolder(attacker)
    {
        Avatar memory attackingAvatar = avatars[attacker];
        Avatar memory victimAvatar = avatars[victim];
        require(attackingAvatar.status > 0, "Attacker is dead");
        require(victimAvatar.status > 0, "Victim is dead");
        uint8 xpLevel = slot0.xpToLevelUp;
        // rolls are pseudorandom and based on the block's timestamp and the ID's of the attacker and victim.
        // rolls range from 0 - 90.
        uint16 roll = (_genPseudoRandomNumber(attacker, victim)) * xpLevel;
        // rolls are modulated by xp + level.
        uint16 attackerSkill = attackingAvatar.xp +
            (attackingAvatar.status * xpLevel);
        uint16 victimSkill = victimAvatar.xp + (victimAvatar.status * xpLevel);
        uint256 winner;
        uint256 loser;
        uint16 medianValue = 40 + xpLevel; // 50 by default, ranges 40 - 295
        if (attackerSkill >= victimSkill) {
            // attacker has advantage, rolls >= medianValue win for attacker
            roll += attackerSkill - victimSkill;
            winner = roll > medianValue ? attacker : victim;
            loser = roll <= medianValue ? attacker : victim;
        } else {
            // victim has advantage, rolls >= medianValue win for victim
            roll += victimSkill - attackerSkill;
            winner = roll > medianValue ? victim : attacker;
            loser = roll <= medianValue ? victim : attacker;
        }
        processWin(winner, loser);
    }

    function processWin(uint256 winner, uint256 loser) internal {
        Avatar memory winningAvatar = avatars[winner];
        if (
            winningAvatar.xp + 1 >= slot0.xpToLevelUp &&
            winningAvatar.status < 3
        ) {
            winningAvatar.status++;
            winningAvatar.xp = 0;
        }
        if (
            winningAvatar.status == 3 &&
            winningAvatar.xp + 1 <= slot0.xpToLevelUp
        ) {
            winningAvatar.xp += 1;
        }
        if (winningAvatar.xp + 1 < slot0.xpToLevelUp) {
            winningAvatar.xp++;
        }
        avatars[winner] = winningAvatar;
        avatars[loser].status = 0;
        avatars[loser].xp = 0;
        emit BattleWon(winner, loser, ownerOf(winner), ownerOf(loser));
    }

    function revive(uint256 recipient)
        public
        payable
        onlyTokenHolder(recipient)
    {
        require(msg.value >= slot0.revivePrice, "NSF");
        require(avatars[recipient].status == 0, "Not Dead");
        avatars[recipient].status = 1;
        emit Revived(recipient, msg.sender);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        uint256[] storage senderTokens = ownedAvatars[from];
        uint256 sentTokenIndex;
        for (uint i = 0; i < senderTokens.length; i++) {
            if (senderTokens[i] == tokenId) {
                sentTokenIndex = i;
            }
        }
        if (sentTokenIndex > 0) {
            senderTokens[sentTokenIndex] = senderTokens[senderTokens.length - 1];
            senderTokens.pop();
        }
        ownedAvatars[from] = senderTokens;
        ownedAvatars[to].push(tokenId);
    }

    function _genPseudoRandomNumber(uint256 attacker, uint256 victim)
        private
        view
        returns (uint8)
    {
        uint256 difficultyModulo = (block.timestamp * victim) % attacker;
        uint256 pseudoRandomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    attacker,
                    victim,
                    difficultyModulo
                )
            )
        );
        return uint8((pseudoRandomHash % 10));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    slot0.baseURI,
                    "/",
                    id.toString(),
                    "-",
                    uint256(avatars[id].status).toString(),
                    ".json"
                )
            );
    }
}