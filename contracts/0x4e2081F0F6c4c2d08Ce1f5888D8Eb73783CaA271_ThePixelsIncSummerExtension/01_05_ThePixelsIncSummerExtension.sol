// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./../../common/interfaces/IThePixelsIncExtensionStorageV2.sol";
import "./../../common/interfaces/ICoreRewarder.sol";

contract ThePixelsIncSummerExtension is Ownable {
    address public immutable extensionStorageAddress;
    address public immutable rewarderAddress;

    constructor(address _extensionStorageAddress, address _rewarderAddress) {
        extensionStorageAddress = _extensionStorageAddress;
        rewarderAddress = _rewarderAddress;
    }

    function extendMultiple(uint256[] memory _tokenIds, uint256[] memory _salts)
        public
    {
        for (uint256 i; i < _tokenIds.length; i++) {
            extend(_tokenIds[i], _salts[i]);
        }
    }

    function extend(uint256 _tokenId, uint256 _salt) public {
        uint256 currentVariant = IThePixelsIncExtensionStorageV2(
            extensionStorageAddress
        ).currentVariantIdOf(1, _tokenId);

        require(currentVariant == 0, "Token has already summer extension");

        uint256 rnd = _rnd(_tokenId, _salt) % 105;
        uint256 variant;

        if (rnd >= 100 && rnd < 105) {           
            variant = 6;                        // 5
        } else if (rnd >= 90 && rnd < 100) {
            variant = 5;                        // 10
        } else if (rnd >= 75 && rnd < 90) {
            variant = 4;                        // 15
        } else if (rnd >= 55 && rnd < 75) {
            variant = 3;                        // 20
        } else if (rnd >= 30 && rnd < 55) {
            variant = 2;                        // 25
        } else if (rnd < 30) {
            variant = 1;                        // 30
        }

        IThePixelsIncExtensionStorageV2(extensionStorageAddress)
            .extendWithVariant(msg.sender, 1, _tokenId, variant, false, 0);
    }

    function _rnd(uint256 _tokenId, uint256 _salt)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        _tokenId,
                        _salt
                    )
                )
            );
    }
}