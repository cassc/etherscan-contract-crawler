// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../libraries/ScaledMath.sol";
import "../../interfaces/tokenomics/IROOTToken.sol";

/// @notice the deployer will initially have minting rights
/// The process will be to premint `PRE_MINT_RATIO` of `MAX_TOTAL_SUPPLY`
/// to the initial distribution address, grant the minting rights to the inflation manager
/// and renounce its minting rights
contract ROOTToken is IROOTToken, ERC20 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using ScaledMath for uint256;

    uint256 public constant PRE_MINT_RATIO = 0.3e18;
    uint256 public constant AIRDROP_MINT_RATIO = 0.1e18;
    uint256 public constant AMM_REWARDS_RATIO = 0.1e18;
    uint256 public constant TREASURY_REWARDS_RATIO = 0.05e18;
    uint256 public constant TREASURY_SEED_RATIO = 0.01e18;
    uint256 public constant INFLATION_RATIO =
        1e18 -
            AMM_REWARDS_RATIO -
            AIRDROP_MINT_RATIO -
            PRE_MINT_RATIO -
            TREASURY_REWARDS_RATIO -
            TREASURY_SEED_RATIO;
    uint256 public constant MAX_TOTAL_SUPPLY = 10_000_000e18;

    EnumerableSet.AddressSet internal authorizedMinters;

    bool public initialDistributionMintDone;
    bool public airdropMintDone;
    bool public ammGaugeMintDone;
    bool public treasuryMintDone;
    bool public seedShareMintDone;

    modifier onlyMinter() {
        require(authorizedMinters.contains(msg.sender), "not authorized");
        _;
    }

    constructor() ERC20("Root Finance Token", "ROOT") {
        authorizedMinters.add(msg.sender);
        emit MinterAdded(msg.sender);
    }

    function addMinter(address newMinter) external onlyMinter {
        if (authorizedMinters.add(newMinter)) {
            emit MinterAdded(newMinter);
        }
    }

    function renounceMinterRights() external onlyMinter {
        authorizedMinters.remove(msg.sender);
        emit MinterRemoved(msg.sender);
    }

    function mintInitialDistribution(address distribution) external onlyMinter {
        require(!initialDistributionMintDone, "premint already done");
        uint256 mintAmount = MAX_TOTAL_SUPPLY.mulDown(PRE_MINT_RATIO);
        _mint(distribution, mintAmount);
        initialDistributionMintDone = true;
        emit InitialDistributionMinted(mintAmount);
    }

    function mintAirdrop(address airdropHandler) external onlyMinter {
        require(!airdropMintDone, "airdrop already done");
        uint256 mintAmount = MAX_TOTAL_SUPPLY.mulDown(AIRDROP_MINT_RATIO);
        _mint(airdropHandler, mintAmount);
        airdropMintDone = true;
        emit AirdropMinted(mintAmount);
    }

    function mintAMMRewards(address ammGauge) external onlyMinter {
        require(!ammGaugeMintDone, "amm rewards already minted");
        uint256 mintAmount = MAX_TOTAL_SUPPLY.mulDown(AMM_REWARDS_RATIO);
        _mint(ammGauge, mintAmount);
        ammGaugeMintDone = true;
        emit AMMRewardsMinted(mintAmount);
    }

    function mintTreasuryShare(address treasuryEscrow) external onlyMinter {
        require(!treasuryMintDone, "treasury rewards already minted");
        uint256 mintAmount = MAX_TOTAL_SUPPLY.mulDown(TREASURY_REWARDS_RATIO);
        _mint(treasuryEscrow, mintAmount);
        treasuryMintDone = true;
        emit TreasuryRewardsMinted(mintAmount);
    }

    function mintSeedShare(address treasury) external onlyMinter {
        require(!seedShareMintDone, "seed share already minted");
        uint256 mintAmount = MAX_TOTAL_SUPPLY.mulDown(TREASURY_SEED_RATIO);
        _mint(treasury, mintAmount);
        seedShareMintDone = true;
        emit SeedShareMinted(mintAmount);
    }

    function mint(address account, uint256 amount) external onlyMinter returns (uint256) {
        uint256 currentSupply = totalSupply();
        if (amount + currentSupply > MAX_TOTAL_SUPPLY) {
            amount = MAX_TOTAL_SUPPLY - currentSupply;
        }
        if (amount > 0) {
            _mint(account, amount);
        }
        return amount;
    }

    /// @dev this assumes that all the pre-mint events occured
    function inflationMintedRatio() external view returns (uint256) {
        uint256 currentSupply = totalSupply();
        uint256 totalToMint = MAX_TOTAL_SUPPLY.mulDown(INFLATION_RATIO);
        uint256 totalPreMinted = MAX_TOTAL_SUPPLY - totalToMint;
        uint256 totalInflationMinted = currentSupply - totalPreMinted;
        return totalInflationMinted.divDown(totalToMint);
    }

    function listMinters() external view returns (address[] memory) {
        return authorizedMinters.values();
    }
}