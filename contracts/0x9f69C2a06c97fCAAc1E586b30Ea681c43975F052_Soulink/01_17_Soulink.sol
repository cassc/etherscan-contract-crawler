// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./libraries/SoulinkLibrary.sol";
import "./standards/SoulBoundToken.sol";
import "./interfaces/ISoulink.sol";

contract Soulink is Ownable, SoulBoundToken, EIP712, ISoulink {
    uint128 private _totalSupply;
    uint128 private _burnCount;

    // keccak256("RequestLink(address to,uint256 deadline)");
    bytes32 private constant _REQUESTLINK_TYPEHASH = 0xc3b100a7bf35d534e6c9e325adabf47ef6ec87fd4874fe5d08986fbf0ad1efc4;

    mapping(address => bool) public isMinter;
    mapping(uint256 => mapping(uint256 => bool)) internal _isLinked;
    mapping(uint256 => uint256) internal _internalId;
    mapping(bytes32 => bool) internal _notUsableSig;

    string internal __baseURI;

    constructor() SoulBoundToken("Soulink", "SL") EIP712("Soulink", "1") {
        isMinter[msg.sender] = true;

        __baseURI = "https://api.soul.ink/metadata/";
    }

    //ownership functions
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        __baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function setMinter(address target, bool _isMinter) external onlyOwner {
        require(isMinter[target] != _isMinter, "UNCHANGED");
        isMinter[target] = _isMinter;
        emit SetMinter(target, _isMinter);
    }

    function updateSigNotUsable(bytes32 sigHash) external onlyOwner {
        _notUsableSig[sigHash] = true;
    }

    //external view/pure functions
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply - _burnCount;
    }

    function getTokenId(address owner) public pure returns (uint256) {
        return SoulinkLibrary._getTokenId(owner);
    }

    function isLinked(uint256 id0, uint256 id1) external view returns (bool) {
        (uint256 iId0, uint256 iId1) = _getInternalIds(id0, id1);
        return _isLinked[iId0][iId1];
    }

    function isUsableSig(bytes32 sigHash) external view returns (bool) {
        return !_notUsableSig[sigHash];
    }

    //internal view/pure functions
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function _requireUsable(bytes32 sig) internal view {
        require(!_notUsableSig[sig], "USED_SIGNATURE");
    }

    function _getInternalIds(uint256 id0, uint256 id1) internal view returns (uint256 iId0, uint256 iId1) {
        _requireMinted(id0);
        _requireMinted(id1);

        (iId0, iId1) = SoulinkLibrary._sort(_internalId[id0], _internalId[id1]);
    }

    //external functions
    function mint(address to) external returns (uint256 tokenId) {
        require(isMinter[msg.sender], "UNAUTHORIZED");
        require(balanceOf(to) == 0, "ALREADY_MINTED");
        tokenId = getTokenId(to);
        _mint(to, tokenId);
        _totalSupply++;
        _internalId[tokenId] = _totalSupply; //_internalId starts from 1
    }

    function burn(uint256 tokenId) external {
        require(getTokenId(msg.sender) == tokenId, "UNAUTHORIZED");
        _burn(tokenId);
        _burnCount++;
        delete _internalId[tokenId];
        emit ResetLink(tokenId);
    }

    /**
        0: id of msg.sender
        1: id of target
    */
    function setLink(
        uint256 targetId,
        bytes[2] calldata sigs,
        uint256[2] calldata deadlines
    ) external {
        require(block.timestamp <= deadlines[0] && block.timestamp <= deadlines[1], "EXPIRED_DEADLINE");

        uint256 myId = getTokenId(msg.sender);

        bytes32 hash0 = _hashTypedDataV4(keccak256(abi.encode(_REQUESTLINK_TYPEHASH, targetId, deadlines[0])));
        SignatureChecker.isValidSignatureNow(msg.sender, hash0, sigs[0]);
        bytes32 sigHash = keccak256(sigs[0]);
        _requireUsable(sigHash);
        _notUsableSig[sigHash] = true;

        bytes32 hash1 = _hashTypedDataV4(keccak256(abi.encode(_REQUESTLINK_TYPEHASH, myId, deadlines[1])));
        SignatureChecker.isValidSignatureNow(address(uint160(targetId)), hash1, sigs[1]);
        sigHash = keccak256(sigs[1]);
        _requireUsable(sigHash);
        _notUsableSig[sigHash] = true;

        (uint256 iId0, uint256 iId1) = _getInternalIds(myId, targetId);
        require(!_isLinked[iId0][iId1], "ALREADY_LINKED");
        _isLinked[iId0][iId1] = true;
        emit SetLink(myId, targetId);
    }

    function breakLink(uint256 targetId) external {
        uint256 myId = getTokenId(msg.sender);
        (uint256 iId0, uint256 iId1) = _getInternalIds(myId, targetId);
        require(_isLinked[iId0][iId1], "NOT_LINKED");
        delete _isLinked[iId0][iId1];
        emit BreakLink(myId, targetId);
    }

    function cancelLinkSig(
        uint256 targetId,
        uint256 deadline,
        bytes calldata sig
    ) external {
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(_REQUESTLINK_TYPEHASH, targetId, deadline)));
        SignatureChecker.isValidSignatureNow(msg.sender, hash, sig);

        bytes32 sigHash = keccak256(sig);
        _requireUsable(sigHash);
        _notUsableSig[sigHash] = true;
        emit CancelLinkSig(msg.sender, targetId, deadline);
    }
}