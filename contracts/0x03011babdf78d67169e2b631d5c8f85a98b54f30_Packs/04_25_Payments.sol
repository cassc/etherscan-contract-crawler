// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Payments
 * @author David Potolski Lafeta
 * @notice This contract uses PaymentSplitter to split the revenue received from Area 54 Pack sales
 * and royalties received from secondary sales between Ron, Valence, Attribute, and Footlocker.
 */
contract Payments is Ownable, PaymentSplitter {
    // To run tests use this address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    address payable private constant _RON_WALLET =
        payable(0x8e3331BbC9aF9B5fDEAE7e2ea83B207ccf66BC39);
    // To run tests use this address: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
    address payable private constant _VALENCE_WALLET =
        payable(0x0bCF68D00C262814f37b0A3408b18A95262434df);
    // To run tests use this address: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
    address payable private constant _ATTRIBUTE_WALLET =
        payable(0xb21884674AFc615458F5Bb8Da6F40783B52b6Fa8);

    address[] private _payees = [_RON_WALLET, _VALENCE_WALLET, _ATTRIBUTE_WALLET];
    uint256[] private _shares = [40, 40, 20];

    // Address of packs
    address internal immutable _packs;

    constructor(address packContractAddress_) payable PaymentSplitter(_payees, _shares) {
        _packs = packContractAddress_;
    }

    function withdraw() external payable {
        require(
            msg.sender == address(_packs),
            "Only the Packs contract is allowed to call this method"
        );
        for (uint256 i = 0; i < _payees.length; i++) {
            release(payable(payee(i)));
        }
    }
}