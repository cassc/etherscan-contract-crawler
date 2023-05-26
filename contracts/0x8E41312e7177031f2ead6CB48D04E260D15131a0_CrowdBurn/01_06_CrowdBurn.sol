// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IERC721 {
    function transferFrom(address, address, uint256) external;
}

contract CrowdBurn is Ownable {
    mapping(bytes => bool) public signatureUsed;

    enum BURN_TYPE {
        NOT_LIVE,
        BURN_TWO,
        BURN_EIGHT,
        BURN_THIRTYTWO
    }

    BURN_TYPE public state;

    error InvalidSignature();
    error SignatureUsed();
    error InvalidBurnType();

    event burned2Event(address user, uint256[] burnIds, uint256[] evolveIds, BURN_TYPE burnType);
    event burned8Event(address user, uint256[] burnIds, uint256[] evolveId, BURN_TYPE burnType);
    event burned32Event(address user, uint256[] burnIds, uint256[] evolveId, BURN_TYPE burnType);

    address public CrowdContract;
    IERC721 public Crowd = IERC721(CrowdContract);
    address public signerAddress;

    constructor(address _signerAddress, address _crowdContract) {
        signerAddress = _signerAddress;
        CrowdContract = _crowdContract;
        Crowd = IERC721(_crowdContract);
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function recoverSigner(address _caller, uint256[] calldata _tokenIds, uint256[] calldata _evolveIds, string memory _functionName, bytes memory signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                _caller,
                _tokenIds,
                _evolveIds,
                _functionName
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function burn2(uint256[] calldata burnIds, uint256[] calldata evolveIds, bytes memory signature) external {
        address signer = recoverSigner(msg.sender, burnIds, evolveIds, "burn2", signature);
        if (signer != signerAddress) revert InvalidSignature();
        if (signatureUsed[signature]) revert SignatureUsed();
        if (state != BURN_TYPE.BURN_TWO) revert InvalidBurnType();
        signatureUsed[signature] = true;
        for (uint256 i = 0; i < burnIds.length; i++) {
            Crowd.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, burnIds[i]);
        }
        emit burned2Event(msg.sender, burnIds, evolveIds, state);
    }

    function burn8(uint256[] calldata burnIds, uint256[] calldata evolveIds, bytes memory signature) external {
        address signer = recoverSigner(msg.sender, burnIds, evolveIds, "burn8", signature);
        if (signer != signerAddress) revert InvalidSignature();
        if (signatureUsed[signature]) revert SignatureUsed();
        if (state != BURN_TYPE.BURN_EIGHT || state != BURN_TYPE.BURN_TWO) revert InvalidBurnType();
        signatureUsed[signature] = true;
        for (uint256 i = 0; i < burnIds.length; i++) {
            Crowd.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, burnIds[i]);
        }
        emit burned8Event(msg.sender, burnIds, evolveIds, state);
    }

    function burn32(uint256[] calldata burnIds, uint256[] calldata evolveIds, bytes memory signature) external {
        address signer = recoverSigner(msg.sender, burnIds, evolveIds, "burn32", signature);
        if (signer != signerAddress) revert InvalidSignature();
        if (signatureUsed[signature]) revert SignatureUsed();
        if (state != BURN_TYPE.BURN_THIRTYTWO || state != BURN_TYPE.BURN_EIGHT || state != BURN_TYPE.BURN_TWO) revert InvalidBurnType();
        signatureUsed[signature] = true;
        for (uint256 i = 0; i < burnIds.length; i++) {
            Crowd.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, burnIds[i]);
        }
        emit burned32Event(msg.sender, burnIds, evolveIds, state);
    }

    function setStateBurnType(BURN_TYPE _state) external onlyOwner {
        state = _state;
    }

    function setCrowdContract(address _contract) external onlyOwner {
        CrowdContract = _contract;
        Crowd = IERC721(_contract);
    }
}