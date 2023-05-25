// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";

import "./IERC4906.sol";
import "./IMetadataRenderer.sol";

contract FunMint is ERC721A, IERC4906, Ownable {
    address public metadataRenderer;
    address public metadataUpdater;

    mapping(uint256 => bool) public mintedSpecialByTokenId;

    uint256 public mintEnd;
    bytes32 merkleRoot;
    bytes32 merkleRootSpecial;

    // Refund constants
    uint256 public constant REFUND_BASE_GAS = 30_000;
    uint256 public constant MAX_REFUND_GAS_USED = 200_000;
    uint256 public constant MAX_REFUND_BASE_FEE = 200 gwei;
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    bool private _initialized;
    string private _name;
    string private _symbol;

    error InvalidTokenId();
    error InvalidProof();
    error MerkleRootNotSet();
    error MintClosed();
    error MintedAlready();
    error OnlyOwnerOrMetadataUpdater();

    constructor() ERC721A("", "") {}

    receive() external payable {}

    function init(string memory name_, string memory symbol_, address owner) public onlyOwner {
        if (_initialized) revert("Already initialized");
        _initialized = true;
        _name = name_;
        _symbol = symbol_;
        transferOwnership(owner);
    }

    function _packAux(bool mintedNormal, bool mintedSpecial) internal pure returns (uint64) {
        uint64 result = 0;
        result = (result << 1) | (mintedNormal ? 1 : 0);
        result = (result << 1) | (mintedSpecial ? 1 : 0);
        return result;
    }

    function _unpackAux(uint64 packedData) internal pure returns (bool mintedNormal, bool mintedSpecial) {
        mintedSpecial = (packedData & 1) != 0;
        mintedNormal = ((packedData >> 1) & 1) != 0;
    }

    function mint(bytes32[] calldata _proof) public refundsGas {
        if (block.timestamp > mintEnd) revert MintClosed();
        (bool mintedNormal, bool mintedSpecial) = _unpackAux(_getAux(msg.sender));
        if (mintedNormal) revert MintedAlready();
        bool isValid = MerkleProofLib.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
        if (!isValid) revert InvalidProof();

        // Perform all state changes before refunding gas to prevent reentrancy

        _mint(msg.sender, 1);
        _setAux(msg.sender, _packAux(true, mintedSpecial));
    }

    function mintSpecial(bytes32[] calldata _proof) public refundsGas {
        if (block.timestamp > mintEnd) revert MintClosed();
        (bool mintedNormal, bool mintedSpecial) = _unpackAux(_getAux(msg.sender));
        if (mintedSpecial) revert MintedAlready();

        bool isValid = MerkleProofLib.verify(_proof, merkleRootSpecial, keccak256(abi.encodePacked(msg.sender)));
        if (!isValid) revert InvalidProof();

        // Perform all state changes before refunding gas to prevent reentrancy
        mintedSpecialByTokenId[_nextTokenId()] = true;
        _mint(msg.sender, 1);
        _setAux(msg.sender, _packAux(mintedNormal, true));
    }

    modifier refundsGas() {
        uint256 startGas = gasleft();
        _;
        _refundGas(startGas);
    }

    // slightly modified from https://github.com/nounsDAO/nouns-monorepo/blob/10bb478328bdb5f4c5efffed9a8c5186f9fe974a/packages/nouns-contracts/contracts/governance/NounsDAOLogicV2.sol#LL1033C2-L1048C21
    function _refundGas(uint256 startGas) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }
            uint256 basefee = _min(block.basefee, MAX_REFUND_BASE_FEE);
            uint256 gasPrice = _min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = _min(startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
            uint256 refundAmount = _min(gasPrice * gasUsed, balance);
            tx.origin.call{value: refundAmount}("");
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf(id) == address(0)) revert InvalidTokenId();
        return IMetadataRenderer(metadataRenderer).tokenURI(id);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // Admin functions
    function refreshMetadata() public {
        if (msg.sender != metadataUpdater && msg.sender != owner()) {
            revert OnlyOwnerOrMetadataUpdater();
        }
        emit BatchMetadataUpdate(_startTokenId(), _nextTokenId() - 1);
    }

    function setMetadataRenderer(address _metadataRenderer) public onlyOwner {
        metadataRenderer = _metadataRenderer;
        refreshMetadata();
    }

    function setMetadataUpdater(address _metadataUpdater) public onlyOwner {
        metadataUpdater = _metadataUpdater;
    }

    function setMerkleRoots(bytes32 regular, bytes32 special) public onlyOwner {
        if (regular == bytes32(0) || special == bytes32(0)) {
            revert MerkleRootNotSet();
        }

        merkleRoot = regular;
        merkleRootSpecial = special;
    }

    function setMintEnd(uint256 _mintEnd) public onlyOwner {
        if (_mintEnd > 0 && (merkleRoot == bytes32(0) || merkleRootSpecial == bytes32(0))) {
            revert MerkleRootNotSet();
        }
        mintEnd = _mintEnd;
    }

    function withdraw() public onlyOwner {
        payable(owner()).call{value: address(this).balance}("");
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC4906).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }
}