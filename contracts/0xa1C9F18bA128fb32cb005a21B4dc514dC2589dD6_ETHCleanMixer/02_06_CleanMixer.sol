//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MerkleTree.sol";

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external view returns (bool r);
}

interface IBlacklistControl {
    function isAddressBlacklisted(address _address) external returns (bool);
    function isTrustedRelayerAddress(address _address) external returns (bool);
}

interface ITwoLevelReferral {
    function payReferral(
        address _depositor,
        address _referrerAddress,
        uint256 _denomination
    ) external;

    function getTotalFee() external returns (uint8);

    function getDecimal() external returns (uint16);

    function saveDepositor(address _depositor, address _referrerAddress) external;

    function getSecondLevel(address _referrerAddress) external returns (address);

    function calculateFirstLevelPay(uint256 _denomination) external returns (uint256);

    function calculateSecondLevelPay(uint256 _denomination) external returns (uint256);

    function getRootOwnerPercentage(uint256 _index) external returns (uint8);
}

abstract contract CleanMixer is MerkleTree, Ownable, ReentrancyGuard {
    IVerifier public verifier;
    IBlacklistControl public blacklistControl;
    ITwoLevelReferral public twoLevelReferral;

    uint256 public denomination;

    address public relayerAddress;
    address public officialMirrorSiteAddress;

    struct DepositItem {
        bytes32 commitment;
        uint32 leafIndex;
        uint256 timestamp;
    }

    // we store all commitments just to prevent accidental deposits with the same commitment
    mapping(bytes32 => bool) public commitments;
    DepositItem[] public depositArray; // array of all commitments in order
    mapping(bytes32 => bool) public nullifierHashes;

    event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event Withdrawal(address to, bytes32 nullifierHashes, address indexed relayer, uint256 fee);

    constructor(
        IVerifier _verifier,
        IBlacklistControl _blacklistControl,
        ITwoLevelReferral _twoLevelReferral,
        uint256 _denomination,
        uint32 _merkleTreeHieght,
        Hasher _hasher
    ) MerkleTree(_merkleTreeHieght, _hasher) {
        require(_denomination > 0, "denomination should be greater than zero");
        verifier = _verifier;
        blacklistControl = _blacklistControl;
        twoLevelReferral = _twoLevelReferral;
        denomination = _denomination;
        relayerAddress = owner();
    }

    function deposit(bytes32 _commitment, address _referrer) public payable nonReentrant {
        require(!commitments[_commitment], "The commitment has been submitted");
        require(!blacklistControl.isAddressBlacklisted(msg.sender), "Banned address");

        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        _processDeposit(_referrer);
        depositArray.push(DepositItem(_commitment, insertedIndex, block.timestamp));
        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    function _processDeposit(address _referrer) internal virtual;

    function withdraw(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _relayerGasfee,
        uint256 _refund
    ) external payable nonReentrant {
        //check if verified relayer is sender
        require(blacklistControl.isTrustedRelayerAddress(msg.sender), "Not Trusted Relayer Address");
        require(_relayer == msg.sender, " msg.sender Not Relayer");
        require(_relayerGasfee <= denomination, "Fee exceeds transfer value");
        require(!nullifierHashes[_nullifierHash], "The note has been already spent");
        require(isKnownRoot(_root), "Cannot find your merkle root");
        require(verifier.verifyProof(a, b, c, input), "Invalid withdraw proof");

        nullifierHashes[_nullifierHash] = true;
        _processWithdraw(_recipient, _relayerGasfee);

        emit Withdrawal(_recipient, _nullifierHash, _relayer, _relayerGasfee);
    }

    function _processWithdraw(address payable _recipient, uint256 _relayGasFee) internal virtual;

    function isSpent(bytes32 _nullifierHash) public view returns (bool) {
        return nullifierHashes[_nullifierHash];
    }

    function getDepositArray() public view returns (DepositItem[] memory) {
        return depositArray;
    }

    function updateRelayerAddress(address _address) external onlyOwner {
        relayerAddress = _address;
    }

    function updateBlackListControlAddress(IBlacklistControl _blacklistControl) external onlyOwner {
        blacklistControl = _blacklistControl;
    }

    // officialMirrorSiteAddress
    function updateMirrorSiteAddress(address _address) external onlyOwner {
        officialMirrorSiteAddress = _address;
    }
}