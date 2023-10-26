// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Society membership is captured in this contract.
//
// It is an NFT (ERC721) with a few custom enhancements:
//
//  1. Captcha Scheme
//      We use a captcha scheme to prevent bots from minting.
//        #isProbablyHuman() - matches a captcha signature signed elsewhere
//
//  2. Money-back Warranty
//      We promise your money back if we don't get enough members:
//               #withdraw() - locks the money unless there are >=2000 members
//                 #refund() - returns your money during refunding
//                             and it's enabled automatically after time has elapsed
//      (see "Refund Warranty Process" below for more details)
//
//  3. Minting Limits
//      A single wallet may only mint 2 memberships.
//
//  4. Founding Team
//      During contract construction, we mint 7 tokens,
//      one for each member of the founding team and the first artist.
//
//  5. Gold/Standard Tokens
//      The first 2,000 wallets to mint get a Gold token, these are
//      identified by having an ID number 1-2000.
//
//  Refund Warranty Process
//
//  If 2,000+ memberships are sold by Feb 18 there are no refunds.
//  But if less than 2,000 are sold by Feb 18, then the refund
//  implementation operates within three phases:
//
//   Phase 1: Jan 18 - Feb 18
//     After contract creation, until the sales deadline or >2,000 sold,
//     all minting fees remain locked in the contract.
//       - The Society's #withdraw() is disabled
//       - Member's #refund() is also disabled
//
//   Phase 2: Feb 18 - Mar 18
//     After the sales deadline (if <2,000 sold), until the refund deadline,
//     Members may claim a #refund() for the sale price.
//       - The Society's #withdraw() is still disabled
//       - Member's #refund() is now enabled
//
//   Phase 3: after Mar 18
//     After the refund deadline, Members can no longer claim a #refund()
//     and The Society can #withdraw() any unrefunded fees.
//       - The Society's #withdraw() is enabled
//       - Member's #refund() is disabled

contract SocietyMember is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    // This indicates what mode this contract is operating in.
    // See #updateMode() for implementation
    enum Mode {
        // Happy path:
        SellingPreThreshold, // before sales deadline < 2,000 sold
        SellingPostThreshold, // > 2,000 sold, < 5,000 sold
        SoldOut, // 5,000 sold
        // Sad path:
        Refunding, // < 2,000 sold, after sales deadline before refund deadline
        ClosingAfterRefundPeriod // < 2,000 sold, after refund deadline
    }

    // This is the sale price of each membership.
    uint256 public constant SALE_PRICE = 0.3 ether;

    // A single wallet may only mint 2 memberships.
    uint256 public constant MINTS_PER_WALLET = 2;

    // There can be only 5,000 members (2,000 gold).
    // NOTE: permanently fixed upon contract creation
    uint256 public immutable MAXIMUM_TOTAL_MEMBER_COUNT;
    uint256 public immutable MAXIMUM_GOLD_MEMBER_COUNT;

    // There need to be 2,000 members to proceed.
    // NOTE: permanently fixed upon contract creation
    uint256 public immutable ENOUGH_MEMBERS_TO_PROCEED;

    // Sales must exceed 2,000 members for the Society to proceed.
    // If we fail to get 2,000 members then the first #refund() request
    // after this time will start refunding.
    //   See note re "Refund Warrant Process" for more details.
    // NOTE: permanently fixed upon contract creation
    uint256 public immutable SALES_DEADLINE; // timestamp in seconds

    // If we fail to get 2,000 members then Members have until
    // this time to claim their #refund()
    //   See note re "Refund Warrant Process" for more details.
    // NOTE: permanently fixed upon contract creation
    uint256 public immutable REFUND_DEADLINE; // timestamp in seconds

    // During contract construction, we mint 7 tokens,
    // one for each member of the founding team and the first artist.
    // NOTE: permanently fixed upon contract creation
    uint256 private immutable FOUNDING_TEAM_COUNT;

    // This indicates the current mode (selling, refunding etc)
    Mode public mode;

    // We generate the next token ID by incrementing these counters.
    // Gold tokens have an ID <= 2,000.
    uint16 private goldIds; // 1 - 2000
    uint16 private standardIds; // 2001 - 5000

    // This tracks mint counts to help limit mints per wallet.
    mapping(address => uint8) private mintCountsByAddress;

    // This tracks gold token count per owner.
    mapping(address => uint16) private goldBalances;

    // This contains the base URI (e.g. "https://example.com/tokens/")
    // that is used to produce a URI for the metadata about
    // each token (e.g. "https://example.com/tokens/1234")
    string private baseURI;

    // For exchanges that support ERC2981, this sets our royalty rate.
    // NOTE: whereas "percent" is /100, this uses "per mille" which is /1000
    uint256 private royaltyPerMille;

    // To combat bots, minting requests include a captcha signed elsewhere.
    // To verify the captcha, we compare its signature with this signer.
    address private captchaSigner;

    // To enable gas-free listings on OpenSea we integrate with the proxy registry.
    address private openSeaProxyRegistry;
    // The Society can disable gas-free listings in case OpenSea is compromised.
    bool private isOpenSeaProxyEnabled = true;

    constructor(
        address[] memory foundingTeam,
        uint256 _maximumTotalMemberCount,
        uint256 _maximumGoldMemberCount,
        uint256 _enoughMembersToProceed,
        uint256 _salesDeadline,
        uint256 _refundDeadline,
        uint256 _royaltyPerMille,
        address _captchaSigner,
        address _openSeaProxyRegistry
    ) ERC721("Collector", "COLLECTOR") {
        require(_enoughMembersToProceed <= _maximumTotalMemberCount);
        require(_maximumGoldMemberCount <= _maximumTotalMemberCount);
        require(_salesDeadline <= _refundDeadline);

        MAXIMUM_TOTAL_MEMBER_COUNT = _maximumTotalMemberCount;
        MAXIMUM_GOLD_MEMBER_COUNT = _maximumGoldMemberCount;
        ENOUGH_MEMBERS_TO_PROCEED = _enoughMembersToProceed;
        SALES_DEADLINE = _salesDeadline;
        REFUND_DEADLINE = _refundDeadline;
        royaltyPerMille = _royaltyPerMille;
        captchaSigner = _captchaSigner;
        openSeaProxyRegistry = _openSeaProxyRegistry;
        mode = Mode.SellingPreThreshold;

        // Grant the founding team the first 7 tokens.
        FOUNDING_TEAM_COUNT = foundingTeam.length;
        for (uint256 i = 0; i < foundingTeam.length; i++) {
            _safeMint(foundingTeam[i], generateTokenId(true));
        }
    }

    //
    // Public Read Methods
    //

    // See how many memberships have been minted by the specified wallet.
    // NOTE: this is not the same as ownership
    function getMintCountByAddress(address minter_)
        external
        view
        returns (uint8)
    {
        return mintCountsByAddress[minter_];
    }

    // How many gold tokens have been issued.
    function goldSupply() external view returns (uint256) {
        return goldIds;
    }

    // Returns the number of gold tokens held by `owner`.
    function goldBalanceOf(address owner) external view returns (uint256) {
        return goldBalances[owner];
    }

    //
    // Public Write Methods
    //

    // This mints a single token to the sender.
    // It requires a `captcha` which is used to verify that
    // the sender is probably human and came here via our web flow.
    function mint(bytes memory captcha, uint8 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(numberOfTokens > 0, "missing number of tokens to mint");
        updateMode();
        require(
            mode == Mode.SellingPreThreshold ||
                mode == Mode.SellingPostThreshold,
            "minting is not available"
        );
        require(
            memberCount() + numberOfTokens <= MAXIMUM_TOTAL_MEMBER_COUNT,
            "not enough memberships remaining"
        );
        require(
            msg.value == SALE_PRICE * numberOfTokens,
            "incorrect ETH payment amount"
        );
        require(isProbablyHuman(captcha, msg.sender), "you seem like a robot");
        uint8 mintCount = mintCountsByAddress[msg.sender];
        require(
            mintCount + numberOfTokens <= MINTS_PER_WALLET,
            "you can only mint two memberships per wallet"
        );

        mintCountsByAddress[msg.sender] = mintCount + numberOfTokens;

        // Only the first mint from this wallet can get a gold token.
        bool couldBeGold = mintCount == 0;
        _safeMint(msg.sender, generateTokenId(couldBeGold));
        for (uint256 i = 1; i < numberOfTokens; i++) {
            _safeMint(msg.sender, generateTokenId(false));
        }
    }

    // If we fail to get >2,000 members
    // members can call this to receive their ETH back.
    // NOTE: after the sales deadline this is enabled automatically.
    function refund(uint256 tokenId) external nonReentrant {
        require(
            ownerOf(tokenId) == msg.sender,
            "only the owner may claim a refund"
        );
        require(
            tokenId > FOUNDING_TEAM_COUNT,
            "founding team tokens do not get a refund"
        );
        updateMode();
        require(mode == Mode.Refunding, "refunding is not available");

        _burn(tokenId);
        payable(msg.sender).transfer(SALE_PRICE);
    }

    //
    // Admin Methods
    //

    // This allows the Society to withdraw funds from the treasury.
    // NOTE: this is locked until there are at least 2,000 members.
    function withdraw() external onlyOwner {
        updateMode();
        require(
            mode == Mode.SellingPostThreshold ||
                mode == Mode.SoldOut ||
                mode == Mode.ClosingAfterRefundPeriod,
            "membership fees are locked until there are enough members (or after refund period)"
        );
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // This allows the Society to withdraw any received ERC20 tokens.
    // NOTE: There are no plans for this contract to receive any ERC20 tokens.
    //       This method exists to avoid the sad scenario where someone
    //       accidentally sends tokens to this address and the tokens get stuck.
    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // The society can update the baseURI for metadata
    //  e.g. if there is a hosting change
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // The society can update the ERC2981 royalty rate
    // NOTE: whereas "percent" is /100, this uses "per mille" which is /1000
    function setRoyalty(uint256 _royaltyPerMille) external onlyOwner {
        royaltyPerMille = _royaltyPerMille;
    }

    // The society can update the signer of the captcha used to secure #mint().
    function setCaptchaSigner(address _captchaSigner) external onlyOwner {
        captchaSigner = _captchaSigner;
    }

    // The society can disable gas-less listings for security in case OpenSea is compromised.
    function setOpenSeaProxyEnabled(bool isEnabled) external onlyOwner {
        isOpenSeaProxyEnabled = isEnabled;
    }

    //
    // Interface Override Methods
    //

    // This hooks into the ERC721 implementation
    // it is used by `tokenURI(..)` to produce the full thing.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    ///
    /// IERC2981 Implementation
    ///

    /**
     * @dev See {IERC2981-royaltyInfo}.
     * This exposes the ERC2981 royalty rate.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "not a valid token");
        return (address(this), (salePrice * royaltyPerMille) / 1000);
    }

    ///
    /// IERC721Enumerable Implementation (partial)
    ///   NOTE: to reduce gas costs, we don't implement tokenOfOwnerByIndex()
    ///

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256) {
        return memberCount();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        if (_index >= goldIds) {
            _index = MAXIMUM_GOLD_MEMBER_COUNT + (goldIds - _index);
        }
        require(_exists(_index + 1), "bad token index");
        return _index + 1;
    }

    // This hooks into transfers to track gold balances.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (tokenId > MAXIMUM_GOLD_MEMBER_COUNT) {
            // We only do the extra bookkeeping
            // when a gold token is being transferred.
            return;
        }
        if (from != address(0)) {
            goldBalances[from] -= 1;
        }
        if (to != address(0)) {
            goldBalances[to] += 1;
        }
    }

    // This hooks into approvals to allow gas-free listings on OpenSea.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (isOpenSeaProxyEnabled) {
            ProxyRegistry registry = ProxyRegistry(openSeaProxyRegistry);
            if (address(registry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    ///
    /// IERC165 Implementation
    ///

    /**
     * @dev See {IERC165-supportsInterface}.
     * This implements ERC165 which announces our other supported interfaces:
     *   - ERC2981 (royalty info)
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        // NOTE: we don't include IERC721Enumerable
        //       because ours is only a partial implementation.
        return super.supportsInterface(interfaceId);
    }

    //
    // Private Helper Methods
    //

    // This tries to prevent robots from minting a membership.
    // The `captcha` contains a signature (generated via web captcha flow)
    // that was made using the Society's private key.
    //
    // This method checks the signature to see:
    //  - if it was signed by the Society's key and
    //  - if it was for the current msg.sender
    function isProbablyHuman(bytes memory captcha, address sender)
        private
        view
        returns (bool)
    {
        // First we recreate the same message that was originally signed.
        // This is equivalent to how we created it elsewhere:
        //      message = ethers.utils.solidityKeccak256(
        //                  ["string", "address"],
        //                  ["member", sender]);
        bytes32 message = keccak256(abi.encodePacked("member", sender));

        // Now we can see who actually signed it
        address signer = message.toEthSignedMessageHash().recover(captcha);

        // And finally check if the signer was us!
        return signer == captchaSigner;
    }

    // This updates the current mode based on the member count and the time.
    // The contract calls this before any use of the current mode.
    // See "Refund Warranty Process" above for more details.
    function updateMode() private {
        uint256 count = memberCount();
        if (count >= MAXIMUM_TOTAL_MEMBER_COUNT) {
            mode = Mode.SoldOut;
        } else if (count >= ENOUGH_MEMBERS_TO_PROCEED) {
            mode = Mode.SellingPostThreshold;
        } else {
            // count < enoughMembersToProceed
            // When there are not enough members to proceed
            // then the mode depends on the time.
            if (block.timestamp < SALES_DEADLINE) {
                // Before sales deadline
                mode = Mode.SellingPreThreshold;
            } else if (block.timestamp < REFUND_DEADLINE) {
                // After sales deadline, before refund deadline
                mode = Mode.Refunding;
            } else {
                // block.timestamp >= refundDeadline
                // After the refund deadline
                mode = Mode.ClosingAfterRefundPeriod;
            }
        }
    }

    // Create the next token ID to be used.
    // This is complicated because we shuffle between two ID ranges:
    //       1-2000 -> gold
    //    2001-5000 -> standard
    // So if it `couldBeGold` and there are gold remaining then we use the gold IDs.
    // Otherwise we use the standard IDs.
    function generateTokenId(bool couldBeGold) private returns (uint256) {
        if (couldBeGold && goldIds < MAXIMUM_GOLD_MEMBER_COUNT) {
            goldIds += 1;
            return goldIds;
        }
        standardIds += 1;
        return standardIds + MAXIMUM_GOLD_MEMBER_COUNT;
    }

    // Compute the total member count.
    function memberCount() private view returns (uint256) {
        return goldIds + standardIds;
    }
}

// These types define our interface to the OpenSea proxy registry.
// We use these to support gas-free listings.
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}