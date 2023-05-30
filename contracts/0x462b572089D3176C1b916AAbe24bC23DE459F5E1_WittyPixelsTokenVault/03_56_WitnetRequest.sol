// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetRequestTemplate.sol";
import "../libs/WitnetV2.sol";

abstract contract WitnetRequest
    is
        IWitnetRequest
{
    event WitnetRequestSettled(WitnetV2.RadonSLA sla);

    function args() virtual external view returns (string[][] memory);
    function class() virtual external view returns (bytes4);
    function curator() virtual external view returns (address);
    function getRadonSLA() virtual external view returns (WitnetV2.RadonSLA memory);
    function initialized() virtual external view returns (bool);
    function modifySLA(WitnetV2.RadonSLA calldata sla) virtual external returns (IWitnetRequest);
    function radHash() virtual external view returns (bytes32);
    function slaHash() virtual external view returns (bytes32);
    function template() virtual external view returns (WitnetRequestTemplate);
    function version() virtual external view returns (string memory);
}