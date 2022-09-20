// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../interfaces/IPuzzleDrop.sol";

contract PuzzleDrop is ERC721AQueryable, IPuzzleDrop {
    /// @notice Price for Single
    uint256 public singlePrice = 22200000000000000;
    /// @notice Price for Bundle
    uint256 public bundlePrice = 33300000000000000;
    /// @notice Public Sale Start Time
    uint64 public immutable publicSaleStart;
    /// @notice Public Sale End Time -
    uint64 public immutable publicSaleEnd;
    /// @notice Seconds Till Next Drop
    uint256 public immutable secondsBetweenDrops;

    /// @notice Sale is inactive
    error Sale_Inactive();
    /// @notice Wrong price for purchase
    error Purchase_WrongPrice(uint256 correctPrice);
    /// @notice Track Sale is inactive
    error Track_Sale_Inactive();

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        /// @dev 1 week live & 3 minutes in testing
        publicSaleStart = uint64(block.timestamp);
        /// @dev Ends on Halloween - October 31 2022 - 23:59:59PM ET
        publicSaleEnd = 1667275199;
        /// @dev 1 week between drops live & 3 minutes in testing
        secondsBetweenDrops = block.chainid == 1 ? 604800 : 60;
    }

    /// @notice Public sale active
    modifier onlyPublicSaleActive() {
        if (!_publicSaleActive()) {
            revert Sale_Inactive();
        }

        _;
    }

    /// @notice Public sale active
    modifier onlyValidPrice(uint256 _price, uint256 _quantity) {
        if (msg.value != _price * _quantity) {
            revert Purchase_WrongPrice(_price * _quantity);
        }

        _;
    }

    /// @notice Public sale active
    function _publicSaleActive() internal view returns (bool) {
        return
            publicSaleStart <= block.timestamp &&
            publicSaleEnd > block.timestamp;
    }

    /// @notice Track sale active
    modifier onlyTrackSaleActive(uint8 _trackNumber) {
        if (!_trackSaleActive(_trackNumber)) {
            revert Track_Sale_Inactive();
        }

        _;
    }

    /// @notice Track sale active
    function _trackSaleActive(uint8 _trackNumber) internal view returns (bool) {
        return _trackNumber > 0 && _trackNumber <= dropsCreated();
    }

    /// @notice Sale details
    /// @return IERC721Drop.SaleDetails sale information details
    function saleDetails() external view returns (SaleDetails memory) {
        return
            SaleDetails({
                publicSaleActive: _publicSaleActive(),
                presaleActive: false,
                publicSalePrice: singlePrice,
                publicSaleStart: publicSaleStart,
                publicSaleEnd: publicSaleEnd,
                presaleStart: 0,
                presaleEnd: 0,
                presaleMerkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
                totalMinted: _totalMinted(),
                maxSupply: type(uint256).max,
                maxSalePurchasePerAddress: 0,
                publicSaleBundlePrice: bundlePrice
            });
    }

    /// @notice Returns the starting token ID.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice returns current week number.
    function weekNumber() public view returns (uint256) {
        return 1 + (block.timestamp - publicSaleStart) / secondsBetweenDrops;
    }

    /// @notice returns number of created drops.
    function dropsCreated() public view returns (uint8) {
        bool isMaxWeek = weekNumber() >= 6;
        return isMaxWeek ? 12 : 2 * uint8(weekNumber());
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
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
}