// SPDX-License-Identifier: MIT

/**
O~~~~~~~~                            O~~     O~~     O~~                        
O~~                                  O~~     O~~     O~~                        
O~~         O~~    O~ O~~~   O~~     O~~     O~~     O~~   O~~       O~~        
O~~~~~~   O~   O~~  O~~    O~~  O~~  O~~     O~~~~~~ O~~ O~~  O~~  O~~  O~~     
O~~      O~~~~~ O~~ O~~   O~~   O~~  O~~     O~~     O~~O~~    O~~O~~   O~~     
O~~      O~         O~~   O~~   O~~  O~~     O~~     O~~ O~~  O~~  O~~  O~~     
O~~        O~~~~   O~~~     O~~ O~~~O~~~     O~~     O~~   O~~         O~~      
                                                                    O~~         
O~~      O~~                      O~~         O~~    O~~        O~~             
 O~~    O~~                       O~~      O~~   O~~ O~~        O~~             
  O~~ O~~      O~~    O~ O~~~     O~~     O~~        O~~O~~  O~~O~~             
    O~~      O~~  O~~  O~~    O~~ O~~     O~~        O~~O~~  O~~O~~ O~~         
    O~~     O~~   O~~  O~~   O~   O~~     O~~        O~~O~~  O~~O~~   O~~       
    O~~     O~~   O~~  O~~   O~   O~~      O~~   O~~ O~~O~~  O~~O~~   O~~       
    O~~       O~~ O~~~O~~~    O~~ O~~        O~~~~  O~~~  O~~O~~O~~ O~~         
                                                                                

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

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

contract XToFeralHogs is Ownable, ERC721A, ReentrancyGuard, VRFConsumerBaseV2 {

    // ChainLink Verifiable Random Number Module
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId = 250;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint256 public randomRevealOffset;
    uint256 public s_requestId;

    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomRevealOffset = randomWords[0] % collectionSize;
    }

    function reveal(string calldata baseURI) external onlyOwner {
        requestRandomWords();
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString((tokenId + randomRevealOffset) % collectionSize))) : '';
    }

    constructor() ERC721A("x 30 to 50 Feral Hogs", "FHYC")VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    uint256 public collectionSize = 3250;

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
        uint256 royaltyForAmadeus = address(this).balance / 100 * 5;
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
    uint256 public allowListMintPrice = 0.020000 ether;
    uint256 public allowListStartTime = 0;
    uint256 public allowListEndTime = 0;
    uint256 public amountForAllowList = 300;
    uint256 public immutable maxPerAddressDuringMint = 2;

    bytes32 private merkleRoot;

    mapping(address => bool) public allowListAppeared;
    mapping(address => uint256) public allowListStock;

    function setAllowListStartTime(uint256 _startTime) external {
        allowListStartTime = _startTime;
    }

    function setAllowListEndTime(uint256 _endTime) external {
        allowListEndTime = _endTime;
    }

    function allowListStatus() public view returns(bool) {
        return block.timestamp >= allowListStartTime && block.timestamp < allowListEndTime;
    }

    function allowListMint(uint256 quantity, bytes32[] memory proof) external payable {
        require(allowListStatus(), "not begun");
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

    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function isInAllowList(address addr, bytes32[] memory proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    //public sale
    uint256 public publicSaleStartTime = 0;
    uint256 public publicSaleEndTime = 0;
    uint256 public publicPrice = 0.032500 ether;
    uint256 public amountForPublicSale = 2900;
    // per mint public sale limitation
    mapping(address => uint256) private publicSaleMintedPerAddress;
    uint256 public immutable publicSalePerAddress = 7;

    function setPublicSaleStartTime(uint256 _startTime) external {
        publicSaleStartTime = _startTime;
    }

    function setPublicSaleEndTime(uint256 _endTime) external {
        publicSaleEndTime = _endTime;
    }

    function publicSaleStatus() public view returns(bool) {
        return block.timestamp >= publicSaleStartTime && block.timestamp < publicSaleEndTime;
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(publicSaleStatus(), "not begun");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(amountForPublicSale >= quantity, "reached max amount");

        require(publicSaleMintedPerAddress[msg.sender] + quantity <= publicSalePerAddress, "reached max amount per address");

        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
        publicSaleMintedPerAddress[msg.sender] += quantity;
        refundIfOver(uint256(publicPrice) * quantity);
    }
}