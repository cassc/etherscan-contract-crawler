// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IEnergy {
    struct CollectProof {
        uint48 proofType;
        address spaceman;
        uint48 energyAmount;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    //view function
    function energyFactory() external view returns (address);

    function totalCollected() external view returns (uint256);

    function energyCollected(address addr) external view returns (uint256);

    // interact actions
    function collectEnergy(uint256 quantity, CollectProof calldata proof) external;

    function burnEnergy(uint256[] calldata energy) external;

    //owner actions
    function withdrawETH() external;

    function withdrawERC20(IERC20 token) external;

    function setEnergyFactory(address energyFactory_) external;

    function enableCollectStatus(bool collectStatus_) external;
}