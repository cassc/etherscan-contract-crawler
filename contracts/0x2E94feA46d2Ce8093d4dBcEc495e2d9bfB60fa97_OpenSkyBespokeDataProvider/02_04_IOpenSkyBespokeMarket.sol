// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../libraries/BespokeTypes.sol';

interface IOpenSkyBespokeMarket {
    event CancelAllOffers(address indexed sender, uint256 nonce);

    event CancelMultipleOffers(address indexed sender, uint256[] nonces);

    event TakeBorrowOffer(
        bytes32 offerHash,
        uint256 indexed loanId,
        address indexed lender,
        address indexed borrower,
        uint256 nonce
    );

    event TakeBorrowOfferETH(
        bytes32 offerHash,
        uint256 indexed loanId,
        address indexed lender,
        address indexed borrower,
        uint256 nonce
    );

    event Repay(uint256 indexed loanId, address indexed borrower);

    event RepayETH(uint256 indexed loanId, address indexed borrower);

    event Foreclose(uint256 indexed loanId, address indexed lender);

    event FlashClaim(address indexed receiver, address sender, address indexed nftAddress, uint256 indexed tokenId);
    event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);
    event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);
    event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

    function takeBorrowOffer(
        BespokeTypes.BorrowOffer memory offerData,
        uint256 supplyAmount,
        uint256 supplyDuration
    ) external;

    function takeBorrowOfferETH(
        BespokeTypes.BorrowOffer memory offerData,
        uint256 supplyAmount,
        uint256 supplyDuration
    ) external payable;

    function repay(uint256 loanId) external;

    function repayETH(uint256 loanId) external payable;

    function foreclose(uint256 loanId) external;

    function cancelAllBorrowOffersForSender(uint256 minNonce_) external;

    function cancelMultipleBorrowOffers(uint256[] calldata offerNonces) external;

    function isValidNonce(address account, uint256 nonce) external view returns (bool);

    function getLoanData(uint256 loanId) external view returns (BespokeTypes.LoanData memory);

    function getStatus(uint256 loanId) external view returns (BespokeTypes.LoanStatus);

    function getBorrowInterest(uint256 loanId) external view returns (uint256);

    function getBorrowBalance(uint256 loanId) external view returns (uint256);

    function getPenalty(uint256 loanId) external view returns (uint256);

    /**
     * @notice Allows smart contracts to access the collateralized NFT within one transaction,
     * as long as the amount taken plus a fee is returned
     * @dev IMPORTANT There are security concerns for developers of flash loan receiver contracts that must be carefully considered
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashClaimReceiver interface
     * @param loanIds The ID of loan being flash-borrowed
     * @param params packed params to pass to the receiver as extra information
     **/
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external;

    /**
     * @notice Claim the ERC20 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive ERC20 token
     * @param amount The amount of the ERC20 token
     **/
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Claim the ERC721 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC721 token
     * @param ids The ID of the ERC721 token
     **/
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Claim the ERC1155 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC1155 tokens
     * @param ids The ID of the ERC1155 token
     * @param amounts The amount of the ERC1155 tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}