pragma solidity ^0.6.2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

contract EnterpriseWalletProxy is Initializable, TransparentUpgradeableProxy {
    event EnterpriseWalletProxyCreated(address indexed contractAddress);

    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address _logic, address _admin, bytes memory _data) public TransparentUpgradeableProxy(_logic, _admin, _data) {
        _setDefaults(_logic, _admin, _data);
    }

    function _setDefaults(address _logic, address _admin, bytes memory _data) initializer public  {
        _setDefaultAdmin(_admin);
        _upgradeTo(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @notice Creates a new minimal proxy contract
     */
    function clone(address _logic, address _admin, bytes memory _data) public returns (EnterpriseWalletProxy newProxy) {
        address cloneAddress = Clones.clone(address(this));
        emit EnterpriseWalletProxyCreated(cloneAddress);
        newProxy = EnterpriseWalletProxy(payable(cloneAddress));
        newProxy._setDefaults(_logic, _admin, _data);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _admin();
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     * parent is private so we need to do this again
     */
    function _setDefaultAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }
}