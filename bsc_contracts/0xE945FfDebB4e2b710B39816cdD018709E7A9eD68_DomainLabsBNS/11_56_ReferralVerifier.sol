pragma solidity >=0.8.4;

import "./ReferralVerifier.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReferralHub} from "./ReferralHub.sol";

contract ReferralVerifier is EIP712, Ownable, Pausable {
    address public spaceid_signer;
    uint256 public sigValidDuration;
    ReferralHub immutable referralHub;

    bytes32 private constant _REFERRAL_TYPEHASH = keccak256("Referral(address referrerAddress,bytes32 nodehash,uint256 referralCount,uint256 signedAt)");

    constructor(address _spaceid_signer, ReferralHub _referral_hub) EIP712("ReferralVerifier", "1.0.0") {
        spaceid_signer = _spaceid_signer;
        referralHub = _referral_hub;
        sigValidDuration = 5 minutes;
    }

    function setSpaceIdSigner(address _spaceid_signer) external onlyOwner {
        spaceid_signer = _spaceid_signer;
    }

    function setSigValidDuration(uint256 duration) external onlyOwner {
        sigValidDuration = duration;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _hash(address referrerAddress, bytes32 nodehash, uint256 referralCount, uint256 signedAt) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(_REFERRAL_TYPEHASH, referrerAddress, nodehash, referralCount, signedAt)));
    }

    function verifyReferral(address referrerAddress, bytes32 nodehash, uint256 referralCount, uint256 signedAt, bytes calldata signature) external view whenNotPaused returns (bool) {
        return block.timestamp < signedAt + sigValidDuration && _verifySignature(_hash(referrerAddress, nodehash, referralCount, signedAt), signature);
    }

    function getReferralCommisionFee(uint256 price, uint256 referralCount) external view returns (uint256, uint256) {
        uint256 curLevel = 1;
        (uint256 minimumReferralCount, uint256 referrerRate, uint256 refereeRate) = referralHub.comissionCharts(curLevel);
        while (referralCount > minimumReferralCount && curLevel <= 10) {
            (, referrerRate, refereeRate) = referralHub.comissionCharts(curLevel);
            (minimumReferralCount, , ) = referralHub.comissionCharts(++curLevel);
        }
        uint256 referrerFee = (price * referrerRate) / 100;
        uint256 refereeFee = (price * refereeRate) / 100;
        return (referrerFee, refereeFee);
    }

    function _verifySignature(bytes32 hash, bytes calldata signature) private view returns (bool) {
        return ECDSA.recover(hash, signature) == spaceid_signer;
    }
}