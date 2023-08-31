//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev interface to be implemented by {KresusNFT}.
 */
interface IKresusNFT {
    /**
     * @dev Function which mints token Id `_assetId` of amount `_amount`, to `_to` address,
     * sets the token URI of `_assetId` as `_tokenURI`.
     *
     * @param _to - the address of the to which tokens are to be minted.
     * @param _amount - the number of tokens of `_assetsId` to be minted.
     * @param _data - extra data parameter.
     * @param _tokenURI - URL for token metadata.
     * @param _assetId - token Id to be minted.
     */
    function mint(
        address _to,
        uint256 _amount,
        bytes memory _data,
        string memory _tokenURI,
        uint256 _assetId
    ) external;

    /**
     * @dev Function which mints multiple tokenIds `_assetIds`.
     * [Batched] version of {mint}.
     *
     * @param _to - the address of the to which tokens are to be minted.
     * @param _amounts - array of uint256 amounts to be minted for each mint.
     * @param _data - extra data parameter.
     * @param _assetIds - array of tokenIds to be minted.
     * @param _tokenURIs - arrray of URLs consisting metata for each of `_assetIds`.
     */
    function bulkMint(
        address _to,
        uint256[] memory  _amounts,
        bytes memory _data,
        uint256[] memory _assetIds,
        string[] memory _tokenURIs
    ) external;

    /**
     * @dev Function which burns the tokens, destroys tokenId `_id`,
     * reduces tokenId `_id` balance from `_from` address.
     *
     * @param _from - address from which tokens are to be deducted.
     * @param _assetId - tokenId to be burnt.
     * @param _amount - number of tokens to be burnt.
     */
    function burnToken(
        address _from,
        uint256 _assetId,
        uint256 _amount
    ) external;

    /**
     * @dev Function which burns multiple tokenIds.
     * [Batched] version of {burnToken}.
     *
     * @param _from - address from which tokens are to be deducted.
     * @param _assetIds - array of tokenIds to be destroyed.
     * @param _amounts - number of tokens to be destroyed for each of `_assetIds`.
     */
    function burnBatchToken(
        address _from,
        uint256[] memory _assetIds,
        uint256[] memory _amounts
    ) external;

    /**
     * @dev Function which transfers tokenId `_assetId` to each of `_to` addresses, of amount `_amounts`.
     *
     * @param _to - array of addresses to which `_assetId` has to be transferred.
     * @param _assetId - token id to be transferred.
     * @param _amounts - array of uint256, number of tokens to be transferred for each of `_assetIds`.
     * @param _data - extra data parameter.
     */
    function batchTransfer(
        address[] memory _to,
        uint256 _assetId,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    /**
     * @dev Function which changes proxy address. Transfers each of `_assetIds` to _proxyAddr of amount `_amounts`.
     * 
     * @param _proxyAddr - new proxy address to be updated.
     * @param _assetIds - array of token ids to be transferred.
     * @param _amounts - array of number of tokens to be transferred.
     * @param _data - extra data parameter.
     */
    function updateProxyAddress(
        address _proxyAddr,
        uint256[] memory _assetIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;
}