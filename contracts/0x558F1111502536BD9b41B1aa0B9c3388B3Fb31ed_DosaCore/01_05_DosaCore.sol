pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    function initialize(address _vault_token, address[] calldata users, uint256 rewardsAmt) external returns(bool);
    function updateTopHolders(address[] calldata users, bool isTop) external;
    function rescueTokens(address recipient, address tokenAddr, uint256 amount) external;
}

contract DosaCore is Ownable {

    mapping(uint256 => address) vaults;

    address public implementation;
    address public treasury;

    uint256 public vaultsCounter;

    event VaultCreated(address indexed vault);
    
    constructor(address _implementation, address _treasury) {
        implementation = _implementation;
        treasury = _treasury;
    }

    function createVault(address vault_token, address[] calldata topHoldersList, uint256 rewardsAmount) external onlyOwner{
        require(vault_token != address(0), "Vault token address cannot be 0");
        require(rewardsAmount > 0, "Rewards amount must be greater than 0");
        require(topHoldersList.length > 0, "Top holders list cannot be empty");

        address vaultCreated = Clones.clone(implementation);
        require(IVault(vaultCreated).initialize(vault_token, topHoldersList, rewardsAmount), "Vault initialization failed");
        require(IERC20(vault_token).transferFrom(treasury, vaultCreated, rewardsAmount), "Failed to transfer rewards to vault");	
        vaults[vaultsCounter] = vaultCreated;
        vaultsCounter++;
        emit VaultCreated(vaultCreated);
    }

    function updateImplementation(address _implementation) external onlyOwner {
        implementation = _implementation;
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function updateVaultTopHolders(address vaultAddr, address[] calldata topHoldersList, bool isTop) external onlyOwner {
        IVault vault = IVault(vaultAddr);
        vault.updateTopHolders(topHoldersList, isTop);
    }

    function rescueTokensFromVault(address vaultAddr, address recipient, address tokenAddr, uint256 amount) external onlyOwner {
        IVault(vaultAddr).rescueTokens(recipient, tokenAddr, amount);
    }

    function getVaultAtIndex(uint256 index) public view returns(address) {
        return vaults[index];
    }

}