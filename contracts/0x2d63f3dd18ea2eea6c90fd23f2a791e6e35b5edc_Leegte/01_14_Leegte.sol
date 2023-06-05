// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/**
          _____            _____                    _____                    _____                _____                    _____          
         /\    \          /\    \                  /\    \                  /\    \              /\    \                  /\    \         
        /::\____\        /::\    \                /::\    \                /::\    \            /::\    \                /::\    \        
       /:::/    /       /::::\    \              /::::\    \              /::::\    \           \:::\    \              /::::\    \       
      /:::/    /       /::::::\    \            /::::::\    \            /::::::\    \           \:::\    \            /::::::\    \      
     /:::/    /       /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \           \:::\    \          /:::/\:::\    \     
    /:::/    /       /:::/__\:::\    \        /:::/__\:::\    \        /:::/  \:::\    \           \:::\    \        /:::/__\:::\    \    
   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \      /:::/    \:::\    \          /::::\    \      /::::\   \:::\    \   
  /:::/    /       /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/    / \:::\    \        /::::::\    \    /::::::\   \:::\    \  
 /:::/    /       /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/    /   \:::\ ___\      /:::/\:::\    \  /:::/\:::\   \:::\    \ 
/:::/____/       /:::/__\:::\   \:::\____\/:::/__\:::\   \:::\____\/:::/____/  ___\:::|    |    /:::/  \:::\____\/:::/__\:::\   \:::\____\
\:::\    \       \:::\   \:::\   \::/    /\:::\   \:::\   \::/    /\:::\    \ /\  /:::|____|   /:::/    \::/    /\:::\   \:::\   \::/    /
 \:::\    \       \:::\   \:::\   \/____/  \:::\   \:::\   \/____/  \:::\    /::\ \::/    /   /:::/    / \/____/  \:::\   \:::\   \/____/ 
  \:::\    \       \:::\   \:::\    \       \:::\   \:::\    \       \:::\   \:::\ \/____/   /:::/    /            \:::\   \:::\    \     
   \:::\    \       \:::\   \:::\____\       \:::\   \:::\____\       \:::\   \:::\____\    /:::/    /              \:::\   \:::\____\    
    \:::\    \       \:::\   \::/    /        \:::\   \::/    /        \:::\  /:::/    /    \::/    /                \:::\   \::/    /    
     \:::\    \       \:::\   \/____/          \:::\   \/____/          \:::\/:::/    /      \/____/                  \:::\   \/____/     
      \:::\    \       \:::\    \               \:::\    \               \::::::/    /                                 \:::\    \         
       \:::\____\       \:::\____\               \:::\____\               \::::/    /                                   \:::\____\        
        \::/    /        \::/    /                \::/    /                \::/____/                                     \::/    /        
         \/____/          \/____/                  \/____/                                                                \/____/         
                                                                                                                                          
 */

/// @author Jake Allen
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IDescriptor.sol";
import { Base64 } from 'base64-sol/base64.sol';

contract Leegte is Ownable, ERC721 {
    using Strings for uint256;

    // mint count tokenId tracker
    uint256 public nextTokenId;

    // contract level details
    string public baseContractURI;

    /**
     * @dev specifies the type of URI requested for a string
     * @param SVG will append 'data:image/svg+xml;base64,' before base64 encoding this value
     * @param HTML will append 'data:text/html;base64,' before base64 encoding this value
     * @param URL will not do any transformations. pass a plain URL string or a data URI
     * that is already properly encoded
     */
    enum UriType { SVG, HTML, URL }

    /**
     * @dev only added for a token id if it is specified as `isOnChain`
     * @param image a plain string of the on chain work, either SVG, HTML, or
     * a wildcard data type (in which case uploader must handle base64 encoding)
     * @param imageUriType specifies how the dataURI should be constructed. if wildcard,
     * the dataURI must be appended as part of the artwork
     * @param animationUrl optional value that may also be an on chain work
     * @param animationUrlUriType data type of the optional animationUrl
     * @param jsonKeyValues DO NOT INCLUDE CURLY BRACKETS, just the key-values.  the
     * brackets will be appended by the contract.
     */
    struct OnChainData {
        string image;
        UriType imageUriType;
        string animationUrl;
        UriType animationUrlUriType;
        string jsonKeyValues;
    }

    /// @dev the following three mappings store different kinds of tokenURI data.
    /// only one of them is needed per tokenId.

    // mapping of optional tokenURI strings per tokenId (if applicable)
    mapping(uint256 => string) public urisByTokenId;

    // mapping of optional descriptor address per tokenId (diverts tokenURI call)
    mapping(uint256 => address) public descriptorsByTokenId;

    // mapping of on chain token data (if applicable) by tokenId
    mapping(uint256 => OnChainData) public onChainDataByTokenId;

    constructor() ERC721("Jan Robert Leegte", "JRL") {}

    /**
     * @dev Return tokenURI directly or via alternative `descriptor` contract
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        // check for descriptor diversion
        if (descriptorsByTokenId[tokenId] != address(0)) {
            return IDescriptor(descriptorsByTokenId[tokenId]).tokenURI(tokenId);
        }

        // check on chain data
        if (bytes(onChainDataByTokenId[tokenId].image).length != 0) {
            OnChainData memory data = onChainDataByTokenId[tokenId];
            // base64 encode the image
            string memory image = buildURI(data.image, data.imageUriType);
            image = string(abi.encodePacked('"image": "', image, '"'));
            // check if animationUrl exists for this token, and if so process it
            if (bytes(data.animationUrl).length != 0) {
                string memory animationUrl;
                animationUrl = buildURI(data.animationUrl, data.animationUrlUriType);
                image = string(abi.encodePacked(image, ', "animation_url": "', animationUrl, '"'));
            }
            string memory json;
            if (bytes(data.jsonKeyValues).length != 0) {
                // concat image and rest of json, then base64 encode it
                json = Base64.encode(
                    abi.encodePacked('{',
                    image,
                    ', ',
                    data.jsonKeyValues,
                    '}')
                );
            } else {
                // concat image and rest of json, then base64 encode it
                json = Base64.encode(
                    abi.encodePacked('{', image, '}')
                );
            }
            
            // prepend the base64 prefix
            return string(abi.encodePacked('data:application/json;base64,', json));
        }

        // else return basic tokenUri
        return urisByTokenId[tokenId];
    }

    function buildURI(string memory uriValue, UriType uriType) public pure returns (string memory) {
        if (uriType == UriType.SVG) {
            return string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(uriValue))
                )
            );
        } else if (uriType == UriType.HTML) {
            return string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    Base64.encode(bytes(uriValue))
                )
            );
        }
        
        return uriValue;
    }

    /**
     * @dev Returns contract-level metadata details
     */
    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    // ========================== ADMIN FUNCTIONS ==============================
    
    /**
     * @dev Accepts two bits of data which are mutually exclusive. pass in null
     * values for the one you're not going to use.
     * @param _uri a string representing an off-chain URL/URI to point to
     * @param _onChainData optional OnChainData struct, if work is on chain
     */
    function mint(
        string calldata _uri,
        OnChainData calldata _onChainData
    ) external onlyOwner {
        // save urisByTokenId data
        urisByTokenId[nextTokenId] = _uri;
        // conditionally save on chain data
        if (bytes(_onChainData.image).length != 0) {
            onChainDataByTokenId[nextTokenId] = _onChainData;
        }
        // mint token
        _mint(msg.sender, nextTokenId++);
    }

    /**
     * @dev see mint function for params. to delete simply pass in null values
     */
    function updateTokenData(
        uint256 tokenId,
        string calldata _uri,
        OnChainData calldata _onChainData
    ) external onlyOwner {
        urisByTokenId[tokenId] = _uri;

        if (bytes(_onChainData.image).length != 0) {
            // delete and then add, otherwise you can't null out values
            delete onChainDataByTokenId[tokenId];
            onChainDataByTokenId[tokenId] = _onChainData;
        } else {
            delete onChainDataByTokenId[tokenId];
        }
    }

    /**
     * @dev Setting this will divert tokenURI calls to the address indicated. set
     * to null address to delete the value.
     */
    function updateDescriptor(
        uint256 tokenId,
        address descriptor
    ) external onlyOwner {
        descriptorsByTokenId[tokenId] = descriptor;
    }

    /**
     * @dev Let owner update base contract level metadata
     */
    function updateBaseContractURI(string memory _baseContractURI) external onlyOwner {
        baseContractURI = _baseContractURI;
    }

    /**
     * @dev Let contract owner delete a token mistakenly minted, as long as it isn't owned
     * by anybody
     */
    function burn(uint256 tokenId) external onlyOwner {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }

}