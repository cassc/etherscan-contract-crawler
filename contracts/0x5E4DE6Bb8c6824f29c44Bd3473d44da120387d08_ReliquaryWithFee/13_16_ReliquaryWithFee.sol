/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Reliquary.sol";

struct FeeAccount {
    uint64 subscriberUntilTime;
    uint192 credits;
}

/**
 * @title Holder of Relics and Artifacts with fees
 * @author Theori, Inc.
 * @notice The Reliquary is the heart of Relic. All issuers of Relics and Artifacts
 *         must be added to the Reliquary. Queries about Relics and Artifacts should
 *         be made to the Reliquary. This Reliquary may charge fees for proving or
 *         accessing facts.
 */
contract ReliquaryWithFee is Reliquary {
    using SafeERC20 for IERC20;

    bytes32 public constant CREDITS_ROLE = keccak256("CREDITS_ROLE");
    bytes32 public constant SUBSCRIPTION_ROLE = keccak256("SUBSCRIPTION_ROLE");

    /// Mapping of fact classes to fee infos about them
    mapping(uint8 => FeeInfo) public factFees;
    /// Information about fee accounts (credits & subscriptions)
    mapping(address => FeeAccount) public feeAccounts;
    /// External tokens and fee delegates for use by
    mapping(uint256 => address) public feeExternals;
    uint32 internal feeExternalsCount;
    /// FeeInfo struct for block queries
    FeeInfo public verifyBlockFeeInfo;

    constructor() Reliquary() {}

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev A fee may be required based on the factSig
     */
    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        checkVerifyFactFee(factSig);
        return _verifyFact(account, factSig);
    }

    /**
     * @notice Query for some information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev A fee may be required based on the factSig
     */
    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version)
    {
        checkVerifyFactFee(factSig);
        return _verifyFactVersion(account, factSig);
    }

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) public payable returns (bool) {
        checkValidBlockFee(num);

        // validBlockHash is a view function, so it cannot modify state and is safe to call
        return IBlockHistory(verifier).validBlockHash(hash, num, proof);
    }

    /**
     * @notice Asserts that a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external payable {
        require(validBlockHash(verifier, hash, num, proof), "invalid block hash");
    }

    /**
     * @notice Helper function to calculate fee for a given feeInfo struct
     * @param feeInfo The FeeInfo struct in question
     * @return The associated fee in wei
     */
    function getFeeWei(FeeInfo memory feeInfo) internal pure returns (uint256) {
        return feeInfo.feeWeiMantissa * (10**feeInfo.feeWeiExponent);
    }

    /**
     * @notice Require that an appropriate fee is paid for queries
     * @param sender The initiator of the query
     * @param feeInfo The FeeInfo struct associated with the query
     * @param data Opaque data that may be needed by downstream fee functions
     * @dev Reverts if the fee is not sufficient
     */
    function checkFeeInfo(
        address sender,
        FeeInfo memory feeInfo,
        bytes memory data
    ) internal {
        uint256 feeWei = getFeeWei(feeInfo);

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeNone)) != 0) {
            return;
        }

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeNative)) != 0) {
            if (msg.value >= feeWei) {
                return;
            }
        }

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeCredits)) != 0) {
            FeeAccount memory feeAccount = feeAccounts[sender];
            // check if sender has a valid subscription
            if (feeAccount.subscriberUntilTime > block.timestamp) {
                return;
            }
            // otherwise subtract credits
            if (feeAccount.credits >= feeInfo.feeCredits) {
                feeAccount.credits -= feeInfo.feeCredits;
                feeAccounts[sender] = feeAccount;
                return;
            }
        }

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeExternalDelegate)) != 0) {
            require(feeInfo.feeExternalId != 0);
            address delegate = feeExternals[feeInfo.feeExternalId];
            require(delegate != address(0));
            IFeeDelegate(delegate).checkFee{value: msg.value}(sender, data);
            return;
        }

        if (feeInfo.flags & (1 << uint256(FeeFlags.FeeExternalToken)) != 0) {
            require(feeInfo.feeExternalId != 0);
            address token = feeExternals[feeInfo.feeExternalId];
            require(token != address(0));
            IERC20(token).safeTransferFrom(sender, address(this), feeWei);
            return;
        }

        revert("insufficient fee");
    }

    /**
     * @notice Require that an appropriate fee is paid for verify fact queries
     * @param factSig The signature of the desired fact
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be used internally
     */
    function checkVerifyFactFee(FactSignature factSig) internal {
        uint8 cls = Facts.toFactClass(factSig);
        if (cls != Facts.NO_FEE) {
            checkFeeInfo(msg.sender, factFees[cls], abi.encode("verifyFact", factSig));
        }
    }

    /**
     * @notice Require that an appropriate fee is paid for proving a fact
     * @param sender The account wanting to prove a fact
     * @dev The fee is derived from the prover which calls this  function
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be called by a prover
     */
    function checkProveFactFee(address sender) external payable {
        address prover = msg.sender;
        ProverInfo memory proverInfo = provers[prover];
        checkProver(proverInfo);

        checkFeeInfo(sender, proverInfo.feeInfo, abi.encode("proveFact", prover));
    }

    /**
     * @notice Require that an appropriate fee is paid for verify block queries
     * @param blockNum The block number to verify
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be used internally
     */
    function checkValidBlockFee(uint256 blockNum) internal {
        checkFeeInfo(msg.sender, verifyBlockFeeInfo, abi.encode("verifyBlock", blockNum));
    }

    // Functions to help callers determine how much fee they need to pay
    /**
     * @notice Determine the appropriate ETH fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256) {
        uint8 cls = Facts.toFactClass(factSig);
        if (cls == Facts.NO_FEE) {
            return 0;
        }
        FeeInfo memory feeInfo = factFees[cls];
        require(feeInfo.flags & (1 << uint256(FeeFlags.FeeNative)) != 0);
        return getFeeWei(feeInfo);
    }

    /**
     * @notice Determine the appropriate token fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256) {
        uint8 cls = Facts.toFactClass(factSig);
        if (cls == Facts.NO_FEE) {
            return 0;
        }
        FeeInfo memory feeInfo = factFees[cls];
        require(feeInfo.flags & (1 << uint256(FeeFlags.FeeExternalToken)) != 0);
        return getFeeWei(feeInfo);
    }

    /**
     * @notice Determine the appropriate ETH fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getProveFactNativeFee(address prover) external view returns (uint256) {
        ProverInfo memory proverInfo = provers[prover];
        checkProver(proverInfo);

        require(proverInfo.feeInfo.flags & (1 << uint256(FeeFlags.FeeNative)) != 0);
        return getFeeWei(proverInfo.feeInfo);
    }

    /**
     * @notice Determine the appropriate token fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getProveFactTokenFee(address prover) external view returns (uint256) {
        ProverInfo memory proverInfo = provers[prover];
        checkProver(proverInfo);

        require(proverInfo.feeInfo.flags & (1 << uint256(FeeFlags.FeeExternalToken)) != 0);
        return getFeeWei(proverInfo.feeInfo);
    }

    /**
     * @notice Check how many credits a given account possesses
     * @param user The account in question
     * @return The number of credits
     */
    function credits(address user) public view returns (uint192) {
        return feeAccounts[user].credits;
    }

    /**
     * @notice Check if an account has an active subscription
     * @param user The account in question
     * @return True if the account is active, otherwise false
     */
    function isSubscriber(address user) public view returns (bool) {
        return feeAccounts[user].subscriberUntilTime > block.timestamp;
    }

    /**
     * @notice Adds a new external fee provider (token or delegate) to a feeInfo
     * @param feeInfo The feeInfo to update with this provider
     * @dev Always appends to the global feeExternals
     */
    function _setFeeExternalId(FeeInfo memory feeInfo, address feeExternal)
        internal
        returns (FeeInfo memory)
    {
        uint32 feeExternalId = 0;
        if (feeExternal != address(0)) {
            feeExternalsCount++;
            feeExternalId = feeExternalsCount;
            feeExternals[feeExternalId] = feeExternal;
        }
        feeInfo.feeExternalId = feeExternalId;
        return feeInfo;
    }

    /**
     * @notice Sets the FeeInfo for a particular fee class
     * @param cls The fee class
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external onlyRole(GOVERNANCE_ROLE) {
        feeInfo = _setFeeExternalId(feeInfo, feeExternal);
        factFees[cls] = feeInfo;
    }

    /**
     * @notice Sets the FeeInfo for a particular prover
     * @param prover The prover in question
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external onlyRole(GOVERNANCE_ROLE) {
        ProverInfo memory proverInfo = provers[prover];
        checkProver(proverInfo);

        feeInfo = _setFeeExternalId(feeInfo, feeExternal);
        proverInfo.feeInfo = feeInfo;
        provers[prover] = proverInfo;
    }

    /**
     * @notice Sets the FeeInfo for block verification
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        feeInfo = _setFeeExternalId(feeInfo, feeExternal);
        verifyBlockFeeInfo = feeInfo;
    }

    /**
     * @notice Add/update a subscription
     * @param user The subscriber account to modify
     * @param ts The new block timestamp at which the subscription expires
     */
    function addSubscriber(address user, uint64 ts) external onlyRole(SUBSCRIPTION_ROLE) {
        require(feeAccounts[user].subscriberUntilTime < ts);
        feeAccounts[user].subscriberUntilTime = ts;
    }

    /**
     * @notice Remove a subscription
     * @param user The subscriber account to modify
     */
    function removeSubscriber(address user) external onlyRole(SUBSCRIPTION_ROLE) {
        feeAccounts[user].subscriberUntilTime = 0;
    }

    /**
     * @notice Set credits for an account
     * @param user The account for which credits should be set
     * @param amount The credits that the account should be updated to hold
     */
    function setCredits(address user, uint192 amount) external onlyRole(CREDITS_ROLE) {
        feeAccounts[user].credits = amount;
    }

    /**
     * @notice Add credits to an account
     * @param user The account to which more credits should be granted
     * @param amount The number of credits to be added
     */
    function addCredits(address user, uint192 amount) external onlyRole(CREDITS_ROLE) {
        feeAccounts[user].credits += amount;
    }

    /**
     * @notice Remove credits from an account
     * @param user The account from which credits should be removed
     * @param amount The number of credits to be removed
     */
    function removeCredits(address user, uint192 amount) external onlyRole(CREDITS_ROLE) {
        feeAccounts[user].credits -= amount;
    }

    /**
     * @notice Extract accumulated fees
     * @param token The ERC20 token from which to extract fees. Or the 0 address for
     *        native ETH
     * @param dest The address to which fees should be transferred
     */
    function withdrawFees(address token, address payable dest) external onlyRole(GOVERNANCE_ROLE) {
        require(dest != address(0));

        if (token == address(0)) {
            dest.transfer(address(this).balance);
        } else {
            IERC20(token).transfer(dest, IERC20(token).balanceOf(address(this)));
        }
    }
}