// contracts/PrivateVaultAccess.sol
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

error ArrayLengthMismatch();
error TokenIndexOutOfBounds();


/// @title PrivateVaultAccess
/// @author Teahouse Finance
contract PrivateVaultAccess is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol) {}

    function devMint(uint256 _amount, address _to) public onlyOwner {
        _safeMint(_to, _amount);
    }

    function batchDevMint(uint256[] memory _amount, address[] memory _to) external {
        if (_amount.length != _to.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < _amount.length; i++) {
            devMint(_amount[i], _to[i]);
        }
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    function ownedTokens(address _addr, uint256 _startId, uint256 _endId) external view returns (uint256[] memory tokenIds, uint256 endTokenId) {
        if (_endId == 0) {
            _endId = _nextTokenId() - 1;
        }

        if (_startId < _startTokenId() || _endId >= _nextTokenId()) revert TokenIndexOutOfBounds();

        uint256 i;
        uint256 balance = balanceOf(_addr);
        if (balance == 0) {
            return (new uint256[](0), _endId + 1);
        }

        if (balance > 256) {
            balance = 256;
        }

        uint256[] memory results = new uint256[](balance);
        uint256 idx = 0;
        
        address owner = ownerOf(_startId);
        for (i = _startId; i <= _endId; i++) {
            if (_ownershipOf(i).addr != address(0)) {
                owner = _ownershipOf(i).addr;
            }

            if (!_ownershipOf(i).burned && owner == _addr) {
                results[idx] = i;
                idx++;

                if (idx == balance) {
                    if (balance == balanceOf(_addr)) {
                        return (results, _endId + 1);
                    }
                    else {
                        return (results, i + 1);
                    }
                }
            }
        }
    }


    function _startTokenId() override internal view virtual returns (uint256) {
        // the starting token Id
        return 1;
    }
}