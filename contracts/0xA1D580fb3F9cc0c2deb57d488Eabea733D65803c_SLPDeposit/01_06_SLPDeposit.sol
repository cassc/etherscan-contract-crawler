// SPDX-License-Identifier: GPL-3.0
// solhint-disable var-name-mixedcase

pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// solhint-disable-next-line max-line-length
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

interface IDepositContract {
    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

contract SLPDeposit is OwnableUpgradeable {
    struct Validator {
        bytes pubkey;
        bytes withdrawal_credentials;
        bytes signature;
        bytes32 deposit_data_root;
    }

    /* ========== EVENTS ========== */

    event EthDeposited(address indexed sender, uint256 tokenAmount);

    /* ========== CONSTANTS ========== */

    uint256 public constant DEPOSIT_SIZE = 32 ether;
    // solhint-disable-next-line max-line-length
    // Refer to https://github.com/lidofinance/lido-dao/blob/14503a5a9c7c46864704bb3561e22ae2f84a04ff/contracts/0.8.9/BeaconChainDepositor.sol#L27
    uint64 public constant DEPOSIT_SIZE_IN_GWEI_LE64 = 0x0040597307000000;
    uint256 public constant MAX_VALIDATORS_PER_DEPOSIT = 50;

    /* ========== STATE VARIABLES ========== */

    // address of Ethereum 2.0 Deposit Contract
    IDepositContract public depositContract;
    // batch id => merkle root of withdrawal_credentials
    mapping(uint256 => bytes32) public merkleRoots;
    // SLP core address
    address public slpCore;
    // withdrawal_credentials with prefix 0x01
    bytes public withdrawalCredentials;
    // WithdrawVault address
    address public withdrawVault;

    /* ========== EVENTS ========== */

    event MerkleRootSet(address indexed sender, uint256 indexed batchId, bytes32 merkleRoot);
    event SLPCoreSet(address indexed sender, address slpCore);
    event WithdrawalCredentialsSet(address indexed sender, bytes withdrawalCredentials);

    function initialize(address _depositContract) public initializer {
        require(_depositContract != address(0), "Invalid deposit contract");
        super.__Ownable_init();

        depositContract = IDepositContract(_depositContract);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Only called by SLP contracts. If you don't know the purpose of this method, please don't call it directly.
    function depositETH() external payable {
        emit EthDeposited(msg.sender, msg.value);
    }

    function batchDepositWithProof(
        uint256 batchId,
        bytes32[] memory proof,
        bool[] memory proofFlags,
        Validator[] memory validators
    ) external onlyOwner {
        require(validators.length <= MAX_VALIDATORS_PER_DEPOSIT, "Too many validators");
        bytes32 root = merkleRoots[batchId];
        require(root != bytes32(0), "Merkle root not exists");

        bytes32[] memory leaves = new bytes32[](validators.length);
        for (uint256 i = 0; i < validators.length; i++) {
            leaves[i] = keccak256(validators[i].withdrawal_credentials);
        }
        require(
            MerkleProofUpgradeable.multiProofVerify(proof, proofFlags, root, leaves),
            "Merkle proof verification failed"
        );

        for (uint256 i = 0; i < validators.length; i++) {
            innerDeposit(validators[i]);
        }
    }

    function batchDeposit(Validator[] calldata validators) external onlyOwner {
        require(validators.length <= MAX_VALIDATORS_PER_DEPOSIT, "Too many validators");
        require(withdrawalCredentials[0] == 0x01, "Wrong credential prefix");
        for (uint256 i = 0; i < validators.length; i++) {
            require(checkDepositDataRoot(validators[i]), "Invalid deposit data");
            innerDeposit(validators[i]);
        }
    }

    function withdrawETH(address recipient, uint256 amount) external onlySLPCoreOrWithdrawVault {
        _sendValue(payable(recipient), amount);
    }

    function setMerkleRoot(uint256 batchId, bytes32 merkleRoot) external onlyOwner {
        require(merkleRoots[batchId] == bytes32(0), "Merkle root exists");
        require(merkleRoot != bytes32(0), "Invalid merkle root");
        merkleRoots[batchId] = merkleRoot;
        emit MerkleRootSet(msg.sender, batchId, merkleRoot);
    }

    function setCredential(address receiver) external onlyOwner {
        require(receiver != address(0), "Invalid receiver");
        withdrawalCredentials = abi.encodePacked(bytes12(0x010000000000000000000000), receiver);
        emit WithdrawalCredentialsSet(msg.sender, withdrawalCredentials);
    }

    function setSLPCore(address _slpCore) external onlyOwner {
        require(_slpCore != address(0), "Invalid SLP core address");
        slpCore = _slpCore;
        emit SLPCoreSet(msg.sender, slpCore);
    }

    function setWithdrawVault(address _withdrawVault) external onlyOwner {
        require(_withdrawVault != address(0), "Invalid withdraw vault address");
        withdrawVault = _withdrawVault;
    }

    function _sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value");
    }

    function innerDeposit(Validator memory validator) private {
        require(address(this).balance >= DEPOSIT_SIZE, "Insufficient balance");
        depositContract.deposit{value: DEPOSIT_SIZE}(
            validator.pubkey,
            validator.withdrawal_credentials,
            validator.signature,
            validator.deposit_data_root
        );
    }

    /* ========== VIEWS ========== */

    function checkDepositDataRoot(Validator calldata validator) public view returns (bool) {
        Validator memory _validator = getValidatorData(validator.pubkey, validator.signature);
        return _validator.deposit_data_root == validator.deposit_data_root;
    }

    function getValidatorData(bytes calldata pubkey, bytes calldata signature) public view returns (Validator memory) {
        bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 signature_root = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(signature[:64])),
                sha256(abi.encodePacked(signature[64:], bytes32(0)))
            )
        );
        bytes32 deposit_data_root = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkey_root, withdrawalCredentials)),
                sha256(abi.encodePacked(DEPOSIT_SIZE_IN_GWEI_LE64, bytes24(0), signature_root))
            )
        );

        return Validator(pubkey, withdrawalCredentials, signature, deposit_data_root);
    }

    modifier onlySLPCoreOrWithdrawVault() {
        require(msg.sender == slpCore || msg.sender == withdrawVault, "Invalid sender");
        _;
    }
}