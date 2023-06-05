//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";

interface ITokenBundler {

    /**
     * BundleCreated
     * @dev Emitted when new bundle is created.
     */
    event BundleCreated(uint256 indexed id, address indexed creator);

    /**
     * BundleUnwrapped
     * @dev Emitted when bundle is unwrapped and burned.
     */
    event BundleUnwrapped(uint256 indexed id);

    /**
     * create
     * @dev Cannot create empty bundle or exceed maximum bundle size.
     * @dev Mint bundle token and transfers assets to Bundler contract.
     * @dev Emits a {BundleCreated} event.
     * @param _assets List of assets to include in a bundle
     * @return Bundle id
     */
    function create(MultiToken.Asset[] memory _assets) external returns (uint256);

    /**
     * unwrap
     * @dev Sender has to be a bundle owner.
     * @dev Burns bundle token and transfers assets to sender.
     * @dev Emits a {BundleUnwrapped} event.
     * @param _bundleId Bundle id to unwrap
     */
    function unwrap(uint256 _bundleId) external;

    /**
     * token
     * @param _tokenId Token nounce from bundle asset list.
     * @return MultiToken.Asset struct
     */
    function token(uint256 _tokenId) external view returns (MultiToken.Asset memory);

    /**
     * bundle
     * @param _bundleId Bundle id.
     * @return List of assets in a bundle.
     */
    function bundle(uint256 _bundleId) external view returns (uint256[] memory);

    /**
     * tokensInBundle
     * @param _bundleId Bundle id.
     * @return List of MultiToken.Asset structs in a bundle.
     */
    function tokensInBundle(uint256 _bundleId) external view returns (MultiToken.Asset[] memory);

}