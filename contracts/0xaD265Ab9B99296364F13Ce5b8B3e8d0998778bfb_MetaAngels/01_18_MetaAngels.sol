// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title Meta Angels Contract
 * @author Gabriel Cebrian (https://twitter.com/gabceb)
 * @notice This contract handles minting and loaning of Meta Angels ERC721 tokens.
 */
contract MetaAngels is ERC721A, ReentrancyGuard, Ownable, Pausable {
    event Loan(address indexed _from, address indexed to, uint _value);
    event LoanRetrieved(address indexed _from, address indexed to, uint value);

    using ECDSA for bytes32;
    using Strings for uint256;

    // Internal vars
    address acct10 = 0x884e96163CD9dCF1425192F8C8Aa6BC63b19f058;
    address acct90 = 0xB6900b1eCf5eEda7E10E5e137Eb927dF5A0159Af;

    // Public vars
    string public baseTokenURI;
    uint256 public price = 0.125 ether;

    // Immutable vars
    uint256 public immutable maxSupply;

    /**
     * @notice Construct a Meta Angels instance
     * @param name Token name
     * @param symbol Token symbol
     * @param baseTokenURI_ Base URI for all tokens
     * @param maxSupply_ Max Supply of tokens
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        uint256 maxSupply_
    ) ERC721A(name, symbol) {
        require(maxSupply_ > 0, "INVALID_SUPPLY");
        baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
    }

    // Used to validate authorized mint addresses
    address private signerAddress = 0x290Df62917EAb5b06E3c04a583E2250A0B46d55f;

    mapping (address => uint256) public totalMintsPerAddress;
    mapping (address => uint256) public totalLoanedPerAddress;
    mapping (uint256 => address) public tokenOwnersOnLoan;
    uint256 private currentLoanIndex = 0;

    bool public loansPaused = true;
    bool public isSaleActive = false;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * To be updated by contract owner to allow for the loan functionality to be toggled
     */
    function setLoansPaused(bool _loansPaused) public onlyOwner {
        require(loansPaused != _loansPaused, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        loansPaused = _loansPaused;
    }

    /**
     * To be updated by contract owner to allow updating the mint price
     */
    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        require(price != _newMintPrice, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        price = _newMintPrice;
    }

    /**
     * To be updated by contract owner to allow gold and silver lists members
     */
    function setSaleState(bool _saleActiveState) public onlyOwner {
        require(isSaleActive != _saleActiveState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        isSaleActive = _saleActiveState;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    /**
     * Returns all the token ids owned by a given address
     */
    function ownedTokensByAddress(address owner) external view returns (uint256[] memory) {
        uint256 totalTokensOwned = balanceOf(owner);
        uint256[] memory allTokenIds = new uint256[](totalTokensOwned);
        for (uint256 i = 0; i < totalTokensOwned; i++) {
            allTokenIds[i] = (tokenOfOwnerByIndex(owner, i));
        }
        return allTokenIds;
    }

    /**
     * Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    /**
     * When the contract is paused, all token transfers are prevented in case of emergency.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal whenNotPaused override(ERC721A) {
        super._beforeTokenTransfers(from, to, tokenId, quantity);

        require(tokenOwnersOnLoan[tokenId] == address(0), "Cannot transfer token on loan");
    }

    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender, uint256 maximumAllowedMints) private pure returns (bytes32) {
        return keccak256(abi.encode(sender, maximumAllowedMints));
    }

    /**
     * @notice Allow for minting of tokens up to the maximum allowed for a given address.
     * The address of the sender and the number of mints allowed are hashed and signed
     * with the server's private key and verified here to prove whitelisting status.
     */
    function mint(
        bytes32 messageHash,
        bytes calldata signature,
        uint256 mintNumber,
        uint256 maximumAllowedMints
    ) external payable virtual nonReentrant {
        require(isSaleActive, "SALE_IS_NOT_ACTIVE");
        require(totalMintsPerAddress[msg.sender] + mintNumber <= maximumAllowedMints, "MINT_TOO_LARGE");
        require(hashMessage(msg.sender, maximumAllowedMints) == messageHash, "MESSAGE_INVALID");
        require(verifyAddressSigner(messageHash, signature), "SIGNATURE_VALIDATION_FAILED");
        // Imprecise floats are scary. Front-end should utilize BigNumber for safe precision, but adding margin just to be safe to not fail txs
        require(msg.value >= ((price * mintNumber) - 0.0001 ether) && msg.value <= ((price * mintNumber) + 0.0001 ether), "INVALID_PRICE");

        uint256 currentSupply = totalSupply();

        require(currentSupply + mintNumber <= maxSupply, "NOT_ENOUGH_MINTS_AVAILABLE");

        totalMintsPerAddress[msg.sender] += mintNumber;

        _safeMint(msg.sender, mintNumber);

        if (currentSupply + mintNumber >= maxSupply) {
            isSaleActive = false;
        }
    }

    /**
     * @notice Allow owner to send `mintNumber` tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256 mintNumber) external onlyOwner {
        require((totalSupply() + (receivers.length * mintNumber)) <= maxSupply, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber);
        }
    }


    // *******
    // *******
    //
    // Meta Angels Loan Functionality
    //
    // *******
    // *******

    /**
     * @notice Allow owner to loan their tokens to other addresses
     */
    function loan(uint256 tokenId, address receiver) external nonReentrant {
        require(loansPaused == false, "Token loans are paused");
        require(ownerOf(tokenId) == msg.sender, "Trying to loan not owned token");
        require(receiver != address(0), "ERC721: transfer to the zero address");
        require(tokenOwnersOnLoan[tokenId] == address(0), "Trying to loan a loaned token");

        // Transfer the token
        safeTransferFrom(msg.sender, receiver, tokenId);

        // Add it to the mapping of originally loaned tokens
        tokenOwnersOnLoan[tokenId] = msg.sender;

        // Add to the owner's loan balance
        uint256 loansByAddress = totalLoanedPerAddress[msg.sender];
        totalLoanedPerAddress[msg.sender] = loansByAddress + 1;
        currentLoanIndex = currentLoanIndex + 1;

        emit Loan(msg.sender, receiver, tokenId);
    }

    /**
     * @notice Allow owner to loan their tokens to other addresses
     */
    function retrieveLoan(uint256 tokenId) external nonReentrant {
        address borrowerAddress = ownerOf(tokenId);
        require(borrowerAddress != msg.sender, "Trying to retrieve their owned loaned token");
        require(tokenOwnersOnLoan[tokenId] == msg.sender, "Trying to retrieve token not on loan");

        // Remove it from the array of loaned out tokens
        delete tokenOwnersOnLoan[tokenId];

        // Subtract from the owner's loan balance
        uint256 loansByAddress = totalLoanedPerAddress[msg.sender];
        totalLoanedPerAddress[msg.sender] = loansByAddress - 1;
        currentLoanIndex = currentLoanIndex - 1;
        
        // Transfer the token back
        _safeTransfer(borrowerAddress, msg.sender, tokenId);

        emit LoanRetrieved(borrowerAddress, msg.sender, tokenId);
    }

    /**
     * Returns the total number of loaned angels
     */
    function totalLoaned() public view returns (uint256) {
        return currentLoanIndex;
    }

    /**
     * Returns the loaned balance of an address
     */
    function loanedBalanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Balance query for the zero address");
        return totalLoanedPerAddress[owner];
    }

    /**
     * Returns all the token ids owned by a given address
     */
    function loanedTokensByAddress(address owner) external view returns (uint256[] memory) {
        require(owner != address(0), "Balance query for the zero address");
        uint256 totalTokensLoaned = loanedBalanceOf(owner);
        uint256 mintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;

        uint256[] memory allTokenIds = new uint256[](totalTokensLoaned);
        for (uint256 i = 0; i < mintedSoFar && tokenIdsIdx != totalTokensLoaned; i++) {
            if (tokenOwnersOnLoan[i] == owner) {
                allTokenIds[tokenIdsIdx] = i;
                tokenIdsIdx++;
            }
        }

        return allTokenIds;
    }

    /**
     * @notice Allow contract owner to withdraw funds to its own account.
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Allow contract owner to withdraw to specific accounts
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;

        require(payable(acct10).send(balance / 100 * 10));
        require(payable(acct90).send(balance / 100 * 90));
    }
}