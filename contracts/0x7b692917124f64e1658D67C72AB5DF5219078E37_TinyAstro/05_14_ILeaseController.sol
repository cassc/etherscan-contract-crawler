// SPDX-License-Identifier: MIT
//.___________. __  .__   __. ____    ____      ___           _______..___________..______        ______
//|           ||  | |  \ |  | \   \  /   /     /   \         /       ||           ||   _  \      /  __  \
//`---|  |----`|  | |   \|  |  \   \/   /     /  ^  \       |   (----``---|  |----`|  |_)  |    |  |  |  |
//    |  |     |  | |  . `  |   \_    _/     /  /_\  \       \   \        |  |     |      /     |  |  |  |
//    |  |     |  | |  |\   |     |  |      /  _____  \  .----)   |       |  |     |  |\  \----.|  `--'  |
//    |__|     |__| |__| \__|     |__|     /__/     \__\ |_______/        |__|     | _| `._____| \______/

pragma solidity 0.8.15;

/*
 * Interface for TinyAstroLeaseController for use in TinyAstro contract
 */
interface ILeaseController {
  function isTokenStaked(uint256 tokenId) external view returns (bool);
}