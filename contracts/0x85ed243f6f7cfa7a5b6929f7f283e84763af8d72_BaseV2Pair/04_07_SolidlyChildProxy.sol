// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyProxy.sol";
import "./interfaces/IFactory.sol";

/**
 * @notice Child Proxy deployed by factories for pairs, fees, gauges, and bribes. Calls back to the factory to fetch proxy implementation.
 */
contract SolidlyChildProxy is SolidlyProxy {
    bytes32 constant FACTORY_SLOT =
        0x547b500e425d72fd0723933cceefc203cef652b4736fd04250c3369b3e1a0a72; // keccak256('FACTORY') - 1

    modifier onlyFactory() {
        require(msg.sender == factoryAddress(), "only Factory");
        _;
    }

    /**
     * @notice Records factory address and current interface implementation
     */
    constructor() {
        address _factory = msg.sender;
        address _interface = IFactory(msg.sender).childInterfaceAddress();
        assembly {
            sstore(FACTORY_SLOT, _factory)
            sstore(IMPLEMENTATION_SLOT, _interface) // Storing the interface into EIP-1967's implementation slot so Etherscan picks up the interface
        }
    }

    /****************************************
                    SETTINGS
     ****************************************/

    /**
     * @notice Governance callable method to update the Factory address
     */
    function updateFactoryAddress(address _factory) external onlyGovernance {
        assembly {
            sstore(FACTORY_SLOT, _factory)
        }
    }

    /**
     * @notice Publically callable function to sync proxy interface with the one recorded in the factory
     */
    function updateInterfaceAddress() external {
        address _newInterfaceAddress = IFactory(factoryAddress())
            .childInterfaceAddress();
        require(
            implementationAddress() != _newInterfaceAddress,
            "Nothing to update"
        );
        assembly {
            sstore(IMPLEMENTATION_SLOT, _newInterfaceAddress)
        }
    }

    /****************************************
                  VIEW METHODS 
     ****************************************/

    /**
     * @notice Fetch current governance address from factory
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        override
        returns (address _governanceAddress)
    {
        return IFactory(factoryAddress()).governanceAddress();
    }

    function factoryAddress() public view returns (address _factory) {
        assembly {
            _factory := sload(FACTORY_SLOT)
        }
    }

    /**
     *@notice Fetch address where actual contract logic is at
     */
    function subImplementationAddress()
        public
        view
        returns (address _subimplementation)
    {
        return IFactory(factoryAddress()).childSubImplementationAddress();
    }

    /**
     * @notice Fetch address where the interface for the contract is
     */
    function interfaceAddress()
        public
        view
        override
        returns (address _interface)
    {
        assembly {
            _interface := sload(IMPLEMENTATION_SLOT)
        }
    }

    /****************************************
                  FALLBACK METHODS 
     ****************************************/

    /**
     * @notice Fallback function that delegatecalls the subimplementation instead of what's in the IMPLEMENTATION_SLOT
     */
    function _delegateCallSubimplmentation() internal override {
        address contractLogic = IFactory(factoryAddress())
            .childSubImplementationAddress();
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    fallback() external payable override {
        _delegateCallSubimplmentation();
    }

    receive() external payable override {
        _delegateCallSubimplmentation();
    }
}