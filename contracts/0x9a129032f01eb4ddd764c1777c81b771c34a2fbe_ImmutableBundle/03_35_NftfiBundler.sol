// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC998TopDown.sol";
import "./INftfiBundler.sol";
import "./IBundleBuilder.sol";
import "./IPermittedNFTs.sol";
import "./utils/Ownable.sol";
import "./airdrop/AirdropFlashLoan.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NftfiBundler
 * @author NFTfi
 * @dev ERC998 Top-Down Composable Non-Fungible Token that supports ERC721 children.
 */
contract NftfiBundler is ERC998TopDown, IBundleBuilder {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    address public immutable permittedNfts;
    address public immutable airdropFlashLoan;

    string public baseURI;

    /**
     * @dev Stores name and symbol
     *
     * @param _admin - Initial admin of this contract.
     * @param _name name of the token contract
     * @param _symbol symbol of the token contract
     */
    constructor(
        address _admin,
        string memory _name,
        string memory _symbol,
        string memory _customBaseURI,
        address _permittedNfts,
        address _airdropFlashLoan
    ) ERC721(_name, _symbol) ERC998TopDown(_admin) {
        permittedNfts = _permittedNfts;
        airdropFlashLoan = _airdropFlashLoan;
        _setBaseURI(_customBaseURI);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IERC721Receiver).interfaceId ||
            _interfaceId == type(INftfiBundler).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Tells if an asset is permitted or not
     * @param _asset address of the asset
     * @return true if permitted, false otherwise
     */
    function permittedAsset(address _asset) public view returns (bool) {
        IPermittedNFTs permittedNFTs = IPermittedNFTs(permittedNfts);
        return permittedNFTs.getNFTPermit(_asset) > 0;
    }

    /**
     * @dev used to build a bundle from the BundleElements struct,
     * returns the id of the created bundle
     *
     * @param _bundleElements - the lists of erc721 tokens that are to be bundled
     */
    function buildBundle(BundleElementERC721[] memory _bundleElements) external override returns (uint256) {
        uint256 tokenId = safeMint(msg.sender);
        _addBundleElements(tokenId, _bundleElements);
        return tokenId;
    }

    /**
     * @dev Adds a set of BundleElementERC721 objects to the specified token ID.
     *
     * @param _tokenId The ID of the token to add the bundle elements to.
     * @param _bundleElements The array of BundleElementERC721 objects to add.
     */
    function addBundleElements(uint256 _tokenId, BundleElementERC721[] memory _bundleElements) external {
        _addBundleElements(_tokenId, _bundleElements);
    }

    /**
     * @dev Removes a set of BundleElementERC721 objects to the specified token ID.
     *
     * @param _tokenId The ID of the token to remove the bundle elements from.
     * @param _bundleElements The array of BundleElementERC721 objects to remove.
     */
    function removeBundleElements(uint256 _tokenId, BundleElementERC721[] memory _bundleElements) external {
        _removeBundleElements(_tokenId, _bundleElements);
    }

    /**
     * @dev Adds and removes a set of BundleElementERC721 objects from the specified token ID.
     *
     * @param _tokenId The ID of the token to add and remove the bundle elements from.
     * @param _toAdd The array of BundleElementERC721 objects to add.
     * @param _toRemove The array of BundleElementERC721 objects to remove.
     */
    function addAndRemoveBundleElements(
        uint256 _tokenId,
        BundleElementERC721[] memory _toAdd,
        BundleElementERC721[] memory _toRemove
    ) external {
        _addBundleElements(_tokenId, _toAdd);
        _removeBundleElements(_tokenId, _toRemove);
    }

    /**
     * @notice Remove all the children from the bundle
     * @dev This method may run out of gas if the list of children is too big. In that case, children can be removed
     *      individually.
     * @param _tokenId the id of the bundle
     * @param _receiver address of the receiver of the children
     */
    function decomposeBundle(uint256 _tokenId, address _receiver) external override {
        _validateReceiver(_receiver);
        _validateTransferSender(_tokenId);

        // In each iteration all contracts children are removed, so eventually all contracts are removed
        while (childContracts[_tokenId].length() > 0) {
            address childContract = childContracts[_tokenId].at(0);

            // In each iteration a child is removed, so eventually all contracts children are removed
            while (childTokens[_tokenId][childContract].length() > 0) {
                uint256 childId = childTokens[_tokenId][childContract].at(0);

                _removeChild(_tokenId, childContract, childId);

                try IERC721(childContract).safeTransferFrom(address(this), _receiver, childId) {
                    // solhint-disable-previous-line no-empty-blocks
                } catch {
                    _oldNFTsTransfer(_receiver, childContract, childId);
                }
                emit TransferChild(_tokenId, _receiver, childContract, childId);
            }
        }
    }

    /**
     * @notice Remove all the children from the bundle and send to personla bundler.
     * If bundle contains a legacy ERC721 element, this will not work.
     * @dev This method may run out of gas if the list of children is too big. In that case, children can be removed
     *      individually.
     * @param _tokenId the id of the bundle
     * @param _personalBundler address of the receiver of the children
     */
    function sendElementsToPersonalBundler(uint256 _tokenId, address _personalBundler) external virtual {
        _validateReceiver(_personalBundler);
        _validateTransferSender(_tokenId);
        require(_personalBundler != address(this), "cannot send to self");
        require(
            IERC165(_personalBundler).supportsInterface(type(IERC998ERC721TopDown).interfaceId),
            "has to implement IERC998ERC721TopDown"
        );
        uint256 personalBundleId = 1;
        //make sure sendeer owns personal bundler token
        require(IERC721(_personalBundler).ownerOf(personalBundleId) == msg.sender, "has to own personal bundle token");

        // In each iteration all contracts children are removed, so eventually all contracts are removed
        while (childContracts[_tokenId].length() > 0) {
            address childContract = childContracts[_tokenId].at(0);

            // In each iteration a child is removed, so eventually all contracts children are removed
            while (childTokens[_tokenId][childContract].length() > 0) {
                uint256 childId = childTokens[_tokenId][childContract].at(0);

                _removeChild(_tokenId, childContract, childId);

                try
                    IERC721(childContract).safeTransferFrom(
                        address(this),
                        _personalBundler,
                        childId,
                        abi.encodePacked(personalBundleId)
                    )
                {
                    // solhint-disable-previous-line no-empty-blocks
                } catch {
                    revert("only safe transfer");
                }
                emit TransferChild(_tokenId, _personalBundler, childContract, childId);
            }
        }
    }

    /**
     * @dev Internal function to add a set of BundleElementERC721 objects to the specified token ID.
     *
     * @param _tokenId The ID of the token to add the bundle elements to.
     * @param _bundleElements The array of BundleElementERC721 objects to add.
     */
    function _addBundleElements(uint256 _tokenId, BundleElementERC721[] memory _bundleElements) internal {
        require(_bundleElements.length > 0, "bundle is empty");
        uint256 elementNumber = _bundleElements.length;
        for (uint256 i; i != elementNumber; ++i) {
            require(permittedAsset(_bundleElements[i].tokenContract), "erc721 not permitted");
            if (_bundleElements[i].safeTransferable) {
                uint256 nuberOfIds = _bundleElements[i].ids.length;
                for (uint256 j; j != nuberOfIds; ++j) {
                    IERC721(_bundleElements[i].tokenContract).safeTransferFrom(
                        msg.sender,
                        address(this),
                        _bundleElements[i].ids[j],
                        abi.encodePacked(_tokenId)
                    );
                }
            } else {
                uint256 nuberOfIds = _bundleElements[i].ids.length;
                for (uint256 j; j != nuberOfIds; ++j) {
                    getChild(msg.sender, _tokenId, _bundleElements[i].tokenContract, _bundleElements[i].ids[j]);
                }
            }
        }

        emit AddBundleElements(_tokenId, _bundleElements);
    }

    /**
     * @dev Internal function to remove a set of BundleElementERC721 objects to the specified token ID.
     *
     * @param _tokenId The ID of the token to remove the bundle elements from.
     * @param _bundleElements The array of BundleElementERC721 objects to remove.
     */
    function _removeBundleElements(uint256 _tokenId, BundleElementERC721[] memory _bundleElements) internal {
        require(_bundleElements.length > 0, "bundle is empty");
        uint256 elementNumber = _bundleElements.length;
        for (uint256 i; i != elementNumber; ++i) {
            address erc721Contract = _bundleElements[i].tokenContract;
            uint256 nuberOfIds = _bundleElements[i].ids.length;
            for (uint256 j; j != nuberOfIds; ++j) {
                uint256 childId = _bundleElements[i].ids[j];
                _validateChildTransfer(_tokenId, erc721Contract, childId);
                _removeChild(_tokenId, erc721Contract, childId);
                if (_bundleElements[i].safeTransferable) {
                    IERC721(erc721Contract).safeTransferFrom(address(this), msg.sender, childId);
                } else {
                    _oldNFTsTransfer(msg.sender, erc721Contract, childId);
                }
                emit TransferChild(_tokenId, msg.sender, erc721Contract, childId);
            }
        }

        emit RemoveBundleElements(_tokenId, _bundleElements);
    }

    /**
     * @dev Update the state to receive a ERC721 child
     * Overrides the implementation to check if the asset is permitted
     * @param _from The owner of the child token
     * @param _tokenId The token receiving the child
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     */
    function _receiveChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual override {
        require(permittedAsset(_childContract), "erc721 not permitted");
        super._receiveChild(_from, _tokenId, _childContract, _childTokenId);
    }

    /**
     * @dev Override validation if it is a transfer from the airdropFlashLoan contract giving back the flashloan.
     * Validates the data from a child transfer and receives it otherwise
     * @param _from The owner of the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     */
    function _validateAndReceiveChild(
        address _from,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) internal virtual override {
        if (_from == airdropFlashLoan) {
            return;
        } else {
            super._validateAndReceiveChild(_from, _childContract, _childTokenId, _data);
        }
    }

    /**
     * @notice this function initiates a flashloan to pull an airdrop from a tartget contract
     *
     * @param _nftContract - contract address of the target nft of the drop
     * @param _nftId - id of the target nft of the drop
     * @param _target - address of the airdropping contract
     * @param _data - function selector to be called on the airdropping contract
     * @param _nftAirdrop - address of the used claiming nft in the drop
     * @param _nftAirdropId - id of the used claiming nft in the drop
     * @param _is1155 -
     * @param _nftAirdropAmount - amount in case of 1155
     */
    function pullAirdrop(
        address _nftContract,
        uint256 _nftId,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        address _beneficiary
    ) external {
        uint256 tokenId = childTokenOwner[_nftContract][_nftId];
        address rootOwner = address(uint160(uint256(rootOwnerOf(tokenId))));
        require(rootOwner == msg.sender, "pullAirdrop msg.sender not eligible");

        IERC721(_nftContract).safeTransferFrom(address(this), airdropFlashLoan, _nftId);

        AirdropFlashLoan(airdropFlashLoan).pullAirdrop(
            _nftContract,
            _nftId,
            _target,
            _data,
            _nftAirdrop,
            _nftAirdropId,
            _is1155,
            _nftAirdropAmount,
            _beneficiary
        );

        //take back collateral
        IERC721(_nftContract).safeTransferFrom(airdropFlashLoan, address(this), _nftId);
    }

    /**
     * @notice used by the owner account to be able to drain ERC721 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _tokenId - id token to be sent out
     * @param _receiver - receiver of the token
     */
    function rescueERC721(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    ) external onlyOwner {
        IERC721 tokenContract = IERC721(_tokenAddress);
        require(childTokenOwner[_tokenAddress][_tokenId] == 0, "token is in bundle");
        require(tokenContract.ownerOf(_tokenId) == address(this), "nft not owned");
        tokenContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /**
     * @notice used by the owner account to be able to drain ERC20 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _receiver - receiver of the token
     */
    function rescueERC20(address _tokenAddress, address _receiver) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "no tokens owned");
        tokenContract.safeTransfer(_receiver, amount);
    }

    /**
     * @dev Sets baseURI.
     * @param _customBaseURI - Base URI
     */
    function setBaseURI(string memory _customBaseURI) external onlyOwner {
        _setBaseURI(_customBaseURI);
    }

    /**
     * @dev Sets baseURI.
     */
    function _setBaseURI(string memory _customBaseURI) internal virtual {
        baseURI = bytes(_customBaseURI).length > 0
            ? string(abi.encodePacked(_customBaseURI, _getChainID().toString(), "/"))
            : "";
    }

    /** @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev This function gets the current chain ID.
     */
    function _getChainID() internal view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}