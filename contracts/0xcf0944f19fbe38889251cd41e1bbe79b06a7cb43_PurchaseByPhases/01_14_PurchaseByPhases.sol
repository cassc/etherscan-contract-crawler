// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PurchaseByPhases is
Initializable,
OwnableUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable,
UUPSUpgradeable {

    struct Phase {
        string id;
        uint256 price;
        bytes32 purchaserMaxQtyMerkleRoot;
        uint maxQty;
    }

    struct PhaseState {
        uint purchased;
        uint256 balance;
    }

    struct PurchaserState {
        bool isPurchaser;
        uint purchasedSum; // all phases
        uint256 balanceSum; // all phases
        mapping(string => PhaseState) phaseState;
    }

    mapping(string => Phase) private _phases; // {phaseId => phase}
    address[] private _purchasers;
    mapping(string => PhaseState) private _phasesState;
    mapping(address => PurchaserState) private _purchasersState;

    string private _activePhaseId;
    bytes32 private _activePhaseIdEncoded;

    // contract-level qty limits (sum of all phases)
    uint private _maxQtyPerAddress;
    uint private _maxQty;

    uint private _purchased; // qty
    uint256 private _balance;

    event SetPhase(Phase);
    event SetActivePhase(string phaseId);
    event Purchased(string phaseId, address purchaser, uint qty, uint256 value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    fallback() external payable {}

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // SETTERS

    function setPhase(Phase memory phase) external onlyOwner {
        _phases[phase.id] = phase;
        emit SetPhase(phase);
    }

    function setActivePhase(string calldata phaseId) external onlyOwner {
        _activePhaseId = phaseId;
        _activePhaseIdEncoded = keccak256(abi.encode(phaseId));
        emit SetActivePhase(phaseId);
    }

    function setMaxQtyPerAddress(uint limit) external onlyOwner {
        _maxQtyPerAddress = limit;
    }

    function setMaxQty(uint qty) external onlyOwner {
        _maxQty = qty;
    }

    // GETTERS

    struct PurchaserStatRet {
        uint purchasedAtPhase;
        uint purchasedSumPhases;
    }

    function getPurchaserStat(address purchaser, string calldata phaseId) external view returns (PurchaserStatRet memory) {
        return PurchaserStatRet({
            purchasedAtPhase: _purchasersState[purchaser].phaseState[phaseId].purchased,
            purchasedSumPhases: _purchasersState[purchaser].purchasedSum
        });
    }

    function getActivePhaseId() external view returns (string memory) {
        return _activePhaseId;
    }

    struct PhaseStatRet {
        uint256 price;
        uint maxQty;
        uint purchased;
    }

    function getPhaseStat(string calldata phaseId) external view returns (PhaseStatRet memory) {
        return PhaseStatRet({
            price: _phases[phaseId].price,
            maxQty: _phases[phaseId].maxQty,
            purchased: _phasesState[phaseId].purchased
        });
    }

    function getMaxQty() external view returns (uint) {
        return _maxQty;
    }

    function getMaxQtyPerAddress() external view returns (uint) {
        return _maxQtyPerAddress;
    }

    function getBalance() external view returns (uint256) {
        return _balance;
    }

    function getPurchased() external view returns (uint) {
        return _purchased;
    }

    // TODO: getStatsOfAllPurchasersByPhases

    // ACTIONS

    function purchase(string calldata phaseId, uint qty, uint purchaserPhaseMaxQty, bytes32[] calldata proof)
    public
    payable
    nonReentrant
    whenNotPaused {
        address purchaser = msg.sender;
        uint256 value = msg.value;

        require(_activePhaseIdEncoded == keccak256(abi.encode(phaseId)), "INACTIVE PHASE");
        require(qty > 0, "TOO SMALL");
        require(_verifyMaxPhaseQty(phaseId, purchaser, purchaserPhaseMaxQty, proof), "BAD PROOF");
        require(value == qty * _phases[phaseId].price, "BAD PAYMENT AMOUNT");
        require(qty + _purchased <= _maxQty, "ALL SOLD OUT");
        require(qty + _phasesState[phaseId].purchased <= _phases[phaseId].maxQty, "PHASE SOLD OUT");
        require(qty + _purchasersState[purchaser].phaseState[phaseId].purchased <= purchaserPhaseMaxQty, "TOO MANY AT PHASE");
        require(qty + _purchasersState[purchaser].purchasedSum <= _maxQtyPerAddress, "TOO MANY AT ALL PHASES");

        if (!_purchasersState[purchaser].isPurchaser) {
            _purchasersState[purchaser].isPurchaser = true;
            _purchasers.push(purchaser);
        }

        // user state
        _purchasersState[purchaser].purchasedSum += qty;
        _purchasersState[purchaser].balanceSum += value;
        _purchasersState[purchaser].phaseState[phaseId].purchased += qty;
        _purchasersState[purchaser].phaseState[phaseId].balance += value;
        // phase state
        _phasesState[phaseId].purchased += qty;
        _phasesState[phaseId].balance += value;
        // contract state
        _purchased += qty;
        _balance += value;

        emit Purchased(phaseId, purchaser, qty, value);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // PRIVATE

    function _verifyMaxPhaseQty(
        string calldata phaseId,
        address purchaser,
        uint256 maxPhaseQty,
        bytes32[] calldata proof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(purchaser, maxPhaseQty)))
        );
        return MerkleProof.verify(proof, _phases[phaseId].purchaserMaxQtyMerkleRoot, leaf);
    }

    // REQUIRED BY PARENTS

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}