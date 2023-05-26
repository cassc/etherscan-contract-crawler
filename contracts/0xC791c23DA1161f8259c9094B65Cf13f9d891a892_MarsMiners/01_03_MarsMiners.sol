// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC721TokenReceiver.sol";
import "./interfaces/IMarsMetadata.sol";

contract MarsMiners {

    constructor(){
        supportsInterface[0x80ac58cd] = true;
        supportsInterface[0x5b5e139f] = true;
        supportsInterface[0x01ffc9a7] = true;
        owner = msg.sender;
        _mint(1,msg.sender,bytes32(0));
        mintCost = BASE_COSTS[0] + CREATOR_FEE;
    }

    uint256[8]  BASE_COSTS = [
        0.000010 ether,
        0.000020 ether,
        0.000025 ether,
        0.000030 ether,

        0.000040 ether,
        0.000050 ether,
        0.000070 ether,
        0.000100 ether
    ];

    uint constant BASE_DIFFICULTY = type(uint).max/uint(50000 * 300);
    uint constant DIFFICULTY_RAMP = uint(50000 * 0.1);
    uint constant CREATOR_FEE = 0.005 ether;
    bytes32[] tokens;
    uint public closed;
    uint public ownerWithdrawn;
    address public owner;
    uint public mintCost;
    mapping( uint => uint) public supplyAtMint;

    event OpenMine( uint _tokenId, bytes32 _hash, address _miner,   uint _newSupply, uint _newMintCost, uint _blockNumber);
    event CloseMine(uint _tokenId, bytes32 _hash, uint _excavated, uint _supplyAtMint, uint _newSupply, uint _newMintCost,  uint _blockNumber);

    function getMineType(bytes32 hash, uint _supplyAtMint) public pure returns(uint){
        uint mineTypeMax;
        if(_supplyAtMint < 500){
            mineTypeMax = 2;
        }else if(_supplyAtMint < 1000){
            mineTypeMax = 3;
        }else if(_supplyAtMint < 1500){
            mineTypeMax = 4;
        }else if(_supplyAtMint < 2000){
            mineTypeMax = 5;
        }else if(_supplyAtMint < 2500){
            mineTypeMax = 6;
        }else{
            mineTypeMax = 7;
        }

        return (uint(hash)%100)**3 *(mineTypeMax + 1) / 1000000;
    }

    function openMine(uint nonce) public payable {
        uint tokenId = tokens.length + 1;
        uint supply = totalSupply();

        uint difficulty = BASE_DIFFICULTY - (DIFFICULTY_RAMP * supply);

        bytes32 hash = keccak256(abi.encodePacked(
                msg.sender,
                tokens[tokens.length - 1],
                nonce
            ));

        require(uint(hash) < difficulty,"difficulty");
        require(msg.value == mintCost,"cost");

        supplyAtMint[tokenId] = supply;
        hash = keccak256(abi.encodePacked(hash,block.timestamp));
        _mint(tokenId,msg.sender,hash);
        mintCost += BASE_COSTS[getMineType(hash,supply)];

        emit OpenMine(tokenId, hash, msg.sender, totalSupply(), mintCost, block.number);
    }

    function closeMine(uint tokenId) public{
        payable(msg.sender).transfer(_closeMine(tokenId));
    }

    function _closeMine(uint tokenId) private returns(uint){
        require(msg.sender == ownerOf(tokenId),"ownerOf");

        uint excavated = (tokens.length - tokenId);
        uint BASE_COST = BASE_COSTS[getMineType(hashOf(tokenId),supplyAtMint[tokenId])];
        uint earnings = excavated * BASE_COST;
        closed++;
        _burn(tokenId);
        mintCost -= BASE_COST;

        emit CloseMine(tokenId, tokens[tokenId - 1], excavated, supplyAtMint[tokenId], totalSupply(), mintCost, block.number);
        return earnings;
    }

    function closeMultiple(uint[] calldata tokenIds) public{
        require(tokenIds.length > 0,"tokenIds");
        uint total;
        for(uint i = 0; i < tokenIds.length; i++){
            total += _closeMine(tokenIds[i]);
        }
        payable(msg.sender).transfer(total);
    }

    function hashOf(uint _tokenId) public view returns(bytes32){
        require(isValidToken(_tokenId),"invalid");
        return tokens[_tokenId - 1];
    }

    function getEthContained(uint _tokenId) public view returns(uint){
        require(isValidToken(_tokenId),"invalid");
        uint BASE_COST = BASE_COSTS[getMineType(hashOf(_tokenId),supplyAtMint[_tokenId])];
        return (tokens.length - _tokenId) * BASE_COST;
    }

    function getLastHash() public view returns(bytes32){
        return tokens[tokens.length - 1];
    }

    function getMiningState() public view returns(bytes32 _hash, uint _supply, uint _closed, uint blockNumber){
        return (tokens[tokens.length - 1], totalSupply(), closed, block.number);
    }

    function mineData(uint _tokenId) public view returns(bytes32 _hash, uint _supplyAtMint, uint _opened){
        require(isValidToken(_tokenId),"invalid");

        return (tokens[_tokenId - 1],supplyAtMint[_tokenId],tokens.length);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(address => uint256) public balanceOf;
    mapping (uint256 => address) internal allowance;
    mapping (address => mapping (address => bool)) public isApprovedForAll;

    mapping(uint256 => address) owners;

    string public name = "Mars Mining Company";
    string public symbol = "MARS";

    address private __metadata;

    address constant VB = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    function _mint(uint _tokenId,address _to, bytes32 _hash) private{
        owners[_tokenId] = msg.sender;
        balanceOf[_to]++;
        tokens.push(_hash);
        emit Transfer(address(0),VB,_tokenId);
        emit Transfer(VB,_to,_tokenId);
    }

    function _burn(uint _tokenId) private{
        address _owner = owners[_tokenId];
        balanceOf[ _owner ]--;
        delete owners[_tokenId];

        emit Transfer(_owner,address(0),_tokenId);
    }

    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return owners[_tokenId] != address(0);
    }

    function ownerOf(uint256 _tokenId) public view returns(address){
        require(isValidToken(_tokenId),"invalid");
        return owners[_tokenId];
    }

    function approve(address _approved, uint256 _tokenId)  external{
        address _owner = ownerOf(_tokenId);
        require( _owner == msg.sender || isApprovedForAll[_owner][msg.sender],"permission");
        emit Approval(_owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(isValidToken(_tokenId),"invalid");
        return allowance[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        isApprovedForAll[msg.sender][_operator] = _approved;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        address _owner = ownerOf(_tokenId);
        require ( _owner == msg.sender  || allowance[_tokenId] == msg.sender  || isApprovedForAll[_owner][msg.sender],"permission");
        require(_owner == _from,"owner");
        require(_to != address(0),"zero");
        emit Transfer(_from, _to, _tokenId);
        owners[_tokenId] =_to;
        balanceOf[_from]--;
        balanceOf[_to]++;
        if(allowance[_tokenId] != address(0)){
            delete allowance[_tokenId];
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        transferFrom(_from, _to, _tokenId);
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from,_to,_tokenId,"");
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory){
        require(isValidToken(_tokenId),'tokenId');

        return IMarsMetadata(__metadata).tokenURI(
            _tokenId,
            tokens[_tokenId-1],
            supplyAtMint[_tokenId],
            tokens.length);
    }

    function totalSupply() public view returns (uint256){
        return tokens.length - closed;
    }

    mapping (bytes4 => bool) public supportsInterface;

    function setOwner(address newOwner) public{
        require(msg.sender == owner,"owner");
        owner = newOwner;
    }

    function setMetadata(address _metadata) public{
        require(msg.sender == owner,"owner");
        __metadata = _metadata;
    }

    function ownerWithdraw() public{
        require(msg.sender == owner,"owner");
        uint toWithdraw = (tokens.length - ownerWithdrawn - 1) * CREATOR_FEE ;
        require(toWithdraw > 0,"withdrawn");
        ownerWithdrawn = tokens.length - 1;
        payable(msg.sender).transfer(toWithdraw);

    }
}