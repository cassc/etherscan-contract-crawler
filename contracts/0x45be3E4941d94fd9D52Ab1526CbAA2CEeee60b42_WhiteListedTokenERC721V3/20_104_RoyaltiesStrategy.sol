// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";

import "../libs/RoyaltyLibrary.sol";
import "../tokens/v2/ERC721BaseV2.sol";
import "../tge/interfaces/IBEP20.sol";
import "../tokens/Royalty.sol";
import "../tokens/v1/HasSecondarySaleFees.sol";
import "../interfaces/IPrimaryRoyalty.sol";

abstract contract RoyaltiesStrategy is Context {
    using SafeMath for uint256;
    using RoyaltyLibrary for RoyaltyLibrary.RoyaltyShareDetails;
    using RoyaltyLibrary for RoyaltyLibrary.RoyaltyInfo;

    bytes4 private constant _INTERFACE_ID_ROYALTY = 0x7b296bd9;
    bytes4 private constant _INTERFACE_ID_ROYALTY_V2 = 0x9e4a83d4;

    function _payOutRoyaltiesByStrategy(
        address _token,
        uint256 _tokenId,
        address _payToken,
        address _payer,
        uint256 _actualPrice, // the total paid price - seller service fee - buyer service fee
        bool _isSecondarySale
    ) internal returns (uint256){
        /*
           * The _totalPrice is on sale price minus seller service fee minus buyer service fee
           * This make sures we have enough balance even the royalties is 100%
        */
        uint256 royalties;
        if (
            IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY)
            || IERC165(_token).supportsInterface(_INTERFACE_ID_ROYALTY_V2)
        ) {
            royalties = _payOutRoyalties(_token, _tokenId, _payToken, _payer, _actualPrice, _isSecondarySale);
        } else {
            // support the old contract with no strategy
            address payable[] memory recipients = HasSecondarySaleFees(_token).getFeeRecipients(_tokenId);
            uint256[] memory royaltyShares = HasSecondarySaleFees(_token).getFeeBps(_tokenId);
            require(royaltyShares.length == recipients.length, "RoyaltyStrategy: Royalty share array length not match recipients array length");
            uint256 sumRoyaltyShareBps;
            for (uint256 i = 0; i < royaltyShares.length; i++) {
                sumRoyaltyShareBps = sumRoyaltyShareBps.add(royaltyShares[i]);
            }
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "RoyaltyStrategy: Total Royalty Shares bps should not exceed 10000"
            );
            for (uint256 i = 0; i < royaltyShares.length; i++) {
                uint256 recipientRoyalty = _actualPrice.mul(royaltyShares[i]).div(10 ** 4);
                _transferToken(_payToken, _payer, recipients[i], recipientRoyalty);
                royalties = royalties.add(recipientRoyalty);
            }
        }
        return royalties;
    }

    function _payOutRoyalties(address _token, uint256 _tokenId, address _payToken, address _payer, uint256 _payPrice, bool _isSecondarySale) internal returns (uint256) {
        uint256 royalties;
        RoyaltyLibrary.RoyaltyInfo memory royalty = Royalty(_token).getRoyalty(_tokenId);
        RoyaltyLibrary.RoyaltyShareDetails[] memory royaltyShares;
        if (royalty.strategy == RoyaltyLibrary.Strategy.PRIMARY_SALE_STRATEGY && _isSecondarySale == false) {
            if (IERC165(_token).supportsInterface(type(IPrimaryRoyalty).interfaceId)) {
                royaltyShares = IPrimaryRoyalty(_token).getPrimaryRoyaltyShares(_tokenId);
            } else {
                royaltyShares = Royalty(_token).getRoyaltyShares(_tokenId);
            }
        } else {
            royaltyShares = Royalty(_token).getRoyaltyShares(_tokenId);
        }
        _checkRoyaltiesBps(royalty, royaltyShares);
        for (uint256 i = 0; i < royaltyShares.length; i++) {
            uint256 recipientRoyalty;
            if (royalty.strategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY && _isSecondarySale) {
                recipientRoyalty = _payPrice.mul(royalty.value).mul(royaltyShares[i].value).div(10 ** 8);
            } else {
                recipientRoyalty = _payPrice.mul(royaltyShares[i].value).div(10 ** 4);
            }
            _transferToken(_payToken, _payer, royaltyShares[i].recipient, recipientRoyalty);
            royalties = royalties.add(recipientRoyalty);
        }
        return royalties;
    }

    function _checkRoyaltiesBps(RoyaltyLibrary.RoyaltyInfo memory _royalty, RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares) internal pure {
        require(
            _royalty.value <= 10 ** 4,
            "RoyaltyStrategy: Royalty bps should be less than 10000"
        );
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps.add(_royaltyShares[i].value);
        }
        if (_royalty.strategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10 ** 4,
                "RoyaltyStrategy: Total Royalty Shares bps should be 10000"
            );
        } else {
            require(
                sumRoyaltyShareBps <= 10 ** 4,
                "RoyaltyStrategy: Total Royalty Shares bps should not exceed 10000"
            );
        }
    }

    function _transferToken(address _payToken, address _payer, address payable _recipient, uint256 _amount) internal {
        if (_payToken == address(0)) {
            _recipient.transfer(_amount);
        } else {
            if (_payer == address(this)) {
                IBEP20(_payToken).transfer(_recipient, _amount);
            } else {
                IBEP20(_payToken).transferFrom(_payer, _recipient, _amount);
            }
        }
    }
}