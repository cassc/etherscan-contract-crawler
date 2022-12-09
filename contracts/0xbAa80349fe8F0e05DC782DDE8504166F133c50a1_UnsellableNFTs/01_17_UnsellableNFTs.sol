// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface ERCBase {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);
}

contract UnsellableNFTs is ReentrancyGuard, Pausable, Ownable {
    bytes4 constant _ERC721 = 0x80ac58cd;
    bytes4 constant _ERC1155 = 0xd9b67a26;

    // what we pay the customer per NFT
    uint256 public nftPaymentAmount = 7000 gwei; // ~ $0.01 as of 2022-10-19

    // what the customer pays us per NFT
    uint256 public serviceFee = 0 ether;

    // the max a customer will pay us per transaction
    uint256 public serviceFeeCap = 0 ether;

    // where the NFTs and service fees go
    address payable public ourWallet =
        payable(0xcc03C4cA24abAB228b79fc6f98834a6e5638336a);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() external payable nonReentrant {}

    function withdrawBalance() external onlyOwner nonReentrant {
        payable(msg.sender).call{value: address(this).balance}("");
    }

    function setOurWalletAddress(address ourWalletAddress) public onlyOwner {
        require(ourWalletAddress != address(0x0), "Address must not be 0x0");
        ourWallet = payable(ourWalletAddress);
    }

    function getOurWalletAddress() public view returns (address) {
        return ourWallet;
    }

    function setNftPaymentAmount(uint256 _nftPaymentAmount)
        public
        onlyOwner
        nonReentrant
    {
        require(
            _nftPaymentAmount >= 0 gwei && _nftPaymentAmount < 0.1 ether,
            "NFT payment amount must be a reasonable number"
        );
        nftPaymentAmount = _nftPaymentAmount;
    }

    function getNftPaymentAmount() public view returns (uint256) {
        return nftPaymentAmount;
    }

    function setServiceFeeAmount(uint256 _serviceFee)
        public
        onlyOwner
        nonReentrant
    {
        require(
            _serviceFee >= 0 gwei && _serviceFee < 1 ether,
            "Service fee amount must be a reasonable number"
        );
        serviceFee = _serviceFee;
    }

    function getServiceFeeAmount() public view returns (uint256) {
        return serviceFee;
    }

    function setServiceFeeCapAmount(uint256 _serviceFeeCap)
        public
        onlyOwner
        nonReentrant
    {
        require(
            _serviceFeeCap >= 0 gwei && _serviceFeeCap < 1 ether,
            "Service fee cap amount must be a reasonable _serviceFeeCap"
        );
        serviceFeeCap = _serviceFeeCap;
    }

    function getServiceFeeCapAmount() public view returns (uint256) {
        return serviceFeeCap;
    }

    function sellNfts(
        address[] calldata tokenContracts,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable nonReentrant whenNotPaused {
        require(
            tokenContracts.length > 0,
            "One or more token contracts required"
        );

        require(
            tokenContracts.length == tokenIds.length &&
                tokenIds.length == amounts.length,
            "Equal array sizes required for contracts/tokenIds/amounts"
        );

        uint256 numberOfNfts = 0;
        for (uint256 i = 0; i < tokenContracts.length; i++) {
            require(amounts[i] > 0, "Token amounts must be greater than zero");
            numberOfNfts += tokenIds.length * amounts[i];
        }
        require(numberOfNfts <= 500, "Must be selling 500 or fewer NFTs");

        uint256 totalServiceFeeAmount = 0;
        for (uint256 i = 0; i < tokenContracts.length; i++) {
            if (ERCBase(tokenContracts[i]).supportsInterface(_ERC721)) {
                totalServiceFeeAmount += serviceFee;
            } else {
                totalServiceFeeAmount += serviceFee * amounts[i];
            }
        }

        if (totalServiceFeeAmount > serviceFeeCap) {
            totalServiceFeeAmount = serviceFeeCap;
        }

        require(
            msg.value == totalServiceFeeAmount,
            "Incorrect service fee payment amount"
        );

        // Transfer service fee to our wallet
        (bool received, ) = ourWallet.call{value: msg.value}("");
        require(received, "Failed to transfer service fee to wallet");

        ERCBase tokenContract;
        uint256 totalAmountToPayCustomer = 0;

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            tokenContract = ERCBase(tokenContracts[i]);

            require(
                tokenContract.isApprovedForAll(msg.sender, address(this)),
                "Token contract not approved for transfers"
            );

            totalAmountToPayCustomer += nftPaymentAmount * amounts[i];

            require(
                address(this).balance > totalAmountToPayCustomer,
                "Not enough funds to pay customer"
            );

            if (tokenContract.supportsInterface(_ERC721)) {
                ERC721(tokenContracts[i]).transferFrom(
                    msg.sender,
                    ourWallet,
                    tokenIds[i]
                );
            } else {
                ERC1155(tokenContracts[i]).safeTransferFrom(
                    msg.sender,
                    ourWallet,
                    tokenIds[i],
                    amounts[i],
                    ""
                );
            }
        }

        (bool sent, ) = payable(msg.sender).call{
            value: totalAmountToPayCustomer
        }("");
        require(sent, "Payment to customer failed");
    }
}