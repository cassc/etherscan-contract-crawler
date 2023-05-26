// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MindfulMetaversePortals is ERC1155, Ownable {
    uint256 TOKEN_ID = 1;
    uint256 GOLD_TOKEN_ID = 2;
    bytes32 public merkleRootHash = 0x726bacaa8fc4fd45d050b77f1f9a57114823dfbc6afb65ebb067fd2b7a79110e;
    string public BASE_URI = "https://gateway.pinata.cloud/ipfs/QmYSEoTVu2TBEJFgurQ9FxfmJdJBp5N2ewKnEKfDbTbYBt/";
    string public name = "MindfulMetaversePortals";
    string public symbol = "MNDFL";
    uint256 public MAX_SUPPLY = 15000;
    uint256 public totalSupply;
    mapping(address => uint8) mintTrack;
    bool public whiteListCheck = true;
    constructor() ERC1155(BASE_URI){

    }

    function setMaxSupply(uint256 _max_supply) external onlyOwner {
        require(_max_supply > totalSupply, "can't set to less than current totalSupply");
        MAX_SUPPLY = _max_supply;
    }

    function setMerkleRoot(bytes32 rootHash) public onlyOwner {
        merkleRootHash = rootHash;
    }

    function setWhiteListCheck(bool _whitelist) external onlyOwner {
        whiteListCheck = _whitelist;
    }

    function mintDaoNFT(bytes32[] calldata _merkleProof) public {
        if (whiteListCheck) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

            require(
                MerkleProof.verify(_merkleProof, merkleRootHash, leaf),
                "You are not whitelisted"
            );
        }
        require(mintTrack[msg.sender] == 0, "You already minted Dao NFT");
        require(totalSupply < MAX_SUPPLY, "MAX SUPPLY REACHED");
        mintTrack[msg.sender] = 1;
        totalSupply += 1;
        _mint(msg.sender, TOKEN_ID, 1, "");
    }


    function setBaseURI(string calldata _baseURI) public onlyOwner {
        require(bytes(_baseURI).length > 0, "Can't set BASE URI to empty string.");
        BASE_URI = _baseURI;
    }

    function airdrop(address _to, uint amount, uint _token_id) external onlyOwner {
        require(amount > 0, "amount must be greater than 0");
        require(_token_id > 0 && _token_id < 3, "Token ID doesn't exist");
        _mint(_to, _token_id, amount, "");
    }

    function uri(uint256 _tokenID) public override view returns (string memory){
        require(_tokenID == TOKEN_ID || _tokenID == GOLD_TOKEN_ID, "Token id doesn't exist");
        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenID), ".json"));
    }
}