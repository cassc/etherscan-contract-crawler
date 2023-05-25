// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IApes.sol";
import "./interface/ITraits.sol";

/// @title Bulls and Apes Project - Traits Constructor
/// @author BAP Dev Team
/// @notice Contract to equip or de-equip traits from Apes
contract TraitsConstructorV2 is ERC1155Holder, ReentrancyGuard, Ownable {
    using Strings for uint256;

    /// @notice BAP Apes contract
    IApes public apesContract;
    /// @notice BAP Traits contract
    ITraits public traitsContract;
    /// @notice Address of the signer wallet
    address public secret;

    event Equipped(
        uint256 tokenId,
        uint256[] offChainIn,
        string changeCode,
        address operator
    );

    event EquippedOffChain(
        uint256 tokenId,
        uint256[] offChainIn,
        uint256[] offChainOut,
        string changeCode,
        address operator
    );

    /// @notice Deploys the contract
    /// @param _apes BAP Apes address
    /// @param _traits BAP Traits address
    /// @param _secret Signer address
    constructor(address _apes, address _traits, address _secret) {
        apesContract = IApes(_apes);
        traitsContract = ITraits(_traits);
        secret = _secret;
    }

    /// @notice Equip or remove traits for the Ape
    /// @param tokenId Id of the Ape to be equipped
    /// @param traitsIn Traits that will be equipped
    /// @param traitsOffChainIn Off chain traits that will be equipped
    /// @param traitsOut Traits that will be removed
    /// @param traitsOGOut OG traits to be removed
    /// @param changeCode Customization code with trait changes
    /// @param signature Signature to verify above parameters
    /// @dev Transfer traitsIn from user to contract, traitsOut from contract to user and mint TraitsOGOut to user
    function equip(
        uint256 tokenId, // Ape id to be modified
        uint256[] memory traitsIn, // id of traits to be added
        uint256[] memory traitsOffChainIn, // id of traits off-chain to be added
        uint256[] memory traitsOut, // id of traits to be removed
        uint256[] memory traitsOGOut, // id of original traits to be removed (need to be minted)
        uint256 timeOut, // time out for signature expiration
        string memory changeCode, // internal code to process image change
        bytes memory signature
    ) external nonReentrant {
        require(block.timestamp < timeOut, "Equip: Signature has expired"); // Checks if signature has expired
        bytes memory traitCode; // Used to avoid unauthorized changes

        if (traitsIn.length > 0) {
            uint256[] memory InAmounts = new uint256[](traitsIn.length); // create arrays with amount 1 for safeBatchTransfer

            for (uint256 i = 0; i < traitsIn.length; i++) {
                InAmounts[i] = 1;

                traitCode = abi.encodePacked(
                    traitCode,
                    "A",
                    traitsIn[i]
                ); // loop through traits to create traitCode
            }

            traitsContract.safeBatchTransferFrom(
                msg.sender,
                address(this),
                traitsIn,
                InAmounts,
                ""
            ); // batch transfer traits in, from user to this contract
        }

        for (uint256 i = 0; i < traitsOffChainIn.length; i++) {
            traitCode = abi.encodePacked(
                traitCode,
                "B",
                traitsOffChainIn[i]
            ); // loop through traits to create traitCode
        }

        if (traitsOut.length > 0) {
            uint256[] memory OutAmounts = new uint256[](traitsOut.length); // create arrays with amount 1 for safeBatchTransfer

            for (uint256 i = 0; i < traitsOut.length; i++) {
                OutAmounts[i] = 1;

                traitCode = abi.encodePacked(
                    traitCode,
                    "C",
                    traitsOut[i]
                ); // loop through traits to create traitCode
            }

            traitsContract.safeBatchTransferFrom(
                address(this),
                msg.sender,
                traitsOut,
                OutAmounts,
                ""
            ); // batch transfer traits in, from this contract to user
        }

        if (traitsOGOut.length > 0) {
            uint256[] memory OGOutAmouts = new uint256[](traitsOGOut.length); // create arrays with amount 1 for safeBatchTransfer

            for (uint256 i = 0; i < traitsOGOut.length; i++) {
                OGOutAmouts[i] = 1;

                traitCode = abi.encodePacked(
                    traitCode,
                    "D",
                    traitsOGOut[i]
                ); // loop through traits to create traitCode
            }

            traitsContract.mintBatch(msg.sender, traitsOGOut, OGOutAmouts); // batch mint original traits, from traits contract to user
        }

        address tokenOwner = apesContract.ownerOf(tokenId); // Current owner of the Ape, allows SafeClaim equip/de-equip

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        tokenId,
                        traitCode,
                        changeCode,
                        timeOut,
                        msg.sender,
                        tokenOwner
                    )
                ),
                signature
            ), // Checks validity of back-end provided signatre
            "Equip: Signature is invalid"
        );

        apesContract.confirmChange(tokenId); // Confirm the change on Apes contract (burn - mint)

        emit Equipped(
            tokenId + 10000,
            traitsOffChainIn,
            changeCode,
            msg.sender
        ); // event emitted with new ID after burn - mint
    }

    /// @notice Equip or remove traits for the Ape but remove traits off-chain
    /// @param tokenId Id of the Ape to be equipped
    /// @param traitsIn Traits that will be equipped
    /// @param traitsOffChainIn Off chain traits that will be equipped
    /// @param traitsOffChainOut Traits that will be removed off-chain
    /// @param changeCode Customization code with trait changes
    /// @param signature Signature to verify above parameters
    /// @dev Transfer traitsIn from user to contract, traitsOut from contract to user and mint TraitsOGOut to user
    function equipWithOffChainRemoval(
        uint256 tokenId, // Ape id to be modified
        uint256[] memory traitsIn, // id of traits to be added
        uint256[] memory traitsOffChainIn, // id of traits off-chain to be added
        uint256[] memory traitsOffChainOut, // id of traits to be removed off-chain
        uint256 timeOut, // time out for signature expiration
        string memory changeCode, // internal code to process image change
        bytes memory signature
    ) external nonReentrant {
        require(block.timestamp < timeOut, "Equip: Signature has expired"); // Checks if signature has expired
        bytes memory traitCode; // Used to avoid unauthorized changes

        if (traitsIn.length > 0) {
            uint256[] memory InAmounts = new uint256[](traitsIn.length); // create arrays with amount 1 for safeBatchTransfer

            for (uint256 i = 0; i < traitsIn.length; i++) {
                InAmounts[i] = 1;

                traitCode = abi.encodePacked(
                    traitCode,
                    "1",
                    traitsIn[i]
                ); // loop through traits to create traitCode
            }

            traitsContract.safeBatchTransferFrom(
                msg.sender,
                address(this),
                traitsIn,
                InAmounts,
                ""
            ); // batch transfer traits in, from user to this contract
        }

        for (uint256 i = 0; i < traitsOffChainIn.length; i++) {
            traitCode = abi.encodePacked(
                traitCode,
                "2",
                traitsOffChainIn[i]
            ); // loop through traits to create traitCode
        }

        for (uint256 i = 0; i < traitsOffChainOut.length; i++) {
            traitCode = abi.encodePacked(
                traitCode,
                "3",
                traitsOffChainOut[i]
            ); // loop through traits to create traitCode
        }

        address tokenOwner = apesContract.ownerOf(tokenId); // Current owner of the Ape, allows SafeClaim equip/de-equip

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        tokenId,
                        traitCode,
                        changeCode,
                        timeOut,
                        msg.sender,
                        tokenOwner
                    )
                ),
                signature
            ), // Checks validity of back-end provided signatre
            "Equip: Signature is invalid"
        );

        apesContract.confirmChange(tokenId); // Confirm the change on Apes contract (burn - mint)

        emit EquippedOffChain(
            tokenId + 10000,
            traitsOffChainIn,
            traitsOffChainOut,
            changeCode,
            msg.sender
        ); // event emitted with new ID after burn - mint
    }

    /// @notice Set new contracts addresses for Apes and Traits
    /// @param _apes New address for BAP Apes
    /// @param _traits New address for BAP Traits
    /// @dev Can only be called by the contract owner
    function setContracts(address _apes, address _traits) external onlyOwner {
        apesContract = IApes(_apes);
        traitsContract = ITraits(_traits);
    }

    /// @notice Change the signer address
    /// @param _secret new signer for encrypted signatures
    /// @dev Can only be called by the contract owner
    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function _verifyHashSignature(
        bytes32 freshHash,
        bytes memory signature
    ) internal view returns (bool) {
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
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}