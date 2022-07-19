// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import { ERC721MM } from "./ERC721MM.sol";

contract Items is ERC721MM {
    string constant public name   = "Meta & Magic Items";
    string constant public symbol = "ITEMS";

    mapping(uint256 => address) statsAddress;
    mapping(uint256 => uint256) bossSupplies;

    uint256 lastTokenIdMinted;

    /*///////////////////////////////////////////////////////////////
                        INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(address stats_1, address stats_2, address stats_3, address stats_4, address stats_5, address renderer_) external {
        require(msg.sender == _owner(), "not authorized");

        statsAddress[0] = stats_1;
        statsAddress[1] = stats_2;
        statsAddress[2] = stats_3;
        statsAddress[3] = stats_4;
        statsAddress[9] = stats_5;
        
        renderer = renderer_;

        // Setting boss drop supplies
        bossSupplies[1] = 1000; 
        bossSupplies[2] = 900; 
        bossSupplies[3] = 800;
        bossSupplies[4] = 700;
        bossSupplies[5] = 600;
        bossSupplies[6] = 500;
        bossSupplies[7] = 400;
        bossSupplies[8] = 300;
        bossSupplies[9] = 200;
    }

    function setLastTokenIdMinted(uint256 _tokenId) external {
        require(msg.sender == _owner(), "not authorized");
        lastTokenIdMinted = _tokenId;
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getStats(uint256 id_) external view virtual returns(bytes10[6] memory stats_) {    
        uint256 seed = entropySeed;
        require(seed != 0, "Not revealed");
        stats_ = StatsLike(statsAddress[id_ > 10000 ? 9 : (id_ % 4)]).getStats(_traits(seed, id_));
    }

    function isSpecial(uint256 id) external view returns(bool sp) {
        return _isSpecial(id, entropySeed);
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        uint256 seed = entropySeed;
        if (seed == 0) return RendererLike(renderer).getPlaceholder(2);
        return RendererLike(renderer).getUri(id, _traits(seed, id), _getCategory(id,seed));
    }

    /*///////////////////////////////////////////////////////////////
                             MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintDrop(uint256 boss, address to) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");

        id = _bossDropStart(boss) + bossSupplies[boss]--; // Note boss drops are predictable because the entropy seed is known

        _mint(to, id, 2);
    }

    function burnFrom(address from, uint256 id) external returns (bool) {
        require(auth[msg.sender], "not authorized");
        _burn(from, id);
        return true;
    }

    function mint(address to, uint256 amount, uint256 stage) external override returns(uint256 id) {
        require(auth[msg.sender], "not authorized");
        for (uint256 i = 0; i < amount; i++) {
            id = lastTokenIdMinted + 1;
            lastTokenIdMinted++;
            _mint(to, id, stage);     
        }
    }


    /*///////////////////////////////////////////////////////////////
                             TRAIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _traits(uint256 seed_, uint256 id_) internal pure override returns (uint256[6] memory traits) {
        require(seed_ != uint256(0), "seed not set");
        if (_isSpecial(id_, seed_)) return _getSpecialTraits(id_);

        traits = [_getTier(id_,   seed_, "LEVEL"), 
                  _getTier(id_,    seed_, "KIND"), 
                  _getTier(id_,    seed_, "MATERIAL"), 
                  _getTier(id_,    seed_, "RARITY"), 
                  _getTier(id_,    seed_, "QUALITY"),
                  _getElement(id_, seed_, "ELEMENT")];

        uint256 boss = _getBossForId(id_);
        if (boss > 0) {
            traits[1] = 10 + boss;
            traits[4] = 0; // Boss traits doesnt have material type
        }
    }

    function _getSpecialTraits(uint256 id_) internal pure returns (uint256[6] memory t) {
        uint256 spc = (id_ / 1250) + 1;
        
        uint256 traitIndcator = spc * 10 + spc;

        t = [traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator];
    }

    function _getElement(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 class_) {
        if (id_ % 4 == 3) return _getTier(id_, seed, "POTENCY");
        
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 

        if (rdn <= 50_0000) return 1;
        return (rdn % 5) + 2;
    }

    function _bossDropStart(uint256 boss) internal pure returns(uint256 start) {
        if (boss == 1) start = 10000;
        if (boss == 2) start = 11000;
        if (boss == 3) start = 11900;
        if (boss == 4) start = 12700;
        if (boss == 5) start = 13400;
        if (boss == 6) start = 14000;
        if (boss == 7) start = 14500;
        if (boss == 8) start = 14900;
        if (boss == 9) start = 15200;
    } 


    function _getBossForId(uint256 id) internal pure returns(uint256 boss) {
        if (id <= 10000) return 0;
        if (id <= 11000) return 1;
        if (id <= 11900) return 2;
        if (id <= 12700) return 3;
        if (id <= 13400) return 4;
        if (id <= 14000) return 5;
        if (id <= 14500) return 6;
        if (id <= 14900) return 7;
        if (id <= 15200) return 8;
        if (id <= 15400) return 9;
    }

    function _isSpecial(uint256 id, uint256 seed) internal pure returns (bool special) {
        uint256 rdn = _getRndForSpecial(seed);
        for (uint256 i = 0; i < 9; i++) {
            if (id == rdn + (1250 * i)) {
                special = true;
                break;
            }
        }
    }

    function _getSpecialCategory(uint256 id, uint256 seed) internal pure returns (uint256 spc) {
        uint256 num = (id / 1250) + 1;
        spc = num + 5 + (num - 1);
    }

    function _getCategory(uint256 id, uint256 seed) internal pure returns (uint256 cat) {
        // Boss Drop
        if (id > 10000) return cat = 4;
        if (_isSpecial(id, seed)) return _getSpecialCategory(id, seed);
        return 2;
    }

    function _getRndForSpecial(uint256 seed) internal pure virtual returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(seed, "SPECIAL"))) % 1250 + 1;
    }

}

interface RendererLike {
    function getUri(uint256 id, uint256[6] calldata traits, uint256 cat) external view returns (string memory meta);
    function getPlaceholder(uint256 cat) external pure returns (string memory meta);
}

interface StatsLike {
    function getStats(uint256[6] calldata attributes) external view returns (bytes10[6] memory stats_); 
}

interface VRFCoordinatorV2Interface {
    function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);
}