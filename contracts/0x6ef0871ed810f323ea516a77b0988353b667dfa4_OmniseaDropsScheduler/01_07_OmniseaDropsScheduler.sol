// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IOmniseaONFT721Psi.sol";
import "../interfaces/IOmniseaDropsScheduler.sol";
import {Phase} from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OmniseaDropsScheduler is IOmniseaDropsScheduler, ReentrancyGuard {
    address private _owner;
    mapping(address => uint8) internal phasesCount;
    mapping(address => mapping(uint8 => Phase)) internal phases;
    mapping(address => mapping(uint8 => mapping(address => uint24))) internal phaseMintedCount;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function getPhase(address _collection, uint8 _phaseId) internal view returns (Phase memory) {
        uint8 count = phasesCount[_collection];
        require(count > 0 && _phaseId > 0 && _phaseId <= count, "!phaseId");

        return phases[_collection][_phaseId];
    }

    function isAllowed(address _account, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external override view returns (bool) {
        Phase memory phase = getPhase(msg.sender, _phaseId);

        if (block.timestamp < phase.from || block.timestamp > phase.to) return false;

        if (phase.maxPerAddress > 0 && phaseMintedCount[msg.sender][_phaseId][_account] + _quantity > phase.maxPerAddress) {
            return false;
        }
        if (phase.merkleRoot == bytes32(0)) return true;
        bytes32 leaf = keccak256(abi.encodePacked(_account));

        return MerkleProof.verify(_merkleProof, phase.merkleRoot, leaf);
    }

    function setPhase(
        uint8 _phaseId,
        uint256 _from,
        uint256 _to,
        bytes32 _merkleRoot,
        uint24 _maxPerAddress,
        uint256 _price
    ) external override {
        require(_from < _to);

        uint8 id;
        if (_phaseId == 0) {
            phasesCount[msg.sender]++;
            id = phasesCount[msg.sender];
        } else {
            id = _phaseId;
            require(id <= phasesCount[msg.sender]);
        }
        phases[msg.sender][id] = Phase(_from, _to, _maxPerAddress, _price, _merkleRoot);
    }

    function increasePhaseMintedCount(address _account,uint8 _phaseId, uint24 _quantity) external override {
        phaseMintedCount[msg.sender][_phaseId][_account] += _quantity;
    }

    function mintPrice(uint8 _phaseId) external view override returns (uint256) {
        Phase memory phase = getPhase(msg.sender, _phaseId);

        return phase.price;
    }
}