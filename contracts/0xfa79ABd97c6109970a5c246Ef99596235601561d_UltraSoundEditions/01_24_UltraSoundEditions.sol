// SPDX-License-Identifier: MIT

/// @title Ultra Sound Editions
/// @author -wizard

/// Ultra Sound Editions is inspired by
/// @jackbutcher, pak, ultrasound.money
/// and by all degens, yes - that's you

pragma solidity ^0.8.6;

import {IUltraSoundGridRenderer} from "./interfaces/IUltraSoundGridRenderer.sol";
import {IUltraSoundDescriptor} from "./interfaces/IUltraSoundDescriptor.sol";
import {IUltraSoundEditions} from "./interfaces/IUltraSoundEditions.sol";
import {ERC2981ContractWideRoyalties, ERC2981Base} from "./libs/royalties/ERC2981ContractWideRoyalties.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UltraSoundEditions is
    IUltraSoundEditions,
    ERC721,
    DefaultOperatorFilterer,
    ERC2981ContractWideRoyalties,
    Pausable,
    Ownable
{
    IERC721Burn public proofOfWork;
    IUltraSoundDescriptor public descriptor;

    uint256 public ultraSoundBaseFee = 1660; // 16600000000;
    uint16 ultraEditionCounter = 0;
    uint8 restoreMax = 6;

    bool private degenMode = true; // for all degens, especially thomas
    uint256 private restoredCounter;

    mapping(uint256 => Edition) private editions;
    mapping(uint256 => uint256) private restoredTracker;

    constructor(IUltraSoundDescriptor _descriptor, IERC721Burn _proofOfWork)
        ERC721("Ultra Sound Editions", unicode"Ξ")
    {
        descriptor = _descriptor;
        proofOfWork = _proofOfWork;
        _setRoyalties(msg.sender, 500);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setRoyalties(address recipient, uint24 value) external onlyOwner {
        _setRoyalties(recipient, value);
    }

    function setProofOfWork(IERC721Burn _proofOfWork) external onlyOwner {
        emit ProofOfWorkUpdated(address(proofOfWork), address(_proofOfWork));
        proofOfWork = _proofOfWork;
    }

    function setDescriptor(IUltraSoundDescriptor _descriptor)
        external
        override
        onlyOwner
    {
        emit DescriptorUpdated(address(descriptor), address(_descriptor));
        descriptor = _descriptor;
    }

    function setUltraSoundBaseFee(uint256 _baseFee)
        external
        override
        onlyOwner
    {
        emit UltraSoundBaseFeeUpdated(ultraSoundBaseFee, _baseFee);
        ultraSoundBaseFee = _baseFee;
    }

    function toggleDegenMode() external override onlyOwner {
        degenMode = !degenMode;
    }

    function restored() public view override returns (uint256) {
        return restoredCounter;
    }

    function isUltraSound(uint256 tokenId)
        public
        view
        override
        returns (bool ultraSound)
    {
        ultraSound = editions[tokenId].ultraSound;
    }

    function levelOf(uint256 tokenId)
        public
        view
        override
        returns (uint256 level)
    {
        level = editions[tokenId].level;
    }

    function levelsOf(uint256[] calldata tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory levels = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            levels[i] = (editions[tokenIds[i]].level);
        }
        return levels;
    }

    function mergeCountOf(uint256 tokenId)
        public
        view
        override
        returns (uint256 mergeCount)
    {
        mergeCount = editions[tokenId].mergeCount;
    }

    function edition(uint256 tokenId)
        public
        view
        override
        returns (
            bool ultraSound,
            bool burned,
            uint32 seed,
            uint8 level,
            uint8 palette,
            uint32 blockNumber,
            uint64 baseFee,
            uint64 blockTime,
            uint16 mergeCount,
            uint16 ultraEdition
        )
    {
        ultraSound = editions[tokenId].ultraSound;
        burned = editions[tokenId].burned;
        seed = editions[tokenId].seed;
        level = editions[tokenId].level;
        palette = editions[tokenId].palette;
        blockNumber = editions[tokenId].blockNumber;
        baseFee = editions[tokenId].baseFee;
        blockTime = editions[tokenId].blockTime;
        mergeCount = editions[tokenId].mergeCount;
        ultraEdition = editions[tokenId].ultraEdition;
    }

    function mint(uint256 tokenId) external override whenNotPaused {
        if (!proofOfWork.isApprovedForAll(msg.sender, address(this))) {
            revert ContractNotOperator();
        }

        if (proofOfWork.ownerOf(tokenId) != msg.sender) {
            revert MustBeTokenOwner(address(proofOfWork), tokenId);
        }

        _redeem(msg.sender, tokenId);
        emit Redeemed(tokenId);
    }

    function mintBulk(uint256[] calldata tokenIds)
        external
        override
        whenNotPaused
    {
        if (tokenIds.length > 20) revert TooMany();
        if (!proofOfWork.isApprovedForAll(msg.sender, address(this))) {
            revert ContractNotOperator();
        }

        for (uint256 i = 0; i < tokenIds.length; ) {
            if (proofOfWork.ownerOf(tokenIds[i]) != msg.sender) {
                revert MustBeTokenOwner(address(proofOfWork), tokenIds[i]);
            }

            _redeem(msg.sender, tokenIds[i]);
            unchecked {
                i++;
            }
        }
        emit RedeemedMultiple(tokenIds);
    }

    function swapPalette(uint256 powToBurn, uint256 tokenToSwap)
        external
        whenNotPaused
    {
        address powOwner = proofOfWork.ownerOf(powToBurn);

        if (ownerOf(tokenToSwap) != msg.sender) {
            revert MustBeTokenOwner(address(this), tokenToSwap);
        }

        if (powOwner != msg.sender) {
            revert MustBeTokenOwner(address(proofOfWork), powToBurn);
        }

        if (!proofOfWork.isApprovedForAll(msg.sender, address(this))) {
            revert ContractNotOperator();
        }

        proofOfWork.burn(powToBurn);
        _swapPalette(tokenToSwap);

        emit MetadataUpdate(tokenToSwap);
        emit Merged(tokenToSwap, powToBurn);
    }

    function merge(uint256 token1, uint256 token2) external whenNotPaused {
        if (ownerOf(token1) != msg.sender) {
            revert MustBeTokenOwner(msg.sender, token1);
        }

        if (ownerOf(token2) != msg.sender) {
            revert MustBeTokenOwner(msg.sender, token2);
        }

        if (!isApprovedForAll(msg.sender, address(this))) {
            revert ContractNotOperator();
        }

        (uint256 tokenIdToBurn, uint256 tokenIdToKeep) = _merge(token1, token2);

        _burn(tokenIdToBurn);

        emit MetadataUpdate(tokenIdToKeep);
        emit MetadataUpdate(tokenIdToBurn);
        emit Merged(tokenIdToKeep, tokenIdToBurn);
    }

    function restore(uint256 toRestore, uint256 toUse) external {
        unchecked {
            restoredTracker[toUse] = restoredTracker[toUse] + 1;
        }

        if (
            _exists(toRestore) ||
            ownerOf(toUse) != msg.sender ||
            levelOf(toUse) != 7 ||
            restoredTracker[toUse] > restoreMax ||
            editions[toRestore].burned == false
        ) revert CannotRestore();

        unchecked {
            restoredCounter = restoredCounter + 1;
        }

        _mint(msg.sender, toRestore);
        emit Restored(toRestore, msg.sender);
    }

    function onERC721Received(
        address,
        address from,
        uint256 id,
        bytes calldata data
    ) external whenNotPaused returns (bytes4) {
        address tokenAddress = msg.sender;
        uint256 action;
        uint256 tokenId;

        if (
            tokenAddress != address(proofOfWork) &&
            tokenAddress != address(this)
        ) {
            revert OnReceivedRequestFailure();
        }

        if (tokenAddress == address(proofOfWork) && data.length == 0) {
            action = 0;
        } else if (data.length == 64) {
            (action, tokenId) = abi.decode(data, (uint256, uint256));
        } else {
            revert OnReceivedRequestFailure();
        }

        if (action == 0) {
            /// MINT ///
            _redeem(from, id);
        } else if (action == 1) {
            /// SWAP ///
            if (ownerOf(tokenId) != from) {
                revert MustBeTokenOwner(address(this), tokenId);
            }
            proofOfWork.burn(id);
            _swapPalette(tokenId);

            emit MetadataUpdate(tokenId);
            emit Merged(tokenId, id);
        } else if (action == 2) {
            /// MERGE ///
            if (ownerOf(tokenId) != from) {
                revert MustBeTokenOwner(address(this), tokenId);
            }
            (uint256 tokenIdToBurn, uint256 tokenIdToKeep) = _merge(
                id,
                tokenId
            );
            _burn(tokenIdToBurn);
            if (tokenId != tokenIdToKeep) {
                _transfer(address(this), from, tokenIdToKeep);
            }

            emit MetadataUpdate(tokenIdToKeep);
            emit MetadataUpdate(tokenIdToBurn);
            emit Merged(tokenIdToKeep, tokenIdToBurn);
        }
        return this.onERC721Received.selector;
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, IUltraSoundEditions)
        returns (string memory)
    {
        Edition memory e = editions[tokenId];
        if (e.blockNumber == 0) revert("Nonexistent token");
        return descriptor.tokenURI(tokenId, editions[tokenId]);
    }

    function tokenSVG(uint256 tokenId, uint8 size)
        public
        view
        override
        returns (string memory)
    {
        Edition memory e = editions[tokenId];
        if (e.blockNumber == 0) revert("Nonexistent token");
        return descriptor.tokenSVG(editions[tokenId], size);
    }

    function _redeem(address to, uint256 tokenId) internal whenNotPaused {
        proofOfWork.burn(tokenId);
        _seedTokenData(tokenId);
        _mint(to, tokenId);
    }

    function _seedTokenData(uint256 tokenId) internal {
        bool ultraSound = block.basefee >= ultraSoundBaseFee;
        uint32 seed = _getSeed(tokenId);

        editions[tokenId] = Edition({
            seed: seed,
            baseFee: uint64(block.basefee),
            blockTime: uint64(block.timestamp),
            blockNumber: uint32(block.number),
            ultraSound: ultraSound,
            ultraEdition: 0,
            mergeCount: 0,
            level: 0,
            palette: _getPalette(seed, ultraSound),
            burned: false
        });
    }

    function _swapPalette(uint256 tokenId) internal {
        Edition storage e = editions[tokenId];
        uint32 seed = _getSeed(tokenId);

        unchecked {
            e.mergeCount = e.mergeCount + 1;
        }
        e.seed = seed;
        e.palette = _getPalette(seed, e.ultraSound);
    }

    function _merge(uint256 tokenIdOne, uint256 tokenIdTwo)
        internal
        returns (uint256 tokenIdToBurn, uint256 tokenIdToKeep)
    {
        uint8 level1 = editions[tokenIdOne].level;
        uint8 level2 = editions[tokenIdTwo].level;

        uint8 nextLevel;
        uint64 basefee;
        uint64 blockTime;
        uint32 blockNumber;
        bool ultraSound;
        uint32 seed;

        if (editions[tokenIdOne].burned || editions[tokenIdOne].burned) {
            revert CannotRestore();
        }

        if (degenMode == true && level1 != level2) {
            revert LevelsMustMatch(level1, level2);
        }

        if (degenMode) {
            unchecked {
                if (level1 > level2) {
                    nextLevel = level1 + 1;
                } else {
                    nextLevel = level2 + 1;
                }
            }
        } else {
            unchecked {
                nextLevel = level1 + level2 + 1;
            }
        }

        if (nextLevel > 7) {
            revert ExceedsMaxLevel(nextLevel, 7);
        }

        uint16 newMergeCount;
        unchecked {
            newMergeCount =
                (editions[tokenIdOne].mergeCount +
                    editions[tokenIdTwo].mergeCount) +
                1;
        }

        if (editions[tokenIdOne].baseFee > editions[tokenIdTwo].baseFee) {
            tokenIdToKeep = tokenIdOne;
            tokenIdToBurn = tokenIdTwo;
        } else {
            tokenIdToKeep = tokenIdTwo;
            tokenIdToBurn = tokenIdOne;
        }

        if (editions[tokenIdToKeep].baseFee > block.basefee) {
            basefee = editions[tokenIdToKeep].baseFee;
            blockTime = editions[tokenIdToKeep].blockTime;
            blockNumber = editions[tokenIdToKeep].blockNumber;
            ultraSound = basefee >= ultraSoundBaseFee;
        } else {
            basefee = uint64(block.basefee);
            blockTime = uint64(block.timestamp);
            blockNumber = uint32(block.number);
            ultraSound = basefee >= ultraSoundBaseFee;
        }

        if (nextLevel == 7 && !ultraSound) {
            revert MustBeUltraSound(tokenIdToKeep);
        } else if (nextLevel == 7) {
            unchecked {
                ultraEditionCounter++;
            }
        }

        seed = _getSeed(tokenIdToKeep);
        editions[tokenIdToBurn].burned = true;
        editions[tokenIdToKeep] = Edition({
            seed: seed,
            baseFee: basefee,
            blockTime: blockTime,
            blockNumber: blockNumber,
            ultraSound: ultraSound,
            mergeCount: newMergeCount,
            ultraEdition: ultraEditionCounter,
            level: nextLevel,
            palette: _getPalette(seed, ultraSound),
            burned: false
        });
    }

    function _getSeed(uint256 tokenId) internal view returns (uint32) {
        return
            uint32(
                uint256(
                    keccak256(
                        abi.encodePacked(tokenId, msg.sender, block.basefee)
                    )
                ) % type(uint32).max
            );
    }

    function _getPalette(uint256 seed, bool ultraSound)
        internal
        view
        returns (uint8 palette)
    {
        uint256 palettes = descriptor.palettesCount();
        if (!ultraSound) {
            unchecked {
                palette = uint8((seed % 4) + 1);
            }
        } else {
            unchecked {
                palette = uint8((seed % palettes));
                palette = palette < 5 ? (palette + 5) : palette;
            }
        }
    }

    // Overrides to support allowed operators

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(ERC2981ContractWideRoyalties).interfaceId ||
            interfaceId == type(ERC2981ContractWideRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

interface IERC721Burn {
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

/* degen - you've made it to the end of the contract

        \||/
        \||/
       ⧫⧫⧫⧫⧫⧫
      ⧫⧫⧫⧫⧫⧫⧫⧫
      ⧫⧫⧫⧫⧫⧫⧫⧫
       ⧫⧫⧫⧫⧫⧫

long live the pineapple (iykyk)

*/