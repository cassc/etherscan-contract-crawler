//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract WhiteSandsStaking is IERC721Receiver, Ownable {
    struct TokenInfo {
        uint32 collectionId;
        uint32 id;
        uint32 timestamp;
        address owner;
    }

    mapping(IERC721 => bool) public _acceptedCollections;
    mapping(IERC721 => uint32) public _collectionToId;
    mapping(IERC721 => mapping(uint256 => mapping(address => uint256)))
        public _indexOfTokens;
    mapping(IERC721 => mapping(uint256 => mapping(address => uint256)))
        public _indexOfTokensByOwners;
    mapping(IERC721 => mapping(uint256 => mapping(address => bool)))
        public _isStaked;
    mapping(address => TokenInfo[]) public _stakedByOwners;
    TokenInfo[] public _staked;
    IERC721[] public _collections;

    constructor(address[] memory collections) {
        for (uint256 i = 0; i < collections.length; i++) {
            acceptCollection(collections[i]);
        }
    }

    function acceptCollection(address collection_) public onlyOwner {
        IERC721 collection = IERC721(collection_);
        _collections.push(collection);
        _collectionToId[collection] = uint32(_collections.length) - 1;
        _acceptedCollections[collection] = true;
    }

    function removeCollection(address collection) external onlyOwner {
        delete _acceptedCollections[IERC721(collection)];
    }

    function stake(address[] calldata collections, uint256[] calldata ids)
        external
    {
        require(collections.length == ids.length, "!params");
        for (uint256 i = 0; i < collections.length; i++) {
            IERC721 collection = IERC721(collections[i]);
            uint256 id = ids[i];
            require(_acceptedCollections[collection], "!collection");
            _isStaked[collection][id][msg.sender] = true;
            TokenInfo memory ti = TokenInfo(
                _collectionToId[collection],
                uint32(id),
                // solhint-disable-next-line not-rely-on-time
                uint32(block.timestamp),
                msg.sender
            );
            _staked.push(ti);
            _indexOfTokens[collection][id][msg.sender] = _staked.length - 1;
            _stakedByOwners[msg.sender].push(ti);
            _indexOfTokensByOwners[collection][id][msg.sender] =
                _stakedByOwners[msg.sender].length -
                1;
            collection.safeTransferFrom(
                msg.sender,
                address(this),
                id,
                abi.encodePacked(WhiteSandsStaking.stake.selector)
            );
        }
    }

    function unstake(address[] calldata collections, uint256[] calldata ids)
        external
    {
        require(collections.length == ids.length, "!params");
        for (uint256 i = 0; i < collections.length; i++) {
            IERC721 collection = IERC721(collections[i]);
            uint256 id = ids[i];
            require(_isStaked[collection][id][msg.sender], "!staked");
            if (_stakedByOwners[msg.sender].length > 1) {
                uint256 index = _indexOfTokensByOwners[collection][id][
                    msg.sender
                ];
                TokenInfo memory last = _stakedByOwners[msg.sender][
                    _stakedByOwners[msg.sender].length - 1
                ];
                _stakedByOwners[msg.sender][index] = last;
                _indexOfTokensByOwners[_collections[last.collectionId]][
                    last.id
                ][msg.sender] = index;
            }
            _stakedByOwners[msg.sender].pop();
            if (_staked.length > 1) {
                uint256 index = _indexOfTokens[collection][id][msg.sender];
                TokenInfo memory last = _staked[_staked.length - 1];
                _staked[index] = last;
                _indexOfTokens[_collections[last.collectionId]][last.id][
                    last.owner
                ] = index;
            }
            _staked.pop();
            delete _indexOfTokens[collection][id][msg.sender];
            delete _indexOfTokensByOwners[collection][id][msg.sender];
            delete _isStaked[collection][id][msg.sender];
            collection.safeTransferFrom(address(this), msg.sender, id);
        }
    }

    function getStakedByOwner(address owner)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 count = _stakedByOwners[owner].length;
        address[] memory collections = new address[](count);
        uint256[] memory ids = new uint256[](count);
        uint256[] memory timestamps = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            TokenInfo memory ti = _stakedByOwners[owner][i];
            collections[i] = address(_collections[ti.collectionId]);
            ids[i] = ti.id;
            timestamps[i] = ti.timestamp;
        }
        return (collections, ids, timestamps);
    }

    function getStaked()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        return getStakedFrom(0, _staked.length);
    }

    function getStakedFrom(uint256 from, uint256 count)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        address[] memory collections = new address[](count);
        uint256[] memory ids = new uint256[](count);
        address[] memory owners = new address[](count);
        uint256[] memory timestamps = new uint256[](count);
        for (uint256 i = from; i < count; i++) {
            TokenInfo memory ti = _staked[i];
            collections[i] = address(_collections[ti.collectionId]);
            ids[i] = ti.id;
            owners[i] = ti.owner;
            timestamps[i] = ti.timestamp;
        }
        return (collections, ids, owners, timestamps);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata data
    ) external pure override returns (bytes4) {
        require(
            keccak256(data) ==
                keccak256(abi.encodePacked(WhiteSandsStaking.stake.selector)),
            "!invalid"
        );
        return IERC721Receiver.onERC721Received.selector;
    }
}