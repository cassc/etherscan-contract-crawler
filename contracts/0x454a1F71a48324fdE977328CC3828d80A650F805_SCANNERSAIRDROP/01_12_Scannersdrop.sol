//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SCANNERSAIRDROP is ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;

    mapping(uint256 => uint256) public dropSessions;

    mapping(uint256 => bytes32[3]) public dropURIs;

    Counters.Counter public dropIDs;

    address private owner;

    uint256 lastdrop;

    constructor() ERC721("SCANNERS AIRDROP", "SCANDROP") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function setDropURI(uint256 _dropId, string calldata b1, string calldata b2, string calldata b3) external onlyOwner {
        require(_dropId >= lastdrop, "URI already set");
        bytes32[3] memory setURI;
        setURI[0] = bytes32(bytes(b1));
        setURI[1] = bytes32(bytes(b2));
        setURI[2] = bytes32(bytes(b3));
        dropURIs[_dropId] = setURI;
        lastdrop = _dropId;
    }

    function dropSingle(address addr) external onlyOwner {
        drop(addr);
    }

    function dropBatch(address[] calldata addrs) external onlyOwner {
        for (uint256 i; i < addrs.length; ++i) {
            drop(addrs[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Unminted");
        uint256 fromSession = dropSessions[tokenId];
        bytes32[3] memory baseURI = dropURIs[fromSession];
        return string(abi.encodePacked(baseURI[0], baseURI[1], baseURI[2]));
    }

    function drop(address _to) internal {
        uint256 sid = dropIDs.current();
        _safeMint(_to, sid);
        dropSessions[sid] = lastdrop;
        dropIDs.increment();
    }

    function getowner() public view virtual returns (address) {
        return owner;
    }

    function _checkOwner() internal view virtual {
        require(getowner() == _msgSender(), "Only Owner");
    }

    receive() external payable {}

    fallback() external payable {}
}