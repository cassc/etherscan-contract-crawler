// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@1inch/solidity-utils/contracts/libraries/RevertReasonParser.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libs/TokenLibrary.sol";
import "../Errors.sol";
import "./CowKyberExecutor.sol";
import "./CowUniswapV3Executor.sol";

contract CowExecutor is CowKyberExecutor, CowUniswapV3Executor
{
    using TokenLibrary for IERC20;

    error Unauthorized();
    error ReceivedLessThanMinReturn(uint256, uint256);

    address private immutable cowSettlementContract;

    constructor(address _cowSettlementContract) {
        cowSettlementContract = _cowSettlementContract;
    }

    modifier onlyCowSettlementContract() {
        if (msg.sender != cowSettlementContract) {
            revert Unauthorized();
        }
        _;
    }

    function guardedReturnAmountCall(uint256 minReturn, address target, bytes memory data) external payable onlyCowSettlementContract() {
        {
            bool shouldRevert;
            assembly {
                let sig := and(mload(add(data, 0x20)), 0xffffffff00000000000000000000000000000000000000000000000000000000)
                shouldRevert := eq(sig, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            }
            if (shouldRevert) {
                revert TransferFromNotAllowed();
            }
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = target.call{value: msg.value}(data);
        if (!success) {
            string memory reason = RevertReasonParser.parse(
                result,
                "CowEx: "
            );
            revert(reason);
        }

        // decode response as uint256
        uint256 received;
        assembly {
            received := mload(add(result, 0x20))
        }

        if (received < minReturn) {
            revert ReceivedLessThanMinReturn(received, minReturn);
        }
    }

    function guardedUncheckedCall(address target, bytes memory data) external payable onlyCowSettlementContract() {
        {
            bool shouldRevert;
            assembly {
                let sig := and(mload(add(data, 0x20)), 0xffffffff00000000000000000000000000000000000000000000000000000000)
                shouldRevert := eq(sig, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            }
            if (shouldRevert) {
                revert TransferFromNotAllowed();
            }
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = target.call{value: msg.value}(data);
        if (!success) {
            string memory reason = RevertReasonParser.parse(
                result,
                "CowEx: "
            );
            revert(reason);
        }
    }
}