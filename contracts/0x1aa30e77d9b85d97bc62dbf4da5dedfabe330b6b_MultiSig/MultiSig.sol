/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// The ERC-20 interface to allow transferring funds out upon approved withdrawal.
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

// A simple, 100 LoC smart contract acting as a MultiSig wallet.
//
// The contract is initialized with a list of addresses (read-only) which can acts as signers. The only available
// public method records approvals for a withdrawal. Upon the second approval the funds get transferred to the payee.
//
// The contract supports both Ethers and ERC-20 tokens.
contract MultiSig {
    // the total number of signers
    uint private constant SIGNERS_COUNT = 3;
    // the number of signers required to approve a withdrawal
    uint private constant APPROVALS_COUNT = SIGNERS_COUNT / 2 + 1;

    // the array of addresses who are allowed to sign withdrawals
    address payable[SIGNERS_COUNT] private signers;
    // the array of hashes of (amount, payee) approved by corresponding signers
    bytes32[SIGNERS_COUNT] private approvals;

    // Merely initializes the contract by populating signers collection with constructor's argument.
    constructor(address payable[SIGNERS_COUNT] memory _signers) {
        // make sure there are exactly SIGNERS_COUNT signers passed to constructor, revert otherwise
        require(_signers.length == SIGNERS_COUNT, "The contract has to be constructed with exactly 3 signers");
        signers = _signers;
    }

    // The contract accepts incoming Ethers and does not ask any questions :)
    receive() external payable {}

    // Records an approval (verifying it is coming from one of the signers) and immediately
    // transfers funds to the payee if enough approvals exist. Use 0x0 for _token address to approve withdrawals in Ethers,
    // and pass ERC-20 contract address to approve withdrawals of an ERC-20 token.
    function withdraw(address _token, uint _amount, address payable _payee) external {
        uint256 index = getSignerIndex();

        // make sure the transaction sender is one of the signers, revert otherwise
        require(index != type(uint256).max, "withdraw() can only be called by one of signers");

        // compute a fingerprint of the requested withdrawal by hashing token, amount and destination...
        bytes32 hash = keccak256(abi.encodePacked(_token, _amount, _payee));
        // ...and record the approval under the index of current transaction's sender
        approvals[index] = hash;

        // check if there are enough approvals and exit if there are not; proceed with the withdrawal otherwise.
        if (!checkApprovals(hash)) {
            return;
        }

        resetApprovals();

        // check if need to withdraw Ethers or ERC-20 tokens and process the withdrawal
        if (_token == address(0)) {
            _payee.transfer(_amount);
        } else {
            IERC20(_token).transfer(_payee, _amount);
        }
    }

    // Clears all the approvals as if nobody has allowed anything.
    function resetApprovals() private {
        for(uint256 i = 0; i < SIGNERS_COUNT; i++) {
            approvals[i] = bytes32(0);
        }
    }

    // Checks that a specific withdrawal hash has been recorded by APPROVALS_COUNT signers - this would mean
    // enough signers have approved a withdrawal of a specific token to a specific address with a specific amount.
    function checkApprovals(bytes32 hash) private view returns (bool) {
        uint256 matchingApprovals = 0;

        for (uint256 i = 0; i < SIGNERS_COUNT; i++) {
            if (hash == approvals[i]) {
                // there is an approval for the given hash – increment the number of approvals
                matchingApprovals++;
            }
        }

        // return true if and only if the amount of approval recorded exceeds APPROVALS_COUNT
        return matchingApprovals >= APPROVALS_COUNT;
    }

    // Finds the index of the transaction's sender in signers array, returning a uint256(-1) if not found.
    function getSignerIndex() private view returns (uint256) {
        for (uint256 i = 0; i < SIGNERS_COUNT; i++) {
            if (signers[i] == msg.sender) {
                // the current transaction's sender address is present within signers – return the index
                return i;
            }
        }

        // no match – indicate this by returning an invalid index
        return type(uint256).max;
    }
}