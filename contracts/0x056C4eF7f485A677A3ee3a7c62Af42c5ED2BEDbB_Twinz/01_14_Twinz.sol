/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract Twinz is ERC721A, Ownable {
    using Strings for uint256;

    uint256 private constant _MAX_SUPPLY = 100;
    
    uint256 public price;
    uint256 public startSaleTime;
    uint256 public endSaleTime;
    
    string private _baseUri;

    bytes32 public whitelistMerkleRoot;
    bool public whitelistFinished;
    bool public salePeriodOverride;

    mapping(address => bool) public userHasMinted;

    modifier canMint {
        require(saleIsActive(), "SALE_NOT_ACTIVE");
        require(msg.value == price, "WRONG_PRICE");
        require(!userHasMinted[_msgSender()], "ALREADY_MINTED");
        require(totalSupply() + 1 <= _MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        _;
    }

    constructor(
        uint256 price_,
        uint256 _startSaleTime,
        uint256 _endSaleTime,
        bytes32 _whitelistMerkleRoot,
        string memory name,
        string memory symbol,
        string memory baseUri
    )
        ERC721A(name, symbol)
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
        _baseUri = baseUri;
        price = price_;
        startSaleTime = _startSaleTime;
        endSaleTime = _endSaleTime;
    }

    function airdrop(address[] memory addresses) external onlyOwner {
        uint256 length = addresses.length;
        require(length  + totalSupply() <= _MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        for (uint i = 0; i < length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function setStartTime(uint startTime) external onlyOwner {
       startSaleTime = startTime;
    }

    function setEndTime(uint endTime) external onlyOwner {
        require(endTime > startSaleTime, "END_LESS_THAN_START");
        endSaleTime = endTime;
    }

    function saleIsActive() public view returns (bool) {
        if(salePeriodOverride) {
            return true;
        }
        return block.timestamp >= startSaleTime && block.timestamp <= endSaleTime;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdrawBalance(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    function setMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    function toggleWhitelist() external onlyOwner {
        whitelistFinished = !whitelistFinished;
    }

    function toggleSalePeriodOverride() external onlyOwner {
        salePeriodOverride = !salePeriodOverride;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _verifyWhitelist(bytes32[] calldata _merkleProof, address addr) private view returns(bool) {
       return (MerkleProof.verify(_merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(addr))) == true);
    }
    
    function whitelistMint(bytes32[] calldata _merkleProof) external payable canMint {
        require(!whitelistFinished, "WHITELIST_FINISHED");
        address account = _msgSender();
        require(_verifyWhitelist(_merkleProof, account), "WHITELIST_NOT_VERIFIED");
        _mint(account);
    }

    function publicMint() external payable canMint  {
        require(whitelistFinished, "WHITELIST_NOT_YET_FINISHED");
        _mint(_msgSender());
    }

    function _mint(address account) private {
        
        userHasMinted[account] = true;
        _safeMint(account, 1);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable { }
}