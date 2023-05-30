// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC2981 is ERC165, IERC2981 {

    struct RoyaltyInfo {
        // Fee in Basis Points
        uint64 fee;
        address receiver;
    }


    RoyaltyInfo private _default;

    mapping(uint256 => RoyaltyInfo) private _info;


    constructor(address receiver, uint64 fee) {
        _default = RoyaltyInfo({
            fee: fee,
            receiver: receiver
        });
    }


    function _setDefaultRoyaltyInfo(address receiver, uint64 fee) internal {
        _default = RoyaltyInfo({
            fee: fee,
            receiver: receiver
        });
    }

    function _setRoyaltyInfo(uint256 tokenId, address receiver, uint64 fee) internal {
        _info[tokenId] = RoyaltyInfo({
            fee: fee,
            receiver: receiver
        });
    }

    function royaltyInfo(uint256 tokenId, uint256 amount) external view override(IERC2981) returns(address, uint256) {
        uint64 fee = _info[tokenId].fee;
        address receiver = _info[tokenId].receiver;

        if (receiver == address(0) || fee == 0) {
            fee = _default.fee;
            receiver = _default.receiver;
        }

        return (receiver, (amount * uint256(fee) / 10000));
    }

    function supportsInterface(bytes4 interfaceId) override(ERC165, IERC165) public view virtual returns(bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}