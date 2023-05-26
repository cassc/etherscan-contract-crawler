// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PlayerOne is ReentrancyGuard,ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;


    EnumerableSet.AddressSet private _minters;

    Counters.Counter private _tokenIdCounter;

    // claim id->claimed
    mapping(uint256 => bool) public claimed;

    string public baseURIPrefix = "ipfs://metadata json folder cid/";

    constructor() ERC721("PLAYER ONE", "1P") {
        baseURIPrefix = "ipfs://QmaNPK17hd5Hb4Sudq6MhwLeCx43SiAmv5kGUspMGzReaE/";
    }

    function isMinter(address value) public view returns (bool) {
        return _minters.contains(value);
    }

    function addMinter(address value) public onlyOwner returns (bool) {
        return _minters.add(value);
    }
    function removeMinter(address value) public onlyOwner returns (bool) {
        return _minters.remove(value);
    }

    function getMinters() public view returns (address[] memory){
        return _minters.values();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIPrefix;
    }

    function _verify(bytes32 digest, bytes memory signature) internal view returns (bool) {
        address signer = ECDSA.recover(digest, signature);
        return isMinter(signer);
    }
    function mintHash(address to,uint256 claimId) public view returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(block.chainid,this,to,claimId)));
    }

    function claim(address to,uint256 claimId,bytes memory signature) external nonReentrant returns (uint256) {
        require(!claimed[claimId], "PlayerOne: claimed");

        bytes32 hashStr = mintHash(to,claimId);
        require(_verify(hashStr,signature), "PlayerOne: invalid signature");
        // claimed
        claimed[claimId] = true;
        // mint
        return _mintTo(to);
    }

    // mint
    function mint(address to) public returns (uint256){
        require(isMinter(_msgSender()) , "PlayerOne: caller is not the minter");
        return _mintTo(to);
    }

    // whith id
    function _mintTo(address to) internal returns (uint256){
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= 10000, "PlayerOne: exceeds total supply");

        _safeMint(to, tokenId);
        return tokenId;
    }



    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        super._requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,tokenId.toString(),".json")) : "";
    }
}