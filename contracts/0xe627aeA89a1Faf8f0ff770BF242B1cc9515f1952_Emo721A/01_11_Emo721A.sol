// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Emo721A is ERC721A, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;

    uint public immutable maxSupply = 10000;
    address public owner;     

    constructor(address[] memory _payees, uint256[] memory _shares) ERC721A("EmoHeads", "EH") PaymentSplitter(_payees, _shares) {
        owner = msg.sender;
    }

// --------------- WHITELIST --------------- \\
    mapping(address => bool) public whitelist;
    event Whitelist(address indexed account, bool status);

    function addToWhitelistSingle(address _account) public onlyGang {
        whitelist[_account] = true;
        emit Whitelist(_account, true);
    }

    function addToWhitelist(address[] memory _accounts) public onlyGang {
        for (uint i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = true;
            emit Whitelist(_accounts[i], true);
        }
    }

    function removeFromWhitelist(address _account) public onlyGang {
        whitelist[_account] = false;
        emit Whitelist(_account, false);
        
    }

    function removeFromWhitelist(address[] memory _accounts) public onlyGang {
        for (uint i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = false;
            emit Whitelist(_accounts[i], false);
        }
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return whitelist[_account];
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Not whitelisted");
        _;
    }



// --------------- PAUSE --------------- \\
    bool public paused = false;
    
    function setPaused(bool _value) public onlyGang{
        paused = _value;
    }



// --------------- MINTING --------------- \\
    uint public price = 0.02 ether;

    function setPrice(uint _value) public onlyGang{
        price = _value;
    }

    function mint(uint256 _quantity, address _to) external payable nonReentrant {
        require(!paused, "Minting is paused");
        require(msg.value == _quantity * price, "Please send the exact amount.");

        _internalMint(_to, _quantity);
    }

    function mintWhiteList(uint256 _quantity, address _to) external payable nonReentrant onlyWhitelisted {
        require(!paused, "Minting is paused");
        require(msg.value == _quantity * price, "Please send the exact amount.");

        _internalMint(_to, _quantity + _quantity);
    }

    function gift(address _addr, uint _amount) external onlyGang nonReentrant {
        _internalMint(_addr, _amount);
    }

    function _internalMint(address _addr,uint256 _qtty) internal
    {
        require(totalSupply() + _qtty < maxSupply + 1, "No more tokens available for minting");
        _mint(_addr, _qtty);
    }




// --------------- URI STUFF --------------- \\

    string public metadataPrefx = "https://bafybeifvu3booco4q4ehsbg5awcdzgpncbeescs7wl6xipx7axmx4vjaue.ipfs.nftstorage.link/";
    string metadataSuffix = ".json";

    function setMetadataPrefix(string memory _value) public onlyGang{
        metadataPrefx = _value;
    }
    function setMetadataSuffix(string memory _value) public onlyGang{
        metadataSuffix = _value;
    }

    function tokenURI(uint tokenId) public view override returns(string memory) {
        string memory _tokenId = tokenId.toString();
        _tokenId = zeroPad(_tokenId, 5);
        
        return string(abi.encodePacked(metadataPrefx, _tokenId, metadataSuffix));
    }

    function zeroPad(string memory _tokenId, uint8 _length) internal pure returns (string memory) {
        bytes memory _bytes = bytes(_tokenId);
        uint8 _pad = _length - uint8(_bytes.length);
        if (_pad > 0) {
            bytes memory _padded = new bytes(_length);
            for (uint8 i = 0; i < _pad; i++) {
                _padded[i] = "0";
            }
            for (uint8 i = 0; i < _bytes.length; i++) {
                _padded[i + _pad] = _bytes[i];
            }
            return string(_padded);
        }
        return _tokenId;
    }


//--------------- MONEY ---------------\\
    address private _privileged = 0x4d4468AA6a297f84cad25774a34A4971Dae6F886;
    
    
    modifier onlyGang() {
        require (
            msg.sender == _privileged ||
            msg.sender ==  owner ,
            "Unauthorized"
        );
        _;
    }

}