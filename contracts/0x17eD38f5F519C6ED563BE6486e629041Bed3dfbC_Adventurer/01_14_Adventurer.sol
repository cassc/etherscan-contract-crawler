// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Adventurer721.sol";

/**

 ________  ___    ___ ________  ___  ___  _______   ________  _________   
|\   __  \|\  \  /  /|\   __  \|\  \|\  \|\  ___ \ |\   ____\|\___   ___\ 
\ \  \|\  \ \  \/  / | \  \|\  \ \  \\\  \ \   __/|\ \  \___|\|___ \  \_| 
 \ \   ____\ \    / / \ \  \\\  \ \  \\\  \ \  \_|/_\ \_____  \   \ \  \  
  \ \  \___|/     \/   \ \  \\\  \ \  \\\  \ \  \_|\ \|____|\  \   \ \  \ 
   \ \__\  /  /\   \    \ \_____  \ \_______\ \_______\____\_\  \   \ \__\
    \|__| /__/ /\ __\    \|___| \__\|_______|\|_______|\_________\   \|__|
          |__|/ \|__|          \|__|                  \|_________|        
                                                                          


 * @title Adventurer
 * Adventurer - a contract for genesis non-fungible PX Quest Adventurer ERC721 Tokens.
 */

interface IChronos {
    function burn(address _from, uint256 _amount) external;

    function burnUnclaimed(address _from, uint256 _amount) external;

    function stake(
        address from,
        uint256 advId,
        uint256 util
    ) external;

    function updateReward(address _from, address _to) external;
}

contract Adventurer is Adventurer721 {
    struct AdvData {
        string name;
        string bio;
    }

    modifier AdvOwner(uint256 advId) {
        require(
            ownerOf(advId) == msg.sender,
            "Cannot interact with an Adventurer you do not own"
        );
        _;
    }

    IChronos public Chronos;

    uint256 public constant SUMMON_PRICE = 750 ether;
    uint256 public constant NAME_CHANGE_PRICE = 50 ether;
    uint256 public constant BIO_CHANGE_PRICE = 50 ether;
    bool public breedActive = false;

    mapping(uint256 => AdvData) public advData;

    event AdvBorn(uint256 advId, uint256 parent1, uint256 parent2);
    event NameChanged(uint256 advId, string advName);
    event BioChanged(uint256 advId, string advBio);

    constructor(
        address _whitelistAdmin,
        uint256 supply,
        uint256 genCount,
        uint256 fixCount,
        uint256 publicStart
    )
        Adventurer721(
            "PXQuest Adventurer",
            "PXQ",
            _whitelistAdmin,
            supply,
            genCount,
            fixCount,
            publicStart
        )
    {}

    function setChronosAddress(address ChronosAddress) external onlyOwner {
        Chronos = IChronos(ChronosAddress);
    }

    function summon(
        uint256 parent1,
        uint256 parent2,
        bool withdrawn
    ) external AdvOwner(parent1) AdvOwner(parent2) {
        require(breedActive, "Gen 2 summoning not yet active.");
        require(
            currentSupply < maxSupply,
            "Cannot summon any more adventurers"
        );
        require(
            parent1 < (maxGenCount + 1) && parent2 < (maxGenCount + 1),
            "Cannot summon a generation with the same generation."
        );
        require(parent1 != parent2, "Must select two unique summoners");
        // allow purchase with withdrawn or unwithdrawn
        if (withdrawn) {
            Chronos.burn(msg.sender, SUMMON_PRICE);
        } else {
            Chronos.burnUnclaimed(msg.sender, SUMMON_PRICE);
        }
        // we are 1 indexing
        uint256 advId = maxGenCount + gen2Count + 1;
        gen2Count++;
        _safeMint(msg.sender, advId);
        currentSupply++;
        // adv parents ID divisibility used to determine race of
        emit AdvBorn(advId, parent1, parent2);
    }

    function enableSummon() public onlyOwner {
        breedActive = true;
    }

    function stake(uint256 advId, uint256 util) external AdvOwner(advId) {
        Chronos.stake(msg.sender, advId, util);
    }

    function changeName(
        uint256 advId,
        string memory newName,
        bool withdrawn
    ) external AdvOwner(advId) {
        bytes memory n = bytes(newName);
        require(n.length > 0 && n.length < 25, "Invalid name length");
        require(
            sha256(n) != sha256(bytes(advData[advId].name)),
            "New name is same as current name"
        );

        if (withdrawn) {
            Chronos.burn(msg.sender, NAME_CHANGE_PRICE);
        } else {
            Chronos.burnUnclaimed(msg.sender, NAME_CHANGE_PRICE);
        }
        advData[advId].name = newName;
        emit NameChanged(advId, newName);
    }

    function changeBio(
        uint256 advId,
        string memory newBio,
        bool withdrawn
    ) external AdvOwner(advId) {
        if (withdrawn) {
            Chronos.burn(msg.sender, BIO_CHANGE_PRICE);
        } else {
            Chronos.burnUnclaimed(msg.sender, BIO_CHANGE_PRICE);
        }
        advData[advId].bio = newBio;
        emit BioChanged(advId, newBio);
    }

    function getAdvData(uint256 advId)
        external
        view
        returns (string memory, string memory)
    {
        return (advData[advId].name, advData[advId].bio);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        Chronos.updateReward(from, to);
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        Chronos.updateReward(from, to);
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }
}