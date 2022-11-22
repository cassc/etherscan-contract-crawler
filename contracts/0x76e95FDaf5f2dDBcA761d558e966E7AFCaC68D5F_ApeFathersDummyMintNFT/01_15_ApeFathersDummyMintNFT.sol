// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting ApeFathersDummyMintNFT tokens.
 */
contract ApeFathersDummyMintNFT is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981
{
    event Loan(address from, address to, uint256 tokenId);
    event LoanRetrieved(address from, address to, uint256 tokenId);

    address public royaltyAddress = 0x75c8CB112Eeb4D70B816fA1ea4EBA1Ee1DE56F64;
    // If true, new loans will be disabled but existing loans can be closed
    bool public loansPaused = true;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen = false;
    mapping(address => uint256) public totalLoanedPerAddress;
    mapping(uint256 => address) public tokenOwnersOnLoan;
    string public baseTokenURI =
        "ipfs://bafybeig7bod5kbx5e5bkoumrjjpzqtekoqkjnhfxbj6dsgetfuvbyra3g4/";
    uint256 private currentLoanIndex = 0;
    // Maximum supply of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 1;
    uint96 public royaltyFee = 10000;

    constructor() ERC721A("ApeFathersDummyMintNFT", "AFDMNFT") {
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "Cannot call from contract address");
        _;
    }

    /**
     * @dev Used to directly approve a token for transfers by the current msg.sender,
     * bypassing the typical checks around msg.sender being the owner of a given token
     * from https://github.com/chiru-labs/ERC721A/issues/395#issuecomment-1198737521
     */
    function _directApproveMsgSenderFor(uint256 tokenId) internal {
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, 6) // '_tokenApprovals' is at slot 6.
            sstore(keccak256(0x00, 0x40), caller())
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Wraps and exposes publicly _numberMinted() from ERC721A
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Freeze metadata so it can never be changed again
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        metadataFrozen = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, ERC4907A)
        returns (bool)
    {
        // Supports the following interfaceIds:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - IERC4907: 0xad092b5c
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC4907A.supportsInterface(interfaceId);
    }

    /**
     * @notice Allow owner to send 'mintNumber' tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256[] calldata mintNumber)
        external
        onlyOwner
    {
        require(
            receivers.length == mintNumber.length,
            "RECEIVERS_AND_MINT_NUMBERS_MUST_BE_SAME_LENGTH"
        );
        uint256 totalMint = 0;
        for (uint256 i = 0; i < mintNumber.length; i++) {
            totalMint += mintNumber[i];
        }
        require(totalSupply() + totalMint <= MAX_SUPPLY, "MINT_TOO_LARGE");
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber[i]);
        }
    }

    // Credit Meta Angels & Gabriel Cebrian

    modifier LoansNotPaused() {
        require(loansPaused == false, "Loans are paused");
        _;
    }

    /**
     * @notice To be updated by contract owner to allow for loan functionality to turned on and off
     */
    function setLoansPaused(bool _loansPaused) external onlyOwner {
        require(
            loansPaused != _loansPaused,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        loansPaused = _loansPaused;
    }

    /**
     * @notice Allow owner to loan their tokens to other addresses
     */
    function loan(uint256 tokenId, address receiver)
        external
        LoansNotPaused
        nonReentrant
    {
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER_OF_TOKEN");
        require(receiver != address(0), "CANNOT_TRANSFER_TO_ZERO_ADDRESS");
        require(
            tokenOwnersOnLoan[tokenId] == address(0),
            "CANNOT_LOAN_LOANED_TOKEN"
        );
        // Add it to the mapping of originally loaned tokens
        tokenOwnersOnLoan[tokenId] = msg.sender;
        // Add to the owner's loan balance
        totalLoanedPerAddress[msg.sender] += 1;
        currentLoanIndex += 1;
        // Transfer the token
        safeTransferFrom(msg.sender, receiver, tokenId);
        emit Loan(msg.sender, receiver, tokenId);
    }

    /**
     * @notice Allow owner to retrieve a loaned token
     */
    function retrieveLoan(uint256 tokenId) external nonReentrant {
        address borrowerAddress = ownerOf(tokenId);
        require(
            borrowerAddress != msg.sender,
            "BORROWER_CANNOT_RETRIEVE_TOKEN"
        );
        require(
            tokenOwnersOnLoan[tokenId] == msg.sender,
            "TOKEN_NOT_LOANED_BY_CALLER"
        );
        // Remove it from the array of loaned out tokens
        delete tokenOwnersOnLoan[tokenId];
        // Subtract from the owner's loan balance
        totalLoanedPerAddress[msg.sender] -= 1;
        currentLoanIndex -= 1;
        // Transfer the token back
        _directApproveMsgSenderFor(tokenId);
        safeTransferFrom(borrowerAddress, msg.sender, tokenId);
        emit LoanRetrieved(borrowerAddress, msg.sender, tokenId);
    }

    /**
     * @notice Allow contract owner to retrieve a loan to prevent malicious floor listings
     */
    function adminRetrieveLoan(uint256 tokenId) external onlyOwner {
        address borrowerAddress = ownerOf(tokenId);
        address loanerAddress = tokenOwnersOnLoan[tokenId];
        require(loanerAddress != address(0), "TOKEN_NOT_LOANED");
        // Remove it from the array of loaned out tokens
        delete tokenOwnersOnLoan[tokenId];
        // Subtract from the owner's loan balance
        totalLoanedPerAddress[loanerAddress] -= 1;
        currentLoanIndex -= 1;
        // Transfer the token back
        _directApproveMsgSenderFor(tokenId);
        safeTransferFrom(borrowerAddress, loanerAddress, tokenId);
        emit LoanRetrieved(borrowerAddress, loanerAddress, tokenId);
    }

    /**
     * Returns the total number of loaned tokens
     */
    function totalLoaned() public view returns (uint256) {
        return currentLoanIndex;
    }

    /**
     * Returns the loaned balance of an address
     */
    function loanedBalanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "CANNOT_QUERY_ZERO_ADDRESS");
        return totalLoanedPerAddress[owner];
    }

    /**
     * Returns all the token ids owned by a given address
     */
    function loanedTokensByAddress(address owner)
        external
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "CANNOT_QUERY_ZERO_ADDRESS");
        uint256 totalTokensLoaned = loanedBalanceOf(owner);
        uint256 mintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        uint256[] memory allTokenIds = new uint256[](totalTokensLoaned);
        for (
            uint256 i = 0;
            i < mintedSoFar && tokenIdsIdx != totalTokensLoaned;
            i++
        ) {
            if (tokenOwnersOnLoan[i] == owner) {
                allTokenIds[tokenIdsIdx] = i;
                tokenIdsIdx++;
            }
        }
        return allTokenIds;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override(ERC721A) whenNotPaused {
        require(
            tokenOwnersOnLoan[tokenId] == address(0),
            "CANNOT_TRANSFER_LOANED_TOKEN"
        );
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }
}