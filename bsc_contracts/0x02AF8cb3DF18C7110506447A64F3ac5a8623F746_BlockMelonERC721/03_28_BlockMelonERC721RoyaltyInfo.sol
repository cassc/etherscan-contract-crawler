// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "../../interfaces/IBlockMelonMarketConfig.sol";
import "../../interfaces/IBlockMelonTreasury.sol";
import "../../interfaces/IGetRoyalties.sol";
import "../../interfaces/IHasSecondarySaleFees.sol";
import "./BlockMelonERC721FirstOwners.sol";

/**
 * @notice Holds a reference to the BlockMelon Market and communicates fees to 3rd party marketplaces.
 * @dev Based on: 0x93249388a3d98fd2412429a78bdd43691cc1508b `NFT721Market.sol`
 * This abstraction layer is reponsible for setting the first owner of each token ID during transfer.
 */
abstract contract BlockMelonERC721RoyaltyInfo is
    IHasSecondarySaleFees,
    IGetRoyalties,
    IERC2981Upgradeable,
    BlockMelonERC721FirstOwners
{
    using AddressUpgradeable for address;
    /// @dev Emitted when either the market or the treasury address is updated
    event MarketAndTreasuryUpdated(
        address indexed market,
        address indexed treasury
    );

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    /// @dev bytes4(keccak256('getRoyalties(address)')) == bb3bafd6
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xbb3bafd6;
    uint256 private constant BASIS_POINTS = 10000;
    /// @dev The address of the BlockMelon treasury
    IBlockMelonTreasury private _treasury;
    /// @dev The address of the BlockMelon token market
    IBlockMelonMarketConfig private _market;

    /// @dev Initializes the market and treasury addresses
    function __BlockMelonERC721RoyaltyInfo_init_unchained(
        address market,
        address treasury
    ) internal onlyInitializing {
        _updateMarketAndTreasury(market, treasury);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BlockMelonERC721FirstOwners, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES ||
            interfaceId == _INTERFACE_ID_FEES ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            BlockMelonERC721FirstOwners.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the address of the BlockMelon market contract.
     */
    function getMarket() public view returns (address) {
        return address(_market);
    }

    /**
     * @notice Returns the address of the BlockMelon treasury contract.
     */
    function getTreasury() public view returns (address) {
        return _treasury.getBlockMelonTreasury();
    }

    function _updateMarketAndTreasury(address market, address treasury)
        internal
        isContract(market)
        isContract(treasury)
    {
        _market = IBlockMelonMarketConfig(market);
        _treasury = IBlockMelonTreasury(treasury);
        _setDefaultApprovedMarket(market);
        emit MarketAndTreasuryUpdated(market, treasury);
    }

    /**
     * @notice Returns an array of recipient addresses to which fees should be sent.
     * The expected fee amount is communicated with `getFeeBps`.
     */
    function getFeeRecipients(uint256 tokenId)
        public
        view
        override
        onylExisting(tokenId)
        returns (address payable[] memory)
    {
        address payable[] memory result = new address payable[](3);
        result[0] = _treasury.getBlockMelonTreasury();
        result[1] = tokenCreator(tokenId);
        result[2] = firstOwner(tokenId);
        return result;
    }

    /**
     * @notice Returns an array of fees in basis points.
     * The expected recipients is communicated with `getFeeRecipients`.
     */
    function getFeeBps(
        uint256 /* tokenId */
    ) public view override returns (uint256[] memory) {
        (
            ,
            uint256 secondaryBlockMelonFeeInBps,
            uint256 secondaryCreatorFeeInBps,
            uint256 secondaryFirstOwnerFeeInBps
        ) = _market.getFeeConfig();
        uint256[] memory feesInBasisPoints = new uint256[](3);
        feesInBasisPoints[0] = secondaryBlockMelonFeeInBps;
        feesInBasisPoints[1] = secondaryCreatorFeeInBps;
        feesInBasisPoints[2] = secondaryFirstOwnerFeeInBps;
        return feesInBasisPoints;
    }

    /**
     * @notice Get fee recipients and fees in a single call.
     * The data is the same as when calling getFeeRecipients and getFeeBps separately.
     */
    function getRoyalties(uint256 tokenId)
        public
        view
        override
        onylExisting(tokenId)
        returns (
            address payable[] memory recipients,
            uint256[] memory feesInBasisPoints
        )
    {
        recipients = new address payable[](3);
        recipients[0] = _treasury.getBlockMelonTreasury();
        recipients[1] = tokenCreator(tokenId);
        recipients[2] = firstOwner(tokenId);
        (
            ,
            uint256 secondaryBlockMelonFeeInBps,
            uint256 secondaryCreatorFeeInBps,
            uint256 secondaryFirstOwnerFeeInBps
        ) = _market.getFeeConfig();
        feesInBasisPoints = new uint256[](3);
        feesInBasisPoints[0] = secondaryBlockMelonFeeInBps;
        feesInBasisPoints[1] = secondaryCreatorFeeInBps;
        feesInBasisPoints[2] = secondaryFirstOwnerFeeInBps;
    }

    /**
     * @notice Return the royalty percantage of the creator
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = tokenCreator(tokenId);
        (, , uint256 secondaryCreatorFeeInBps, ) = _market.getFeeConfig();
        royaltyAmount = (salePrice * secondaryCreatorFeeInBps) / BASIS_POINTS;
    }

    /**
     * @dev See {ERC721-_transfer}
     * @dev Sets `to` as the first owner of `tokenId`, if it is not set yet
     * and if `to` is neither the creator nor the `defaultApprovedMarket` contract
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);

        if (to != defaultApprovedMarket) {
            _setFirstOwner(tokenId, to);
        }
    }

    uint256[50] private __gap;
}