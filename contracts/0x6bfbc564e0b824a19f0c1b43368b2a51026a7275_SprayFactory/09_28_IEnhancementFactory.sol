// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Structs.sol";

interface IEnhancementFactory {

    function applyEnhancement(BaseAttributes memory baseAtts, uint skyId, string memory seed) external view returns (BaseAttributes memory);

}