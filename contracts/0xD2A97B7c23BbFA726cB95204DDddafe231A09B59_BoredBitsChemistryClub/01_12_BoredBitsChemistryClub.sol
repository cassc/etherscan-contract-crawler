// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BoredBitsChemistryClub is ERC1155, Ownable {
    using Strings for uint256;

    bool public mintOpen = false;
    
    address private mutationContract;
    string private baseURI;

    bytes32 public m1MerkleRoot;
    bytes32 public m2MerkleRoot;
    bytes32 public megaMerkleRoot;

    mapping(uint256 => bool) public validSerumTypes;
    mapping(uint256 => uint256) public maxSerums;
    mapping(address => mapping(uint => bool)) private claimed;
    mapping(uint => uint) public assetNonce;

    string public name = "Bored Bits Chemistry Club";
    string public symbol = "BBCC";

    modifier notClaimed(uint idx){
        require(!claimed[msg.sender][idx],"You cannot claim this again");
        _;
    }

    modifier opened(){
        require(mintOpen, "mint is closed");
        _;
    }

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        validSerumTypes[0] = true;
        validSerumTypes[1] = true;
        validSerumTypes[69] = true;
        maxSerums[0] = 7500;
        maxSerums[1] = 2492;
        maxSerums[69] = 8;
    }

    function setM1MerkleRoot(bytes32 root) external onlyOwner {
        m1MerkleRoot = root;
    }

    function setM2MerkleRoot(bytes32 root) external onlyOwner {
        m2MerkleRoot = root;
    }

    function setMegaMerkleRoot(bytes32 root) external onlyOwner {
        megaMerkleRoot = root;
    }

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function claimM1(uint qty, bytes32[] memory proof) external opened notClaimed(0) {
        require(MerkleProof.verify(proof, m1MerkleRoot, keccak256(abi.encodePacked(msg.sender, qty))), "Invalid proof");
        require(assetNonce[0] + qty <= maxSerums[0], "Total exceeded");
        claimed[msg.sender][0] = true;
        assetNonce[0] += qty;
        _mint(msg.sender, 0, qty, "");
    }

    function claimM2(uint qty, bytes32[] memory proof) external opened notClaimed(1) {
        require(MerkleProof.verify(proof, m2MerkleRoot, keccak256(abi.encodePacked(msg.sender, qty))), "Invalid proof");
        require(assetNonce[1] + qty <= maxSerums[1], "Total exceeded");
        claimed[msg.sender][1] = true;
        assetNonce[1] += qty;
        _mint(msg.sender, 1, qty, "");
    }

    function claimMega(uint qty, bytes32[] memory proof) external opened notClaimed(69) {
        require(MerkleProof.verify(proof, megaMerkleRoot, keccak256(abi.encodePacked(msg.sender, qty))), "Invalid proof");
        require(assetNonce[69] + qty <= maxSerums[69], "Total exceeded");
        claimed[msg.sender][69] = true;
        assetNonce[69] += qty;
        _mint(msg.sender, 69, qty, "");
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }

    function setMutationContractAddress(address mutationContractAddress)
        external
        onlyOwner
    {
        mutationContract = mutationContractAddress;
    }

    function burnSerumForAddress(uint256 typeId, address burnTokenAddress)
        external
    {
        require(msg.sender == mutationContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, 1);
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            validSerumTypes[typeId],
            "URI requested for invalid serum type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}