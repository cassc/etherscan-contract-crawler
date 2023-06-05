// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MEMECOPY is ERC1155, Ownable, AccessControlEnumerable, ERC2981 {
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    string internal baseTokenURI;
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant JUICING_ROLE = keccak256("JUICING_ROLE");

    Counters.Counter nftID;

    constructor(
        string memory _name,
        string memory _symbol,
        address payable royaltyReceiver
    ) ERC1155("https://api.dontdiememe.com/nft/1155/{id}") {
        name = _name;
        symbol = _symbol;
        _setDefaultRoyalty(royaltyReceiver, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, "");
    }

    function createCard() public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 id = nftID.current();
        nftID.increment();
        return id;
    }

    function safeMint(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 id = nftID.current();
        _mint(to, id, amount, "");
        nftID.increment();
        return id;
    }

    function _baseURI() internal view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function uri(uint256 _tokenid)
        public
        view
        override
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenid.toString()))
                : "";
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    mapping(uint256 => uint256) private juicingStarted;
    mapping(uint256 => uint256) private juicingTaskId;

    event Juiced(uint256 indexed tokenId, uint256 indexed taskId);

    event UnJuiced(uint256 indexed tokenId, uint256 indexed taskId);

    function juicingStatus(uint256 tokenId)
        external
        view
        returns (
            bool juicing,
            uint256 start,
            uint256 task
        )
    {
        start = juicingStarted[tokenId];
        task = juicingTaskId[tokenId];
        if (start != 0) {
            juicing = true;
        } else {
            juicing = false;
        }
    }

    function _beforeTokenTransfer(
        address,
        address,
        address,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; ++i)
            require(juicingStarted[ids[i]] == 0, "MEME721: juicing");
    }

    function toggleJuicing(
        uint256 tokenId,
        bool juicing,
        uint256 taskId
    ) internal {
        if (juicing) {
            juicingStarted[tokenId] = block.timestamp;
            juicingTaskId[tokenId] = taskId;
            emit Juiced(tokenId, taskId);
        } else {
            require(taskId == juicingTaskId[tokenId], "MEME721: wrong taskid");
            juicingStarted[tokenId] = 0;
            juicingTaskId[tokenId] = 0;
            emit UnJuiced(tokenId, taskId);
        }
    }

    function toggleJuicing(
        uint256[] calldata tokenIds,
        bool juicing,
        uint256 taskId
    ) external onlyRole(JUICING_ROLE) {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleJuicing(tokenIds[i], juicing, taskId);
        }
    }
}