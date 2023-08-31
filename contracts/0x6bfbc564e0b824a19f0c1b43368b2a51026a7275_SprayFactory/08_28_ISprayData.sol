// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Structs.sol";

interface ISprayData {

    function getPaintBySkyId(uint skyId) external view returns (PaintData memory paintData);

}