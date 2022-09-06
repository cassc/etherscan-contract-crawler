// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

*/


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
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

contract GirlsAndFlowers is Ownable, ERC721A, ReentrancyGuard {
    uint256 public collabSupply = 600;
    uint256 public publicSupply = 8777;
    uint256 public maxSupply = collabSupply + publicSupply;
    uint256 public publicPrice = 0.0069 ether;
    uint256 public freePerWallet = 1;
    uint256 public maxPerWallet = 6;
    uint256 public maxBatchSize = 30;


    constructor(
    ) ERC721A("GirlsAndFlowers", "GAF") {
    }

    // For marketing etc.
    function reserveMint(uint256 quantity, address toaddr) external onlyOwner {
        require(
            totalSupply() + quantity <= maxSupply,
            "too many already minted before dev mint"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(toaddr, maxBatchSize);
        }
        if (quantity % maxBatchSize != 0){
            _safeMint(toaddr, quantity % maxBatchSize);
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

    function setPublicPrice(uint256 price) external onlyOwner {
        publicPrice = price;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    //     _setOwnersExplicit(quantity);
    // }

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
    uint256 private allowListMintPrice = 0.000000 ether;
    // default false
    bool private allowListStatus = false;
    uint256 private allowListMintAmount = 0;
    uint256 public immutable maxPerAddressDuringMint = 2;

    bytes32 private merkleRoot;

    mapping(address => bool) public addressAppeared;
    mapping(address => uint256) public addressMintStock;


    function allowListMint(uint256 quantity, bytes32[] memory proof) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(allowListStatus, "allowList sale has not begun yet");
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf),
            "Invalid Merkle Proof.");
        if(!addressAppeared[msg.sender]){
            addressAppeared[msg.sender] = true;
            addressMintStock[msg.sender] = maxPerAddressDuringMint;
        }
        require(addressMintStock[msg.sender] >= quantity, "reached allow list per address mint amount");
        addressMintStock[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
        allowListMintAmount -= quantity;
        refundIfOver(allowListMintPrice*quantity);
    }

    function setAllowList(bytes32 root_) external onlyOwner{
        merkleRoot = root_;
    }

    function setAllowListStatus(bool status) external onlyOwner {
        allowListStatus = status;
    }

    function getAllowListStatus() external view returns(bool){
        return allowListStatus;
    }
    //public sale
    bool public publicSaleStatus = false;

    function publicSaleMint(uint256 quantity) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");

        require(
        publicSaleStatus,
        "public sale has not begun yet"
        );

        require(
        totalSupply() + quantity <= maxSupply,
        "reached max supply"
        );

        require(
        _numberMinted(msg.sender) + quantity <= maxPerWallet,
        "reached max per wallet"
        );

        uint256 price;
        if (_numberMinted(msg.sender) > 0) {
            price = publicPrice * quantity;
        } else {
            price = publicPrice * (quantity - freePerWallet);
        }

        _safeMint(msg.sender, quantity);
        refundIfOver(price);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }

    function renounceOwnership() public override onlyOwner {
    }
}