// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;


/// @title CryptopiaEarlyAccess Token
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaEarlyAccessToken {


    /**
     * Public functions
     */
    /// @dev Initializes the token contract
    /// @param _proxyRegistry Whitelist for easy trading
    /// @param _initialContractURI Location to contract info
    /// @param _initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function initialize(
        address _proxyRegistry, 
        string calldata _initialContractURI, 
        string calldata _initialBaseTokenURI) external;


    /// @dev Get contract URI
    /// @return Location to contract info
    function getContractURI() external view returns (string memory);


    /// @dev Set contract URI
    /// @param _uri Location to contract info
    function setContractURI(string memory _uri) external;


    /// @dev Get base token URI 
    /// @return Base of location where token data is stored. To be postfixed with tokenId
    function getBaseTokenURI() external view returns (string memory);


    /// @dev Set base token URI 
    /// @param _uri Base of location where token data is stored. To be postfixed with tokenId
    function setBaseTokenURI(string memory _uri) external;


    /// @dev getTokenURI() postfixed with the token ID baseTokenURI(){tokenID}
    /// @param _tokenId Token ID
    /// @return Location where token data is stored
    function getTokenURI(uint _tokenId) external view returns (string memory);


    /// @dev Mints a token to an address.
    /// @param _to address of the future owner of the token
    /// @param _referrer referrer that's added to the token uri
    /// @param _faction faction that's added to the token uri
    function mintTo(address _to, uint _referrer, uint8 _faction) external;
}