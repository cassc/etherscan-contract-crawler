// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { IERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/**************************************

    EquityBadge interface

 **************************************/

interface IEquityBadge is IERC1155Upgradeable {

    // mint from fundraising
    function mint(
        address _sender, uint256 _projectId, uint256 _amount, bytes memory _data
    ) external;

    // delegate on behalf from fundraising
    function delegateOnBehalf(
        address _account, address _delegatee, bytes memory _data
    ) external;

    // total supply
    function totalSupply(uint256 _projectId) external view returns (uint256);

}