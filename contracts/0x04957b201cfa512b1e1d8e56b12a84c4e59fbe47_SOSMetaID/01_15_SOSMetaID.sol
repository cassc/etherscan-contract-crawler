// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SOSMetaID is Ownable, EIP712, ERC721Enumerable {
    using Strings for uint256;

    // Address of SOS
    address public erc721Address;

    // Whitelist
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address minter,uint256 tokenId,uint256 nonce)");
    address public whitelistSigner;

    string private _contractURI;
    string private _tokenBaseURI;

    constructor()
        ERC721("SOS Meta ID", "SOSMETAID")
        EIP712("SOS Meta ID", "1")
    {}

    function setContractAddress(address _erc721Address) external onlyOwner {
        erc721Address = _erc721Address;
    }

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function getSigner(
        address _minter,
        uint256 _tokenId,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, _minter, _tokenId, _nonce))
        );
        return ECDSA.recover(digest, _signature);
    }

    function mint(
        address _minter,
        uint256 _tokenId,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        require(erc721Address != address(0), "SOS address not set yet");
        require(
            IERC721(erc721Address).ownerOf(_tokenId) == msg.sender,
            "You do not own the SOS token"
        );
        require(
            getSigner(msg.sender, _tokenId, _nonce, _signature) == whitelistSigner,
            "Invalid signature"
        );

        // token id has to be unique
        // this prevent double mint for same SOS token id
        _safeMint(msg.sender, _tokenId);
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "Token not exist");

        return string(abi.encodePacked(_tokenBaseURI, _tokenId.toString()));
    }
}