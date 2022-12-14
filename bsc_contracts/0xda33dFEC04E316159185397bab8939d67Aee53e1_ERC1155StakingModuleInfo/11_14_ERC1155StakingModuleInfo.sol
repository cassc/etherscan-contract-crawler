/*
ERC721StakingModuleInfo

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import "../interfaces/IStakingModule.sol";
import "../ERC1155StakingModule.sol";

/**
 * @title ERC1155 staking module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC1155StakingModule contract.
 */
library ERC1155StakingModuleInfo {
    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of staking module
     * @return uri
     */
    function token(address module)
        public
        view
        returns (string memory)
    {
        IStakingModule m = IStakingModule(module);
        IERC1155MetadataURI tkn = IERC1155MetadataURI(m.tokens()[0]);
        if (!tkn.supportsInterface(0x0e89341c)) {
            return "";
        }
        return "";
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
        ERC1155StakingModule m = ERC1155StakingModule(module);

        // return all user shares
        if (amount == 0) {
            return m.userTotalBalance(addr) * m.SHARES_PER_TOKEN();
        }

        require(amount <= m.userTotalBalance(addr), "smni1");
        return amount * m.SHARES_PER_TOKEN();
    }

    /**
     * @notice get shares per token
     * @param module address of staking module
     * @return current shares per token
     */
    function sharesPerToken(address module) public view returns (uint256) {
        ERC1155StakingModule m = ERC1155StakingModule(module);
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
        ERC1155StakingModule m = ERC1155StakingModule(module);
        uint256 sz = m.userTotalBalance(addr);
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