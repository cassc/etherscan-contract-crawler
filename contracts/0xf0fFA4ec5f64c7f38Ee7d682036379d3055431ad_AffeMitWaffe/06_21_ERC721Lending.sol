// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice Implementation of ERC-721 NFT lending. The code below was written by using, as a
 *   starting point, the code made public by the Meta Angels NFT team (thank you to that team
 *   for making their code available for other projects to use!)
 *   The code has been modified in several ways, most importantly, that in the original
 *   implementation it was included in the main contract, whereas here we have abstracted the
 *   functionality into its own parent contract. Also, some additional events have been added,
 *   and checking whether loans are paused has been moved to a Modifier. In addition a function
 *   has been added to allow a borrower to initiate the return of a loan (rather than only 
 *   allowing for the original lender to 'recall' the loan.)
 *   Note that when lending, the meaning of terms like 'owner' become ambiguous, particularly
 *   because once a token is lent, as far as the ERC721 standard is concerned, the borrower is
 *   technically the owner. (In other words, the function 'ownerOf()' reqired by EIP-721 will
 *   return the address of the borrower while a token is lent. In the comments and variable names
 *   below we have tried to disambiguate by refering wherever possible to the original/rightful
 *   owner as the address that truly owns the NFT (the address that is able to recall the loan
 *   whenever they want.) However it is important to understand that once a token is loaned, to
 *   the outside world it will appear to be 'owned' by the borrower. From that perspective, the
 *   'owner' is the current borrower.
 * @dev if you would like to use this code and add a function that enumerates the tokens
 *   loaned out by a particular address (eg. it could be a function called
 *   loanedTokensByAddress(address rightfulOwner) ), you'll need to modify this contract so it
 *   inherits from ERC721Enumerable (because such a function will need access to the
 *   'totalSupply()' provided by the Enumerable contract. For the sake of simplicity, this
 *   contract does not currently implement a function that generates the enumeration of loaned
 *   tokens. However, note that a child contract can readily implement such a function, if it
 *   inherits from ERC721Enumerable.
 */
abstract contract ERC721Lending is ERC721, ReentrancyGuard {
    using Strings for uint256;

    mapping (address => uint256) public totalLoanedPerAddress;
    /**
    * @notice The mapping below keeps track of the original/rightful owner of each token, in other words,
    *   the address that truly owns the token (and has simply lent it out.) This is the address
    *   that is allowed to retrieve the token (to end the loan.)
    */
    mapping (uint256 => address) public mapFromTokenIdToRightfulOwner;
    uint256 internal counterGlobalLoans = 0;

    /**
     * @notice A variable that servers two purposes. 1) To allow the 'outside world' to easily query
     *   whether lendig is currently paused (or not), and 2) to hold the current state so that
     *   certain parts of the code can make decisons about the actions that are allowed (or not.)
     *   NOTE that when lending is paused, this restricts NEW loans from happening, but it does not
     *   restrict owners from reclaiming their loans, or from borrowers returning their borrowed tokens.
     */
    bool public loansAreCurrentlyPaused = false;

    /**
     * @notice Emitted when a loan is made.
     * @param from is the owner of the token (who is making the loan.)
     * @param to is the recipient of the loan.
     * @param item is the tokenID representing the token being lent.
     */
    event Loan(address indexed from, address indexed to, uint item);
    /**
     * @notice Emitted when a loan is recalled by its rightful/original owner.
     * @param byOriginalOwner is the original and rightful owner of the token.
     * @param fromBorrower is the address the token was lent out to.
     * @param item is the tokenID representing the token that was lent.
     */
    event LoanReclaimed(address indexed byOriginalOwner, address indexed fromBorrower, uint item);
    /**
     * @notice Emitted when a loan is returned by the borrower.
     * @param byBorrower is the address that token has been lent to.
     * @param toOriginalOwner is the original and rightful owner of the token.
     * @param item is the tokenID representing the token that was lent.
     */
    event LoanReturned(address indexed byBorrower, address indexed toOriginalOwner, uint item);
    /**
     * @notice Emitted when the pausing of loans is triggered.
     * @param account is the address that paused lending.
     */
    event LendingPaused(address account);
    /**
     * @notice Emitted when UNpausing of loans is triggered.
     * @param account is the address that UNpaused lending.
     */
    event LendingUnpaused(address account);


    /**
     * @notice Enables an owner to loan one of their tokens to another address. The loan is effectively
     *   a complete transfer of ownership. However, what makes it a 'loan' are a set of checks that do
     *   not allow the new owner to do certain things (such as further transfers of the token), and the
     *   ability of the lender to recall the token back into their ownership.
     * @param tokenId is the integer ID of the token to loan.
     * @param receiver is the address that the token will be loaned to.
     */
    function loan(address receiver, uint256 tokenId) external nonReentrant allowIfLendingNotPaused {
        require(msg.sender == ownerOf(tokenId), "ERC721Lending: Trying to lend a token that is not owned.");
        require(msg.sender != receiver, "ERC721Lending: Lending to self (the current owner's address) is not permitted.");
        require(receiver != address(0), "ERC721Lending: Loans to the zero 0x0 address are not permitted.");
        require(mapFromTokenIdToRightfulOwner[tokenId] == address(0), "ERC721Lending: Trying to lend a token that is already on loan.");

        // Transfer the token
        safeTransferFrom(msg.sender, receiver, tokenId);

        // Add it to the mapping (of loaned tokens, and who their original/rightful owners are.)
        mapFromTokenIdToRightfulOwner[tokenId] = msg.sender;

        // Add to the owner's loan balance
        uint256 loansByAddress = totalLoanedPerAddress[msg.sender];
        totalLoanedPerAddress[msg.sender] = loansByAddress + 1;
        counterGlobalLoans = counterGlobalLoans + 1;

        emit Loan(msg.sender, receiver, tokenId);
    }

    /**
     * @notice Allow the rightful owner of a token to reclaim it, if it is currently on loan.
     * @dev Notice that (in contrast to the loan() function), this function has to use the _safeTransfer()
     *   function as opposed to safeTransferFrom(). The difference between these functions is that
     *   safeTransferFrom requires taht msg.sender _isApprovedOrOwner, whereas _sefTransfer() does not. In
     *   this case, the current owner as far as teh ERC721 contract is concerned is the borrower, so
     *   safeTransferFrom() cannot be used.
     * @param tokenId is the integer ID of the token that should be retrieved.
     */
    function reclaimLoan(uint256 tokenId) external nonReentrant {
        address rightfulOwner = mapFromTokenIdToRightfulOwner[tokenId];
        require(msg.sender == rightfulOwner, "ERC721Lending: Only the original/rightful owner can recall a loaned token.");

        address borrowerAddress = ownerOf(tokenId);

        // Remove it from the array of loaned out tokens
        delete mapFromTokenIdToRightfulOwner[tokenId];

        // Subtract from the rightful owner's loan balance
        uint256 loansByAddress = totalLoanedPerAddress[rightfulOwner];
        totalLoanedPerAddress[rightfulOwner] = loansByAddress - 1;

        // Decrease the global counter
        counterGlobalLoans = counterGlobalLoans - 1;
        
        // Transfer the token back. (_safeTransfer() requires four parameters, so it is necessary to
        // pass an empty string as the 'data'.)
        _safeTransfer(borrowerAddress, rightfulOwner, tokenId, "");

        emit LoanReclaimed(rightfulOwner, borrowerAddress, tokenId);
    }

    /**
     * @notice Allow the borrower to return the loaned token.
     * @param tokenId is the integer ID of the token that should be retrieved.
     */
    function returnLoanByBorrower(uint256 tokenId) external nonReentrant {
        address borrowerAddress = ownerOf(tokenId);
        require(msg.sender == borrowerAddress, "ERC721Lending: Only the borrower can return the token.");

        address rightfulOwner = mapFromTokenIdToRightfulOwner[tokenId];

        // Remove it from the array of loaned out tokens
        delete mapFromTokenIdToRightfulOwner[tokenId];

        // Subtract from the rightful owner's loan balance
        uint256 loansByAddress = totalLoanedPerAddress[rightfulOwner];
        totalLoanedPerAddress[rightfulOwner] = loansByAddress - 1;

        // Decrease the global counter
        counterGlobalLoans = counterGlobalLoans - 1;
        
        // Transfer the token back
        safeTransferFrom(borrowerAddress, rightfulOwner, tokenId);

        emit LoanReturned(borrowerAddress, rightfulOwner, tokenId);
    }

    /**
     * @notice Queries the number of tokens that are currently on loan.
     * @return The total number of tokens presently loaned.
     */
    function totalLoaned() public view returns (uint256) {
        return counterGlobalLoans;
    }

    /**
     * @notice Function retrieves the number of tokens that an address currently has on loan.
     * @param rightfulOwner is the original/rightful owner of a token or set of tokens.
     * @return The total number of tokens presently loaned by a specific original owner.
     */
    function loanedBalanceOf(address rightfulOwner) public view returns (uint256) {
        require(rightfulOwner != address(0), "ERC721Lending: Balance query for the zero address");
        return totalLoanedPerAddress[rightfulOwner];
    }

    /**
     * @notice Function to pause lending.
     * @dev The function is internal, so it should be called by child contracts, which allows
     *   them to implement their own restrictions, such as Access Control.
     */
    function _pauseLending() internal allowIfLendingNotPaused {
        loansAreCurrentlyPaused = true;
        emit LendingPaused(msg.sender);
    }

    /**
     * @notice Function to UNpause lending.
     * @dev The function is internal, so it should be called by child contracts, which allows
     *   them to implement their own restrictions, such as Access Control.
     */
    function _unpauseLending() internal {
        require(loansAreCurrentlyPaused, "ERC721Lending: Lending of tokens is already in unpaused state.");
        loansAreCurrentlyPaused = false;
        emit LendingUnpaused(msg.sender);
    }

    /**
     * @notice This hook is arguably the most important part of this contract. It is the piece
     *   of code that ensures a borrower cannot transfer the token.
     * @dev Hook that is called before any token transfer. This includes minting
     *   and burning.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
        require(mapFromTokenIdToRightfulOwner[tokenId] == address(0), "ERC721Lending: Cannot transfer token on loan.");
    }

    /**
     * @dev Modifier to make a function callable only if lending is not paused.
     */
    modifier allowIfLendingNotPaused() {
        require(!loansAreCurrentlyPaused, "ERC721Lending: Lending of tokens is currently paused.");
        _;
    }

}