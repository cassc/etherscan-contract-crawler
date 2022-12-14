/*
ERC721StakingModuleInfo

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "../interfaces/IStakingModule.sol";
import "../ERC721StakingModule.sol";

/**
 * @title ERC721 staking module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC721StakingModule contract.
 */
library ERC721StakingModuleInfo {
    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of staking module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(address module)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint8
        )
    {
        IStakingModule m = IStakingModule(module);
        IERC721Metadata tkn = IERC721Metadata(m.tokens()[0]);
        if (!tkn.supportsInterface(0x5b5e139f)) {
            return (address(tkn), "", "", 0);
        }
        return (address(tkn), tkn.name(), tkn.symbol(), 0);
    }

    /**
     * @notice quote the share value for an amount of tokens
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens. if zero, return entire share balance
     * @return number of shares
     */
    function shares(
        address module,
        address addr,
        uint256 amount
    ) public view returns (uint256) {
        ERC721StakingModule m = ERC721StakingModule(module);

        // return all user shares
        if (amount == 0) {
            return m.counts(addr) * m.SHARES_PER_TOKEN();
        }

        require(amount <= m.counts(addr), "smni1");
        return amount * m.SHARES_PER_TOKEN();
    }

    /**
     * @notice get shares per token
     * @param module address of staking module
     * @return current shares per token
     */
    function sharesPerToken(address module) public view returns (uint256) {
        ERC721StakingModule m = ERC721StakingModule(module);
        return m.SHARES_PER_TOKEN() * 1e18;
    }

    /**
     * @notice get staked token ids for user
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens to enumerate
     * @param start token index to start at
     * @return ids array of token ids
     */
    function tokenIds(
        address module,
        address addr,
        uint256 amount,
        uint256 start
    ) public view returns (uint256[] memory ids) {
        ERC721StakingModule m = ERC721StakingModule(module);
        uint256 sz = m.counts(addr);
        require(start + amount <= sz, "smni2");

        if (amount == 0) {
            amount = sz - start;
        }

        ids = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            ids[i] = m.tokenByOwner(addr, i + start);
        }
    }
}