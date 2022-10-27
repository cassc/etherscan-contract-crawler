// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library BoilerplateParam {
    struct ParamTemplate {
        // 0: not random-able from seed
        // 1: int
        // 2: float
        // 3: string
        // 4: bool
        uint8 _typeValue;

        uint16 _max;
        uint16 _min;
        uint8 _decimal;
        string[] _availableValues;
        uint16 _value;// index of available array value or value of range min,max
    }

    struct ParamsOfProject {
        bytes32 _seed;
        ParamTemplate[] _params;
    }
}