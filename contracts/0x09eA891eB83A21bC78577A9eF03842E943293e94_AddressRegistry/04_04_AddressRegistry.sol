// SPDX-License-Identifier: MIT
/*
_____   ______________________   ____________________________   __
___  | / /__  ____/_  __ \__  | / /__  __ \__    |___  _/__  | / /
__   |/ /__  __/  _  / / /_   |/ /__  /_/ /_  /| |__  / __   |/ / 
_  /|  / _  /___  / /_/ /_  /|  / _  _, _/_  ___ |_/ /  _  /|  /  
/_/ |_/  /_____/  \____/ /_/ |_/  /_/ |_| /_/  |_/___/  /_/ |_/  
 ___________________________________________________________ 
  S Y N C R O N A U T S: The Bravest Souls in the Metaverse

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Affiliate contract
    address public affiliate;

    /// @notice Showcase contract
    address public showcase;

    /// @notice Auction contract
    address public auction;

    /// @notice Marketplace contract
    address public marketplace;

    /// @notice TokenRegistry contract
    address public tokenRegistry;

    /// @notice PriceFeed contract
    address public priceFeed;

    /**
     @notice Update Affiliate contract
     @dev Only admin
     */

    function updateAffiliate(address _affiliate) external onlyOwner {
        affiliate = _affiliate;
    }

    /**
     @notice Update Showcase contract
     @dev Only admin
     */

    function updateShowcase(address _showcase) external onlyOwner {
        showcase = _showcase;
    }

    /**
     @notice Update Auction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update Marketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
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