// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Interfaces/IArtzoneMinter.sol";
import "./Helpers/ERC2981/ERC2981RoyaltiesPerToken.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev Core ERC1155 creator implementation
 */
abstract contract ArtzoneMinter is IArtzoneMinter, ERC2981RoyaltiesPerToken {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 constant public VERSION = 2;

    /*///////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => uint256) internal _tokenSupply;
    mapping(uint256 => uint256) internal _tokenMaxSupply;
    mapping(uint256 => string) internal _tokenIdUri;
    mapping(uint256 => bool) internal _tokenUpdateAccess;


     /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

     /// @dev Checks if the token has been initialised prior to minting.
    modifier validateInitialisedToken(uint256 _tokenId){
        require(_tokenId <= _tokenIds.current(), "Uninitialised token.");
        _;
    }

      /// @dev Checks if the quantity specified for minting is valid.
    modifier validateMint(uint256 _tokenId, uint256 _quantity){
        require(_quantity != 0, "Mint quantity cannot be 0.");
        require(_tokenSupply[_tokenId] + _quantity <= _tokenMaxSupply[_tokenId], "Invalid quantity specified.");
        _;
    }

    /// @dev Checks if the quantities specified for batch minting is valid.
    modifier validateBatchMint(uint256[] memory _tokens, uint256[] memory _quantities){
        require(_tokens.length == _quantities.length, "Mismatch token quantities");
        for (uint256 i = 0; i < _tokens.length;){
            require(_quantities[i] != 0, "Mint quantity cannot be 0.");
            require(_tokenSupply[_tokens[i]] + _quantities[i] <= _tokenMaxSupply[_tokens[i]], "Invalid quantity specified.");

            unchecked{
                i++;
            }
        }
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IArtzoneMinter).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _value) public view virtual override returns (address, uint256) {
        return super.royaltyInfo(_tokenId, _value);
    }
}