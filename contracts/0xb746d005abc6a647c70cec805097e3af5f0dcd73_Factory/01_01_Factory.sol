// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Factory {
    uint public primaryId;

    struct Product {
        string name;
        uint price;
        uint quality;
        uint id;
    }

    mapping(uint => Product) public list;
    uint public length;

    function isEqual(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        bytes memory aa = bytes(a);
        bytes memory bb = bytes(b);
        if (aa.length != bb.length) return false;
        for (uint i = 0; i < aa.length; i++) {
            if (aa[i] != bb[i]) return false;
        }

        return true;
    }

    function create(string memory _name, uint _price, uint _quality) public {
        bool flag = isEqual(_name, "");
        require(flag);
        uint _id = primaryId + 1;
        Product storage p = list[primaryId];
        p.name = _name;
        p.price = _price;
        p.quality = _quality;
        p.id = _id;
        primaryId++;
        length++;
    }

    function editName(uint _id, string memory _name) public {
        Product storage p = list[_id];
        p.name = _name;
    }
}