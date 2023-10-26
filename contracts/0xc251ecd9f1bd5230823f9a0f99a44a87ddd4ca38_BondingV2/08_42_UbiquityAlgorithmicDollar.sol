// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./interfaces/IIncentive.sol";
import "./ERC20Ubiquity.sol";

contract UbiquityAlgorithmicDollar is ERC20Ubiquity {
    /// @notice get associated incentive contract, 0 address if N/A
    mapping(address => address) public incentiveContract;

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    constructor(address _manager)
        ERC20Ubiquity(_manager, "Ubiquity Algorithmic Dollar", "uAD")
    {} // solhint-disable-line no-empty-blocks

    /// @param account the account to incentivize
    /// @param incentive the associated incentive contract
    /// @notice only UAD manager can set Incentive contract
    function setIncentiveContract(address account, address incentive) external {
        require(
            ERC20Ubiquity.manager.hasRole(
                ERC20Ubiquity.manager.UBQ_TOKEN_MANAGER_ROLE(),
                msg.sender
            ),
            "Dollar: must have admin role"
        );

        incentiveContract[account] = incentive;
        emit IncentiveContractUpdate(account, incentive);
    }

    function _checkAndApplyIncentives(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        // incentive on sender
        address senderIncentive = incentiveContract[sender];
        if (senderIncentive != address(0)) {
            IIncentive(senderIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }

        // incentive on recipient
        address recipientIncentive = incentiveContract[recipient];
        if (recipientIncentive != address(0)) {
            IIncentive(recipientIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }

        // incentive on operator
        address operatorIncentive = incentiveContract[msg.sender];
        if (
            msg.sender != sender &&
            msg.sender != recipient &&
            operatorIncentive != address(0)
        ) {
            IIncentive(operatorIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }

        // all incentive, if active applies to every transfer
        address allIncentive = incentiveContract[address(0)];
        if (allIncentive != address(0)) {
            IIncentive(allIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super._transfer(sender, recipient, amount);
        _checkAndApplyIncentives(sender, recipient, amount);
    }
}