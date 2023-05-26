// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../../interfaces/IRoyalty.sol";
import "../../interfaces/IHasSecondarySale.sol";
import "../../libs/RoyaltyLibrary.sol";
import "./RanERC721Mock.sol";
import "../../interfaces/ICreator.sol";
import "../../interfaces/IPrimaryRoyalty.sol";


contract RoyaltyERC721Mock is Context, IRoyalty, IHasSecondarySale, ERC165, ICreator, IPrimaryRoyalty {
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
    mapping(uint256 => RoyaltyLibrary.RoyaltyInfo) royalty;

    // tokenId => royaltyShares
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) royaltyShares;

    // tokenId => bool: true is first sale, false is secondary sale
    mapping(uint256 => bool) isSecondarySale;

    // ERC721/1155 Address
    address tokenContract;

    // Max count of royalty shares
    uint256 maxRoyaltyShareCount;

    // tokenId => creator address
    mapping(uint256 => address) creators;

    // tokenId => primary royalty
    mapping(uint256 => RoyaltyLibrary.RoyaltyShareDetails[]) primaryRoyaltyShares;

    constructor (address _tokenContract, uint256 _maxRoyaltyShareCount) public {
        tokenContract = _tokenContract;
        maxRoyaltyShareCount = _maxRoyaltyShareCount;

        _registerInterface(type(IRoyalty).interfaceId);
        _registerInterface(type(IHasSecondarySale).interfaceId);
        _registerInterface(type(IPrimaryRoyalty).interfaceId);
        _registerInterface(type(ICreator).interfaceId);
    }

    function getTokenContract() external view override returns (address) {
        return tokenContract;
    }

    //    // Optional
    //    function setTokenContract(address token);

    function getRoyalty(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyInfo memory) {
        return royalty[_tokenId];
    }

    function getRoyaltyShares(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return royaltyShares[_tokenId];
    }

    function checkSecondarySale(uint256 _tokenId) public view override returns (bool) {
        return isSecondarySale[_tokenId];
    }

    function setSecondarySale(uint256 _tokenId) public override {
        isSecondarySale[_tokenId] = true;
    }

    function getPrimaryRoyaltyShares(uint256 _tokenId) external view override returns (RoyaltyLibrary.RoyaltyShareDetails[] memory) {
        return primaryRoyaltyShares[_tokenId];
    }

    function getCreator(uint256 _tokenId) external view override returns (address) {
        return creators[_tokenId];
    }

    function mint(
        uint256 _tokenId,
        bytes memory _signature,
        string memory _uri,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) public {
        RanERC721Mock(tokenContract).mint(_msgSender(), _tokenId);
        _addRoyalties(_tokenId, _royaltyShares, _royaltyBps, _royaltyStrategy, _primaryRoyaltyShares);
        creators[_tokenId] = _msgSender();
    }

    // Optional to make it public or not
    function _addRoyalties(
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _primaryRoyaltyShares
    ) internal {
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps + _royaltyShares[i].value;
        }

        if (_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total royalty share bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10 ** 4,
                "Royalty: Total royalty share bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps, RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY) {
            uint256 sumPrimaryRoyaltyShareBps;
            for (uint256 i = 0; i < _primaryRoyaltyShares.length; i++) {
                sumPrimaryRoyaltyShareBps = sumPrimaryRoyaltyShareBps + _primaryRoyaltyShares[i].value;
            }
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total royalty share bps should not exceed 10000"
            );
            require(
                sumPrimaryRoyaltyShareBps <= 10 ** 4,
                "Royalty: Total primary royalty share bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY);
            _addPrimaryRoyaltyShares(_tokenId, _primaryRoyaltyShares);
        } else {
            revert("Royalty: Royalty option does not exist");
        }

        _addRoyaltyShares(_tokenId, _royaltyShares);
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
        // Pushing the royalty shares into the mapping
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