// SPDX-License-Identifier: MIT

/// @title Muon Interface
/// @author DIBS (spsina)
/// @notice This contract is used to interact with the Muon protocol and DIBS contract

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./MuonClient.sol";
import "./interfaces/IDibs.sol";

contract MuonInterfaceV1 is MuonClient, AccessControl {
    using ECDSA for bytes32;
    bytes32 public constant SETTER = keccak256("SETTER");

    // ======== STATE VARIABLES ========

    address public dibs;
    address public validGateway;

    // ======== CONSTRUCTOR ========

    constructor(
        address admin_,
        address setter_,
        address dibs_,
        address validGateway_,
        uint256 muonAppId_,
        PublicKey memory muonPublicKey_
    ) MuonClient(muonAppId_, muonPublicKey_) {
        dibs = dibs_;
        validGateway = validGateway_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(SETTER, setter_);
    }

    // ======== PUBLIC FUNCTIONS ========

    error InvalidSignature();
    error InvalidGateway();

    /// @notice Verifies a Muon signature of the given data
    /// @param data data being signed
    /// @param reqId request id that the signature was obtained from
    /// @param sign signature of the data
    /// @param gatewaySignature signature of the data by the gateway (specific Muon node)
    /// reverts if the signature is invalid
    function verifyTSSAndGW(
        bytes memory data,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) public {
        bytes32 hash = keccak256(abi.encodePacked(muonAppId, reqId, data));
        if (!muonVerify(reqId, uint256(hash), sign, muonPublicKey))
            revert InvalidSignature();

        hash = hash.toEthSignedMessageHash();
        address gatewaySignatureSigner = hash.recover(gatewaySignature);

        if (gatewaySignatureSigner != validGateway) revert InvalidGateway();
    }

    event Claimed(address indexed user, address indexed token, uint256 amount);

    /// @notice withdraws tokens from Dibs contract on behalf of a user
    /// @param user user address
    /// @param token token address
    /// @param to address to send the tokens to
    /// @param accumulativeBalance accumulative balance of the user
    /// @param amount amount of tokens to withdraw
    /// @param sign signature of the data
    /// @param reqId request id that the signature was obtained from
    /// @param gatewaySignature signature of the data by the gateway (specific Muon node)
    function claim(
        address user,
        address token,
        address to,
        uint256 accumulativeBalance,
        uint256 amount,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) external {
        bytes memory data = abi.encodePacked(user, token, accumulativeBalance);
        verifyTSSAndGW(data, reqId, sign, gatewaySignature);
        IDibs(dibs).claim(user, token, amount, to, accumulativeBalance);
        emit Claimed(user, token, amount);
    }

    event RoundWinnerSet(uint32 indexed round, address indexed winner);

    /// @notice sets the winner of a round
    /// @param round round number
    /// @param winner winner address
    /// @param reqId request id that the signature was obtained from
    /// @param sign signature of the data
    /// @param gatewaySignature signature of the data by the gateway (specific Muon node)
    function setRoundWinner(
        uint32 round,
        address winner,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) external {
        bytes memory data = abi.encodePacked(round, winner);
        verifyTSSAndGW(data, reqId, sign, gatewaySignature);
        IDibs(dibs).setRoundWinner(round, winner);
        emit RoundWinnerSet(round, winner);
    }

    // ======== RESTRICTED FUNCTIONS ========

    event SetDibs(address _old, address _new);

    /// @notice sets the Dibs contract address
    /// @param dibs_ Dibs contract address
    function setDibs(address dibs_) external onlyRole(SETTER) {
        emit SetDibs(dibs, dibs_);
        dibs = dibs_;
    }

    event SetMuonPublicKey(PublicKey _old, PublicKey _new);

    /// @notice sets the Muon public key
    /// @param muonPublicKey_ Muon public key
    function setMuonPublicKey(PublicKey calldata muonPublicKey_)
        external
        onlyRole(SETTER)
    {
        emit SetMuonPublicKey(muonPublicKey, muonPublicKey_);
        muonPublicKey = muonPublicKey_;
    }

    event SetMuonAppId(uint256 _old, uint256 _new);

    /// @notice sets the Muon app id
    /// @param muonAppId_ Muon app id
    function setMuonAppId(uint256 muonAppId_) external onlyRole(SETTER) {
        emit SetMuonAppId(muonAppId, muonAppId_);
        muonAppId = muonAppId_;
    }

    event SetValidGateway(address _old, address _new);

    /// @notice sets the valid gateway address
    /// @param validGateway_ valid gateway address
    function setValidGateway(address validGateway_) external onlyRole(SETTER) {
        emit SetValidGateway(validGateway, validGateway_);
        validGateway = validGateway_;
    }
}