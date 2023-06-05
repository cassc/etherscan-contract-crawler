//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./ITokenBundler.sol";


contract TokenBundler is Ownable, ERC1155, IERC1155Receiver, IERC721Receiver, ITokenBundler {
    using MultiToken for MultiToken.Asset;

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * Global incremental bundle id variable
     */
    uint256 private _id;

    /**
     * Global incremental token nonce variable
     */
    uint256 private _nonce;

    /**
     * Mapping of bundle id to token nonce list
     */
    mapping (uint256 => uint256[]) private _bundles;

    /**
     * Mapping of token nonce to asset struct
     */
    mapping (uint256 => MultiToken.Asset) private _tokens;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    // No custom events nor errors

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR & FUNCTIONS                               *|
    |*----------------------------------------------------------*/

    /**
     * Token Bundler constructor
     * @param _uri Bundlers metadata URI
     */
    constructor(string memory _uri) ERC1155(_uri) {

    }


    /**
     * @dev See {ITokenBundler-create}.
     */
    function create(MultiToken.Asset[] memory _assets) override external returns (uint256 bundleId) {
        uint256 length = _assets.length;
        require(length > 0, "Need to bundle at least one asset");
        require(length <= type(uint256).max - _nonce, "Bundler out of capacity");

        bundleId = ++_id;
        uint256 _bundleNonce = _nonce;
        unchecked { _nonce += length; }

        for (uint i; i < length;) {
            unchecked { ++_bundleNonce; }

            _tokens[_bundleNonce] = _assets[i];
            _bundles[bundleId].push(_bundleNonce);

            _assets[i].transferAssetFrom(msg.sender, address(this));

            unchecked { ++i; }
        }

        _mint(msg.sender, bundleId, 1, "");

        emit BundleCreated(bundleId, msg.sender);
    }

    /**
     * @dev See {ITokenBundler-unwrap}.
     */
    function unwrap(uint256 _bundleId) override external {
        require(balanceOf(msg.sender, _bundleId) == 1, "Sender is not bundle owner");

        uint256[] memory tokenList = _bundles[_bundleId];

        uint256 length = tokenList.length;
        for (uint i; i < length;) {
            _tokens[tokenList[i]].transferAsset(msg.sender);
            delete _tokens[tokenList[i]];

            unchecked { ++i; }
        }

        delete _bundles[_bundleId];

        _burn(msg.sender, _bundleId, 1);

        emit BundleUnwrapped(_bundleId);
    }

    /**
     * @dev See {ITokenBundler-token}.
     */
    function token(uint256 _tokenId) override external view returns (MultiToken.Asset memory) {
        return _tokens[_tokenId];
    }

    /**
     * @dev See {ITokenBundler-bundle}.
     */
    function bundle(uint256 _bundleId) override external view returns (uint256[] memory) {
        return _bundles[_bundleId];
    }

    /**
     * @dev See {ITokenBundler-tokensInBundle}.
     */
    function tokensInBundle(uint256 _bundleId) override external view returns (MultiToken.Asset[] memory) {
        uint256[] memory tokenList = _bundles[_bundleId];
        uint256 length = tokenList.length;

        MultiToken.Asset[] memory tokens = new MultiToken.Asset[](length);

        for (uint256 i; i < length;) {
            tokens[i] = _tokens[tokenList[i]];

            unchecked { ++i; }
        }

        return tokens;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address operator,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) override external view returns (bytes4) {
        require(operator == address(this), "Unsupported transfer function");
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address operator,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) override external view returns (bytes4) {
        require(operator == address(this), "Unsupported transfer function");
        return 0xf23a6e61;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) override external pure returns (bytes4) {
        revert("Unsupported transfer function");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(ITokenBundler).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * setUri
     * @dev An non-essential setup function. Can be called to adjust the bundler token metadata URI
     * @param _newUri setting the new origin of bundler metadata
     */
    function setUri(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }

}