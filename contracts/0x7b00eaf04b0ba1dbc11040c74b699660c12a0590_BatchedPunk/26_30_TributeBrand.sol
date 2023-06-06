// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
╭━━━╮╱╱╱╱╱╱╱╭╮╭━╮╱╭╮╱╱╱╱╭╮╱╱╱╱╭━━━╮
┃╭━╮┃╱╱╱╱╱╱╱┃┃┃┃╰╮┃┃╱╱╱╱┃┃╱╱╱╱┃╭━╮┃
┃╰━━┳━━┳━╮╭━╯┃┃╭╮╰╯┣╮╭┳━╯┣━━┳━┻┫╭╯┃
╰━━╮┃┃━┫╭╮┫╭╮┃┃┃╰╮┃┃┃┃┃╭╮┃┃━┫━━┫┃╭╯
┃╰━╯┃┃━┫┃┃┃╰╯┃┃┃╱┃┃┃╰╯┃╰╯┃┃━╋━━┃╭╮
╰━━━┻━━┻╯╰┻━━╯╰╯╱╰━┻━━┻━━┻━━┻━━╯╰╯
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";
import "./DropNFT.sol";

// =============================================================
//                       FRONTEND API
// =============================================================

interface ITributeBrand {
    function signedMint(
        address to,
        bytes32 uuid,
        bytes32 mintData,
        uint256 expiresAt,
        uint256 price,
        bytes calldata signature
    ) external payable;

    function signedPayment(bytes32 uuid, uint256 expiresAt, uint256 price, bytes calldata signature) external payable;

    /**
     * @dev See comment in DropNFT.sol over the function tokensOfOwner for info
     * 			on how to enumerate all the tokens in all the drops owned by some user.
     *
     */

    function currentDrop() external view returns (DropNFT);

    /**
     * @dev This function (drops) exists, its just commented out because its created internally
     * 			by the compiler (due to there existing a state variable with the same and public visibility).
     *
     * 			See comment in DropNFT.sol over the function tokensOfOwner for info on how to use this function
     * 			to enumerate all the tokens in all the drops owned by some specific user (it has to be done off-chain).
     */

    // function drops() public returns(DropNFT);
}

/// @title Tribute Brand
/// @author Tribute Brand LLC
/// @notice This contract serves as interface and factory to all Tribute Brand blockchain processes.

contract TributeBrand is EIP712, ReentrancyGuard, Ownable, ITributeBrand, CantBeEvil(LicenseVersion.PUBLIC) {
    error ActionAlreadyUsed();
    error BadSignature();
    error SignatureExpired();
    error InvalidPayment(uint256 required, uint256 received);

    // =============================================================
    //                        EVENTS
    // =============================================================

    event TokenMinted(address indexed receiver, address indexed dropNFT, uint256 tokenId, bytes32 indexed mintData);

    event ReservedTokensMinted(
        address indexed receiver, address indexed dropNFT, uint256 indexed startTokenId, uint256 quantity
    );
    event PaymentReceived(bytes32 indexed uuid, address indexed from, uint256 amount);

    // =============================================================
    //                        TYPES / UTILITY
    // =============================================================

    address private constant VERIFIER_ADDRESS = 0x2C1c452924C085566d764e3186a886A7eAA23229;

    bytes32 public constant SIGNED_ACTION_TYPEHASH =
        keccak256("SignedAction(bytes32 uuid,bytes32 data,uint256 expiresAt,uint256 price)");

    struct SignedAction {
        bytes32 uuid;
        bytes32 data;
        uint256 expiresAt;
        uint256 price;
    }

    // Utility function for backend to create digest for a signed action.
    // A digest can only be used once, so it can be seen as the UUID for the action.
    // Both signed mint and payment use this.
    // Mint uses data to specify tokenId and dropId. Payment uses data to specify payment uuid on backend.
    function actionDigest(bytes32 uuid, bytes32 data, uint256 expiresAt, uint256 price)
        public
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedDataV4(keccak256(abi.encode(SIGNED_ACTION_TYPEHASH, uuid, data, expiresAt, price)));
    }

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================

    constructor(string memory name, string memory version) EIP712(name, version) {}

    // =============================================================
    //                        DROPS
    // =============================================================

    DropNFT[] public drops;

    // Adds the given drop (note: it appears on opensea after the first token is minted).
    function publishDrop(address dropNFTAddress) external onlyOwner {
        DropNFT dropNFT = DropNFT(dropNFTAddress);
        drops.push(dropNFT);
        dropNFT.requestEntropy();
    }

    function revealDrop(string calldata realBaseTokenURI) external onlyOwner {
        currentDrop().reveal(realBaseTokenURI);
    }

    function currentDrop() public view returns (DropNFT) {
        require(drops.length > 0, "No drops have been created yet.");
        return drops[drops.length - 1];
    }

    // =============================================================
    //                        PAYMENTS
    // =============================================================

    function signedPayment(bytes32 uuid, uint256 expiresAt, uint256 price, bytes calldata signature)
        external
        payable
        verifySignature(uuid, bytes32(0), expiresAt, price, signature)
    {
        emit PaymentReceived(uuid, msg.sender, msg.value);
    }

    // =============================================================
    //                        MINTING
    // =============================================================
    // mintData is 32 bytes long and currently encodes drop id.
    // drop id = 0 means use currentDrop, so leave it empty to mint on the latest.
    function signedMint(
        address to,
        bytes32 uuid,
        bytes32 mintData,
        uint256 expiresAt,
        uint256 price,
        bytes calldata signature
    ) external payable verifySignature(uuid, mintData, expiresAt, price, signature) {
        uint256 dropId = uint256(mintData);
        address receiver = to == address(0) ? msg.sender : to;
        DropNFT drop = dropId == 0 ? currentDrop() : drops[dropId];
        uint256 tokenId = drop.mint(receiver, 0);
        emit TokenMinted(receiver, address(drop), tokenId, mintData);
    }

    function reservedMint(
        address to,
        uint256 dropId, // 0 means current drop
        uint256 quantity
    ) external onlyOwner {
        DropNFT drop = dropId == 0 ? currentDrop() : drops[dropId];
        uint256 startTokenId = drop.reservedMint(to, quantity, 0);
        emit ReservedTokensMinted(to, address(drop), startTokenId, quantity);
    }

    // =============================================================
    //                        OTHER
    // =============================================================

    function checkClaimEligibility(uint256 quantity) external view returns (string memory) {
        if (drops.length == 0) {
            return "not live yet";
        } else {
            DropNFT drop = drops[drops.length - 1];
            return drop.checkClaimEligibility(quantity);
        }
    }

    // keep track of used action signatures
    mapping(bytes32 => bool) private _actionDigestUsed;

    modifier verifySignature(bytes32 uuid, bytes32 data, uint256 expiresAt, uint256 price, bytes calldata signature) {
        if (price != msg.value) revert InvalidPayment(price, msg.value);
        if (block.timestamp > expiresAt) revert SignatureExpired();

        bytes32 digest = actionDigest(uuid, data, expiresAt, price);

        if (_actionDigestUsed[digest]) revert ActionAlreadyUsed();

        if (VERIFIER_ADDRESS != ECDSA.recover(digest, signature)) {
            revert BadSignature();
        }
        _actionDigestUsed[digest] = true;
        _;
    }

    function withdraw(address _receiver) public onlyOwner {
        (bool os,) = payable(_receiver).call{value: address(this).balance}("");
        require(os, "Withdraw unsuccesful");
    }
}