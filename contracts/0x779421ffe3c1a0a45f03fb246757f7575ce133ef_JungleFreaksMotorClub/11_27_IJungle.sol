// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IJungle is IERC1155, IERC20, IERC20Metadata {
    function getStakedTokens(address staker)
        external
        view
        returns (uint256[] memory);

    function getStakedAmount(address staker) external view returns (uint256);

    function getStaker(uint256 tokenId) external view returns (address);

    function getAllRewards(address staker) external view returns (uint256);

    function getLegendariesRewards(address staker)
        external
        view
        returns (uint256);

    function stakeById(uint256[] calldata tokenIds) external;

    function legendariesStaked(address)
        external
        view
        returns (
            uint32 cotfAccumulatedTime,
            uint32 mtfmAccumulatedTime,
            uint32 cotfLastStaked,
            uint32 mtfmLastStaked,
            uint8 cotfStaked,
            uint8 mtfmStaked
        );

    function stakeLegendaries(uint8 cotf, uint8 mtfm) external;

    function unstakeLegendaries(uint8 cotf, uint8 mtfm) external;

    function claimLegendaries() external;

    function unstakeByIds(uint256[] calldata tokenIds) external;

    function unstakeAll() external;

    function claimAll() external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function setController(address controller, bool authorized) external;

    function setAuthorizedAddress(address authorizedAddress, bool authorized)
        external;
}