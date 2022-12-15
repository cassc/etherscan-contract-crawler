// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IVeERC20.sol";

/**
 * @dev Interface of the VeOh
 */
interface IVeOh is IVeERC20, IERC721Receiver {
    function isUser(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function claim() external;

    function withdraw(uint256 _amount) external;

    function unstakeNft() external;

    function getStakedNft(address _addr) external view returns (uint256);

    function getStakedOh(address _addr) external view returns (uint256);

    function getVotes(address _account) external view returns (uint256);
}