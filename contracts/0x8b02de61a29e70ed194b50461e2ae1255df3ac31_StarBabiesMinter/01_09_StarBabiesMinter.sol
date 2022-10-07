// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./erc721a/contracts/interfaces/IERC721A.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

interface IStarBabies is IERC721A{
    function mintByRole(address to, uint256 count) external;
}

contract StarBabiesMinter is Ownable {
    using ECDSA for bytes32;

    IStarBabies public nftContract;

    uint256 public unitPrice = 0.18 ether;
    uint8 public maxPerUser = 20;
    uint256 public whitelistStartDate = block.timestamp;
    uint256 public publicStartDate = block.timestamp + 24*3600;
    address public signer;
    uint256 public maxCap = 3000;
    mapping(address =>  uint256) public usersMinted;

    bytes32 public merkleRoot = 0xc8cf9034dcbc694ad2444aa7462f3439e291f1de92005f09bbeaa0b31388d787;
    bytes32 public merkleRoot2 = 0x43c25e05bf9e132e7e6d8ce0d76cba29a44626c8c438183d69365331800499f6;    


    modifier isValidMerkleProof(address _to, bytes32[] calldata _proof, bytes32 root) {
        if (!MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(_to)))) {
          revert("Invalid access list proof");
        }
        _;
    }

    constructor(
        //address nftContractAddress
    ){
        nftContract = IStarBabies(0x106a40B30c71E2e6518756637e846E80600A89B4);
        signer = 0x7E9e166eEC3AFFe3BD2b1175849f73D6Eb53bAfE;
    }


    function mintWL1(
        address _to,
        uint256 _count,
        bytes32[] calldata _proof
      ) public payable isValidMerkleProof(_to, _proof, merkleRoot) {
        //require(block.timestamp >= startTime, "not started");
        require(msg.value >= price(_count), "value");
        require(_count + nftContract.totalSupply() <= maxCap, "> maxCap");

        _mint(_to, _count);
    }

    function mintWL2(
        address _to,
        uint256 _count,
        bytes32[] calldata _proof
      ) public payable isValidMerkleProof(_to, _proof, merkleRoot2) {
        //require(block.timestamp >= startTime, "not started");
        require(msg.value >= ( price(_count) - (0.01 ether)*_count), "value");
        require(_count + nftContract.totalSupply() <= maxCap, "> maxCap");

        _mint(_to, _count);
    }

    function mint(
        address _to,
        uint256 _count
    ) public payable {
        require(publicStartDate <= block.timestamp, "!not started yet");
        require(_count <= maxPerUser, "> maxPerUser");
        require(_count + nftContract.totalSupply() <= maxCap, "> maxCap");
        require(msg.value >= price(_count), "!value");
        _mint(_to, _count);
    }

    function whitelistMint(
        address _to,
        uint256 _count,
        uint8 mintableAmount,
        bytes calldata sig
    ) public payable {
        require(whitelistStartDate <= block.timestamp, "!not started yet");
        require(_count + nftContract.totalSupply() <= maxCap, "> maxCap");
        require(msg.value >= price(_count), "!value");
        bytes32 hash = keccak256(abi.encodePacked(_to, mintableAmount));
        hash = hash.toEthSignedMessageHash();
        address sigSigner = hash.recover(sig);
        require(sigSigner == signer, "!sig");
        require(_count + usersMinted[_to] <= mintableAmount, "exceeded balance");
        usersMinted[_to] += _count;
        _mint(_to, _count);
    }

    function _mint(address _to, uint256 _count) private {
        // for(uint i = 0; i < _count; i++) {
        //     nftContract.mint(_to, nftContract.totalSupply());
        // }
        nftContract.mintByRole(_to, _count);
    }

    function price(uint _count) public view returns (uint256) {
        return _count * unitPrice;
    }

    function updateUnitPrice(uint256 _unitPrice) public onlyOwner {
        unitPrice = _unitPrice;
    }

    function updateWhitelistStartDate(uint256 _date) public onlyOwner {
        whitelistStartDate = _date;
    }

    function updatePublicStartDate(uint256 _date) public onlyOwner {
        publicStartDate = _date;
    }

    function updateSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function updateMaxPerUser(uint8 _maxPerUser) public onlyOwner {
        maxPerUser = _maxPerUser;
    }

    function updateNftContrcat(IStarBabies _newAddress) public onlyOwner {
        nftContract = IStarBabies(_newAddress);
    }

    function updateMaxCap(uint256 _val) public onlyOwner {
        maxCap = _val;
    }

    function setMerkleRoot(bytes32 _root, bytes32 _root2) external onlyOwner {
        merkleRoot = _root;
        merkleRoot2 = _root2;
    }

    // allows the owner to withdraw tokens
    function ownerWithdraw(uint256 amount, address _to, address _tokenAddr) public onlyOwner{
        require(_to != address(0));
        if(_tokenAddr == address(0)){
        payable(_to).transfer(amount);
        }else{
        IERC20(_tokenAddr).transfer(_to, amount);
        }
    }
}