// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./Authorizable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./OnlySender.sol";

interface IY0uKey {
    function burnKey(address _address, uint256 tokenId) external; 
}

struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
 }

contract Y0uKey is 
    IY0uKey,
    ERC721, 
    ERC721Burnable, 
    Authorizable, 
    ReentrancyGuard,
    OnlySender {
    using Address for address;
    using Strings for uint256;

    enum KeyType { None, Y0U, Platinum, Diamond, Gold, Member }

    uint256 public y0uKeyPrice = 0;
    uint256 public platinumKeyPrice = 0;
    uint256 public diamondKeyPrice = 0;
    uint256 public goldKeyPrice = 0;
    uint256 public memberKeyPrice = 0;

    uint256 public nextInd = 1;

    string public _baseTokenURI = "https://y0uclub.mypinata.cloud/ipfs/QmacPhsWvCyQyST1gvZFh37cnFB6rREGtKUAFvw7Wfzsd5/";

    address private _adminSigner = 0x7dF9601333aD61394c9344dc6d097A87feB7F8F9; 

    mapping(uint256 => uint8) public tokenKeyTypes;

    mapping(address => bool) public addressDidMint;

    // solhint-disable-next-line no-empty-blocks,  func-visibility
    constructor() ERC721("Y0uKey", "Y0UKEY") {}

    function mintPrice(uint256 _keyType) public view returns (uint256) {
        KeyType keyType = KeyType(_keyType);
        if (keyType == KeyType.Y0U) {
            return y0uKeyPrice;
        } else if (keyType == KeyType.Platinum) {
            return platinumKeyPrice;
        } else if (keyType == KeyType.Diamond) {
            return diamondKeyPrice;
        } else if (keyType == KeyType.Gold) {
            return goldKeyPrice;
        } else if (keyType == KeyType.Member) {
            return memberKeyPrice;
        } else {
            return 0;
        }
    }

    function _isVerifiedCoupon(bytes32 digest, Coupon calldata coupon) internal view returns(bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "Invalid signature");
        return signer == _adminSigner;
    }

    function publicMint(uint256 _keyType, Coupon calldata coupon) external payable onlySender {

        KeyType keyType = KeyType(_keyType);
        require(keyType != KeyType.None, "Bad keyType");

        bytes32 digest = keccak256(abi.encode(_keyType, msg.sender));
  
        require(
            _isVerifiedCoupon(digest, coupon), 
            "Invalid coupon"
        ); 

        require(!addressDidMint[msg.sender], "You have already minted");

        uint256 price = mintPrice(_keyType);
        require(msg.value == price, "Incorrect payment");

        uint256 _tokenInd = nextInd;  
        nextInd += 1;     
        tokenKeyTypes[_tokenInd] = uint8(_keyType);        
        addressDidMint[msg.sender] = true;

        _safeMint(msg.sender, _tokenInd);
    }

    function setBaseURI(string calldata baseURI) external onlyAuthorized {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token");

        uint256 keyType = uint256(tokenKeyTypes[_tokenId]);

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    keyType.toString()
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function burnKey(address _address, uint256 tokenId) external override onlyAuthorized {
        require(_exists(tokenId), "Nonexistent token");
        require(ownerOf(tokenId) == _address, "Token not owned by address");
        require(tokenId != 0, "Can't burn 0");
        _burn(tokenId);
    }

    function setKeyPrice(uint256 _keyType, uint256 _price) external onlyAuthorized {
        KeyType keyType = KeyType(_keyType);
        require(keyType != KeyType.None, "Can't set type");
        if (keyType == KeyType.Y0U) {
            y0uKeyPrice = _price;
        } else if (keyType == KeyType.Platinum) {
            platinumKeyPrice = _price;
        } else if (keyType == KeyType.Diamond) {
            diamondKeyPrice = _price;
        } else if (keyType == KeyType.Gold) {
            goldKeyPrice = _price;
        } else if (keyType == KeyType.Member) {
            memberKeyPrice = _price;
        }
    }

    function withdraw(address _address) external onlyAuthorized nonReentrant {
        // solhint-disable mark-callable-contracts
        Address.sendValue(payable(_address), address(this).balance);
    }

    function setAdminSigner(address _signer) external onlyAuthorized {
        _adminSigner = _signer;
    }

    function walletOfOwner(address _address) external view returns (uint[] memory) {
        uint balance = balanceOf(_address); 
        uint[] memory tokens = new uint[](balance);
        uint index;
        for (uint i = 1; i < nextInd; i++) {
            if (_address == ownerOf(i)) { 
                tokens[index] = i; 
                index++; 
                if (index >= balance) {
                    return tokens;
                }
            }
        }
        return tokens;
    }

}