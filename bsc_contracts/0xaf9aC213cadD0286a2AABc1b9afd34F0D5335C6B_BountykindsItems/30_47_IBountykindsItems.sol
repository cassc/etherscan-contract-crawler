// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IBountykindsItems {
    error NFT__InvalidType();
    error NFT__NotInBussiness();
    error NFT__InsufficientBalance();
    error NFT__LimitExceeded();
    error NFT__Expired();
    error NFT__Unauthorized();

    error NFT__SelfPermit();

    event NewBaseTokenURI(string baseTokenURI);

    event Registered(address indexed user, uint256 indexed typeNFT, uint256 tokenId, uint256 totalMint, uint256 soldByType, address paymentToken, uint256 paymentAmount);

    function setBaseTokenURI(string calldata baseTokenURI_) external;

    function buy(uint256 typeNFT_, uint256 quantity_) external payable;

    function setCreator(address creator_) external;

    function setLockUser(address account, bool status) external;

    function setupPrimarySaleRecipient(address recipient_) external;

    function setTransferFee(address token_, address beneficiary_, uint256 amount_) external;

    function setType(uint256 type_, address paymentToken_, uint256 price_, uint256 limit_, uint256 quantity_) external;

    function acceptBusinessAddresses(address[] calldata addresses_) external;

    function cancelBusinessAddresses(address[] calldata addresses_) external;

    function metadata(uint256 tokenId_) external view returns (address, uint256);

    function getTypeNFT(uint256 typeNFT) external view returns (address paymentToken, uint256 price, uint256 limit, uint256 unboxQuantity);
}