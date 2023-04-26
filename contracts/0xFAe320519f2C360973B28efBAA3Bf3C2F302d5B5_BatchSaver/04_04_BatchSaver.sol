// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../multivault/interfaces/multivault/IMultiVaultFacetWithdraw.sol";


contract BatchSaver {
    address immutable public multivault;

    constructor(
        address _multivault
    ) {
        multivault = _multivault;
    }

    event WithdrawalAlreadyUsed(bytes32 indexed withdrawalId);
    event WithdrawalSaved(bytes32 indexed withdrawalId);

    struct Withdraw {
        bool isNative;
        bytes payload;
        bytes[] signatures;
    }

    function checkWithdrawalAlreadySeen(bytes32 withdrawalId) public view returns (bool) {
        return IMultiVaultFacetWithdraw(multivault).withdrawalIds(withdrawalId);
    }

    function saveWithdrawals(
        Withdraw[] memory withdrawals
    ) external {
        for (uint i = 0; i < withdrawals.length; i++) {
            Withdraw memory withdraw = withdrawals[i];

            bytes32 withdrawalId = keccak256(withdraw.payload);

            if (checkWithdrawalAlreadySeen(withdrawalId)) {
                emit WithdrawalAlreadyUsed(withdrawalId);

                continue;
            }

            if (withdraw.isNative) {
                IMultiVaultFacetWithdraw(multivault).saveWithdrawNative(
                    withdraw.payload,
                    withdraw.signatures
                );
            } else {
                IMultiVaultFacetWithdraw(multivault).saveWithdrawAlien(
                    withdraw.payload,
                    withdraw.signatures
                );
            }

            emit WithdrawalSaved(withdrawalId);
        }
    }
}