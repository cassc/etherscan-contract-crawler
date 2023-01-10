// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";

contract NFT is Ownable, ERC721("CARBON", "CARBON") {
    event DataAdded(uint256 indexed index, bytes data);
    event DataUpdated(uint256 indexed index, bytes data);
    event DataFreezed(uint256 indexed index);

    event NFTDataAdded(uint256 indexed tokenId, uint256 indexed dataIndex);
    event NFTDataRemoved(uint256 indexed tokenId, uint256 indexed dataIndex);

    // on-chain metadata
    mapping(uint256 => bytes) public metadata;
    mapping(uint256 => bool) public freezed;
    uint256 public nextTokenId;

    // binary data
    bytes[] public binaryData;
    // token id to data id mapping
    mapping(uint256 => uint256[]) public tokenIdData;

    struct MintInfo {
        string metadata;
        uint256[] dataIndexes;
        bytes[] data;
    }

    function batchMint(MintInfo[] calldata _mintInfo) public onlyOwner {
        for (uint256 i = 0; i < _mintInfo.length; i++) {
            _mintWithData(_mintInfo[i]);
        }
    }

    function mint(MintInfo calldata _mintInfo) public onlyOwner {
        _mintWithData(_mintInfo);
    }

    function _mintWithData(MintInfo calldata _mintInfo) internal {
        bytes memory byteMetadata = bytes(_mintInfo.metadata);
        metadata[nextTokenId] = byteMetadata;

        // add data
        for (uint256 i = 0; i < _mintInfo.data.length; i++) {
            if (_mintInfo.data[i].length != 0) {
                tokenIdData[nextTokenId].push(binaryData.length); // add the latest binary data that is being added below
                _addData(_mintInfo.data[i]);
            }
        }

        // link preset data with this nft
        for (uint256 i = 0; i < _mintInfo.dataIndexes.length; i++) {
            tokenIdData[nextTokenId].push(_mintInfo.dataIndexes[i]);
        }
        _mint(msg.sender, nextTokenId++);
    }

    function _addData(bytes calldata _data) internal {
        binaryData.push(_data);
        emit DataAdded(binaryData.length - 1, _data);
    }

    function addData(bytes calldata _data) public onlyOwner {
        _addData(_data);
    }

    function updateData(uint256 _index, bytes calldata _data) external onlyOwner {
        require(!freezed[_index], "Data is already freezed!");

        binaryData[_index] = _data;
        emit DataUpdated(_index, _data);
    }

    function setNFTData(uint256 _tokenId, uint256[] calldata _dataIndex) public onlyOwner {
        for (uint256 i = 0; i < _dataIndex.length; i++) {
            tokenIdData[_tokenId].push(_dataIndex[i]);
            emit NFTDataAdded(_tokenId, _dataIndex[i]);
        }
    }

    function setNFTDataBatch(uint256[] memory _tokenIds, uint256[][] calldata _dataIndexes) external onlyOwner {
        require(_tokenIds.length == _dataIndexes.length, "Invalid args");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            setNFTData(_tokenIds[i], _dataIndexes[i]);
        }
    }

    function removeNFTData(uint256 _tokenId, uint256 _index) external onlyOwner {
        emit NFTDataRemoved(_tokenId, tokenIdData[_tokenId][_index]);
        tokenIdData[_tokenId][_index] = tokenIdData[_tokenId][tokenIdData[_tokenId].length - 1];
        tokenIdData[_tokenId].pop();
    }

    function freezData(uint256 index) external onlyOwner {
        freezed[index] = true;
        emit DataFreezed(index);
    }

    function getNFTDataIndexes(uint256 _tokenId) external view returns (uint256[] memory) {
        return tokenIdData[_tokenId];
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
        return string(abi.encodePacked(baseURL, Base64.encode(metadata[_tokenId])));
    }
}