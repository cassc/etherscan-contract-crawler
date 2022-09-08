// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import "@openzeppelin/contracts/access/Ownable.sol";

// Openluck interfaces
import {TaskItem, TaskExt} from "./ILucksExecutor.sol";
import {ILucksVRF} from "./ILucksVRF.sol";
import {ILucksGroup} from "./ILucksGroup.sol";
import {ILucksPaymentStrategy} from "./ILucksPaymentStrategy.sol";
import {ILucksAuto} from "./ILucksAuto.sol";
import {IPunks} from "./IPunks.sol";
import {IProxyNFTStation} from "./IProxyNFTStation.sol";

interface ILucksHelper {

    function checkPerJoinLimit(uint32 num) external view returns (bool);
    function checkAcceptToken(address acceptToken) external view returns (bool);
    function checkNFTContract(address addr) external view returns (bool);
    function checkNewTask(address user, TaskItem memory item) external view returns (bool);
    function checkNewTaskExt(TaskExt memory ext) external pure returns (bool);
    function checkNewTaskRemote(TaskItem memory item) external view returns (bool);
    function checkJoinTask(address user, uint256 taskId, uint32 num, string memory note) external view returns (bool);
    function checkTokenListing(address addr, address seller, uint256[] memory tokenIds, uint256[] memory amounts) external view returns (bool,string memory);    
    function checkExclusive(address account, address token, uint256 amount) external view returns (bool);
    function isPunks(address nftContract) external view returns(bool);

    function getProtocolFeeRecipient() external view returns (address);
    function getProtocolFee() external view returns (uint256);
    function getMinTargetLimit(address token) external view returns (uint256);
    function getDrawDelay() external view returns (uint32);

    function getVRF() external view returns (ILucksVRF);
    function getGROUPS() external view returns (ILucksGroup);
    function getSTRATEGY() external view returns (ILucksPaymentStrategy);
    function getAutoClose() external view returns (ILucksAuto);
    function getAutoDraw() external view returns (ILucksAuto);

    function getPunks() external view returns (IPunks);
    function getProxyPunks() external view returns (IProxyNFTStation);

}