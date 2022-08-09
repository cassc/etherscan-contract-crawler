// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../token/onft/extension/UniversalONFT721.sol";


contract ApolloFi is Context, UniversalONFT721 {
    using Strings for uint256;

    string private baseURI = "";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(uint256 => string) private _signatures;

    event Signature(address from, uint256 tokenId, string signature);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address _layerZeroEndpoint,
        uint _startMintId,
        uint _endMintId
    ) UniversalONFT721(name, symbol, _layerZeroEndpoint, _startMintId, _endMintId) {
        baseURI = baseUri;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
    * @notice set token base uri
    *
    * @param _base the base uri of token
    */
    function setBaseURI(string calldata _base) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC721Metadata: must have minter role"
        );
        baseURI = _base;
    }

    /**
    * @notice set NFT max end token id
    *
    * @param _endMaxId max end token id
    */
    function setMaxMintId(uint _endMaxId) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC721Metadata: must have minter role"
        );
        _setMaxMintId(_endMaxId);
    }

    /**
    * @notice set signature for the token
    *
    * @param _tokenId the token id
    * @param _signature the signature of token
    */
    function setSignature(uint256 _tokenId, string calldata _signature) public {
        require(
            ownerOf(_tokenId) == _msgSender(),
            "ERC721Metadata: not the owner of token"
        );
        _signatures[_tokenId] = _signature;

        emit Signature(_msgSender(), _tokenId, _signature);
    }

    /**
    * @notice mint your NFT
    *
    * @param to the address to mint for
    * @param signature sign result by the minter
    */
    function mint(
        address to,
        bytes memory signature
    ) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have minter role to mint"
        );

        safeMint(to, signature);
    }

    /**
    * @notice returns the Uniform Resource Identifier (URI) for `tokenId` token.
    *
    * @param _tokenId the token id to search uri
    */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
    * @notice return the token signature
    *
    * @param _tokenId the token id to search signature
    */
    function getSignature(uint256 _tokenId) public view returns (string memory) {
        return _signatures[_tokenId];
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to unpause"
        );
        _unpause();
    }
}