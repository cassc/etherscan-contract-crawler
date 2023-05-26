// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../libs/RoyaltyLibrary.sol";
import "../interfaces/IRoyalty.sol";
import "../interfaces/IPrimaryRoyalty.sol";
import "../interfaces/ICreator.sol";

abstract contract Royalty is Context, ERC165, IRoyalty, IPrimaryRoyalty, ICreator {
    event SetRoyaltyShares (
        uint256 indexed tokenId,
        address[] recipients,
        uint[] bp
    );

    event SetRoyalty (
        address owner,
        uint256 indexed tokenId,
        uint256 value,
        RoyaltyLibrary.Strategy strategy
    );

    event SetPrimaryRoyaltyShares (
        uint256 indexed tokenId,
        address[] recipients,
        uint[] bp
    );

    // tokenId => royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyInfo) public royalty;

    // tokenId => royaltyShares
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) public royaltyShares;

    // tokenId => creator address
    mapping(uint256 => address) creators;

    // tokenId => primary royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) primaryRoyaltyShares;

    // Max count of royalty shares
    uint256 maxRoyaltyShareCount = 100;

    /*
     * bytes4(keccak256('getRoyalty(uint256 _tokenId)')) == 0x71f1e123
     * bytes4(keccak256('getRoyaltyShares(uint256 _tokenId)')) == 0x8e9727ba
     * bytes4(keccak256('_setRoyalty(uint256 _tokenId, uint256 _bps, RoyaltyLibrary.Strategy _strategy')) == 0x8bb6c361
     * bytes4(keccak256('_addRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares)')) == 0xa0034d9f
     * bytes4(keccak256('royalty()')) == 0x29ee566c
     * bytes4(keccak256('royaltyShares()')) == 0x861475d2
     *
     * => 0x71f1e123 ^ 0x8e9727ba ^ 0x8bb6c361 ^ 0xa0034d9f ^ 0x29ee566c ^ 0x861475d2 == 0x7b296bd9
     */

    // IMPORTANT: This is version 1 of the royalty. Please do not delete for record.
    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;

    // From IRoyalty
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    constructor() public {
        _registerInterface(_INTERFACE_ID_ROYALTY_V2);
        _registerInterface(type(IPrimaryRoyalty).interfaceId);
        _registerInterface(type(ICreator).interfaceId);
    }

    function getTokenContract() public view override returns (address) {
        return address(this);
    }

    function getRoyalty(uint256 _tokenId) public view override returns (RoyaltyLibrary.RoyaltyInfo memory) {
        return royalty[_tokenId];
    }

    function getRoyaltyShares(uint256 _tokenId) public view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return royaltyShares[_tokenId];
    }

    function getPrimaryRoyaltyShares(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return primaryRoyaltyShares[_tokenId];
    }

    function getCreator(uint256 _tokenId) external view override returns (address) {
        return creators[_tokenId];
    }

    function _setRoyalty(uint256 _tokenId, uint256 _bps, RoyaltyLibrary.Strategy _strategy) internal {
        require(
            _bps <= 10 ** 4,
            "Royalty: Total royalty bps should not exceed 10000"
        );
        royalty[_tokenId] = RoyaltyLibrary.RoyaltyInfo({
        value : _bps,
        strategy : _strategy
        });
        emit SetRoyalty(_msgSender(), _tokenId, _bps, _strategy);
    }

    function _addRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal {
        require(
            _royaltyShares.length <= maxRoyaltyShareCount,
            "Royalty: Amount of royalty recipients can't exceed 100"
        );

        address[] memory recipients = new address[](_royaltyShares.length);
        uint[] memory bps = new uint[](_royaltyShares.length);
        for (uint i = 0; i < _royaltyShares.length; i++) {
            require(_royaltyShares[i].recipient != address(0x0), "Royalty: Royalty share recipient should be present");
            require(_royaltyShares[i].value != 0, "Royalty: Royalty share bps value should be positive");
            royaltyShares[_tokenId].push(_royaltyShares[i]);
            recipients[i] = _royaltyShares[i].recipient;
            bps[i] = _royaltyShares[i].value;
        }
        if (_royaltyShares.length > 0) {
            emit SetRoyaltyShares(_tokenId, recipients, bps);
        }
    }

    function _addPrimaryRoyaltyShares(uint256 _tokenId, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal {
        require(
            _royaltyShares.length <= maxRoyaltyShareCount,
            "Royalty: Amount of royalty recipients can't exceed 100"
        );

        address[] memory recipients = new address[](_royaltyShares.length);
        uint[] memory bps = new uint[](_royaltyShares.length);
        // Pushing the royalty shares into the mapping
        for (uint i = 0; i < _royaltyShares.length; i++) {
            require(_royaltyShares[i].recipient != address(0x0), "Royalty: Primary royalty share recipient should be present");
            require(_royaltyShares[i].value != 0, "Royalty: Primary royalty share bps value should be positive");
            primaryRoyaltyShares[_tokenId].push(_royaltyShares[i]);
            recipients[i] = _royaltyShares[i].recipient;
            bps[i] = _royaltyShares[i].value;
        }
        if (_royaltyShares.length > 0) {
            emit SetPrimaryRoyaltyShares(_tokenId, recipients, bps);
        }
    }
}