//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface GameBalance {
    function shardId() external returns (uint256);

    function updatePastOwners(address account) external;
}

contract CabinetOfCuriosities is ERC1155, Ownable {
    uint256 public _currentTokenID = 0;
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => uint256) public tokenSupply;

    address public mirrorAddress;

    constructor() ERC1155("Cabinet Of Curiosities") {}

    function create(
        address initialOwner,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) external returns (uint256) {
        require(
            msg.sender == owner() || msg.sender == mirrorAddress,
            "unauthorized"
        );
        require(bytes(tokenUri).length > 0, "uri required");
        require(totalTokenSupply > 0, "supply must be more than 0");
        uint256 id = _currentTokenID;
        _currentTokenID++;

        tokenURIs[id] = tokenUri;
        tokenSupply[id] = totalTokenSupply;
        emit URI(tokenUri, id);
        _mint(initialOwner, id, totalTokenSupply, data);
        return id;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(tokenURIs[id]).length > 0, "That token does not exist");
        return tokenURIs[id];
    }

    function setTokenURI(uint256 tokenId, string calldata tokenUri)
        public
        onlyOwner
    {
        require(
            bytes(tokenURIs[tokenId]).length > 0,
            "That token does not exist"
        );
        emit URI(tokenUri, tokenId);
        tokenURIs[tokenId] = tokenUri;
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (operator == mirrorAddress) {
            return true;
        }
        return super.isApprovedForAll(account, operator);
    }

    function _beforeTokenTransfer(
        address,
        address,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal override {
        require(ids.length == 1, "batch transfer not supported");
        if (
            mirrorAddress != address(0) &&
            ids[0] == GameBalance(mirrorAddress).shardId() &&
            balanceOf(to, ids[0]) == 0
        ) {
            GameBalance(mirrorAddress).updatePastOwners(to);
        }
    }

    function setMirrorAddress(address _address) public onlyOwner {
        require(mirrorAddress == address(0), "Already set");
        mirrorAddress = _address;
    }
}