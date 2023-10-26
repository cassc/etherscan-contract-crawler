// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC721Pausable.sol";
contract VacationPaletteNft is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 300;
    address public constant creatorAddress = 0x67c7d48DA5FF0Ca165c26944a5d01DF1D6F62c75;
    string public baseTokenURI;
    string public codeURI;
    mapping (uint8 => address) public minters;
    mapping (uint8 => uint16) public seed;
    mapping (address => bool) public didMint;

    event CreateNFT(uint256 indexed id);
    constructor(
        string memory baseURI,
        string memory _codeURI
    ) ERC721("Vacation Palette NFT", "VPNFT") {
        setBaseURI(baseURI);
        setCodeURI(_codeURI);
        pause(true);
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
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
    function mint(uint16 _seed) public payable saleIsOpen {
        require(_seed <= 10000, "_seed > 10k");
        uint256 total = _totalSupply();
        require(total + 1 <= MAX_ELEMENTS, "Max limit");
        bool alreadyMinted = didMint[_msgSender()];
        require(!alreadyMinted || _msgSender() == owner(), "address already minted");

        _mintAnElement(_msgSender(), _seed);
    }
    function _mintAnElement(address _to, uint16 _seed) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateNFT(id);
        minters[uint8(id)] = _to;
        seed[uint8(id)] = _seed;
        didMint[_to] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function getCodeURI() public view returns (string memory) {
        return codeURI;
    }

    function setCodeURI(string memory _codeURI) public onlyOwner {
        codeURI = _codeURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function getDataById(uint _id) public view returns (address, uint16) {
        require(_id <= _totalSupply(), 'invalid id');
        address _minter = minters[uint8(_id)];
        uint16 _seed = seed[uint8(_id)];
        return (_minter, _seed);
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
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

    receive() external payable {
        revert('Not allowed');
    }

}