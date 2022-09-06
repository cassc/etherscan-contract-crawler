// SPDX-License-Identifier: I live in the mountains
pragma solidity ^0.8.9;

import "./interfaces/IERC721TokenReceiver.sol";
import "./DoomsdayGardenMetadata.sol";

contract DoomsdayGarden {

    constructor(){
        supportsInterface[0x80ac58cd] = true; //ERC721
        supportsInterface[0x5b5e139f] = true; //ERC721Metadata
        supportsInterface[0x01ffc9a7] = true; //ERC165

        owner = msg.sender;

        _mint(1,msg.sender,bytes32(0));
    }


    uint constant BASE_COST = 0.000025 ether;
    uint constant BASE_DIFFICULTY = type(uint).max/uint(50000 * 300);
    uint constant DIFFICULTY_RAMP = uint(50000 * 0.1);
    uint constant CREATOR_FEE = 0.005 ether;

    bytes32[] tokens;
    uint public harvested;

    uint public ownerWithdrawn;
    address public owner;

    mapping( uint => uint) public supplyAtMint;

    event Plant(uint _tokenId, bytes32 _hash, address _planter, uint _newSupply, uint _blockNumber);
    event Harvest(uint _tokenId, bytes32 _hash, uint _growth, uint _supplyAtMint, uint _newSupply, uint _blockNumber);

    function plant(uint seed) public payable {
        uint tokenId = tokens.length + 1;
        uint supply = totalSupply();

        uint difficulty = BASE_DIFFICULTY - (DIFFICULTY_RAMP * supply);

        uint cost = BASE_COST * supply  + CREATOR_FEE;

        bytes32 hash = keccak256(abi.encodePacked(
                        msg.sender,
                        tokens[tokens.length - 1],
                        seed
                    ));

        require(uint(hash) < difficulty,"difficulty");
        require(msg.value == cost,"cost");

        supplyAtMint[tokenId] = supply;

        hash = keccak256(abi.encodePacked(hash,block.timestamp));

        _mint(tokenId,msg.sender,hash);

        emit Plant(tokenId, hash, msg.sender, totalSupply(), block.number);
    }

    function harvest(uint tokenId) public{
        require(msg.sender == ownerOf(tokenId),"ownerOf");

        uint growth = (tokens.length - tokenId);
        uint produce = growth * BASE_COST;


        harvested++;

        _burn(tokenId);

        payable(msg.sender).transfer(produce);

        emit Harvest(tokenId, tokens[tokenId - 1], growth, supplyAtMint[tokenId], totalSupply(), block.number);
    }

    function harvestMultiple(uint[] calldata tokenIds) public{
        require(tokenIds.length > 0,"tokenIds");
        for(uint i = 0; i < tokenIds.length; i++){
            harvest(tokenIds[i]);
        }
    }


    function hashOf(uint _tokenId) public view returns(bytes32){
        require(isValidToken(_tokenId),"invalid");
        return tokens[_tokenId - 1];
    }
    function getEthContained(uint _tokenId) public view returns(uint){
        require(isValidToken(_tokenId),"invalid");
        return (tokens.length - _tokenId) * BASE_COST;
    }
    function getLastHash() public view returns(bytes32){
        return tokens[tokens.length - 1];
    }
    function getMiningState() public view returns(bytes32 _hash, uint _supply, uint _harvested, uint blockNumber){
        return (tokens[tokens.length - 1], totalSupply(), harvested, block.number);
    }


    function treeData(uint _tokenId) public view returns(bytes32 _hash, uint _supplyAtMint, uint _planted){
        require(isValidToken(_tokenId),"invalid");

        return (tokens[_tokenId - 1],supplyAtMint[_tokenId],tokens.length);
    }

    //////===721 Standard
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //////===721 Implementation
    mapping(address => uint256) public balanceOf;
    mapping (uint256 => address) internal allowance;
    mapping (address => mapping (address => bool)) public isApprovedForAll;

    mapping(uint256 => address) owners;  //Mapping of owners

    //    METADATA VARS
    string public name = "Doomsday Garden";
    string public symbol = "TREE";

    address private __metadata;


    function _mint(uint _tokenId,address _to, bytes32 _hash) private{
        owners[_tokenId] = msg.sender;
        balanceOf[_to]++;

        tokens.push(_hash);
        emit Transfer(address(0),_to,_tokenId);
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
        require( _owner == msg.sender                    //Require Sender Owns Token
            || isApprovedForAll[_owner][msg.sender]                //  or is approved for all.
        ,"permission");

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

        //Check Transferable
        //There is a token validity check in ownerOf
        address _owner = ownerOf(_tokenId);

        require ( _owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || isApprovedForAll[_owner][msg.sender]          //or is approved for all
        ,"permission");

        require(_owner == _from,"owner");
        require(_to != address(0),"zero");

        emit Transfer(_from, _to, _tokenId);

        owners[_tokenId] =_to;

        balanceOf[_from]--;
        balanceOf[_to]++;

        //Reset approved if there is one
        if(allowance[_tokenId] != address(0)){
            delete allowance[_tokenId];
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
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

        return DoomsdayGardenMetadata(__metadata).tokenURI(
                _tokenId,
                tokens[_tokenId-1],
                supplyAtMint[_tokenId],
                tokens.length);
    }


    function totalSupply() public view returns (uint256){
        return tokens.length - harvested;
    }


    ///////===165 Implementation
    mapping (bytes4 => bool) public supportsInterface;
    ///==End 165


    //Admin
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