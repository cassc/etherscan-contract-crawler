// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PreUtils.sol";

library PreUranoBundles {
    function getInternalRate(uint256 _usdtValueUnit, uint256 _perUranoUnit)
        public
        pure
        returns (uint256[2] memory)
    {
        return [
            PreUtils.unitToMicro(_usdtValueUnit),
            PreUtils.unitToAtto(_perUranoUnit)
        ];
    }

    function getBundleByName(string memory _bundle)
        public
        pure
        returns (uint256[2] memory)
    {
        bytes32 bundledVal = keccak256(abi.encodePacked(_bundle));
        if (bundledVal == keccak256(abi.encodePacked("250"))) {
            return getBundle250();
        } else if (bundledVal == keccak256(abi.encodePacked("500"))) {
            return getBundle500();
        } else if (bundledVal == keccak256(abi.encodePacked("1k"))) {
            return getBundle1k();
        } else if (bundledVal == keccak256(abi.encodePacked("3k"))) {
            return getBundle3k();
        } else if (bundledVal == keccak256(abi.encodePacked("5k"))) {
            return getBundle5k();
        } else if (bundledVal == keccak256(abi.encodePacked("10k"))) {
            return getBundle10k();
        } else if (bundledVal == keccak256(abi.encodePacked("20k"))) {
            return getBundle20k();
        } else if (bundledVal == keccak256(abi.encodePacked("30k"))) {
            return getBundle30k();
        } else if (bundledVal == keccak256(abi.encodePacked("50k"))) {
            return getBundle50k();
        } else if (bundledVal == keccak256(abi.encodePacked("100k"))) {
            return getBundle100k();
        } else {
            revert("invalid bundle");
        }
    }

    function getBundleJsonArray() public pure returns (string memory) {
        return '["250","500","1k","3k","5k","10k","20k","30k","50k","100k"]';
    }

    function getAvailableBundlesJsonArray(uint256 _availableUrano)
        public
        pure
        returns (string memory)
    {
        if (_availableUrano >= 2150000000) {
            return
                '["250","500","1k","3k","5k","10k","20k","30k","50k","100k"]';
        } else if (_availableUrano >= 1070000000) {
            return '["250","500","1k","3k","5k","10k","20k","30k","50k"]';
        } else if (_availableUrano >= 639000000) {
            return '["250","500","1k","3k","5k","10k","20k","30k"]';
        } else if (_availableUrano >= 424000000) {
            return '["250","500","1k","3k","5k","10k","20k"]';
        } else if (_availableUrano >= 210000000) {
            return '["250","500","1k","3k","5k","10k"]';
        } else if (_availableUrano >= 100000000) {
            return '["250","500","1k","3k","5k"]';
        } else if (_availableUrano >= 60000000) {
            return '["250","500","1k","3k"]';
        } else if (_availableUrano >= 20000000) {
            return '["250","500","1k"]';
        } else if (_availableUrano >= 10000000) {
            return '["250","500"]';
        } else if (_availableUrano >= 5000000) {
            return '["250"]';
        } else {
            return "[]";
        }
    }

    function getBundle250() public pure returns (uint256[2] memory) {
        return getInternalRate(250, 5000000);
    }

    function getBundle500() public pure returns (uint256[2] memory) {
        return getInternalRate(500, 10000000);
    }

    function getBundle1k() public pure returns (uint256[2] memory) {
        return getInternalRate(1000, 20000000);
    }

    function getBundle3k() public pure returns (uint256[2] memory) {
        return getInternalRate(3000, 60000000);
    }

    function getBundle5k() public pure returns (uint256[2] memory) {
        return getInternalRate(5000, 100000000);
    }

    function getBundle10k() public pure returns (uint256[2] memory) {
        return getInternalRate(10000, 210000000);
    }

    function getBundle20k() public pure returns (uint256[2] memory) {
        return getInternalRate(20000, 424000000);
    }

    function getBundle30k() public pure returns (uint256[2] memory) {
        return getInternalRate(30000, 639000000);
    }

    function getBundle50k() public pure returns (uint256[2] memory) {
        return getInternalRate(50000, 1070000000);
    }

    function getBundle100k() public pure returns (uint256[2] memory) {
        return getInternalRate(100000, 2150000000);
    }
}