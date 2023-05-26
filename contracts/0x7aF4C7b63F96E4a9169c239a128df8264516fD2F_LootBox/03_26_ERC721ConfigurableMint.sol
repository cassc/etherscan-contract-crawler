// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721, ERC721A, IERC721A} from "../ERC721.sol";
import {ERC721Pausable} from "./ERC721Pausable.sol";
import {MintGate, MintHasEnded} from "../libraries/MintGate.sol";
import {Withdrawable} from "../utilities/Withdrawable.sol";

error InvalidMintKey();

abstract contract ERC721ConfigurableMint is ERC721, ERC721Pausable, Withdrawable {

    // Limit of 4 active configurable mints defined by total number of uint16
    // values we can pack into ERC721A uint64 `aux` value
    // - 0 index counts as a key
    uint256 public constant MAX_MINT_KEY = 3;


    // Collection abides by normal max supply rules but we have the ability to
    // define up to 4 `sales` with different settings.
    // - Multi sale configuration is provided to enable CONFIGURABLE allowlist,
    //  giveaways etc. alongside the main mint sale at the same time.
    // - Includes the ability to modify any setting after deployment.
    struct Sale {
        uint64 endsAt;
        uint32 maxMint;
        uint32 maxSupply;
        uint64 price;
        uint64 startsAt;
    }


    // Sale Key => Merkle Root Allowlist
    mapping(uint256 => bytes32) public _allowlists;

    // Sale Key => Configuration
    mapping(uint256 => Sale) public _sales;


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

    function deleteSale(uint256 key) external onlyOwner {
        delete _sales[key];
    }

    function isAllowlisted(uint256 key, bytes32[] memory proof) external view returns (bool) {
        return MintGate.isAllowlisted(_msgSender(), proof, _allowlists[key]);
    }

    function mint(uint256 key, uint256 quantity) payable public virtual whenNotPaused returns (uint256) {
        return mint(key, new bytes32[](0), quantity);
    }

    function mint(uint256 key, bytes32[] memory proof, uint256 quantity) payable public virtual whenNotPaused returns (uint256) {
        address buyer = _msgSender();
        Sale memory sale = _sales[key];

        // Collection gate
        MintGate.maxMint(_maxMint, _numberMinted(buyer), quantity);

        // `Sale` gates
        if (sale.maxSupply == 0) {
            revert MintHasEnded();
        }

        MintGate.allowlist(buyer, proof, _allowlists[key]);
        MintGate.open(sale.endsAt, sale.startsAt);
        MintGate.price(buyer, sale.price, quantity, msg.value);

        uint256 available = _availableSupply();
        uint16[4] memory aux = _unpackAux(_getAux(buyer));

        // `Sale` max supply is not allowed to exceed max collection supply
        if (available > sale.maxSupply) {
            available = sale.maxSupply;
        }

        MintGate.supply(available, sale.maxMint, aux[key], quantity);

        // `Sale` max supply
        _sales[key].maxSupply -= uint32(quantity);

        // Buyer mint counter
        aux[key] += uint16(quantity);

        _setAux(buyer, _packAux(aux));
        _safeMint(buyer, quantity);

        return (sale.price * quantity);
    }

    function setAllowlist(uint256 key, bytes32 root) public onlyOwner {
        if (key > MAX_MINT_KEY) {
            revert InvalidMintKey();
        }

        _allowlists[key] = root;
    }

    function setSale(uint256 key, Sale memory sale) public onlyOwner virtual {
        if (key > MAX_MINT_KEY) {
            revert InvalidMintKey();
        }

        _sales[key] = sale;
    }

    function setMaxMint(uint256 maxMint) public onlyOwner {
        _maxMint = maxMint;
    }
}