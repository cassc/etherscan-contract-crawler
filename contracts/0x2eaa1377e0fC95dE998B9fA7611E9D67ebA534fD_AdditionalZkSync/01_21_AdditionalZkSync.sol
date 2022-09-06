pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeMathUInt128.sol";
import "./SafeCast.sol";
import "./Utils.sol";

import "./Storage.sol";
import "./Config.sol";
import "./Events.sol";

import "./Bytes.sol";
import "./Operations.sol";

import "./UpgradeableMaster.sol";

/// @title zkSync additional main contract
/// @author Matter Labs
contract AdditionalZkSync is Storage, Config, Events, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathUInt128 for uint128;

    function increaseBalanceToWithdraw(bytes22 _packedBalanceKey, uint128 _amount) internal {
        uint128 balance = pendingBalances[_packedBalanceKey].balanceToWithdraw;
        pendingBalances[_packedBalanceKey] = PendingBalance(balance.add(_amount), FILLED_GAS_RESERVE_VALUE);
    }

    /// @notice Withdraws token from ZkSync to root chain in case of exodus mode. User must provide proof that he owns funds
    /// @param _storedBlockInfo Last verified block
    /// @param _owner Owner of the account
    /// @param _accountId Id of the account in the tree
    /// @param _proof Proof
    /// @param _tokenId Verified token id
    /// @param _amount Amount for owner (must be total amount, not part of it)
    function performExodus(
        StoredBlockInfo calldata _storedBlockInfo,
        address _owner,
        uint32 _accountId,
        uint32 _tokenId,
        uint128 _amount,
        uint32 _nftCreatorAccountId,
        address _nftCreatorAddress,
        uint32 _nftSerialId,
        bytes32 _nftContentHash,
        uint256[] calldata _proof
    ) external nonReentrant {
        require(_accountId <= MAX_ACCOUNT_ID, "e");
        require(_accountId != SPECIAL_ACCOUNT_ID, "v");
        require(_tokenId < SPECIAL_NFT_TOKEN_ID, "T");

        require(exodusMode, "s"); // must be in exodus mode
        require(!performedExodus[_accountId][_tokenId], "t"); // already exited
        require(storedBlockHashes[totalBlocksExecuted] == hashStoredBlockInfo(_storedBlockInfo), "u"); // incorrect stored block info

        bool proofCorrect = verifier.verifyExitProof(
            _storedBlockInfo.stateHash,
            _accountId,
            _owner,
            _tokenId,
            _amount,
            _nftCreatorAccountId,
            _nftCreatorAddress,
            _nftSerialId,
            _nftContentHash,
            _proof
        );
        require(proofCorrect, "x");

        if (_tokenId <= MAX_FUNGIBLE_TOKEN_ID) {
            bytes22 packedBalanceKey = packAddressAndTokenId(_owner, uint16(_tokenId));
            increaseBalanceToWithdraw(packedBalanceKey, _amount);
            emit WithdrawalPending(uint16(_tokenId), _owner, _amount, Operations.WithdrawalType.FullExit);
        } else {
            require(_amount != 0, "Z"); // Unsupported nft amount
            Operations.WithdrawNFT memory withdrawNftOp = Operations.WithdrawNFT(
                _nftCreatorAccountId,
                _nftCreatorAddress,
                _nftSerialId,
                _nftContentHash,
                _owner,
                _tokenId
            );
            pendingWithdrawnNFTs[_tokenId] = withdrawNftOp;
            emit WithdrawalNFTPending(_tokenId);
        }
        performedExodus[_accountId][_tokenId] = true;
    }

    function cancelOutstandingDepositsForExodusMode(uint64 _n, bytes[] calldata _depositsPubdata)
        external
        nonReentrant
    {
        require(exodusMode, "8"); // exodus mode not active
        uint64 toProcess = Utils.minU64(totalOpenPriorityRequests, _n);
        require(toProcess > 0, "9"); // no deposits to process
        uint64 currentDepositIdx = 0;
        for (uint64 id = firstPriorityRequestId; id < firstPriorityRequestId + toProcess; ++id) {
            if (priorityRequests[id].opType == Operations.OpType.Deposit) {
                bytes memory depositPubdata = _depositsPubdata[currentDepositIdx];
                require(Utils.hashBytesToBytes20(depositPubdata) == priorityRequests[id].hashedPubData, "a");
                ++currentDepositIdx;

                Operations.Deposit memory op = Operations.readDepositPubdata(depositPubdata);
                bytes22 packedBalanceKey = packAddressAndTokenId(op.owner, uint16(op.tokenId));
                pendingBalances[packedBalanceKey].balanceToWithdraw += op.amount;
            }
            delete priorityRequests[id];
        }
        firstPriorityRequestId += toProcess;
        totalOpenPriorityRequests -= toProcess;
    }

    uint256 internal constant SECURITY_COUNCIL_THRESHOLD = 9;

    /// @notice processing new approval of decrease upgrade notice period time to zero
    /// @param addr address of the account that approved the reduction of the upgrade notice period to zero
    /// NOTE: does NOT revert if the address is not a security council member or number of approvals is already sufficient
    function approveCutUpgradeNoticePeriod(address addr) internal {
        address payable[SECURITY_COUNCIL_MEMBERS_NUMBER] memory SECURITY_COUNCIL_MEMBERS = [
            0xa2602ea835E03fb39CeD30B43d6b6EAf6aDe1769,0x9D5d6D4BaCCEDf6ECE1883456AA785dc996df607,0x002A5dc50bbB8d5808e418Aeeb9F060a2Ca17346,0x71E805aB236c945165b9Cd0bf95B9f2F0A0488c3,0x76C6cE74EAb57254E785d1DcC3f812D274bCcB11,0xFBfF3FF69D65A9103Bf4fdBf988f5271D12B3190,0xAfC2F2D803479A2AF3A72022D54cc0901a0ec0d6,0x4d1E3089042Ab3A93E03CA88B566b99Bd22438C6,0x19eD6cc20D44e5cF4Bb4894F50162F72402d8567,0x39415255619783A2E71fcF7d8f708A951d92e1b6,0x399a6a13D298CF3F41a562966C1a450136Ea52C2,0xee8AE1F1B4B1E1956C8Bda27eeBCE54Cf0bb5eaB,0xe7CCD4F3feA7df88Cf9B59B30f738ec1E049231f,0xA093284c707e207C36E3FEf9e0B6325fd9d0e33B,0x225d3822De44E58eE935440E0c0B829C4232086e
        ];
        for (uint256 id = 0; id < SECURITY_COUNCIL_MEMBERS_NUMBER; ++id) {
            if (SECURITY_COUNCIL_MEMBERS[id] == addr) {
                // approve cut upgrade notice period if needed
                if (!securityCouncilApproves[id]) {
                    securityCouncilApproves[id] = true;
                    numberOfApprovalsFromSecurityCouncil += 1;
                    emit ApproveCutUpgradeNoticePeriod(addr);

                    if (numberOfApprovalsFromSecurityCouncil >= SECURITY_COUNCIL_THRESHOLD) {
                        if (approvedUpgradeNoticePeriod > 0) {
                            approvedUpgradeNoticePeriod = 0;
                            emit NoticePeriodChange(approvedUpgradeNoticePeriod);
                        }
                    }
                }

                break;
            }
        }
    }

    /// @notice approve to decrease upgrade notice period time to zero
    /// NOTE: сan only be called after the start of the upgrade
    function cutUpgradeNoticePeriod(bytes32 targetsHash) external nonReentrant {
        require(upgradeStartTimestamp != 0, "p1");
        require(getUpgradeTargetsHash() == targetsHash, "p3"); // given targets are not in the active upgrade

        approveCutUpgradeNoticePeriod(msg.sender);
    }

    /// @notice approve to decrease upgrade notice period time to zero by signatures
    /// NOTE: Can accept many signatures at a time, thus it is possible
    /// to completely cut the upgrade notice period in one transaction
    function cutUpgradeNoticePeriodBySignature(bytes[] calldata signatures) external nonReentrant {
        require(upgradeStartTimestamp != 0, "p2");

        bytes32 targetsHash = getUpgradeTargetsHash();
        // The Message includes a hash of the addresses of the contracts to which the upgrade will take place to prevent reuse signature.
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n110",
                "Approved new ZkSync's target contracts hash\n0x",
                Bytes.bytesToHexASCIIBytes(abi.encodePacked(targetsHash))
            )
        );

        for (uint256 i = 0; i < signatures.length; ++i) {
            address recoveredAddress = Utils.recoverAddressFromEthSignature(signatures[i], messageHash);
            approveCutUpgradeNoticePeriod(recoveredAddress);
        }
    }

    /// @return hash of the concatenation of targets for which there is an upgrade
    /// NOTE: revert if upgrade is not active at this moment
    function getUpgradeTargetsHash() internal view returns (bytes32) {
        // Get the addresses of contracts that are being prepared for the upgrade.
        address gatekeeper = 0x38A43F4330f24fe920F943409709fc9A6084C939;
        (bool success0, bytes memory newTarget0) = gatekeeper.staticcall(
            abi.encodeWithSignature("nextTargets(uint256)", 0)
        );
        (bool success1, bytes memory newTarget1) = gatekeeper.staticcall(
            abi.encodeWithSignature("nextTargets(uint256)", 1)
        );
        (bool success2, bytes memory newTarget2) = gatekeeper.staticcall(
            abi.encodeWithSignature("nextTargets(uint256)", 2)
        );

        require(success0 && success1 && success2, "p5"); // failed to get new targets
        address newTargetAddress0 = abi.decode(newTarget0, (address));
        address newTargetAddress1 = abi.decode(newTarget1, (address));
        address newTargetAddress2 = abi.decode(newTarget2, (address));

        return keccak256(abi.encodePacked(newTargetAddress0, newTargetAddress1, newTargetAddress2));
    }

    /// @notice Set data for changing pubkey hash using onchain authorization.
    ///         Transaction author (msg.sender) should be L2 account address
    /// @notice New pubkey hash can be reset, to do that user should send two transactions:
    ///         1) First `setAuthPubkeyHash` transaction for already used `_nonce` will set timer.
    ///         2) After `AUTH_FACT_RESET_TIMELOCK` time is passed second `setAuthPubkeyHash` transaction will reset pubkey hash for `_nonce`.
    /// @param _pubkeyHash New pubkey hash
    /// @param _nonce Nonce of the change pubkey L2 transaction
    function setAuthPubkeyHash(bytes calldata _pubkeyHash, uint32 _nonce) external nonReentrant {
        requireActive();

        require(_pubkeyHash.length == PUBKEY_HASH_BYTES, "y"); // PubKeyHash should be 20 bytes.
        if (authFacts[msg.sender][_nonce] == bytes32(0)) {
            authFacts[msg.sender][_nonce] = keccak256(_pubkeyHash);
        } else {
            uint256 currentResetTimer = authFactsResetTimer[msg.sender][_nonce];
            if (currentResetTimer == 0) {
                authFactsResetTimer[msg.sender][_nonce] = block.timestamp;
            } else {
                require(block.timestamp.sub(currentResetTimer) >= AUTH_FACT_RESET_TIMELOCK, "z");
                authFactsResetTimer[msg.sender][_nonce] = 0;
                authFacts[msg.sender][_nonce] = keccak256(_pubkeyHash);
            }
        }
    }

    /// @notice Reverts unverified blocks
    function revertBlocks(StoredBlockInfo[] calldata _blocksToRevert) external nonReentrant {
        requireActive();

        governance.requireActiveValidator(msg.sender);

        uint32 blocksCommitted = totalBlocksCommitted;
        uint32 blocksToRevert = Utils.minU32(uint32(_blocksToRevert.length), blocksCommitted - totalBlocksExecuted);
        uint64 revertedPriorityRequests = 0;

        for (uint32 i = 0; i < blocksToRevert; ++i) {
            StoredBlockInfo memory storedBlockInfo = _blocksToRevert[i];
            require(storedBlockHashes[blocksCommitted] == hashStoredBlockInfo(storedBlockInfo), "r"); // incorrect stored block info

            delete storedBlockHashes[blocksCommitted];

            --blocksCommitted;
            revertedPriorityRequests += storedBlockInfo.priorityOperations;
        }

        totalBlocksCommitted = blocksCommitted;
        totalCommittedPriorityRequests -= revertedPriorityRequests;
        if (totalBlocksCommitted < totalBlocksProven) {
            totalBlocksProven = totalBlocksCommitted;
        }

        emit BlocksRevert(totalBlocksExecuted, blocksCommitted);
    }
}