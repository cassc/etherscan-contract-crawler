// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/introspection/ERC165Checker.sol";

import "./IEulerBeatsRoyaltyReceiver.sol";


contract RoyaltyDistributor {

    using Address for address payable;

    function _distributeRoyalty(
        uint256 tokenId,
        address payable tokenOwner,
        uint256 royalty
    ) internal {
        require(royalty > 0, "Missing royalty");

        // this logic is broken into three cases:
        // case 1: tokenOwner is a contract that implements RoyaltyReciever
        // case 2: tokenOwner is a contract but not a RoyaltyReceiver
        // case 3: tokenOwner is not a contract

        if (tokenOwner.isContract()) {
            if (ERC165Checker.supportsInterface(tokenOwner, IEulerBeatsRoyaltyReceiver(tokenOwner).royaltyReceived.selector)) {
                // case 1
                require(address(this).balance >= royalty, "RoyaltyDistributor: insufficient balance");
                try IEulerBeatsRoyaltyReceiver(tokenOwner).royaltyReceived{value: royalty}(address(this), tokenId, tokenOwner) returns (bytes4 response) {
                    if (response != IEulerBeatsRoyaltyReceiver(tokenOwner).royaltyReceived.selector) {
                        revert("IEulerBeatsRoyaltyReceiver rejected royalty");
                    }
                } catch Error(string memory reason) {
                    revert(reason);
                } catch {
                    revert("RoyaltyDistributor: royaltyReceived reverted");
                }
            } else {
                // case 2
                tokenOwner.sendValue(royalty);
            }
        } else {
            // case 3
            tokenOwner.sendValue(royalty);
        }

    }

}