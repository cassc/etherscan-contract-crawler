// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./JsonNftTemplate.sol";

contract SilverDollarTypePriceSheet is AccessControlEnumerable {
    mapping(bytes32=>uint32) coinPriceCents;
    bytes32 public constant PRICE_SETTER = keccak256("PRICE_SETTER");

    enum Design {MORGAN, PEACE}

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PRICE_SETTER
        , _msgSender());
    }

    function set(Design design, uint8 grade, uint32 priceCents) onlyRole(PRICE_SETTER) public {
        coinPriceCents[
            keccak256(abi.encodePacked(design,grade))
        ] = priceCents;
    }

    function setMulti(Design[] calldata designs, uint8[] calldata grades, uint32[] calldata priceCents) onlyRole(PRICE_SETTER) public {
       for(uint i; i<grades.length; i++){
           set(designs[i],grades[i],priceCents[i]);
       } 
    }

    function get(Design design, uint8 grade) public view returns (uint32 priceCents) {
        return coinPriceCents[keccak256(abi.encodePacked(design,grade))];
    }

    function getSum(Design[] calldata designs, uint8[] calldata grades) public view returns (uint32 priceCentsSum) {
        for(uint i; i<grades.length; i++){
            priceCentsSum += get(designs[i],grades[i]);
        }
    }

    function getCoinNftPriceCents(JsonNftTemplate nftContract, uint id) public view returns (uint32 priceCents) {
        string memory serial = nftContract.serial(id);
        uint16 year = stringToUint16(getSlice(serial,0,4));
        uint8 grade = uint8(stringToUint16(getSlice(serial,5,7)));
        Design design = Design.MORGAN;
        if(year>1921) design = Design.PEACE;
        return get(design, grade);
    }

    function getCoinNftSum(JsonNftTemplate nftContract, uint[] calldata ids) public view returns (uint32 priceCentsSum) {
        for(uint i; i<ids.length; i++){
            priceCentsSum += getCoinNftPriceCents(nftContract,ids[i]);
        }
    }

    function getCoinNftRangeSum(JsonNftTemplate nftContract, uint first, uint count) public view returns (uint32 priceCentsSum) {
        for(uint i = first; i<first+count; i++){
            priceCentsSum += getCoinNftPriceCents(nftContract,i);
        }
    }

    function getSlice(string memory text, uint256 begin, uint256 end) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin);
        for(uint i=0;i<end-begin;i++){
            a[i] = bytes(text)[i+begin];
        }
        return string(a);    
    }

    function stringToUint16(string memory s) internal pure returns (uint16 result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }
}