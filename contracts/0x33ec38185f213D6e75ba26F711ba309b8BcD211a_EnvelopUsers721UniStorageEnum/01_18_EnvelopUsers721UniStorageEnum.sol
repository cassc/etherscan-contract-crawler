// SPDX-License-Identifier: MIT
// ENVELOP protocol for NFT. Mintable User NFT Collection
pragma solidity 0.8.16;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "EnvelopUsers721Swarm.sol";
import "Subscriber.sol";


contract EnvelopUsers721UniStorageEnum is ERC721Enumerable, Ownable, Subscriber {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Strings for uint160;

    
    string private _baseTokenURI;
    
    // Oracle signers status
    mapping(address => bool) public oracleSigners;
    
    // mapping from url prefix to baseUrl
    mapping(bytes4 => string) public baseByPrefix;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl,
        uint256 _code
    ) 
        ERC721(name_, symbol_)
        Subscriber(_code)  
    {
        _baseTokenURI = string(
            abi.encodePacked(
                _baseurl,
                block.chainid.toString(),
                "/",
                uint160(address(this)).toHexString(),
                "/"
            )
        );

    }

    
    //////////////////////////////////////////////////////////////////////
    ///  Section below is OppenZeppelin ERC721URIStorage inmplementation /
    //////////////////////////////////////////////////////////////////////

     // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        // ------------------------------------
        // For public Envelop mint app 
        bytes4 prefix = bytes4(bytes(_tokenURI));

        if (
              prefix == bytes4(bytes("bzz:")) ||
              prefix == bytes4(bytes("ipfs"))
            ) 
        {
            base = baseByPrefix[prefix];
        }
        // --------------------------------------
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    
    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////

    function mintWithURI(
        address _to, 
        uint256 _tokenId, 
        string calldata _tokenURI, 
        bytes calldata _signature
    ) public {
        // If signature present - lets checkit
        if (_signature.length > 0) {
            bytes32 msgMustWasSigned = keccak256(abi.encode(
                msg.sender,
                _tokenId,
                _tokenURI
            )).toEthSignedMessageHash();

            // Check signature  author
            require(oracleSigners[msgMustWasSigned.recover(_signature)], "Unexpected signer");

        // If there is no signature then sender must have valid status
        } else {
            require(
                _checkAndFixSubscription(msg.sender),
                "Has No Subscription"
            );

        }
        _mintWithURI(_to, _tokenId, _tokenURI);
    }

    function mintWithURIBatch(
        address[] calldata _to, 
        uint256[] calldata _tokenId, 
        string[] calldata _tokenURI, 
        bytes[] calldata _signature
    ) external {
        for (uint256 i = 0; i < _to.length; i ++){
            mintWithURI(_to[i], _tokenId[i], _tokenURI[i], _signature[i]);
        }
    }

    //////////////////////////////
    //  Admin functions        ///
    //////////////////////////////
    function setSignerStatus(address _signer, bool _status) external onlyOwner {
        oracleSigners[_signer] = _status;
    }

    function setSubscriptionManager(address _manager) external onlyOwner {
        _setSubscriptionManager(_manager);
    }

    function setPrefixURI(bytes4 _prefix, string memory _base)
        public 
        virtual
        onlyOwner 
    {
        baseByPrefix[_prefix] = _base;
    }
    ///////////////////////////////
    function _mintWithURI(address _to, uint256 _tokenId, string memory _tokenURI)
        internal 
    {
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function baseURI() external view  returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view  override returns (string memory) {
        return _baseTokenURI;
    }
}