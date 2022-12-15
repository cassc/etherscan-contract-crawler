// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// solhint-disable no-empty-blocks, func-name-mixedcase

// inheritance
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interface/IRoyalty.sol";

abstract contract RoyaltyUpgradeable is OwnableUpgradeable, IRoyalty {
    RoyaltyInfo[] private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo[]) private _tokenRoyaltyInfo;

    //
    // proxy constructors
    //

    function __Royalty_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Royalty_init_unchained() internal onlyInitializing {}

    //
    // public methods
    //

    function setDefaultRoyalty(
        RoyaltyInfo[] memory defaultRoyaltyInfo_
    ) public virtual override onlyOwner {
        _setDefaultRoyalty(defaultRoyaltyInfo_);
    }

    function setTokenRoyalty(
        uint256 tokenId_,
        RoyaltyInfo[] memory royalty_
    ) public virtual override onlyOwner {
        _setTokenRoyalty(tokenId_, royalty_);
    }

    function calculateRoyalty(
        uint256 tokenId_,
        uint256 salePrice_
    )
        public
        view
        virtual
        override
        returns (address[] memory, uint256[] memory, uint256)
    {
        // token royalty or default royalty
        RoyaltyInfo[] memory royalty = _tokenRoyaltyInfo[tokenId_];
        if (royalty.length == 0) {
            royalty = _defaultRoyaltyInfo;
        }

        // funds calculating
        address[] memory targets = new address[](royalty.length);
        uint256[] memory amounts = new uint256[](royalty.length);
        uint256 totalSum;
        for (uint256 i = 0; i < royalty.length; i++) {
            targets[i] = royalty[i].receiver;
            amounts[i] =
                (salePrice_ * royalty[i].royaltyFraction) /
                _feeDenominator();
            totalSum += amounts[i];
        }

        return (targets, amounts, totalSum);
    }

    function defaultRoyaltyInfo()
        public
        view
        virtual
        override
        returns (RoyaltyInfo[] memory)
    {
        return _defaultRoyaltyInfo;
    }

    function tokenRoyaltyInfo(
        uint256 tokenId_
    ) public view virtual override returns (RoyaltyInfo[] memory) {
        return _tokenRoyaltyInfo[tokenId_];
    }

    //
    // internal methods
    //

    function _setDefaultRoyalty(
        RoyaltyInfo[] memory defaultRoyaltyInfo_
    ) internal virtual {
        _checkRoyalty(defaultRoyaltyInfo_);

        _resetDefaultRoyalty();

        for (uint256 i = 0; i < defaultRoyaltyInfo_.length; i++) {
            _defaultRoyaltyInfo.push(defaultRoyaltyInfo_[i]);
        }

        emit SetDefaultRoyalty({
            sender: msg.sender,
            defaultRoyaltyInfo: defaultRoyaltyInfo_
        });
    }

    function _resetDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    function _setTokenRoyalty(
        uint256 tokenId_,
        RoyaltyInfo[] memory royalty_
    ) internal virtual {
        _checkRoyalty(royalty_);

        _resetTokenRoyalty(tokenId_);

        for (uint256 i = 0; i < royalty_.length; i++) {
            _tokenRoyaltyInfo[tokenId_].push(royalty_[i]);
        }

        emit SetTokenRoyalty({
            sender: msg.sender,
            tokenId: tokenId_,
            defaultRoyaltyInfo: royalty_
        });
    }

    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _checkRoyalty(RoyaltyInfo[] memory royalty) internal pure virtual {
        uint256 totalSum;
        for (uint256 i = 0; i < royalty.length; i++) {
            require(
                royalty[i].receiver != address(0),
                "RoyaltyUpgradeable: wrong receiver"
            );
            require(
                royalty[i].royaltyFraction < _feeDenominator(),
                "RoyaltyUpgradeable: wrong royalty fraction"
            );
            totalSum += royalty[i].royaltyFraction;
        }
        require(
            totalSum < _feeDenominator(),
            "RoyaltyUpgradeable: wrong royalty sum"
        );
    }

    uint256[48] private __gap;
}