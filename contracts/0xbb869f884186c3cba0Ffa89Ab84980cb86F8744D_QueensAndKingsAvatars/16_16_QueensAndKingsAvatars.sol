// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol";
import "./ITrait.sol";

contract QueensAndKingsAvatars is ERC721 {
    using Strings for uint256;

    modifier onlyAvatarOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the avatar");

        _;
    }

    address public signerAddress;

    string public baseURI = "ipfs://HASH/";
    uint16 public totalTokens = 6900;
    uint16 public totalSupply = 0;
    uint256 public latestExternalTokenId = totalTokens + 1;

    address[] public traitTypeToAddress;

    // TokenId => Trait => TraitId
    mapping(uint16 => mapping(uint8 => uint16)) public avatarTraits;
    mapping(uint16 => bool) public hasMintedTraits;
    mapping(uint256 => uint16) public externalToInternalMapping;
    mapping(uint16 => uint256) public internalToExternalMapping;
    mapping(uint16 => bool) public frozenAvatars;

    bool isFreezeAllowed;

    constructor() ERC721("Queens+KingsAvatars", "Q+KA") {}

    // ONLY OWNER

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Adds the contract address of a trait type
     */
    function addTraitType(address _traitAddress) external onlyOwner {
        traitTypeToAddress.push(_traitAddress);
    }

    /**
     * @dev Adds the contract address of a trait type
     */
    function resetTraitTypes() external onlyOwner {
        delete traitTypeToAddress;
    }

    function setFreezedAllowed(bool _isFreezeAllowed) external onlyOwner {
        isFreezeAllowed = _isFreezeAllowed;
    }

    // END ONLY OWNER

    // ONLY MINTER

    /**
     * @dev Mints a avatars
     */
    function mint(uint16 _tokenId, address _to) external onlyMinter {
        require(_tokenId > 0 && _tokenId <= totalTokens, "Token ID cannot be 0");
        require(totalSupply < totalTokens, "Cannot mint more avatars");

        externalToInternalMapping[_tokenId] = _tokenId;
        internalToExternalMapping[_tokenId] = _tokenId;

        totalSupply++;

        _mint(_to, _tokenId);
    }

    // END ONLY MITNER

    // ONLY AVATAR OWNER

    /**
     * @dev Adds full traits to an avatar
     */
    function setTraitsToAvatar(uint256 _tokenId, uint16[] memory _traits) external onlyAvatarOwner(_tokenId) {
        require(traitTypeToAddress.length == _traits.length, "Invalid amount of traits");
        uint16 _iTokenId = getInternalMapping(_tokenId);
        require(hasMintedTraits[_iTokenId], "Can not modify avatar until original traits are minted");

        require(!frozenAvatars[_iTokenId], "Can not change the traits of a frozen avatar");

        bool regenerate;
        uint256[] memory traitsPreviousAvatar = new uint256[](_traits.length);
        uint256 regeneratePreviousAvatarCounter;

        for (uint8 i; i < _traits.length; i++) {
            if (_traits[i] == avatarTraits[_iTokenId][i]) {
                continue;
            }

            ITrait trait = ITrait(traitTypeToAddress[i]);

            require(_traits[i] == 0 || trait.ownerOf(_traits[i]) == msg.sender, "Caller is not the owner of the trait");

            uint16 newTraitCurrentAvatarId = trait.traitToAvatar(_traits[i]);

            if (newTraitCurrentAvatarId != 0 && newTraitCurrentAvatarId != _iTokenId) {
                avatarTraits[newTraitCurrentAvatarId][i] = 0;

                traitsPreviousAvatar[regeneratePreviousAvatarCounter] = getExternalMapping(newTraitCurrentAvatarId);

                regeneratePreviousAvatarCounter++;
            }

            if (avatarTraits[_iTokenId][i] != 0) {
                regenerate = true;
                trait.onTraitRemovedFromAvatar(avatarTraits[_iTokenId][i], ownerOf(_tokenId));
            }

            avatarTraits[_iTokenId][i] = _traits[i];

            if (_traits[i] != 0) {
                trait.onTraitAddedToAvatar(_traits[i], _iTokenId);
            }
        }

        for (uint256 i; i < regeneratePreviousAvatarCounter; i++) {
            if (_exists(traitsPreviousAvatar[i])) {
                regenerateAvatar(traitsPreviousAvatar[i]);
            }
        }

        if (regenerate) {
            regenerateAvatar(_tokenId);
        }
    }

    /**
     * @dev mints the traits for a given avatar
     */
    function mintTraits(
        uint16 _tokenId,
        uint16[] memory _traits,
        bytes calldata _signature
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the avatar");
        require(_tokenId <= totalTokens, "Invalid token Id");
        require(!hasMintedTraits[_tokenId], "Traits already minted");

        bytes32 messageHash = generateMessageHash(_tokenId, _traits);
        address recoveredWallet = ECDSA.recover(messageHash, _signature);
        require(recoveredWallet == signerAddress, "Invalid signature for the caller");

        hasMintedTraits[_tokenId] = true;

        for (uint8 i; i < _traits.length; i++) {
            if (_traits[i] == 0) {
                continue;
            }

            ITrait trait = ITrait(traitTypeToAddress[i]);
            trait.mint(_traits[i], msg.sender);

            avatarTraits[_tokenId][i] = _traits[i];

            trait.onTraitAddedToAvatar(_traits[i], _tokenId);
        }
    }

    function freeze(uint256 _tokenId) external {
        require(isFreezeAllowed, "Cannot freeze at this stage");
        uint16 _iTokenId = getInternalMapping(_tokenId);

        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the avatar");
        require(hasMintedTraits[_iTokenId], "Traits have not been minted");
        require(!frozenAvatars[_iTokenId], "Avatar is already frozen");

        frozenAvatars[_iTokenId] = true;

        for (uint8 i; i < traitTypeToAddress.length; i++) {
            if (avatarTraits[_iTokenId][i] == 0) {
                continue;
            }

            ITrait trait = ITrait(traitTypeToAddress[i]);
            trait.burn(avatarTraits[_iTokenId][i]);
        }
    }

    // END ONLY AVATAR OWNER

    // ONLY TRAIT CONTRACTS

    /**
     * @dev removes a single trait from an avatar
     * by it's contract type
     */
    function removeTrait(uint16 _iTokenId) external {
        require(!frozenAvatars[_iTokenId], "Avatar is already frozen");
        bool found;

        uint256 _tokenId = getExternalMapping(_iTokenId);

        for (uint8 i; i < traitTypeToAddress.length; i++) {
            if (traitTypeToAddress[i] == msg.sender) {
                avatarTraits[getInternalMapping(_tokenId)][i] = 0;
                found = true;

                break;
            }
        }

        require(found, "Caller is not allowed");

        regenerateAvatar(_tokenId);
    }

    // END ONLY TRAIT CONTRACTS

    // CUSTOM ERC721

    /**
     * @dev See {ERC721}.
     *
     * Calls avatarTransfer for all the traits that the avatar has
     * in order to emit the transfer event for all the traits
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        uint16 _iTokenId = getInternalMapping(tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), uint16(tokenId));

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[_iTokenId] = to;

        emit Transfer(from, to, tokenId);

        for (uint8 i; i < traitTypeToAddress.length; i++) {
            if (avatarTraits[_iTokenId][i] == 0) {
                continue;
            }

            ITrait traitContract = ITrait(traitTypeToAddress[i]);
            traitContract.onAvatarTransfer(from, to, avatarTraits[_iTokenId][i]);
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        uint16 _iTokenId;
        if (tokenId > totalTokens) {
            _iTokenId = getInternalMapping(tokenId);
        } else {
            _iTokenId = uint16(tokenId);
        }

        address owner = _owners[_iTokenId];
        require(owner != address(0), "ERC721 Avatar: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev See {IRC721-_exists}.
     */
    function _exists(uint256 tokenId) internal view override returns (bool) {
        uint16 _iTokenId = externalToInternalMapping[tokenId];

        return _owners[_iTokenId] != address(0);
    }

    /**
     * @dev See {ERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[getInternalMapping(tokenId)];
    }

    /**
     * @dev See {ERC721-_approve}.
     */
    function _approve(address to, uint16 tokenId) internal virtual override {
        _tokenApprovals[getInternalMapping(tokenId)] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // END CUSTOM ERC721

    /**
     * @dev Returns the traits for the given token id
     */
    function getAvatarTraits(uint256 _tokenId) external view returns (uint16[] memory) {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");

        uint16 _iTokenId = getInternalMapping(_tokenId);

        uint16[] memory traits = new uint16[](traitTypeToAddress.length);
        for (uint8 i; i < traitTypeToAddress.length; i++) {
            traits[i] = avatarTraits[_iTokenId][i];
        }

        return traits;
    }

    // INTERNAL

    /**
     * @dev to avoid users receiving offers for their complete avatars, removing
     * the parts and accepting the offers; The NFT changes ID every time a part is removed
     * or replaced
     */
    function regenerateAvatar(uint256 _tokenId) internal returns (uint256) {
        address _owner = ownerOf(_tokenId);

        emit Transfer(_owner, address(0), _tokenId);
        emit Transfer(address(0), _owner, latestExternalTokenId);

        uint16 _iTokenId = getInternalMapping(_tokenId);

        externalToInternalMapping[latestExternalTokenId] = _iTokenId;
        internalToExternalMapping[_iTokenId] = latestExternalTokenId;

        delete externalToInternalMapping[_tokenId];

        latestExternalTokenId++;

        return latestExternalTokenId - 1;
    }

    /**
     * @dev returns the original id for the given avatar
     */
    function getInternalMapping(uint256 _tokenId) internal view returns (uint16) {
        require(externalToInternalMapping[_tokenId] != 0, "getInternalMapping: Invalid mapping");

        return externalToInternalMapping[_tokenId];
    }

    /**
     8 @dev returns the external id for the original given id
     */
    function getExternalMapping(uint16 _iTokenId) internal view returns (uint256) {
        require(internalToExternalMapping[_iTokenId] != 0, "getExternalMapping: Invalid mapping");

        return internalToExternalMapping[_iTokenId];
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Generate a message hash for the given parameters
     */
    function generateMessageHash(uint256 _avatarId, uint16[] memory _traitIds) internal pure returns (bytes32) {
        uint256 signatureBytes = 32 + _traitIds.length * 32;

        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n", signatureBytes.toString(), _avatarId, _traitIds)
            );
    }
}