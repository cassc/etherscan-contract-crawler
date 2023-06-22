// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/Base64.sol";

import {ERC721A, IERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title 1337 critters are pure 1/1 handcrafted animals living onchain
 * @author hoanh.eth & snjolfur.eth
 */

struct Critter {
    string variety;
    uint16 ctype;
    uint16 background;
    address image;
}

contract LeetCritter is ERC721A, ERC721AQueryable, Ownable {
    uint256 public immutable supply;

    bool public isOpen = false;
    bytes32 private merkleRoot = 0;

    mapping(address => bool) minted;

    string[] public backgroundsOptions;
    string[] public typesOptions;

    Critter[] private critters;

    uint16[] private remapIDs;
    uint16[] private shuffleIDs;
    uint256 private shuffleIndex;

    error MintClosed();
    error NotEqualLength();
    error NotEnoughLeft();
    error NotOnWhitelist();
    error MaxMint();
    error TokenDoesntExist();
    error ZeroBalance();
    error InvalidTraits();

    constructor(
        string memory name,
        string memory symbol,
        uint256 _supply,
        string[] memory _backgroundsOptions,
        string[] memory _typesOptions
    ) ERC721A(name, symbol) {
        supply = _supply;
        shuffleIDs = new uint16[](_supply);
        remapIDs = new uint16[](_supply);
        shuffleIndex = _supply;

        backgroundsOptions = _backgroundsOptions;
        typesOptions = _typesOptions;
    }

    /**
     * @notice Set minting status
     */
    function setMintStatus(bool state) external onlyOwner {
        isOpen = state;
    }

    /**
     * @notice Check if an address is on whitelist
     */
    function checkWhitelist(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(addr)));
    }

    /**
     * @notice Set whitelist using merkle proof
     */
    function setWhitelist(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    /**
     * @notice Whilelist mint
     */
    function whitelistMint(bytes32[] calldata merkleProof) public {
        if (!checkWhitelist(msg.sender, merkleProof)) revert NotOnWhitelist();
        if (minted[msg.sender]) revert MaxMint();

        helperMint(1);
    }

    /**
     * @notice Owner mint
     */
    function ownerMint(uint256 amount) public onlyOwner {
        helperMint(amount);
    }

    /**
     * @notice Add critters traits
     */
    function addCritters(
        string[] calldata _varieties,
        uint16[] calldata _types,
        uint16[] calldata _backgrounds,
        string[] calldata _traits
    ) public onlyOwner {
        if (_varieties.length != _types.length) revert NotEqualLength();
        if (_varieties.length != _backgrounds.length) revert NotEqualLength();
        if (_varieties.length != _traits.length) revert NotEqualLength();

        uint256 i = 0;
        Critter memory critter;
        do {
            critter.variety = _varieties[i];
            critter.ctype = _types[i];
            critter.background = _backgrounds[i];
            critter.image = SSTORE2.write(bytes(_traits[i]));

            critters.push(critter);
            unchecked {
                ++i;
            }
        } while (i < _varieties.length);
    }

    /**
     * @notice Build trait image
     */
    function buildImage(Critter memory critter) internal view returns (string memory image) {
        return Base64.encode(
            abi.encodePacked(
                '<svg id="critter" width="100%" height="100%" viewBox="0 0 20000 20000" xmlns="http://www.w3.org/2000/svg">',
                "<style>#critter{background-color:",
                backgroundsOptions[critter.background],
                ";background-image:url(data:image/png;base64,",
                string(SSTORE2.read(critter.image)),
                ");background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;}</style></svg>"
            )
        );
    }

    /**
     * @notice Build trait metadata
     */
    function buildMetadata(string memory key, string memory value) internal pure returns (string memory trait) {
        return string.concat('{"trait_type":"', key, '","value": "', value, '"}');
    }

    /**
     * @notice Build trait name
     */
    function buildName(string memory _type, string memory _variety) internal pure returns (string memory name) {
        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("Unique"))) {
            return _variety;
        }
        return string.concat(_type, " ", _variety);
    }

    /**
     * @notice Build metadata and assemble the corresponding token info
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory metadata)
    {
        if (!_exists(tokenId)) revert TokenDoesntExist();

        Critter memory critter = critters[remapIDs[tokenId]];
        string memory critterType = typesOptions[critter.ctype];

        bytes memory json = abi.encodePacked(
            '{"name": "',
            buildName(critterType, critter.variety),
            '", "description":"',
            "1337 critters are pure 1/1 handcrafted animals living onchain",
            '","image":"data:image/svg+xml;base64,',
            buildImage(critter),
            '",',
            '"attributes": [',
            buildMetadata("variety", critter.variety),
            ",",
            buildMetadata("type", critterType),
            ",",
            buildMetadata("background", backgroundsOptions[critter.background]),
            "]}"
        );

        return string(abi.encodePacked("data:application/json,", json));
    }

    /**
     * @notice Helper mint function
     */
    function helperMint(uint256 amount) internal {
        if (!isOpen) revert MintClosed();

        uint256 current = _totalMinted();
        unchecked {
            if ((current + amount) > supply) revert NotEnoughLeft();
        }

        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        for (uint8 i = 0; i < amount; i++) {
            remapIDs[current] = shuffle(random);
            ++current;
        }

        if (msg.sender != owner()) {
            minted[msg.sender] = true;
        }
        _safeMint(msg.sender, amount, "");
    }

    /**
     * @notice Shuffle random IDs from fixed population
     * Based on 0xDoubleSharp's algorithm
     * https://www.justinsilver.com/technology/programming/nft-mint-random-token-id/
     */
    function shuffle(uint256 random) internal returns (uint16 id) {
        if (shuffleIndex == 0) revert NotEnoughLeft();
        unchecked {
            uint256 lastIndex = --shuffleIndex;
            uint256 randomIndex = random % (lastIndex + 1);
            id = shuffleIDs[randomIndex] != 0 ? uint16(shuffleIDs[randomIndex]) : uint16(randomIndex);
            shuffleIDs[randomIndex] = shuffleIDs[lastIndex] == 0 ? uint16(lastIndex) : shuffleIDs[lastIndex];
            shuffleIDs[lastIndex] = 0;
        }
    }
}