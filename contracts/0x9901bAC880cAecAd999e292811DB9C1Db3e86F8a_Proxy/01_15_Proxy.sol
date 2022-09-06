// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IProxy.sol";
import "./interface/IRegistry.sol";
import "./interface/IFeeRuleRegistry.sol";
import "./Config.sol";
import "./Storage.sol";
import "./lib/LibParam.sol";
import "./lib/LibFeeStorage.sol";

/**
 * @title The entrance of Furucombo
 * @author Ben Huang
 */
contract Proxy is IProxy, Storage, Config {
    using Address for address;
    using SafeERC20 for IERC20;
    using LibParam for bytes32;
    using LibStack for bytes32[];
    using Strings for uint256;
    using LibFeeStorage for mapping(bytes32 => bytes32);

    event LogBegin(
        address indexed handler,
        bytes4 indexed selector,
        bytes payload
    );
    event LogEnd(
        address indexed handler,
        bytes4 indexed selector,
        bytes result
    );
    event ChargeFee(address indexed tokenIn, uint256 feeAmount);

    modifier isNotBanned() {
        require(registry.bannedAgents(address(this)) == 0, "Banned");
        _;
    }

    modifier isNotHalted() {
        require(registry.fHalt() == false, "Halted");
        _;
    }

    address private constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IRegistry public immutable registry;
    IFeeRuleRegistry public immutable feeRuleRegistry;

    constructor(address registry_, address feeRuleRegistry_) {
        registry = IRegistry(registry_);
        feeRuleRegistry = IFeeRuleRegistry(feeRuleRegistry_);
    }

    /**
     * @notice Direct transfer from EOA should be reverted.
     * @dev Callback function will be handled here.
     */
    fallback() external payable isNotHalted isNotBanned isInitialized {
        // If triggered by a function call, caller should be registered in
        // registry.
        // The function call will then be forwarded to the location registered
        // in registry.
        require(_isValidCaller(msg.sender), "Invalid caller");

        address target = address(bytes20(registry.callers(msg.sender)));
        bytes memory result = _exec(target, msg.data, type(uint256).max);

        // return result for aave v2 flashloan()
        uint256 size = result.length;
        assembly {
            let loc := add(result, 0x20)
            return(loc, size)
        }
    }

    /**
     * @notice Direct transfer from EOA should be reverted.
     */
    receive() external payable {
        require(Address.isContract(msg.sender), "Not allowed from EOA");
    }

    /**
     * @notice Combo execution function. Including three phases: pre-process,
     * exection and post-process.
     * @param tos The handlers of combo.
     * @param configs The configurations of executing cubes.
     * @param datas The combo datas.
     * @param ruleIndexes The indexes of rules.
     */
    function batchExec(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] memory datas,
        uint256[] calldata ruleIndexes
    ) external payable override isNotHalted isNotBanned {
        _preProcess(ruleIndexes);
        _execs(tos, configs, datas);
        _postProcess();
    }

    /**
     * @notice The execution interface for callback function to be executed.
     * @dev This function can only be called through the handler, which makes
     * the caller become proxy itself.
     */
    function execs(
        address[] calldata tos,
        bytes32[] calldata configs,
        bytes[] memory datas
    ) external payable override isNotHalted isNotBanned isInitialized {
        require(msg.sender == address(this), "Does not allow external calls");
        _execs(tos, configs, datas);
    }

    /**
     * @notice The execution phase.
     * @param tos The handlers of combo.
     * @param configs The configurations of executing cubes.
     * @param datas The combo datas.
     */
    function _execs(
        address[] memory tos,
        bytes32[] memory configs,
        bytes[] memory datas
    ) internal {
        bytes32[256] memory localStack;
        uint256 index;
        uint256 counter;

        require(
            tos.length == datas.length,
            "Tos and datas length inconsistent"
        );
        require(
            tos.length == configs.length,
            "Tos and configs length inconsistent"
        );
        for (uint256 i = 0; i < tos.length; i++) {
            address to = tos[i];
            bytes32 config = configs[i];
            bytes memory data = datas[i];
            // Check if the data contains dynamic parameter
            if (!config.isStatic()) {
                // If so, trim the exectution data base on the configuration and stack content
                _trim(data, config, localStack, index);
            }
            // Emit the execution log before call
            bytes4 selector = _getSelector(data);
            emit LogBegin(to, selector, data);

            // Check if the output will be referenced afterwards
            bytes memory result = _exec(to, data, counter);
            counter++;

            // Emit the execution log after call
            emit LogEnd(to, selector, result);

            if (config.isReferenced()) {
                // If so, parse the output and place it into local stack
                uint256 num = config.getReturnNum();
                uint256 newIndex = _parse(localStack, result, index);
                require(
                    newIndex == index + num,
                    "Return num and parsed return num not matched"
                );
                index = newIndex;
            }

            // Setup the process to be triggered in the post-process phase
            _setPostProcess(to);
        }
    }

    /**
     * @notice Trimming the execution data.
     * @param data The execution data.
     * @param config The configuration.
     * @param localStack The stack the be referenced.
     * @param index Current element count of localStack.
     */
    function _trim(
        bytes memory data,
        bytes32 config,
        bytes32[256] memory localStack,
        uint256 index
    ) internal pure {
        // Fetch the parameter configuration from config
        (uint256[] memory refs, uint256[] memory params) = config.getParams();
        // Trim the data with the reference and parameters
        for (uint256 i = 0; i < refs.length; i++) {
            require(refs[i] < index, "Reference to out of localStack");
            bytes32 ref = localStack[refs[i]];
            uint256 offset = params[i];
            uint256 base = PERCENTAGE_BASE;
            assembly {
                let loc := add(add(data, 0x20), offset)
                let m := mload(loc)
                // Adjust the value by multiplier if a dynamic parameter is not zero
                if iszero(iszero(m)) {
                    // Assert no overflow first
                    let p := mul(m, ref)
                    if iszero(eq(div(p, m), ref)) {
                        revert(0, 0)
                    } // require(p / m == ref)
                    ref := div(p, base)
                }
                mstore(loc, ref)
            }
        }
    }

    /**
     * @notice Parse the return data to the local stack.
     * @param localStack The local stack to place the return values.
     * @param ret The return data.
     * @param index The current tail.
     */
    function _parse(
        bytes32[256] memory localStack,
        bytes memory ret,
        uint256 index
    ) internal pure returns (uint256 newIndex) {
        uint256 len = ret.length;
        // The return value should be multiple of 32-bytes to be parsed.
        require(len % 32 == 0, "illegal length for _parse");
        // Estimate the tail after the process.
        newIndex = index + len / 32;
        require(newIndex <= 256, "stack overflow");
        assembly {
            let offset := shl(5, index)
            // Store the data into localStack
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 0x20)
            } {
                mstore(
                    add(localStack, add(i, offset)),
                    mload(add(add(ret, i), 0x20))
                )
            }
        }
    }

    /**
     * @notice The execution of a single cube.
     * @param to_ The handler of cube.
     * @param data_ The cube execution data.
     * @param counter_ The current counter of the cube.
     */
    function _exec(
        address to_,
        bytes memory data_,
        uint256 counter_
    ) internal returns (bytes memory result) {
        require(_isValidHandler(to_), "Invalid handler");
        bool success;
        assembly {
            success := delegatecall(
                sub(gas(), 5000),
                to_,
                add(data_, 0x20),
                mload(data_),
                0,
                0
            )
            let size := returndatasize()

            result := mload(0x40)
            mstore(
                0x40,
                add(result, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(result, size)
            returndatacopy(add(result, 0x20), 0, size)
        }

        if (!success) {
            if (result.length < 68) revert("_exec");
            assembly {
                result := add(result, 0x04)
            }

            if (counter_ == type(uint256).max) {
                revert(abi.decode(result, (string))); // Don't prepend counter
            } else {
                revert(
                    string(
                        abi.encodePacked(
                            counter_.toString(),
                            "_",
                            abi.decode(result, (string))
                        )
                    )
                );
            }
        }
    }

    /**
     * @notice Setup the post-process.
     * @param to_ The handler of post-process.
     */
    function _setPostProcess(address to_) internal {
        // If the stack length equals 0, just skip
        // If the top is a custom post-process, replace it with the handler
        // address.
        if (stack.length == 0) {
            return;
        } else if (
            stack.peek() == bytes32(bytes12(uint96(HandlerType.Custom))) &&
            bytes4(stack.peek(1)) != 0x00000000
        ) {
            stack.pop();
            stack.setAddress(to_);
            stack.setHandlerType(HandlerType.Custom);
        }
    }

    /// @notice The pre-process phase.
    function _preProcess(uint256[] memory ruleIndexes_)
        internal
        virtual
        isStackEmpty
    {
        // Set the sender.
        _setSender();
        // Set the fee collector
        cache._setFeeCollector(feeRuleRegistry.feeCollector());

        // Calculate fee
        uint256 feeRate =
            feeRuleRegistry.calFeeRateMulti(_getSender(), ruleIndexes_);
        require(feeRate <= PERCENTAGE_BASE, "fee rate out of range");
        cache._setFeeRate(feeRate);
        if (msg.value > 0 && feeRate > 0) {
            // Process ether fee
            uint256 feeEth = _calFee(msg.value, feeRate);

            // It will fail if fee collector is gnosis contract, because .transfer() will only consume 2300 gas limit.
            // Replacing .transfer() with .call('') to avoid out of gas
            address collector = cache._getFeeCollector();
            (bool success, ) = collector.call{value: feeEth}("");
            require(success, "Send fee to collector failed");
            emit ChargeFee(NATIVE_TOKEN, feeEth);
        }
    }

    /// @notice The post-process phase.
    function _postProcess() internal {
        // Handler type will be parsed at the beginning. Will send the token back to
        // user if the handler type is "Token". Will get the handler address and
        // execute the customized post-process if handler type is "Custom".
        while (stack.length > 0) {
            bytes32 top = stack.get();
            // Get handler type
            HandlerType handlerType = HandlerType(uint96(bytes12(top)));
            if (handlerType == HandlerType.Token) {
                address addr = address(uint160(uint256(top)));
                uint256 tokenAmount = IERC20(addr).balanceOf(address(this));
                if (tokenAmount > 0)
                    IERC20(addr).safeTransfer(msg.sender, tokenAmount);
            } else if (handlerType == HandlerType.Custom) {
                address addr = stack.getAddress();
                _exec(
                    addr,
                    abi.encodeWithSelector(POSTPROCESS_SIG),
                    type(uint256).max
                );
            } else {
                revert("Invalid handler type");
            }
        }

        // Balance should also be returned to user
        uint256 amount = address(this).balance;
        if (amount > 0) payable(msg.sender).transfer(amount);
        // Reset cached datas
        cache._resetFeeCollector();
        cache._resetFeeRate();
        _resetSender();
    }

    /// @notice Check if the handler is valid in registry.
    function _isValidHandler(address handler) internal view returns (bool) {
        return registry.isValidHandler(handler);
    }

    /// @notice Check if the caller is valid in registry.
    function _isValidCaller(address caller) internal view returns (bool) {
        return registry.isValidCaller(caller);
    }

    /// @notice Get payload function selector.
    function _getSelector(bytes memory payload)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            payload[0] |
            (bytes4(payload[1]) >> 8) |
            (bytes4(payload[2]) >> 16) |
            (bytes4(payload[3]) >> 24);
    }

    function _calFee(uint256 amount, uint256 feeRate)
        internal
        pure
        returns (uint256)
    {
        return (amount * feeRate) / PERCENTAGE_BASE;
    }
}