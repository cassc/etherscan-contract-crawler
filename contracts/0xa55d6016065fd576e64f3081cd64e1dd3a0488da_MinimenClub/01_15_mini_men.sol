// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@    //
//    @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////

import "../token/ERC721/extensions/ERC721OwnerEnumerable.sol";
import "../utils/ECDSA.sol";

error InvalidSignature();
error NoContractMinting();
error NoContractClaiming();
error NotTokenOwner();
error OverMintLimit();
error OverSupplyLimit();
error SenderNotApproved();
error TokenAlreadyClaimed();
error TokenNotClaimable();
error TransferTooEarlyAfterLock();

interface IMintable {
    function mint(address claimer) external;
}

/**
 * MinimenClub is the first contract in a pair of contracts that allow for a legendary claimable mint.
 * This first contract has many tokens with a select number of the first tokenIds having the ability to claim a
 * token from the second (legendary) collection. Tokens from this collection are minted with onchain randomness
 * meaning that ever call to {mint} will give a random token from the entire collection.
 *
 * Claiming a token not only gives the user a token from the legendary collection, but also a new tokenURI from
 * this collection.
 *
 * Additionally, this contract places a 5 minute transfer hold on recently claimed tokens. This is done to prevent a frontrunner
 * from selling an unclaimed rare token on a marketplace and frontrunning the sale of the transaction with a {claim} call
 * which would result in the buyer recieving a rare token that already has the legendary token claimed even though it
 * would be unclaimed before they initiated the sale.
 */
contract MinimenClub is ERC721OwnerEnumerable {
    using ECDSA for bytes32;
    using Strings for uint256;

    // Used to prevent sellers from front-running a Claim transaction before
    // another user's buy transaction can go through.
    uint256 public constant POST_CLAIM_LOCK_TIME = 300;
    uint256 public constant LEGENDARY_COUNT = 69;
    uint256 public constant MAX_TOKENS = 3333;

    // Address of the wallet that can approve other addresses to mint
    address public mintApproverAddress;

    // This must be the address of contract which follows IMintable interface.
    address public legendaryTokenAddress;

    // Used to maintain constant time on-chain random ID generation
    uint256[MAX_TOKENS] private indices;

    // Used to track if a token is claimed, and block immediate transfers after claim
    mapping(uint256 => uint256) internal _claimedTimestamp;

    // Token metadata for all tokens when they are first minted
    string public tokenDirectory;

    // Token metadata for the legendary tokens that are claimable
    string public claimedDirectory;

    constructor(
        string memory name,
        string memory symbol,
        string memory _tokenDirectory,
        string memory _claimedDirectory,
        uint256 royalty,
        address royaltyWallet,
        address mintApprover
    ) ERC721(name, symbol) {
        tokenDirectory = _tokenDirectory;
        claimedDirectory = _claimedDirectory;
        mintApproverAddress = mintApprover;
        _setRoyaltyBPS(royalty);
        _setRoyaltyWallet(royaltyWallet);
        _setTokenRange(1, MAX_TOKENS);
    }

    /**
     * @dev allows owner to update royalties following EIP-2981 at anytime
     */
    function updateRoyalty(uint256 royaltyBPS, address royaltyWallet)
        external
        onlyOwner
    {
        _setRoyaltyBPS(royaltyBPS);
        _setRoyaltyWallet(royaltyWallet);
    }

    /**
     * @dev Display either the original or the claimed metadata of a token based on if
     * the token is claimable or not
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        if (_claimedTimestamp[tokenId] != 0) {
            return
                string(
                    abi.encodePacked(claimedDirectory, "/", tokenId.toString())
                );
        }
        return
            string(abi.encodePacked(tokenDirectory, "/", tokenId.toString()));
    }

    /**
     * @dev Updates the address that must approve of wallets for mint.
     */
    function setMintApprover(address approver) external onlyOwner {
        mintApproverAddress = approver;
    }

    /**
     * @dev Returns if a given tokenId is both a legendary token and has not been claimed yet.
     */
    function isClaimable(uint256 tokenId) public view returns (bool) {
        return
            tokenId - _minTokenId < LEGENDARY_COUNT &&
            _claimedTimestamp[tokenId] == 0;
    }

    /**
     * @dev Quick function to view only claimable tokens rather than using the Enumerable methods.
     * This will enable us to get all claimable tokens an address has in constant time porpotional
     * to the LEGENDARY_COUNT rather than MAX_TOKENS
     */
    function getClaimableTokens(address owner)
        public
        view
        returns (uint256[] memory)
    {
        if (owner == address(0)) revert QueryForZeroAddress();

        uint256[] memory tokenIds = new uint256[](LEGENDARY_COUNT);
        uint256 index = 0;

        for (uint256 i = _minTokenId; i <= _minTokenId + LEGENDARY_COUNT; i++) {
            address tokenOwner = _owners[i];
            if (tokenOwner == owner && isClaimable(i)) {
                tokenIds[index] = i;
                index++;
            }
        }
        return tokenIds;
    }

    /**
     * @dev Updates the token metadata of all tokens.
     */
    function setTokenDirectory(string memory _tokenDirectory)
        external
        onlyOwner
    {
        tokenDirectory = _tokenDirectory;
    }

    /**
     * @dev Updates the token metadata of claimed tokens.
     */
    function setClaimedDirectory(string memory _claimedDirectory)
        external
        onlyOwner
    {
        claimedDirectory = _claimedDirectory;
    }

    /**
     * @dev Sets the address of the Legendary contract which this contract will mint from when
     * a user claims a token. That contract is created to allow this and only this contract to
     * mint from it.
     */
    function setLegendaryTokenAddress(address _legendaryTokenAddress)
        external
        onlyOwner
    {
        legendaryTokenAddress = _legendaryTokenAddress;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Makes sure tokens which were just claimed cannot be transfered to prevent
     * front-running a claim transaction before a sale.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (
            _claimedTimestamp[tokenId] != 0 &&
            _claimedTimestamp[tokenId] + POST_CLAIM_LOCK_TIME > block.timestamp
        ) {
            revert TransferTooEarlyAfterLock();
        }
    }

    /**
     * @dev Function to allow the owner to airdrop tokens to any address. Not checkedd to save gas but
     * it should be limited to around 100 - 150 mints per transaction max.
     *
     * Note: airdropping to an address from this function prevents that address from being able to mint
     * through the mint method because it will count towards an address's numberMinted
     */
    function ownerMint(address receiver, uint256 amount) external onlyOwner {
        if (totalSupply() >= _tokenLimit()) revert OverSupplyLimit();

        if (totalSupply() + amount > _tokenLimit()) {
            _mintRandomIndex(receiver, _tokenLimit() - totalSupply());
        } else {
            _mintRandomIndex(receiver, amount);
        }
    }

    /**
     * @dev Hash an order that we need to check against the signature to see who the signer is.
     * see {_hashForAllowList} to see the hash that needs to be signed.
     */
    function _hashToCheckForApproved(address approved)
        internal
        view
        returns (bytes32)
    {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(address(this), block.chainid, approved))
            );
    }

    /**
     * @dev Free mint method which checks that the address is one that has the correct signature from
     * the mintApproverAddress AND the sender matches that address.
     *
     * Only Wallet Addresses are allowed to mint and any contracts will be denied.
     */
    function mint(address approvedWallet, bytes memory signature) external {
        if (totalSupply() >= _tokenLimit()) revert OverSupplyLimit();
        if (_addressData[_msgSender()].numberMinted > 0) revert OverMintLimit();
        if (approvedWallet != _msgSender()) revert SenderNotApproved();
        if (Address.isContract(_msgSender())) revert NoContractMinting();

        bytes32 hash = _hashToCheckForApproved(approvedWallet);
        if (hash.recover(signature) != mintApproverAddress) {
            revert InvalidSignature();
        }

        _mintRandomIndex(approvedWallet, 1);
    }

    /**
     * @dev Claims an array of tokenIds that all must be owned by the message sender and must
     * be claimable. Claiming does the following:
     * - changes the tokenURI of the tokenId
     * - makes a tokenId no longer claimable
     * - mints a random token from the legendary collection to the claimer
     *
     * Only Wallet Addresses are allowed to claim and any contracts will be denied.
     */
    function claim(uint256[] memory tokenIds) external {
        if (Address.isContract(_msgSender())) revert NoContractClaiming();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != _msgSender()) revert NotTokenOwner();
            if (!isClaimable(tokenId)) revert TokenNotClaimable();

            _claimedTimestamp[tokenId] = block.timestamp;
            IMintable(legendaryTokenAddress).mint(_msgSender());
        }
    }

    /// @notice Generates a pseudo random index of our tokens that has not been used so far
    function _mintRandomIndex(address claimer, uint256 amount) internal {
        uint256 supplyLeft = _tokenLimit() - totalSupply();

        for (uint256 i = 0; i < amount; i++) {
            // generate a random index from the remaining supply
            uint256 index = _random(supplyLeft);
            uint256 tokenAtPlace = indices[index];

            uint256 tokenId;
            // if we havent stored a replacement token...
            if (tokenAtPlace == 0) {
                //... we just return the current index
                tokenId = index;
            } else {
                // else we take the replace we stored with logic below
                tokenId = tokenAtPlace;
            }

            // get the highest token id we havent handed out
            uint256 lastTokenAvailable = indices[supplyLeft - 1];
            // we need to store a replacement token for the next time we roll the same index
            // if the last token is still unused...
            if (lastTokenAvailable == 0) {
                // ... we store the last token as index
                indices[index] = supplyLeft - 1;
            } else {
                // ... we store the token that was stored for the last token
                indices[index] = lastTokenAvailable;
            }

            _mint(claimer, tokenId + _minTokenId);
            supplyLeft--;
        }
    }

    /// @notice Generates a pseudo random number based on arguments with decent entropy
    /// @param max The maximum value we want to receive
    /// @return A random number less than the max
    function _random(uint256 max) internal view returns (uint256) {
        uint256 rand = uint256(
            keccak256(
                abi.encode(
                    _msgSender(),
                    block.difficulty,
                    block.timestamp,
                    blockhash(block.number - 1)
                )
            )
        );
        return rand % max;
    }
}