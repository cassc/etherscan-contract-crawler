// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollection is ERC721Burnable, Ownable {

    event ItemCreated(
        address indexed owner,
        uint256 indexed tokenId
    );

    struct TokenExtraInfo {
        string metaDataURI;
        string metaData;
        bytes32 metaDataHash;
    }

    mapping (uint256 => TokenExtraInfo) public extraInfoMap;
    uint internal _totalSupply;
    // Used to correctly support fingerprint verification for the assets
    bytes4 public constant _INTERFACE_ID_ERC721_VERIFY_FINGERPRINT = bytes4(
        keccak256("verifyFingerprint(uint256,bytes32)")
    );

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    )
        public ERC721(_name, _symbol)
    {
        _setBaseURI(_baseUri);

        // Registers
        _registerInterface(_INTERFACE_ID_ERC721_VERIFY_FINGERPRINT);
    }

    /**
     * Set new uri
     * @param _baseUri for the token
     */
    function setURI(string memory _baseUri) external onlyOwner {
        _setBaseURI(_baseUri);
    }


    /**
     * Creates a NFT
     * @param _metaDataURI for the new token
     * @param _metaData metadata JSONified string
     */
    function create(
        string calldata _metaDataURI,
        string calldata _metaData
    )
        external
    {
        _create(msg.sender, _metaDataURI, _metaData);
    }

    function _create(
        address _owner,
        string memory _metaDataURI,
        string memory _metaData
    )
        internal returns (uint256 tokenId)
    {
        tokenId = ++_totalSupply;

        /// Save data
        extraInfoMap[tokenId] = TokenExtraInfo({
            metaDataURI: _metaDataURI,
            metaData: _metaData,
            metaDataHash: getMetaDataHash(_metaData)
        });

        /// Mint new NFT
        _mint(_owner, tokenId);
        _setTokenURI(tokenId, _metaDataURI);

        emit ItemCreated(_owner, tokenId);
    }

    function getMetaDataHash(string memory _metaData) public pure returns (bytes32) {
        bytes32 msgHash = keccak256(abi.encodePacked(_metaData));

        // return prefixed hash, see: eth_sign()
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
        );
    }

    function verifyFingerprint(uint256 _tokenId, bytes32 _fingerprint) external view returns (bool) {
        return extraInfoMap[_tokenId].metaDataHash == _fingerprint;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
}