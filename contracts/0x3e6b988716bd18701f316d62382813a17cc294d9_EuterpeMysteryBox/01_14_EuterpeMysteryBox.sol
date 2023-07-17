// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./lib/ERC721AOperatorFilterable.sol";
import "./EuterpeMysteryBoxErrorsAndEvents.sol";

/**
 * @title EuterpeMysteryBox represents the Euterpe NFT Mystery Boxes which can redeem the Euterpe IP-NFTs.
 */
contract EuterpeMysteryBox is
    Ownable,
    ERC721AOperatorFilterable,
    EuterpeMysteryBoxErrorsAndEvents,
    ReentrancyGuard
{
    // max supply
    uint64 public constant MAX_SUPPLY = 1180;

    // mint limit per wallet
    uint64 public constant MINT_LIMIT_PER_WALLET = 1;

    // mint price
    uint256 public constant PRICE = 0.02 ether;

    // mapping from address to the number of minted tokens
    mapping(address => uint256) public numberMinted;

    // base token URI
    string public baseURI;

    // merkle root for the whitelist membership verification
    bytes32 public verificationRoot;

    // Euterpe Genesis SBT
    address public immutable SBT;

    // status
    Status public status;

    // status pipeline
    enum Status {
        INIT,
        WHITELIST_MINT,
        SBT_MINT,
        PUBLIC_MINT,
        REDEEMABLE,
        PAUSED
    }

    /**
     * @notice Make sure that the caller is user.
     */
    modifier callerIsUser() {
        if (tx.origin != _msgSender()) revert CallerIsNotUser();

        _;
    }

    /**
     * @notice Constructor.
     * @param baseURI_  The base token URI
     * @param status_ The initial status
     * @param sbt_ The Euterpe Genesis SBT address
     */
    constructor(
        string memory baseURI_,
        Status status_,
        address sbt_
    ) ERC721A("Euterpe Mystery Box", "EuterpeMysteryBox") {
        baseURI = baseURI_;
        status = status_;
        SBT = sbt_;
    }

    /**
     * @notice Mint tokens for the team operation.
     * @param quantity The quantity of tokens to be minted
     */
    function teamMint(uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();

        _safeMint(_msgSender(), quantity);
    }

    /**
     * @notice Claim tokens for the community operation.
     * @param recipients The recipient set
     * @param quantities The corresponding token quantity set
     */
    function claim(address[] calldata recipients, uint256[] calldata quantities)
        external
        onlyOwner
        nonReentrant
    {
        if (recipients.length != quantities.length) revert InvalidParams();

        for (uint256 i = 0; i < recipients.length; i++) {
            if (totalSupply() + quantities[i] > MAX_SUPPLY)
                revert MaxSupplyExceeded();

            _safeMint(recipients[i], quantities[i]);
        }
    }

    /**
     * @notice Mint tokens for the whitelisted accounts holding Euterpe Genesis SBT.
     * @param quantity The quantity of tokens to be minted
     * @param proof The membership proof
     */
    function whitelistMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        callerIsUser
    {
        if (status != Status.WHITELIST_MINT) revert WhitelistMintNotEnabled();
        if (!isWhitelisted(_msgSender(), proof)) revert NotWhitelisted();
        if (!isSBTHolder(_msgSender())) revert NotSBTHolder();

        _checkAndMint(_msgSender(), quantity);
    }

    /**
     * @notice Mint tokens for Euterpe Genesis SBT holders.
     * @param quantity The quantity of tokens to be minted
     */
    function sbtMint(uint256 quantity) external payable callerIsUser {
        if (status != Status.SBT_MINT) revert SBTMintNotEnabled();
        if (!isSBTHolder(_msgSender())) revert NotSBTHolder();

        _checkAndMint(_msgSender(), quantity);
    }

    /**
     * @notice Mint tokens publicly.
     * @param quantity The quantity of tokens to be minted
     */
    function publicMint(uint256 quantity) external payable callerIsUser {
        if (status != Status.PUBLIC_MINT) revert PublicMintNotEnabled();

        _checkAndMint(_msgSender(), quantity);
    }

    /**
     * @notice Redeem the Euterpe IP-NFTs with the specified mystery boxes.
     * The original mystery boxes will be BURNED.
     * @param tokenIds The ids of Euterpe Mystery Boxes with which to redeem
     */
    function redeem(uint256[] calldata tokenIds) external {
        if (status != Status.REDEEMABLE) revert RedemptionNotEnabled();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (ownerOf(tokenId) != _msgSender()) revert NotTokenOwner();

            _burn(tokenId, false);

            emit RedemptionRequested(_msgSender(), tokenId);
        }
    }

    /**
     * @notice Check if the given account is whitelisted.
     * @param account The destination account to be verified
     * @param proof The membership proof
     * @return whitelisted True if the given account is whitelisted, false otherwise
     */
    function isWhitelisted(address account, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                verificationRoot,
                keccak256(abi.encodePacked(account))
            );
    }

    /**
     * @notice Check if the given account is the qualified Euterpe Genesis SBT holder.
     * @param account The destination account
     * @return bool True if the given account is qualified, false otherwise
     */
    function isSBTHolder(address account) public view returns (bool) {
        return IERC721(SBT).balanceOf(account) > 0;
    }

    /**
     * @notice Set the current status.
     * @param status_ The current status
     */
    function setStatus(Status status_) external onlyOwner {
        status = status_;

        emit StatusChanged(uint8(status_));
    }

    /**
     * @notice Set the base token URI.
     * @param baseURI_ The base token URI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;

        emit BaseURISet(baseURI_);
    }

    /**
     * @notice Set the verification root.
     * @param verificationRoot_ The merkle root for the whitelist verification
     */
    function setVerificationRoot(bytes32 verificationRoot_) external onlyOwner {
        verificationRoot = verificationRoot_;
    }

    /**
     * @notice Withdraw balance.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert InsufficientBalance();

        payable(_msgSender()).transfer(balance);

        emit Withdrawal(_msgSender(), balance);
    }

    /**
     * @notice Check and mint `quantity` of tokens to the specified account.
     * @param to The specified recipient address
     * @param quantity The quantity of tokens to be minted
     */
    function _checkAndMint(address to, uint256 quantity) internal {
        if (numberMinted[to] + quantity > MINT_LIMIT_PER_WALLET)
            revert MintLimitPerWalletExceeded();
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();

        _paymentHandler(PRICE, quantity);

        numberMinted[to] += quantity;
        _safeMint(to, quantity);
    }

    /**
     * @notice Handle payment.
     * @param price The price per token
     * @param quantity The token quantity
     */
    function _paymentHandler(uint256 price, uint256 quantity) internal {
        uint256 total = price * quantity;
        if (msg.value < total) revert InsufficientValue();

        if (msg.value > total) {
            payable(_msgSender()).transfer(msg.value - total);
        }
    }

    /**
     * @notice Override the super._startTokenId() implementation.
     * @return startTokenId The starting id of tokens
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Override the super._baseURI() implementation.
     * @return baseURI The base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Query all tokens of the given owner.
     * @param owner The owner
     * @return tokenIds The ids of tokens of the owner
     */
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);

        TokenOwnership memory ownership;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
            ownership = _ownershipAt(i);

            if (ownership.burned) {
                continue;
            }

            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }

            if (currOwnershipAddr == owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }

        return tokenIds;
    }
}