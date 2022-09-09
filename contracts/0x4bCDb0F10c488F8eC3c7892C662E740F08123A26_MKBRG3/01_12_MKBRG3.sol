// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MKBRG3 is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 5000;

    address public authSigner;
    uint256 public constant NUM_RESERVED = 557;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event AuthSignerSet(address indexed newSigner);
    event NftMinted(address _minter);

    mapping(bytes => bool) sigsUsed;

    constructor(address _authSigner) ERC721("MK BRG3 Pass", "MKBRG3") {
        authSigner = _authSigner;
    }

    // set auth signer
    function setAuthSigner(address _authSigner) external onlyOwner {
        authSigner = _authSigner;
        emit AuthSignerSet(_authSigner);
    }

    function getAuthSigner() external view returns (address) {
        return authSigner;
    }

    function mintToken(address _to, bytes memory _sig) external {
        require(_tokenIds.current() < MAX_SUPPLY - NUM_RESERVED, "ERC721: Max supply");
        require(!sigsUsed[_sig], "Invalid signature");
        bytes memory b = abi.encodePacked(msg.sender);
        require(recoverSigner(keccak256(b), _sig) == authSigner, "Invalid sig");

        _tokenIds.increment();
        uint256 id = _tokenIds.current();

        sigsUsed[_sig] = true;
        _safeMint(_to, id);

        emit NftMinted(_to);
    }

    function mintTo(address _to) external onlyOwner {
        require(_tokenIds.current() < MAX_SUPPLY, "ERC721: Max supply");
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _safeMint(_to, id);
        emit NftMinted(_to);
    }

    function batchMintToken(address _to, uint256 _numberOfTokens) external onlyOwner {
        require(_tokenIds.current() < MAX_SUPPLY, "ERC721: Max supply");

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();

            _safeMint(_to, id);
        }
        emit NftMinted(_to);
    }

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(msg.sender == ownerOf(_tokenId), "Not owner of this token");
        _transfer(_from, _to, _tokenId);
    }

    function burn(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "Not owner of this token");
        _burn(_tokenId);
    }

    function getTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    // Metadata
    string public baseURI;

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    // Crypto
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "invalid sig");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
}