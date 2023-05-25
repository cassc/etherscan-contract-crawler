// SPDX-License-Identifier: MIT
// Creator: P4SD Labs

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error CannotUseCoinYet();
error NonExistentToken();
error NotEveryAddressHasQuantity();
error CoinSupplyWouldExceedLimit();


contract VendingCoins is ERC1155Supply, ERC2981, Ownable {
    mapping(uint256 => uint256) public coinLimit;
    mapping(uint256 => bool) public coinUsable;

    event CoinsUsed(address sender, uint256 coin, uint256 quantity);

    constructor(address defaultTreasury) ERC1155("") {
        setRoyaltyInfo(payable(defaultTreasury), 500);
        setLimit(0, 10000);
    }

    function mint(address[] calldata receivers, uint256 coin, uint256[] calldata quantity) external onlyOwner {
        if (receivers.length != quantity.length) revert NotEveryAddressHasQuantity();

        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], coin, quantity[i], "");
        }

        if (totalSupply(coin) > coinLimit[coin]) revert CoinSupplyWouldExceedLimit();
    }

    function use(uint256 coin, uint256 quantity) external {
        if (!coinUsable[coin]) revert CannotUseCoinYet();
        _burn(msg.sender, coin, quantity);

        // Oracle listens to this event and dispenses items.
        emit CoinsUsed(msg.sender, coin, quantity);
    }

    /**
     * @dev Update the royalty percentage (500 = 5%)
     */
    function setRoyaltyInfo(address treasuryAddress, uint96 newRoyaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(payable(treasuryAddress), newRoyaltyPercentage);
    }

    /**
     * @dev Set whether the coin is usable / burnable
     */
    function setUsable(uint256 coin, bool canUse) public onlyOwner {
        coinUsable[coin] = canUse;
    }

    /**
     * @dev Sets the coin limit. Not intended for use post mint.
     */
    function setLimit(uint256 coin, uint256 supply) public onlyOwner {
        coinLimit[coin] = supply;
    }

    /**
     * @dev Update the base uri
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }
    
    // ---- Overrides ----

    function uri(uint256 tokenID) public view override returns (string memory){
        if (!exists(tokenID)) revert NonExistentToken();
        return string(abi.encodePacked(super.uri(tokenID), Strings.toString(tokenID), ".json"));
    }

    /**
     * @dev {ERC165-supportsInterface} Adding IERC2981
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return 
            ERC1155.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

}