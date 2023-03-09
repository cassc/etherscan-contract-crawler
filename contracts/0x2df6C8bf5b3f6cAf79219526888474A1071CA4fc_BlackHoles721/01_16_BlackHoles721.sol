// SPDX-License-Identifier: MIT

/*********************************
*                                *
*               •                *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/ERC721Enumerable.sol";
import "./IBlackHoleDescriptor.sol";
import "./lib/IERC4906.sol";

contract BlackHoles721 is ERC721Enumerable, Ownable, IERC4906 {
    event Merge(uint256 indexed consumerTokenId, uint256[] consumedTokenIds);
    event NameChange(uint256 indexed tokenId, string newName);

    struct BlackHole {
        string name;
        uint256 mergers;
    }

    mapping(uint256 => BlackHole) internal blackHoles;
    IBlackHoleDescriptor public descriptor;
    uint256 public maxSupply = 4200;
    uint256 public maxPrivate = 11;
    uint256 public maxPublic = 4;
    uint256 public maxNameLength = 21;
    bool public mergersEnabled = false;
    bool public minting = false;
    bool public publicMinting = false;
    bool public privateMinting = false;
    bool canUpdateMergers = true;

    mapping(address => bool) public privateWhitelist;
    mapping(address => bool) public publicWhiteList;

    constructor(IBlackHoleDescriptor newDescriptor) ERC721("BLVCK HOLES", "BLVCK") {
        descriptor = newDescriptor;
    }

    function mint(uint256 count) external payable {
        require(minting, "Cannot mint.");
        uint256 nextTokenId = _owners.length;
        unchecked {
            require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count;) {
             _mint(_msgSender(), nextTokenId);
             unchecked { ++nextTokenId; ++i; }
        }
    }

    function mintInPublic(uint256 count) external payable {
        require(publicMinting, "Cannot mint.");
        require(count < maxPublic, "Exceeds max allowed.");
        require(publicWhiteList[_msgSender()], "You are not on the whitelist.");
        uint256 nextTokenId = _owners.length;
        unchecked {
            require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count;) {
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }

        delete publicWhiteList[_msgSender()];
    }

    function mintInPrivate(uint32 count) external payable {
        require(privateMinting, "Cannot mint.");
        require(count < maxPrivate, "Exceeds max allowed.");
        require(privateWhitelist[_msgSender()], "You are not on the whitelist.");
        uint256 nextTokenId = _owners.length;
        unchecked {
           require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count;) {
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }

        delete privateWhitelist[_msgSender()];
    }

    function ownerMint(uint256 count) external payable onlyOwner {
        uint256 nextTokenId = _owners.length;
        unchecked {
           require(nextTokenId + count < maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count;) {
            _mint(_msgSender(), nextTokenId);
            unchecked { ++nextTokenId; ++i; }
        }
    }

    function setName(uint256 tokenId, string memory newName) external {
        require(mergersEnabled, "BLACK HOLES can't be named yet.");
        require(bytes(newName).length < maxNameLength, "Name too long");
        require(_exists(tokenId), "BLACK HOLE does not exist.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved.");
        blackHoles[tokenId].name = newName;
        emit NameChange(tokenId, newName);
        emit MetadataUpdate(tokenId);
    }

    function merge(uint256 consumerTokenId, uint256[] memory consumedTokenIds) external {
        require(mergersEnabled, "Can't merge yet.");
        require(_isApprovedOrOwner(_msgSender(), consumerTokenId), "Not approved.");

        uint256 count = consumedTokenIds.length;

        uint256 mergers;
        for (uint256 i; i < count;) {
            uint256 tokenId = consumedTokenIds[i];
            unchecked {
                mergers = mergers + blackHoles[tokenId].mergers + 1;
                ++i;
            }
            burn(tokenId);
        }

        unchecked {
            blackHoles[consumerTokenId].mergers += mergers;
        }

        emit Merge(consumerTokenId, consumedTokenIds);
        emit MetadataUpdate(consumerTokenId);
    }

    function setMergersEnabled(bool value) external onlyOwner {
        mergersEnabled = value;
    }

    function setDescriptor(IBlackHoleDescriptor newDescriptor) external onlyOwner {
        descriptor = newDescriptor;
    }

    function setMaxNameLength(uint256 value) external onlyOwner {
        maxNameLength = value;
    }

    function withdraw() external payable onlyOwner {
        (bool os,)= payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setPrivateMinting(bool value) external onlyOwner {
        privateMinting = value;
    }

    function setPublicMinting(bool value) external onlyOwner {
        publicMinting = value;
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function setPrivateWhitelist(address[] memory addresses) external onlyOwner {
        uint256 count = addresses.length;
        //brute force anti-merkle tree :)
        for (uint256 i; i < count;) {
            privateWhitelist[addresses[i]] = true;
            unchecked {++i;}
        }
    }

    function setPublicWhitelist(address[] memory addresses) external onlyOwner {
        uint256 count = addresses.length;

        for (uint256 i; i < count;) {
            publicWhiteList[addresses[i]] = true;
            unchecked {++i;}
        }
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        delete blackHoles[tokenId];
        _burn(tokenId);
    }

    function getBlackHole(uint256 tokenId) public view returns (BlackHole memory) {
        require(_exists(tokenId), "BLACK HOLE does not exist.");
        return blackHoles[tokenId];
    }

    function updateMergers(uint256 tokenId, uint256 mergers) external onlyOwner {
        require(canUpdateMergers, "Cannot set mergers");
        blackHoles[tokenId].mergers = mergers;
    }

    function disableMergerUpdate() external onlyOwner {
        canUpdateMergers = false;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "BLACK HOLE does not exist.");
        BlackHole memory blackHole = blackHoles[tokenId];
        return descriptor.tokenURI(tokenId, blackHole.name, blackHole.mergers);
    }

    //supports MetadataUpdate
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}