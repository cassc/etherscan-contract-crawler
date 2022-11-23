// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IGudSoulbound721.sol";
import "./Soulbound721Upgradable.sol";

contract GudSoulbound721 is IGudSoulbound721, Soulbound721Upgradable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    error InvalidNumTiers();
    error InsufficientValue();
    error PublicMintingDisabled(uint8 tier);
    error ExceedsMaxOwnership(uint8 tier);
    error ExceedsMaxMerkleMintUses(uint8 tier);
    error ExceedsMaxSupply(uint8 tier);
    error NotOwner();
    error IncorrectOwnerSignature();
    error IncorrectMerkleProof();
    error WithdrawFailed();
    error NoSuchToken(uint256 tokenId);

    Tier[] private _tiers;
    mapping(uint8 /*tier*/ => uint248 /*numMinted*/) _numMinted;
    mapping(address /*owner*/ => mapping(uint8 /*tier*/ => uint248 /*numOwned*/)) private _numOwned;
    bytes32 private _mintMerkleRoot;
    bytes32 private _numMerkleRoots;
    mapping(address /*owner*/ => mapping(uint8 /*tier*/ => uint248 /*numMinted*/))[] private _merkleMintUses;

    function initialize(string memory name, string memory symbol, Tier[] memory tiers) external initializer {
        OwnableUpgradeable.__Ownable_init();
        Soulbound721Upgradable.__ERC721_init(name, symbol);
        setTiers(tiers);
    }

    function mint(address to, uint248[] calldata numMints) external payable {
        uint256 totalPrice = 0;
        for (uint i = 0; i < numMints.length; ++i) {
            if (numMints[i] != 0 && _tiers[i].publicPrice == type(uint256).max) {
                revert PublicMintingDisabled(uint8(i));
            }
            totalPrice += _tiers[i].publicPrice * numMints[i];
        }
        _mint(to, numMints, totalPrice);
    }

    function mint(
        uint248[] calldata numMints,
        MerkleMint calldata merkleMint,
        bytes32[] calldata merkleProof
    ) external payable {
        if (MerkleProofUpgradeable.verify(
            merkleProof,
            _mintMerkleRoot,
            keccak256(abi.encode(merkleMint.to, merkleMint.tierMaxMints,merkleMint.tierPrices))
        ) == false) {
            revert IncorrectMerkleProof();
        }
        mapping(uint8 => uint248) storage merkleMintUses = _merkleMintUses[_merkleMintUses.length - 1][merkleMint.to];
        uint256 totalPrice = 0;

        for (uint i = 0; i < numMints.length; ++i) {
            if (merkleMintUses[uint8(i)] + numMints[i] > merkleMint.tierMaxMints[i]) {
                revert ExceedsMaxMerkleMintUses(uint8(i));
            }
            merkleMintUses[uint8(i)] += numMints[i];

            totalPrice += merkleMint.tierPrices[i] * numMints[i];
        }
        _mint(merkleMint.to, numMints, totalPrice);

        emit MerkleMintUsed(merkleMint, numMints);
    }

    function burn(uint256 tokenId) external {
        if (ownerOf(tokenId) != _msgSender()) {
            revert NotOwner();
        }
        _burn(tokenId);
        _numOwned[msg.sender][uint8(tokenId >> 248)] -= 1;
        emit TokenBurned(tokenId);
    }

    function setTiers(Tier[] memory tiers) public onlyOwner {
        delete _tiers;

        if (tiers.length > type(uint8).max) {
            revert InvalidNumTiers();
        }

        for (uint i = 0; i < tiers.length; ++i) {
            _tiers.push(tiers[i]);
        }

        emit TiersSet(tiers);
    }

    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        if (success == false) {
            revert WithdrawFailed();
        }
        emit EtherWithdrawn(to, amount);
    }

    function setMintMerkleRoot(bytes32 mintMerkleRoot) external onlyOwner {
        _mintMerkleRoot = mintMerkleRoot;
        _merkleMintUses.push();
        emit MintMerkleRootSet(mintMerkleRoot);
    }

    function getTiers() external view returns (Tier[] memory) {
        return _tiers;
    }

    function numMinted(uint8 tier) external view returns (uint248) {
        return _numMinted[tier];
    }

    function numOwned(address owner, uint8 tier) external view returns (uint248) {
        return _numOwned[owner][tier];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Soulbound721Upgradable, IERC165Upgradeable)
        returns (bool)
    {
            return interfaceId == type(IGudSoulbound721).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721MetadataUpgradeable, Soulbound721Upgradable)
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) {
            revert NoSuchToken(tokenId);
        }
        Tier storage tier = _tiers[tokenId >> 248];
        if (tier.idInUri) {
            return string.concat("ipfs://", tier.cid, "/", Strings.toString(uint248(tokenId)), ".json");
        } else {
            return string.concat("ipfs://", tier.cid, "/metadata.json");
        }
    }

    function _mint(address to, uint248[] calldata numMints, uint256 totalPrice) private {
        for (uint tierNum = 0; tierNum < numMints.length; ++tierNum) {
            Tier storage tier = _tiers[tierNum];

            if (_numOwned[to][uint8(tierNum)] + numMints[tierNum] > tier.maxOwnable) {
                revert ExceedsMaxOwnership(uint8(tierNum));
            }
            if (_numMinted[uint8(tierNum)] + numMints[tierNum] > tier.maxSupply) {
                revert ExceedsMaxSupply(uint8(tierNum));
            }

            uint256 tokenId = (tierNum << 248) + _numMinted[uint8(tierNum)];
            for (uint j = 0; j < numMints[tierNum]; ++j) {
                _safeMint(to, ++tokenId);
            }
            _numOwned[to][uint8(tierNum)] += numMints[uint8(tierNum)];
            _numMinted[uint8(tierNum)] += numMints[uint8(tierNum)];
        }

        if (totalPrice > msg.value) {
            revert InsufficientValue();
        }
    }
}