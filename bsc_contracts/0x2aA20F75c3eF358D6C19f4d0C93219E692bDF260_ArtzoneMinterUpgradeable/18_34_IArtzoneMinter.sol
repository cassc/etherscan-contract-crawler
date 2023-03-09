// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IArtzoneMinter {

  /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
  /**
   * @dev Emitted when a a new token is initialised on Artzone Minter.
   */
    event TokenInitialisation(
        uint256 indexed tokenId,
        uint256 maxQuantity,
        uint256 royaltyPercent,
        address royaltyAddr,
        string tokenUri
    );


     /**
   * @dev Emitted when a a token tokenURI access has been permanently locked.
   */
    event TokenAccessLock(
        uint256 tokenId
    );

  /*///////////////////////////////////////////////////////////////
                        Main Functions
    //////////////////////////////////////////////////////////////*/

  /**
   *  @notice Initialise metadata parameters of a token to allow subsequent minting.
   *
   *  @param _tokenURI       The tokenURI of token.
   *
   *  @param _maxQuantity    Maximum fixed quantity allowed for minting.
   *
   *  @param _royaltyRecipient   Secondary royalty receipient address.
   *
   *  @param _royaltyValue    Percentage value of royalties for each secondary sale of token based on ERC-2981 standard (out of 10,000 BPS).
   *
   *  @param _accessToUpdateToken   Edit access to override tokenURI of token in the future.
   *
   */
  function initialiseToken(
    string memory _tokenURI, 
    uint256 _maxQuantity,
    address _royaltyRecipient,
    uint256 _royaltyValue,
    bool _accessToUpdateToken
    ) external;

  /**
   *  @notice Mint token to a specified address with a specified quantity.
   *
   *  @param _tokenId   TokenId of token to be minted.
   *
   *  @param _quantity  The desired quantity to be minted.
   *
   *  @param _receiver   Receiver address for token to be minted to.
   *
   */
    function mintToken(
        uint256 _tokenId,
        uint256 _quantity,
        address _receiver
    ) external;

  /**
    * @notice Batch minting of multiple tokenIds with varying respective quantities to a receipient, permission only exclusive to whitelisted admin wallet.
   *
   *  @param _tokens   List of tokens to be minted in the batch.
   *
   *  @param _quantities   Respective quantities of each tokens specified in the batch mint.
   *
   *  @param _receiver   Receiver address for token batch.
   *
   */
  function batchMintToken(uint256[] memory _tokens, uint256[] memory _quantities, address _receiver) external;

  /**
   * @notice One way lock of locking up tokenURI update access, only permissable by admins.
   *
   *  @param _tokenId   TokenId to lock token access update.
   */
   function lockTokenUpdateAccess(uint256 _tokenId) external;

  /**
  * @notice For admins to override existing tokenURI should it be allowed to.
   *
   *  @param _tokenId   TokenId to override existing tokenURI with new one.
   *
   *  @param _newUri    New tokenURI to override existing one.
   *
   */
  function overrideExistingURI(
        uint256 _tokenId,
        string memory _newUri
    ) external;

//   /**
//      * @notice To query creator royalties info based on ERC2981 Implementation.
//     *
//     * @param _tokenId    The tokenId initialised on ArtzoneMinter to be queried for.
//     *
//     * @param _value      The base value of sale to be calculated from.
//    */
//    function royaltyInfo(uint256 _tokenId, uint256 _value)
//         external
//         view
//         returns (address, uint256);

//       /**
//     * @notice Total amount of tokens minted in with a given tokenId.
//     *
//     * @param _tokenId    The tokenId initialised on ArtzoneMinter to be queried for.
//     *
//    */
//    function totalSupply(uint256 _tokenId) external view returns (uint256);
}