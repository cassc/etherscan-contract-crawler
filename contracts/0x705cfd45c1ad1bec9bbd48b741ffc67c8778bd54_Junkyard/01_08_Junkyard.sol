// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

error JunkyardAddressNotSet();
error MaxTransfersPerTxReached();
error TokensNotApprovedForTransfer();
error InvalidFeeAmount();
error ERC1155JunkGroupMismatchedLengths();

struct ERC721JunkGroup {
    address contractAddress;
    uint256[] tokenIds;
}

struct ERC1155JunkGroup {
    address contractAddress;
    uint256[] tokenIds;
    uint256[] amounts;
}

/**
 * Contract that allows users to bulk sell NFTs at a fixed price
 */
contract Junkyard is ReentrancyGuard, Pausable, Ownable {
    address public junkyard = address(0); // The address, to which NFTs are transferred
    uint256 public buyPrice = 1 gwei; // Price paid to the caller for each NFT
    uint256 public fee = 0.0006 ether; // Service fee paid by caller for each junked NFT
    uint256 public maxTransfersPerTx = 100; // Maximum NFTs that can be junked at once

    /// Mappings, needed for the referral code system to work
    /// Get user's address by referral code
    mapping(string => address) private userByReferralCode;
    /// Get referral code by user's address
    mapping(address => string) public referralCodeByUser;
    /// How many NFTs were sold via the user's referral code
    mapping(address => uint256) public referralSalesByUser;

    constructor() {
        _pause();
    }

    /// Sets junkyard address
    function setJunkyard(address _junkyard) public onlyOwner {
        junkyard = _junkyard;
    }

    /// Sets buy price
    function setBuyPrice(uint256 _buyPrice) public onlyOwner {
        buyPrice = _buyPrice;
    }

    /// Sets fee
    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    /// Sets maximum transfers limit
    function setMaxTransfers(uint256 _maxTransfersPerTx) public onlyOwner {
        maxTransfersPerTx = _maxTransfersPerTx;
    }

    /// Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// Unpauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// Performs the act of "junking" the given NFTs. It will:
    ///     1. Transfer the ERC721s and ERC1155 to the "junkyard" address
    ///     2. Pay out 1 gwei for each token transferred
    /// @param erc721sToJunk All ERC721 tokens being transfered, grouped by contract address
    /// @param erc1155sToJunk All ERC1155 tokens being transfered, grouped by contract address
    /// @param referralCode The referral code. If not needed, pass an empty string
    function junkNFTs(
        ERC721JunkGroup[] calldata erc721sToJunk,
        ERC1155JunkGroup[] calldata erc1155sToJunk,
        string calldata referralCode
    ) external payable whenNotPaused nonReentrant {
        if (junkyard == address(0)) revert JunkyardAddressNotSet();

        uint256 transfersInTx;
        uint256 numTokensTransferred;

        // handle the transfer of ERC721s
        for (uint256 i = 0; i < erc721sToJunk.length; i++) {
            ERC721JunkGroup calldata junkGroup = erc721sToJunk[i];
            IERC721 tokenContract = IERC721(junkGroup.contractAddress);

            transfersInTx += junkGroup.tokenIds.length;

            if (transfersInTx > maxTransfersPerTx)
                revert MaxTransfersPerTxReached();

            numTokensTransferred += junkGroup.tokenIds.length;
            for (uint256 j = 0; j < junkGroup.tokenIds.length; j++) {
                tokenContract.transferFrom(
                    _msgSender(),
                    junkyard,
                    junkGroup.tokenIds[j]
                );
            }
        }

        if (transfersInTx + erc1155sToJunk.length > maxTransfersPerTx)
            revert MaxTransfersPerTxReached();
        
        // handle the transfer of ERC1155s
        for (uint256 i = 0; i < erc1155sToJunk.length; i++) {
            ERC1155JunkGroup calldata junkGroup = erc1155sToJunk[i];

            if (junkGroup.amounts.length != junkGroup.tokenIds.length)
                revert ERC1155JunkGroupMismatchedLengths();

            IERC1155 tokenContract = IERC1155(junkGroup.contractAddress);

            for (uint256 j = 0; j < junkGroup.tokenIds.length; j++) {
                numTokensTransferred += junkGroup.amounts[j];
            }
            tokenContract.safeBatchTransferFrom(
                _msgSender(),
                junkyard,
                junkGroup.tokenIds,
                junkGroup.amounts,
                ""
            );
        }

        if (msg.value != numTokensTransferred * fee) revert InvalidFeeAmount();

        (bool sent, ) = payable(_msgSender()).call{
            value: numTokensTransferred * buyPrice
        }("");
        require(sent, "Failed to send ether");

        if (
            keccak256(abi.encodePacked(referralCode)) != keccak256(abi.encodePacked(""))
            && userByReferralCode[referralCode] != address(0)
        ) {
            referralSalesByUser[userByReferralCode[referralCode]] += numTokensTransferred;
        }
    }

    receive() external payable {}

    /// Withdraws the balance
    function withdrawBalance() external onlyOwner {
        (bool sent, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to withdraw ether");
    }

    /// Sets the referral code for the user
    /// @param code The referral code
    function setReferralCode(string calldata code) public whenNotPaused {
        require(userByReferralCode[code] == address(0), "Referral code already exists");
        require(
            keccak256(abi.encodePacked(referralCodeByUser[msg.sender])) == keccak256(abi.encodePacked("")),
            "User already has a referral code"
        );
        userByReferralCode[code] = msg.sender;
        referralCodeByUser[msg.sender] = code;
    }
}