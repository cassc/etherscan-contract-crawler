// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
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

interface IOracle {
    /// @notice Query the exchange rate between ETH and CETH2.
    /// @return The exchange rate.
    function exchangeRate() external view returns (uint);
}

contract CreamETH2 is ERC20 {
    event DepositEvent(
        address account,
        uint ethAmount,
        uint creth2Amount
    );

    event WithdrawEvent(
        address account,
        uint ethAmount,
        uint creth2Amount
    );

    event StakeEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes signature
    );

    IDepositContract public constant eth2DepositContract = IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    uint public constant VALIDATOR_AMOUNT = 32e18;

    address public admin;
    IOracle public oracle;
    uint public cap;
    uint public accumulated = 0;
    bool public breaker = false;

    constructor(address _oracle, uint _cap) public ERC20("Cream ETH 2", "CRETH2") {
        admin = msg.sender;
        oracle = IOracle(_oracle);
        cap = _cap;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "!admin");
        admin = _admin;
    }

    function setOracle(address _oracle) external {
        require(msg.sender == admin, "!admin");
        oracle = IOracle(_oracle);
    }

    function increaseCap(uint _cap) external {
        require(msg.sender == admin, "!admin");
        require(_cap > cap, "cap must strictly increase");
        cap = _cap;
    }

    function setBreaker(bool _breaker) external {
        require(msg.sender == admin, "!admin");
        breaker = _breaker;
    }

    function stake(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external payable {
        require(msg.sender == admin, "!admin");

        uint count = pubkeys.length;
        require(count == withdrawal_credentials.length, "invalid argument");
        require(count == signatures.length, "invalid argument");
        require(count == deposit_data_roots.length, "invalid argument");

        uint totalAmount = VALIDATOR_AMOUNT.mul(count);
        require(address(this).balance >= totalAmount, "insufficient balance");

        for (uint i = 0; i < count; i++) {
            eth2DepositContract.deposit{value: VALIDATOR_AMOUNT}(pubkeys[i], withdrawal_credentials[i], signatures[i], deposit_data_roots[i]);
            emit StakeEvent(pubkeys[i], withdrawal_credentials[i], signatures[i]);
        }
    }

    function deposit() external payable {
        require(breaker == false, "breaker");
        accumulated = accumulated.add(msg.value);
        require(accumulated <= cap, "cap exceeded");
        uint creth2Amount = msg.value.mul(oracle.exchangeRate()).div(1e18);

        _mint(msg.sender, creth2Amount);
        emit DepositEvent(msg.sender, msg.value, creth2Amount);
    }

    function withdraw(uint creth2Amount) external {
        require(breaker == true, "!breaker");
        uint ethAmount = creth2Amount.mul(1e18).div(oracle.exchangeRate());
        require(address(this).balance >= ethAmount, "insufficient balance");
        accumulated = accumulated.sub(ethAmount);

        _burn(msg.sender, creth2Amount);
        msg.sender.transfer(ethAmount);
        emit WithdrawEvent(msg.sender, ethAmount, creth2Amount);
    }
}