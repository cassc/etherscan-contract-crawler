// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

import "./ICoucou.sol";

contract CoucouAlpha is ERC721AUpgradeable, ICoucou, OwnableUpgradeable {

    using StringsUpgradeable for uint256;

    bytes32 public merkleRoot;

    uint public saleTime;
    
    function initialize() initializerERC721A initializer public {
        __ERC721A_init("CoucouNFT - Alpha", "CCA");
        __Ownable_init();
        saleTime = 2 ** 256 - 1;
    }

    function freeMint(uint256 quantity, bytes32[] calldata merkleProof) external payable override {
        require(block.timestamp >= saleTime, "please wait for the sale");
        require(totalSupply() + quantity <= _maxSupply(), "mint exceeded");
        require(_numberMinted(_msgSender()) == 0, "can't mint more");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, quantity));
        require(MerkleProofUpgradeable.verify(merkleProof, merkleRoot, leaf), "invalid proof");

        _mint(_msgSender(), quantity);
    }

    function publicMint(uint256 quantity) external payable override {
        require(block.timestamp >= saleTime, "please wait for the sale");
        require(quantity <= _onceMaxMintQuantity(), "each mint is limited to two");
        require(totalSupply() + quantity <= _maxSupply(), "mint exceeded");
        require(msg.value >= _mintPrice() * quantity, "insufficient Payment");

        _mint(_msgSender(), quantity);
    }

    function mintPrice() external pure override returns (uint) {
        return _mintPrice();
    }

    function updateMerkleRoot(bytes32 _root) external onlyOwner override {
        merkleRoot = _root;
    }

    function updateSaleTime(uint _time) external onlyOwner override {
        saleTime = _time;
    }

    function withdrawFunds(address _to) external onlyOwner override {
        payable(_to).transfer(address(this).balance);
    }

    function _maxSupply() internal pure returns (uint) {
        return 100;
    }

    function _mintPrice() internal pure returns (uint) {
        return 0.069 ether;
    }

    function _onceMaxMintQuantity() internal pure returns (uint) {
        return 2;
    }

    function _startTokenId() internal pure override returns (uint) {
        return 1;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmV1Z7wnhYpShsPP6yEouFuEP8tXL3VzQwGJ6PDiA1U6n3/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _exists(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function contractURI() public view returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    'data:application/json;base64,',
                    Base64Upgradeable.encode(
                        abi.encodePacked(
                            '{"name":"', 
                            name(),
                            '","description":"',
                            _contractDescription(),
                            '","image":"',
                            _contractImage(),
                            '"}'
                        )
                    )
                    /* solhint-enable */
                )
            );
    }

    function _contractImage() internal pure returns (bytes memory) {
        return "ipfs://QmdehWRRaSJLX63TSzkLHJUh5HqB9EHaEunyT3g3D8ZBxW";
    }

    function _contractDescription() internal pure returns (string memory) {
        return 
            'Inspired by the disgust of the behavior of \\"bear children\\", we explore the nature of human nature. '
            'Human nature is the instinctive desires we repress deep inside us without realizing it, and these '
            'instincts drive us to seek pleasure, and we have become bad before we receive various kinds of education. '
            'Many people like to derive pleasure and excitement from destruction, such as stomping on bugs, dissecting dolls, '
            'and destroying toys. Adults can determine whether such behavior is good or bad, but infants cannot. '
            'Through the study of instinctive psychology, pictures are used to express the social attributes of '
            "human's acquired nature and incontinence instincts.";
    }
}