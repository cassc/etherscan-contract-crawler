// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


struct SaleConfiguration {
    uint256 projectID; 
    address token;
    address payable[] wallets;
    uint16[] shares;

    uint256 maxMintPerTransaction;      // How many tokens a transaction can mint
    uint256 maxApprovedSale;            // Max sold in approvedsale across approvedsale eth
    uint256 maxApprovedSalePerAddress;  // Limit discounts per address
    uint256 maxSalePerAddress;

    uint256 approvedsaleStart;
    uint256 approvedsaleEnd;
    uint256 saleStart;
    uint256 saleEnd;

    uint256 fullPrice;
    uint256 maxUserMintable;
    address signer;
    uint256 fullDustPrice;
    bool    ethSaleEnabled;
    bool    erc777SaleEnabled;
    address erc777tokenAddress;
}


struct SaleInfo {
    SaleConfiguration config;
    uint256 userMinted;
    bool    approvedSaleIsActive;
    bool    saleIsActive;
}

struct SaleSignedPayload {
    uint256 projectID;
    uint256 chainID;  // 1 mainnet / 4 rinkeby / 11155111 sepolia / 137 polygon / 80001 mumbai
    bool    free;
    uint16  max_mint;
    address receiver;
    uint256 valid_from;
    uint256 valid_to;
    uint256 eth_price;
    uint256 dust_price;
    bytes   signature;
}

struct tokenPayload {
    uint256 numberOfCards;
    SaleSignedPayload payload;
}

interface ISaleContract {
    function UpdateSaleConfiguration(SaleConfiguration memory) external;
    function UpdateWalletsAndShares(address payable[] memory, uint16[] memory) external;
    function mint(uint256) external payable;
    function crossmint(uint256, address) external payable;
    function mint_approved(SaleSignedPayload memory _payload, uint256 _numberOfCards) external payable;
    function tellEverything() external view returns (SaleInfo memory);
    function getBlockTimestamp() external view returns(uint256);

    // ERC677
    function onTokenTransfer(address from, uint amount, bytes calldata userData) external;
    // ERC777
    function tokensReceived(address, address from, address, uint256 amount, bytes calldata userData, bytes calldata) external;
}