// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SpookyFrens is ERC721Enumerable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 5555;
    uint256 public constant MAX_BY_MINT = 10;
    uint256 public endClaim_timestamp = 1636952400; // Nov 15 2021 5:00:00 UTC
    mapping (uint256 => uint256) private _spookyFrensUsed;

    string public baseTokenURI;

    event CreateSpookyFren(uint256 indexed id);

    ERC721Enumerable public fastFoodFrens = ERC721Enumerable(0x4721D66937B16274faC603509E9D61C5372Ff220);

    constructor() ERC721("SpookyFrens", "SF") {
        setBaseURI("https://fast-food-fren.herokuapp.com/spookyfrens/");
    }

    modifier claimIsOpen {
        require(block.timestamp <= endClaim_timestamp, "Claim end");
        require(_totalSupply() <= MAX_ELEMENTS, "Claim end");
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
            require(canClaim(_tokenId) && fastFoodFrens.ownerOf(_tokenId) == _msgSender(), "Bad owner!");

            _spookyFrensUsed[_tokenId] = 1;
            _mintAnElement(_to, _tokenId);

        }
    }

    function canClaim(uint256 _tokenId) public view returns(bool) {
        return _spookyFrensUsed[_tokenId] == 0;
    }

    function canClaimBatch(uint256[] memory _tokensId) public view returns(bool[] memory) {
        bool[] memory claimable = new bool[](_tokensId.length);
        for (uint256 i = 0; i < _tokensId.length; i++) {
                claimable[i] = canClaim(_tokensId[i]); 
        }
        return claimable;
    }

    function claimableBatch(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = fastFoodFrens.balanceOf(_owner);

        uint256[] memory wallet = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            wallet[i] = fastFoodFrens.tokenOfOwnerByIndex(_owner, i);
        }

        uint256[] memory claimable = new uint256[](wallet.length);
        for (uint256 i = 0; i < wallet.length; i++) {
            claimable[i] = canClaim(wallet[i]) ? wallet[i] : 0xffffff;
        }
        return claimable;
    }

    function _mintAnElement(address _to, uint256 id) private {
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateSpookyFren(id);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
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
    function setFastFoodFrens(address _fastFoodFrens) external onlyOwner {
        fastFoodFrens = ERC721Enumerable(_fastFoodFrens);
    }
}