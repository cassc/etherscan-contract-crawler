// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library IndexedMapping {

    ///=============================================================================================
    /// Data Structures
    ///=============================================================================================

    struct Data {
        mapping(address => bool) valueExists;
        mapping(address => uint256) valueIndex;
        address[] valueList;
    }

    ///=============================================================================================
    /// Mutable
    ///=============================================================================================

    function add(Data storage self, address val) internal returns (bool) {
        if (exists(self, val)) return false;

        self.valueExists[val] = true;
        
        // push value to the actual list
        // no longers returns index
        self.valueList.push(val);

        // set the index by subtracting 1
        self.valueIndex[val] = self.valueList.length - 1;
        return true;
    }

    function remove(Data storage self, address val) internal returns (bool) {

        if (!exists(self, val)) return false;

        uint256 index = self.valueIndex[val];
        address lastVal = self.valueList[self.valueList.length - 1];

        // replace value we want to remove with the last value
        self.valueList[index] = lastVal;

        // adjust index for the shifted value
        self.valueIndex[lastVal] = index;

        // remove the last item
        self.valueList.pop();

        // remove value
        delete self.valueExists[val];
        delete self.valueIndex[val];

        return true;
    }

    ///=============================================================================================
    /// Non Mutable
    ///=============================================================================================

    function exists(Data storage self, address val) internal view returns (bool) {
        return self.valueExists[val];
    }

    function getValue(Data storage self, uint256 index) internal view returns (address) {
        return self.valueList[index];
    }

    function getValueList(Data storage self) internal view returns (address[] memory) {
        return self.valueList;
    }
}