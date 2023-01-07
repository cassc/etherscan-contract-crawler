// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HookedAvatar is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address private _signer;
    mapping(uint256 => string) private _Uris;
    bool isLocked = true;
    uint32 private _totalNumber = 0;
    uint32 public _maxNumber = 10000;

    event Locked();
    event Unlocked();
    event SetMaxNumber(uint32 num);
    
    constructor(address signer) ERC721("HookedAvatar","HA") {
        _signer = signer;
        emit Locked();
    }

    function setSigner(address signer) public onlyOwner {
        require(signer != address(0),"Invalid signer");
        _signer = signer;
    }

    function setLock(bool status) public onlyOwner {
        isLocked = status;
        if(isLocked){
            emit Locked();
        }else{
            emit Unlocked();
        }
    }

    function setMaxNumber(uint32 num) public onlyOwner {
        require(num > _maxNumber);
        _maxNumber = num;
        emit SetMaxNumber(_maxNumber);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return _Uris[tokenId];
    }

    function totalMintNumber() public view returns (uint32) {
        return _totalNumber;
    }

    function mint(bytes calldata signature,string memory metaURI) public {
        require(_totalNumber < _maxNumber, "Max limit exceeded");
        require(balanceOf(msg.sender) == 0, "Wallet HA limit exceeded");
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender)));
        require(SignatureChecker.isValidSignatureNow(_signer, message, signature),"Invalid signature");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _Uris[newTokenId] = metaURI;
        _mint(msg.sender, newTokenId);
        _totalNumber++;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override
    {
        if(isLocked){
            require(from == address(0),"NFT locked");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

}