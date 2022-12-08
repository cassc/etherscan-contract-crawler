// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyImplementation.sol";
import "./interfaces/IFactory.sol";

contract SolidlyChildImplementation is SolidlyImplementation {
    bytes32 constant FACTORY_SLOT =
        0x547b500e425d72fd0723933cceefc203cef652b4736fd04250c3369b3e1a0a72; // keccak256('FACTORY') - 1

    modifier onlyFactory() {
        require(msg.sender == factoryAddress(), "only Factory");
        _;
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
}