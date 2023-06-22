// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./INameWrapper.sol";
import "./ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "https://github.com/ensdomains/name-wrapper/blob/master/contracts/BytesUtil.sol";

contract PlayTrain is Ownable, ERC1155Holder {
    using BytesUtils for bytes;

    INameWrapper nameWrapper;

    uint256 public index;
    address public resolver;
    bool public isMintable;
    
    mapping(bytes32 => bool) public isMinted;
    mapping(uint256 => bytes32) public indexToNode;
    mapping(uint256 => address) public indexToOwner;

    function setEnsData(address _nameWrapper, address _resolver, bytes32 _startNode) external onlyOwner {
        nameWrapper = INameWrapper(_nameWrapper);
        resolver = _resolver;
        indexToNode[0] = _startNode;
    }

    function getOnTheTrain(bytes32 yourNode, string memory label) public {
        require(isMintable, "PlayTrain: not mintable");
        require(!isMinted[yourNode], "PlayTrain: Already minted");
        bytes memory name = nameWrapper.names(yourNode);
        (bytes32 labelhash, ) = name.readLabel(0);
        require(labelhash == keccak256(bytes(label)), "PlayTrain: label is not correct");

        nameWrapper.setSubnodeRecord(
            indexToNode[index],
            label,
            address(this),
            resolver,
            0,
            0,
            0
        );

        bytes32 nextParentNode = _makeNode(indexToNode[index], labelhash);
        (address owner, ,) = nameWrapper.getData(uint256(yourNode));

        uint256 nextIndex = ++index;
        indexToOwner[nextIndex] = owner;
        indexToNode[nextIndex] = nextParentNode;
        isMinted[yourNode] = true;

        if(index > 2){
            uint256 tokenid = uint256(indexToNode[index - 2]);
            nameWrapper.safeTransferFrom(address(this), owner, tokenid, 1, "");
        }
    }

    function setMintable(bool _isMintable) external onlyOwner {
        isMintable = _isMintable;
    }
    
    function _makeNode(bytes32 node, bytes32 labelhash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, labelhash));
    }

    function getIndex() external view returns(uint256) {
        return index;
    }

    function getNode(uint256 _index) external view returns(bytes32) {
        return indexToNode[_index];
    }

    function transfer(address from, address to, uint256 id) external onlyOwner {
        nameWrapper.safeTransferFrom(from, to, id, 1, "");
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public override(ERC1155Holder) returns(bytes4) {
        return ERC1155Holder.onERC1155Received(operator, from, id, value, data);
    }
}