//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author NitroLeague.
interface INitroCollection1155 {
    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     *
     * @param newuri base uri for tokens
     */
    function setURI(string memory newuri) external;

    /**
     * Get URI of token with given id.
     */
    function uri(uint256 _tokenid) external;

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
    ) external;

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
    ) external;

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
    ) external;

    function mintAllowlisted(
        address _to,
        uint[] memory ids,
        uint[] memory amounts
    ) external;

    function lockMetaData() external;

    function paused() external view returns (bool);

    function pause() external;

    function unpause() external;

    function getClaimed(string memory context, address account)
        external
        view
        returns (bool claimed);

    function mintsCounter() external view returns (uint);

    function maxDailyMints() external view returns (uint);

    function lastChecked() external view returns (uint);
}