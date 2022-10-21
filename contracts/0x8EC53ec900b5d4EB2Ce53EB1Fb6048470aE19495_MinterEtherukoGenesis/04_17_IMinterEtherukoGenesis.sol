//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../EtherukoGenesis.sol";

interface IMinterEtherukoGenesis {
    event SetFeeTo(address _feeTo);
    event GrantAdmin(address _account);
    event RevokeAdmin(address _account);
    event GrantWhitelist(address[] _wallet);
    event RevokeWhitelist(address[] _wallet);
    event SetMaxTxLimit(uint256 _maxTxLimit);
    event SetMaxSale(uint256 _maxSale);
    event SetTeamSaleLeft(uint256 _teamSaleLeft);
    event GrantOG(address[] _wallet);
    event GrantWlAndOg(address[] _wallet);
    event RevokeOG(address[] _wallet);
    event SetWlPrice(uint256 _wlPrice);
    event SetPbPrice(uint256 _pbPrice);
    event SetWhiteListSaleMaxCount(uint8 _whiteListSaleMaxCount);
    
    event OgFreeMint(address indexed _buyer, uint256 _nowAmount);
    event StartSale(bool _onSale);
    event StopSale(bool _onSale);
    event WlPriceMint(
        address indexed _buyer,
        uint256 _amount,
        uint256 _nowAmount,
        uint256 _price
    );
    event PbPriceMint(
        address indexed _buyer,
        uint256 _amount,
        uint256 _nowAmount,
        uint256 _price
    );
    event TeamMint(
        address[] to,
        uint256[] _amount
    );

    function setGenesis(EtherukoGenesis _etherukoGenesis) external;

    function setFeeTo(address payable _feeTo) external;

    function setMaxTxLimit(uint256 _maxTxLimit) external;

    function setMaxSale(uint256 _maxSale) external;

    function setTeamSaleLeft(uint256 _teamSaleLeft) external;

    function isAdmin(address account) external view returns (bool);

    function grantAdmin(address account) external;

    function revokeAdmin(address account) external;

    function isWhitelist(address account) external view returns (bool);

    function grantWhiteList(address[] calldata _wallet) external;

    function revokeWhiteList(address[] calldata _wallet) external;

    function isOg(address account) external view returns (bool);

    function grantOG(address[] calldata _wallet) external;

    function grantWlAndOg(address[] calldata _wallet) external;

    function revokeOG(address[] calldata _wallet) external;

    function setWlPrice(uint256 _wlPrice) external;

    function setPbPrice(uint256 _pbPrice) external;

    function setWhiteListSaleMaxCount(uint8 _whiteListSaleMaxCount) external;

    function startSale() external;

    function stopSale() external;

    function ogFreeMint() external;

    function wlPriceMint(uint256 _amount) external payable;

    function pbPriceMint(uint256 _amount) external payable;

    function teamMint(address[] calldata to, uint256[] calldata _amount) external;
}