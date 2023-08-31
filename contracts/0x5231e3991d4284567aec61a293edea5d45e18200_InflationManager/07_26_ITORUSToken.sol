// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITORUSToken is IERC20 {
    event MinterAdded(address minter);
    event MinterRemoved(address minter);
    event InitialDistributionMinted(uint256 amount);
    event AirdropMinted(uint256 amount);
    event AMMRewardsMinted(uint256 amount);
    event TreasuryRewardsMinted(uint256 amount);
    event SeedShareMinted(uint256 amount);

    /// @notice adds a new minter
    function addMinter(address newMinter) external;

    /// @notice renounces the minter rights of the sender
    function renounceMinterRights() external;

    /// @notice mints the initial distribution amount to the distribution contract
    function mintInitialDistribution(address distribution) external;

    /// @notice mints the airdrop amount to the airdrop contract
    function mintAirdrop(address airdropHandler) external;

    /// @notice mints the amm rewards
    function mintAMMRewards(address ammGauge) external;

    /// @notice mints `amount` to `account`
    function mint(address account, uint256 amount) external returns (uint256);

    /// @notice returns a list of all authorized minters
    function listMinters() external view returns (address[] memory);

    /// @notice returns the ratio of inflation already minted
    function inflationMintedRatio() external view returns (uint256);
}