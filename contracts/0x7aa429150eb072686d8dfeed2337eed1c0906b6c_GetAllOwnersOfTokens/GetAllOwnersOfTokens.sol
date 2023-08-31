/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract GetAllOwnersOfTokens {
    function getAllOwnersOfTokens(address contract_, uint256 from_, uint256 to_) external view returns (address[] memory) {
        uint256 l = to_ - from_ + 1;
        uint256 index;
        address[] memory _addresses = new address[] (l);
        for (uint256 i = from_; i <= to_;) {
            try IERC721(contract_).ownerOf(i) returns (address _owner) {
                _addresses[index] = _owner;
            }
            catch {
                _addresses[index] = address(0);
            }
            unchecked { ++index; ++i; }
        }
        return _addresses;
    }
    function getAllOwnersOfTokenArray(address contract_, uint256[] calldata tokenIds_) external view returns (address[] memory) {
        uint256 l = tokenIds_.length;
        address[] memory _addresses = new address[] (l);
        for (uint256 i = 0; i < l;) {
            try IERC721(contract_).ownerOf(i) returns (address _owner) {
                _addresses[i] = _owner;
            }
            catch {
                _addresses[i] = address(0);
            }
            unchecked { ++i; }
        }
        return _addresses;
    }
}