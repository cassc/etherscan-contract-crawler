// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ArtverseNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    address private _admin;
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to owner address
    mapping(string =>  mapping(address => uint256)) private mintAmount;

    constructor() ERC721("Artverse", "ATV") {
        _admin = address(0);
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function setAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "Signer: new admin is the zero address");
        _admin = newAdmin;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function verifyMintParam(uint256 allowance, uint256 start, uint256 end, string memory baseUri, uint value, bytes memory signature) public view {
        string memory message = string(abi.encodePacked(Strings.toHexString(msg.sender), ' ', Strings.toString(allowance), ' ', Strings.toString(start), ' ', Strings.toString(end), ' ', baseUri, ' ', Strings.toString(value)));
        bytes32 messageDigest = getEthSignedMessageHash(getMessageHash(message));
        address signer = ECDSA.recover(messageDigest, signature);
        require(signer == owner() || signer == admin(), 'invalid signature');

        // check params
        uint256 tokenId = _tokenIdCounter.current();
        require(start <= tokenId && tokenId <= end, 'permission denied: tokenId not in [start, end]');
        require(mintAmount[baseUri][msg.sender] < allowance, 'permission denied: allowance < amount');
    }

    function mint(address to, uint256 allowance, uint256 start, uint256 end, string memory baseUri, uint value, bytes memory signature) public payable {
        verifyMintParam(allowance, start, end, baseUri, value, signature);
        if (value > 0) {
            require(msg.value >= value * 1 gwei, 'insufficient value');
            Address.sendValue(payable(owner()), msg.value);
        }
        uint256 tokenId = _tokenIdCounter.current();
        mintAmount[baseUri][msg.sender] += 1;
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(baseUri, Strings.toString(tokenId), '.json')));
    }

    function getMessageHash(
        string memory _message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function mintedOf(address addr, string memory baseUri) public view returns (uint256) {
        return mintAmount[baseUri][addr];
    }

    function withdraw() public onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }
}