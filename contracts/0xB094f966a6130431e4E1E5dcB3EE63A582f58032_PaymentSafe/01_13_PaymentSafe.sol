// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PaymentSafe is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant BP = 10000;
    uint256 public nftContractOwnerPercentage;
    uint256 public tokenOwnerPercentage;
    address payable public nftContractOwner;
    address public nftContract;

    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    error PaymentError(address recipient, uint256 amount);

    constructor(
        address _nftContract,
        address _nftContractOwner,
        uint256 _nftContractOwnerPercentage,
        uint256 _tokenOwnerPercentage
    ) {
        // Needed to comment this because the nft deployment goes
        // require(
        //     _nftContract != address(0),
        //     "Invalid zero address nft contract"
        // );
        require(
            _nftContractOwner != address(0),
            "Invalid zero address nft contract owner"
        );
        nftContract = _nftContract;
        nftContractOwner = payable(_nftContractOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        changeRoyaltyDistribution(
            _nftContractOwnerPercentage,
            _tokenOwnerPercentage
        );
    }

    function distributeRoyalties(
        uint256[] memory amountsToPay,
        address payable[] memory recipients,
        IERC20[] memory paymentTokens
    ) external onlyRole(DISTRIBUTOR_ROLE) {
        require(
            amountsToPay.length == recipients.length &&
                amountsToPay.length == paymentTokens.length,
            "Inputs must have the same length"
        );
        for (uint256 i; i < amountsToPay.length; i++) {
            // ETH Payment
            if (paymentTokens[i] == IERC20(address(0))) {
                sendValue(recipients[i], amountsToPay[i]);
            }
            // ERC20 Token Payment
            else {
                paymentTokens[i].safeTransfer(recipients[i], amountsToPay[i]);
            }
        }
    }

    function getPaymentDetails(uint256 paidAmount, uint256 tokenId)
        external
        view
        returns (
            uint256 amountNftContractOwner,
            uint256 amountNftReceiver,
            address contractOwner,
            address nftRoyaltyReceiver
        )
    {
        amountNftContractOwner = (paidAmount * nftContractOwnerPercentage) / BP;
        amountNftReceiver = paidAmount - amountNftContractOwner;
        contractOwner = nftContractOwner;
        (nftRoyaltyReceiver, ) = IERC2981(nftContract).royaltyInfo(tokenId, 0);
    }

    function changeRoyaltyDistribution(
        uint256 _nftContractOwnerPercentage,
        uint256 _tokenOwnerPercentage
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _nftContractOwnerPercentage + _tokenOwnerPercentage == BP,
            "Royalties must add up to 100%"
        );
        nftContractOwnerPercentage = _nftContractOwnerPercentage;
        tokenOwnerPercentage = _tokenOwnerPercentage;
    }

    function changeNftContractOwner(address payable _nftContractOwner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _nftContractOwner != address(0),
            "Invalid zero address nft contract owner"
        );
        nftContractOwner = _nftContractOwner;
    }

    function changeNftContract(address payable _nftContract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _nftContract != address(0),
            "Invalid zero address nft contract"
        );
        nftContract = _nftContract;
    }

    function sendValue(address payable recipient, uint256 amount)
        private
        nonReentrant
    {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert PaymentError(recipient, amount);
    }

    // Allow to receive ETH
    receive() external payable {}

    fallback() external payable {}
}