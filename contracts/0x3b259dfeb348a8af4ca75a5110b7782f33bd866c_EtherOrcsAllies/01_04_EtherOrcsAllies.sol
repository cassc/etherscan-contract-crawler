// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../ERC20.sol";
import "./ERC721.sol"; 
import "../interfaces/Interfaces.sol";

contract EtherOrcsAllies is ERC721 {

    uint256 constant startId = 5050;

    mapping(uint256 => Ally) public allies;
    mapping(address => bool) public auth;

    uint16 public shSupply;
    uint16 public ogSupply;
    uint16 public mgSupply;
    uint16 public rgSupply;

    ERC20 boneShards;

    MetadataHandlerAllies metadaHandler;

    address public castle;
    bool    public openForMint;
    
    bytes32 internal entropySauce;

    struct Ally {uint8 class; uint16 level; uint32 lvlProgress; uint16 modF; uint8 skillCredits; bytes22 details;}

    struct Shaman {uint8 body; uint8 featA; uint8 featB; uint8 helm; uint8 mainhand; uint8 offhand;}
    struct Ogre   {uint8 body; uint8 mouth; uint8 nose;  uint8 eyes; uint8 armor; uint8 mainhand; uint8 offhand;}
    struct Rogue  {uint8 body; uint8 face; uint8 boots; uint8 pants; uint8 shirt; uint8 hair; uint8 armor; uint8 mainhand; uint8 offhand;}

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(auth[msg.sender] || (msg.sender == tx.origin && size == 0), "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    function initialize(address ct, address bs, address meta) external {
        require(msg.sender == admin);

        castle = ct;
        boneShards = ERC20(bs);
        metadaHandler = MetadataHandlerAllies(meta);
    }

    function setAdmin(address admin_) external {
        require(msg.sender == admin);
        admin = admin_;
        auth[admin_] = true;
    }

    function setAuth(address add_, bool status) external {
        require(msg.sender == admin);
        auth[add_] = status;
    }

    function setMintOpen(bool open_) external {
        require(msg.sender == admin);
        openForMint = open_;
    }

    function tokenURI(uint256 id) external view returns(string memory) {
        Ally memory ally = allies[id];
        return metadaHandler.getTokenURI(id, ally.class, ally.level, ally.modF, ally.skillCredits, ally.details);
    }

    function mintRogues(uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            mintRogue();
        }
    }

    function mintRogue() public noCheaters {
        require(openForMint || auth[msg.sender], "not open for mint");
        boneShards.burn(msg.sender, 60 ether);

        _mintRogue(_rand());
    } 

    // function mintOgres(uint256 amount) external {
    //     for (uint256 i = 0; i < amount; i++) {
    //         mintOgre();
    //     }
    // }

    // function mintOgre() public noCheaters {
    //     require(openForMint || auth[msg.sender], "not open for mint");
    //     boneShards.burn(msg.sender, 60 ether);

    //     _mintOgre(_rand());
    // } 

    function pull(address owner_, uint256[] calldata ids) external {
        require (auth[msg.sender], "not auth");
        for (uint256 index = 0; index < ids.length; index++) {
            _transfer(owner_, msg.sender, ids[index]);
        }
        CastleLike(msg.sender).pullCallback(owner_, ids);
    }

    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external {
        require(auth[msg.sender], "not authorized");

        allies[id] = Ally({class: class_, level: level_, lvlProgress: lvlProgress_, modF: modF_, skillCredits: skillCredits_, details: details_});
    }

    function shaman(bytes22 details) external pure returns(Shaman memory sh) {
        uint8 body     = uint8(bytes1(details));
        uint8 featA    = uint8(bytes1(details << 8));
        uint8 featB    = uint8(bytes1(details << 16));
        uint8 helm     = uint8(bytes1(details << 24));
        uint8 mainhand = uint8(bytes1(details << 32));
        uint8 offhand  = uint8(bytes1(details << 40));

        sh.body     = body;
        sh.featA    = featA;
        sh.featB    = featB;
        sh.helm     = helm;
        sh.mainhand = mainhand;
        sh.offhand  = offhand;
    }

    function ogre(bytes22 details) external pure returns(Ogre memory og) {
        uint8 body     = uint8(bytes1(details));
        uint8 mouth    = uint8(bytes1(details << 8));
        uint8 nose     = uint8(bytes1(details << 16));
        uint8 eye      = uint8(bytes1(details << 24));
        uint8 armor    = uint8(bytes1(details << 32));
        uint8 mainhand = uint8(bytes1(details << 40));
        uint8 offhand  = uint8(bytes1(details << 48));

        og.body     = body;
        og.mouth    = mouth;
        og.nose     = nose;
        og.eyes     = eye;
        og.armor    = armor;
        og.mainhand = mainhand;
        og.offhand  = offhand;
    }

    function rogue(bytes22 details) external pure returns(Rogue memory rg) {
        uint8 body     = uint8(bytes1(details));
        uint8 face     = uint8(bytes1(details << 8));
        uint8 boots    = uint8(bytes1(details << 16));
        uint8 pants    = uint8(bytes1(details << 24));
        uint8 shirt    = uint8(bytes1(details << 32));
        uint8 hair     = uint8(bytes1(details << 40));
        uint8 armor    = uint8(bytes1(details << 48));
        uint8 mainhand = uint8(bytes1(details << 56));
        uint8 offhand  = uint8(bytes1(details << 64));

        rg.body     = body;
        rg.face     = face;
        rg.armor    = armor;
        rg.mainhand = mainhand;
        rg.offhand  = offhand;
        rg.boots    = boots;
        rg.pants    = pants;
        rg.shirt    = shirt;
        rg.hair     = hair;
    }

    function _mintOgre(uint256 rand) internal returns (uint16 id) {
        id = uint16(ogSupply + 3001 + startId); //check that supply is less than 3000
        require(ogSupply++ <= 3000, "max supply reached");

        // Getting Random traits
        uint8 body = uint8(_randomize(rand, "BODY", id) % 8) + 1; 

        uint8 mouth    = uint8(_randomize(rand, "MOUTH",    id) % 3) + 1 + ((body - 1) * 3); 
        uint8 nose     = uint8(_randomize(rand, "NOSE",     id) % 3) + 1 + ((body - 1) * 3); 
        uint8 eyes     = uint8(_randomize(rand, "EYES",     id) % 3) + 1 + ((body - 1) * 3); 
        uint8 armor    = uint8(_randomize(rand, "ARMOR",    id) % 6) + 1;
        uint8 mainhand = uint8(_randomize(rand, "MAINHAND", id) % 6) + 1; 
        uint8 offhand  = uint8(_randomize(rand, "OFFHAND",  id) % 6) + 1;

        _mint(msg.sender, id);

        allies[id] = Ally({class: 2, level: 30, lvlProgress: 30000, modF: 0, skillCredits: 100, details: bytes22(abi.encodePacked(body, mouth, nose, eyes, armor, mainhand, offhand))});
    }

    function _mintRogue(uint256 rand) internal returns (uint16 id) {
        id = uint16(rgSupply + 6001 + startId); //check that supply is less than 3000
        require(rgSupply++ <= 3000, "max supply reached");

        // Getting Random traits
        uint8 body = uint8(_randomize(rand, "BODY", id) % 2) + 1; 

        uint8 face     = uint8(_randomize(rand, "FACE",     id) % 10) + 1 + ((body - 1) * 10); 
        uint8 boots    = uint8(_randomize(rand, "BOOTS",    id) % 25) + 1;
        uint8 pants    = uint8(_randomize(rand, "PANTS",    id) % 21) + 1;
        uint8 shirt    = uint8(_randomize(rand, "SHIRT",    id) % 19) + 1;
        uint8 hair     = uint8(_randomize(rand, "HAIR",     id) % 21) + 1;

        _mint(msg.sender, id);

        allies[id] = Ally({class: 3, level: 30, lvlProgress: 30000, modF: 0, skillCredits: 100, details: bytes22(abi.encodePacked(body, face, boots, pants, shirt, hair, uint8(0), uint8(0), uint8(0)))});
    }

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
    }
}