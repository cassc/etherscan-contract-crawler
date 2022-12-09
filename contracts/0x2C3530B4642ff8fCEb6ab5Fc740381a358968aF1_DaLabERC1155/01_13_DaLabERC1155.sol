//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DaLabERC1155 is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public immutable tokenAmount = 1;

    struct Badge {
        bool mintable;
        bool transferable;
        uint256 maxSupply;
        string tokenURI;
        uint256 maxMintPerWallet; // 0 means user can mint how much they want. so no limitation with minting
    }

    mapping(uint256 => Badge) public badges;
    mapping(uint256 => uint256) public totalSupply;
    mapping(address => Badge[]) private userBadges;
    event Mint(address indexed minter, uint256 indexed tokenId);
    event MintByAdmin(
        address indexed minter,
        address indexed holder,
        uint256 indexed tokenId
    );
    event NewBadge(uint256 indexed id, bool mintable);
    event UpdateBadge(uint256 indexed id, bool mintable);
    event BurnBadge(uint256 indexed id, address indexed holder);

    constructor() ERC1155("") {}

    function getBadges() public view returns (Badge[] memory) {
        Badge[] memory badgeArray = new Badge[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            badgeArray[i] = badges[i + 1];
        }
        return badgeArray;
    }

    function badgesOf(address _of) public view returns (Badge[] memory) {
        return userBadges[_of];
    }

    modifier onlyExistBadge(uint256 _tokenId) {
        require(
            _tokenId > 0 && _tokenId <= _tokenIds.current(),
            "Badge Not Exists"
        );
        _;
    }

    modifier onlyHolder(address _of, uint256 _tokenId) {
        require(balanceOf(_of, _tokenId) > 0, "Invalid: NOT HOLDER");
        _;
    }

    modifier onlyBelowMaxMintPerWallet(address _of, uint256 _tokenId) {
        require(
            (balanceOf(_of, _tokenId) < badges[_tokenId].maxMintPerWallet) ||
                badges[_tokenId].maxMintPerWallet == 0,
            "Invalid: EXCEED MAX MINT PER WALLET"
        );
        _;
    }

    modifier notExceedMaxSupply(uint256 _tokenId) {
        require(
            badges[_tokenId].maxSupply > totalSupply[_tokenId],
            "Invalid: Exceed Supply"
        );
        _;
    }

    function createBadge(Badge memory _badge) public onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        badges[newItemId] = _badge;
        totalSupply[newItemId] = 0;
        emit NewBadge(newItemId, _badge.mintable);
    }

    function updateBadgeAttr(
        uint256 _tokenId,
        bool _mintable,
        string memory _tokenURI
    ) public onlyOwner onlyExistBadge(_tokenId) {
        bytes memory _uri = bytes (_tokenURI);
        badges[_tokenId].mintable = _mintable;
        if (_uri.length > 1) {
            badges[_tokenId].tokenURI = _tokenURI;
        }
        emit UpdateBadge(_tokenId, _mintable);
    }

    function mint(uint256 _tokenId)
        public
        onlyExistBadge(_tokenId)
        notExceedMaxSupply(_tokenId)
        onlyBelowMaxMintPerWallet(msg.sender, _tokenId)
    {
        _mint(msg.sender, _tokenId, tokenAmount, "");
        totalSupply[_tokenId] += 1;
        userBadges[msg.sender].push(badges[_tokenId]);
        emit Mint(msg.sender, _tokenId);
    }

    // only by owner
    function mintByAdmin(uint256 _tokenId, address _to)
        public
        onlyOwner
        onlyExistBadge(_tokenId)
        notExceedMaxSupply(_tokenId)
        onlyBelowMaxMintPerWallet(_to, _tokenId)
    {
        _mint(_to, _tokenId, tokenAmount, "");
        totalSupply[_tokenId] += 1;
        userBadges[_to].push(badges[_tokenId]);
        emit MintByAdmin(msg.sender, _to, _tokenId);
    }

    // or use before transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public virtual override onlyExistBadge(_tokenId) {
        require(badges[_tokenId].transferable, "TRANSFER FORBIDDEN");

        _safeTransferFrom(_from, _to, _tokenId, _amount, _data);
    }

    function burn(uint256 _tokenId, address _of)
        public
        onlyExistBadge(_tokenId)
        onlyHolder(_of, _tokenId)
    {
        require(
            msg.sender == owner() || msg.sender == _of,
            "NOT HAVE AUTHORITY"
        );
        totalSupply[_tokenId] -= 1;
        _burn(_of, _tokenId, tokenAmount);
        emit BurnBadge(_tokenId, _of);
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return badges[_tokenId].tokenURI;
    }
}