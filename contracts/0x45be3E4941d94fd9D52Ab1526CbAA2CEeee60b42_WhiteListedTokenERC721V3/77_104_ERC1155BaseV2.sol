// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../HasContractURI.sol";
import "../HasTokenURI.sol";
import "./ERC1155Supply.sol";
import "../../roles/MinterRole.sol";
import "../../libs/RoyaltyLibrary.sol";
import "../Royalty.sol";

abstract contract ERC1155BaseV2 is
HasTokenURI,
HasContractURI,
ERC1155Supply,
MinterRole,
Royalty
{
    string public name;
    string public symbol;

    /*
     * bytes4(keccak256('MINT_WITH_ADDRESS')) == 0xe37243f2
     */
    bytes4 private constant _INTERFACE_ID_MINT_WITH_ADDRESS = 0xe37243f2;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _tokenURIPrefix,
        string memory _uri
    ) HasContractURI(_contractURI) HasTokenURI(_tokenURIPrefix) ERC1155(_uri) public {
        name = _name;
        symbol = _symbol;
        _registerInterface(_INTERFACE_ID_MINT_WITH_ADDRESS);
    }

    // Creates a new token type and assings _initialSupply to minter
    function _mint(
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        uint256 _supply,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) internal {
        require(exists(_tokenId) == false, "ERC1155: Token is already minted");
        require(_supply != 0, "ERC1155: Supply should be positive");
        require(bytes(_uri).length > 0, "ERC1155: Uri should be set");

        _mint(msg.sender, _tokenId, _supply, "");
        _setTokenURI(_tokenId, _uri);
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps.add(_royaltyShares[i].value);
        }

        if(_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10**4,
                "ERC1155: Total fee bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10**4,
                "ERC1155: Total fee bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps,  RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        }else{
            revert("ERC1155: Royalty option does not exist");
        }

        _addRoyaltyShares(_tokenId, _royaltyShares);

        // Transfer event with mint semantic
        emit URI(_uri, _tokenId);
    }

    function burn(address _owner, uint256 _tokenId, uint256 _value) external {
        _burn(_owner, _tokenId, _value);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string memory _uri) override virtual internal {
        require(exists(_tokenId), "ERC1155: Token should exist");
        super._setTokenURI(_tokenId, _uri);
    }

    function setTokenURIPrefix(string memory _tokenURIPrefix) public onlyAdmin {
        _setTokenURIPrefix(_tokenURIPrefix);
    }

    function setContractURI(string memory _contractURI) public onlyAdmin {
        _setContractURI(_contractURI);
    }

    function uri(uint256 _tokenId) override external view returns (string memory) {
        return _tokenURI(_tokenId);
    }
}