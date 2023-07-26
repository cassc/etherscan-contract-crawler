// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import "./ERC20PresetMinterPauserV300.sol";
import { IInbox, IBridge, IOutbox } from "./IArbitrum.sol";
import { MCB } from "./MCB.sol";

/**
 * @dev MCB token v2.0.0
 */
contract EthMCBv2 is MCB {
    using Address for address;

    address public inbox;
    address public gateway;
    address public l2Token;

    event RegisterTokenOnL2(
        address indexed gateway,
        address indexed l2Token,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    );
    event SetGateway(
        address indexed gateway,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    );
    event EscrowMint(address indexed minter, uint256 amount);

    function migrateToArb(
        address inbox_,
        address gateway_,
        address gatewayRouter_,
        address l2Token_,
        uint256 maxSubmissionCost1,
        uint256 maxSubmissionCost2,
        uint256 maxGas,
        uint256 gasPriceBid
    ) external payable {
        require(inbox == address(0), "already migrated");
        require(gateway == address(0), "already migrated");
        require(l2Token == address(0), "already migrated");
        require(inbox_.isContract(), "inbox must be contract");
        require(gateway_.isContract(), "gateway must be contract");
        require(gatewayRouter_.isContract(), "gatewayRouter must be contract");
        require(l2Token_ != address(0), "l1Token must be non-zero address");

        inbox = inbox_;
        gateway = gateway_;
        l2Token = l2Token_;

        uint256 gas1 = maxSubmissionCost1 + maxGas * gasPriceBid;
        uint256 gas2 = maxSubmissionCost2 + maxGas * gasPriceBid;
        require(msg.value == gas1 + gas2, "overpay");

        // register token address to paring with arb-token.
        {
            bytes memory functionCallData = abi.encodeWithSignature(
                "registerTokenToL2(address,uint256,uint256,uint256)",
                l2Token,
                maxGas,
                gasPriceBid,
                maxSubmissionCost1
            );
            _functionCallWithValue(
                gateway,
                functionCallData,
                gas1,
                "call registerTokenToL2 failed"
            );
            emit RegisterTokenOnL2(
                gateway,
                l2Token,
                maxGas,
                gasPriceBid,
                maxSubmissionCost1
            );
        }

        // register token to gateway.
        {
            bytes memory functionCallData = abi.encodeWithSignature(
                "setGateway(address,uint256,uint256,uint256)",
                gateway,
                maxGas,
                gasPriceBid,
                maxSubmissionCost2
            );
            _functionCallWithValue(
                gatewayRouter_,
                functionCallData,
                gas2,
                "call setGateway failed"
            );
            emit SetGateway(gateway, maxGas, gasPriceBid, maxSubmissionCost2);
        }
    }

    function migrateToArb2(address inbox_) external {
        require(inbox == address(0), "already migrated");
        inbox = inbox_;
    }

    /**
     * @notice Mint tokens to gateway, so that tokens minted from L2 will be able to withdraw from arb->eth.
     */
    function escrowMint(uint256 amount) external virtual {
        address msgSender = _l2Sender();
        require(msgSender == l2Token, "sender must be l2 token");
        _mint(gateway, amount);
        emit EscrowMint(msgSender, amount);
    }

    function _l2Sender() internal view virtual returns (address) {
        IBridge bridge = IInbox(inbox).bridge();
        require(address(bridge) != address(0), "bridge is zero address");
        IOutbox outbox = IOutbox(bridge.activeOutbox());
        require(address(outbox) != address(0), "outbox is zero address");
        return outbox.l2ToL1Sender();
    }

    function proposal19() public virtual override {
        revert("removed");
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "insufficient balance for call"
        );
        require(target.isContract(), "call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20PresetMinterPauserUpgradeSafe) {
        super._beforeTokenTransfer(from, to, amount);

        // proposal 2023-07-17: reject anyMCB
        require(
            from != 0xd1a891E6eCcB7471Ebd6Bc352F57150d4365dB21 &&
                to != 0xd1a891E6eCcB7471Ebd6Bc352F57150d4365dB21,
            "anyMCB"
        );
    }

    uint256[50] private __gap;
}