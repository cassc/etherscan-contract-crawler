// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CryptoPepeHolder.sol";

interface CryptoPepe {
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external returns (uint256 tokenId);
    function implementsERC721() external pure returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokenId) external returns (bool) ;
    function transfer(address _to, uint256 _tokenId) external returns (bool);
}

error ExpensivePepeTransfer(uint256 requested, uint256 correct);
error EmptyArray();
error OutOfRange();

contract CryptoPepeWrapper is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    address private _cryptoPepe;
    CryptoPepe private pepe;
    string private _baseURIextended;

    constructor(address _cryptoPepeAddress) ERC721("CryptoPepes 2018", "CPEP") {
        _cryptoPepe = _cryptoPepeAddress;
        pepe = CryptoPepe(_cryptoPepeAddress);
        _baseURIextended = "ipfs://QmNdH5K3rHumNzqvEHqLsZ9MCsYJxnPvNZaSLY75w8or8T/";
    }

    // EVENTS

    event Wrap(address indexed sender, uint256 indexed tokenId);
    event BatchWrap(address indexed sender, uint256[] tokenIds);
    event BatchUnwrap(address indexed sender, address indexed receiver, uint256[] tokenIds);
    event Unwrap(address indexed from, address indexed to, uint256 indexed tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /**
     * @dev Returns base URI of token.
     */
    function baseTokenURI() public view returns (string memory) {
        return _baseURIextended;
    }

    /** 
     * dev Sets base token URI. Emits BatchMetadataUpdate for Opensea.
     * @param baseURI_ string to set base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
        emit BatchMetadataUpdate(1, 5496);
    }
    
    /**
     * @dev Wraps single token. Sends original token to computed address.
     * @param _tokenId token identifier to be wrapped
     */
    function wrap(uint256 _tokenId) public {
        _wrap(_tokenId);
        emit Wrap(msg.sender, _tokenId);
    }

    /**
     * @dev Wraps multiple tokens. Sends original tokens to computed addresses.
     * @param _tokenIds token identifier array to wrapped
     */
    function batchWrap(uint256[] calldata _tokenIds) public {
        if(_tokenIds.length == 0)
            revert EmptyArray(); 
    
        uint len = _tokenIds.length;
        for (uint i = 0; i < len; ++i) {  
            uint256 _tokenId = _tokenIds[i];
            _wrap(_tokenId);
        }
    
        emit BatchWrap(msg.sender, _tokenIds);
    }

    /**
     * @dev Unwrap single token. Burns wrapped token and sends original token to _to address.
     * @param _tokenId token identifier to be unwrapped
     * @param _to address to send unwrapped token
     */
    function unwrap(uint256 _tokenId, address _to) public {
        _unwrap(_tokenId, _to);
        emit Unwrap(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Unwrap multiple tokens. Burns wrapped tokens and sends original tokens to _to address.
     * @param _tokenIds array of token to be wrapped
     * @param _to address to send unwrapped token
     */
    function batchUnwrap(uint256[] calldata _tokenIds, address _to) public {
        if(_tokenIds.length == 0)
            revert EmptyArray(); 
        uint len = _tokenIds.length;
        for (uint i = 0; i < len; ++i) {  
            uint256 _tokenId = _tokenIds[i];
            _unwrap(_tokenId, _to);
        }
        emit BatchUnwrap(msg.sender, _to, _tokenIds);
    }

    //Internal Functions

    /**
     * @dev Wraps single token. Sends original token to computed address.
     * @param _tokenId token identifier to be wrapped
     */
    function _wrap(uint256 _tokenId) internal {
        if(_tokenId > 5496)
            revert OutOfRange(); 
        uint256 pepeIndex = pepe.tokenOfOwnerByIndex(msg.sender, 0);

        if(pepeIndex != _tokenId)
            revert ExpensivePepeTransfer(_tokenId, pepeIndex);

        address holdingAddress = computeAddress(getBytecode(address(this)), _tokenId);
        
        if(!pepe.transferFrom(msg.sender, holdingAddress, _tokenId))
            revert NotPepeOwner(); 
        _safeMint(msg.sender, _tokenId);
    }
    
    /**
     * @dev Unwrap single token. Burns wrapped token and sends original token to _to address.
     * @param _tokenId token identifier to be unwrapped
     * @param _to address to send unwrapped token
     */
    function _unwrap(uint256 _tokenId, address _to) internal {
        if(ownerOf(_tokenId) != msg.sender)
            revert NotPepeOwner(); 

        address holderAddress;

        _burn(_tokenId);

        uint256 extSize;

        bytes memory byteCode = getBytecode(address(this));
        holderAddress = computeAddress(byteCode, _tokenId);
       
            assembly {
                extSize := extcodesize(holderAddress)      
                if iszero(extSize){ 
                    holderAddress:= create2(callvalue(),add(byteCode,0x20), mload(byteCode), _tokenId)
                
                    if iszero(extcodesize(holderAddress)){
                        revert(0,0)
                    }
                }
            }

        CryptoPepeHolder holder = CryptoPepeHolder(holderAddress);
        holder.transfer(_cryptoPepe, _to, _tokenId);
    }

    /**
     * @dev Returns bytecode of holder contract.
     * @param _owner encodes creationcode with owner address
     */
    function getBytecode(address _owner) private pure returns (bytes memory){
        return abi.encodePacked(type(CryptoPepeHolder).creationCode, abi.encode(_owner)) ;
    }
    
    /**
     * @dev Computes address of bytecode with salt
     * @param _byteCode contract bytecode
     * @param _salt salt used to hash
     */
    function computeAddress(bytes memory _byteCode, uint256 _salt) private view returns (address ){
        bytes32 hash_ = keccak256(abi.encodePacked(bytes1(0xff),address(this),_salt,keccak256(_byteCode)));
        return address(uint160(uint256(hash_)));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}