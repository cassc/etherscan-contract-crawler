//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/*                  @@@@@@@@@@@@@             @@@@@@@@@@@@@@
                  @@@@@@@@@@@@@@                 @@@@@@@@@@@@@@
                @@@@@@@@@@@@@@                     @@@@@@@@@@@@@@
              @@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@                           @@@@@@@@@@@@@@
           @@@@@@@@@@@@@@                               @@@@@@@@@@@@@@
         @@@@@@@@@@@@@@                                  @@@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@                                     @@@@@@@@@@@@@@
      @@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@
    @@@@@@@@@@@@@@                      @                     @@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@             @@       @@@       @@             @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@                 @@@    @@@    @@@                 @@@@@@@@@@@@@@
                                 @@@@@@@@@@@@@@@
                                  @@@@@@@@@@@@@
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                  @@@@@@@@@@@@@
                                 @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@                 @@@    @@@    @@@                 @@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@             @@       @@@       @@             @@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@                      @                     @@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@                                     @@@@@@@@@@@@@@
         @@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@
           @@@@@@@@@@@@@@                               @@@@@@@@@@@@@@
             @@@@@@@@@@@@@@                           @@@@@@@@@@@@@@
              @@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@
                @@@@@@@@@@@@@@                     @@@@@@@@@@@@@@
                  @harry830622                   @@@@@@@@@@@@@@               */

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error NotAuthorized();
error InvalidToken();

contract Shell is Ownable, ERC721ABurnable, ERC721AQueryable, ERC2981 {
    using BitMaps for BitMaps.BitMap;

    string private _baseTokenURI = "https://api.elysiumshell.xyz/es/";

    BitMaps.BitMap private _isTokenInvalid;

    mapping(address => bool) private _isAuthorized;

    bytes32 public provenanceMerkleRoot;

    modifier onlyAuthorized() {
        if (!_isAuthorized[msg.sender]) {
            revert NotAuthorized();
        }
        _;
    }

    constructor() ERC721A("E-Shell", "ES") {
        _setDefaultRoyalty(
            address(0xd188Db484A78C147dCb14EC8F12b5ca1fcBC17f5),
            750
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function nextTokenId() external view returns (uint256) {
        return _currentIndex;
    }

    function numMintedOf(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function numBurnedOf(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    function isTokenValid(uint256 tokenId) external view returns (bool) {
        return !_isTokenInvalid.get(tokenId);
    }

    function verifyProvenance(
        uint256 metadataId,
        string calldata cid,
        bytes32[] calldata merkleProofs
    ) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(metadataId, cid));
        return MerkleProof.verify(merkleProofs, provenanceMerkleRoot, leaf);
    }

    function mint(address to, uint256 quantity) external onlyAuthorized {
        _mint(to, quantity, "", false);
    }

    function setTokenInvalid(uint256 tokenId) external onlyAuthorized {
        _isTokenInvalid.set(tokenId);
    }

    function setTokenValid(uint256 tokenId) external onlyAuthorized {
        _isTokenInvalid.unset(tokenId);
    }

    function setAuthorized(address addr, bool isAuthorized) external onlyOwner {
        _isAuthorized[addr] = isAuthorized;
    }

    function setProvenanceMerkleRoot(bytes32 root) external onlyOwner {
        provenanceMerkleRoot = root;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from == address(0) || to == address(0)) {
            return;
        }

        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            ++tokenId
        ) {
            if (_isTokenInvalid.get(tokenId)) {
                revert InvalidToken();
            }
        }
    }
}