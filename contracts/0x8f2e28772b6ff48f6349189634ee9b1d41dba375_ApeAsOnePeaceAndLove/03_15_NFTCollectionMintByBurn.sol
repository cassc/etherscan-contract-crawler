// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../NFTCollection.sol";
import "./NFTCollectionBurnable.sol";

abstract contract NFTCollectionMintByBurn is NFTCollection {
    NFTCollectionBurnable public burnableContract;

    error InsufficientBurnedTokens();
    error NotCorrectOwner();
    error RegularMintDisabled();
    error ExcessiveTokensPassed(uint256 amount);

    constructor(address _burnedContract) {
        burnableContract = NFTCollectionBurnable(_burnedContract);
    }

    function setBurnContract(address _burnedContract) public onlyOwner {
        burnableContract = NFTCollectionBurnable(_burnedContract);
    }

    /// @param _burnedTokens array with all the token ids a user is about to burn
    /// @dev tokens in burnedTokens must have been approved by owner to this contract address
    function mintByBurn(uint256[] calldata _burnedTokens) public virtual {
        uint256 burnAmount = _burnedTokens.length;
        uint256 mintAmount = burnAmount / getBurnToMintRate();
        uint256 excessBurnAmount = burnAmount % getBurnToMintRate();

        if (burnAmount < getBurnToMintRate()) {
            revert InsufficientBurnedTokens();
        }
        if (excessBurnAmount != 0) {
            revert ExcessiveTokensPassed(excessBurnAmount);
        }

        for (uint256 i = 0; i < burnAmount; i++) {
            if (burnableContract.ownerOf(_burnedTokens[i]) != msg.sender) {
                revert NotCorrectOwner();
            }
            burnableContract.burn(_burnedTokens[i]);
        }
        _mintAmount(mintAmount);
    }

    function mint(uint256) public payable virtual override {
        revert RegularMintDisabled();
    }

    function getBurnToMintRate() public view virtual returns (uint256) {
        return cost;
    }
}