// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OnAvaxAddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Ovx contract
    address public ovx;

    /// @notice OnAvaxAuction contract
    address public auction;

    /// @notice OnAvaxMarketplace contract
    address public marketplace;

    /// @notice OnAvaxBundleMarketplace contract
    address public bundleMarketplace;

    /// @notice OnAvaxNFTFactory contract
    address public factory;

    /// @notice OnAvaxNFTFactoryPrivate contract
    address public privateFactory;

    /// @notice OnAvaxArtFactory contract
    address public artFactory;

    /// @notice OnAvaxArtFactoryPrivate contract
    address public privateArtFactory;

    /// @notice OnAvaxTokenRegistry contract
    address public tokenRegistry;

    /// @notice OnAvaxPriceFeed contract
    address public priceFeed;

    /**
     @notice Update ovx contract
     @dev Only admin
     */
    function updateOvx(address _ovx) external onlyOwner {
        require(
            IERC165(_ovx).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        ovx = _ovx;
    }

    /**
     @notice Update OnAvaxAuction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update OnAvaxMarketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update OnAvaxBundleMarketplace contract
     @dev Only admin
     */
    function updateBundleMarketplace(address _bundleMarketplace)
        external
        onlyOwner
    {
        bundleMarketplace = _bundleMarketplace;
    }

    /**
     @notice Update OnAvaxNFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     @notice Update OnAvaxNFTFactoryPrivate contract
     @dev Only admin
     */
    function updateNFTFactoryPrivate(address _privateFactory)
        external
        onlyOwner
    {
        privateFactory = _privateFactory;
    }

    /**
     @notice Update OnAvaxArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _artFactory) external onlyOwner {
        artFactory = _artFactory;
    }

    /**
     @notice Update OnAvaxArtFactoryPrivate contract
     @dev Only admin
     */
    function updateArtFactoryPrivate(address _privateArtFactory)
        external
        onlyOwner
    {
        privateArtFactory = _privateArtFactory;
    }

    /**
     @notice Update token registry contract
     @dev Only admin
     */
    function updateTokenRegistry(address _tokenRegistry) external onlyOwner {
        tokenRegistry = _tokenRegistry;
    }

    /**
     @notice Update price feed contract
     @dev Only admin
     */
    function updatePriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = _priceFeed;
    }
}