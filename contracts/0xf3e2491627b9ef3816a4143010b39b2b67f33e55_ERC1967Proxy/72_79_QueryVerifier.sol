// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@iden3/contracts/verifiers/ZKPVerifier.sol";
import "@iden3/contracts/lib/GenesisUtils.sol";
import "@iden3/contracts/interfaces/ICircuitValidator.sol";

import "./interfaces/IQueryVerifier.sol";
import "./interfaces/IVerifiedSBT.sol";

contract QueryVerifier is IQueryVerifier, ZKPVerifier {
    uint256 public constant AGE_VERIFY_REQUEST_ID = 1;

    IVerifiedSBT public override sbtContract;

    mapping(address => uint256) public override addressToUserId;

    mapping(uint256 => VerificationInfo) internal _verificationsInfo;

    function setSBTContract(address sbtContract_) external override onlyOwner {
        sbtContract = IVerifiedSBT(sbtContract_);
    }

    function getVerificationInfo(
        uint256 userId_
    ) external view override returns (VerificationInfo memory) {
        return _verificationsInfo[userId_];
    }

    function isUserVerified(uint256 userId_) public view override returns (bool) {
        return _verificationsInfo[userId_].senderAddr != address(0);
    }

    function _beforeProofSubmit(
        uint64,
        uint256[] memory inputs_,
        ICircuitValidator
    ) internal override {
        require(
            !isUserVerified(_getIdentityId(inputs_)),
            "QueryVerifier: identity with this identifier has already been verified"
        );
        require(
            addressToUserId[msg.sender] == 0,
            "QueryVerifier: current address has already been used to verify another identity"
        );
    }

    function _afterProofSubmit(
        uint64,
        uint256[] memory inputs_,
        ICircuitValidator
    ) internal override {
        uint256 tokenId_ = sbtContract.nextTokenId();
        uint256 userId_ = _getIdentityId(inputs_);

        _verificationsInfo[userId_] = VerificationInfo(msg.sender, tokenId_);
        addressToUserId[msg.sender] = userId_;

        sbtContract.mint(msg.sender);

        emit Verified(userId_, msg.sender, tokenId_);
    }

    function _getIdentityId(uint256[] memory inputs_) internal pure returns (uint256) {
        return inputs_[1];
    }
}