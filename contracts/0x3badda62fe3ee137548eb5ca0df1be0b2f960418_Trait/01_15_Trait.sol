// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC721.sol";
import "./IQueensAndKingsAvatars.sol";

contract Trait is ERC721 {
    event TraitChanged(uint16 indexed _avatarId, uint16 indexed _traitId);

    modifier onlyAvatarContract() {
        require(avatarContractAddress == msg.sender, "Caller is not the avatar contract");

        _;
    }

    string public baseURI = "ipfs://HASH/";
    uint16 public totalSupply = 0;

    address public avatarContractAddress;

    // trait => avatar
    mapping(uint16 => uint16) public traitToAvatar;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    // ONLY OWNER

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Sets the avatar contract address.
     */
    function setAvatarContractAddress(address _avatarContractAddress) external onlyOwner {
        avatarContractAddress = _avatarContractAddress;
    }

    // END ONLY OWNER

    // ONLY MINTER

    /**
     * @dev Mints a token
     */
    function mint(uint256 _tokenId, address _to) external onlyMinter {
        require(_tokenId > 0, "Token ID cannot be 0");

        _mint(_to, _tokenId);

        totalSupply++;
    }

    function burn(uint16 _tokenId) external onlyMinter {
        _burn(_tokenId);
    }

    // END ONLY MINTER

    // ONLY AVATAR CONTRACT

    /**
     * @dev sets to what avatar a trait is assigned
     */
    function onTraitAddedToAvatar(uint16 _tokenId, uint16 _avatarId) external onlyAvatarContract {
        traitToAvatar[_tokenId] = _avatarId;
        emit TraitChanged(_avatarId, _tokenId);
    }

    /**
     * @dev removes the traitToAvatar relation and if the current owner
     * hasn't been updated on the trait, it updates it.
     */
    function onTraitRemovedFromAvatar(uint16 _tokenId, address _owner) external onlyAvatarContract {
        if (_owners[_tokenId] != _owner) {
            _owners[_tokenId] = _owner;
        }

        emit TraitChanged(traitToAvatar[_tokenId], _tokenId);
        traitToAvatar[_tokenId] = 0;
    }

    /**
     * @dev emits the transfer event when an avatar with a trait is transferred
     */
    function onAvatarTransfer(
        address _from,
        address _to,
        uint16 _tokenId
    ) external onlyAvatarContract {
        require(_exists(_tokenId), "Avatar transfer for a non existent token");

        _balances[_from] -= 1;
        _balances[_to] += 1;
        if (_tokenApprovals[_tokenId] != address(0)) {
            _tokenApprovals[_tokenId] = address(0);
        }

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     @dev Returns wether a token exists or not
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // END ONLY AVATAR CONTRACT

    // CUSTOM ERC721

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        IQueensAndKingsAvatars qakContract = IQueensAndKingsAvatars(avatarContractAddress);

        if (traitToAvatar[uint16(tokenId)] != 0) {
            return qakContract.ownerOf(traitToAvatar[uint16(tokenId)]);
        }

        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721 Trait: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev See {ERC721}.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        ERC721._transfer(from, to, tokenId);
        IQueensAndKingsAvatars qakContract = IQueensAndKingsAvatars(avatarContractAddress);
        uint16 _tokenId = uint16(tokenId);

        if (traitToAvatar[_tokenId] != 0) {
            qakContract.removeTrait(traitToAvatar[_tokenId]);
        }

        traitToAvatar[_tokenId] = 0;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        IQueensAndKingsAvatars qakContract = IQueensAndKingsAvatars(avatarContractAddress);

        if (traitToAvatar[uint16(tokenId)] != 0) {
            return qakContract.getApproved(traitToAvatar[uint16(tokenId)]);
        }

        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[uint16(tokenId)];
    }

    // END CUSTOM ERC721

    function traitToExternalAvatarID(uint16 _tokenId) external view returns (uint256) {
        IQueensAndKingsAvatars qakContract = IQueensAndKingsAvatars(avatarContractAddress);

        return qakContract.internalToExternalMapping(traitToAvatar[_tokenId]);
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}