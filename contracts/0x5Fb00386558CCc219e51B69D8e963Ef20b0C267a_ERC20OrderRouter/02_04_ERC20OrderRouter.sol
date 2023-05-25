// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import {ETH} from "./constants/Tokens.sol";
import {IGelatoPineCore} from "./interfaces/IGelatoPineCore.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20OrderRouter {
    IGelatoPineCore public immutable gelatoPineCore;

    event DepositToken(
        bytes32 indexed key,
        address indexed caller,
        uint256 amount,
        address module,
        address inputToken,
        address indexed owner,
        address witness,
        bytes data,
        bytes32 secret
    );

    constructor(IGelatoPineCore _gelatoPineCore) {
        gelatoPineCore = _gelatoPineCore;
    }

    // solhint-disable max-line-length
    /** @dev To be backward compatible with old ERC20 Order submission
    * parameters are in format expected by subgraph:
    * https://github.com/gelatodigital/limit-orders-subgraph/blob/7614c138e462577475d240074000c60bad6b76cc/src/handlers/Order.ts#L58
    ERC20 transfer should have an extra data we use to identify a order.
    * A transfer with a order looks like:
    *
    * 0xa9059cbb
    * 000000000000000000000000c8b6046580622eb6037d5ef2ca74faf63dc93631
    * 0000000000000000000000000000000000000000000000000de0b6b3a7640000
    * 0000000000000000000000000000000000000000000000000000000000000060
    * 0000000000000000000000000000000000000000000000000000000000000120
    * 000000000000000000000000ef6c6b0bce4d2060efab0d16736c6ce7473deddc
    * 000000000000000000000000c7ad46e0b8a400bb3c915120d284aafba8fc4735
    * 0000000000000000000000005523f2fc0889a6d46ae686bcd8daa9658cf56496
    * 0000000000000000000000008153f16765f9124d754c432add5bd40f76f057b4
    * 00000000000000000000000000000000000000000000000000000000000000c0
    * 67656c61746f6e6574776f726b2020d83ddc09ea73fa863b164de440a270be31
    * 0000000000000000000000000000000000000000000000000000000000000060
    * 000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    * 00000000000000000000000000000000000000000000000004b1e20ebf83c000
    * 000000000000000000000000842A8Dea50478814e2bFAFF9E5A27DC0D1FdD37c
    *
    * The important part is 67656c61746f6e6574776f726b which is gelato's secret (gelatonetwork in hex)
    * We use that as the index to parse the input data:
    * - module = 5 * 32 bytes before secret index
    * - inputToken = ERC20 which emits the Transfer event
    * - owner = `from` parameter of the Transfer event
    * - witness = 2 * 32 bytes before secret index
    * - secret = 32 bytes from the secret index
    * - data = 2 * 32 bytes after secret index (64 or 96 bytes length). Contains:
    *   - outputToken =  2 * 32 bytes after secret index
    *   - minReturn =  3 * 32 bytes after secret index
    *   - handler =  4 * 32 bytes after secret index (optional)
    *
    */
    // solhint-disable function-max-lines
    function depositToken(
        uint256 _amount,
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes32 _secret
    ) external {
        require(
            _inputToken != ETH,
            "ERC20OrderRouter.depositToken: ONLY_ERC20"
        );

        bytes32 key =
            gelatoPineCore.keyOf(_module, _inputToken, _owner, _witness, _data);

        IERC20(_inputToken).transferFrom(
            msg.sender,
            gelatoPineCore.vaultOfOrder(
                _module,
                _inputToken,
                _owner,
                _witness,
                _data
            ),
            _amount
        );

        emit DepositToken(
            key,
            msg.sender,
            _amount,
            _module,
            _inputToken,
            _owner,
            _witness,
            _data,
            _secret
        );
    }
}