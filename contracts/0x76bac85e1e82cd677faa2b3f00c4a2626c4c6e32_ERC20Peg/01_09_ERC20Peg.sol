// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./CENNZnetBridge.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Provides an Eth/ERC20/GA CENNZnet peg
// - depositing: lock Eth/ERC20 tokens to redeem CENNZnet "generic asset" 1:1
// - withdrawing: burn or lock GAs to redeem Eth/ERC20 tokens 1:1
contract ERC20Peg is Ownable {
    using SafeMath for uint256;
    // whether the peg is accepting deposits
    bool public depositsActive;
    // whether CENNZ deposists are on
    bool public cennzDepositsActive;
    // whether the peg is accepting withdrawals
    bool public withdrawalsActive;
    // CENNZnet bridge contract address
    CENNZnetBridge public bridge;
    // Reserved address for native Eth deposits/withdraw
    address constant public ETH_RESERVED_TOKEN_ADDRESS = address(0);
    // CENNZ ERC20 contract address
    address constant public CENNZ_TOKEN_ADDRESS = 0x1122B6a0E00DCe0563082b6e2953f3A943855c1F;

    constructor(address _bridge) {
        bridge = CENNZnetBridge(_bridge);
    }

    event Endow(uint256 amount);
    event Deposit(address indexed, address tokenType, uint256 amount, bytes32 cennznetAddress);
    event Withdraw(address indexed, address tokenType, uint256 amount);

    // Deposit amount of tokenType the pegged version of the token will be claim-able on CENNZnet.
    // tokenType '0' is reserved for native Eth
    function deposit(address tokenType, uint256 amount, bytes32 cennznetAddress) payable external {
        require(depositsActive, "deposits paused");
        require(cennznetAddress != bytes32(0), "invalid CENNZnet address");

        if (tokenType == ETH_RESERVED_TOKEN_ADDRESS) {
            require(msg.value == amount, "incorrect deposit amount");
        } else {
            // CENNZ deposits will require a vote to activate
            if (tokenType == CENNZ_TOKEN_ADDRESS) {
                require(cennzDepositsActive, "cennz deposits paused");
            }
            SafeERC20.safeTransferFrom(IERC20(tokenType), msg.sender, address(this), amount);
        }

        emit Deposit(msg.sender, tokenType, amount, cennznetAddress);
    }

    // Withdraw tokens from this contract
    // tokenType '0' is reserved for native Eth
    // Requires signatures from a threshold of current CENNZnet validators
    // v,r,s are sparse arrays expected to align w public key in 'validators'
    // i.e. v[i], r[i], s[i] matches the i-th validator[i]
    function withdraw(address tokenType, uint256 amount, address recipient, CENNZnetEventProof calldata proof) payable external {
        require(withdrawalsActive, "withdrawals paused");
        bytes memory message = abi.encode(tokenType, amount, recipient, proof.validatorSetId, proof.eventId);
        bridge.verifyMessage{ value: msg.value }(message, proof);

        if (tokenType == ETH_RESERVED_TOKEN_ADDRESS) {
            (bool sent, ) = recipient.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            SafeERC20.safeTransfer(IERC20(tokenType), recipient, amount);
        }

        emit Withdraw(recipient, tokenType, amount);
    }

    function endow() external onlyOwner payable {
        require(msg.value > 0, "must endow nonzero");
        emit Endow(msg.value);
    }

    function activateCENNZDeposits() external onlyOwner {
        cennzDepositsActive = true;
    }

    function activateDeposits() external onlyOwner {
        depositsActive = true;
    }

    function pauseDeposits() external onlyOwner {
        depositsActive = false;
    }

    function activateWithdrawals() external onlyOwner {
        withdrawalsActive = true;
    }

    function pauseWithdrawals() external onlyOwner {
        withdrawalsActive = false;
    }
}