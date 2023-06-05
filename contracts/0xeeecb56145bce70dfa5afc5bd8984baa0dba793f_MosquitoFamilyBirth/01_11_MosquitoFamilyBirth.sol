// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IMosquitoFamily.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MosquitoFamilyBirth is AccessControl, Ownable, Pausable {
    using ECDSA for bytes32;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    IMosquitoFamily public mosquitoFamily;

    // ForSign
    uint256 public timezoneDiffHour = 9;
    uint256 public birthCost;
    uint256 public nonce = 0;
    address private _signer;

    // Event
    event MosquitoBirth(address _sender, uint256 _motherTokenId, address _motherOwner, uint256 _fatherTokenId, address _fatherOwner);

    // Modifier
    modifier enoughEth() {
        require(msg.value >= birthCost, 'Not Enough Eth');
        _;
    }
    modifier isTokenOwner(address _address, uint256 _tokenId) {
        require(mosquitoFamily.isTokenOwner(_address, _tokenId), "You Are Not Token Owner");
        _;
    }
    modifier isValidSignature (uint256 _motherTokenId, address _motherOwner, uint256 _fatherTokenId, address _fatherOwner, bytes calldata _signature) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                msg.sender,
                _motherTokenId,
                _motherOwner,
                _fatherTokenId,
                _fatherOwner,
                getTimestamp(),
                nonce
            )
        ).toEthSignedMessageHash().recover(_signature);
        require(recoveredAddress == _signer, "Invalid Signature");
        _;
    }


    // Constructor
    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    function recoverSignature (address _address, uint256 _motherTokenId, address _motherOwner, uint256 _fatherTokenId, address _fatherOwner, uint256 _timestamp, uint256 _nonce, bytes calldata _signature) external view returns (address) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                _address,
                _motherTokenId,
                _motherOwner,
                _fatherTokenId,
                _fatherOwner,
                _timestamp,
                _nonce
            )
        ).toEthSignedMessageHash().recover(_signature);
        return recoveredAddress;
    }

    // Birth
    function birth (uint256 _motherTokenId, address _motherOwner, uint256 _fatherTokenId, address _fatherOwner, bytes calldata _signature) external payable
        whenNotPaused
        enoughEth()
        isTokenOwner(_motherOwner, _motherTokenId)
        isTokenOwner(_fatherOwner, _fatherTokenId)
        isValidSignature(_motherTokenId, _motherOwner, _fatherTokenId, _fatherOwner, _signature)
    {
        mosquitoFamily.burn(_fatherTokenId);
        nonce++;
        emit MosquitoBirth(msg.sender, _motherTokenId, _motherOwner, _fatherTokenId, _fatherOwner);
    }

    // Getter
    function getTimestamp() public view returns (uint256) {
        return (block.timestamp + timezoneDiffHour * 60 * 60) / (24 * 60 * 60);
    }

    // Setter
    function setMosquitoFamily(address _value) external onlyRole(ADMIN) {
        mosquitoFamily = IMosquitoFamily(_value);
    }
    function setTimezoneDiffHour(uint256 _value) external onlyRole(ADMIN) {
        timezoneDiffHour = _value;
    }
    function setBirthCost(uint256 _value) external onlyRole(ADMIN) {
        birthCost = _value;
    }
    function setSigner(address _value) external onlyRole(ADMIN) {
        _signer = _value;
    }

    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }
}