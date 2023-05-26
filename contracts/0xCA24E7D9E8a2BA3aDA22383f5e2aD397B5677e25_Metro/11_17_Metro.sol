// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                        888
//                        888
//                        888
// 88888b.d88b.   .d88b.  888888 888d888 .d88b.
// 888 "888 "88b d8P  Y8b 888    888P"  d88""88b
// 888  888  888 88888888 888    888    888  888
// 888  888  888 Y8b.     Y88b.  888    Y88..88P
// 888  888  888  "Y8888   "Y888 888     "Y88P"

// 888                    d8b          888                          888
// 888                    Y8P          888                          888
// 888                                 888                          888
// 88888b.  888  888      888 88888b.  888888       8888b.  888d888 888888
// 888 "88b 888  888      888 888 "88b 888             "88b 888P"   888
// 888  888 888  888      888 888  888 888         .d888888 888     888
// 888 d88P Y88b 888      888 888  888 Y88b.       888  888 888     Y88b.
// 88888P"   "Y88888      888 888  888  "Y888      "Y888888 888      "Y888
//               888
//          Y8b d88P
//           "Y88P"

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {BaseERC721A} from "./BaseERC721A.sol";

import {IMetro, MetroTokenProperties} from "./interfaces/IMetro.sol";
import {IMetroRenderer} from "./interfaces/IMetroRenderer.sol";

contract Metro is BaseERC721A, IMetro {
    struct MetroTokenState {
        uint256 mode; // 0: Curate, 1: Evolve, 2: Lock
        uint256 baseSeedSetDate;
        uint256 lockStartDate;
        uint256 progressStartIndex;
        uint256 curateCount;
        bytes32 baseSeed;
    }

    address public minterAddress;
    bool public isCollectionEvolveEnabled;
    IMetroRenderer public renderer;

    uint256 public mintStartDate;

    uint256 public constant TOTAL_SUPPLY = 2048;
    uint256 public constant MAX_PROGRESS = 50;
    uint256 public constant PROGRESS_FREQUENCY = 5 days;
    uint256 public constant PROGRESS_SEED_STEP = 10;
    uint256 public constant PROGRESS_SEED_FREQUENCY =
        PROGRESS_SEED_STEP * PROGRESS_FREQUENCY;
    uint256 public MAX_BLOCK_NUMBER_OFFSET = 50;

    mapping(uint256 => MetroTokenState) public tokenStates;
    bytes32[] public progressSeeds;

    error InvalidMinter();
    error MintingNotStarted();
    error MintingAlreadyStarted();
    error InvalidBlockNumber();
    error AlreadyEvolving();
    error AlreadyLocked();
    error AlreadyCurated();
    error CantStartEvolveOnceLocked();
    error CantEvolveRightNow();
    error InvalidTokenOwner();
    error ReachedMaxSupply();
    error CollectionEvolveNotEnabled();

    constructor() BaseERC721A("the metro", "METRO") {
        // mint 1 metro to set up marketplace pages:
        _safeMint(0x3a3Da350FD33a1854bEaeab086261c848526811b, 1);
    }

    // - owner operations

    function updateDependencies(
        address _rendererAddress,
        address _minterAddress
    ) public onlyOwner {
        updateRenderer(_rendererAddress);
        updateMinterAddress(_minterAddress);
    }

    function updateRenderer(address _rendererAddress) public onlyOwner {
        renderer = IMetroRenderer(_rendererAddress);
    }

    function updateMinterAddress(address _minterAddress) public onlyOwner {
        minterAddress = _minterAddress;
    }

    function updateMintStartDate(uint256 _mintStartDate) public onlyOwner {
        mintStartDate = _mintStartDate;
    }

    function setIsCollectionEvolveEnabled(bool _isCollectionEvolveEnabled)
        public
        onlyOwner
    {
        isCollectionEvolveEnabled = _isCollectionEvolveEnabled;
    }

    function startMinting() public onlyOwner {
        if (mintStartDate > 0) {
            revert MintingAlreadyStarted();
        }
        mintStartDate = block.timestamp;
    }

    // - public helpers

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number - 1;
    }

    // - mint operations

    function mint(address target, uint256 count) public {
        if (mintStartDate == 0) {
            revert MintingNotStarted();
        }
        if (msg.sender != minterAddress) {
            revert InvalidMinter();
        }
        uint256 totalMinted = _totalMinted();
        if (totalMinted + count > TOTAL_SUPPLY) {
            if (totalMinted < TOTAL_SUPPLY) {
                count = TOTAL_SUPPLY - totalMinted;
            }else{
                revert ReachedMaxSupply();
            }
        }
        _safeMint(target, count);
    }

    // - token evolving operations

    function startEvolvingWithLastBlockNumber(uint256 tokenId) public {
        startEvolvingMetro(tokenId, getBlockNumber());
    }

    function startEvolvingMetro(uint256 tokenId, uint256 blockNumber) public {
        revertIfBlockNumberIsInvalid(blockNumber);
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidTokenOwner();
        }

        MetroTokenState memory tokenState = tokenStates[tokenId];
        if (tokenState.mode == 1) {
            revert AlreadyEvolving();
        } else if (tokenState.mode == 2) {
            revert CantStartEvolveOnceLocked();
        }

        tokenState.mode = 1;
        tokenState.baseSeed = getTokenSeed(tokenId, blockNumber);
        tokenState.baseSeedSetDate = block.timestamp;
        tokenState.progressStartIndex = progressSeeds.length;
        tokenStates[tokenId] = tokenState;

        emit EvolveMetro(msg.sender, tokenId);
        emit MetadataUpdate(tokenId);
    }

    // - token lock operations

    function lockMetroWithLastBlockNumber(uint256 tokenId) public {
        lockMetro(tokenId, getBlockNumber());
    }

    function lockMetro(uint256 tokenId, uint256 blockNumber) public {
        MetroTokenState memory tokenState = tokenStates[tokenId];
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidTokenOwner();
        }
        if (tokenState.mode == 0) {
            revertIfBlockNumberIsInvalid(blockNumber);
        }
        if (tokenState.mode == 2) {
            revert AlreadyLocked();
        }

        if (tokenState.mode == 0) {
            tokenState.baseSeed = getTokenSeed(tokenId, blockNumber);
            tokenState.baseSeedSetDate = block.timestamp;
        }

        tokenState.mode = 2;
        tokenState.lockStartDate = block.timestamp;
        tokenStates[tokenId] = tokenState;

        emit LockMetro(msg.sender, tokenId);
        emit MetadataUpdate(tokenId);
    }

    // - token reset operations

    function resetMetro(uint256 tokenId) public {
        MetroTokenState memory tokenState = tokenStates[tokenId];
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidTokenOwner();
        }
        if (tokenState.mode == 0) {
            revert AlreadyCurated();
        }

        tokenState.mode = 0;
        tokenState.curateCount++;
        tokenStates[tokenId] = tokenState;

        emit ResetMetro(msg.sender, tokenId);
        emit MetadataUpdate(tokenId);
    }

    // - collection evolve operations

    function canEvolveCollection() public view returns (bool) {
        unchecked {
            if (!isCollectionEvolveEnabled) {
                return false;
            }
            uint256 progress = (block.timestamp - mintStartDate) /
                PROGRESS_SEED_FREQUENCY;
            return progress > (progressSeeds.length);
        }
    }

    function nextEvolveTimestamp() public view returns (uint256) {
        return (progressSeeds.length + 1) * PROGRESS_SEED_FREQUENCY + mintStartDate;
    }

    function evolveCollection() public {
        if (!canEvolveCollection()) {
            revert CantEvolveRightNow();
        }
        progressSeeds.push(getProgressSeed());
        emit EvolveCollection(msg.sender);
        emit BatchMetadataUpdate(1, totalSupply());
    }

    // - progress calculations

    function getProgressOf(uint256 tokenId) public view returns (uint256) {
        unchecked {
            MetroTokenState memory tokenState = tokenStates[tokenId];
            if (tokenState.mode == 2) {
                return
                    (tokenState.lockStartDate - tokenState.baseSeedSetDate) /
                    PROGRESS_FREQUENCY;
            } else if (tokenState.mode == 1) {
                uint256 progress = (getBlockTimestamp() -
                    tokenState.baseSeedSetDate) / PROGRESS_FREQUENCY;
                if (progress > MAX_PROGRESS) {
                    return MAX_PROGRESS;
                }
                return progress;
            }
            return 0;
        }
    }

    function getProgressSeedsOf(uint256 tokenId)
        public
        view
        returns (bytes32[] memory)
    {
        unchecked {
            MetroTokenState memory tokenState = tokenStates[tokenId];
            uint256 tokenProgress = getProgressOf(tokenId);

            uint256 progressSeedCount = tokenProgress / PROGRESS_SEED_STEP;
            bytes32[] memory progress;

            if (progressSeedCount == 0) {
                return progress;
            }

            bytes32[] memory _progressSeeds = progressSeeds;
            progress = new bytes32[](progressSeedCount);
            uint256 progressIndex;
            uint256 i = tokenState.progressStartIndex;
            uint256 length = tokenState.progressStartIndex + progressSeedCount;
            do {
                if (i < _progressSeeds.length) {
                    bytes32 foundSeed = _progressSeeds[i];
                    if (foundSeed.length > 0) {
                        bytes32 currentProgress = keccak256(
                            abi.encodePacked(
                                i,
                                tokenId,
                                tokenState.baseSeed,
                                foundSeed
                            )
                        );
                        progress[progressIndex] = currentProgress;
                    }
                }
                ++progressIndex;
            } while (++i < length);
            return progress;
        }
    }

    function getTokenProperties(uint256 tokenId)
        public
        view
        returns (MetroTokenProperties memory)
    {
        return getTokenProperties(tokenId, getBlockNumber());
    }

    function getTokenProperties(uint256 tokenId, uint256 blockNumber)
        public
        view
        returns (MetroTokenProperties memory)
    {
        MetroTokenState memory tokenState = tokenStates[tokenId];
        MetroTokenProperties memory tokenProperties;

        if (tokenState.mode == 1 || tokenState.mode == 2) {
            tokenProperties.seed = tokenState.baseSeed;
        } else {
            tokenProperties.seed = getTokenSeed(tokenId, blockNumber);
        }

        tokenProperties.mode = tokenState.mode;
        tokenProperties.progress = getProgressOf(tokenId);
        tokenProperties.progressSeeds = getProgressSeedsOf(tokenId);
        tokenProperties.progressSeedStep = PROGRESS_SEED_STEP;
        tokenProperties.curateCount = tokenState.curateCount;
        tokenProperties.maxProgress = MAX_PROGRESS;

        return tokenProperties;
    }

    // - token URI

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return renderer.tokenURI(tokenId);
    }

    function tokenURIWithCurrentBlockNumber(uint256 tokenId)
        public
        view
        returns (string memory, uint256)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return (renderer.tokenURI(tokenId), getBlockNumber());
    }

    // - internal

    function getProgressSeed() internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp)
            );
    }

    function getTokenSeed(uint256 tokenId, uint256 blockNumber)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, blockhash(blockNumber)));
    }

    function revertIfBlockNumberIsInvalid(uint256 blockNumber) internal view {
        if (blockNumber < getBlockNumber() - MAX_BLOCK_NUMBER_OFFSET) {
            revert InvalidBlockNumber();
        }
    }

    event EvolveMetro(address indexed owner, uint256 indexed tokenId);
    event LockMetro(address indexed owner, uint256 indexed tokenId);
    event ResetMetro(address indexed owner, uint256 indexed tokenId);
    event EvolveCollection(address indexed owner);

    // Marketplace events
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}