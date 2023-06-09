//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


interface ILightbulbman {
    //EVENTS
    event Mint(address indexed _user, uint256 indexed _tokenId, string _tokenURI);
    event ToggleSaleState(bool _state);
    event BaseURIChanged(string _baseURI);
    event WithdrawalWalletChanged(address payable _newWithdrawalWallet);
    event MintPriceChanged(uint256 _mintPrice);
    event WhitelistBuy(address _user, uint8 _amount);
    event ToggleWhitelistSaleState(bool _whitelistSaleActive);
    event WhiteListAdded(address _user, uint8 _maxMint);
    event NameChange(uint256 indexed lightbulbmanIndex, string newName);
    event FinalizeStartingIndex(uint256 startingIndex);
    event WhitelistStatusChanged(address _user, uint8 _maxMint);

}