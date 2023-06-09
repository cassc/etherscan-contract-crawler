// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@amxx/hre/contracts/ENSReverseRegistration.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "./extensions/ERC721YieldUpgradeable.sol";

contract ApeGang is
    IERC1155Receiver,
    OwnableUpgradeable,
    ERC721YieldUpgradeable,
    MulticallUpgradeable
{
    address public parent;
    address public toucans;
    bytes32 public root;
    string  private baseURI;

    function initialize(
        string memory __name,
        string memory __symbol,
        IMintable     __token,
        string memory __baseURI,
        address       __parent,
        address       __toucans,
        bytes32       __migrationRoot
    )
    public
        initializer()
    {
        __ERC721_init(__name, __symbol);
        __ERC721Yield_init(__token, uint256(1 ether) / uint256(1 days));

        baseURI = __baseURI;
        parent  = __parent;
        toucans = __toucans;
        root    = __migrationRoot;
    }

    /**
     * Migrations
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        require(msg.sender == parent, "Unsuported contract");

        _migrate(id, from, abi.decode(data, (bytes32[])));

        IERC1155(msg.sender).safeTransferFrom(address(this), address(0xdead), id, amount, new bytes(0));

        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4) {
        require(msg.sender == parent, "Unsuported contract");

        bytes[] memory proofs = abi.decode(data, (bytes[]));
        require(ids.length == proofs.length, "Length missmatch");

        for (uint256 i = 0; i < ids.length; ++i) {
            _migrate(ids[i], from, abi.decode(proofs[i], (bytes32[])));
        }

        IERC1155(msg.sender).safeBatchTransferFrom(address(this), address(0xdead), ids, amounts, new bytes(0));

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function _migrate(uint256 tokenId, address from, bytes32[] memory proof) internal {
        require(IERC1155(parent).balanceOf(address(this), tokenId) == 1);
        require(MerkleProof.verify(proof, root, bytes32(tokenId)), "Invalid proof");
        _mint(from, tokenId);
    }

    /**
     * Boosting
     */
    function boostWithToucan(uint256 apeId, uint256 toucanId) external {
        IERC721(toucans).transferFrom(msg.sender, address(0xdead), toucanId);

        require(ownerOf(apeId) == msg.sender, "Cannot boost other people's ape");
        require(tokenBoost(apeId) == 0, "Token already boosted");
        _setBoost(apeId, 25);
    }

    /**
     * Admin operations
     */
    function forceMigrate(address owner, uint256 tokenId, bytes32[] memory proof)
    external
        onlyOwner()
    {
        _migrate(tokenId, owner, proof);
        IERC1155(parent).safeTransferFrom(
            address(this),
            address(0xdead),
            tokenId,
            IERC1155(parent).balanceOf(address(this), tokenId),
            new bytes(0)
        );
    }

    function setName(address ensRegistry, string calldata ensName)
    external
        onlyOwner()
    {
        ENSReverseRegistration.setName(ensRegistry, ensName);
    }

    function setBaseURI(string calldata newBaseURI)
    external
        onlyOwner()
    {
        baseURI = newBaseURI;
    }

    /**
     * Override
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Upgradeable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseURI;
    }
}