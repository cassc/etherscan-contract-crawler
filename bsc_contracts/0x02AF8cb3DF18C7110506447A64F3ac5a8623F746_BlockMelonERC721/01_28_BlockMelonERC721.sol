/**
 * @notice Submitted for verification at bscscan.com on 2022-09-18
 */

/*
 _______          ___            ___      ___          ___
|   __   \       |   \          /   |    |   \        |   |
|  |  \   \      |    \        /    |    |    \       |   |
|  |__/    |     |     \      /     |    |     \      |   |
|         /      |      \____/      |    |      \     |   |
|        /       |   |\        /|   |    |   |\  \    |   |
|   __   \       |   | \______/ |   |    |   | \  \   |   |
|  |  \   \      |   |          |   |    |   |  \  \  |   |
|  |__/    |     |   |          |   |    |   |   \  \ |   |
|         /      |   |          |   |    |   |    \  \|   |
|________/       |___|          |___|    |___|     \______|
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BlockMelonERC721Minter.sol";

/**
 * @title BlockMelonERC721
 * @author BlockMelon
 * @dev A 'tradable' implementation of the standard {ERC721} by OpenZeppelin.
 *      See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol.
 *      Based on the code by Rarible and Foundation.
 *          See https://github.com/rarible/protocol-contracts/blob/master/tokens/contracts/erc-721/ERC721Rarible.sol
 *          See 0x93249388a3d98fd2412429a78bdd43691cc1508b `FNDNFT721.sol`
 */
contract BlockMelonERC721 is BlockMelonERC721Minter {
    /// @notice Emitted when the token contract is created
    event CreateBlockMelonERC721(
        address indexed creator,
        string name,
        string symbol
    );

    function __BlockMelonERC721_init(
        string memory contractName,
        string memory tokenSymbol,
        string memory baseURI_,
        address market,
        address treasury,
        address _adminContract,
        address _approvalContract
    ) external initializer {
        __BlockMelonERC721_init_unchained(
            contractName,
            tokenSymbol,
            baseURI_,
            market,
            treasury
        );
        _updateAdminContract(_adminContract);
        _updateApprovalContract(_approvalContract);
        _setDefaultApprovedMarket(market);
        emit CreateBlockMelonERC721(_msgSender(), contractName, tokenSymbol);
    }

    function __BlockMelonERC721_init_unchained(
        string memory contractName,
        string memory tokenSymbol,
        string memory baseURI_,
        address market,
        address treasury
    ) internal {
        __Context_init_unchained();
        __ERC165_init_unchained();
        _setBaseURI(baseURI_);
        __ERC721_init_unchained(contractName, tokenSymbol);
        __ERC721URIStorage_init_unchained();
        __BlockMelonERC721TokenBase_init_unchained();
        __BlockMelonERC721Creator_init_unchained();
        __BlockMelonERC721LockedContent_init_unchained();
        __BlockMelonERC721FirstOwners_init_unchained();
        __BlockMelonERC721RoyaltyInfo_init_unchained(market, treasury);
        __BlockMelonERC721Minter_init_unchained();
    }

    /**
     * @dev Allows a BlockMelon admin to update the market and treasury contract addresses
     */
    function updateMarketAndTreasury(address market, address treasury)
        external
        onlyBlockMelonAdmin
    {
        _updateMarketAndTreasury(market, treasury);
    }

    /**
     * @notice Allows a BlockMelon admin to change the admin contract address.
     */
    function updateAdminContract(address _adminContract)
        external
        onlyBlockMelonAdmin
    {
        _updateAdminContract(_adminContract);
    }

    /**
     * @notice Allows a BlockMelon admin to change the creator approval contract address.
     */
    function updateApprovalContract(address _approvalContract)
        external
        onlyBlockMelonAdmin
    {
        _updateApprovalContract(_approvalContract);
    }
}