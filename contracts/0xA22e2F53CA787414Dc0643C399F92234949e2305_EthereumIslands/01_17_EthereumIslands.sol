// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IslandBase.sol";

contract EthereumIslands is IslandBase {
    uint256 public genesisMintIndex;
    uint256 public genesisMintPrice = 1000000 * 10**18;

    IERC20Burnable public pmlg;

    constructor(
        IERC20Burnable pml,
        IMetadataStorage metadataStorage,
        IERC20Burnable _pmlg
    ) IslandBase("Grassland Archipelago", "PGA", pml, metadataStorage) {
        pmlg = _pmlg;
    }

    // @notice mint genesis islands with PMLG tokens
    function mintGenesis(uint256 amount) external {
        if (genesisMintIndex + amount > genesisLimit) revert MintWouldExceedLimit();

        pmlg.burnFrom(msg.sender, amount * genesisMintPrice);

        uint256 newMintIndex = genesisMintIndex;
        for (uint256 i = 0; i < amount; i++) {
            ++newMintIndex;
            _safeMint(msg.sender, newMintIndex);
        }
        genesisMintIndex = newMintIndex;
    }

    // ------------------
    // Setter
    // ------------------

    function setGenesisMintPrice(uint256 _genesisMintPrice) external onlyOwner {
        genesisMintPrice = _genesisMintPrice;
    }
}