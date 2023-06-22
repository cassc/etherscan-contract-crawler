// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/****************************************************************

                                     lllllll
                                     l:::::l
                                     l:::::l
                                     l:::::l
 uuuuuu    uuuuuu rrrrr   rrrrrrrrr   l::::l zzzzzzzzzzzzzzzzz
 u::::u    u::::u r::::rrr:::::::::r  l::::l z:::::::::::::::z
 u::::u    u::::u r:::::::::::::::::r l::::l z::::::::::::::z
 u::::u    u::::u rr::::::rrrrr::::::rl::::l zzzzzzzz::::::z
 u::::u    u::::u  r:::::r     r:::::rl::::l       z::::::z
 u::::u    u::::u  r:::::r     rrrrrrrl::::l      z::::::z
 u::::u    u::::u  r:::::r            l::::l     z::::::z
 u:::::uuuu:::::u  r:::::r            l::::l    z::::::z
 u:::::::::::::::uur:::::r           l::::::l  z::::::zzzzzzzz
  u:::::::::::::::ur:::::r           l::::::l z::::::::::::::z
   uu::::::::uu:::ur:::::r           l::::::lz:::::::::::::::z
     uuuuuuuu  uuuurrrrrrr           llllllllzzzzzzzzzzzzzzzzz

            Showcase all of your urlz with one url.
            by @DannPetty & @MarkBucknell
 ****************************************************************/

contract Urlz is ERC721Enumerable, Ownable {
    string public baseTokenURI;

    uint256 public price = 0.025 ether;
    uint256 public priceExtra = 0.025 ether;

    uint public maxMint = 4;

    bool public _paused = false;
    bool public _isPresale = false;

    mapping(address => bool) presaleAddresses;
    mapping(address => bool) tokenRedeemed;
    mapping(uint256 => string) tokenIdToName;

    constructor(string memory baseURI) ERC721("Urlz", "Urlz") {
        setBaseURI(baseURI);
    }

    function claim(string[] memory _usernames, uint256[] memory _hashes)
        external
        payable
    {
        require(!_paused, "Sale paused");
        require(_usernames.length <= maxMint, "Can only mint 4 at a time");

        if (_isPresale) {
            require(verifyUser(msg.sender), "You are not on the presale list");
            require(
                !tokenRedeemed[msg.sender],
                "You have already redeemed your presale urlz"
            );
            require(
                _usernames.length == 1,
                "Cannot mint specified number of urlz"
            );
        }

        uint256 runningPrice = 0 ether;

        for (uint256 i = 0; i <= _usernames.length - 1; i++) {
            uint256 _hash = hash(lower(_usernames[i]));

            require(bytes(_usernames[i]).length > 2, "Username length invalid");
            require(bytes(_usernames[i]).length <= 30, "Username length invalid");
            require(isValidName(_usernames[i]), "Username must be alphanumeric");
            require(_hash == _hashes[i], "invalid hash");
            require(!(_exists(_hashes[i])), "Token already exists");

            if (bytes(_usernames[i]).length < 4) {
                runningPrice = runningPrice + priceExtra;
            }
        }

        uint256 _price = (price * _usernames.length) + runningPrice;
        require(msg.value == _price, "Insufficient funds to redeem");

        for (uint256 i = 0; i <= _usernames.length - 1; i++) {
            _safeMint(msg.sender, _hashes[i]);
            tokenIdToName[_hashes[i]] = _usernames[i];
        }

        if (_isPresale) {
            tokenRedeemed[msg.sender] = true;
        }
    }

    function getNameFromToken(uint256 id) public view returns (string memory) {
        return tokenIdToName[id];
    }

    function reserveNames(string[] memory _usernames, uint256[] memory _hashes) public onlyOwner {
        for (uint256 i = 0; i <= _usernames.length - 1; i++) {
            _safeMint(msg.sender, _hashes[i]);
            tokenIdToName[_hashes[i]] = _usernames[i];
        }
    }

    function addUsers(address[] memory _addressesToPresaleList)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addressesToPresaleList.length; i++) {
            presaleAddresses[_addressesToPresaleList[i]] = true;
        }
    }

    function verifyUser(address _presaleAddress) public view returns (bool) {
        bool userIsPresaleOwner = presaleAddresses[_presaleAddress];
        return userIsPresaleOwner;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAmount(uint amount) public onlyOwner {
        require(amount < address(this).balance, "Balance too low for amount");
        payable(owner()).transfer(amount);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function getPausedState() public view returns (bool isPaused) {
        isPaused = _paused;
    }

    function pauseSale() public onlyOwner {
        _paused = true;
    }

    function unpauseSale() public onlyOwner {
        _paused = false;
    }

    function setMaxMint(uint _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function getPrice(string[] memory _usernames)
        public
        view
        returns (uint256 totalPrice)
    {
        uint256 runningPrice = 0 ether;

        for (uint256 i = 0; i <= _usernames.length - 1; i++) {
            if (bytes(_usernames[i]).length < 4) {
                runningPrice = runningPrice + priceExtra;
            }
        }

        totalPrice = (price * _usernames.length) + runningPrice;

        return totalPrice;
    }

    function getPresaleState() public view returns (bool isPresale) {
        isPresale = _isPresale;
        return isPresale;
    }

    function preSaleStart() public onlyOwner {
        _isPresale = true;
    }

    function preSaleStop() public onlyOwner {
        _isPresale = false;
    }

    function hash(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }

    function isValidName(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x2E) //.
            )
                return false;
        }

        return true;
    }
}