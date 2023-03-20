// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3

pragma solidity ^0.8.4;

import './ERC721A.sol';
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
} 

contract TrumpInmate45 is ERC721A, Ownable{
    using Strings for uint256;

    constructor() ERC721A("Trump Inmate 45", "TI45") {}

    uint256 public cost = 2000000000000000;
    uint256 public maxMintAmountPerTx = 100;
    bool public paused = false;
    uint16 public maxSupply = 10000;
    string private URI = "ipfs://bafybeieh5ctjyn557vt7tp4sydfn33rzzwjdy67cessnphxa77hplay3qq/"; 
    string private uriPrefix;
    string private uriSuffix = "";

    function updateCost(uint256 _newCost) public onlyOwner{
        cost = _newCost;
    }

    function updateMintAmount(uint256 _amount) public onlyOwner{
        maxMintAmountPerTx = _amount;
    }


    function publicMint(uint8 _mintAmount) external payable  {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        require(_mintAmount  <= maxMintAmountPerTx, "Exceeds max per transaction.");
        require(!paused, "The contract is paused!");
        uint8 costAmount = _mintAmount;
        require(msg.value >= cost * costAmount, "Insufficient funds!");
        _safeMint(msg.sender , _mintAmount);
        delete totalSupply;
        delete _mintAmount;
    }
  
    function ownerMint(uint16 _mintAmount, address _receiver) external onlyOwner {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        _safeMint(_receiver , _mintAmount);
        delete _mintAmount;
        delete _receiver;
        delete totalSupply;
    }

    function  airdrop(uint8 _amountPerAddress, address[] calldata addresses) external onlyOwner {
        uint16 totalSupply = uint16(totalSupply());
        uint totalAmount =   _amountPerAddress * addresses.length;
        require(totalSupply + totalAmount <= maxSupply, "Exceeds max supply.");
        for (uint256 i = 0; i < addresses.length; i++) {
                _safeMint(addresses[i], _amountPerAddress);
            }
        delete _amountPerAddress;
        delete totalSupply;
    }

    function setMaxSupply(uint16 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return URI;
    }

    function toggleMint() external onlyOwner {
        paused = !paused;
    }

    function updateBaseURI(string memory _URI) public onlyOwner{
        URI = _URI;
    }

    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance ); 
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
            : "";
    }
}