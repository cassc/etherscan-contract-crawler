// SPDX-License-Identifier: MIT

pragma solidity >0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//  __  __  ___   ___  _   _ _  ____   ______
// |  \/  |/ _ \ / _ \| \ | | |/ /\ \ / / ___|
// | |\/| | | | | | | |  \| | ' /  \ V /\___ \
// | |  | | |_| | |_| | |\  | . \   | |  ___) |
// |_|  |_|\___/ \___/|_| \_|_|\_\  |_| |____/

contract Moonkys is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;
    using SafeMath for uint256;

    address t1 = 0x94f65107EB422c67E61588682Fcf9D85AaC940B8;  //qu
    address t2 = 0x4C96256FD81F6fcd3110694e416ea203AeCea720;  //ek
    address t3 = 0x40a764a31d30C5FD62294A19861612A036F59943;  //mo
    address t4 = 0x5D2EebAddCD11E72F4672bFBaE23200514F49b11;  //en

    address private _importantAddress = 0x3f0E5e69982FBF8Bc05cBCeEcBC90A938E9B9aB6;

    mapping(address => bool) private _usedPresaleAddress;

    mapping (uint256 => string) private _tokenURIs;

    string private _baseURIextended;

    uint256 private _price = 0.04 ether;

    bool private _public_paused = true;
    bool private _presale_paused = true;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdentifiers;

    uint256 private _reserved = 130;
    uint256 public constant MAX_SUPPLY = 9000;

    constructor() ERC721("Moonkys", "MOONK") {
        _baseURIextended = "https://api.moonkys.art/meta/";
        super._pause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable)  returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function adopt(uint256 num) public payable whenNotPaused {
        uint256 supply = totalSupply();
        require(!_public_paused, "Public sale paused");
        require(num < 6, "You can adopt a maximum of 5 Moonkys");
        require(supply.add(num) <= MAX_SUPPLY - _reserved, "Exceeds maximum Moonkys supply");
        require(msg.value >= _price * num, "Ether sent is not correct");

        for(uint256 i; i < num; i++){
            _tokenIdentifiers.increment();
            uint256 newRECIdentifier = _tokenIdentifiers.current();
            _safeMint(msg.sender, newRECIdentifier);
        }
    }

    function presale(uint256 num, uint256 _total, bool _presale, bytes memory sig) public payable whenNotPaused {
        require(!_presale_paused, "Presale paused");
        require(!_usedPresaleAddress[msg.sender], "Presale Address already used!");

        string memory wallet = toAsciiString(msg.sender);
        require(isValidSignature(wallet, _total, _presale, sig) == true, "Invalid signature!");
        require(num <= _total, "Maximum reached!");

        uint256 supply = totalSupply();
        require(supply.add(num) <= MAX_SUPPLY - _reserved, "Exceeds maximum Moonkys supply");
        require(msg.value >= _price * num, "Ether sent is not correct");

        for(uint256 i; i < num; i++){
            _tokenIdentifiers.increment();
            uint256 newRECIdentifier = _tokenIdentifiers.current();
            _safeMint(msg.sender, newRECIdentifier);
        }
        _usedPresaleAddress[msg.sender] = true;
    }

    function giveAway(address _to, uint256 _amount) public whenNotPaused{
        require(t1 == _msgSender() || t2 == _msgSender() || t3 == _msgSender() || t4 == _msgSender(), "Caller is not part of the team!");
        require(_amount <= _reserved, "That would exceed the max reserved!");

        for (uint i = 0; i < _amount; i++) {
            _tokenIdentifiers.increment();
            uint256 newRECIdentifier = _tokenIdentifiers.current();
            _safeMint(_to, newRECIdentifier);
        }
       _reserved = _reserved.sub(_amount);
    }

    function getNFTBalance(address _owner) public view returns (uint256) {
       return ERC721.balanceOf(_owner);
    }

    function withdraw() public {
        require(t1 == _msgSender() || t2 == _msgSender() || t3 == _msgSender() || t4 == _msgSender(), "Caller is not part of the team!");

        uint256 balance = address(this).balance;
        uint256 balanceT1 = balance.mul(25).div(100);
        uint256 balanceT2 = balance.sub(balanceT1.mul(3));

        address payable t1Address = payable(t1);
        address payable t2Address = payable(t2);
        address payable t3Address = payable(t3);
        address payable t4Address = payable(t4);

        t1Address.transfer(balanceT1);
        t2Address.transfer(balanceT1);
        t3Address.transfer(balanceT1);
        t4Address.transfer(balanceT2);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function pause() external virtual onlyOwner() {
        super._pause();
    }

    function unpause() external virtual onlyOwner() {
        super._unpause();
    }

    function publicPause() public onlyOwner {
        _public_paused = true;
    }

    function publicUnpause() public onlyOwner {
        _public_paused = false;
    }

    function presalePause() public onlyOwner {
        _presale_paused = true;
    }

    function presaleUnpause() public onlyOwner {
        _presale_paused = false;
    }

    function isPresaleClaimed(address _address) public view returns(bool) {
        if( _usedPresaleAddress[_address] == true ) {
            return true;
        } else {
            return false;
        }
    }

    function setImportantAddress(address importantAddress) public onlyOwner() {
        _importantAddress = importantAddress;
    }

    function isValidSignature(string memory _wallet, uint256 _total, bool _presale, bytes memory sig) internal view returns(bool) {
       bytes32 message = keccak256(abi.encodePacked(_wallet, _total, _presale));
       return (recoverSigner(message, sig) == _importantAddress);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
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

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(abi.encodePacked("0x",s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}