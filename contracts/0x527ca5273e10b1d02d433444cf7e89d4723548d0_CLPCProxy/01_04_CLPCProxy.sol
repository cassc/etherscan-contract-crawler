// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./StorageSlot.sol";

contract CLPCProxy is Proxy, Context {
    bytes32 internal constant _OWNER_SLOT =
        bytes32(uint256(keccak256("eip1967.clpcproxy.admin")) - 1);

    bytes32 internal constant _IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.clpcproxy.implementation")) - 1);

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address logicContract) {
        _transferOwnership(_msgSender());
        _setImplementation(logicContract);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (StorageSlot.getAddressSlot(_OWNER_SLOT).value == _msgSender()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = StorageSlot.getAddressSlot(_OWNER_SLOT).value;
        StorageSlot.getAddressSlot(_OWNER_SLOT).value = newOwner;

        emit AdminChanged(oldOwner, newOwner);
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function getImplementation() external view returns (address) {
        return _implementation();
    }

    function proxyOwner() external view returns (address) {
        return StorageSlot.getAddressSlot(_OWNER_SLOT).value;
    }

    function _setImplementation(address newImplementation) private {
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;

        emit Upgraded(_implementation());
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) public onlyOwner {
        _setImplementation(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) public onlyOwner {
        upgradeTo(newImplementation);

        if (data.length > 0 || forceCall) {
            functionDelegateCall(
                newImplementation,
                data,
                "CLPCProxy upgradeToAndCall "
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)

                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}