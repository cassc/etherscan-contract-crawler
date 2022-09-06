// SPDX-License-Identifier: GPL-1.0-only
pragma solidity >=0.8.0 <0.9.0;

import "Ownable.sol";
import "ERC721Enumerable.sol";
import "ECDSA.sol";

contract SpaceTimeScapes is ERC721Enumerable, Ownable {

    address public _systemAddress = address(0x8c209E7a039fb146C8d9e63d951b44F541448BA7);
    uint256 maxTokenNum = 888;
    string private _currentBaseURI;

    address public _w1 = 0xe23cB922E2b13BFA2268Ac263141D1A05385f8a1;
    address public _w2 = 0x629B9443DAC3E80171f847B4DAdE69565602Beb6;

    constructor() ERC721("SpaceTimeScapes", "SPS") {
        setBaseURI("https://spacetimescapes.com/metadata/");
    }

    function mint(address to, uint256 id, uint256 price, bytes memory signature) public payable {
        require(id < maxTokenNum, "Token id is out of limit");
        require(!_exists(id), "Token id is already minted");
        require(price <= msg.value, "Ether value sent is less than expected");
        require(_isValidSignature(keccak256(abi.encodePacked(id, price)),
                signature), "Invalid signature");
        _safeMint(to, id);
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

    function _isValidSignature(bytes32 hash, bytes memory signature) internal returns (bool) {
        require(_systemAddress != address(0), "CP: Invalid system address");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == _systemAddress;
    }

    function withdraw() external payable {
        require((msg.sender == _w1) ||
                (msg.sender == _w2) ||
                (msg.sender == owner()), "withdrawal address not in whitelist");
        payable(msg.sender).transfer(address(this).balance);
    }
}