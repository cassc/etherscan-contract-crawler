pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./BlackholePrevention.sol";

contract MirandusVOX is
    ERC721,
    ERC1155Holder,
    Ownable,
    BlackholePrevention,
    ReentrancyGuard,
    ERC721Enumerable,
    ERC721Burnable,
    VRFConsumerBase
{
    using Counters for Counters.Counter;
    using Address for address payable;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string public constant PROVENANCE = "fa0a30c08c8a6f63e7321c10500edade6ae4f4637551c26a4f664d8b4d6053af";
    uint256 public constant MAX_PURCHASE = 8; 
    uint256 public constant maxSupply = 8888;
    uint256 public constant offset = 0;
    uint256 public constant PRICE = 1;

    address public erc1155Token;
    uint256 public erc1155TokenId;
    uint256 public balance;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public saleStartTimestamp;
    bytes32 internal vrfRequestId;
    uint256 internal vrfRandomness;

    uint private nonce = 0;
    uint[maxSupply] private indices;

    constructor(
        address _erc1155Token,
        uint256 _erc1155TokenId,
        uint256 _saleStartTimestamp
    ) 
    ERC721("VOX Series 2", "VOX") 
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
    )
    {
        erc1155Token = _erc1155Token;
        erc1155TokenId = _erc1155TokenId;
        saleStartTimestamp = _saleStartTimestamp;

        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        require(block.timestamp >= saleStartTimestamp, "Sale has not started");
        require(totalSupply() < maxSupply, "Sale has ended");
        require(value <= maxSupply - _tokenIdCounter.current(), "Cannot buy that many");
        require(msg.sender == erc1155Token, "Invalid token contract used");
        require(id == erc1155TokenId, "Invalid token ID sent");
        require(value <= MAX_PURCHASE, "Cannot buy that many at once");

        uint256 balanceAfter = IERC1155(erc1155Token).balanceOf(
            address(this),
            erc1155TokenId
        );
        if (balance + value == balanceAfter) {
            for (uint256 i = 0; i < value; i++) {
                uint tokenId = randomTokenId();
                _safeMint(from, tokenId);
                _tokenIdCounter.increment();
            }
        }
        balance = IERC1155(erc1155Token).balanceOf(
            address(this),
            erc1155TokenId
        );
        return this.onERC1155Received.selector;
    }

    function generateRandomness() public {
        require(vrfRequestId == 0, "Randomness already requested");
        require(vrfRandomness == 0, "Randomness is already set");
        vrfRequestId = requestRandomness(keyHash, fee);
    }

    function randomTokenId() internal returns (uint) {
        uint remaining = maxSupply - _tokenIdCounter.current();

        uint index = uint(keccak256(abi.encodePacked(vrfRandomness, nonce, msg.sender, block.difficulty, block.timestamp))) % remaining;

        uint tokenId = 0;
        if (indices[index] != 0) {
            tokenId = indices[index];
        } else {
            tokenId = index;
        }

        if (indices[remaining - 1] == 0) {
            indices[index] = remaining - 1;
        } else {
            indices[index] = indices[remaining - 1];
        }

        nonce++;

        return tokenId.add(1);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(vrfRequestId == requestId, "VRF Request Id must match");
        vrfRandomness = randomness;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.collectvox.com/metadata/mirandus/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function withdrawEther(address payable receiver, uint256 amount)
        external
        virtual
        onlyOwner
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external virtual onlyOwner {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 _tokenId
    ) external virtual onlyOwner {
        _withdrawERC721(receiver, tokenAddress, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC1155Receiver, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}