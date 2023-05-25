//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface tokenInterface {
    function mint(string calldata _uri, address _to) external;
    function getOrderStart() external view returns(bool);
}

contract SANSYU_NO_JINGI is ReentrancyGuard, Ownable {
    tokenInterface tokenContract;
    using Strings for uint256;

    bytes32 public merkleRoot;
    uint256 public mintLimit = 1;
    uint256 public eventPhase;
    mapping(uint256 => mapping(address => uint256)) public minted;

    function setTokenContract(address _address) external onlyOwner {
        tokenContract = tokenInterface(_address);
    }

    function setMintLimit(uint256 _amount) external onlyOwner {
        mintLimit = _amount;
    }

    function setEventPhase(uint256 _phase) external onlyOwner {
        eventPhase = _phase;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // image func
    function createImagePathBase(string[12] memory _parts) private pure returns (string memory) {
        string memory base = "https://d2qpyjh0cr011z.cloudfront.net/output/sansyu_no_jingi-";
        return string(abi.encodePacked(base, _parts[0]));
    }

    function createImagePathAttributes(string[12] memory _parts) private pure returns (string memory) {
        return string(abi.encodePacked(
            '-[BACKGROUND-', _parts[1],
            '][AYAKASHI-', _parts[2],
            '][SHADOW-', _parts[3],
            '][WEAPON-', _parts[4],
            '][TYPE-', _parts[5],
            '][MOUTH-', _parts[6],
            '][EYE-', _parts[7],
            '][HAIR-', _parts[8],
            '][CLOTHES-', _parts[9],
            '][ACCESSORY-', _parts[10],
            '][KAGAMI-', _parts[11]
        ));
    }

    // order
    function order(bytes32[] calldata _merkleProof, string[12] memory _parts) public nonReentrant {
        require(tokenContract.getOrderStart(), 'Out of order period.');
        require(minted[eventPhase][msg.sender] < mintLimit, 'Mint limit over.');
        require(checkMerkleProof(_merkleProof), "Invalid Merkle Proof");

        string memory uri = string(abi.encodePacked(
            createImagePathBase(_parts),
            createImagePathAttributes(_parts),
            '].png'
        ));

        tokenContract.mint(uri, msg.sender);
        minted[eventPhase][msg.sender]++;
    }

    function checkMerkleProof(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }
}