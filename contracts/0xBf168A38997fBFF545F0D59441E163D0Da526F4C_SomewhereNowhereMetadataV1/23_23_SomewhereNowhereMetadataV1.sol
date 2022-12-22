// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';
import './interfaces/ISomewhereNowhere.sol';
import './interfaces/ISomewhereNowhereMetadataV1.sol';
import './lib/Revealable.sol';

contract SomewhereNowhereMetadataV1 is ISomewhereNowhereMetadataV1, Revealable {
    using Strings for uint256;

    address private _tokenContractAddress;

    constructor(
        address tokenContractAddress,
        address linkAddress,
        address wrapperAddress,
        string memory defaultURI
    ) Ownable(_msgSender()) Revealable(linkAddress, wrapperAddress) {
        setControllerAddress(_msgSender());
        setTokenContractAddress(tokenContractAddress);
        setDefaultURI(defaultURI);
    }

    function setTokenContractAddress(address tokenContractAddress)
        public
        override
        onlyController
    {
        _tokenContractAddress = tokenContractAddress;

        emit TokenContractAddressUpdated(tokenContractAddress);
    }

    function getTokenContractAddress() public view override returns (address) {
        return _tokenContractAddress;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_tokenContractAddress == address(0))
            revert TokenContractAddressIsZeroAddress();

        return
            isRevealed()
                ? string(
                    abi.encodePacked(
                        _getRevealedBaseURI(),
                        _getShuffledId(
                            ISomewhereNowhere(_tokenContractAddress)
                                .getGlobalSupply(),
                            tokenId
                        ).toString(),
                        '.json'
                    )
                )
                : _getDefaultURI();
    }
}