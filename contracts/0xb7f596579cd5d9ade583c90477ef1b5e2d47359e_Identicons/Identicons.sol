/**
 *Submitted for verification at Etherscan.io on 2023-07-03
*/

// SPDX-License-Identifier: MiT
// Author: tycoon.eth
// v0.0.2
pragma solidity ^0.8.19;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

/**

(_____ \           | |
 _____) )   _ ____ | |  _
|  ____/ | | |  _ \| |_/ )
| |    | |_| | | | |  _ (
|_|    |____/|_| |_|_| \_)

 _     _                  _
| |   | |             _  (_)
| | __| |_____ ____ _| |_ _  ____ ___  ____   ___
| |/ _  | ___ |  _ (_   _) |/ ___) _ \|  _ \ /___)
| ( (_| | ____| | | || |_| ( (__| |_| | | | |___ |
|_|\____|_____)_| |_| \__)_|\____)___/|_| |_(___/

Punk Identicons - generate punks based on a random number, such as an Ethereum
address (which is a 160-bit number).

Uses punkblocks to source the traits and assemble them on an SVG.

*/

contract Identicons {

    IPunkBlocks pb = IPunkBlocks(0x829e113C94c1acb6b1b5577e714E486bb3F86593);
    struct Trait {
        bytes32 hash;   // The hash of the name
        uint128 sample; // count of occurrences in a population
        uint128 list;   // which group (will use the block's default layer if list is 0)
    }
    struct Config {
        Trait[18] superRare;     // Rare base traits. Like a mapping, leadingZeros => Trait.
        Trait[] baseTraits;      // Base traits, male & female
        Trait[][13] largeTraits; // the "male" traits, grouped by lists to choose from
        Trait[][13] smallTraits; // the "female" traits, grouped by lists to choose from
        uint256 population;
        uint32 orderConfigId;         // the orderConfig from the punk-blocks contract
    }
    uint64 public nextConfigId;
    mapping (uint64 => Config) private cfg;
    event NewConfig(uint64);
    constructor() {
    }

    function config(uint64 c) view public returns (Config memory) {
        return cfg[c];
    }

    /**
    * @dev Set a new configuration for picking
    * @param _superRare The super-rare traits assigned depending on the number
    *    of leading zeros. Each trait.sample sets how many zeros will be required
    *    to match the trait.
    * @param _baseTraits. A list of all the faces, aka "base traits". These
    *    will be used to determine the type of the punk and traits will be
    *    drawn on top.
    * @param _largeTraits. A list of all the large (typically male) traits to
    *    choose from.
    * @param _smallTraits. A list of all the small (typically female) traits to
    *    choose from.
    * @param _population the total population.
    */
    function setConfig(
        Trait[] calldata _superRare,
        Trait[] calldata _baseTraits,
        Trait[] calldata _largeTraits,
        Trait[] calldata _smallTraits,
        uint256 _population,
        uint32 _orderConfigId
    ) external {
        uint256 info;
        Config storage c = cfg[nextConfigId];
        c.orderConfigId = _orderConfigId;
        for (uint256 i = 0; i < _superRare.length; i++) {
            require(_superRare[i].sample <= _population, "sample too big");
            info = pb.blocksInfo(_superRare[i].hash);
            require(info > 0, "superare block not found");
            c.superRare[_superRare[i].sample] = _superRare[i]; // key by sample (leading zeros)
        }
        for (uint256 i = 0; i < _baseTraits.length; i++) {
            require(_baseTraits[i].sample <= _population, "sample too big");
            info = pb.blocksInfo(_baseTraits[i].hash);
            require(info > 0, "base block not found");
            c.baseTraits.push(_baseTraits[i]);
        }
        for (uint256 i = 0; i < _largeTraits.length; i++) {
            require(_largeTraits[i].sample <= _population, "sample too big");
            info = pb.blocksInfo(_largeTraits[i].hash);
            require(info > 0, "large block not found");
            if (_largeTraits[i].list > 0) {
                info = _largeTraits[i].list;                   // overwrite with a custom layer value
            }
            c.largeTraits[uint8(info)].push(_largeTraits[i]);
        }
        for (uint256 i = 0; i < _smallTraits.length; i++) {
            require(_smallTraits[i].sample <= _population, "sample too big");
            info = pb.blocksInfo(_smallTraits[i].hash);
            require(info > 0, "small block not found");
            if (_smallTraits[i].list > 0) {
                info = _smallTraits[i].list;                   // overwrite with a custom layer value
            }
            c.smallTraits[uint8(info)].push(_smallTraits[i]);
        }
        c.population = _population;
        emit NewConfig(nextConfigId);
        nextConfigId++;
    }

    /**
    * @dev Pick a base layer (male, female, zombie, ape, etc)
    * @param _entropy random value
    * @param _cid config id
    */
    function _pickBase(
        uint256 _entropy,
        uint64 _cid
    ) internal view returns (uint256 baseIndex) {
        uint256 size = cfg[_cid].baseTraits.length;
        uint16 i =  uint16(_uniform(_entropy, size));
        uint n;
        while (true) {
            n = _uniform(_entropy, cfg[_cid].population);
            if (cfg[_cid].baseTraits[i].sample >= n) {
                baseIndex = i;
                break;
            }
            i++;
            if (i == size) {
                i = 0; // wrap around, keep picking
            }
            _entropy = uint256(keccak256(abi.encodePacked(_entropy)));
        }
        return baseIndex;
    }

    /**
    * @dev pick a super-rare trait, depending on how many leading zeros _a has
    * @param _a a random number used for the seed
    * @param _cid the config id
    * @return bytes32 hash of the chosen punk block
    */
    function _pickLeadingZeros(
        uint160 _a,
        uint64 _cid) internal view returns (bytes32) {
        uint16 leadingZeros;
        uint offset = 4;                  // each hex char is 4 bytes
        while (_a >> 160 - offset == 0) { // count leading 0's
            leadingZeros++;
            offset+=4;
        }
        return cfg[_cid].superRare[leadingZeros].hash;
    }

    /**
    * @dev generates a punk, picking traits using a random seed
    * @param _a the random seed
    * @param _cid the config id
    * @return string of the punk svg generated
    */
    function generate(
        address _a,
        uint64 _cid,
        uint16 _x,
        uint16 _y,
        uint16 _size
    ) view external returns (string memory) {
        bytes32[] memory traits = _generate(_a, _cid);
        string memory ret = pb.svgFromKeys(traits, _x, _y, _size, cfg[_cid].orderConfigId);
        return ret;
    }

    /**
    * @dev picks a punk, picking traits using a random seed, returning the
    *   hashes of the seeds.
    * @param _a the random seed
    * @param _cid the config id
    * @return bytes32[] representing the punk-block hashes.
    */
    function pick(
        address _a,
        uint64 _cid) view external returns (bytes32[] memory) {
        return _generate(_a, _cid);
    }

    function _generate(address _a, uint64 _cid) view internal returns (bytes32[] memory) {
        uint160 a = uint160(_a);
        bytes32[13] memory picks;
        picks[0] = _pickLeadingZeros(a, _cid);
        if (picks[0] == 0x0) {
            // pick a standard base, randomly
            picks[0] = cfg[_cid].baseTraits[_pickBase(a, _cid)].hash;
        }
        (, uint256 n, ) = pb.info(picks[0]);
        uint256 i = _uniform(a, 13);
        uint256 rolls;
        Trait[][13] storage pool;
        if (n > 0) {
            pool = cfg[_cid].largeTraits;
        } else {
            pool = cfg[_cid].smallTraits;
        }
        uint256 j;
        while (true) {
            // if layer has traits to pick and no trait been picked yet
            // then pick a trait and roll it.
            if (pool[i].length > 0 && picks[i] == 0x0) {
                j = _uniform(a, pool[i].length);           // roll a dice to choose starting pos
                uint256 count = 0;
                while (true) {
                    if (count==pool[i].length) {
                        break;
                    }
                    Trait memory rolled = pool[i][j];
                    a =  uint160(uint256(keccak256(abi.encodePacked(a))));
                    n = _uniform(a, cfg[_cid].population); // roll a dice to choose trait
                    if (rolled.sample >= n) {
                        picks[i] = rolled.hash;
                        break;
                    }
                    unchecked {
                        j++;
                        count++;
                    }
                    if (j ==  pool[i].length) {
                        j = 0;
                    }
                }
            }
            unchecked {rolls++;}
            if (rolls > 13) {
                break;
            }
            unchecked{i++;}
            if (i >= pool.length) {
                i=0;
            }
        }
        bytes32[] memory traits;
        j=0;
        for (i = 0; i < picks.length; i++) {
            if (picks[i] != 0x0) {
                assembly {
                    mstore (traits, add(mload(traits), 1)) // length++
                    mstore (0x40, add(mload(0x40), 0x20))  // move free memory ptr
                }
                traits[j] = picks[i];
                unchecked{j++;}
            }
        }
        return traits;
    }

    /**
    * Generate a uniform random number between 0 - _upperBound
    * See https://medium.com/hownetworks/dont-waste-cycles-with-modulo-bias-35b6fdafcf94
    */
    function _uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
        unchecked {
            uint256 negate = type(uint256).max - _upperBound + 1; // negate 2's compliment
            uint256 min = negate % _upperBound;
            while (true) {
                if (_entropy >= min) {
                    break;
                }
                _entropy = uint256(keccak256(abi.encodePacked(_entropy)));
            }
            return _entropy % _upperBound;
        }
    }
}

interface IPunkBlocks {
    enum Layer {
        Base,      //0 Base is the face. Determines if m or f version will be used to render the remaining layers
        Mouth,     //1 (Hot Lipstick, Smile, Buck Teeth, ...)
        Cheeks,    //2 (Rosy Cheeks)
        Blemish,   //3 (Mole, Spots)
        Eyes,      //4 (Clown Eyes Green, Green Eye Shadow, ...)
        Neck,      //5 (Choker, Silver Chain, Gold Chain)
        Beard,     //6 (Big Beard, Front Beard, Goat, ...)
        Ears,      //7 (Earring)
        HeadTop1,  //8 (Purple Hair, Shaved Head, Beanie, Fedora,Hoodie)
        HeadTop2,  //9 eg. sometimes an additional hat over hair
        Eyewear,   //10 (VR, 3D Glass, Eye Mask, Regular Shades, Welding Glasses, ...)
        MouthProp, //11 (Medical Mask, Cigarette, ...)
        Nose       //12 (Clown Nose)
    }
    function blocksInfo(bytes32) view external returns(uint256);
    function info(bytes32 _id) view external returns(Layer, uint16, uint16);
    function svgFromKeys(
        bytes32[] memory _attributeKeys,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID) external view returns (string memory);
}