//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IFirstDibsRoyalties.sol';
import './SplitForwarderFactory.sol';

contract FirstDibsPayments is IFirstDibsRoyalties, Ownable {
    // default royalties to creators on secondary sales
    uint32 public override globalCreatorRoyaltyBasisPoints = 1000;
    /**
     * @dev token ID mapping to payable alternate payment address for a creator
     */
    mapping(uint256 => address payable) private tokenPaymentAddresses;

    /**
     * @dev token ID mapping to royalty basis points
     */
    mapping(uint256 => uint32) private perTokenRoyalties;

    /**
     * @dev setter for global creator royalty rate
     * @param royaltyBasisPoints new creator royalty rate
     */
    function setGlobalCreatorRoyaltyBasisPoints(uint32 royaltyBasisPoints)
        external
        override
        onlyOwner
    {
        require(royaltyBasisPoints <= 10000, 'Value must be <= 10000');
        require(royaltyBasisPoints >= 200, 'Creator royalty cannot be lower than 2%');
        globalCreatorRoyaltyBasisPoints = royaltyBasisPoints;
    }

    /**
     * @dev set a new payment address for a token
     * @param _tokenId token ID to set a new payment address for
     * @param _paymentAddress new payment address
     *
     */
    function _setTokenPaymentAddress(address payable _paymentAddress, uint256 _tokenId) internal {
        tokenPaymentAddresses[_tokenId] = _paymentAddress;
    }

    /**
     * @dev set per token royalties
     * @param _tokenId token ID to set a individual royalties for
     * @param _basisPoints royalty basis point
     */
    function _setPerTokenRoyalties(uint256 _tokenId, uint32 _basisPoints) internal {
        require(_basisPoints <= 3000, 'Per token royalty must be less than 30%');
        perTokenRoyalties[_tokenId] = _basisPoints;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        override
        returns (address _receiver, uint256 _royaltyAmount)
    {
        _receiver = tokenPaymentAddresses[_tokenId];
        uint256 royaltyBasisPoints = globalCreatorRoyaltyBasisPoints;
        if (perTokenRoyalties[_tokenId] != 0) {
            royaltyBasisPoints = perTokenRoyalties[_tokenId];
        }
        _royaltyAmount = (_value * royaltyBasisPoints) / 10000;
    }
}