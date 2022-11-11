//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721M.sol";

contract ERC721MIncreasableSupply is ERC721M {
    // Whether mintable supply can increase. Once set to false, _maxMintableSupply can never increase.
    bool private _canIncreaseMaxMintableSupply;

    event DisableIncreaseMaxMintableSupply();

    constructor(
        string memory collectionName,
        string memory collectionSymbol,
        string memory tokenURISuffix,
        uint256 maxMintableSupply,
        uint256 globalWalletLimit,
        address cosigner,
        uint64 timestampExpirySeconds
    )
        ERC721M(
            collectionName,
            collectionSymbol,
            tokenURISuffix,
            maxMintableSupply,
            globalWalletLimit,
            cosigner,
            timestampExpirySeconds
        )
    {
        _canIncreaseMaxMintableSupply = true;
    }

    /**
     * @dev Return true if max mintable supply can be increased.
     */
    function getCanIncreaseMaxMintableSupply() external view returns (bool) {
        return _canIncreaseMaxMintableSupply;
    }

    /**
     * @dev Makes _canIncreaseMaxMintableSupply false permanently.
     */
    function disableIncreaseMaxMintableSupply() external onlyOwner {
        _canIncreaseMaxMintableSupply = false;
        emit DisableIncreaseMaxMintableSupply();
    }

    /**
     * @dev Sets maximum mintable supply.
     *
     * New supply cannot be larger than the old, unless _canIncreaseMaxMintableSupply is true.
     */
    function setMaxMintableSupply(uint256 maxMintableSupply)
        external
        override
        onlyOwner
    {
        if (
            !_canIncreaseMaxMintableSupply &&
            maxMintableSupply > _maxMintableSupply
        ) {
            revert CannotIncreaseMaxMintableSupply();
        }
        _maxMintableSupply = maxMintableSupply;
        emit SetMaxMintableSupply(maxMintableSupply);
    }
}