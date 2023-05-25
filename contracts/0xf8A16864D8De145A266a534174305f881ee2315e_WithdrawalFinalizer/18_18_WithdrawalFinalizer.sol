pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0



import "@matterlabs/zksync-contracts/l1/contracts/bridge/interfaces/IL1Bridge.sol";
import "@matterlabs/zksync-contracts/l1/contracts/zksync/interfaces/IMailbox.sol";
import "@matterlabs/zksync-contracts/l1/contracts/common/libraries/UncheckedMath.sol";


contract WithdrawalFinalizer {
    using UncheckedMath for uint256;
    IMailbox constant ZKSYNC_MAILBOX = IMailbox(0x32400084C286CF3E17e7B677ea9583e60a000324);
    IL1Bridge constant ERC20_BRIDGE = IL1Bridge(0x57891966931Eb4Bb6FB81430E6cE0A03AAbDe063);

    struct RequestFinalizeWithdrawal {
        uint256 _l2BlockNumber;
        uint256 _l2MessageIndex;
        uint16 _l2TxNumberInBlock;
        bytes _message;
        bytes32[] _merkleProof;
        bool _isEth;
        uint256 _gas;
    }

    struct Result {
        uint256 _l2BlockNumber;
        uint256 _l2MessageIndex;
        uint256 _gas;
        bool success;
    }

    function finalizeWithdrawals(
        RequestFinalizeWithdrawal[] calldata requests
    ) external returns (Result[] memory) {
        uint256 requestsLength = requests.length;
        Result[] memory results = new Result[](requestsLength);
        for (uint256 i = 0; i < requestsLength; i = i.uncheckedInc()) {
            require(gasleft() >= ((requests[i]._gas * 64) / 63) + 500, "i");
            uint256 gasBefore = gasleft();
            if (requests[i]._isEth) {
                try
                    ZKSYNC_MAILBOX.finalizeEthWithdrawal{gas: requests[i]._gas}(
                        requests[i]._l2BlockNumber,
                        requests[i]._l2MessageIndex,
                        requests[i]._l2TxNumberInBlock,
                        requests[i]._message,
                        requests[i]._merkleProof
                    )
                {
                    results[i] = Result({
                        _l2BlockNumber: requests[i]._l2BlockNumber,
                        _l2MessageIndex: requests[i]._l2MessageIndex,
                        _gas: gasBefore - gasleft(),
                        success: true
                    });
                } catch {
                    results[i] = Result({
                        _l2BlockNumber: requests[i]._l2BlockNumber,
                        _l2MessageIndex: requests[i]._l2MessageIndex,
                        _gas: 0,
                        success: false
                    });
                }
            } else {
                try
                    ERC20_BRIDGE.finalizeWithdrawal{gas: requests[i]._gas}(
                        requests[i]._l2BlockNumber,
                        requests[i]._l2MessageIndex,
                        requests[i]._l2TxNumberInBlock,
                        requests[i]._message,
                        requests[i]._merkleProof
                    )
                {
                    results[i] = Result({
                        _l2BlockNumber: requests[i]._l2BlockNumber,
                        _l2MessageIndex: requests[i]._l2MessageIndex,
                        _gas: gasBefore - gasleft(),
                        success: true
                    });
                } catch {
                    results[i] = Result({
                        _l2BlockNumber: requests[i]._l2BlockNumber,
                        _l2MessageIndex: requests[i]._l2MessageIndex,
                        _gas: 0,
                        success: false
                    });
                }
            }
        }
        return results;
    }
}