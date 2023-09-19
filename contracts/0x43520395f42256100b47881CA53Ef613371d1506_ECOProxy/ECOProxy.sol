/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

/*

 ______     __   __     ______     __  __    
/\  ___\   /\ "-.\ \   /\  ___\   /\_\_\_\   
\ \  __\   \ \ \-.  \  \ \ \____  \/_/\_\/_  
 \ \_____\  \ \_\\"\_\  \ \_____\   /\_\/\_\ 
  \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/ 
                                             
EnrichX offers decentralized options trading, empowering you to trade, mint, and exercise crypto options with ease.

🛠️ Flash Exercise: Power in Your Hands
🛠️ ERC-20 Standard: Fungibility and Integration
🛠️ Non-Custodial: Your Assets, Your Control
🛠️ Counterparty Risk Eliminated

🛠️ Website: https://www.enrichx.co/
🛠️ Medium: https://enrichx.medium.com/
🛠️ Community: https://t.me/EnrichX
🛠️ Twitter: https://twitter.com/EnrichXFi

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// Contract on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title ECOProxy
 * @dev A proxy contract that implements delegation of calls to other contracts.
 */
contract ECOProxy {
    
    /**
     * @dev Emitted when the admin address has been changed.
     * @param previousAdmin Address of the previous admin.
     * @param newAdmin Address of the new admin.
     */
    event ProxyAdminUpdated(address previousAdmin, address newAdmin);
    
    /**
     * @dev Emitted when the proxy implementation has been changed.
     * @param previousImplementation Address of the previous proxy implementation.
     * @param newImplementation Address of the new proxy implementation.
     */
    event SetImplementation(address previousImplementation, address newImplementation);
    
    /**
     * @dev Storage position for the admin address.
     */
    bytes32 private constant adminPosition = keccak256("ecoproxy.admin");
    
    /**
     * @dev Storage position for the proxy implementation address.
     */
    bytes32 private constant implementationPosition = keccak256("ecoproxy.implementation");

    /**
     * @dev Modifier to check if the `msg.sender` is the admin.
     * Only admin address can execute.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin(), "ECOProxy::onlyAdmin");
        _;
    }
    
    receive() external payable {}

    constructor() {
        _setAdmin(msg.sender);
    }

    /**
     * @dev Fallback function that delegates the execution to the proxy implementation contract.
     */
    fallback() external payable {
        address addr = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    

    /**
     * @dev Function to set the proxy implementation address.
     * Only can be called by the proxy admin.
     * @param newImplementation Address of the new proxy implementation.
     * @param initData ABI encoded with signature data that will be delegated over the new implementation.
     */
    function setImplementation(address newImplementation, bytes calldata initData) external onlyAdmin {
        _setImplementation(newImplementation, initData);
    }

    /**
     * @dev Internal function to set the proxy admin address.
     * @param newAdmin Address of the new proxy admin.
     */
    function _setAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "ECOProxy::_setAdmin: Invalid admin");
        
        emit ProxyAdminUpdated(admin(), newAdmin);
        
        bytes32 position = adminPosition;
        assembly {
            sstore(position, newAdmin)
        }
    }
    
    /**
     * @dev Internal function to set the proxy implementation address.
     * The implementation address must be a contract.
     * @param newImplementation Address of the new proxy implementation.
     * @param initData ABI encoded with signature data that will be delegated over the new implementation.
     */
    function _setImplementation(address newImplementation, bytes memory initData) internal {
        require(Address.isContract(newImplementation), "ECOProxy::_setImplementation: Invalid implementation");
        
        emit SetImplementation(implementation(), newImplementation);
        
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, newImplementation)
        }
        if (initData.length > 0) {
            (bool success,) = newImplementation.delegatecall(initData);
            assert(success);
        }
    }

    /**
     * @dev Function to be compliance with EIP 897.
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-897.md
     * It is an "upgradable proxy".
     */
    function proxyType() public pure returns(uint256) {
        return 2; 
    }
    
    /**
     * @dev Function to get the proxy admin address.
     * @return adm The proxy admin address.
     */
    function admin() public view returns (address adm) {
        bytes32 position = adminPosition;
        assembly {
            adm := sload(position)
        }
    }
    
    /**
     * @dev Function to get the proxy implementation address.
     * @return impl The proxy implementation address.
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Function to set the proxy admin address.
     * Only can be called by the proxy admin.
     * @param newAdmin Address of the new proxy admin.
     */
    function transferProxyAdmin(address newAdmin) external onlyAdmin {
        _setAdmin(newAdmin);
    }
}