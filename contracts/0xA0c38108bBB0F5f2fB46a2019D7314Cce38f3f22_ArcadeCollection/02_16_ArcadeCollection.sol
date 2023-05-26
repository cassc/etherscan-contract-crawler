// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ArcadeBaseCollection.sol";
import "./lib/String.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ArcadeCollection is ArcadeBaseCollection {
    using SafeMath for uint256;

    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev Create the contract.
     * @param _name - name of the contract
     * @param _symbol - symbol of the contract
     * @param _operator - Address allowed to mint tokens
     * @param _baseURI - base URI for token URIs
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _operator,
        string memory _baseURI
    ) ArcadeBaseCollection(_name, _symbol, _operator, _baseURI) {}

    /**
     * @dev Issue a new NFT of the specified kind.
     * @notice that will throw if kind has reached its maximum or is invalid
     * @param _beneficiary - owner of the token
     * @param _gameId - token game
     */
    function issueToken(address _beneficiary, string calldata _gameId) 
        external
        payable
    {
        _issueToken(_beneficiary, _gameId);
    }

    /**
     * @dev Issue a new NFT of the specified kind.
     * @notice that will throw if kind has reached its maximum or is invalid
     * @param _beneficiary - owner of the token
     * @param _gameId - token game
     * @param _nbrOfTokens - Number of tokens to mint
     */
    function issueTokens(address _beneficiary, string calldata _gameId, uint256 _nbrOfTokens)
        external
        payable
    {
        bytes32 key = getGameKey(_gameId);
        require(collectionPrice[key].mul(_nbrOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < _nbrOfTokens; i++) {  
            _issueToken(_beneficiary, _gameId);
        }
    }

    /**
     * @dev Issue a new NFT of the specified kind.
     * @notice that will throw if kind has reached its maximum or is invalid
     * @param _beneficiary - owner of the token
     * @param _gameId - token game
     */
    function _issueToken(address _beneficiary, string memory _gameId) internal {
        bytes32 key = getGameKey(_gameId);
        uint256 issuedId = issued[key] + 1;
        uint256 tokenId = this.totalSupply();

        _mint(_beneficiary, tokenId, key, _gameId, issuedId);
        _setTokenURI(
            tokenId,
            string(
                abi.encodePacked(
                    gameURIs[key],
                    "/",
                    String.uint2str(issuedId),
                    ".json"
                )
            )
        );
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param _tokenId - uint256 ID of the token to set as its URI
     * @param _uri - string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string memory _uri) internal {
        _tokenPaths[_tokenId] = _uri;
    }

    /**
     * @dev Burns the speficied token.
     * @param tokenId - token id
     */
    function burn(uint256 tokenId) external onlyAllowed {
        super._burn(tokenId);

        if (bytes(_tokenPaths[tokenId]).length != 0) {
            delete _tokenPaths[tokenId];
        }
    }
}