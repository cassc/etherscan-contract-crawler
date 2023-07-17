// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

contract ContractAddressChecker {
    function isContract(address _address) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }
    
    function getContractAddresses(address[] memory addresses) public view returns (address[] memory) {
        uint256 contractCount = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            if (isContract(addresses[i])) {
                contractCount++;
            }
        }
        
        address[] memory contractAddresses = new address[](contractCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            if (isContract(addresses[i])) {
                contractAddresses[currentIndex] = addresses[i];
                currentIndex++;
            }
        }
        
        return contractAddresses;
    }
}