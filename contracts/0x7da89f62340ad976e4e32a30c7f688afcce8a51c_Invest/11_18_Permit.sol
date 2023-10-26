// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IPermit2} from "../interfaces/IPermit2.sol";

/**
 * @title Permit2 SignatureTransfer functions
 * @author Pino development team
 */
contract Permit {
    IPermit2 public immutable permit2;

    /**
     * @notice Sets permit2 contract address
     * @param _permit2 Permit2 contract address
     */
    constructor(address _permit2) payable {
        permit2 = IPermit2(_permit2);
    }

    /**
     * @notice Transfers 1 token from user to the contract using Permit2
     * @param _permit PermitTransferFrom data struct
     * @param _signature EIP712 Signature of the Permit2 data structure
     */
    function permitTransferFrom(IPermit2.PermitTransferFrom calldata _permit, bytes calldata _signature)
        public
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            IPermit2.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );
    }

    /**
     * @notice Transfers multiple tokens from user to the contract using Permit2
     * @param _permit permitBatchTransferFrom data struct
     * @param _signature EIP712 Signature of the Permit2 data structure
     */
    function permitBatchTransferFrom(IPermit2.PermitBatchTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        uint256 tokensLen = _permit.permitted.length;

        IPermit2.SignatureTransferDetails[] memory details = new IPermit2.SignatureTransferDetails[](tokensLen);

        for (uint256 i = 0; i < tokensLen;) {
            details[i].to = address(this);
            details[i].requestedAmount = _permit.permitted[i].amount;

            unchecked {
                ++i;
            }
        }

        permit2.permitTransferFrom(_permit, details, msg.sender, _signature);
    }
}