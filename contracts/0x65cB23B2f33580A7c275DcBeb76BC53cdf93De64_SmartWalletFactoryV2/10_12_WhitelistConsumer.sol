// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/IWhitelist.sol";

abstract contract WhitelistConsumer {
    mapping(bytes1 => address) public whitelists;

    event WhitelistChanged(
        bytes1 _whitelistId,
        address _previousAddress,
        address _newAddress
    );

    modifier isWhitelistedOn(bytes1 whitelistId) {
        require(
            IWhitelist(whitelists[whitelistId]).isWhitelisted(msg.sender),
            "Sender is not whitelisted"
        );

        _;
    }

    function _setWhitelistAddress(
        address _whitelistAddress,
        bytes1 _whitelistId
    ) internal {
        if (_whitelistAddress != address(0)) {
            require(
                ERC165Checker.supportsInterface(
                    _whitelistAddress,
                    type(IWhitelist).interfaceId
                ),
                "Interface not supported"
            );
        }
        address previousAddress = whitelists[_whitelistId];
        whitelists[_whitelistId] = _whitelistAddress;
        emit WhitelistChanged(_whitelistId, previousAddress, _whitelistAddress);
    }
}