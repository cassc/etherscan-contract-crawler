// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract Airdrop is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function multisendToken(
        IERC721Upgradeable token,
        address[] memory recipients,
        uint256[] memory tokenIds
    ) external onlyOwner{
        require(recipients.length == tokenIds.length, "Incorrect length" );
        for (uint256 i = 0; i < recipients.length; i++){
         token.safeTransferFrom(msg.sender,recipients[i], tokenIds[i]);
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}