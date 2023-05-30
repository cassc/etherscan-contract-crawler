// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "reservoir-oracle/ReservoirOracle.sol";

/// @title StolenNftFilterOracle
/// @author out.eth (@outdoteth)
/// @notice A contract to check that a set of NFTs are not stolen.
contract StolenNftFilterOracle is ReservoirOracle, Owned {
    bytes32 private constant TOKEN_TYPE_HASH = keccak256("Token(address contract,uint256 tokenId)");
    uint256 public cooldownPeriod = 0;
    uint256 public validFor = 60 minutes;

    constructor() Owned(msg.sender) ReservoirOracle(0xAeB1D03929bF87F69888f381e73FBf75753d75AF) {}

    /// @notice Sets the cooldown period.
    /// @param _cooldownPeriod The cooldown period.
    function setCooldownPeriod(uint256 _cooldownPeriod) public onlyOwner {
        cooldownPeriod = _cooldownPeriod;
    }

    /// @notice Sets the valid for period.
    /// @param _validFor The valid for period.
    function setValidFor(uint256 _validFor) public onlyOwner {
        validFor = _validFor;
    }

    function updateReservoirOracleAddress(address newReservoirOracleAddress) public override onlyOwner {
        RESERVOIR_ORACLE_ADDRESS = newReservoirOracleAddress;
    }

    /// @notice Checks that a set of NFTs are not stolen.
    /// @param tokenAddress The address of the NFT contract.
    /// @param tokenIds The ids of the NFTs.
    /// @param messages The messages signed by the reservoir oracle.
    function validateTokensAreNotStolen(address tokenAddress, uint256[] calldata tokenIds, Message[] calldata messages)
        public
        view
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Message calldata message = messages[i];

            // check that the signer is correct and message id matches token id + token address
            bytes32 expectedMessageId = keccak256(abi.encode(TOKEN_TYPE_HASH, tokenAddress, tokenIds[i]));
            require(_verifyMessage(expectedMessageId, validFor, message), "Message has invalid signature");

            (bool isFlagged, uint256 lastTransferTime) = abi.decode(message.payload, (bool, uint256));

            // check that the NFT is not stolen
            require(!isFlagged, "NFT is flagged as suspicious");

            // check that the NFT was not transferred too recently
            require(lastTransferTime + cooldownPeriod < block.timestamp, "NFT was transferred too recently");
        }
    }
}