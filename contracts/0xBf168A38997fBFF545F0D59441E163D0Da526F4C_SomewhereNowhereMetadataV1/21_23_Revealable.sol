// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';
import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import './interfaces/IRevealable.sol';
import './Roles.sol';

abstract contract Revealable is IRevealable, Roles, VRFV2WrapperConsumerBase {
    address private immutable _linkAddress;

    uint32 private _callbackGasLimit = 50000;
    string private _defaultURI;
    string private _revealedBaseURI;
    uint256 private _seed;

    constructor(address linkAddress, address wrapperAddress)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        _linkAddress = linkAddress;
    }

    function requestRandomSeed() external virtual override onlyController {
        uint256 requestId = requestRandomness(_callbackGasLimit, 3, 1);

        emit RandomnessRequested(block.timestamp, requestId);
    }

    function setCallbackGasLimit(uint32 callbackGasLimit)
        public
        virtual
        override
        onlyController
    {
        _callbackGasLimit = callbackGasLimit;

        emit CallbackGasLimitUpdated(callbackGasLimit);
    }

    function setDefaultURI(string memory defaultURI)
        public
        virtual
        override
        onlyController
    {
        _defaultURI = defaultURI;

        emit DefaultURIUpdated(defaultURI);
    }

    function setRevealedBaseURI(string memory revealedBaseURI)
        public
        virtual
        override
        onlyController
    {
        _revealedBaseURI = revealedBaseURI;

        emit RevealedBaseURIUpdated(revealedBaseURI);
    }

    function setSeed(uint256 seed) public virtual override onlyController {
        if (_seed > 0) revert SeedIsAlreadySet();

        _setSeed(seed);
    }

    function withdrawLink() public virtual override onlyController {
        LinkTokenInterface link = LinkTokenInterface(_linkAddress);

        if (!link.transfer(_msgSender(), link.balanceOf(address(this))))
            revert CannotTransferLink();
    }

    function isRevealed() public view virtual override returns (bool) {
        return _seed > 0;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        uint256 randomWord = randomWords[0];
        if (randomWord > 0) {
            emit RandomnessSucceeded(block.timestamp, requestId, randomWord);

            _setSeed(randomWord);
        } else {
            emit RandomnessFailed(block.timestamp, requestId, randomWord);
        }
    }

    function _setSeed(uint256 seed) internal virtual {
        _seed = seed;

        emit SeedUpdated(seed);
    }

    function _getDefaultURI() internal view virtual returns (string memory) {
        return _defaultURI;
    }

    function _getRevealedBaseURI()
        internal
        view
        virtual
        returns (string memory)
    {
        return _revealedBaseURI;
    }

    function _getShuffledId(uint256 supply, uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256[] memory data = new uint256[](supply + 1);
        data[0] = supply;
        for (uint256 i = 1; i <= supply; ++i) {
            data[i] = i;
        }
        for (uint256 i = 1; i <= tokenId; ++i) {
            uint256 j = i +
                (uint256(keccak256(abi.encode(_seed, i))) % data[0]);
            (data[i], data[j]) = (data[j], data[i]);
            --data[0];
        }
        return data[tokenId];
    }
}