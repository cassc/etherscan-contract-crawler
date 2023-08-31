//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IKresusNFT.sol";
import "./deps/token/ERC1155/utils/ERC1155Holder.sol";
import "./deps/token/ERC1155/IERC1155.sol";
import "./deps/access/AccessControl.sol";

/**
 * @dev Proxy contract which makes calls to {KresusNFT} to manage
 * mint, bulk mint, transfer and bulk transfer nft.
 * Manages Roles using access control contract using openzeppelin.
 * {AccessControl} - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol.
 */
contract KresusProxy is AccessControl, ERC1155Holder{

    // hash of string `SUB_ADMINS`, used in Access Control.
    bytes32 public constant SUB_ADMINS = keccak256("SUB_ADMINS");

    // address of deployed instance of contract implementing {IKresusNFT}.
    IKresusNFT private KRESUS_NFT_CONTRACT;

    /**
     * @dev Sets `_defaultAdmin` as Default Admin.
     * `_defaultAdmin` account can add subadmins or add more default admins,
     * to manage the minting and transfers of NFT from proxy contract`
     * 
     * @param _defaultAdmin - address which will be set as the default admin.
     */
    constructor(
        address _defaultAdmin
    )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /**
     * @dev supports interface implementation.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Function which makes call to {KresusNFT}. Mints `_assetId` to itself,
     * of amount `_amount`, with tokenURI `_tokenURI`.
     *
     * @param _amount - number of tokens to be minted.
     * @param _data - extra data parameter.
     * @param _tokenURI - URL of the token metadata.
     * @param _assetId - token id to be minted.
     *
     * Requirements:
     *  - Only accounts which have default admin or subadmin role can call this function.
     */
    function mint(
        uint256 _amount,
        bytes memory _data,
        string memory _tokenURI,
        uint256 _assetId
    )
        external
    {
        validateCaller(msg.sender);
        KRESUS_NFT_CONTRACT.mint(
            address(this),
            _amount,
            _data,
            _tokenURI,
            _assetId
        );
    }

    /**
     * @dev Function which mints multiple tokens to itself.
     * token Ids `_assetIds` are minted.
     * [Batch] version {mint}.
     *
     * @param _amounts - number of tokens to be minted for each of `_assetIds`.
     * @param _data - extera data parameter.
     * @param _assetIds - token Ids to be minted.
     * @param _tokenURIs - URL of the token metadata for each of `_assetIds`.
     *
     * Requirements:
     *  - Only accounts which have default admin or subadmin role can call this function.
     */
    function bulkMint(
        uint256[] memory  _amounts,
        bytes memory _data,
        uint256[] memory _assetIds,
        string[] memory _tokenURIs
    )
        external
    {
        validateCaller(msg.sender);
        KRESUS_NFT_CONTRACT.bulkMint(
            address(this),
            _amounts,
            _data,
            _assetIds,
            _tokenURIs
        );
    }

    /**
     * @dev Function to destroy minted tokens owned by the proxy contract.
     * Destroys token id `_assetId` of amount `_amount`.
     *
     * @param _assetId - token id to be destroyed.
     * @param _amount - amount to be destroyed.
     *
     * Requirements:
     *  - Only accounts which have default admin or subadmin role can call this function.
     */
    function burnToken(
        uint256 _assetId,
        uint256 _amount
    )
        external
    {
        validateCaller(msg.sender);
        KRESUS_NFT_CONTRACT.burnToken(
            address(this),
            _assetId,
            _amount
        );
    }

    /**
     * @dev Function to destroy multiple tokens owned by the proxy contract.
     * Destroys each of `_assetId` of amount `_amount`.
     * [Batch] version of {burnToken}.
     *
     * @param _assetIds - token ids to be destroyed.
     * @param _amounts - number of tokens to be destroyed for each of `_assetIds`.
     *
     * Requirements:
     *  - Only accounts which have default admin or subadmin role can call this function.
     */
    function burnBatchToken(
        uint256[] memory _assetIds,
        uint256[] memory _amounts
    )
        external
    {
        validateCaller(msg.sender);
        KRESUS_NFT_CONTRACT.burnBatchToken(
            address(this),
            _assetIds,
            _amounts
        );
    }

    /**
     * @dev Function to transfer owned NFTs from proxy contract.
     * Transfers token id `_assetId` to `_to` address of amount `_amount`.
     *
     * @param _to - address to which `_assetId` has to be transferred.
     * @param _assetId - token id which has to be transferred.
     * @param _amount - number of tokens to be transferred.
     * @param _data - extra data parameter.
     *
     * Requirements:
     * - Only accounts which have default admin or subadmin role can call this function.
     */
    function transferNFT(
        address _to,
        uint256 _assetId,
        uint256 _amount,
        bytes memory _data
    ) 
        external
    {
        validateCaller(msg.sender);
        IERC1155(
            address(KRESUS_NFT_CONTRACT)
        ).safeTransferFrom(
            address(this),
            _to,
            _assetId,
            _amount,
            _data
        );
    }

    /**
     * @dev Function to be called when a new proxy is deployed and all the tokens owned by proxy contract 
     * are to be transferred to a new proxy impl address.
     * calls batch transfer from {ERC1155}.
     *
     * @param _to - address of the new proxy. to which all the tokens are to be transferred.
     * @param _assetIds - token ids of all the tokens owned by the proxy contract.
     * @param _amounts - number of tokens to be transferred to the new proxy contract.
     * @param _data - extra data parameter.
     *
     * Requirements:
     * - Only accounts which have default admin role can call this function.
     */
    function migrate(
        address _to,
        uint256[] memory _assetIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) 
        external
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        KRESUS_NFT_CONTRACT.updateProxyAddress(
            _to,
            _assetIds,
            _amounts,
            _data
        );
    }

    /**
     * @dev Function to transfer token Id `_assetId` to each of `_to` addresses.
     * 
     * @param _to - addresses to which `_assetId` has to be transferred.
     * @param _assetId - tokenId which has to be transferred.
     * @param _amounts - number of tokens to be transferred to each of `_to` addresses.
     * @param _data - extra data parameter.
     * 
     * Requirements:
     * - Only accounts which have default admin or subadmin role can call this function.
     */
    function transferBatch(
        address[] memory _to,
        uint256 _assetId,
        uint256[] memory _amounts,
        bytes memory _data
    )
        external
    {
        validateCaller(msg.sender);
        KRESUS_NFT_CONTRACT.batchTransfer(
            _to,
            _assetId,
            _amounts,
            _data
        );
    }

    /**
     * @dev Function to get address of deployed instance of {KresusNFT}.
     */
    function getKresusNftAddress() external view returns(IKresusNFT) {
        return KRESUS_NFT_CONTRACT;
    }

    /**
     * @dev Function to update {KresusNFT} contract address.
     * 
     * Requirements:
     * - Only default admin can call this function.
     */
    function updateKresusNFT(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        KRESUS_NFT_CONTRACT = IKresusNFT(_address);
    }

    /**
     * @dev Function to check if `_address` has default admin or subadmin role.
     */
    function validateCaller(address _address) internal view {
        require(
            hasRole(SUB_ADMINS, _address) || 
            hasRole(DEFAULT_ADMIN_ROLE, _address),
            "Kresus Proxy: Unauthorized Caller"
        );
    }
}