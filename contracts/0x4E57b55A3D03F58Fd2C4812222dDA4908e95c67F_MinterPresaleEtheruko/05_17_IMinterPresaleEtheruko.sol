//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMinterPresaleEtheruko {
    event SetFeeTo(address _feeTo);
    event GrantAdmin(address _account);
    event RevokeAdmin(address _account);
    event SetGenesis(address _etherukoGenesis);
    event SetPresaleAmount(uint256 _presaleAmount);
    event SetPresalePrice(uint256 _presalePrice);
    event PresaleMint(address _to, uint256 _amount);
    event InitPresale(uint256 _presaleAmount, uint256 _presaleNowAmount);
}