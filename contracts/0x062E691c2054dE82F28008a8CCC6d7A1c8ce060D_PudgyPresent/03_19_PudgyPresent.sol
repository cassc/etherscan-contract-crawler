// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Pausable.sol";
import "./PudgyPenguinsInterface.sol";

contract PudgyPresent is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public constant MAX_BY_MINT = 10;
    uint256 public endClaim_timestamp = 1630958400; // Thu Sept 06 2021 20:00:00 UTC
    mapping (uint256 => uint256) private _pudgyPenguinsUsed;

    string public baseTokenURI;

    event CreatePenguinPresent(uint256 indexed id);

    PudgyPenguinsInterface public pudgyPenguins;
    constructor(string memory baseURI) ERC721("PudgyPresent", "PP") {
        setBaseURI(baseURI);
        pause(true);
    }

    modifier claimIsOpen {
        require(block.timestamp <= endClaim_timestamp, "Claim end");
        require(_totalSupply() <= MAX_ELEMENTS, "Claim end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256[] memory _tokensId) public payable claimIsOpen {
        uint256 total = _totalSupply();
        require(total <= MAX_ELEMENTS, "Claim end");
        require(total + _tokensId.length <= MAX_ELEMENTS, "Max limit");
        require(_tokensId.length <= MAX_BY_MINT, "Exceeds number");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            uint256  _tokenId = _tokensId[i];
            require(canClaim(_tokenId) && pudgyPenguins.ownerOf(_tokenId) == _msgSender(), "Bad owner!");

            _pudgyPenguinsUsed[_tokenId] = 1;
            _mintAnElement(_to, _tokenId);

        }
    }

    function canClaim(uint256 _tokenId) public view returns(bool) {
        return _pudgyPenguinsUsed[_tokenId] == 0;
    }

    function _mintAnElement(address _to, uint256 id) private {
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreatePenguinPresent(id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setEndClaimDate(uint256 _end) public onlyOwner{
        endClaim_timestamp = _end;
    }
    function getEndClaimDate() public view returns(uint256){
        return endClaim_timestamp;
    }
    function setPudgyPenguins(address _pudgyPenguins) external onlyOwner {
        pudgyPenguins = PudgyPenguinsInterface(_pudgyPenguins);
    }

    address public constant creatorAddress = 0x6F84Fa72Ca4554E0eEFcB9032e5A4F1FB41b726C;
    address public constant devAddress = 0xcBCc84766F2950CF867f42D766c43fB2D2Ba3256;
    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(devAddress, balance.mul(35).div(100));
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}