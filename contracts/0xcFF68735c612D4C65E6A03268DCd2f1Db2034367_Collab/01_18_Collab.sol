// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC4906.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Collab is ERC4906, ReentrancyGuard, Ownable {
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////////////////////////
    // Constant & variable
    ////////////////////////////////////////////////////////////////////////////////////
    uint public rd1Price;
    uint public pbPrice;
    uint public rd1StrTime;
    uint public rd1EndTime;
    uint public pbStrTime;
    uint public pbEndTime;
    uint public revealTime;
    uint public maxMintCount;
    
    string private CID;
    string private revealCID;
    
    bytes32 private rd1MerkleRoot;
    mapping(address => uint) public mintedCount;
    
    address payable public depositAddress;
    
    constructor(
        address payable _depositAddress,
        string memory _CID,
        string memory _revealCID,
        uint _rd1Price,
        uint _pbPrice,
        uint _maxMintCount
    ) ERC4906("BNFC", "BONSAI NFT FARM COLLAB") {
        depositAddress = _depositAddress;
        CID = _CID;
        revealCID = _revealCID;
        rd1Price = _rd1Price;
        pbPrice = _pbPrice;
        maxMintCount = _maxMintCount;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////
    // User Function
    ////////////////////////////////////////////////////////////////////////////////////
    function Mint(bytes32[] calldata _proof, uint _upperLimit, uint _amount) external payable nonReentrant {
        require((_totalMinted() + _amount) <= maxMintCount, "Beyond Max Supply");

        uint price;

        uint section = GetRoundSection();
        if (section == 1) {
            require(CheckValidityPlusLimit(_proof, rd1MerkleRoot, _upperLimit), "Not on the AllowList1");
            require((_amount + mintedCount[msg.sender]) <= _upperLimit, "Cannot mint more than your upper limit");
            price = rd1Price * _amount;
        } else if (section == 3) {
            price = pbPrice * _amount;
        } else {
            require(false, "Not a sale period");
        }

        require(price == msg.value, "Different amounts");
        depositAddress.transfer(address(this).balance);

        unchecked{
            mintedCount[msg.sender] += _amount;
        }
        _safeMint(msg.sender, _amount);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Not exists");

        if (block.timestamp < revealTime) {
            return string(abi.encodePacked(revealCID));
        }
        
        return string(abi.encodePacked(CID, Strings.toString(_tokenId), ".json"));
    }

    // before:0, round1:1, public:3, after:9
    function GetRoundSection() public view returns (uint) {
        if (block.timestamp < rd1StrTime) {
            return 0;
        } else if (rd1StrTime < block.timestamp && block.timestamp < rd1EndTime) {
            return 1;
        } else if (pbStrTime < block.timestamp && block.timestamp < pbEndTime) {
            return 3;
        }

        return 9;
    }

    function GetMintCount() external view returns (uint) {
        return _totalMinted();
    }

    function getAllowFlg() external view returns(bool) {
        return _getAllowFlg();
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Owner Function
    ////////////////////////////////////////////////////////////////////////////////////
    function OwnerMint(address _toAddress, uint256 _amount) public onlyOwner {
        _safeMint(_toAddress, _amount);
    }

    function BulkMint(address[] calldata _toAddress, uint[] calldata _amount) external onlyOwner {
        for(uint i = 0; i < _toAddress.length;) {
            OwnerMint(_toAddress[i], _amount[i]);
            unchecked{ i++; }
        }
    }

    function SetMaxMintCount(uint256 _amount) external onlyOwner {
        require(_totalMinted() <= _amount, "mintCount <= _amount");
        maxMintCount = _amount;
    }

    function SetPrice(uint _rd1Price, uint _pbPrice) external onlyOwner {
        rd1Price = _rd1Price;
        pbPrice = _pbPrice;
    }

    function SetRoundSection(
        uint256 _rd1StrTime, uint256 _rd1EndTime,
        uint256 _pbStrTime, uint256 _pbEndTime) external onlyOwner {
        rd1StrTime = _rd1StrTime;
        rd1EndTime = _rd1EndTime;
        pbStrTime = _pbStrTime;
        pbEndTime = _pbEndTime;
    }

    function SetRevealTime(uint256 _revealTime) external onlyOwner {
        revealTime = _revealTime;
    }

    function SetCID(string calldata _CID, string calldata _revealCID) external onlyOwner {
        CID = _CID;
        revealCID = _revealCID;
    }

    function SetDepositAddress(address payable _depositAddress) external onlyOwner {
        depositAddress = _depositAddress;
    }

    function SetAllowList(bytes32 _merkleRoot) external onlyOwner {
        rd1MerkleRoot = _merkleRoot;
    }

    function setAllowTime(uint256 _time) external onlyOwner {
        _setAllowTime(_time);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // Private Function
    ////////////////////////////////////////////////////////////////////////////////////
    function CheckValidityPlusLimit(bytes32[] calldata proof, bytes32 merkleRoot, uint _upperLimit) private view returns (bool) {
        string memory tmpLeaf = string.concat(Strings.toHexString(uint160(msg.sender)), ',', _upperLimit.toString());
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(tmpLeaf)));
    }
}