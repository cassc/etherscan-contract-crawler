// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

interface IEarlyMintersRoyalties  {

    event MinterWithdraw(address indexed minterAddress, uint256 indexed amount, uint256 indexed closeVersion);

    event EarlyMinterSet(address indexed minterAddress, uint256 indexed tokenId);

    event PeriodClosed(address indexed closer, uint256 amount, uint256 sells, uint256 unaryAmount, uint256 indexed period);

    struct History { uint256 period; uint256 amount; }

    function setEarlyMinter(address minter, uint256 tokenId) external;

    function getEarlyMinter(uint256 tokenId) external view returns (address);
    
    function getNumMintsByMinter(address minter) external view returns (uint256);

    function getBalance() external view returns (uint256);

    function getCurrentPeriod() external view returns (uint256);

    function getCurrentPeriodBalance() external view returns (uint256);

    function getPeriodBalance(uint256 period) external view returns (uint256);

    function getLastPeriodBalanceUnitaryAmount() external view returns (uint256);

    function getPeriodBalanceUnitaryAmount(uint256 period) external view returns (uint256);

    function getHistoryWithdrawForPeriod(address minter) external view returns (History[] memory);

    function closePeriod() external;

    function isSuspended() external view returns (bool);

    function suspend() external;

    function activate() external;

    function withdraw() external;

    function safeOwnerWithdraw() external;

    receive() external payable;
}