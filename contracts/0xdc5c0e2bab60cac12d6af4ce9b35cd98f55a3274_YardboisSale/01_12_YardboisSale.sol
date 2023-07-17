//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IYardbois.sol";
import "../interfaces/IYardboisResources.sol";

contract YardboisSale is Ownable {
    using ECDSA for bytes32;

    error InvalidAmount();
    error InvalidRange();
    error SaleClosed();
    error InvalidETHAmount();

    struct Range {
        uint128 endIndex;
        uint128 next;
    }

    uint256 public constant ORE_INDEX = uint256(keccak256("ORE"));
    uint256 public constant GEM_INDEX = uint256(keccak256("GEM"));

    IYardbois public immutable GNOMES;
    IYardboisResources public immutable RESOURCES;

    uint256 public immutable MINT_PRICE;
    uint256 public immutable START_TIMESTAMP;
    uint256 public immutable END_TIMESTAMP;
    uint256 public immutable RANGE_LENGTH;
    uint256 public immutable MAX_PUBLIC_SALE;
    uint256 public immutable MAX_GEM_SALE;
    uint256 public immutable MAX_TEAM;

    uint256 public publicMinted;
    uint256 public gemsMinted;
    uint256 public teamMinted;

    mapping(uint256 => Range) public ranges;

    constructor(
        IYardbois _gnomes,
        IYardboisResources _resources,
        uint256 _mintPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _maxGemSale,
        uint256 _maxTeam,
        uint128[] memory _rangeLengths
    ) {
        GNOMES = _gnomes;
        RESOURCES = _resources;
        MINT_PRICE = _mintPrice;
        START_TIMESTAMP = _startTimestamp;
        END_TIMESTAMP = _endTimestamp;
        MAX_GEM_SALE = _maxGemSale;
        MAX_TEAM = _maxTeam;

        uint128 _nextStart;
        for (uint256 i; i < _rangeLengths.length; ++i) {
            uint128 _currentLength = _rangeLengths[i];
            ranges[i] = Range(_nextStart + _currentLength, _nextStart);
            _nextStart += _currentLength;
        }

        MAX_PUBLIC_SALE = _nextStart - _maxGemSale - _maxTeam;
        RANGE_LENGTH = _rangeLengths.length;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return
            block.timestamp >= START_TIMESTAMP &&
            block.timestamp < END_TIMESTAMP &&
            publicMinted < MAX_PUBLIC_SALE;
    }

    function isGemSaleOpen() public view returns (bool) {
        return block.timestamp >= END_TIMESTAMP && gemsMinted < MAX_GEM_SALE;
    }

    function purchase(uint256 _amount, uint256 _range) external payable {
        if (!isPublicSaleOpen()) revert SaleClosed();

        uint256 _publicMinted = publicMinted;
        if (_publicMinted + _amount > MAX_PUBLIC_SALE) revert SaleClosed();

        if (_amount == 0) revert InvalidAmount();

        if (_amount * MINT_PRICE != msg.value) revert InvalidETHAmount();

        if (_range >= RANGE_LENGTH) revert InvalidRange();

        publicMinted = _publicMinted + _amount;

        _mint(msg.sender, _amount, _range);

        RESOURCES.mint(msg.sender, ORE_INDEX, _amount * 100);
    }

    function purchaseWithGems(uint256 _amount, uint256 _range) external {
        if (!isGemSaleOpen()) revert SaleClosed();

        uint256 _gemsMinted = gemsMinted;
        uint256 _publicSaleRemaining = MAX_PUBLIC_SALE - publicMinted;
        if (_gemsMinted + _amount > MAX_GEM_SALE + _publicSaleRemaining)
            revert SaleClosed();

        if (_amount == 0) revert InvalidAmount();

        if (_range >= RANGE_LENGTH) revert InvalidRange();

        gemsMinted = _gemsMinted + _amount;

        RESOURCES.burn(msg.sender, GEM_INDEX, _amount * 3);
        _mint(msg.sender, _amount, _range);
    }

    function mintTeam(
        address _recipient,
        uint256 _amount,
        uint256 _range
    ) external onlyOwner {
        uint256 _teamMinted = teamMinted;
        if (_teamMinted + _amount > MAX_TEAM) revert SaleClosed();

        if (_amount == 0) revert InvalidAmount();

        if (_range >= RANGE_LENGTH) revert InvalidRange();

        teamMinted = _teamMinted + _amount;

        _mint(_recipient, _amount, _range);
    }

    function withdrawETH() external onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        if (!sent) revert();
    }

    function _mint(
        address _recipient,
        uint256 _amount,
        uint256 _range
    ) internal {
        uint256 _mintedAmount = _tryMintFromRange(_recipient, _amount, _range);
        if (_mintedAmount < _amount) {
            for (uint256 i; i < RANGE_LENGTH && _mintedAmount < _amount; ++i) {
                uint256 _currRange = RANGE_LENGTH - 1 - i;
                if (_currRange != _range)
                    _mintedAmount += _tryMintFromRange(
                        _recipient,
                        _amount - _mintedAmount,
                        _currRange
                    );
            }

            assert(_mintedAmount == _amount);
        }
    }

    function _tryMintFromRange(
        address _recipient,
        uint256 _amount,
        uint256 _rangeIndex
    ) internal returns (uint256) {
        Range memory _range = ranges[_rangeIndex];
        uint256 _remaining = _range.endIndex - _range.next;

        if (_remaining == 0) return 0;
        else if (_remaining > _amount) {
            _mintMultiple(_recipient, _range.next, _amount);
            ranges[_rangeIndex].next = _range.next + uint128(_amount);

            return _amount;
        } else {
            _mintMultiple(_recipient, _range.next, _remaining);
            ranges[_rangeIndex].next = _range.endIndex;

            return _remaining;
        }
    }

    function _mintMultiple(
        address _recipient,
        uint256 _startIndex,
        uint256 _amount
    ) internal {
        for (uint256 i; i < _amount; ++i) {
            GNOMES.mint(_recipient, _startIndex + i);
        }
    }
}