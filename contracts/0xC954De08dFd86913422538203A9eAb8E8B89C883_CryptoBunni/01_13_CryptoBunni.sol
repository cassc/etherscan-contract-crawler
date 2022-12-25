// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CryptoBunni is ERC721, Ownable, ReentrancyGuard{

    using SafeMath for uint256;

    constructor() ERC721("CryptoBunni", "CBI") {
        setBaseURI("ipfs://QmR82nB1E6RN9jWFJCAJ51ineYEkjRdSciWWoKYM51nHq4/");

        mintTo(msg.sender, 69);
    }

    event MintBunni(uint tokenId, address sender);

    uint256 public cost = 0.0069 ether;
    uint256 public maxMintAmountPerTx = 10;
    uint256 public maxSupply = 2000;
    uint256 public _currentTokenId = 0;
    string public baseURI;

    modifier initialMintCompliance(uint256 _mintAmount) {
        require(
            _currentTokenId + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            _currentTokenId + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function buyBunni(address _to, uint _mintAmount) 
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
        {
        for (uint i = 0; i < _mintAmount; i++) {
            uint256 newTokenId = _nextTokenId();
            _safeMint(_to, newTokenId);
            emit MintBunni(newTokenId, msg.sender);
            _incrementTokenId();   
        }
    }

    function mintTo(address _to, uint _mintAmount) 
        private 
        initialMintCompliance(_mintAmount)
        onlyOwner {
        for (uint i = 0; i < _mintAmount; i++) {
            uint256 newTokenId = _nextTokenId();
            _safeMint(_to, newTokenId);
            emit MintBunni(newTokenId, msg.sender);
            _incrementTokenId();
        }
    }

    function _nextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string memory _newUri) public onlyOwner {
        baseURI = _newUri;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
    }

    function uint2str(uint256 _i) internal pure  returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}