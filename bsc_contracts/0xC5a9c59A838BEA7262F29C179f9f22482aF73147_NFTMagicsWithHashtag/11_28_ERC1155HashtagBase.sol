// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './ERC1155Base.sol';

abstract contract ERC1155HashtagBase is ERC1155Base {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    mapping(uint256 => string) internal _id2hashtag;
    mapping(string => uint256) internal _hashtag2id;

    function createItemWithNative(
        string calldata hashtag,
        string calldata url,
        address to,
        uint256 royalty,
        bool participateInDistributed
    ) public payable returns (uint256) {
        require(_prices[TokenType.Native][_ONE] != 0, 'Invalid quantity!');
        require(
            msg.value >=
                (
                    participateInDistributed
                        ? _prices[TokenType.Native][_ONE] +
                            _distributedParticipationFee
                        : _prices[TokenType.Native][_ONE]
                ),
            _INSUFFICIENT_VALUE
        );

        if (participateInDistributed) {
            address userAddress = _msgSender();
            _validateDistributedParticipation(userAddress, TokenType.Native);
        }

        _handleNativeFunding(msg.value, participateInDistributed);

        uint256 id = _createItem(
            hashtag,
            url,
            to,
            royalty,
            TokenType.Native,
            participateInDistributed
        );
        return id;
    }

    function getHashTagWithIndex(
        uint256 id
    ) public view returns (string memory) {
        return _id2hashtag[id];
    }

    function getIndexWithHashTag(
        string calldata to
    ) public view returns (uint256) {
        return _hashtag2id[to];
    }

    function _createItem(
        string calldata hashtag,
        string calldata url,
        address to,
        uint256 royalty,
        TokenType _mintTokenType,
        bool participateInDistributed
    ) internal returns (uint256) {
        require(
            royalty >= _ONE && royalty <= _TEN,
            'royalty should be 1% - 10%'
        );

        if (_hashtag2id[hashtag] > _ZERO) {
            revert('Hashtag already in use');
        }

        _nftIds.increment();
        uint256 id = _nftIds.current();

        _setURI(id, url);

        _id2hashtag[id] = hashtag;
        _hashtag2id[hashtag] = id;

        itemDetails[id].mintTokenType = _mintTokenType;
        itemDetails[id].creator = _msgSender();
        itemDetails[id].royalty = royalty;

        _mint(to, id, _ONE, '');

        _purchaseLotteryTicketsForUser(_msgSender(), _ONE);

        if (participateInDistributed) {
            IDistributedRewardsPot(distributed).noteUserMintParticipation(
                _msgSender(),
                _mintTokenType
            );
        }

        return id;
    }
}