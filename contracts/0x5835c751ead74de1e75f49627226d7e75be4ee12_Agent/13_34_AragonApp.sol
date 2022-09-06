pragma solidity 0.4.24;

import "contracts/lib/AppStorage.sol";
import "contracts/lib/Autopetrified.sol";
import "contracts/lib/VaultRecoverable.sol";
import "contracts/lib/ReentrancyGuard.sol";
import "contracts/lib/EVMScriptRunner.sol";
import "contracts/lib/ACLSyntaxSugar.sol";
import "contracts/lib/ConversionHelpers.sol";

contract AragonApp is
    AppStorage,
    Autopetrified,
    VaultRecoverable,
    ReentrancyGuard,
    EVMScriptRunner,
    ACLSyntaxSugar
{
    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    modifier auth(bytes32 _role) {
        require(
            canPerform(msg.sender, _role, new uint256[](0)),
            ERROR_AUTH_FAILED
        );
        _;
    }

    modifier authP(bytes32 _role, uint256[] _params) {
        require(canPerform(msg.sender, _role, _params), ERROR_AUTH_FAILED);
        _;
    }

    /**
     * @dev Check whether an action can be performed by a sender for a particular role on this app
     * @param _sender Sender of the call
     * @param _role Role on this app
     * @param _params Permission params for the role
     * @return Boolean indicating whether the sender has the permissions to perform the action.
     *         Always returns false if the app hasn't been initialized yet.
     */
    function canPerform(
        address _sender,
        bytes32 _role,
        uint256[] _params
    ) public view returns (bool) {
        if (!hasInitialized()) {
            return false;
        }

        IKernel linkedKernel = kernel();
        if (address(linkedKernel) == address(0)) {
            return false;
        }

        return
            linkedKernel.hasPermission(
                _sender,
                address(this),
                _role,
                ConversionHelpers.dangerouslyCastUintArrayToBytes(_params)
            );
    }

    /**
     * @dev Get the recovery vault for the app
     * @return Recovery vault address for the app
     */
    function getRecoveryVault() public view returns (address) {
        // Funds recovery via a vault is only available when used with a kernel
        return kernel().getRecoveryVault(); // if kernel is not set, it will revert
    }
}