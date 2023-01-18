// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Counters.sol";

contract SunriseNFT is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    // Constant
    uint256 constant pricePerUnit = 0.15 ether;
    uint8 constant tierCount = 15;
    uint256 constant rewardsPerTier = 0.01 ether;

    // Token ID counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    event Mint(address indexed to, uint256 indexed referrer, uint256 qty);
    event Redeem(
        address indexed to,
        uint256 indexed tokenId,
        uint256 weiAmount
    );

    // Base URI information
    string private _prefixUri;

    // Mapping of token ID to child array of token ID
    // Max referral is 2
    mapping(uint256 => uint256[]) private _referralTree;

    // Mapping of token ID to parent token ID
    mapping(uint256 => uint256) private _parentOfToken;

    // Mapping of token ID to available rewards in wei
    mapping(uint256 => uint256) private _availableRewards;

    // Mapping of token ID to total rewards in wei
    mapping(uint256 => uint256) private _totalRewards;

    // Mapping of address to total withdrawn in wei
    mapping(address => uint256) private _withdrawnByAddress;

    // Total withdraw amount in wei
    uint256 private _totalWithdrawn;

    // Constructor
    constructor() ERC721("Sunrise NFT", "SNFT") {
        // Initial counter reset
        _tokenIdCounter.reset();

        // Set default value
        _prefixUri = "https://projectsunrise.net/api/token/";

        // Genisis minting to kickstart
        genesisMint();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _prefixUri;
    }

    // ************************ //
    // Internal function
    // ************************ //

    function shuffle(uint256[] memory numArray) private view {
        for (uint256 i = 0; i < numArray.length; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (numArray.length - i));
            uint256 temp = numArray[n];
            numArray[n] = numArray[i];
            numArray[i] = temp;
        }
    }

    function assignChild(uint256[] memory referrals, uint256 newReferral)
        private
    {
        uint256 maxLength = 16; // Suitable number to allow minter to double their earnings before randomly distribute to child
        uint256[] memory newReferrals = new uint256[](
            referrals.length * 2 > maxLength ? maxLength : referrals.length * 2
        );

        // Shuffle referrals
        shuffle(referrals);

        // Loop each referral
        for (uint256 i = 0; i < referrals.length; i++) {
            if (_referralTree[referrals[i]].length < 2) {
                // Assign new referral under current referralId
                _referralTree[referrals[i]].push(newReferral);
                _parentOfToken[newReferral] = referrals[i];
                return;
            } else {
                // Append child to new referrals list
                newReferrals[(2 * i)] = _referralTree[referrals[i]][0];
                newReferrals[(2 * i) + 1] = _referralTree[referrals[i]][1];

                // Stop operation if max length reach
                if (i == ((maxLength / 2) - 1)) {
                    break;
                }
            }
        }

        assignChild(newReferrals, newReferral);
    }

    function genesisMint() private {
        // Mint
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);

        // For genesis NFT, there is no parent NFT, so the referral is assigned to self.
        _parentOfToken[tokenId] = tokenId;
    }

    function distributeRewards(uint256 tokenId) private {
        uint256 referral = _parentOfToken[tokenId];

        for (uint8 i = 0; i < tierCount; i++) {
            _availableRewards[referral] += rewardsPerTier;
            _totalRewards[referral] += rewardsPerTier;

            // Update next referral for the loop
            referral = _parentOfToken[referral];
        }
    }

    function processRedeem(uint256 tokenId) private {
        // Check if caller is the token owner
        require(
            ownerOf(tokenId) == _msgSender(),
            "SunriseNFT: Not token owner"
        );

        // Check if referral met requirement
        require(
            _referralTree[tokenId].length >= 2,
            "SunriseNFT: Referral usage is less than 2"
        );

        // Calculate amount
        uint256 amount = _availableRewards[tokenId];
        require(amount > 0, "SunriseNFT: Redeem amount is 0");

        // Info update
        _availableRewards[tokenId] = 0;
        _withdrawnByAddress[_msgSender()] += amount;
        _totalWithdrawn += amount;

        // Execute payout
        address payable recipient = payable(_msgSender());
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "SunriseNFT: Unable to send value, recipient may have reverted"
        );

        // Event
        emit Redeem(_msgSender(), tokenId, amount);
    }

    function processMint(uint256 referralTokenId) private {
        // Mint
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);

        // Referral
        uint256[] memory referrals = new uint256[](1);
        referrals[0] = referralTokenId;
        assignChild(referrals, tokenId);

        // Distribute rewards
        distributeRewards(tokenId);
    }

    // ************************ //
    // External function
    // ************************ //

    function safeMint(uint256 referralTokenId, uint8 qty)
        public
        payable
        nonReentrant
    {
        // Check if referral is valid
        require(_exists(referralTokenId), "SunriseNFT: Invalid token ID");

        // Limit max qty to mint
        require(qty <= 16, "SunriseNFT: Quantity exceeds the maximum amount");

        // Check for payment amount
        require(
            msg.value >= (pricePerUnit * qty),
            "SunriseNFT: Payment not enough"
        );

        for (uint8 i = 0; i < qty; i++) {
            processMint(referralTokenId);
        }

        // Event
        emit Mint(_msgSender(), referralTokenId, qty);
    }

    function redeem(uint256 tokenId) public nonReentrant {
        processRedeem(tokenId);
    }

    function redeemAll(uint256[] memory tokenIds) public nonReentrant {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            processRedeem(tokenIds[i]);
        }
    }

    function setPrefixURI(string memory uri) public onlyOwner {
        _prefixUri = uri;
    }

    function prefixURI() public view returns (string memory) {
        return _prefixUri;
    }

    function parentOfToken(uint256 tokenId) public view returns (uint256) {
        return _parentOfToken[tokenId];
    }

    function availableRewards(uint256 tokenId) public view returns (uint256) {
        return _availableRewards[tokenId];
    }

    function totalRewards(uint256 tokenId) public view returns (uint256) {
        return _totalRewards[tokenId];
    }

    function referralTree(uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return _referralTree[tokenId];
    }

    // Total withdrawn amount of an address in this project
    function withdrawnByAddress(address _address)
        public
        view
        returns (uint256)
    {
        return _withdrawnByAddress[_address];
    }

    // Total withdrawn amount in this project
    function totalWithdrawn() public view returns (uint256) {
        return _totalWithdrawn;
    }
}