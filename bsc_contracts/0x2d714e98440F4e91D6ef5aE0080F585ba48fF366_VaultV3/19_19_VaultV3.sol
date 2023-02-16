// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "../openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IToken.sol";

contract VaultV3 is EIP712Upgradeable, AccessControlUpgradeable {
    struct ClaimRequest {
        uint id;
        address[] addresses;
        uint nonce;
        uint timestamp;
        string messageForAlice;
        uint[] cumulativeDebits;
        bytes[] signatures;
        uint256 closed;
    }

    struct ClaimTransaction {
        uint id;
        uint nonce;
        uint timestamp;
        uint[] cumulativeDebits;
    }

    struct EmergencyWithdrawRequest {
        ClaimTransaction claimTransaction;
        uint timestamp;
        address requester;
    }

    struct BobWithdrawRequest {
        uint256 timestamp;
        uint256 amount;
    }

    IToken private _token;

    // Alice constant
    uint8 constant ALICE = 0;
    // Bob constant
    uint8 constant BOB = 1;

    address public serverAddress;
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    mapping(address => uint256) public balances;

    mapping(address => ClaimTransaction) public withdrawTransactions;

    BobWithdrawRequest public bobWithdrawRequest;

    mapping(address => EmergencyWithdrawRequest) public emergencyWithdrawRequests;

    event InitEmergencyWithdraw(EmergencyWithdrawRequest emergencyWithdrawRequest);
    event StopEmergencyWithdraw(EmergencyWithdrawRequest emergencyWithdrawRequest, string cause);

    // Evento da emettere quando completo il withdraw consensuale
    event WithdrawAlice(ClaimTransaction claimTransaction);
    event WithdrawBob(uint amount);

    modifier onlyAliceRequest(ClaimRequest memory req) {
        require(msg.sender == req.addresses[ALICE], "Request must be sent by Alice.");
        _;
    }

    modifier onlyAlice() {
        require(msg.sender != serverAddress, "Requester must be Alice.");
        _;
    }

    modifier onlyBob() {
        require(msg.sender == serverAddress, "Requester must be Bob.");
        _;
    }

    function deposit(
        uint256 amount
    ) public {
        balances[msg.sender] += amount;
        require(_token.transferFrom(msg.sender, address(this), amount), "ERC20 operation did not succeed");
    }

    function depositFor(
        address account,
        uint256 amount
    ) public {
        balances[account] += amount;
        require(_token.transferFrom(msg.sender, address(this), amount), "ERC20 operation did not succeed");
    }

    function balanceOf(address clientAddress) public view returns (uint256) {
        return balances[clientAddress];
    }

    function verify(ClaimRequest calldata req) public view {
        require(req.addresses[BOB] == serverAddress, 'Bob is not the server.');
        require(req.cumulativeDebits[ALICE] == 0 || req.cumulativeDebits[BOB] == 0, "Claim is not balanced.");
        require(req.cumulativeDebits[ALICE] <= balances[req.addresses[ALICE]], "Balance {Alice} KO.");
        require(req.cumulativeDebits[BOB] <= _token.balanceOf(address(this)), "Balance {Bob} KO.");

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Claim(uint256 id,address alice,address bob,uint256 nonce,uint256 timestamp,string messageForAlice,uint256 cumulativeDebitAlice,uint256 cumulativeDebitBob,uint256 closed)"),
                    req.id,
                    req.addresses[ALICE],
                    req.addresses[BOB],
                    req.nonce,
                    req.timestamp,
                    keccak256(bytes(req.messageForAlice)),
                    req.cumulativeDebits[ALICE],
                    req.cumulativeDebits[BOB],
                    req.closed
                )
            )
        );
        
        address recoveredSignerAlice = ECDSAUpgradeable.recover(digest, req.signatures[ALICE]);
        address recoveredSignerBob = ECDSAUpgradeable.recover(digest, req.signatures[BOB]);

        require(recoveredSignerAlice == req.addresses[ALICE], "Signature ALICE mismatch.");
        require(recoveredSignerBob == req.addresses[BOB], "Signature BOB mismatch.");
    }

    function _processClaimRequest(
        ClaimRequest calldata req
    ) private view returns (ClaimTransaction memory){
        verify(req);

        ClaimTransaction memory claimTransaction;

        claimTransaction.id = req.id;
        claimTransaction.nonce = req.nonce;
        claimTransaction.timestamp = req.timestamp;
        claimTransaction.cumulativeDebits = req.cumulativeDebits;

        return claimTransaction;
    }

    // emergency withdraw
    function _initEmergencyWithdraw(ClaimTransaction memory claimTransaction, address alice) private {
        EmergencyWithdrawRequest storage emergencyWithdrawRequest = emergencyWithdrawRequests[alice];
        require(emergencyWithdrawRequest.timestamp == 0, "Another emergency withdraw running.");

        emergencyWithdrawRequests[alice] = EmergencyWithdrawRequest(claimTransaction, block.timestamp, msg.sender);

        emit InitEmergencyWithdraw(emergencyWithdrawRequests[alice]);
    }

    function initEmergencyWithdraw(ClaimRequest calldata req) external {
        require(req.addresses[ALICE] == msg.sender || req.addresses[BOB] == msg.sender, 'Only Alice or Bob can withdraw.');

        ClaimTransaction memory lastClaimTransaction = withdrawTransactions[req.addresses[ALICE]];

        require(req.id == lastClaimTransaction.id + 1, "Wrong channel id.");

        _initEmergencyWithdraw(_processClaimRequest(req), req.addresses[ALICE]);
    }

    function _emergencyWithdraw(address alice) private {
        EmergencyWithdrawRequest memory emergencyWithdrawRequest = emergencyWithdrawRequests[alice];

        require(block.timestamp - emergencyWithdrawRequest.timestamp > 3 days, "You cannot withdraw yet.");
        
        withdrawTransactions[alice] = emergencyWithdrawRequest.claimTransaction;
        delete emergencyWithdrawRequests[alice];

        uint256 cumulativeDebitAlice = emergencyWithdrawRequest.claimTransaction.cumulativeDebits[ALICE];
        uint256 cumulativeDebitBob = emergencyWithdrawRequest.claimTransaction.cumulativeDebits[BOB];

        balances[alice] = balances[alice] + cumulativeDebitBob - cumulativeDebitAlice;

        uint amountToTransfer = balances[alice];
        balances[alice] = 0;

        require(_token.transfer(alice, amountToTransfer), "ERC20 operation did not succeed");
    }

    function initEmergencyWithdrawAliceWithoutClaim() external onlyAlice() {
        ClaimTransaction memory claimTransaction;

        claimTransaction.id = withdrawTransactions[msg.sender].id + 1;
        claimTransaction.nonce = 0;
        claimTransaction.timestamp = block.timestamp;
        claimTransaction.cumulativeDebits = new uint256[](2);

        _initEmergencyWithdraw(claimTransaction, msg.sender);
    }

    function emergencyWithdrawAlice() external onlyAlice() {
        _emergencyWithdraw(msg.sender);
    }

    function emergencyWithdrawBobForAlice(address alice) external onlyBob() {
        _emergencyWithdraw(alice);
    }

    function stopEmergencyWithdraw(ClaimRequest calldata req) external {
        ClaimTransaction memory claim = _processClaimRequest(req);

        address alice = req.addresses[ALICE];

        EmergencyWithdrawRequest memory emergencyWithdrawRequest = emergencyWithdrawRequests[alice];

        if (claim.id == emergencyWithdrawRequest.claimTransaction.id && claim.nonce > emergencyWithdrawRequest.claimTransaction.nonce) {
            if (emergencyWithdrawRequest.requester == alice) {
                balances[alice] = 0;
            } else {
                uint256 penalty = balances[alice] * 2;
                balances[alice] += penalty;
            }
            emit StopEmergencyWithdraw(emergencyWithdrawRequest, "Transaction executed on a closed channel.");

            delete emergencyWithdrawRequests[req.addresses[ALICE]];
        }
        else {
            revert("Emergency withdraw request is legal.");
        }
    }

    // Withdraw consensuale
    function withdrawAlice(ClaimRequest calldata req) public onlyAlice() onlyAliceRequest(req) {
        require(req.closed == 1, "'Closed' param is not true.");

        address alice = msg.sender;
        uint cumulativeDebitAlice = req.cumulativeDebits[ALICE];
        uint cumulativeDebitBob = req.cumulativeDebits[BOB];

        verify(req);

        uint balanceToWithdraw = balances[alice] + cumulativeDebitBob - cumulativeDebitAlice;

        ClaimTransaction memory claimTransaction = ClaimTransaction(req.id, req.nonce, req.timestamp, req.cumulativeDebits);

        ClaimTransaction memory last = withdrawTransactions[msg.sender];

        require(last.id < claimTransaction.id, "Invalid channel id.");
        require(last.timestamp < claimTransaction.timestamp, "Invalid timestamp.");
        require(_token.balanceOf(address(this)) >= cumulativeDebitBob, "Balance {Bob} KO.");
        require(balanceToWithdraw > 0, "Cannot withdraw zero amount");

        balances[alice] = 0;

        withdrawTransactions[alice] = claimTransaction;

        _token.transfer(alice, balanceToWithdraw);

        emit WithdrawAlice(claimTransaction);
    }

    function withdrawBob(uint256 amount) external onlyRole(WITHDRAWER_ROLE) {
        require(_token.balanceOf(address(this)) >= amount, "You cannot withdraw this amount.");

        _token.transfer(msg.sender, amount);

        emit WithdrawBob(amount);
    }
}