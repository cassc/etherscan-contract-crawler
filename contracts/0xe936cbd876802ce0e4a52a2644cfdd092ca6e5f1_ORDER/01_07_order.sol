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

contract ORDER is ReentrancyGuard, Ownable {
    tokenInterface tokenContract;
    using Strings for uint256;

    /*
      MENU NUMBER
      0: sansyu_no_jingi
      1: junihitoe
      2: sarutoken
      3: goyou
      4: gokou
      5: inosikachou
      6: ryuuseikyuushi
      7: shitiryuukon
    */

    mapping(uint256 => bytes32) public merkleRoot; // menu => merkleRoot
    uint256 public mintLimit = 1;
    uint256 public eventPhase;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public minted; // phase => menu => address => minted

    function setTokenContract(address _address) external onlyOwner {
        tokenContract = tokenInterface(_address);
    }

    function setMintLimit(uint256 _amount) external onlyOwner {
        mintLimit = _amount;
    }

    function setEventPhase(uint256 _phase) external onlyOwner {
        eventPhase = _phase;
    }

    function setMerkleRoot(uint256 _menu, bytes32 _merkleRoot) public onlyOwner {
        merkleRoot[_menu] = _merkleRoot;
    }

    // image func
    function createImagePathBase(uint256 _menu, string[12] memory _parts) private pure returns (string memory) {
      string memory base;
      if (_menu == 0) {
        base = "https://d2qpyjh0cr011z.cloudfront.net/output/sansyu_no_jingi-";
      } else if (_menu == 1) {
        base = "https://d2qpyjh0cr011z.cloudfront.net/output/junihitoe-";
      } else if (_menu == 2) {
        base = "https://d2qpyjh0cr011z.cloudfront.net/output/sarutoken-";
      } else if (_menu == 3) {
        base = "https://d2qpyjh0cr011z.cloudfront.net/output/goyou-";
      } else if (_menu == 4) {
        base = "https://d2qpyjh0cr011z.cloudfront.net/output/gokou-";
      } else if (_menu == 5) {
        base = "https://d2qpyjh0cr011z.cloudfront.net/output/inosikachou-";
      } else if (_menu == 6) {
        base = "https://d2qpyjh0cr011z.cloudfront.net/output/ryuuseikyuushi-";
      } else if (_menu == 7) {
        base = "https://d2qpyjh0cr011z.cloudfront.net/output/shitiryuukon-";
      }

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
    function order(uint256 _menu, bytes32[] calldata _merkleProof, string[12] memory _parts) public nonReentrant {
        require(tokenContract.getOrderStart(), 'Out of order period.');
        require(minted[eventPhase][_menu][msg.sender] < mintLimit, 'Mint limit over.');
        require(checkMerkleProof(_menu, _merkleProof), "Invalid Merkle Proof");

        string memory uri = string(abi.encodePacked(
            createImagePathBase(_menu, _parts),
            createImagePathAttributes(_parts),
            '].png'
        ));

        tokenContract.mint(uri, msg.sender);
        minted[eventPhase][_menu][msg.sender]++;
    }

    function checkMerkleProof(uint256 _menu, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot[_menu], leaf);
    }
}