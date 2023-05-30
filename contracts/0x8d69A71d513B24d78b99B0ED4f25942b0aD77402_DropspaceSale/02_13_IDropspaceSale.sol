// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

interface IDropspaceSale {
    // OWNER ONLY
    function toggleSaleActive() external;
    function togglePresaleActive() external;
    function setBaseURI(string memory _baseURI) external;
    function setWithdrawalWallet(address payable _withdrawalWallet) external;
    function setDevWallet(address payable _devWallet) external;
    function setDevSaleShare(uint256 _devSaleShare) external;
    function setMintLimit(uint256 _mintLimit) external;
    function setSmartContractAllowance(bool _smartContractAllowance) external;
    function setTicketAddress(address _ticketAddress) external;
    function reserve(uint256 _amount) external;
    function withdraw() external;
    function toggleWhitelistSaleActive() external;
    function setWhitelistStatus(address _user, bool _status) external;
    function addWhitelist(address[] memory _userList) external;
    function clearTicket(uint256 _ticketId) external;
    function changeSupplyLimit(uint256 _supplyLimit) external;

    // EXTERNAL
    function buy(uint256 _amount) external payable;
    function presaleBuy(uint256 _ticketId, uint256 _amount) external payable;
    function whitelistBuy(uint256 _amount) external payable;

    // VIEW
    function totalSupply() view external returns(uint256);
    function supplyLimit() view external returns(uint256);
    function mintPrice() view external returns(uint256);
    function mintLimit() view external returns(uint256);
    function baseURI() view external returns(string memory);
    function saleActive() view external returns(bool);
    function presaleActive() view external returns(bool);
    function whitelistSaleActive() view external returns(bool);
    function smartContractAllowance() view external returns(bool);
    function devWallet() view external returns(address payable);
    function withdrawalWallet() view external returns(address payable);
    function ticketAddress() view external returns(address);
    function usedTickets(uint256 _ticketId) view external returns(bool);
    function whitelist(address _user) view external returns(bool);


    // EVENTS
    event Reserve(uint256 _amount);
    event Mint(address indexed _user, uint256 indexed _tokenId, string _tokenURI);
    event ToggleSaleState(bool _state);
    event BaseURIChanged(string _baseURI);
    event WithdrawalWalletChanged(address payable _newWithdrawalWallet);
    event DevWalletChanged(address payable _newDevWallet);
    event DevShareSaleChanged(uint256 _devSaleShare);
    event MintLimitChanged(uint256 _newMintLimit);
    event SmartContractAllowanceChanged(bool _newSmartContractAllowance);
    event TogglePresaleState(bool _preSaleState);
    event TicketAddressChanged(address _ticketAddress);
    event PresaleBuy(address _user, uint256 _ticketId, uint256 _amount);
    event WhitelistBuy(address _user, uint256 _amount);
    event WhitelistStatusChanged(address _user, bool _status);
    event ToggleWhitelistSaleState(bool _whitelistSaleActive);
    event SupplyLimitChanged(uint256 _supplyLimit);
    event TicketCleared(uint256 _ticketId);
    event WhiteListAdded(address _user, bool _status);

    receive() external payable;
}