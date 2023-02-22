// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Signature.sol";

contract NutsStaking is Ownable, IERC721Receiver {
    struct StakedItem {
        uint id;
        address owner;
        uint stakedAt;
        uint expiresAt;
    }

    address public unstakeSigner;
    IERC721 public immutable parentNft;

    mapping(uint => StakedItem) public stakedItems;
    mapping(address => uint[]) public stakedItemsByOwner;

    event Stake(uint id, address owner, uint timestamp);
    event Unstake(uint id, address owner, uint timestamp);
    event UnstakeWithSignature(uint id, address owner, uint timestamp);
    event UnstakeToAdmin(uint id, address owner, uint timestamp);
    event SetSigner(address signer);

    constructor(address _unstakeSigner, address _parentContract) payable {
        unstakeSigner = _unstakeSigner;
        parentNft = IERC721(_parentContract);
    }

    function stake(uint _id) public {
        parentNft.safeTransferFrom(msg.sender, address(this), _id);

        address owner = msg.sender;
        uint stakedAt = block.timestamp;
        uint expiresAt = block.timestamp + 180 days;

        stakedItems[_id] = StakedItem({
            id: _id,
            owner: owner,
            stakedAt: stakedAt,
            expiresAt: expiresAt
        });
        stakedItemsByOwner[owner].push(_id);

        emit Stake(_id, owner, stakedAt);
    }

    function unstake(uint _id) public {
        StakedItem storage stakedItem = stakedItems[_id];
        require(stakedItem.owner == msg.sender, "Not owner");
        require(
            stakedItem.expiresAt <= block.timestamp,
            "Not ready for unstake"
        );

        parentNft.safeTransferFrom(address(this), msg.sender, _id);

        delete stakedItems[_id];

        uint[] storage stakedIds = stakedItemsByOwner[msg.sender];
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == _id) {
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                break;
            }
        }

        emit Unstake(_id, msg.sender, block.timestamp);
    }

    function unstakeWithSignature(uint _id, bytes memory _signature) public {
        StakedItem storage stakedItem = stakedItems[_id];
        require(stakedItem.owner == msg.sender, "Not owner");

        bool isSignatureValid = Signature.verify(
            unstakeSigner,
            stakedItem.owner,
            stakedItem.id,
            stakedItem.stakedAt,
            stakedItem.expiresAt,
            _signature
        );
        require(isSignatureValid, "Invalid signature");

        delete stakedItems[_id];

        uint[] storage stakedIds = stakedItemsByOwner[msg.sender];
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == _id) {
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                break;
            }
        }

        emit UnstakeWithSignature(_id, msg.sender, block.timestamp);
    }

    function withdrawToAdmin(uint _id) public onlyOwner {
        StakedItem storage stakedItem = stakedItems[_id];
        require(stakedItem.owner != address(0), "Not staked");

        parentNft.safeTransferFrom(address(this), msg.sender, _id);

        address originalOwner = stakedItem.owner;
        delete stakedItems[_id];

        uint[] storage stakedIds = stakedItemsByOwner[stakedItem.owner];
        for (uint i = 0; i < stakedIds.length; i++) {
            if (stakedIds[i] == _id) {
                stakedIds[i] = stakedIds[stakedIds.length - 1];
                stakedIds.pop();
                break;
            }
        }

        emit UnstakeToAdmin(_id, originalOwner, block.timestamp);
    }

    function getMessageHash(
        address _owner,
        uint _id,
        uint _stakedAt,
        uint _expiresAt
    ) public pure returns (bytes32) {
        return Signature.getMessageHash(_owner, _id, _stakedAt, _expiresAt);
    }

    function getStakesByOwner(
        address _owner
    ) public view returns (StakedItem[] memory) {
        uint[] memory stakedIds = stakedItemsByOwner[_owner];

        StakedItem[] memory stakes = new StakedItem[](stakedIds.length);
        for (uint i = 0; i < stakedIds.length; i++) {
            uint id = stakedIds[i];
            StakedItem storage stakedItem = stakedItems[id];
            stakes[i] = stakedItem;
        }

        return stakes;
    }

    function setSigner(address _signer) public onlyOwner {
        unstakeSigner = _signer;

        emit SetSigner(_signer);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}