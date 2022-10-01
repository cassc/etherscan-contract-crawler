// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./ScratchNFT.sol";

contract Rental is Ownable, IERC721Receiver {
    ScratchNFT nft; //The collection of the NFT to lend
    uint256 public rentalPayment; //The amount of ETH the borrower must pay the lender in order to rent the NFT if returned on time
    uint256 public collateral; //The amount of additional ETH the lender requires as collateral

    // Events
    event RentalStarted();
    event NftReturned();
    event PayoutPeriodBegins();
    event PayoutPeriodEnds();

    // Errors
    error InsufficientValue();
    error Unauthorized();
    error InvalidState();
    error BadTimeBounds();
    error AlreadyDeposited();
    error NonTokenOwner();
    error NotAvailableNow();

    // Constructor
    constructor(ScratchNFT _nftAddress) {
        nft = _nftAddress;
    }

    // Struct to store the info about Leased NFT
    struct Lease {
        address lenderAddress; //The address of the original owner
        address borrowerAddress; //The address of the tempory borrower
        uint256 nftId; //The the id of the NFT within the collection
        uint256 dueDate; //The expiration time of the rental , @dev Measured as a future block timestamp
        uint256 collateralPayoutPeriod; //The amount of time the collateral will be linearly paid out over if the NFT isn't returned on time
        uint256 rentalStartTime; //The time when the rental contract officially begins
        uint256 collectedCollateral; //The amount of collateral collected by the lender
        bool nftIsDeposited; //Store if the NFT has been deposited
        bool ethIsDeposited; //Store if the borrower's required ETH has been deposited
        bool currentlyOnLease; //Store if NFT is on lease or not
    }

    // Maps tokenId to Lease
    mapping(uint256 => Lease) public book;

    // External Functions
    function depositNft(uint256 _nftId) external {
        uint256 tokenId = _nftId;

        // The ERC721 Token Depositer must be the lender
        if (msg.sender != nft.ownerOf(tokenId)) revert Unauthorized();

        // We don't accept double deposits
        if (book[tokenId].nftIsDeposited) revert AlreadyDeposited();

        nft.transferFrom(msg.sender, address(this), tokenId);

        book[tokenId].currentlyOnLease = false;
        book[tokenId].lenderAddress = msg.sender;
        book[tokenId].nftId = _nftId;
        book[tokenId].nftIsDeposited = true;
        book[tokenId].collectedCollateral = 0;
    }

    function depositEth(uint256 _tokenId) external payable {
        uint256 tokenId = _tokenId;

        if (tokenId < 15 || tokenId > 114) {
            rentalPayment = 0.010 ether;
            collateral = 0.250 ether;
        } else {
            rentalPayment = 0.005 ether;
            collateral = 0.125 ether;
        }

        // We don't accept double deposits
        if (book[tokenId].ethIsDeposited) revert AlreadyDeposited();

        if (msg.value < rentalPayment + collateral) revert InsufficientValue();

        if (!book[tokenId].nftIsDeposited) revert NotAvailableNow();

        // If the borrower sent too much ETH, immediately refund them the extra ETH they sent
        if (msg.value > rentalPayment + collateral) {
            payable(msg.sender).transfer(
                msg.value - (rentalPayment + collateral)
            );
        }

        nft.transferFrom(address(this), msg.sender, tokenId);
        payable(book[tokenId].lenderAddress).transfer(rentalPayment);

        // Setting dueDate, CollateralPayOutPeriod after NFT has been transfered
        uint256 _dueDate = block.timestamp + 2592000; // 1 Month
        uint256 _collateralPayoutPeriod = 1296000; // 15 days

        // uint256 _dueDate                 = block.timestamp + 600 ;  // 10 min
        // uint256 _collateralPayoutPeriod  = 300 ;          //  5 min

        emit RentalStarted();
        book[tokenId].currentlyOnLease = true;
        book[tokenId].rentalStartTime = block.timestamp;
        book[tokenId].borrowerAddress = msg.sender;
        book[tokenId].ethIsDeposited = true;
        book[tokenId].dueDate = _dueDate;
        book[tokenId].collateralPayoutPeriod = _collateralPayoutPeriod;
    }

    /// @notice Allows the lender to withdraw an nft if the borrower doesn't deposit
    function withdrawNft(uint256 _tokenId) external {
        uint256 tokenId = _tokenId;

        // Require that only the lender can withdraw the NFT
        if (msg.sender != book[tokenId].lenderAddress) revert Unauthorized();

        // Require that the NFT is in the contract
        if (!book[tokenId].nftIsDeposited) revert InvalidState();

        // Require that the NFT should not be on Lease
        if (book[tokenId].currentlyOnLease) revert InvalidState();

        // Send the nft back to the lender
        nft.transferFrom(address(this), book[tokenId].lenderAddress, tokenId);
        initializeState(tokenId);
    }

    /// @notice Allows the Borrower to return the borrowed NFT
    function returnNft(uint256 _tokenId) external {
        uint256 tokenId = _tokenId;

        if (tokenId < 15 || tokenId > 114) {
            rentalPayment = 0.010 ether;
            collateral = 0.250 ether;
        } else {
            rentalPayment = 0.005 ether;
            collateral = 0.125 ether;
        }

        // Require Caller should be the owner of NFT
        if (nft.ownerOf(tokenId) != msg.sender) revert Unauthorized();
        book[tokenId].currentlyOnLease = false;

        if (
            block.timestamp <
            book[tokenId].dueDate + book[tokenId].collateralPayoutPeriod
        ) {
            // Return the NFT from the borrower to the lender
            nft.transferFrom(msg.sender, book[tokenId].lenderAddress, tokenId);
        }

        // Check if the NFT has been returned on time
        if (block.timestamp <= book[tokenId].dueDate) {
            // Return the collateral to the borrower
            payable(book[tokenId].borrowerAddress).transfer(collateral);
        }
        // Check if the NFT has been returned during the collateral payout period
        if (block.timestamp > book[tokenId].dueDate) {
            // Send the lender the collateral they are owed
            withdrawCollateral(tokenId);
        }
        initializeState(tokenId);
    }

    /// @notice Transfers the amount of collateral owed to the lender
    /// @dev Anyone can call to withdraw collateral to lender
    function withdrawCollateral(uint256 _tokenId) public {
        uint256 tokenId = _tokenId;

        if (tokenId < 15 || tokenId > 114) {
            rentalPayment = 0.010 ether;
            collateral = 0.250 ether;
        } else {
            rentalPayment = 0.005 ether;
            collateral = 0.125 ether;
        }

        // This can only be called after the rental due date has passed and the payout period has begun
        if (block.timestamp <= book[tokenId].dueDate) revert InvalidState();

        uint256 tardiness = block.timestamp - book[tokenId].dueDate;
        uint256 payableAmount = 0;
        if (tardiness >= book[tokenId].collateralPayoutPeriod) {
            payableAmount = collateral;

            // The time to return th NFT has passed.So, NFT is not on Lease anymore and the borrower holds the NFT now.
            book[tokenId].currentlyOnLease = false;
        } else {
            payableAmount =
                (tardiness * collateral) /
                book[tokenId].collateralPayoutPeriod;
        }

        // Remove what the lender already collected
        payableAmount -= book[tokenId].collectedCollateral;

        // sstore the collected collateral
        book[tokenId].collectedCollateral += payableAmount;

        if (book[tokenId].currentlyOnLease) {
            payable(book[tokenId].lenderAddress).transfer(payableAmount);
        } else {
            payable(book[tokenId].lenderAddress).transfer(payableAmount);
            payable(book[tokenId].borrowerAddress).transfer(
                collateral - book[tokenId].collectedCollateral
            );

            if (
                block.timestamp >
                (book[tokenId].dueDate + book[tokenId].collateralPayoutPeriod)
            ) {
                initializeState(tokenId);
            }
        }
    }

    // Allows this contract to custody ERC721 Tokens
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function currentTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    // Get the number of  User's NFT on lease
    function usersBalance(address account) public view returns (uint256) {
        uint256 balance = 0;
        uint256 supply = nft.totalSupply();
        for (uint256 i = 1; i <= supply; i++) {
            if (book[i].lenderAddress == account && book[i].currentlyOnLease) {
                balance += 1;
            }
        }
        return balance;
    }

    // should never be used inside of transaction because of gas fee
    // Returns the array of token Id of user which are currently on lease
    function tokensOfOwner(address account)
        public
        view
        returns (uint256[] memory ownersTokens)
    {
        uint256 supply = nft.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (
                book[tokenId].lenderAddress == account &&
                book[tokenId].currentlyOnLease
            ) {
                tmp[index] = book[tokenId].nftId;
                index += 1;
            }
        }

        uint256[] memory tokensList = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokensList[i] = tmp[i];
        }

        return tokensList;
    }

    // Returns the array of token Id of user which he took on lease
    function rentalTokensOfOwner(address account)
        public
        view
        returns (uint256[] memory ownersTokens)
    {
        uint256 supply = nft.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (
                book[tokenId].borrowerAddress == account &&
                book[tokenId].currentlyOnLease
            ) {
                tmp[index] = book[tokenId].nftId;
                index += 1;
            }
        }

        uint256[] memory tokensList = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokensList[i] = tmp[i];
        }

        return tokensList;
    }

    // Should return list of tokenId, which are currently on lease
    function tokensOnLease()
        public
        view
        returns (uint256[] memory tokensCurrentlyOnLease)
    {
        uint256 supply = nft.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (book[tokenId].currentlyOnLease) {
                tmp[index] = book[tokenId].nftId;
                index += 1;
            }
        }

        uint256[] memory tokensList = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokensList[i] = tmp[i];
        }

        return tokensList;
    }

    // Should return list of tokenIds, which are available for lease
    function tokensAvailableForLease()
        public
        view
        returns (uint256[] memory tokensAvailableForLease)
    {
        uint256 supply = nft.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (book[tokenId].nftIsDeposited && !book[tokenId].ethIsDeposited) {
                tmp[index] = book[tokenId].nftId;
                index += 1;
            }
        }

        uint256[] memory tokensList = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokensList[i] = tmp[i];
        }

        return tokensList;
    }

    function initializeState(uint256 _tokenId) internal {
        uint256 tokenId = _tokenId;
        book[tokenId].lenderAddress = address(0);
        book[tokenId].borrowerAddress = address(0);
        book[tokenId].ethIsDeposited = false;
        book[tokenId].nftIsDeposited = false;
        book[tokenId].dueDate = 0;
        book[tokenId].collateralPayoutPeriod = 0;
        book[tokenId].rentalStartTime = 0;
        book[tokenId].collectedCollateral = 0;
    }
}