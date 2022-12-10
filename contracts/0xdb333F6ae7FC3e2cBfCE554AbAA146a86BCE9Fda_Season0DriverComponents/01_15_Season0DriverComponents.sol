// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

import "../lib/ERC1155.sol";
import "../lib/MetaOwnable.sol";
import "../lib/Mintable.sol";
import "../lib/ERC1155ClaimContext.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/** @title Standard ERC1155 NFT Contract with support of
 * 1. Meta transactions (owner as signer, user as executor).
 * 2. Contextual claim (List of tokens for a wallet against identifier)
 * 3. Minter (has the minting rights, different from owner)
 *
 * @author NitroLeague.
 */
contract Season0DriverComponents is
    ERC1155,
    MetaOwnable,
    Mintable,
    ERC1155ClaimContext
{
    constructor(
        address forwarder,
        address minter,
        uint dailyLimit
    ) ERC1155("", forwarder) Mintable(dailyLimit) {
        setMinter(minter);
        unPauseMint();
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     *
     * @param newuri base uri for tokens
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * Get URI of token with given id.
     */
    function uri(
        uint256 _tokenid
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    ERC1155.uri(_tokenid),
                    Strings.toString(_tokenid),
                    ".json"
                )
            );
    }

    /**
     * @dev Mints a token to a wallet (called by owner)
     *
     * @param to address to mint to
     * @param id token id to be minted.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Mints a token to a winner against a context (called by minter)
     *
     * @param _context Race/Event address, Lootbox or blueprint ID.
     * @param _to address to mint to
     * @param id token id to be minted.
     */
    function mintGame(
        string calldata _context,
        address _to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyMinter mintingAllowed inLimit validClaim(_context, _to, id) {
        setContext(_context, _to, id);
        _incrementMintCounter();
        _mint(_to, id, amount, data);
    }

    /**
     * @dev Mints multiple ids to a wallet (called by owner)
     *
     * @param to address to mint to
     * @param ids token ids to be minted.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
}