//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Interfaces/ILisaSettings.sol";
import "./Interfaces/IArtTokenVault.sol";

contract ArtTokenVaultFactory is Ownable, Pausable {
    event ERC721TokenCreated(address tokenAddress);

    ILisaSettings public settings;

    event ArtTokenVaultCreated(
        address vaultAddress,
        address nftAddress,
        string nftSymbol
    );

    constructor(ILisaSettings _settings) {
        settings = _settings;
    }

    function updateSettings(address newSettings) external onlyOwner {
        settings = ILisaSettings(newSettings);
    }

    function deployTokenVault(
        string memory ftName,
        string memory ftSymbol,
        string memory nftName,
        string memory nftSymbol,
        string memory nftTokenURI
    ) external whenNotPaused {
        IArtERC721 nftContract = IArtERC721(
            Clones.clone(settings.getLogic(keccak256("ArtTokenERC721V1")))
        );
        nftContract.initialize(nftName, nftSymbol);

        address vault = Clones.clone(
            settings.getLogic(keccak256("ArtTokenVaultV1"))
        );
        IArtTokenVault(vault).initialize(
            _msgSender(),
            nftContract,
            ftName,
            ftSymbol
        );
        nftContract.mintItem(vault, nftTokenURI);
        nftContract.transferOwnership(vault);
        emit ArtTokenVaultCreated(vault, address(nftContract), nftSymbol);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}