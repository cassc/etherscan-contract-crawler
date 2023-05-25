// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./libs/Withdrawable.sol";
import "./libs/ERC721Opensea.sol";

contract FreshShrimpwear is ERC721Opensea {
    event DiscountUsed(address indexed receiver, uint256 discountValue);
    event FreebiesUsed(address indexed receiver, uint8 freebiesQty);

    event PhygitalClaimed(
        address indexed receiver,
        uint256 indexed tokenId,
        bytes32 userId
    );

    struct PhygitalClaim {
        address claimerAddress;
        uint256 claimedTokenId;
        bytes32 userId;
    }

    mapping(address => uint8) public freebiesData;
    mapping(uint256 => PhygitalClaim) public phygitalClaimData;

    uint256 public claimTotalQty = 0;
    uint256 public phygitalClaimTotalQty = 0;

    // =============== MINTING ===============
    /**
     * @dev Mint request
     * @param mintRequest The mint request
     */
    function getBatchMintPrice(
        MintRequest[] calldata mintRequest
    ) public pure returns (uint256) {
        uint256 totalMintPrice = 0;

        for (uint256 i = 0; i < mintRequest.length; i++) {
            totalMintPrice += mintRequest[i].price;
        }

        return totalMintPrice;
    }

    /**
     * @dev Single mint of NFT
     * @param mintRequest The mint request
     * @param signature The signature
     */
    function singleMint(
        MintRequest calldata mintRequest,
        bytes calldata signature
    ) internal isPublicSalesActive {
        // check if the signer is the MINTER_ROLE
        address signer = getAddressFromMintSignature(mintRequest, signature);
        require(
            hasRole(MINTER_ROLE, signer),
            "Signature must be signed by the minter"
        );

        // check mint signature
        require(checkMintSignature(mintRequest.uid), "Invalid mint signature");

        safeMint(msg.sender, mintRequest.uri);
        useMintSignature(mintRequest.uid);
    }

    /**
     * @dev Batch mint of NFT
     * @param mintRequests The array of mint requests
     * @param signatures The array of signatures
     */
    function batchMint(
        MintRequest[] calldata mintRequests,
        bytes[] calldata signatures,
        DiscountRequest calldata discountRequest,
        bytes calldata discountSignature
    ) external payable isPublicSalesActive {
        require(
            mintRequests.length == signatures.length,
            "Mint requests and signatures must be the same length"
        );

        uint256 totalPrice = getBatchMintPrice(mintRequests);

        if (discountRequest.totalDiscount > 0) {
            require(
                discountRequest.totalDiscount <=
                    getBatchMintPrice(mintRequests),
                "Discount must be less than or equal to the total price"
            );

            // Check if discount is valid
            address discountSigner = getAddressFromDiscountSignature(
                discountRequest,
                discountSignature
            );
            require(
                hasRole(MINTER_ROLE, discountSigner),
                "Discount Signature must be signed by the minter"
            );

            require(
                checkDiscountSignature(discountRequest.uid),
                "Invalid discount signature"
            );

            // check if discountRequest.orderId && mintRequest[i].orderId are the same
            for (uint256 i = 0; i < mintRequests.length; i++) {
                require(
                    mintRequests[i].orderId == discountRequest.orderId,
                    "Discount uid must be the same as mint uid"
                );
            }

            totalPrice -= discountRequest.totalDiscount;
        }

        require(msg.value >= totalPrice, "Insufficient ETH sent for minting");

        // Mint
        for (uint256 i = 0; i < mintRequests.length; i++) {
            singleMint(mintRequests[i], signatures[i]);
        }

        // Check if freebies are used
        uint8 totalFreebies = 0;
        for (uint256 i = 0; i < mintRequests.length; i++) {
            if (mintRequests[i].price == 0) {
                totalFreebies += 1;
            }
        }

        if (totalFreebies > 0) {
            require(
                checkAddressUsedFreebies(msg.sender) == false,
                "Address has already used freebies"
            );
            freebiesData[msg.sender] = totalFreebies;
            emit FreebiesUsed(msg.sender, totalFreebies);
        }

        if (discountRequest.totalDiscount > 0) {
            useDiscountSignature(discountRequest.uid);
            emit DiscountUsed(msg.sender, discountRequest.totalDiscount);
        }
    }

    /**
     * @dev Claim phygital NFT
     * @param phygitalClaimRequest The phygital claim request
     * @param signature The signature
     */
    function claimPhygital(
        PhygitalClaimRequest calldata phygitalClaimRequest,
        bytes calldata signature
    ) internal {
        // check if the signer is the MINTER_ROLE
        address signer = getAddressFromPhygitalClaimSignature(
            phygitalClaimRequest,
            signature
        );

        require(
            hasRole(MINTER_ROLE, signer),
            "Signature must be signed by the minter"
        );

        // check mint signature
        require(
            checkPhygitalClaimSignature(phygitalClaimRequest.uid),
            "Invalid mint signature"
        );

        require(
            phygitalClaimData[phygitalClaimRequest.tokenId].claimerAddress == address(0),
            "Phygital NFT has already been claimed"
        );

        _setTokenURI(phygitalClaimRequest.tokenId, phygitalClaimRequest.uri);
        usePhygitalClaimSignature(phygitalClaimRequest.uid);

        // Update the phygital claim data
        phygitalClaimData[phygitalClaimRequest.tokenId] = PhygitalClaim(
            msg.sender,
            phygitalClaimRequest.tokenId,
            phygitalClaimRequest.userId
        );

        // emit event
        emit PhygitalClaimed(
            msg.sender,
            phygitalClaimRequest.tokenId,
            phygitalClaimRequest.userId
        );
    }

    /**
     * @dev Batch claim phygital NFT
     * @param phygitalClaimRequests The array of phygital claim requests
     * @param signatures The array of signatures
     */
    function batchClaimPhygital(
        PhygitalClaimRequest[] calldata phygitalClaimRequests,
        bytes[] calldata signatures
    ) external {
        require(
            phygitalClaimRequests.length == signatures.length,
            "Phygital claim requests and signatures must be the same length"
        );

        for (uint256 i = 0; i < phygitalClaimRequests.length; i++) {
            claimPhygital(phygitalClaimRequests[i], signatures[i]);
        }
    }

    /**
     * Check if user has used freebies
     * @param _address The address of the user
     * @return true if user has used freebies, false otherwise
     */
    function checkAddressUsedFreebies(
        address _address
    ) public view returns (bool) {
        return freebiesData[_address] > 0;
    }

    // =============== Phygital Utility Functions ===============
    /**
     * @dev Get single phygital claim data
     * @param tokenId The ID of the token
     * @return The phygital claim data
     */
    function getSinglePhygitalClaimData(
        uint256 tokenId
    ) public view returns (PhygitalClaim memory) {
        return phygitalClaimData[tokenId];
    }

    /**
     * @dev Get all phygital claim data, iterate through the phygitalClaimData mapping with totalClaimed() length
     * @return The phygital claim data
     */
    function getAllPhygitalClaimData()
        public
        view
        returns (PhygitalClaim[] memory)
    {
        PhygitalClaim[] memory allPhygitalClaimData = new PhygitalClaim[](
            totalClaimed()
        );

        for (uint256 i = 0; i < totalClaimed(); i++) {
            allPhygitalClaimData[i] = phygitalClaimData[i];
        }

        return allPhygitalClaimData;
    }

    /**
     * @dev Get all phygital claim data by address, iterate through the phygitalClaimData mapping with totalClaimed() length
     * @param claimerAddress The address of the claimer
     * @return The phygital claim data
     */
    function getPhygitalClaimDataByAddress(
        address claimerAddress
    ) public view returns (PhygitalClaim[] memory) {
        PhygitalClaim[] memory allPhygitalClaimData = new PhygitalClaim[](
            totalClaimed()
        );

        uint256 count = 0;
        for (uint256 i = 0; i < totalClaimed(); i++) {
            if (phygitalClaimData[i].claimerAddress == claimerAddress) {
                allPhygitalClaimData[count] = phygitalClaimData[i];
                count++;
            }
        }

        return allPhygitalClaimData;
    }

    /**
     * @dev Returns the total amount of claimed phygital tokens
     * @return uint256 The total amount of claimed phygital tokens
     */
    function totalPhygitalClaimed() public view returns (uint256) {
        return phygitalClaimTotalQty;
    }

    // =============== Claim Utility Functions ===============
    /**
     * @dev Returns the total amount of claimed tokens
     * @return uint256 The total amount of claimed tokens
     */
    function totalClaimed() public view returns (uint256) {
        return claimTotalQty;
    }

    // =============== Owner Functions ===============
    // convert int to ether
    function convertIntToEther(uint256 amount) public pure returns (uint256) {
        return amount * 10 ** 18;
    }

    constructor(
        string memory name,
        string memory symbol,
        address minterAddress,
        uint256 publicSalesStartTimestamp
    ) ERC721(name, symbol) {
        _setupRole(MINTER_ROLE, minterAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        PUBLIC_SALES_START_TIMESTAMP = publicSalesStartTimestamp;
    }
}