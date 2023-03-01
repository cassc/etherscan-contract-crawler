// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPeach is IERC20 {
    function stake(
        uint256[] calldata tokenIds,
        uint256 ts,
        bytes memory sig
    ) external;

    function claim(uint256[] calldata tokenIds) external;

    function claimable(uint256 tokenId) external view returns (uint256 sum);

    function staker(uint256 tokenId) external view returns (address);
}