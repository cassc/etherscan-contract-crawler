// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import '@rari-capital/solmate/src/utils/ReentrancyGuard.sol';
import './ozUpgradeableBeacon.sol';
import './StorageBeacon.sol';


/**
 * @title Receiver of an user's ETH transfers (aka THE account)
 * @notice Proxy that users create where they will receive all ETH transfers
 * sent to them, which would be converted to the stablecoin of their choosing.
 */
contract ozAccountProxy is ReentrancyGuard, Initializable, BeaconProxy { 

    bytes dataForL2;

    // event FundsToArb(address indexed sender, uint amount);
    // event EmergencyTriggered(address indexed sender, uint amount); 
    
    constructor(
        address beacon_,
        bytes memory data_
    ) BeaconProxy(beacon_, data_) {}                                    


    receive() external payable override {}


    /// @dev Gets the first version of StorageBeacon
    function _getStorageBeacon() private view returns(StorageBeacon) {
        return StorageBeacon(ozUpgradeableBeacon(_beacon()).storageBeacon(0));
    }

    /// @dev Gelato checker for autonomous calls
    function checker() external view returns(bool canExec, bytes memory execPayload) { 
        uint amountToSend = address(this).balance;
        if (amountToSend > 0) canExec = true;
        execPayload = abi.encodeWithSignature('sendToArb(uint256)', amountToSend); 
    }

  
    /**
     * @notice Forwards payload to the implementation
     * @dev Queries between the authorized selectors. If true, the original calldata is kept in the forwarding.
     * If false, it changes the payload to the account details and forwards that, along L2 gas price. 
     * @param implementation Address of the implementation connected to each account
     */
    function _delegate(address implementation) internal override { 
        bytes memory data; 
        StorageBeacon storageBeacon = _getStorageBeacon();

        if ( storageBeacon.isSelectorAuthorized(bytes4(msg.data)) ) { 
            data = msg.data;
        } else {
            uint amountToSend = abi.decode(msg.data[4:], (uint));

            data = abi.encodeWithSignature(
                'sendToArb(uint256,uint256,address)', 
                storageBeacon.getGasPriceBid(),
                amountToSend,
                address(this)
            );
        }

        assembly {
            let result := delegatecall(gas(), implementation, add(data, 32), mload(data), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}