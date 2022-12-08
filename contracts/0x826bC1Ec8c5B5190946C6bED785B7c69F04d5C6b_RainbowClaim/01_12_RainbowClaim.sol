// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RainbowClaim is
    Initializable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    bytes32 public merkleRoot;
    address public pixelAddress;
    uint256[] public pixelIds;
    mapping(address => bool) public addressHasClaimed;

    function initialize(address _pixelAddress, bytes32 _merkleRoot)
        public
        initializer
    {
        __Ownable_init();
        pixelAddress = _pixelAddress;
        merkleRoot = _merkleRoot;
    }

    function claim(bytes32[] calldata _merkleProof) public {
        require(
            this.isAddressInMerkleTree(_merkleProof, msg.sender),
            "Not in whitelisted addresses"
        );

        require(pixelIds.length > 0, "No more pixels");
        require(!addressHasClaimed[msg.sender], "Address has already claimed");

        uint256 index = getPsuedoRandom(pixelIds.length);
        uint256 tokenId = pixelIds[index];
        address tokenOwner = IERC721(pixelAddress).ownerOf(tokenId);
        require(
            tokenOwner == address(this),
            "Contract does not own this token"
        );
        addressHasClaimed[msg.sender] = true;
        pixelIds[index] = pixelIds[pixelIds.length - 1];
        pixelIds.pop();
        IERC721(pixelAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            ""
        );
    }

    function deposit(uint256[] calldata _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(pixelAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i],
                ""
            );
        }
    }

    function withdrawPixels() external onlyOwner {
        for (uint256 i = 0; i < pixelIds.length; i++) {
            IERC721(pixelAddress).safeTransferFrom(
                address(this),
                msg.sender,
                pixelIds[i],
                ""
            );
        }
        delete pixelIds;
    }

    function isAddressInMerkleTree(
        bytes32[] calldata _merkleProof,
        address _address
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getPsuedoRandom(uint256 _mod) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % _mod;
    }

    function getPixelIds() public view returns (uint256[] memory) {
        uint256[] memory _pixelIds = pixelIds;
        return _pixelIds;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        if (msg.sender == pixelAddress) {
            // save available pixel id
            pixelIds.push(tokenId);
        }
        return this.onERC721Received.selector;
    }
}