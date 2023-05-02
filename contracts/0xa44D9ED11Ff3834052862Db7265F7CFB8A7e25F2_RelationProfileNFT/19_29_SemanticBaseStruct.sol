// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

    enum FieldType {
        INT,
        STRING,
        ADDRESS,
        SUBJECT,
        BLANKNODE
    }

    struct IntPO {
        uint256 pIndex;
        uint256 o;
    }

    struct StringPO {
        uint256 pIndex;
        string o;
    }

    struct AddressPO {
        uint256 pIndex;
        address o;
    }

    struct SubjectPO {
        uint256 pIndex;
        uint256 oIndex;
    }

    struct BlankNodePO {
        uint256 pIndex;
        IntPO[] intO;
        StringPO[] stringO;
        AddressPO[] addressO;
        SubjectPO[] subjectO;
    }

    struct BlankNodeO {
        uint256[] pIndex;
        uint256[] oIndex;
    }

    struct SPO {
        uint160 owner;
        uint256 sIndex;
        uint256[] pIndex;
        uint256[] oIndex;
    }

    struct Predicate {
        string name;
        FieldType fieldType;
    }

    struct Subject {
        string value;
        uint256 cIndex;
    }