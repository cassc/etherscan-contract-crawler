// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

struct Deposit {
    uint8 accountType;
    address account;
    uint256 value;
}

interface IUtilityToken {
    function distribute() external returns (bool);

    function deposit(uint8 accountType_, address to_, uint256 amount_) external returns (uint256);

    function virtualMintDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) external returns (uint256);

    function mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_
    ) external payable returns (uint256);

    function mint(uint256 minBTK_) external payable returns (uint256 numBTK);

    function mintTo(address to_, uint256 minBTK_) external payable returns (uint256 numBTK);

    function destroyTokens(uint256 numBTK_) external returns (bool);

    function depositTokensOnBridges(uint8 routerVersion_, bytes calldata data_) external payable;

    function burn(uint256 amount_, uint256 minEth_) external returns (uint256 numEth);

    function burnTo(
        address to_,
        uint256 amount_,
        uint256 minEth_
    ) external returns (uint256 numEth);

    function getYield() external view returns (uint256);

    function getDepositID() external view returns (uint256);

    function getPoolBalance() external view returns (uint256);

    function getTotalTokensDeposited() external view returns (uint256);

    function getDeposit(uint256 depositID) external view returns (Deposit memory);

    function getLatestEthToMintTokens(uint256 numBTK_) external view returns (uint256 numEth);

    function getLatestEthFromTokensBurn(uint256 numBTK_) external view returns (uint256 numEth);

    function getLatestMintedTokensFromEth(uint256 numEth_) external view returns (uint256);

    function getMarketSpread() external pure returns (uint256);

    function getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) external pure returns (uint256 numEth);

    function getEthFromTokensBurn(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) external pure returns (uint256 numEth);

    function getMintedTokensFromEth(
        uint256 poolBalance_,
        uint256 numEth_
    ) external pure returns (uint256);
}