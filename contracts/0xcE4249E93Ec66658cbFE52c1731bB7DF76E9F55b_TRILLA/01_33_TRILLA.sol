// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./FixedPriceSeller.sol";
import "./ERC721Common.sol";

contract TRILLA is
    ERC721Common,
    BaseTokenURI,
    FixedPriceSeller,
    ERC2981,
    AccessControlEnumerable
{
    using Monotonic for Monotonic.Increaser;

    // tierName -> index threshold (exclusive)
    mapping(uint256 => uint256) public tierThresholds;

    // tierName -> index of current minting
    mapping(uint256 => uint256) public tierIndexs;

    constructor(
        string memory name,
        string memory symbol,
        address payable beneficiary,
        address payable royaltyReceiver,
        uint256[] memory _tierThresholds
    )
        ERC721Common(name, symbol)
        BaseTokenURI("ipfs://QmeUXp3WamCoT5dVGqejvyLUMpemy4a5nfEHsyseXSRFR1")
        FixedPriceSeller(
            0.07 ether,
            Seller.SellerConfig({
                totalInventory: 45,
                lockTotalInventory: false,
                maxPerAddress: 1,
                maxPerTx: 45,
                freeQuota: 45,
                lockFreeQuota: false,
                reserveFreeQuota: false
            }),
            beneficiary
        )
    {
        setTiers(_tierThresholds);
        _setDefaultRoyalty(royaltyReceiver, 1000);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function setTiers(uint256[] memory _thresholds)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < _thresholds.length; index++) {
            tierThresholds[index] = _thresholds[index];
            if (index > 0) {
                tierIndexs[index] = tierThresholds[index-1];
            }
        }
    }

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 tokenId,
        bool
    ) internal override {
        _safeMint(to, tokenId);
    }

    /**
    @notice Mint as a non-holder of mint pass tokens.
     */
    function mintTierPublic(
        address to,
        uint256 tierId
    ) external payable {
        require(tierIndexs[tierId] < tierThresholds[tierId], "NFTs: tier soldout");
        _purchase(to, tierIndexs[tierId]);
        tierIndexs[tierId]++;
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
    @notice If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Common, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}