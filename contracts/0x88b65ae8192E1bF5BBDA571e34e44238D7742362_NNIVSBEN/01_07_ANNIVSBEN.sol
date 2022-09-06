// SPDX-License-Identifier: MIT

/**

                     ._____.
_____    ____   ____ |__\_ |__   ____   ____
\__  \  /    \ /    \|  || __ \_/ __ \ /    \
 / __ \|   |  \   |  \  || \_\ \  ___/|   |  \
(____  /___|  /___|  /__||___  /\___  >___|  /
     \/     \/     \/        \/     \/     \/


 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract NNIVSBEN is Ownable, ERC721A, ReentrancyGuard {
    constructor(
    ) ERC721A("ANNI VS BEN", "AnniBen") {}

    uint256 public collectionSize = 2000;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // For marketing etc.
    function reserveMintBatch(uint256[] calldata quantities, address[] calldata tos) external onlyOwner {
        for(uint256 i = 0; i < quantities.length; i++){
            require(
                totalSupply() + quantities[i] <= collectionSize,
                "Too many already minted before dev mint."
            );
            _safeMint(tos[i], quantities[i]);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        address amadeusAddress = address(0x718a7438297Ac14382F25802bb18422A4DadD31b);
        uint256 royaltyForAmadeus = address(this).balance / 100 * 10;
        uint256 remain = address(this).balance - royaltyForAmadeus;
        (bool success, ) = amadeusAddress.call{value: royaltyForAmadeus}("");
        require(success, "Transfer failed.");
        (success, ) = msg.sender.call{value: remain}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    // allowList mint
    uint256 public allowListMintPrice = 0.000000 ether;
    // default false
    bool public allowListStatus = false;
    uint256 public amountForAllowList = 1500;
    uint256 public immutable maxPerAddressDuringMint = 2;

    bytes32 private merkleRoot;

    mapping(address => bool) public allowListAppeared;
    mapping(address => uint256) public allowListStock;

    function allowListMint(uint256 quantity, bytes32[] memory proof) external payable {
        require(allowListStatus, "not begun");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(amountForAllowList >= quantity, "reached max amount");
        require(isInAllowList(msg.sender, proof), "Invalid Merkle Proof.");
        if(!allowListAppeared[msg.sender]){
            allowListAppeared[msg.sender] = true;
            allowListStock[msg.sender] = maxPerAddressDuringMint;
        }
        require(allowListStock[msg.sender] >= quantity, "reached amount per address");
        allowListStock[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
        amountForAllowList -= quantity;
        refundIfOver(allowListMintPrice*quantity);
    }

    function setRoot(bytes32 root) external onlyOwner{
        merkleRoot = root;
    }

    function setAllowListStatus(bool status) external onlyOwner {
        allowListStatus = status;
    }

    function isInAllowList(address addr, bytes32[] memory proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    //public sale
    bool public publicSaleStatus = false;
    uint256 public publicPrice = 0.000000 ether;
    uint256 public amountForPublicSale = 300;
    // per mint public sale limitation
    uint256 public immutable publicSalePerMint = 2;

    function publicSaleMint(uint256 quantity) external payable callerIsUser{
        require(
            publicSaleStatus,
            "not begun"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            amountForPublicSale >= quantity,
            "reached max amount"
        );

        require(
            quantity <= publicSalePerMint,
            "reached max amount per mint"
        );

        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
        refundIfOver(uint256(publicPrice) * quantity);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }
}