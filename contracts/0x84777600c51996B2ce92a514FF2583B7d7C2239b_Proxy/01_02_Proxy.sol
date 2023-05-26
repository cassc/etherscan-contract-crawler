// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";

contract Proxy {
    /* =========  MEMBER VARS ========== */
    // Code(Implementation Logic) position in storage is keccak256("implementation.address.slot")-1 = "0xce37950e7cd2678a5aaa22967639b72d05dc378e897c3d84e58abae42ac0f9b6"
    // Admin/Owner position in storage is keccak256("admin.address.slot")-1 = "0x5306ace5707e43e9b5b05781f9c753311b483bee34840818000845c91ad8c543"

    /* ===========   EVENTS  =========== */
    /**
     * @dev Emitted when the _implementation is upgraded.
     */
    event Upgraded(
        address indexed oldImplementation,
        address indexed newImplementation
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /* ========== MODIFIERS ============= */
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address contractLogic) {
        // save the code address
        _upgradeTo(contractLogic);
        _transferOwnership(msg.sender);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @dev fallback
     */
    fallback() external {
        _delegate();
    }

    /**
     * @dev Upgrade function to be only called by owner
     */
    function upgrade(address _newLogic) external onlyOwner {
        _upgradeTo(_newLogic);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Proxy: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev external function to get the current implementation/logic address
     */
    function getImplementationAddress() external view returns (address logic) {
        return _getImplementationAddress();
    }

    /**
     * @dev external function to get the current admin/owner address
     */
    function getOwnerAddress() external view returns (address logic) {
        return _getOwnerAddress();
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address _newLogic) internal {
        require(
            _newLogic != address(0),
            "Proxy:new implementation cannot be zero address"
        );
        require(
            Address.isContract(_newLogic),
            "Proxy:new implementation is not a contract"
        );
        require(
            _getImplementationAddress() != _newLogic,
            "Proxy:new implementation cannot be the same address"
        );

        assembly {
            // solium-disable-line
            sstore(
                0xce37950e7cd2678a5aaa22967639b72d05dc378e897c3d84e58abae42ac0f9b6,
                _newLogic
            )
        }
        emit Upgraded(_getImplementationAddress(), _newLogic);
    }

    /**
     * @dev delegate to implementation logic
     */
    function _delegate() internal {
        assembly {
            // solium-disable-line
            let contractLogic := sload(
                0xce37950e7cd2678a5aaa22967639b72d05dc378e897c3d84e58abae42ac0f9b6
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     * Emits an {OwnershipTransferred} event.
     */
    function _transferOwnership(address _newOwner) internal {
        address oldOwner = _getOwnerAddress();
        assembly {
            // solium-disable-line
            sstore(
                0x5306ace5707e43e9b5b05781f9c753311b483bee34840818000845c91ad8c543,
                _newOwner
            )
        }
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        require(
            _getOwnerAddress() == msg.sender,
            "Proxy: caller is not the owner"
        );
    }

    /**
     * @dev internal function to get the current implementation/logic address
     */
    function _getImplementationAddress() internal view returns (address logic) {
        assembly {
            // solium-disable-line
            logic := sload(
                0xce37950e7cd2678a5aaa22967639b72d05dc378e897c3d84e58abae42ac0f9b6
            )
        }
    }

    /**
     * @dev internal function to get the current admin/owner address
     */
    function _getOwnerAddress() internal view returns (address owner) {
        assembly {
            // solium-disable-line
            owner := sload(
                0x5306ace5707e43e9b5b05781f9c753311b483bee34840818000845c91ad8c543
            )
        }
    }
}