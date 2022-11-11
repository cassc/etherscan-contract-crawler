pragma solidity ^0.8.15;
import "./Address.sol";
import "../actions/common/Executable.sol";

library ActionAddress {
  using Address for address;

  function execute(address action, bytes memory callData) internal {
    require(isCallingAnExecutable(callData), "OpExecutor: illegal call");
    action.functionDelegateCall(callData, "OpExecutor: low-level delegatecall failed");
  }

  function isCallingAnExecutable(bytes memory callData) private pure returns (bool) {
    bytes4 executeSelector = convertBytesToBytes4(
      abi.encodeWithSelector(Executable.execute.selector)
    );
    bytes4 selector = convertBytesToBytes4(callData);
    return selector == executeSelector;
  }

  function convertBytesToBytes4(bytes memory inBytes) private pure returns (bytes4 outBytes4) {
    if (inBytes.length == 0) {
      return 0x0;
    }

    assembly {
      outBytes4 := mload(add(inBytes, 32))
    }
  }
}