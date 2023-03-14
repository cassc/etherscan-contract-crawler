//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import "../../common/variables.sol";
import "../../../infiniteProxy/IProxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract DSAModule is Variables {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error DSAModule__NotAuth();

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/
    // @notice reverts is msg.sender is not auth.
    modifier onlyAuth() {
        if (IProxy(address(this)).getAdmin() != msg.sender) {
            revert DSAModule__NotAuth();
        }
        _;
    }

    /***********************************|
    |              EVENTS               |
    |__________________________________*/
    // @notice emitted when spell function is called by auth
    event LogDSASpell(
        address indexed to,
        bytes data,
        uint256 value,
        uint256 operation
    );

    // @notice emitted when addDSAAuth function is called by auth
    event LogAddDSAAuthority(address indexed newAuthority);

    /**
     * @dev Admin Spell function
     * @param to_ target address
     * @param calldata_ function calldata
     * @param value_ function msg.value
     * @param operation_ .call or .delegate. (0 => .call, 1 => .delegateCall)
     */
    function spell(
        address to_,
        bytes memory calldata_,
        uint256 value_,
        uint256 operation_
    ) external payable onlyAuth {
        if (operation_ == 0) {
            // .call
            Address.functionCallWithValue(
                to_,
                calldata_,
                value_,
                "spell: .call failed"
            );
        } else if (operation_ == 1) {
            // .delegateCall
            Address.functionDelegateCall(
                to_,
                calldata_,
                "spell: .delegateCall failed"
            );
        } else {
            revert("no operation");
        }
        emit LogDSASpell(to_, calldata_, value_, operation_);
    }

    /**
     * @dev Admin function to add auth on DSA
     * @param auth_ new auth address for DSA
     */
    function addDSAAuth(address auth_) external onlyAuth {
        string[] memory targets_ = new string[](1);
        bytes[] memory calldata_ = new bytes[](1);
        targets_[0] = "AUTHORITY-A";
        calldata_[0] = abi.encodeWithSignature("add(address)", auth_);
        vaultDSA.cast(targets_, calldata_, address(this));

        emit LogAddDSAAuthority(auth_);
    }
}