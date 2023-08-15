//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./deps/token/ERC1155/extensions/ERC1155URIStorage.sol";
import { IKresusNFT } from "./interfaces/IKresusNFT.sol";

/**
 * @dev contract complaint with {IKresusNFT} and extension of {ERC1155URIStorage}.
 * {ERC1155URIStorage} - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol
 */
contract KresusNFT is ERC1155URIStorage, IKresusNFT{

    // proxy contract address, deployed instance of {KresusProxy}.
    address private proxyAddress;

    // mapping from token ids to token minted or not.
    mapping(uint256 => bool) private mintedAssetIds;

    /**
     * @dev emitted when `assetId` is minted successfully to `to` address
     * and uri is set using `tokenURI`.
     */
    event mintSuccessful(
        address to,
        uint256 amount,
        bytes data,
        string tokenURI,
        uint256 assetId
    );

    /**
     * @dev emitted when `assetIds` are minted successfully to `to` addresses
     * and uri is set for each of `assetIds` using `tokenURIs`.
     */
    event bulkMintSuccessful(
        address to,
        uint256[] amounts,
        bytes data,
        string[] tokenURIs,
        uint256[] assetIds
    );

    /**
     * @dev emitted when a `tokenId` is successfully transferred to `to` addresses 
     * of amount `amounts`.
     */
    event batchTransferSuccessful(
        address[] to,
        uint256 assetId,
        uint256[] amounts,
        bytes data
    );

    /**
     * @dev Calls constructor of {ERC1155} with empty base URI and sets proxyAddress.
     * 
     * @param _proxyAddr - deployed contract address of {KresusProxy}.
     */
    constructor(address _proxyAddr)ERC1155(""){
        proxyAddress = _proxyAddr;
    }

    /**
     * @dev supports interface implementation.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IKresusNFT}.
     *
     * emits an {mintSuccessful} event.
     *
     * Requirements:
     * - Only `proxyAddress` can call this function.
     * - `_assetId` should not be minted before.
     */
    function mint(
        address _to,
        uint256 _amount,
        bytes memory _data,
        string memory _tokenURI,
        uint256 _assetId
    )
        external
        override
    {
        require(msg.sender == proxyAddress, "Kresus NFT: Caller not Proxy");
        require(!mintedAssetIds[_assetId], "Kresus NFT: Already Minted");
        mintedAssetIds[_assetId] = true;
        _mint(_to, _assetId, _amount, _data);
        _setURI(_assetId, _tokenURI);
        emit mintSuccessful(
            _to,
            _amount,
            _data,
            _tokenURI,
            _assetId
        );
    }

    /**
     * @dev See {IKresusNFT}
     *
     * emits an {bulkSuccessful} event.
     *
     * Requirements:
     * - Only `proxyAddress` can call this function.
     * - Lengths of `_assetIds`, `_tokenURIs` and `_amounts` must be equal.
     * - All ids in `_assetIds` should not be minted before.
     */
    function bulkMint(
        address _to,
        uint256[] memory  _amounts,
        bytes memory _data,
        uint256[] memory _assetIds,
        string[] memory _tokenURIs
    )
        external
        override
    {
        require(msg.sender == proxyAddress, "Kresus NFT: Caller not Proxy");
        require(_amounts.length == _tokenURIs.length, "Kresus NFT: Inconsistent lengths");
        for(uint256 i=0;i<_assetIds.length; i++){
            require(!mintedAssetIds[_assetIds[i]], "Kresus NFT: Already minted!");
            mintedAssetIds[_assetIds[i]] = true;
            _setURI(_assetIds[i], _tokenURIs[i]);
        }
        _mintBatch(_to, _assetIds, _amounts, _data);
        emit bulkMintSuccessful(
            _to,
            _amounts,
            _data,
            _tokenURIs,
            _assetIds
        );
    }

    /**
     * @dev See {IKresusNFT}.
     */
    function burnToken(
        address _from,
        uint256 _assetId,
        uint256 _amount
    )
        external
        override
    {
        _burn(_from, _assetId, _amount);
    }

    /**
     * @dev See {IKresusNFT}.
     */
    function burnBatchToken(
        address _from,
        uint256[] memory _assetIds,
        uint256[] memory _amounts
    )
        external
        override
    {
        _burnBatch(_from, _assetIds, _amounts);
    }

    /**
     * @dev See {IKresusNFT}.
     *
     * emits an {batchTransferSuccessful} event.
     *
     * Requirements:
     * - Lengths of `_to` and `_amounts` must be same length.
     */
    function batchTransfer(
        address[] memory _to,
        uint256 _assetId,
        uint256[] memory _amounts,
        bytes memory _data
    )
        external
        override
    {
        uint256 len = _to.length;
        require(len == _amounts.length, "Kresus NFT: Inconsistent lengths");
        for(uint256 i=0;i<len;i++) {
            _safeTransferFrom(msg.sender, _to[i], _assetId, _amounts[i], _data);
        }
        emit batchTransferSuccessful(_to, _assetId, _amounts, _data);
    }

    /**
     * @dev Function to change the proxy contract address.
     * @param _proxyAddr - new proxy address to be changed.
     * @param _assetIds - token ids of all the tokens owned by the proxy contract.
     * @param _amounts - number of tokens to be transferred to the new proxy contract.
     * @param _data - extra data parameter.
     *
     * Requirements:
     * - Only `proxyAddress` can call this function.
     */
    function updateProxyAddress(
        address _proxyAddr,
        uint256[] memory _assetIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) 
        external
        override
    {
        require(msg.sender == proxyAddress, "Kresus NFT: Caller not Proxy");
        proxyAddress = _proxyAddr;
        _safeBatchTransferFrom(msg.sender, _proxyAddr, _assetIds, _amounts, _data);
    }

    /**
     * @dev Function to get the address of proxy contract.
     */
    function getProxyAddress() external view returns(address) {
        return proxyAddress;
    }

    /**
     * @dev Function to check if `_assetId` is already minted.
     */
    function isMinted(uint256 _assetId) external view returns(bool) {
        return mintedAssetIds[_assetId];
    }
}