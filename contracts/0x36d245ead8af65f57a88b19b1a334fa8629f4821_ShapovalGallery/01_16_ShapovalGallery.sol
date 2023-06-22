// SPDX-License-Identifier: GPL-1.0-only
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ShapovalGallery is ERC721Enumerable, Ownable {

    address public _systemAddress = address(0x1692D2fC28d561f4bC68202171062F0E445f8ff0);
    address public _w1 = address(0x7F212D666C7b9fe8625Bb5C95800A729BC8EB160);
    address public _w2 = address(0x112c1C31323ea73844b86b6196Fffc7B41eAD0a0);

    uint256 maxTokenNum = 200;
    uint256 contractFee = 30;
    string private _currentBaseURI;

    constructor() ERC721("ShapovalDigitalArtGallery", "SDAG") {
        setBaseURI("https://shapoval.art/metadata/");
    }

    function mint(uint256 id, uint256 price, bytes memory signature) public payable {
        require(id < maxTokenNum, "Token id is out of limit");
        require(!_exists(id), "Token id is already minted");
        require(price <= msg.value, "Ether value sent is less than expected");
        require(_isValidSignature(keccak256(abi.encodePacked(id, price)),
                signature), "Invalid signature");
        _safeMint(msg.sender, id);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _currentBaseURI = newBaseURI;
    }

    function baseURI() public view virtual returns (string memory) {
        return _currentBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    /// @notice Set the system address
    /// @param systemAddress Address to set as systemAddress
    function setSystemAddress(address systemAddress) external onlyOwner {
        _systemAddress = systemAddress;
    }

    using ECDSA for bytes32;

    function _isValidSignature(bytes32 hash, bytes memory signature)
    internal view returns (bool) {
        require(_systemAddress != address(0), "CP: Invalid system address");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == _systemAddress;
    }

    function withdraw() external payable {
        require(((msg.sender == _w1) ||
                (msg.sender == _w2)), "withdrawal address not in whitelist");

        uint256 balance = address(this).balance;
        uint256 ownerAmount = balance * contractFee / 100;
        uint256 withdrawalAmount = balance - ownerAmount;

        payable(owner()).transfer(ownerAmount);
        payable(msg.sender).transfer(withdrawalAmount);
    }
}