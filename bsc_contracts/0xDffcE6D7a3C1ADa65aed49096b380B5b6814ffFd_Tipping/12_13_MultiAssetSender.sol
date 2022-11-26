// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title MultiAssetSender
 * @author Rafał Kalinowski <[email protected]>
 * @notice This is an utility contract for sending different kind of assets
 * @dev Please note that you should make reentrancy check yourself
 */
contract MultiAssetSender {

    constructor() { }

    /**
    * @notice Wrapper for sending native Coin via call function
    * @dev When using this function please make sure to not send it to anyone, verify the
    *      address in IDriss registry
    */
    function _sendCoin (address _to, uint256 _amount) internal {
        (bool sent, ) = payable(_to).call{value: _amount}("");
        require(sent, "Failed to send");
    }

    /**
     * @notice Wrapper for sending single ERC1155 asset 
     * @dev due to how approval in ERC1155 standard is handled, the smart contract has to ask for permissions to manage
     *      ALL tokens "for simplicity"... Hence, it has to be done before calling function that transfers the token
     *      to smart contract, and revoked afterwards
     */
    function _sendERC1155AssetBatch (
        uint256[] memory _assetIds,
        uint256[] memory _amounts,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC1155 nft = IERC1155(_contractAddress);
        nft.safeBatchTransferFrom(_from, _to, _assetIds, _amounts, "");
    }

    /**
     * @notice Wrapper for sending multiple ERC1155 assets
     * @dev due to how approval in ERC1155 standard is handled, the smart contract has to ask for permissions to manage
     *      ALL tokens "for simplicity"... Hence, it has to be done before calling function that transfers the token
     *      to smart contract, and revoked afterwards
     */
    function _sendERC1155Asset (
        uint256 _assetId,
        uint256 _amount,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC1155 nft = IERC1155(_contractAddress);
        nft.safeTransferFrom(_from, _to, _assetId, _amount, "");
    }

    /**
     * @notice Wrapper for sending NFT asset
     */
    function _sendNFTAsset (
        uint256 _assetIds,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC721 nft = IERC721(_contractAddress);
        nft.safeTransferFrom(_from, _to, _assetIds, "");
    }

    /**
     * @notice Wrapper for sending NFT asset with additional checks and iteraton over an array
     */
    function _sendNFTAssetBatch (
        uint256[] memory _assetIds,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        require(_assetIds.length > 0, "Nothing to send");

        IERC721 nft = IERC721(_contractAddress);
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            nft.safeTransferFrom(_from, _to, _assetIds[i], "");
        }
    }

    /**
     * @notice Wrapper for sending ERC20 Token asset with additional checks
     */
    function _sendTokenAsset (
        uint256 _amount,
        address _to,
        address _contractAddress
    ) internal {
        IERC20 token = IERC20(_contractAddress);

        bool sent = token.transfer(_to, _amount);
        require(sent, "Failed to transfer token");
    }

    /**
     * @notice Wrapper for sending ERC20 token from specific account with additional checks and iteraton over an array
     */
    function _sendTokenAssetFrom (
        uint256 _amount,
        address _from,
        address _to,
        address _contractAddress
    ) internal {
        IERC20 token = IERC20(_contractAddress);

        bool sent = token.transferFrom(_from, _to, _amount);
        require(sent, "Failed to transfer token");
    }
}