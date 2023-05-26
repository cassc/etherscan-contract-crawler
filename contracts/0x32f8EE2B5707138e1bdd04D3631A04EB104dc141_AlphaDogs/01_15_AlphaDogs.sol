// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

import {IAlphaToken} from "$/interfaces/IAlphaToken.sol";
import {IAlphaDogs} from "$/interfaces/IAlphaDogs.sol";
import {IAlphaDogsAttributes} from "$/interfaces/IAlphaDogsAttributes.sol";

import {Genetics} from "$/libraries/Genetics.sol";
import {Gene} from "$/libraries/Gene.sol";
import {ERC721} from "$/ERC721.sol";

/// @title  AlphaDogs
/// @author Aleph Retamal <github.com/alephao>, Gustavo Tiago <github.com/gutiago>
contract AlphaDogs is IAlphaDogs, ERC721, Ownable, ReentrancyGuard {
    using Gene for uint256;
    using Strings for uint160;
    // ========================================
    // Immutable
    // ========================================

    address private constant BLACKHOLE = address(0);

    /// @notice amount of $ALPHA a staked genesis dog earn per day
    uint256 public constant GENESIS_TOKEN_PER_DAY = 10 ether;

    /// @notice amount of $ALPHA a staked puppy dog earn per day
    uint256 public constant PUPPY_TOKEN_PER_DAY = 2.5 ether;

    /// @notice price in $ALPHA to breed
    uint256 public constant BREEDING_PRICE = 600 ether;

    /// @notice price in $ALPHA to update name or lore of a dog
    uint256 public constant UPDATE_PRICE = 100 ether;

    /// @notice max amount of genesis tokens
    uint32 public immutable maxGenesis;

    /// @notice max amount of puppy tokens
    uint32 public immutable maxPuppies;

    /// @notice address of the $ALPHA ERC20
    IAlphaToken public immutable alphaToken;

    /// @notice merkle tree root for allow-list
    bytes32 public immutable merkleRoot;

    /// @notice number of reserved genesis tokens for wallets in the allow-list
    uint32 public immutable maxReserved;

    // ========================================
    // Mutable
    // ========================================

    /// @notice if the mint function is open
    bool public isSaleActive = false;

    /// @notice if supply should be reserved for allow-list
    bool public isSupplyReserved = true;

    /// @notice amount of genesis minted so far not via allow-list
    uint32 public genesisNonReservedSupply = 0;

    /// @notice amount of genesis minted so far via allow-list
    uint32 public genesisReservedSupply = 0;

    /// @notice amount of puppied minted so far
    uint32 public puppySupply = 0;

    /// @notice map from dog id to custom Name and Lore
    mapping(uint256 => CustomMetadata) internal metadata;

    /// @notice map from dog id to its staked state
    mapping(uint256 => Stake) public getStake;

    /// @notice check if an address already minted
    mapping(address => bool) public didMint;

    /// @notice address of the AlphaDogsAttributes contract
    IAlphaDogsAttributes public attributes;

    // ========================================
    // Constructor
    // ========================================

    constructor(
        uint32 _maxGenesis,
        uint32 _maxPuppies,
        uint32 _maxReserved,
        IAlphaToken _alphaToken,
        IAlphaDogsAttributes _attributes,
        bytes32 _merkleRoot
    ) ERC721("AlphaDogs", "AD") {
        maxGenesis = _maxGenesis;
        maxPuppies = _maxPuppies;
        maxReserved = _maxReserved;
        alphaToken = _alphaToken;
        attributes = _attributes;
        merkleRoot = _merkleRoot;
    }

    // ========================================
    // Modifiers
    // ========================================

    modifier dogzOwner(uint256 id) {
        if (ownerOf[id] != msg.sender) revert InvalidTokenOwner();
        _;
    }

    modifier whenSaleIsActive() {
        if (!isSaleActive) revert NotActive();
        _;
    }

    // " and \ are not valid
    modifier isValidString(string calldata value) {
        bytes memory str = bytes(value);

        for (uint256 i; i < str.length; i++) {
            bytes1 char = str[i];
            if ((char == 0x22) || (char == 0x5c)) revert InvalidChar();
        }
        _;
    }

    // ========================================
    // Owner only
    // ========================================

    function setIsSaleActive(bool _isSaleActive) external onlyOwner {
        if (isSaleActive == _isSaleActive) revert NotChanged();
        isSaleActive = _isSaleActive;
    }

    function setIsSupplyReserved(bool _isSupplyReserved) external onlyOwner {
        if (isSupplyReserved == _isSupplyReserved) revert NotChanged();
        isSupplyReserved = _isSupplyReserved;
    }

    // ========================================
    // Change NFT Data
    // ========================================

    function setName(uint256 id, string calldata newName)
        external
        override
        dogzOwner(id)
        isValidString(newName)
    {
        bytes memory n = bytes(newName);

        if (n.length > 25) revert InvalidNameLength();
        if (keccak256(n) == keccak256(bytes(metadata[id].name)))
            revert InvalidSameValue();

        metadata[id].name = newName;
        alphaToken.burn(msg.sender, UPDATE_PRICE);
        emit NameChanged(id, newName);
    }

    function setLore(uint256 id, string calldata newLore)
        external
        override
        dogzOwner(id)
        isValidString(newLore)
    {
        bytes memory n = bytes(newLore);

        if (keccak256(n) == keccak256(bytes(metadata[id].lore)))
            revert InvalidSameValue();

        metadata[id].lore = newLore;
        alphaToken.burn(msg.sender, UPDATE_PRICE);
        emit LoreChanged(id, newLore);
    }

    // ========================================
    // Breeding
    // ========================================

    function breed(uint256 mom, uint256 dad)
        external
        override
        dogzOwner(mom)
        dogzOwner(dad)
    {
        if (genesisLeft() != 0) revert NotActive();

        uint256 mintIndex = puppySupply;
        if (mintIndex == maxPuppies) revert InsufficientTokensAvailable();
        if (Gene.isPuppy(mom) || Gene.isPuppy(dad))
            revert FusionWithPuppyForbidden();
        if (mom == dad) revert FusionWithSameParentsForbidden();

        unchecked {
            puppySupply++;
        }

        uint256 puppyId = _generatePuppyTokenIdWithNoCollision(
            mom,
            dad,
            random(mintIndex)
        );
        alphaToken.burn(msg.sender, BREEDING_PRICE);
        //slither-disable-next-line reentrancy-no-eth
        _mint(msg.sender, puppyId);

        emit Breeded(puppyId, mom, dad);
    }

    function _generatePuppyTokenIdWithNoCollision(
        uint256 mom,
        uint256 dad,
        uint256 seed
    ) internal view returns (uint256 tokenId) {
        tokenId = Genetics.uniformCrossOver(mom, dad, seed);
        uint256 i = 3;
        while (ownerOf[tokenId] != BLACKHOLE) {
            tokenId = Genetics.incrementByte(tokenId, i);
            unchecked {
                i++;
            }
        }
    }

    // ========================================
    // Stake / Unstake
    // ========================================

    function stake(uint256[] calldata tokenIds) external override {
        if (tokenIds.length == 0) revert InvalidInput();
        if (msg.sender == address(0)) revert InvalidSender();

        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; ) {
            tokenId = tokenIds[i];
            // No need to check ownership since transferFrom already checks that
            // and the caller of this function should be the token Owner
            getStake[tokenId] = Stake(msg.sender, uint96(block.timestamp));
            _transfer(msg.sender, address(this), tokenId);
            emit Staked(tokenId);

            unchecked {
                ++i;
            }
        }
    }

    function unstake(uint256[] calldata tokenIds) external override {
        _claim(tokenIds, true);
    }

    function claim(uint256[] calldata tokenIds) external override {
        _claim(tokenIds, false);
    }

    function _claim(uint256[] calldata tokenIds, bool shouldUnstake) internal {
        if (tokenIds.length == 0) revert InvalidInput();
        if (msg.sender == address(0)) revert InvalidSender();

        // total rewards amount to claim
        uint256 totalRewards;

        // loop variables

        // rewards for current genzee in the loop below
        uint256 rewards;

        // current genzeeid in the loop below
        uint256 tokenId;

        // staking information for the current genzee in the loop below
        Stake memory stakeInfo;

        for (uint256 i = 0; i < tokenIds.length; ) {
            tokenId = tokenIds[i];
            stakeInfo = getStake[tokenId];

            if (stakeInfo.owner != msg.sender) revert InvalidTokenOwner();

            uint256 tokensPerDay = tokenId.isPuppy()
                ? PUPPY_TOKEN_PER_DAY
                : GENESIS_TOKEN_PER_DAY;

            rewards = stakeInfo.stakedAt > 1
                ? ((tokensPerDay * (block.timestamp - stakeInfo.stakedAt)) /
                    1 days)
                : 0;
            totalRewards += rewards;

            if (shouldUnstake) {
                getStake[tokenId] = Stake(BLACKHOLE, 1);
                _transfer(address(this), msg.sender, tokenId);
                emit Unstaked(tokenId, rewards);
            } else {
                //slither-disable-next-line incorrect-equality
                if (rewards == 0) revert InvalidAmountToClaim();
                getStake[tokenId].stakedAt = uint96(block.timestamp);
                emit ClaimedTokens(tokenId, rewards);
            }

            unchecked {
                ++i;
            }
        }

        //slither-disable-next-line incorrect-equality
        if (totalRewards == 0) return;
        alphaToken.mint(msg.sender, totalRewards);
    }

    // ========================================
    // Mint
    // ========================================

    function _generateTokenIdWithNoCollision(uint256 seed)
        internal
        view
        returns (uint256 tokenId)
    {
        tokenId = Genetics.generateGenes(seed);
        uint256 i = 3;
        while (ownerOf[tokenId] != BLACKHOLE) {
            tokenId = Genetics.incrementByte(tokenId, i);
            unchecked {
                i++;
            }
        }
    }

    function premint(bytes32[] calldata proof) external whenSaleIsActive {
        uint256 reservedSupply = genesisReservedSupply;

        if (didMint[msg.sender]) revert TokenLimitReached();
        if (reservedSupply + 2 > maxReserved)
            revert InsufficientReservedTokensAvailable();
        if (reservedSupply + genesisNonReservedSupply + 2 > maxGenesis)
            revert InsufficientTokensAvailable();

        bytes32 leaf = keccak256(
            abi.encodePacked(uint160(msg.sender).toHexString(20))
        );
        bool isProofValid = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isProofValid) revert InvalidMerkleProof();

        didMint[msg.sender] = true;

        unchecked {
            uint256 mintIndex = genesisSupply();
            genesisReservedSupply += 2;
            _safeMint(
                msg.sender,
                _generateTokenIdWithNoCollision(random(mintIndex + 1))
            );
            _safeMint(
                msg.sender,
                _generateTokenIdWithNoCollision(random(mintIndex + 2))
            );
        }
    }

    function mint() external whenSaleIsActive {
        // Can only mint once per address
        if (didMint[msg.sender]) {
            revert TokenLimitReached();
        }

        uint256 reservedSupply = genesisReservedSupply;
        uint256 nonReservedSupply = genesisNonReservedSupply;

        if (reservedSupply + nonReservedSupply + 2 > maxGenesis)
            revert InsufficientTokensAvailable();

        // When minting, if isSupplyReserved is on, public minters won't be able
        // to mint the amount reserved for allow-listed wallets
        if (
            isSupplyReserved && nonReservedSupply + 2 > maxGenesis - maxReserved
        ) {
            revert InsufficientNonReservedTokensAvailable();
        }

        didMint[msg.sender] = true;

        unchecked {
            uint256 mintIndex = genesisSupply();
            genesisNonReservedSupply += 2;
            _safeMint(
                msg.sender,
                _generateTokenIdWithNoCollision(random(mintIndex + 1))
            );
            _safeMint(
                msg.sender,
                _generateTokenIdWithNoCollision(random(mintIndex + 2))
            );
        }
    }

    function random(uint256 nonce) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin, // solhint-disable-line avoid-tx-origin
                        tx.gasprice,
                        nonce,
                        block.number,
                        block.timestamp
                    )
                )
            );
    }

    // ========================================
    // View
    // ========================================

    function genesisSupply() public view returns (uint32) {
        unchecked {
            return genesisReservedSupply + genesisNonReservedSupply;
        }
    }

    /// @notice amount of tokens left to be minted
    function genesisLeft() public view returns (uint32) {
        unchecked {
            return maxGenesis - genesisSupply();
        }
    }

    /// @notice amount do puppies left to be created
    function puppyTokensLeft() external view returns (uint32) {
        unchecked {
            return maxPuppies - puppySupply;
        }
    }

    /// @notice total supply of nfts
    function totalSupply() external view returns (uint32) {
        unchecked {
            return genesisSupply() + puppySupply;
        }
    }

    function getMetadata(uint256 id)
        external
        view
        override
        returns (CustomMetadata memory)
    {
        return metadata[id];
    }

    // ========================================
    // Overrides
    // ========================================

    function tokenURI(uint256 id)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (ownerOf[id] == BLACKHOLE) revert InvalidTokenID();
        CustomMetadata memory md = metadata[id];
        return attributes.tokenURI(id, bytes(md.name), md.lore);
    }
}