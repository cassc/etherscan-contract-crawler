//                                                                           ,,---.
//                                                                         .-^^,_  `.
//                                                                    ;`, / 3 ( o\   }
//         __             __                     ___              __  \  ;   \`, /  ,'
//        /\ \__         /\ \                  /'___\ __         /\ \ ;_/^`.__.-"  ,'
//    ____\ \ ,_\    __  \ \ \/'\      __     /\ \__//\_\    ____\ \ \___     `---'
//   /',__\\ \ \/  /'__`\ \ \ , <    /'__`\   \ \ ,__\/\ \  /',__\\ \  _ `\
//  /\__, `\\ \ \_/\ \L\.\_\ \ \\`\ /\  __/  __\ \ \_/\ \ \/\__, `\\ \ \ \ \
//  \/\____/ \ \__\ \__/.\_\\ \_\ \_\ \____\/\_\\ \_\  \ \_\/\____/ \ \_\ \_\
//   \/___/   \/__/\/__/\/_/ \/_/\/_/\/____/\/_/ \/_/   \/_/\/___/   \/_/\/_/
//
// stakefish Eth2 Batch Deposit contract
//
// This contract allows deposit of multiple validators in one transaction
// SPDX-License-Identifier: Apache-2.0

// Coinbase updates: remove fee collection, pausing and ownership

pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";

// Deposit contract interface
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

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

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

/// @notice BatchDeposit is a contract to support creating multiple ETH2 deposits in a single transaction
contract BatchDeposit {
    using SafeMath for uint256;

    address immutable depositContract;

    uint256 constant PUBKEY_LENGTH = 48;
    uint256 constant SIGNATURE_LENGTH = 96;
    uint256 constant CREDENTIALS_LENGTH = 32;
    uint256 constant MAX_VALIDATORS = 100;
    uint256 constant DEPOSIT_AMOUNT = 32 ether;

    /**
     * @notice Creates a BatchDeposit contract
     * @param depositContractAddr Address of the underlying deposit contract
    */
    constructor(address depositContractAddr) public {
        require(IERC165(depositContractAddr).supportsInterface(type(IDepositContract).interfaceId), "BatchDeposit: Invalid Deposit Contract");
        depositContract = depositContractAddr;
    }

    /**
     * @notice Performs a batch deposit
     * @param pubkeys Concatenation of multiple BLS12-381 public keys.
     * @param withdrawal_credentials Commitment to a public key for withdrawals.
     * @param signatures Concatenation of multiple BLS12-381 signature.
     * @param deposit_data_roots List of SHA-256 hashes of the SSZ-encoded DepositData object.
     */
    function batchDeposit(
        bytes calldata pubkeys,
        bytes calldata withdrawal_credentials,
        bytes calldata signatures,
        bytes32[] calldata deposit_data_roots
    )
        external payable
    {
        // sanity checks
        require(msg.value % 1 gwei == 0, "BatchDeposit: Deposit value not multiple of GWEI");
        require(msg.value >= DEPOSIT_AMOUNT, "BatchDeposit: Amount is too low");

        uint256 count = deposit_data_roots.length;
        require(count > 0, "BatchDeposit: You should deposit at least one validator");
        require(count <= MAX_VALIDATORS, "BatchDeposit: You can deposit max 100 validators at a time");

        require(pubkeys.length == count * PUBKEY_LENGTH, "BatchDeposit: Pubkey count doesn't match");
        require(signatures.length == count * SIGNATURE_LENGTH, "BatchDeposit: Signatures count doesn't match");
        require(withdrawal_credentials.length == 1 * CREDENTIALS_LENGTH, "BatchDeposit: Withdrawal Credentials count doesn't match");

        uint256 expectedAmount = DEPOSIT_AMOUNT.mul(count);
        require(msg.value == expectedAmount, "BatchDeposit: Amount is not aligned with number of pubkeys");

        for (uint256 i = 0; i < count; ++i) {
            bytes memory pubkey = bytes(pubkeys[i*PUBKEY_LENGTH:(i+1)*PUBKEY_LENGTH]);
            bytes memory signature = bytes(signatures[i*SIGNATURE_LENGTH:(i+1)*SIGNATURE_LENGTH]);

            IDepositContract(depositContract).deposit{value: DEPOSIT_AMOUNT}(
                pubkey,
                withdrawal_credentials,
                signature,
                deposit_data_roots[i]
            );
        }
    }
}