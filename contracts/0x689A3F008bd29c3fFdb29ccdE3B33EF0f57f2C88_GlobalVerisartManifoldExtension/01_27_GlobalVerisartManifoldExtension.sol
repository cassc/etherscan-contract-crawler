// SPDX-License-Identifier: MIT
import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionRoyalties.sol";

pragma solidity ^0.8.9;


/**
 * Shared Manifold extension which supports letting users add arbitrary minting permissions
 * and per token royalties set at the time of minting.
 *
 * Version: 1.1
 */
contract GlobalVerisartManifoldExtension is ICreatorExtensionRoyalties  {

    struct RoyaltyConfig {
        address payable receiver;
        uint16 bps;
    }

    event Granted(address indexed creatorContract, address indexed account);
    event Revoked(address indexed creatorContract, address indexed account);
    event RoyaltiesUpdated(address indexed creatorContract, uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address indexed creatorContract, address payable[] receivers, uint256[] basisPoints);

    mapping(address => mapping(address => bool)) private _permissions;

    mapping(address => mapping(uint256 => RoyaltyConfig[])) private _tokenRoyalties;
    mapping(address => RoyaltyConfig[]) private _defaultRoyalties;

    function supportsInterface(bytes4 interfaceId) external view virtual override(IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionRoyalties).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function hasMintingPermission(address creatorContract, address creator) public view returns (bool) {
        return _permissions[creatorContract][creator];
    }

    function grantMinting(address creatorContract, address creator) external {
        require(ERC721Creator(creatorContract).isAdmin(msg.sender), "Must be admin");
        _permissions[creatorContract][creator] = true;
        emit Granted(creatorContract, creator);
    }

    function revokeMinting(address creatorContract, address creator) external {
        require(ERC721Creator(creatorContract).isAdmin(msg.sender), "Must be admin");
        _permissions[creatorContract][creator] = false;
        emit Revoked(creatorContract, creator);
    }

    function mint(address creatorContract, address to, string calldata uri, address payable[] calldata receivers, uint256[] calldata basisPoints) external {
        ERC721Creator creatorCon = _checkIsGranted(creatorContract);
        _checkRoyalties(receivers, basisPoints);
        uint256 tokenId = creatorCon.mintExtension(to, uri);
        _setTokenRoyalties(creatorContract, tokenId, receivers, basisPoints);
    }

    function mintBatch(address creatorContract, address to, string[] calldata uris, address payable[][] calldata receiversPerToken, uint256[][] calldata basisPointsPerToken) external {
        ERC721Creator creatorCon = _checkIsGranted(creatorContract);

        require(receiversPerToken.length == basisPointsPerToken.length, "Mismatch in array lengths");
        require(receiversPerToken.length == 0 || receiversPerToken.length == uris.length, "Incorrect royalty array length");
        for (uint256 i = 0; i < receiversPerToken.length; i++) {
            _checkRoyalties(receiversPerToken[i], basisPointsPerToken[i]);
        }

        uint256[] memory tokenIds = creatorCon.mintExtensionBatch(to, uris);

        if (receiversPerToken.length != 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                _setTokenRoyalties(creatorContract, tokenIds[i], receiversPerToken[i], basisPointsPerToken[i]);
            }
        }
    }

    function setTokenRoyalties(address creatorContract, uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external {
        _checkIsGranted(creatorContract);
        _checkRoyalties(receivers, basisPoints);
        _setTokenRoyalties(creatorContract, tokenId, receivers, basisPoints);
        emit RoyaltiesUpdated(creatorContract, tokenId, receivers, basisPoints);
    }

    function setDefaultRoyalties(address creatorContract, address payable[] calldata receivers, uint256[] calldata basisPoints) external {
        _checkIsGranted(creatorContract);
        _checkRoyalties(receivers, basisPoints);
        delete _defaultRoyalties[creatorContract];
        _setRoyalties(receivers, basisPoints, _defaultRoyalties[creatorContract]);
        emit DefaultRoyaltiesUpdated(creatorContract, receivers, basisPoints);
    }

    function getRoyalties(address creator, uint256 tokenId) external virtual view override returns (address payable[] memory, uint256[] memory) {
        RoyaltyConfig[] memory royalties = _tokenRoyalties[creator][tokenId];

        if (royalties.length == 0) {
            royalties = _defaultRoyalties[creator];
        }

        address payable[] memory receivers = new address payable[](royalties.length);
        uint256[] memory bps = new uint256[](royalties.length);
        for (uint i; i < royalties.length;) {
            receivers[i] = royalties[i].receiver;
            bps[i] = royalties[i].bps;
            unchecked { ++i; }
        }

        return (receivers, bps);
    }

    function _setTokenRoyalties(address creatorContract, uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) private {
        delete _tokenRoyalties[creatorContract][tokenId];
        _setRoyalties(receivers, basisPoints, _tokenRoyalties[creatorContract][tokenId]);
    }

    function _setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints, RoyaltyConfig[] storage royalties) private {
        for (uint i; i < basisPoints.length;) {
            royalties.push(
                RoyaltyConfig({
                    receiver: receivers[i],
                    bps: uint16(basisPoints[i])
                })
            );
            unchecked { ++i; }
        }
    }

    function _checkIsGranted(address creatorContract) private view returns (ERC721Creator) {
        ERC721Creator creatorCon = ERC721Creator(creatorContract);
        require(hasMintingPermission(creatorContract, msg.sender) || creatorCon.isAdmin(msg.sender), "Permission denied");
        return creatorCon;
    }

    function _checkRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) private pure {
        require(receivers.length == basisPoints.length, "Mismatch in array lengths");
        uint256 totalBasisPoints;
        for (uint i; i < basisPoints.length;) {
            totalBasisPoints += basisPoints[i];
            unchecked { ++i; }
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
    }
}