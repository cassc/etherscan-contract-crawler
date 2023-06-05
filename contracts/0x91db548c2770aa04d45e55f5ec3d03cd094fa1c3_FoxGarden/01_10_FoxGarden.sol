pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FoxGarden is ERC721AQueryable, Ownable, ReentrancyGuard {
    uint256 public maxSupply;

    string public defaultURI;

    string public baseURI;

    uint256 public publicPrice;

    uint256 public publicStartTime;

    uint256 public publicEndTime;

    mapping(uint256 => bool) public blackList;

    using Strings for uint256;

    constructor() public ERC721A("Fox Garden", "Fox Garden") {
        maxSupply = 333;
        publicPrice = 0.5 ether;
        publicStartTime = 1667365200;
        publicEndTime = 999999999999;
        baseURI = "ipfs://bafybeie52pmsjpf7z3tcvifnnbvu23gnhdybhxinqaqx4zk7m2zzq4etny/";
    }

    function setPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setTime(uint256 _publicStartTime, uint256 _publicEndTime)
        external
        onlyOwner
    {
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
    }

    function publicMint(uint256 _num) external payable nonReentrant {
        require(
            block.timestamp >= publicStartTime &&
                block.timestamp <= publicEndTime,
            "Must in time"
        );
        require(msg.value >= publicPrice * _num, "Must greater than value");
        require(totalSupply() + _num <= maxSupply, "Must lower than maxSupply");
        _mint(_msgSender(), _num);
    }

    function adminMint(uint256 _num) external onlyOwner {
        require(totalSupply() + _num <= maxSupply, "Must lower than maxSupply");
        _mint(_msgSender(), _num);
    }

    function withdrawETH(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken(address _token, address _to) external onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
            require(!blackList[i], "In blacklist");
        }
    }

    function setBlackList(uint256[] calldata _blackList, bool _status)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _blackList.length; i++) {
            blackList[_blackList[i]] = _status;
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory imageURI = bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString()))
            : defaultURI;

        return imageURI;
    }
}