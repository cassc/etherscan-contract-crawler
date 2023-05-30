// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ERC721.sol";
import "./interface/ILife.sol";

/**
 * @title NFTKEY Life collection contract
 */
contract Life is ILife, ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    constructor(string memory name_, string memory symbol_) public ERC721(name_, symbol_) {}

    uint256 public constant SALE_START_TIMESTAMP = 1616247000;

    uint256 public constant MAX_NFT_SUPPLY = 10000;

    mapping(address => uint256) private _pendingWithdrawals;
    mapping(uint256 => uint8[]) private _bioDNAById;
    mapping(bytes32 => bool) private _bioExistanceByHash;

    uint8 private _feeFraction = 1;
    uint8 private _feeBase = 100;
    mapping(uint256 => Listing) private _bioListedForSale;
    mapping(uint256 => Bid) private _bioWithBids;

    /**
     * @dev See {ILife-getBioDNA}.
     */
    function getBioDNA(uint256 bioId) external view override returns (uint8[] memory) {
        return _bioDNAById[bioId];
    }

    /**
     * @dev See {ILife-allBioDNAs}.
     */
    function getBioDNAs(uint256 from, uint256 size)
        external
        view
        override
        returns (uint8[][] memory)
    {
        uint256 endBioIndex = from + size;
        require(endBioIndex <= totalSupply(), "Requesting too many Bios");

        uint8[][] memory bios = new uint8[][](size);
        for (uint256 i; i < size; i++) {
            bios[i] = _bioDNAById[i + from];
        }
        return bios;
    }

    /**
     * @dev See {ILife-getBioPrice}.
     */
    function getBioPrice() public view override returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        uint256 currentSupply = totalSupply();

        if (currentSupply > 9900) {
            return 10000000000000000000; // 9901 - 10000 10 ETH
        } else if (currentSupply > 9500) {
            return 2000000000000000000; // 9501 - 9900 2.0 ETH
        } else if (currentSupply > 8500) {
            return 1000000000000000000; // 8501  - 9500 1 ETH
        } else if (currentSupply > 4500) {
            return 800000000000000000; // 4501 - 8500 0.8 ETH
        } else if (currentSupply > 2500) {
            return 600000000000000000; // 2501 - 4500 0.6 ETH
        } else if (currentSupply > 1000) {
            return 400000000000000000; // 1001 - 2500 0.4 ETH
        } else if (currentSupply > 100) {
            return 200000000000000000; // 101 - 1000 0.2 ETH
        } else {
            return 100000000000000000; // 0 - 100 0.1 ETH
        }
    }

    /**
     * @dev See {ILife-isBioExist}.
     */
    function isBioExist(uint8[] memory bioDNA) external view override returns (bool) {
        bytes32 bioHashOriginal = keccak256(abi.encodePacked(bioDNA));

        return _bioExistanceByHash[bioHashOriginal];
    }

    /**
     * @dev See {ILife-mintBio}.
     */
    function mintBio(uint8[] memory bioDNA) external payable override {
        // Bio RLE
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(totalSupply().add(1) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getBioPrice() == msg.value, "Ether value sent is not correct");

        bytes32 bioHash = keccak256(abi.encodePacked(bioDNA));
        require(!_bioExistanceByHash[bioHash], "Bio already existed");

        uint256 activeCellCount = 0;
        uint256 totalCellCount = 0;
        for (uint8 i = 0; i < bioDNA.length; i++) {
            totalCellCount = totalCellCount.add(bioDNA[i]);
            if (i % 2 == 1) {
                activeCellCount = activeCellCount.add(bioDNA[i]);
            }
        }

        require(totalCellCount <= 289, "Total cell count should be smaller than 289");
        require(
            activeCellCount >= 5 && activeCellCount <= 48,
            "Active cell count of Bio is not allowed"
        );

        uint256 mintIndex = totalSupply();

        _bioExistanceByHash[bioHash] = true;
        _bioDNAById[mintIndex] = bioDNA;
        _safeMint(msg.sender, mintIndex);
        _pendingWithdrawals[owner()] = _pendingWithdrawals[owner()].add(msg.value);

        emit BioMinted(mintIndex, msg.sender, bioDNA, bioHash);
    }

    modifier saleEnded() {
        require(totalSupply() >= MAX_NFT_SUPPLY, "Bio sale still going");
        _;
    }

    modifier bioExist(uint256 bioId) {
        require(bioId < totalSupply(), "Bio doesn't exist");
        _;
    }

    modifier isBioOwner(uint256 bioId) {
        require(ownerOf(bioId) == msg.sender, "Not the owner of this Bio");
        _;
    }

    /**
     * @dev See {ILife-getBioListing}.
     */
    function getBioListing(uint256 bioId) external view override returns (Listing memory) {
        return _bioListedForSale[bioId];
    }

    /**
     * @dev See {ILife-getListings}.
     */
    function getBioListings(uint256 from, uint256 size)
        external
        view
        override
        returns (Listing[] memory)
    {
        uint256 endBioIndex = from + size;
        require(endBioIndex <= totalSupply(), "Requesting too many listings");

        Listing[] memory listings = new Listing[](size);
        for (uint256 i; i < size; i++) {
            listings[i] = _bioListedForSale[i + from];
        }
        return listings;
    }

    /**
     * @dev See {ILife-getBioBid}.
     */
    function getBioBid(uint256 bioId) external view override returns (Bid memory) {
        return _bioWithBids[bioId];
    }

    /**
     * @dev See {ILife-getBioBids}.
     */
    function getBioBids(uint256 from, uint256 size) external view override returns (Bid[] memory) {
        uint256 endBioIndex = from + size;
        require(endBioIndex <= totalSupply(), "Requesting too many bids");

        Bid[] memory bids = new Bid[](size);
        for (uint256 i; i < totalSupply(); i++) {
            bids[i] = _bioWithBids[i + from];
        }
        return bids;
    }

    /**
     * @dev See {ILife-listBioForSale}.
     */
    function listBioForSale(uint256 bioId, uint256 minValue)
        external
        override
        saleEnded
        bioExist(bioId)
        isBioOwner(bioId)
    {
        _bioListedForSale[bioId] = Listing(
            true,
            bioId,
            msg.sender,
            minValue,
            address(0),
            block.timestamp
        );
        emit BioListed(bioId, minValue, msg.sender, address(0));
    }

    /**
     * @dev See {ILife-listBioForSaleToAddress}.
     */
    function listBioForSaleToAddress(
        uint256 bioId,
        uint256 minValue,
        address toAddress
    ) external override saleEnded bioExist(bioId) isBioOwner(bioId) {
        _bioListedForSale[bioId] = Listing(
            true,
            bioId,
            msg.sender,
            minValue,
            toAddress,
            block.timestamp
        );
        emit BioListed(bioId, minValue, msg.sender, toAddress);
    }

    function _delistBio(uint256 bioId) private saleEnded bioExist(bioId) {
        emit BioDelisted(bioId, _bioListedForSale[bioId].seller);
        delete _bioListedForSale[bioId];
    }

    function _removeBid(uint256 bioId) private saleEnded bioExist(bioId) {
        emit BioBidRemoved(bioId, _bioWithBids[bioId].bidder);
        delete _bioWithBids[bioId];
    }

    /**
     * @dev See {ILife-delistBio}.
     */
    function delistBio(uint256 bioId) external override isBioOwner(bioId) {
        require(_bioListedForSale[bioId].isForSale, "Bio is not for sale");
        _delistBio(bioId);
    }

    /**
     * @dev Return ETH if it's not a contract, else add it to pending withdrawals
     * @param receiver Address to receive value
     * @param value value to send
     */
    function _sendValue(address receiver, uint256 value) private {
        if (receiver.isContract() && receiver != msg.sender) {
            _pendingWithdrawals[receiver] = value;
        } else {
            Address.sendValue(payable(receiver), value);
        }
    }

    /**
     * @dev See {ILife-buyBio}.
     */
    function buyBio(uint256 bioId)
        external
        payable
        override
        saleEnded
        bioExist(bioId)
        nonReentrant
    {
        Listing memory listing = _bioListedForSale[bioId];

        require(listing.isForSale, "Bio is not for sale");
        require(
            listing.onlySellTo == address(0) || listing.onlySellTo == msg.sender,
            "Bio is not selling to this address"
        );
        require(ownerOf(bioId) == listing.seller, "This seller is not the owner");
        require(msg.sender != ownerOf(bioId), "This Bio belongs to this address");

        uint256 fees = listing.minValue.mul(_feeFraction).div(_feeBase);
        require(
            msg.value >= listing.minValue + fees,
            "The value send is below sale price plus fees"
        );

        uint256 valueWithoutFees = msg.value.sub(fees);

        _sendValue(ownerOf(bioId), valueWithoutFees);
        _pendingWithdrawals[owner()] = _pendingWithdrawals[owner()].add(fees);
        emit BioBought(bioId, valueWithoutFees, listing.seller, msg.sender);

        _safeTransfer(ownerOf(bioId), msg.sender, bioId, "");

        _delistBio(bioId);

        Bid memory existingBid = _bioWithBids[bioId];
        if (existingBid.bidder == msg.sender) {
            _sendValue(msg.sender, existingBid.value);
            _removeBid(bioId);
        }
    }

    /**
     * @dev See {ILife-enterBidForBio}.
     */
    function enterBidForBio(uint256 bioId)
        external
        payable
        override
        saleEnded
        bioExist(bioId)
        nonReentrant
    {
        require(ownerOf(bioId) != address(0), "This Bio has been burnt");
        require(ownerOf(bioId) != msg.sender, "Owner of Bio doesn't need to bid");
        require(msg.value != 0, "The bid price is too low");

        Bid memory existingBid = _bioWithBids[bioId];
        require(msg.value > existingBid.value, "The bid price is no higher than existing one");

        if (existingBid.value > 0) {
            _sendValue(existingBid.bidder, existingBid.value);
        }
        _bioWithBids[bioId] = Bid(true, bioId, msg.sender, msg.value, block.timestamp);
        emit BioBidEntered(bioId, msg.value, msg.sender);
    }

    /**
     * @dev See {ILife-acceptBidForBio}.
     */
    function acceptBidForBio(uint256 bioId)
        external
        override
        saleEnded
        bioExist(bioId)
        isBioOwner(bioId)
        nonReentrant
    {
        Bid memory existingBid = _bioWithBids[bioId];
        require(existingBid.hasBid && existingBid.value > 0, "This Bio doesn't have a valid bid");

        uint256 fees = existingBid.value.mul(_feeFraction).div(_feeBase + _feeFraction);
        uint256 bioValue = existingBid.value.sub(fees);
        _sendValue(msg.sender, bioValue);
        _pendingWithdrawals[owner()] = _pendingWithdrawals[owner()].add(fees);

        _safeTransfer(msg.sender, existingBid.bidder, bioId, "");
        emit BioBidAccepted(bioId, bioValue, msg.sender, existingBid.bidder);

        _removeBid(bioId);

        if (_bioListedForSale[bioId].isForSale) {
            _delistBio(bioId);
        }
    }

    /**
     * @dev See {ILife-withdrawBidForBio}.
     */
    function withdrawBidForBio(uint256 bioId)
        external
        override
        saleEnded
        bioExist(bioId)
        nonReentrant
    {
        Bid memory existingBid = _bioWithBids[bioId];
        require(existingBid.bidder == msg.sender, "This address doesn't have active bid");

        _sendValue(msg.sender, existingBid.value);

        emit BioBidWithdrawn(bioId, existingBid.value, existingBid.bidder);
        _removeBid(bioId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 bioId
    ) public override nonReentrant {
        require(
            _isApprovedOrOwner(_msgSender(), bioId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, bioId);

        if (_bioListedForSale[bioId].seller == from) {
            _delistBio(bioId);
        }
        if (_bioWithBids[bioId].bidder == to) {
            _sendValue(_bioWithBids[bioId].bidder, _bioWithBids[bioId].value);
            _removeBid(bioId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 bioId
    ) public override {
        safeTransferFrom(from, to, bioId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 bioId,
        bytes memory _data
    ) public override nonReentrant {
        require(
            _isApprovedOrOwner(_msgSender(), bioId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, bioId, _data);

        if (_bioListedForSale[bioId].seller == from) {
            _delistBio(bioId);
        }
        if (_bioWithBids[bioId].bidder == to) {
            _sendValue(_bioWithBids[bioId].bidder, _bioWithBids[bioId].value);
            _removeBid(bioId);
        }
    }

    /**
     * @dev See {ILife-serviceFee}.
     */
    function serviceFee() external view override returns (uint8, uint8) {
        return (_feeFraction, _feeBase);
    }

    /**
     * @dev See {ILife-pendingWithdrawals}.
     */
    function pendingWithdrawals(address toAddress) external view override returns (uint256) {
        return _pendingWithdrawals[toAddress];
    }

    /**
     * @dev See {ILife-withdraw}.
     */
    function withdraw() external override nonReentrant {
        require(_pendingWithdrawals[msg.sender] > 0, "There is nothing to withdraw");
        _sendValue(msg.sender, _pendingWithdrawals[msg.sender]);
        _pendingWithdrawals[msg.sender] = 0;
    }

    /**
     * @dev Change withdrawal fee percentage.
     * If 1%, then input (1,100)
     * If 0.5%, then input (5,1000)
     * @param feeFraction_ Fraction of withdrawal fee based on feeBase_
     * @param feeBase_ Fraction of withdrawal fee base
     */
    function changeSeriveFee(uint8 feeFraction_, uint8 feeBase_) external onlyOwner {
        require(feeFraction_ <= feeBase_, "Fee fraction exceeded base.");
        uint256 percentage = (feeFraction_ * 1000) / feeBase_;
        require(percentage <= 25, "Attempt to set percentage higher than 2.5%.");

        _feeFraction = feeFraction_;
        _feeBase = feeBase_;
    }
}