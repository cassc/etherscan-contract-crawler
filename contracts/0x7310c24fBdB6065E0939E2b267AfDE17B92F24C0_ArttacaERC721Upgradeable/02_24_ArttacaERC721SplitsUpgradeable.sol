// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (contracts/collections/erc721/ArttacaERC721SplitsUpgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../lib/Ownership.sol";

/**
 * @title Arttaca AbstractSplitsUpgradeable
 *
 * @dev Basic splits definition for Arttaca collections.
 */
abstract contract ArttacaERC721SplitsUpgradeable is IERC2981Upgradeable, ERC721Upgradeable, OwnableUpgradeable {

    uint96 internal feeNumerator;
    mapping(uint => Ownership.Royalties) internal tokenRoyalties;

    function __Splits_init(uint96 _royaltyPct) internal onlyInitializing {
        __Splits_init_unchained(_royaltyPct);
    }

    function __Splits_init_unchained(uint96 _royaltyPct) internal onlyInitializing {
        _setDefaultRoyalty(_royaltyPct);
    }

    function royaltyInfo(uint _tokenId, uint _salePrice) external view virtual override returns (address, uint) {
        _requireMinted(_tokenId);
        uint royaltyAmount = (_salePrice * feeNumerator * 100) / _feeDenominator();

        return (owner(), royaltyAmount);
    }

    function getRoyalties(uint _tokenId) public view returns (Ownership.Royalties memory) {
        return tokenRoyalties[_tokenId];
    }

    function _setRoyalties(uint _tokenId, Ownership.Royalties memory _royalties) internal {
        require(_checkSplits(_royalties.splits), "AbstractSplits::_setSplits: Total shares should be equal to 100.");

        if (tokenRoyalties[_tokenId].splits.length > 0) delete tokenRoyalties[_tokenId];
        for (uint i; i < _royalties.splits.length; i++) {
            tokenRoyalties[_tokenId].splits.push(_royalties.splits[i]);
        }
        tokenRoyalties[_tokenId].percentage = _royalties.percentage;
    }

    function _checkSplits(Ownership.Split[] memory _splits) internal pure returns (bool) {
        require(_splits.length <= 5, "AbstractSplits::_checkSplits: Can only split up to 5 addresses.");
        uint totalShares;
        for (uint i = 0; i < _splits.length; i++) {
            require(_splits[i].account != address(0x0), "AbstractSplits::_checkSplits: Invalid account.");
            require(_splits[i].shares > 0, "AbstractSplits::_checkSplits: Shares value must be greater than 0.");
            totalShares += _splits[i].shares;
        }
        return totalShares == _maxShares();
    }

    function getBaseRoyalty() external view returns (Ownership.Split memory) {
        return Ownership.Split(payable(owner()), feeNumerator);
    }

    function _setDefaultRoyalty(uint96 _feeNumerator) internal virtual {
        require(_feeNumerator * 100 <= _feeDenominator(), "AbstractSplits::_setDefaultRoyalty: Royalty fee must be lower than fee denominator.");
        feeNumerator = _feeNumerator;
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _maxShares() internal pure virtual returns (uint96) {
        return 100;
    }

    uint256[50] private __gap;
}