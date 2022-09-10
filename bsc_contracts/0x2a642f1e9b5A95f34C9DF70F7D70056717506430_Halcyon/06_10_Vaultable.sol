// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "../vendor/@openzeppelin/contracts/access/Ownable.sol";
import "../vendor/@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Vaultable is Ownable
{
  using SafeMath for uint256;
  
    struct Vault {
        string name;
        address wallet;
        uint256 reflection;
        bool exists;
    }

    mapping(string => Vault) internal byName;
    mapping(address => Vault) internal byAddress;
    address[] internal _vaults;
    uint256 internal fees;

    event VaultAdded(address vault, string name);
    event VaultRemoved(address vault, string name);


    function setVault(string memory name, address vault, uint256 reflection) external onlyOwner
    {
        require(!byAddress[vault].exists, "Already in vaults.");
        require(reflection <= 3, "Vault fee cannot exceed 3%.");
        require(_vaults.length <= 5, "Total vaults cannot exceed 5.");

        fees += reflection;
        Vault memory _vault = Vault(name, vault, reflection, true);
        byAddress[vault] = _vault;
        byName[name] = _vault;

        _vaults.push(vault);

        emit VaultAdded(vault, name);
    }

  
    function getVaultByAddress(address vault) internal view returns (Vault memory)
    {
        return byAddress[vault];
    }

  
    function getVaultByName(string memory name) internal view returns (Vault memory)
    {
        return byName[name];
    }

  
    function removeVault(address vault) external onlyOwner
    {
        require(byAddress[vault].exists, "Vault does not exist.");

        uint256 fee = byAddress[vault].reflection;
        string memory name = byAddress[vault].name;
        fees = fees.sub(fee);
        delete byAddress[vault];
        delete byName[name];

        for (uint256 i = 0; i < _vaults.length; i++)
        {
            if (_vaults[i] == vault)
            {
                _vaults[i] = _vaults[_vaults.length - 1];
                _vaults.pop();
                break;
            }
        }

        emit VaultRemoved(vault, name);
    }
}