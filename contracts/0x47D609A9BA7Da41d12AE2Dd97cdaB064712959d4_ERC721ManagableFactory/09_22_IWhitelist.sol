// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IWhitelist { 

    event WhitelistSet(bool status);
    event WhitelistChanged();
    
    function addToWhitelist(address[] memory wallets) external;

    function deleteFromWhitelist(address[] memory wallets) external;

    function setWhitelistActive(bool active) external;

    function isWhitelisted(address wallet) external view returns (bool);

    function isWhitelistActive() external view returns (bool);

    function queryWhitelist(uint256 _cursor, uint256 _limit) external view returns (address[] memory);
}