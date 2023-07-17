// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**===============================================================================
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,@@(((((,,,,,,,,,@@,,,,,@@((,,,,,,,,,,  @@,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@(((((,,,,,,,,,,,,,@@@@@((,,,,,,,,,,,,,,  @@,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,@@@((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,  @@@,,,,,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,@@@@@@@@@@@,,,,,@@,,,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@    @@,,,@@,,,,,,,,,,,,,
,,,,,,,,,,@@(((((((,,,,@@@@@@@@@@@@@@,,@@@,,,,@@     @@@@@    @@,,,,,@@,,,,,,,,,,,
,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,,,@@@@@,,,,@@   @@@@@@@    @@,,,,,@@,,,,,,,,,,,
,,,,,,,@@@(((((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,@@@,,,,,,,,
,,,,,,,@@@(((((((((@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@(((((((@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@,,,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@((@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@((((@@@@@((((((((((((((((((((((((((((((((@@@@(((@@,,@@@,,,,,,,,
,,,,,,,@@@(((((((((@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@,,@@@,,,,,,,,
,,,,,,,@@@(((((((((**##############################################,,**@@@,,,,,,,,
,,,,,,,,,,@@(((((((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,((@@,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((((((((((((((((((((((((((((((((((((((((((((((((@@,,,,,,,,,,,,,
,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
==================================================================================
🐸                               MINTING LOGIC                                  🐸
🐸                       THE PEOPLES' NFT MADE BY FROGS                         🐸
================================================================================*/

import "./Base.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BabyPepes is Base {

    // Mint phases
    enum MintPhase {
        CLOSED, AL, PUBLIC
    }

    // Merkleroot for allowList
    bytes32 public _merkleRoot;

    // Bits Layout:
    // [0..7]   uint8 `mintPhase`
    // [8..15]  uint8 `signatureDisabled`
    // [16.175] address `signer`
    uint256 public _mintData;

    // minting related errors
    error BotMinter();
    error InsufficientFunds();
    error InsufficientSupply();
    error InvalidMerkleProof();
    error InvalidMintPhase();
    error InvalidSignature();
    error MintingTooMany();

    constructor(
        address rendererAddress,
        uint256 supply,
        string memory name,
        string memory symbol,
        uint256 reserve
    )
    Base(name, symbol, rendererAddress, supply) {
        // mint some for the team
        if (reserve > 0) {
            _mintERC2309(msg.sender, reserve);
        }
    }

    // =============================================================
    //                       MINTING LOGIC
    // =============================================================

    /**
     🐸 @notice Mint tokens in the AL phase
     🐸 @dev Can save gas here by not running site sig checks
     🐸      The merkle validation combats bots
     🐸 @param quantity - Desired quantity to mint
     🐸 @param merkleProof - MerkleProof data for sender
     */
    function allowlistMint(
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) public payable {
        // unpack mint _mintData
        (uint8 currentMintPhase, , ) = getMintData();

        // run check using unpacked data
        _mintCheck(currentMintPhase, MintPhase.AL);
        _hasValidMerkleProof(merkleProof);

        _mintTokens(quantity);
    }

    /**
     🐸 @notice Mint tokens in public mint phase
     🐸 @param quantity - Desired quantity to mint
     🐸 @param signature - Signature from app
     */
    function publicMint(uint256 quantity, bytes calldata signature)
    public
    payable
    {
        // unpack mint _mintData
        (uint8 mintPhase, uint8 signatureDisabled, address signer) = getMintData();

        // run check using unpacked data
        _mintCheck(mintPhase, MintPhase.PUBLIC);
        _hasValidateWebSignature(signatureDisabled, signature, signer);

        _mintTokens(quantity);
    }

    /**
     🐸 @notice Mint tokens
     🐸 @param quantity - Desired quantity to mint
     */
    function _mintTokens(uint256 quantity) internal {
        uint256 newMinted = _validateQuantity(quantity);
        _setAux(msg.sender, uint64(newMinted));
        _mint(msg.sender, quantity);
    }

    // =============================================================
    //                       MINTING CHECKS
    // =============================================================

    /**
     🐸 @notice Check minting in the correct phase from desired origin
     🐸 @param currentMintPhase - Current minting phase
     🐸 @param desiredPhase - Desired minting phase
     */
    function _mintCheck(
        uint8 currentMintPhase,
        MintPhase desiredPhase
    ) internal view {
        if (currentMintPhase != uint8(desiredPhase)) revert InvalidMintPhase();
        if (msg.sender != tx.origin) revert BotMinter();
    }

    /**
     🐸 @notice Verify merkleProof submitted by a sender
     🐸 @param merkleProof - Merkle data to verify against
    */
    function _hasValidMerkleProof(
        bytes32[] calldata merkleProof
    ) internal view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        if (!MerkleProof.verifyCalldata(merkleProof, _merkleRoot, leaf)) {
            revert InvalidMerkleProof();
        }
    }

    /**
     🐸 @notice Verify signature
     🐸 @param signatureDisabled - Signature disabled 0|1
     🐸 @param signature - Signature from app
     🐸 @param signerA - Signer from app
     */
    function _hasValidateWebSignature(
        uint8 signatureDisabled,
        bytes calldata signature,
        address signerA
    ) internal view {
        if (signatureDisabled == 0) {
            bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encode(msg.sender));
            (address signerB,) = ECDSA.tryRecover(messageHash, signature);
            if (signerA != signerB) revert InvalidSignature();
        }
    }

    /**
     🐸 @notice Validate the desired quantity and return new total minted for address
     🐸 @param quantity - Desired quantity to mint
     🐸 @return new total minted for address
     */
    function _validateQuantity(uint256 quantity) internal view returns (uint256) {
        uint256 newMinted;
        unchecked {
            newMinted = _getAux(msg.sender) + quantity;
            if (newMinted > WALLET_MAX) revert MintingTooMany();
            if (_totalMinted() + quantity > MAX_POP) revert InsufficientSupply();
            if (msg.value < _price * quantity) revert InsufficientFunds();
        }
        return newMinted;
    }

    // =============================================================
    //                       MINTING GETTERS
    // =============================================================

    /**
     🐸 @notice Unpack and return the minting data
     🐸 @return mintPhase - Desired current minting phase
     🐸 @return signatureDisabled - Signature disabled 0|1
     🐸 @return signer - Address of new signer
     */
    function getMintData() public view returns(uint8 mintPhase, uint8 signatureDisabled, address signer) {
        uint256 data = _mintData;
        mintPhase = uint8(data);
        signatureDisabled = uint8(data >> 8);
        signer = address(uint160(data >> 16));
    }

    /**
     🐸 @notice Get the number of token minted by an address
     🐸 @param check - Address to check
     🐸 @return Number of tokens minted
     */
    function getMintedCount(address check) external view returns(uint64) {
        return _getAux(check);
    }

    // =============================================================
    //                       MINTING SETTERS
    // =============================================================

    /**
     🐸 @notice Set the minting data
     🐸 @param mintPhase - Desired current minting phase
     🐸 @param signatureDisabled - Signature disabled 0|1
     🐸 @param signer - Address of new signer
     */
    function setMintData(uint8 mintPhase, uint8 signatureDisabled, address signer) external onlyOwner {
        uint256 packed = uint256(mintPhase)
        | uint256(signatureDisabled) << 8
        | uint256(uint160(signer)) << 16;
        _mintData = packed;
    }

    /**
     🐸 @notice Set merkle root for a specific minting phase
     🐸 @param merkleRoot - MerkleRoot for specific minting phase
     */
    function setMerkleRoot( bytes32 merkleRoot ) public onlyOwner {
        _merkleRoot = merkleRoot;
    }
}