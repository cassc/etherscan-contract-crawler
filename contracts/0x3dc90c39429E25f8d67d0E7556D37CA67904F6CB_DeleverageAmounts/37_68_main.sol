//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/variables.sol";
import "../../../../infiniteProxy/IProxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SecurityModule is Variables {
    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(IProxy(address(this)).getAdmin() == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Admin Spell function
     * @param to_ target address
     * @param calldata_ function calldata
     * @param value_ function msg.value
     * @param operation_ .call or .delegate. (0 => .call, 1 => .delegateCall)
     */
    function spell(address to_, bytes memory calldata_, uint256 value_, uint256 operation_) external payable onlyAuth {
        if (operation_ == 0) {
            // .call
            Address.functionCallWithValue(to_, calldata_, value_, "spell: .call failed");
        } else if (operation_ == 1) {
            // .delegateCall
            Address.functionDelegateCall(to_, calldata_, "spell: .delegateCall failed");
        } else {
            revert("no operation");
        }
    }

    /**
     * @dev Admin function to add auth on DSA
     * @param auth_ new auth address for DSA
     */
    function addDSAAuth(address auth_) external onlyAuth {
        string[] memory targets_ = new string[](1);
        bytes[] memory calldata_ = new bytes[](1);
        targets_[0] = "AUTHORITY-A";
        calldata_[0] = abi.encodeWithSignature(
            "add(address)",
            auth_
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
    }
}