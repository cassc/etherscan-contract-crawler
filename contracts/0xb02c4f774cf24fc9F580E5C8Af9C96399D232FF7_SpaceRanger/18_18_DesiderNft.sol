// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IStarknetCore.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";

abstract contract DesiderNft is ERC721, ERC721Burnable, Ownable {
    using Address for address;
    using Strings for uint256;


    mapping(address => bool) private whitelist;

    mapping(uint256 => uint256) private _tokenLucky;

    mapping(uint256 => uint256) private _token_earn_tm;

    mapping(uint256 => string) private _tokenURIs;

    uint256 constant EARN_INTERNAL = 86400;
    
    function addWhitelist(address _newEntry) external onlyOwner {
        require (_newEntry.isContract(), "only set contract");

        whitelist[_newEntry] = true;
    }

    function initTokenId(uint256 tokenId) internal {
        _tokenLucky[tokenId] = 0;
        _token_earn_tm[tokenId] = block.timestamp;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function upgradeLuck(uint256 tokenId) external {
        require(whitelist[msg.sender], "Not in whitelist");

        _tokenLucky[tokenId] += 1;
        _tokenURIs[tokenId] = string.concat(tokenId.toString(), "-", _tokenLucky[tokenId].toString(), ".json");
    }


    function onlyTokenIdUri(uint256 tokenId) public view returns (string memory) {
        string memory _tokenURI = _tokenURIs[tokenId];

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string.concat(tokenId.toString(), ".json");
    }

    function touchToEarn(uint256 tokenId) external {
        require(whitelist[msg.sender], "Not in whitelist");

        uint256 lastEarnTm = _token_earn_tm[tokenId];
        require(block.timestamp - lastEarnTm > EARN_INTERNAL, "please wait for more time");

        _token_earn_tm[tokenId] = block.timestamp;
    }

    function getLucky(uint256 tokenId) public view virtual returns (uint256 lucky) {
        require(ERC721._exists(tokenId), "tokenId not exist");

        return _tokenLucky[tokenId];
    }

    function getLastEarnTm(uint256 tokenId) public view virtual returns (uint256 lucky) {
        require(ERC721._exists(tokenId), "tokenId not exist");

        return _token_earn_tm[tokenId];
    }

    function _getTokenUri(uint256 tokenId) internal view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function burnForTransferToL2(uint256 tokenId) public virtual {
        require(whitelist[msg.sender], "Not in whitelist");

        super._burn(tokenId);
        delete _tokenURIs[tokenId];
    }


    function receiveFromL1ReMint(address to, uint256 tokenId, uint256 lucky, uint256 earn_tm) public virtual {
        require(whitelist[msg.sender], "Not in whitelist");

        _safeMint(to, tokenId);
        _tokenLucky[tokenId] = lucky;
        if (lucky == 1) {
            _tokenURIs[tokenId] = string.concat(tokenId.toString(), ".json");
        } else {
            _tokenURIs[tokenId] = string.concat(tokenId.toString(), "-", lucky.toString(), ".json");
        }
        _token_earn_tm[tokenId] = earn_tm;
        emit Transfer(address(0), to, tokenId);
    }

}