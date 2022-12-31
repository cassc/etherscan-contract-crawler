// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*

    @###^"####N       ,##########b]###b               j###b           ###[
    @###   "####m   ;#####========!====               j###b           ###[
    @###     "@###[email protected]####~                             j###b           ###[
    @###      ]###[email protected]#############b]###[email protected]###[email protected]####p   j###b^%####w    ##############
    @###      ]###[email protected]###M*********b]###[email protected]###b  ^%####p j###b  ^%####m  ####**********
    @###      ]###[email protected]###~          ]###[email protected]###b    ^%###[j###b     7#### ###[
    @###      ]###[email protected]###~          ]###[email protected]###b     j###[j###b      #### ###[
    @###      ]###[email protected]###~          ]###[email protected]###b     j###[j###b      #### ###[
    @###      ]###[email protected]###~          ]###b1####w    j###[j###b      #### ####N
    @###      ]###[email protected]###~          ]###b '%####m  j###[j###b      ####  [email protected]###########
    @###      ]###[email protected]###~          ]###b    7####mJ###[j###b      ####    [email protected]#########
                                                #####b
                                       @###########C
                                       @#########\
*/

import {ASSPLayerParent} from "../ASSPLayer/ASSPLayerParent.sol";

/**
 * @title NFightParent
 * @notice Layer 1 protocol for NFight project and token registration
 * @dev This contract is used for initial integration of partner projects and tokens
 */

contract NFightParent is ASSPLayerParent {
    constructor(address _checkpointManager, address _fxRoot) ASSPLayerParent(_checkpointManager, _fxRoot) {}

    function _processMessageFromChild(bytes memory data) internal override {}
}