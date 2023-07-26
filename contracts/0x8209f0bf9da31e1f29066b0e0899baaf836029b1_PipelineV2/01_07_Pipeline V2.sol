pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PipelineV2 is Ownable {
    using SafeERC20 for IERC20;

    struct Action {
        // Hash of action type name
        bytes32 actionType;
        // Encoded struct of type actionType 
        bytes actionData;
    }

    // Action for transfer tokens from user to PipelineV2
    struct TransferToPipelineAction {
        // Token address
        address token;
        // Amount of tokens
        uint256 amount;
    }

    // Action for simple action call
    struct ContractCallAction {
        // Contract to call
        address target;
        // Amount of ethereum to pass
        uint256 ethValue;
        // Calldata for call
        bytes callData;
    }

    // Action for injection call. Calldata will be modified, according to slotPoss and injPoss 
    struct ContractCallWithInjAction {
        // Contract to call
        address target;
        // Amount of ethereum to pass
        uint256 ethValue;
        // Stack slots, that will be used as data for injection
        uint256[] slotPoss;
        // Positions of calldata where slotPoss[i] should be injected
        uint256[][] injPoss;
        // Initial calldata
        bytes callData;
    }

    // TODO opeartions with slots

    // Create portion
    struct PortionAction {
        // Inital slot
        uint256 slot;
        // numerator
        uint256 num;
        // denominator
        uint256 denom;
    }

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bytes32 constant TRANSFER_TO_PIPELINE = keccak256("TRANSFER_TO_PIPELINE"); // 1bb1878b6670fa7206eebc9cb11ef07f8feee71bfdc1ad1fd7591912384522f7
    bytes32 constant INJ_CONTRACT_CALL = keccak256("INJ_CONTRACT_CALL"); // e46b02ffe1dea4964e76d441936eed7baa80e377f1c03f2285cfecf8b9d67206
    bytes32 constant CONTRACT_CALL = keccak256("CONTRACT_CALL"); // d8707188b9da729f25dc8515ec1fbf7041db645a531c7f87fc701ac78ecc9f1f
    bytes32 constant INJECT_ACTION = keccak256("INJECT_ACTION"); // 3deffeff28f6ec21f4dbd8d6adb044acf075dcdf02fb5607b421c9674a6d72ad
    bytes32 constant GET_PORTION = keccak256("GET_PORTION"); // 226682f29272344a1f04d9556c5380a1e659b7c4265f62f5f608cb7591dd3ac9

    /// @dev Runs actions, stores output on stack(only bytes32 values)
    /// @param actions List of actions to run
    /// @param tokenOut Token address, for balance check 
    /// @param minOutAmount Min amount of <tokenOut> token return
    function run(Action[] calldata actions, address tokenOut, uint256 minOutAmount) payable external {
        // #TODO len(actions) == slotsAmount?

        uint256 balanceBefore;
        if (minOutAmount > 0) {
            balanceBefore = _getBalance(tokenOut, msg.sender);
        }
        bytes32[] memory slots = new bytes32[](actions.length);
        uint256 lastSlot;

        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i].actionType == TRANSFER_TO_PIPELINE) {
                slots[lastSlot] = _transferToPipeline(abi.decode(actions[i].actionData, (TransferToPipelineAction)));
                lastSlot++;
                continue;
            }

            if (actions[i].actionType == CONTRACT_CALL) {
                slots[lastSlot] = _contractCall(abi.decode(actions[i].actionData, (ContractCallAction)));
                lastSlot++;
                continue;
            }

            if (actions[i].actionType == INJ_CONTRACT_CALL) {
                slots[lastSlot] = _injContractCall(slots, abi.decode(actions[i].actionData, (ContractCallWithInjAction)));
                lastSlot++;
                continue;
            }

            if (actions[i].actionType == GET_PORTION) {
                slots[lastSlot] = _getPortion(slots, abi.decode(actions[i].actionData, (PortionAction)));
                lastSlot++;
                continue;
            }

            require(false, "Wrong action type");
        }

        if(minOutAmount > 0) {
            uint256 balanceDiff = _getBalance(tokenOut, msg.sender) - balanceBefore;
            require(balanceDiff >= minOutAmount, "Not enought token gained");
        }
    }

    /// @dev Transfers token from user to Pipeline
    function _transferToPipeline(TransferToPipelineAction memory data) internal returns(bytes32) {
        // TODO should we have distinct action for this?
        IERC20(data.token).safeTransferFrom(msg.sender, address(this), data.amount);
        return bytes32(IERC20(data.token).balanceOf(address(this)));
    }

    /// @dev Simple contract call
    function _contractCall(ContractCallAction memory data) internal returns(bytes32) {
        return _contractCall(data.target, data.ethValue, data.callData);
    }

    function _contractCall(address target, uint256 ethValue, bytes memory callData) internal returns(bytes32) {
        _checkIfCallDataSafe(callData);
        require(_isContract(target), "Target is not a contract");

        (bool success, bytes memory res) = target.call{value: ethValue}(callData);

        require(success, "Can't call contract");

        return bytes32(res);
    }

    /// @dev Contract call with injections of stored data to calldata
    function _injContractCall(bytes32[] memory slots, ContractCallWithInjAction memory data) internal returns(bytes32) {
        require(data.slotPoss.length == data.injPoss.length, "Wrong params");

        // Injection phase
        for (uint256 i = 0; i < data.slotPoss.length; i++) {
            bytes32 injection = slots[data.slotPoss[i]];
            for (uint256 j = 0; j < data.injPoss[i].length; j++) {
                uint256 injPos = data.injPoss[i][j];

                uint256 callDataPos = _getBytesMemoryPos(data.callData);
                uint256 absoluteInjPoss = 32 + callDataPos + injPos;
                uint256 lastAccesibleSlot = callDataPos + data.callData.length; // callDataPoss + data.callData.length + 32(callDatalength) - 32(last slot offset)

                require(absoluteInjPoss <= lastAccesibleSlot, "Can't inject in that position");

                _inject(absoluteInjPoss, injection);
            }
        }

        return _contractCall(data.target, data.ethValue, data.callData);
    }

    /// @dev Get portion of stored slot
    function _getPortion(bytes32[] memory slots, PortionAction memory data) internal returns(bytes32) {
        return bytes32(uint256(slots[data.slot]) * data.num / data.denom);
    }

    /// @dev Gets location of bytes memory
    function _getBytesMemoryPos(bytes memory b) internal returns(uint256 pos) {
        assembly {
            pos := b
        }
    }

    /// @dev Sets memory data at <pos>
    function _inject(uint256 pos, bytes32 value) internal {
        assembly {
            mstore(pos, value)
        }
    }

    /// @dev Check if contract call is not transferFrom
    function _checkIfCallDataSafe(bytes memory callData) internal {
        bytes4 sig = bytes4(callData);

        require(sig != IERC20.transferFrom.selector, "Unsafe call"); 
    }

    /// @dev Check if address is contract
    function _isContract(address addr) internal returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /// @dev Get balance of token or eth
    function _getBalance(address token, address account) internal returns(uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    receive() external payable {}
}