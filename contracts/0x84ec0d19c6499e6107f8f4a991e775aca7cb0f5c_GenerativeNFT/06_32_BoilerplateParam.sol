// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library BoilerplateParam {
    struct ParamTemplate {
        // 1: int
        // 2: float
        // 3: string
        // 4: bool
        uint8 _typeValue;

        uint256 _max;
        uint256 _min;
        uint8 _decimal;
        string[] _availableValues;
        uint256 _value;// index of available array value or value of range min,max
        bool _editable; // false: random by seed, true: not random by seed
    }

    struct ParamsOfProject {
        bytes32 _seed;
        ParamTemplate[] _params;
    }
}