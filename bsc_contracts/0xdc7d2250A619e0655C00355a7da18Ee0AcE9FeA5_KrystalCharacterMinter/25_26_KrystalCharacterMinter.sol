// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./KrystalCharacterStorage.sol";
import "./IKrystalCharacter.sol";
import "./KrystalCharacterImpl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KrystalCharacterMinter is IKrystalCharacter, KrystalCharacterStorage {
    using Strings for uint256;

    function initialize(
        address _admin,
        address _verifier,
        address _character
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        verifier = _verifier;
        characterContract = _character;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "unauthorized: admin required");
        _;
    }

    function setCharacterContract(address _character) external onlyAdmin {
        characterContract = _character;
        emit SetCharacterContract(_character);
    }

    function setVerifier(address _verifier) external onlyAdmin {
        verifier = _verifier;
        emit SetVerifier(_verifier);
    }

    function mint(
        address buyer,
        uint256[] calldata bodyPartIds,
        bytes memory signature
    ) external payable {
        {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 message = keccak256(
                abi.encodePacked(
                    prefix,
                    keccak256(
                        abi.encodePacked(
                            buyer,
                            bodyPartIds[0],
                            bodyPartIds[1],
                            bodyPartIds[2],
                            bodyPartIds[3],
                            bodyPartIds[4]
                        )
                    )
                )
            );
            _verifyMessage(message, signature);
        }

        // verify bodyParts
        for (uint256 i = 0; i < bodyPartIds.length; i += 1) {
            require(minted[bodyPartIds[i]] != true, "mint: part minted");
            minted[bodyPartIds[i]] = true;
        }

        KrystalCharacterImpl(characterContract).mint(buyer);
    }

    function _verifyMessage(bytes32 message, bytes memory signature) private view {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // First 32 bytes is for the length
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        // Arbitrary EVM magic .i.e 27 and 28 for the version
        if (v < 27) v += 27;

        require(ecrecover(message, v, r, s) == verifier, "verify: failed");
    }
}