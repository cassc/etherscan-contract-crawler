/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {AppStorage} from "../AppStorage.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {LibEth} from "../../libraries/Token/LibEth.sol";

/**
 * @author Beasley
 * @title Users call any function in Beanstalk
 **/

contract FarmFacet {
    AppStorage internal s;

    /*
     * Farm Function
     */

    function _farm(bytes calldata data) private {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        bytes4 functionSelector;
        assembly {
            functionSelector := calldataload(data.offset)
        }
        address facet = ds
            .selectorToFacetAndPosition[functionSelector]
            .facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        (bool success, bytes memory returndata) = address(facet).delegatecall(data);
        if (!success) {
            if (returndata.length == 0) revert();
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
    }

    function farm(bytes[] calldata data) external payable {
        if (msg.value > 0) s.isFarm = 2;
        for (uint256 i; i < data.length; ++i) {
            _farm(data[i]);
        }
        if (msg.value > 0) {
            s.isFarm = 1;
            LibEth.refundEth();
        }
    }
}