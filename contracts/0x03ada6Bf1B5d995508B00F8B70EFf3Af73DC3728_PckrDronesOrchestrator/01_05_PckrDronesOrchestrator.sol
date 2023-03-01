// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PckrDronesInterface.sol";
import "./HpprsInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PckrDronesOrchestrator is Ownable {
    uint256 public dronesMintPrice = 0.05 ether;
    uint256 public dronesPreMintPrice = 0.04 ether;
    uint256 public tradeStart = 1677596400;
    uint256 public premintStart = 1677682800;
    uint256 public premintEnd = 1677769140;
    uint256 public mintStart = 1677769200;

    uint256 public maxPreMintsPerWallet = 2;
    uint256 public maxMintsPerTransaction = 10;

    address public secret = 0x9C17E0f19f6480747436876Cee672150d39426A5;

    PckrDronesInterface public drones = PckrDronesInterface(0x25720B5936043ed7A322ac63459e65eCf4cDF501);
    HpprsInterface public hpprs = HpprsInterface(0xE2609354791Bf57E54B3f7F9A26b2dacBed61DA1);

    mapping(address => uint) public walletsPreMints;

    event Mint(address owner, uint256 tokenAmount);
    event Trade(address owner, uint256 tokenAmount);

    function setSettings(
        address _drones,
        address _hpprs,
        address _secret,
        uint256 _dronesPreMintPrice,
        uint256 _dronesMintPrice,
        uint256 _maxPreMintsPerWallet,
        uint256 _maxMintsPerTransaction,
        uint256 _tradeStart,
        uint256 _premintStart,
        uint256 _premintEnd,
        uint256 _mintStart
    ) external onlyOwner {
        hpprs = HpprsInterface(_hpprs);
        drones = PckrDronesInterface(_drones);
        secret = _secret;
        dronesMintPrice = _dronesMintPrice;
        dronesPreMintPrice = _dronesPreMintPrice;
        maxPreMintsPerWallet = _maxPreMintsPerWallet;
        maxMintsPerTransaction = _maxMintsPerTransaction;
        tradeStart = _tradeStart;
        premintStart = _premintStart;
        premintEnd = _premintEnd;
        mintStart = _mintStart;
    }

    function setTimers(
        uint256 _tradeStart,
        uint256 _premintStart,
        uint256 _premintEnd,
        uint256 _mintStart) external onlyOwner {
        tradeStart = _tradeStart;
        premintStart = _premintStart;
        premintEnd = _premintEnd;
        mintStart = _mintStart;
    }

    function setSalePrices(uint256 _dronesPreMintPrice, uint256 _dronesMintPrice) external onlyOwner {
        dronesPreMintPrice = _dronesPreMintPrice;
        dronesMintPrice = _dronesMintPrice;
    }

    function preMintDrone(uint256 tokenAmount, bytes calldata signature) external payable {
        require(block.timestamp >= premintStart && block.timestamp <= premintEnd, "Presale is closed");
        require(tokenAmount + walletsPreMints[msg.sender] <= maxPreMintsPerWallet, "Cannot exceed max premint");
        require(msg.value == tokenAmount * dronesPreMintPrice, "Wrong ETH amount");
        require(
            _verifyHashSignature(keccak256(abi.encode(msg.sender)), signature),
            "Signature is invalid"
        );

        walletsPreMints[msg.sender] += tokenAmount;
        emit Mint(msg.sender, tokenAmount);
        drones.airdrop(msg.sender, tokenAmount);
    }

    function mintDrone(uint256 tokenAmount) external payable {
        require(block.timestamp >= mintStart, "Mint is closed");
        require(msg.value == tokenAmount * dronesMintPrice, "Wrong ETH amount");
        require(tokenAmount <= maxMintsPerTransaction, "Limit per transaction");

        emit Mint(msg.sender, tokenAmount);
        drones.airdrop(msg.sender, tokenAmount);
    }

    function tradeDrone(uint256[] calldata hpprsIds) external {
        require(block.timestamp >= tradeStart, "Trade is closed");

        for (uint256 i = 0; i < hpprsIds.length; i++) {
            require(hpprs.ownerOf(hpprsIds[i]) == msg.sender, "Not HPPR owner");
            hpprs.burn(hpprsIds[i]);
        }

        emit Trade(msg.sender, hpprsIds.length * 2);
        drones.airdrop(msg.sender, hpprsIds.length * 2);
    }

    function withdraw() external onlyOwner {
        payable(0xB3b3C662B547eBc3cDE4C481d9fB63f03a8d90Eb).transfer(address(this).balance);
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature) internal view returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}