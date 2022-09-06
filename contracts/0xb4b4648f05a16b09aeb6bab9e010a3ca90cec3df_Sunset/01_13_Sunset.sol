// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IIdentityVerifier is IERC165 {
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);
}

/**
 * Inspired by "bid theory"
 *
 * Thanks to Kaesha for sharing this sunset with me 💕
 */
contract Sunset is AdminControl, IIdentityVerifier, ICreatorExtensionTokenURI {
    using Strings for uint256;

    address _marketplace;
    address _creator;
    bytes32 _merkleRoot;

    address _highBid;
    address _secondBid;

    string _baseURI;
    string _stillImageBaseURI;

    uint bids;

    // Maps token ID to BidAmount (which is the seed)
    mapping(uint => uint) giftSeeds;

    function configure(address marketplace, address creator, bytes32 merkleRoot) public adminRequired {
        _marketplace = marketplace;
        _creator = creator;
        _merkleRoot = merkleRoot;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IIdentityVerifier).interfaceId || super.supportsInterface(interfaceId);
    }

    function verify(uint40, address identity, address, uint256, uint24, uint256 bidAmount, address, bytes calldata data) external override returns (bool) {
        require(msg.sender == _marketplace, "Can only be be called by the marketplace");

        bytes32 leaf = keccak256(abi.encodePacked(identity));
        bytes32[] memory proof = abi.decode(data, (bytes32[]));

        require(MerkleProof.verify(proof, _merkleRoot, leaf), "Not allowed to bid");

        // Drop the high bid to second bid
        _secondBid = _highBid;

        // High bid is current bidder
        _highBid = identity;

        // Add to how many bids
        bids++;

        // Save seed at bid index
        giftSeeds[bids] = bidAmount;

        // Mint to the currently second bid (never to high bid, as they will win auction)
        if (_secondBid != address(0)) {
            mintPieceForBid(_secondBid);
        }

        return true;
    }

    function verifyView(uint40, address identity, address, uint256, uint24, uint256, address, bytes calldata data) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(identity));
        bytes32[] memory proof = abi.decode(data, (bytes32[]));

        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    function mintPieceForBid(address identity) internal {
      IERC721CreatorCore(_creator).mintExtension(identity);
    }

    function setBaseURI(string memory baseURI) public adminRequired {
        _baseURI = baseURI;
    }

    function setStillImageBaseURI(string memory stillImageBaseURI) public adminRequired {
      _stillImageBaseURI = stillImageBaseURI;
    }

    // Will be called with tokenId 2 -> X
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && tokenId > 1 && bids+1 > tokenId, "Invalid token");
        return string(abi.encodePacked('data:application/json;utf8,',
        '{"name":"Sunset #',
        tokenId.toString(),
        '","created_by":"yung wknd","description":"To be shared...","image":"',
        string(abi.encodePacked(_stillImageBaseURI, tokenId.toString())),
        '","image_url":"',
        string(abi.encodePacked(_stillImageBaseURI, tokenId.toString())),
        '","animation":"',
        animationURL(tokenId),
        '","animation_url":"',
        animationURL(tokenId),
        '","attributes":[',
        _wrapTrait("Bid Amount", getDecimalETH(giftSeeds[tokenId-1])),
        ']}'));
    }

    function getDecimalETH(uint bidAmount) private pure returns (string memory) {
        uint leftPart = bidAmount / 1 ether;
        uint rightPart =  100 * (bidAmount - (leftPart * 1 ether)) / 1 ether;
        return string(abi.encodePacked(leftPart.toString(), ".", rightPart.toString()));
    }

    function _wrapTrait(string memory trait, string memory value) private pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function animationURL(uint256 tokenId) private view returns (string memory) {
        // 2nd token is first bid
        uint seed = giftSeeds[tokenId-1];

        // Second to last bid
        if (tokenId == bids) {
            return string(abi.encodePacked(_baseURI, seed.toString(), "&special=true"));
        }

        return string(abi.encodePacked(_baseURI, seed.toString()));
    }

}