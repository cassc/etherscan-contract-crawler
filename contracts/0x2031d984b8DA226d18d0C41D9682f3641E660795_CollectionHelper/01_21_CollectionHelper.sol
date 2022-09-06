// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./Hinata721.sol";
import "./Hinata1155.sol";

contract CollectionHelper is Ownable, Pausable {
    string public baseURI;

    constructor(string memory uri) {
        baseURI = uri;
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function getType(address collection) external view returns (uint8) {
        uint256 csize;
        assembly {
            csize := extcodesize(collection)
        }
        if (csize == 0) return 0;

        bool is721;
        try IERC165(collection).supportsInterface(type(IERC721).interfaceId) returns (
            bool result1
        ) {
            is721 = result1;
            if (result1) return 1;
            try IERC165(collection).supportsInterface(type(IERC1155).interfaceId) returns (
                bool result2
            ) {
                return result2 ? 2 : 0;
            } catch {
                return 0;
            }
        } catch {
            return 0;
        }
    }

    function deploy(
        address owner,
        string memory name,
        string memory symbol,
        bool is721
    ) external whenNotPaused returns (address) {
        if (is721) {
            Hinata721 nft = new Hinata721(owner, name, symbol, baseURI);
            return address(nft);
        } else {
            Hinata1155 nft = new Hinata1155(owner, name, symbol, baseURI);
            return address(nft);
        }
    }
}