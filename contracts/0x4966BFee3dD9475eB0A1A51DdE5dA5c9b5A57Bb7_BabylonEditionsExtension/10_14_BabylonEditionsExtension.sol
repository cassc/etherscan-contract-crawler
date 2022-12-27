// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./interfaces/IBabylonCore.sol";
import "./interfaces/IEditionsExtension.sol";
import "./editions/BabylonEditions.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

contract BabylonEditionsExtension is Ownable, IEditionsExtension, ICreatorExtensionTokenURI {
    address internal _core;

    // id of a listing -> collection address
    mapping(uint256 => address) internal _editions;

    // Mapping for token URIs of Editions collections
    mapping(address => string) internal _editionURIs;

    // Max royalties basis points is 1000 (10%)
    uint256 constant MAX_ROYALTIES_BPS = 1000;

    event EditionRegistered(uint256 listingId, address editionsCollection, address newOwner, string editionsURI);
    event EditionMinted(uint256 listingId, address editionsCollection, address receiver, uint256 amount);

    function registerEdition(
        EditionInfo calldata info,
        address creator,
        uint256 listingId
    ) external override {
        require(msg.sender == _core, "BabylonEditionsExtension: Only BabylonCore can register");
        require(_editions[listingId] == address(0), "BabylonEditionsExtension: Edition already registered for this listing");
        require(info.royaltiesBps <= MAX_ROYALTIES_BPS, "BabylonEditionsExtension: Royalties BPS too high");

        address newEditions = address(new BabylonEditions(info.name));
        address payable[] memory receivers = new address payable[](1);
        receivers[0] = payable(creator);
        uint256[] memory basisPoints = new uint256[](1);
        basisPoints[0] = info.royaltiesBps;
        IERC721CreatorCore(newEditions).setRoyalties(receivers, basisPoints);
        IERC721CreatorCore(newEditions).registerExtension(address(this), "");
        Ownable(newEditions).transferOwnership(creator);

        _editions[listingId] = newEditions;
        _editionURIs[newEditions] = info.editionURI;

        emit EditionRegistered(listingId, newEditions, creator, info.editionURI);
    }

    function mintEdition(uint256 listingId, address receiver, uint256 amount) external override {
        require(msg.sender == _core, "BabylonEditionsExtension: Only BabylonCore can mint");
        address editionsCollection = _editions[listingId];
        require(editionsCollection != address(0), "BabylonEditionsExtension: Edition should exist for this listing");

        IERC721CreatorCore(editionsCollection).mintExtensionBatch(receiver, uint16(amount));

        emit EditionMinted(listingId, editionsCollection, receiver, amount);
    }

    function setBabylonCore(address core) external onlyOwner {
        _core = core;
    }

    function getEditionsCollection(uint256 listingId) external view returns (address) {
        return _editions[listingId];
    }

    function getEditionURI(uint256 listingId) external view returns (string memory) {
        return _editionURIs[_editions[listingId]];
    }

    function getBabylonCore() external view returns (address) {
        return _core;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function tokenURI(address core, uint256 tokenId) external view override returns (string memory) {
        return _editionURIs[core];
    }
}