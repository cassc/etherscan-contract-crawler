// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./IDeposit.sol";

// Based on Stakefish and Staked.us contracts.
//
// We don't need fees, but we want truffle & unit tests.
contract BatchDeposit {
    using Address for address payable;
    using SafeMath for uint256;

    uint256 public constant kDepositAmount = 32 ether;
    IDeposit public immutable depositContract_;

    event LogDepositLeftover(address to, uint256 amount);
    event LogDepositSent(bytes pubkey, bytes withdrawal);

    // We pass the address of a contract here because this will change
    // from one environment to another. On mainnet and testnet we use
    // the official addresses:
    //
    // - testnet: 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b (https://goerli.etherscan.io/address/0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b)
    // - zheijang: 0x4242424242424242424242424242424242424242 (https://blockscout.com/eth/zhejiang-testnet/address/0x4242424242424242424242424242424242424242)
    // - mainnet: 0x00000000219ab540356cbb839cbe05303d7705fa (https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa)
    //
    // The migration script handles this.
    constructor (address deposit_contract_address) {
	    depositContract_ = IDeposit(deposit_contract_address);
    }

    function batchDeposit(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external payable {
        require(
            pubkeys.length == withdrawal_credentials.length &&
            pubkeys.length == signatures.length &&
            pubkeys.length == deposit_data_roots.length,
            "#BatchDeposit batchDeposit(): All parameter array's must have the same length."
        );
        require(
            pubkeys.length > 0,
            "#BatchDeposit batchDeposit(): All parameter array's must have a length greater than zero."
        );
        require(
            msg.value >= kDepositAmount.mul(pubkeys.length),
            "#BatchDeposit batchDeposit(): Ether deposited needs to be at least: 32 * (parameter `pubkeys[]` length)."
        );

        uint256 deposited = 0;

        for (uint256 i = 0; i < pubkeys.length; i++) {
            depositContract_.deposit{value: kDepositAmount}(
                pubkeys[i],
                withdrawal_credentials[i],
                signatures[i],
                deposit_data_roots[i]
            );
	    emit LogDepositSent(pubkeys[i], withdrawal_credentials[i]);
            deposited = deposited.add(kDepositAmount);
        }

        assert(deposited == kDepositAmount.mul(pubkeys.length));

        uint256 ethToReturn = msg.value.sub(deposited);
        if (ethToReturn > 0) {
          emit LogDepositLeftover(msg.sender, ethToReturn);
	  Address.sendValue(payable(msg.sender), ethToReturn);
        }
    }
}