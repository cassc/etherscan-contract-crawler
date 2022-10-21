// SPDX-License-Identifier: MIT

/*

██╗░░██╗██╗██╗░░██╗░█████╗░██╗░██████╗  ███╗░░░███╗██╗░░░██╗░██████╗████████╗██╗░█████╗░░██████╗
██║░██╔╝██║██║░██╔╝██╔══██╗╚█║██╔════╝  ████╗░████║╚██╗░██╔╝██╔════╝╚══██╔══╝██║██╔══██╗██╔════╝
█████═╝░██║█████═╝░██║░░██║░╚╝╚█████╗░  ██╔████╔██║░╚████╔╝░╚█████╗░░░░██║░░░██║██║░░╚═╝╚█████╗░
██╔═██╗░██║██╔═██╗░██║░░██║░░░░╚═══██╗  ██║╚██╔╝██║░░╚██╔╝░░░╚═══██╗░░░██║░░░██║██║░░██╗░╚═══██╗
██║░╚██╗██║██║░╚██╗╚█████╔╝░░░██████╔╝  ██║░╚═╝░██║░░░██║░░░██████╔╝░░░██║░░░██║╚█████╔╝██████╔╝
╚═╝░░╚═╝╚═╝╚═╝░░╚═╝░╚════╝░░░░╚═════╝░  ╚═╝░░░░░╚═╝░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═════╝░

sorry my baked goods tasted like cardboard.
at least now we have some use for them!

*/

pragma solidity ^0.8.15;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract KikosMystics is ERC721AUpgradeable, OwnableUpgradeable {
    // metadata
    string public baseURI;
    bool public metadataFrozen;
    mapping (uint256 => uint256) public cc0;
    event SetCC0(uint256 indexed tokenId);

    // constants
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public MAX_MINTED_NONESSENCE;
    uint256 public constant NONESSENCE_BURNED_KB = 10;

    // claim settings
    bool public claimEssencePaused;
    bool public claimNonEssencePaused;
    mapping (uint256 => uint256) public hasEssenceBitset;
    bool public essenceLocked;
    uint256 public totalMintedNonEssence;

    // external
    IERC721Upgradeable public KikoBakes;

    /**
     * @dev Initializes the contract
     */
    function initialize() initializerERC721A initializer public {
        __ERC721A_init("Kiko\'s Mystics", 'MYSTICS');
        __Ownable_init();
        MAX_MINTED_NONESSENCE = 2000;
    }
    // --------- config ------------

    /**
     * @dev Sets KikoBakes address
     */
    function setKikoBakes(address _kb) external onlyOwner {
        KikoBakes = IERC721Upgradeable(_kb);
    }

    /**
     * @dev Update max minted without essence. Can only be increased
     */
    function updateMaxMintedNonessence(uint256 newValue) external onlyOwner {
        require(newValue > MAX_MINTED_NONESSENCE);
        MAX_MINTED_NONESSENCE = newValue;
    }

    /**
     * @dev Gets base metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(!metadataFrozen);
        baseURI = _uri;
    }

    /**
     * @dev Freezes metadata
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen);
        metadataFrozen = true;
    }

    /**
     * @dev Pause/unpause claim with essence
     */
    function togglePauseClaimEssence() external onlyOwner {
        claimEssencePaused = !claimEssencePaused;
    }

    /**
     * @dev Pause/unpause claim without essence
     */
    function togglePauseClaimNonEssence() external onlyOwner {
        claimNonEssencePaused = !claimNonEssencePaused;
    }

    /**
     * @dev Set which token has mystic essence
     */
    function setHasEssenceBitset(uint256[] calldata _set) external onlyOwner {
        require(!essenceLocked, "Locked");
        for (uint256 i=0; i<_set.length; i++) {
            hasEssenceBitset[i] = _set[i];
        }
    }

    /**
     * @dev Set which token has mystic essence and specify starting index
     */
    function setHasEssenceBitsetFromIndex(uint256[] calldata _set, uint256 startIndex) external onlyOwner {
        require(!essenceLocked, "Locked");
        for (uint256 i=0; i<_set.length; i++) {
            hasEssenceBitset[i+startIndex] = _set[i];
        }
    }

    /**
     * @dev Locks essence bitset
     */
    function lockEssenceBitset() external onlyOwner {
        essenceLocked = true;
    }

    /**
     * @dev Gets whether token has mystic essence
     */
    function hasMysticEssence(uint256 tokenId) public view returns (bool) {
        return (hasEssenceBitset[tokenId/256] >> (tokenId % 256)) & 1 > 0;
    }

    /**
     * @dev Set CC0 status for tokens
     */
    function setCC0(uint256[] calldata tokenIds) external {
        for (uint256 i=0; i<tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "Not owner");
            emit SetCC0(tokenIds[i]);
            cc0[tokenIds[i]/256] |= 1 << tokenIds[i]%256;
        }
    }

    /**
     * @dev Get CC0 status of a token
     */
    function getCC0(uint256 tokenId) external view returns (bool) {
        return (cc0[tokenId/256] >> (tokenId%256)) & 1 > 0;
    }

    // --------- minting ------------

    /**
     * @dev Owner minting
     */
    function airdropOwner(address[] calldata addr, uint256[] calldata count) external onlyOwner {
        for (uint256 i=0; i<addr.length; i++) {
            _mint(addr[i], count[i]);
        }
        require(totalSupply() <= MAX_SUPPLY, "Supply exceeded");
    }

    /**
     * @dev Batch transfer each of tokenIds to each of toAddresses
     */
    function batchTransferOut(address[] calldata toAddresses, uint256[] calldata tokenIds) external {
        for (uint256 i=0; i < toAddresses.length; i++) {
            transferFrom(msg.sender, toAddresses[i], tokenIds[i]);
        }
    }

    /**
     * @dev Claim with essence KB
     */
    function claimEssence(uint256[] calldata tokenIds) external {
        require(!claimEssencePaused, "Paused");
        for (uint256 i=0; i<tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(hasMysticEssence(tokenId), "Must have mystic essence");
            KikoBakes.transferFrom(msg.sender, address(this), tokenId);
        }
        _mint(msg.sender, tokenIds.length);
        require(totalSupply() <= MAX_SUPPLY, "Supply exceeded");
    }

    /**
     * @dev Claim without essence KB
     */
    function claimNonEssence(uint256[] calldata tokenIds) external {
        require(!claimNonEssencePaused, "Paused");
        require(tokenIds.length % NONESSENCE_BURNED_KB == 0, "Incorrect number of tokens");
        uint256 toMint = tokenIds.length / NONESSENCE_BURNED_KB;
        for (uint256 i=0; i<tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(!hasMysticEssence(tokenId), "Must NOT have mystic essence");
            KikoBakes.transferFrom(msg.sender, address(this), tokenId);
        }
        _mint(msg.sender, toMint);
        totalMintedNonEssence += toMint;
        require(totalMintedNonEssence <= MAX_MINTED_NONESSENCE, "Non-essence supply exceeded");
        require(totalSupply() <= MAX_SUPPLY, "Supply exceeded");
    }

    /**
     * @dev Claim essence and non-essence in a single transaction
     */
    function claimAll(uint256[] calldata tokenIdsEssence, uint256[] calldata tokenIdsNonEssence) external {
        if (tokenIdsEssence.length > 0) {
            require(!claimEssencePaused, "Paused");
            for (uint256 i=0; i<tokenIdsEssence.length; i++) {
                uint256 tokenId = tokenIdsEssence[i];
                require(hasMysticEssence(tokenId), "Must have mystic essence");
                KikoBakes.transferFrom(msg.sender, address(this), tokenId);
            }
            _mint(msg.sender, tokenIdsEssence.length);
            require(totalSupply() <= MAX_SUPPLY, "Supply exceeded");
        }
        if (tokenIdsNonEssence.length > 0) {
            require(!claimNonEssencePaused, "Paused");
            require(tokenIdsNonEssence.length % NONESSENCE_BURNED_KB == 0, "Incorrect number of tokens");
            uint256 toMint = tokenIdsNonEssence.length / NONESSENCE_BURNED_KB;
            for (uint256 i=0; i<tokenIdsNonEssence.length; i++) {
                uint256 tokenId = tokenIdsNonEssence[i];
                require(!hasMysticEssence(tokenId), "Must NOT have mystic essence");
                KikoBakes.transferFrom(msg.sender, address(this), tokenId);
            }
            _mint(msg.sender, toMint);
            totalMintedNonEssence += toMint;
            require(totalMintedNonEssence <= MAX_MINTED_NONESSENCE, "Non-essence supply exceeded");
            require(totalSupply() <= MAX_SUPPLY, "Supply exceeded");
        }
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

/*

¯\_(ツ)_/¯

*/