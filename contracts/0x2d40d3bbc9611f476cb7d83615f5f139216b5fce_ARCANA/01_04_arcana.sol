//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface tokenInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract ARCANA is Ownable {
    mapping(uint256 => address) public tokenContractAddress;
    tokenInterface tokenContract;

    modifier checkTokenContract(uint256 _contractIndex) {
        require(
            tokenContractAddress[_contractIndex] != address(0),
            "Please put the correct address"
        );
        tokenContract = tokenInterface(tokenContractAddress[_contractIndex]);
        _;
    }

    modifier onlyChimeraOwner(uint256 _contractIndex, uint256 _tokenId) {
        address owner = tokenContract.ownerOf(_tokenId);
        require(owner == msg.sender, "Chimera owners only");
        _;
    }

    bool private _setStart;

    function setTokenContract(uint256 _contractIndex, address _address)
        external
        onlyOwner
    {
        require(_address != address(0), "Please put the correct address");
        tokenContractAddress[_contractIndex] = _address;
    }

    bool private standbyStart;
    uint256 public arcanaCost = 86400;
    mapping(uint256 => mapping(uint256 => uint256)) public standbyStarted;
    mapping(address => uint256) public standbyTotal;

    function setArcanaCost(uint256 _cost) external onlyOwner {
        arcanaCost = _cost;
    }

    function toggleStandbyStart() external onlyOwner {
        standbyStart = !standbyStart;
    }

    function arcanaStandby(uint256 _contractIndex, uint256 _tokenId)
        public
        checkTokenContract(_contractIndex)
        onlyChimeraOwner(_contractIndex, _tokenId)
    {
        require(standbyStart, "ARCANA Standby is not yet ready to run");

        uint256 start = standbyStarted[_contractIndex][_tokenId];
        if (start == 0) {
            standbyStarted[_contractIndex][_tokenId] = block.timestamp;
        } else {
            standbyTotal[msg.sender] += block.timestamp - start;
            standbyStarted[_contractIndex][_tokenId] = block.timestamp;
        }
    }

    function batchArcanaStandby(
        uint256 _contractIndex,
        uint256[] calldata _tokenIds
    ) public {
        uint256 n = _tokenIds.length;
        for (uint256 i = 0; i < n; ) {
            arcanaStandby(_contractIndex, _tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    event arcanaStandbyStarted(uint256 indexed tokenId);

    function getArcana(address _address) external view returns (uint256) {
        return standbyTotal[_address] / arcanaCost;
    }

    mapping(address => bool) private _controllableAddress;

    function setControllableAddress(address _address, bool _state)
        external
        onlyOwner
    {
        _controllableAddress[_address] = _state;
    }

    modifier onlyControllableAddress() {
        require(_controllableAddress[msg.sender], "Operation not authorized");
        _;
    }

    function decreaseArcana(address _address, uint256 _size)
        external
        onlyControllableAddress
    {
        uint256 size = arcanaCost * _size;
        require(standbyTotal[_address] >= size, "Exceeds the number of owned");
        standbyTotal[_address] = standbyTotal[_address] - size;
    }

    function increaseArcana(address _address, uint256 _size)
        external
        onlyControllableAddress
    {
        uint256 size = arcanaCost * _size;
        standbyTotal[_address] = standbyTotal[_address] + size;
    }
}