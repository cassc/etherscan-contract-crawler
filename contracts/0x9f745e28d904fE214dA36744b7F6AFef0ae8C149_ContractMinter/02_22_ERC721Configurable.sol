// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721} from "../ERC721.sol";
import {ERC721Burnable} from "../ERC721Burnable.sol";
import {ERC721Metadata} from "../ERC721Metadata.sol";
import {ERC721Pausable} from "../ERC721Pausable.sol";
import {ERC721Royalty} from "../ERC721Royalty.sol";
import {MintGate, MintHasEnded} from "../libraries/MintGate.sol";
import {Withdrawable} from "../utilities/Withdrawable.sol";

error InvalidMintKey();

abstract contract ERC721Configurable is ERC721, ERC721Burnable, ERC721Metadata, ERC721Pausable, ERC721Royalty, Withdrawable {

    // Limit of 4 active configurable mints defined by total number of uint16
    // values we can pack into ERC721A uint64 `aux` value
    // - 0 index counts as a key
    uint256 public constant MAX_MINT_KEY = 3;


    // Collection abides by normal max supply rules but we have the ability to
    // define up to 4 `sales` with different settings.
    // - Multi sale configuration is provided to enable CONFIGURABLE allowlist,
    //  giveaways etc. alongside the main mint sale at the same time.
    // - Includes the ability to modify any setting after deployment.
    struct SaleConfig {
        uint64 endsAt;
        uint32 maxMint;
        uint32 maxSupply;
        uint64 price;
        uint64 startsAt;
    }


    // Sale Key => Merkle Root Allowlist
    mapping(uint256 => bytes32) public _allowlists;

    // Sale Key => Configuration
    mapping(uint256 => SaleConfig) public _config;


    // Max collection wide mint per wallet
    uint256 public _maxMint;

    // Max collection supply
    uint256 public immutable _maxSupply;


    constructor(uint256 maxMint, uint256 maxSupply, string memory name, string memory symbol) ERC721(name, symbol) {
        _maxMint = maxMint;
        _maxSupply = maxSupply;
    }


    function _availableSupply() internal view virtual returns (uint256) {
        return _maxSupply - _totalMinted();
    }

    function _baseURI() internal override(ERC721, ERC721Metadata) view virtual returns (string memory) {
        return ERC721Metadata._baseURI();
    }

    function _packAux(uint16[4] memory unpacked) internal pure returns (uint64) {
        return uint64(unpacked[0]) << 0 | uint64(unpacked[1]) << 16 | uint64(unpacked[2]) << 32 | uint64(unpacked[3]) << 48;
    }

    function _unpackAux(uint64 packed) internal pure returns (uint16[4] memory) {
        return [
            uint16(packed >> 0),
            uint16(packed >> 16),
            uint16(packed >> 32),
            uint16(packed >> 48)
        ];
    }

    function deleteAllowlist(uint256 key) external onlyOwner {
        delete _allowlists[key];
    }

    function deleteConfig(uint256 key) external onlyOwner {
        delete _config[key];
    }

    function isAllowed(uint256 key, bytes32[] memory proof) external view returns (bool) {
        return MintGate.isAllowed(_msgSender(), proof, _allowlists[key]);
    }

    function mint(uint256 key, uint16 quantity) payable public whenNotPaused {
        mint(key, new bytes32[](0), quantity);
    }

    function mint(uint256 key, bytes32[] memory proof, uint16 quantity) payable public whenNotPaused {
        address buyer = _msgSender();
        SaleConfig memory config = _config[key];

        // Collection gate
        MintGate.maxMint(_maxMint, _numberMinted(buyer), quantity);

        // `SaleConfig` gates
        if (config.maxSupply == 0) {
            revert MintHasEnded();
        }

        MintGate.allowed(buyer, proof, _allowlists[key]);
        MintGate.open(config.endsAt, config.startsAt);
        MintGate.price(buyer, config.price, quantity, msg.value);

        uint256 available = _availableSupply();
        uint16[4] memory aux = _unpackAux(_getAux(buyer));

        // `SaleConfig` max supply is not allowed to exceed max collection supply
        if (available > config.maxSupply) {
            available = config.maxSupply;
        }

        MintGate.supply(available, config.maxMint, aux[key], quantity);

        unchecked {
            // `SaleConfig` max supply
            _config[key].maxSupply -= quantity;

            // Buyer minted counters
            aux[key] += quantity;

            _setAux(buyer, _packAux(aux));
        }

        _safeMint(buyer, quantity);
    }

    function setAllowlist(uint256 key, bytes32 root) public onlyOwner {
        if (key > MAX_MINT_KEY) {
            revert InvalidMintKey();
        }

        _allowlists[key] = root;
    }

    function setConfig(uint256 key, uint64 endsAt, uint32 maxMint, uint32 maxSupply, uint64 price, uint64 startsAt) public onlyOwner {
        if (key > MAX_MINT_KEY) {
            revert InvalidMintKey();
        }

        _config[key] = SaleConfig({
            endsAt: endsAt,
            maxMint: maxMint,
            maxSupply: maxSupply,
            price: price,
            startsAt: startsAt
        });
    }

    function setMaxMint(uint256 maxMint) public onlyOwner {
        _maxMint = maxMint;
    }

    function supportsInterface(bytes4 interfaceId) override(ERC721, ERC721Royalty) public view virtual returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC721Royalty.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) override(ERC721, ERC721Metadata) public view virtual returns(string memory) {
        return ERC721Metadata.tokenURI(tokenId);
    }
}