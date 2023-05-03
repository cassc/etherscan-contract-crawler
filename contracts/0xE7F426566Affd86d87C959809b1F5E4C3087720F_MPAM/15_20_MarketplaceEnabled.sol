//SPDX-License-Identifier: MIT
/**
 * @title MarketplaceEnabled
 * @dev @brougkr
 * note: This Contract Is Used To Enable DutchMarketplace To Purchase Tokens From Your Contract
 * note: This Contract Should Be Imported and Included In The `is` Portion Of The Contract Declaration, ex. `contract NFT is Ownable, MarketplaceEnabled`
 * note: You Can Copy Or Modify The Example Functions Below To Implement The Two Functions In Your Contract Required By MarketplaceEnabled
 */
pragma solidity 0.8.19;
abstract contract MarketplaceEnabled
{
    /**
     * @dev Marketplace Mint
     * note: Should Be Implemented With onlyMarketplace Access Modifier
     * note: Should Return The TokenID Being Transferred To The Recipient
     */
    function _MintToFactory(uint ProjectID, address Recipient, uint Amount) external virtual;
    // EXAMPLE:
    // function _MintToFactory(uint ProjectID, address Recipient, uint Amount) override virtual external onlyMarketplace
    // {
    //     require(totalSupply() + Amount <= 100, "MP: Max Supply Reached");
    //     _mint(Recipient, Amount); 
    // }

    /**
     * @dev ChangeMarketplaceAddress Changes The Marketplace Address | note: Should Be Implemented To Include onlyOwner Or Similar Access Modifier
     */
    function __ChangeMarketplaceAddress(address NewAddress) external virtual;
    // EXAMPLE: 
    // function __ChangeMarketplaceAddress(address NewAddress) override virtual external onlyOwner { _MARKETPLACE = NewAddress; }

    /**
     * @dev Marketplace Address
     */
    address public _MARKETPLACE_ADDRESS = 0x3725a379F90BeB320101453A0C75196C40749571; // GOERLI
    // address _MARKETPLACE_ADDRESS = 0x295f593B7A162B68b4353444cA622209492bCA2E; // MAINNET

    /**
     * @dev Access Modifier For Marketplace
     */
    modifier onlyMarketplace
    {
        require(msg.sender == _MARKETPLACE_ADDRESS, "onlyMarketplace: `msg.sender` Is Not The Marketplace Contract");
        _;
    }
}