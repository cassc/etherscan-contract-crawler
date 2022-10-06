// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract NiceNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, ERC721Royalty {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) private holderList;
    mapping(address => bool) private whitelistedAddresses;
    mapping(uint256 => bool) private batchIDList;
    mapping(uint256 => bool) private tokenIDList;

    address private signatureAddr;
    bool private isMintable;

    struct Batch {
        uint256 quantity;
        uint256 totalPrice;
        uint256 batchID;
        address recAddr;
        uint96 feeNumerator;
        bytes batchSig;
    }

    struct TknArr {
        string tokenURI;
        uint256 tokenID;
        uint256 batchID;
        bytes tknSig;
    }

    constructor() ERC721("Project Nice", "PNNFT") {}

    modifier whenMintable {
        require(isMintable == true, "000: Minting has been disabled.");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSignatureAddr(address _addr) public onlyOwner {
      signatureAddr = _addr;
    }

    function setIsMintable(bool _boolMint) public onlyOwner {
      isMintable = _boolMint;
    }

    function safeMint(Batch calldata _batch, TknArr[] calldata _tknArr) 
        external whenNotPaused whenMintable payable {

        bytes32 batchHash = keccak256(abi.encodePacked(_batch.quantity,_batch.totalPrice,_batch.batchID, _batch.recAddr, _batch.feeNumerator));
        (address verAddr,) = ECDSA.tryRecover(batchHash,_batch.batchSig);

        require(verAddr == signatureAddr, "001: This transaction has not been authorised.");
        require(batchIDList[_batch.batchID] == false, "002: This transaction has already been processed.");
        require(msg.value >= _batch.totalPrice, "003: Insufficient funds recieved.");

        batchIDList[_batch.batchID] = true;

        for (uint256 i = 0; i < _batch.quantity; i++) {
            mintNft(msg.sender, _tknArr[i], _batch);
        }
        payable(_batch.recAddr).transfer(msg.value);
    }

    function mintNft(address _to, TknArr calldata _tknT, Batch calldata batch) internal {

        bytes32 tknHash = keccak256(abi.encodePacked(_tknT.tokenURI, _tknT.tokenID, _tknT.batchID));
        (address verAddr,) = ECDSA.tryRecover(tknHash, _tknT.tknSig);

        require(verAddr == signatureAddr, "011: This transaction has not been authorised.");
        require(_tknT.batchID == batch.batchID, "012: This transaction has not been authorised.");
        require(tokenIDList[_tknT.tokenID] == false, "013: This transaction has already been processed.");

        tokenIDList[_tknT.tokenID] = true;

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _tknT.tokenURI);
        _setTokenRoyalty(tokenId, batch.recAddr, batch.feeNumerator);

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}