// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC721TokenReceiver.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IMetadata.sol";

contract MinersOfTheMerge {

    constructor() payable{
        supportsInterface[0x80ac58cd] = true; //ERC721
        supportsInterface[0x5b5e139f] = true; //ERC721Metadata
        supportsInterface[0x01ffc9a7] = true; //ERC165

        owner = msg.sender;

        _mint(1,msg.sender,bytes32(0));


        uint cost = (PRIZE_FEE) * (100 + CREATOR_FEE_PERCENT) / 100;
        require(msg.value == cost,"Must start with prize ETH");
    }


    uint constant BASE_COST = 0.00002 ether;
    uint constant PRIZE_FEE = 0.005 ether;
    uint constant CREATOR_FEE_PERCENT = 10;

    uint constant BASE_DIFFICULTY = type(uint).max/uint(50000 * 300);

    uint constant DIFFICULTY_RAMP = uint(50000 * 0.1);

    bytes32[] tokens;

    uint public ownerWithdrawn;
    address public owner;

    mapping(uint => uint) public tokenWithdrawn;

    bool public winnerHasWithdrawn;
    uint public burnCount;


    function mergeHasHappened() public view returns(bool){
        return block.difficulty == 0;
    }

    event Mine(uint _tokenId, bytes32 _hash, address _miner, uint _blockNumber);
    event WithdrawEth(uint _tokenId, uint _amount, uint _tokenWithdrawn);
    event WithdrawPrize();

    function mine(uint seed) public payable {
        require(!mergeHasHappened() && !winnerHasWithdrawn,"Game has finished");

        uint tokenId = tokens.length + 1;
        uint supply = totalSupply();

        uint difficulty = BASE_DIFFICULTY - (DIFFICULTY_RAMP * supply);

        uint cost = (BASE_COST * supply  + PRIZE_FEE) * (100 + CREATOR_FEE_PERCENT) / 100;

        bytes32 hash = keccak256(abi.encodePacked(
                msg.sender,
                tokens[tokens.length - 1],
                seed
            ));

        require(uint(hash) < difficulty,"difficulty");
        require(msg.value == cost,"cost");

        hash = keccak256(abi.encodePacked(hash,block.timestamp));

        _mint(tokenId,msg.sender,hash);

        emit Mine(tokenId, hash, msg.sender, block.number);
    }

    function _withdrawEth(uint tokenId) private returns(uint){
        require(msg.sender == ownerOf(tokenId),"ownerOf");

        uint amount = _getEthContained(tokenId);

        require(amount > 0,"Nothing to withdraw");

        uint to = tokens.length;

        tokenWithdrawn[tokenId] = to;

        emit WithdrawEth(tokenId,amount,to);

        return amount;
    }

    function withdrawPrize() public{
        uint winningToken = tokens.length;
        require(mergeHasHappened(),"Merge hasn't happened yet");
        require(msg.sender == ownerOf(winningToken),"You didn't win");
        require(!winnerHasWithdrawn,"You have already withdrawn");

        uint amount = (tokens.length ) * PRIZE_FEE;

        _burn(winningToken);

        winnerHasWithdrawn = true;

        payable(msg.sender).transfer(amount);

        emit WithdrawPrize();

    }

    function withdrawEth(uint tokenId) public{
        uint amount = _withdrawEth(tokenId);
        payable(msg.sender).transfer(amount);
    }

    function withdrawEthMultiple(uint[] calldata tokenIds) public{
        require(tokenIds.length > 0,"tokenIds");
        uint amount;
        for(uint i = 0; i < tokenIds.length; i++){
            amount +=  _withdrawEth(tokenIds[i]);
        }
        payable(msg.sender).transfer(amount);
    }


    function hashOf(uint _tokenId) public view returns(bytes32){
        require(isValidToken(_tokenId),"invalid");
        return tokens[_tokenId - 1];
    }
    function getEthContained(uint _tokenId) public view returns(uint){
        require(isValidToken(_tokenId),"invalid");

        return _getEthContained(_tokenId);
    }
    function _getEthContained(uint _tokenId) private view returns(uint){
        uint from;
        if(tokenWithdrawn[_tokenId] > 0){
            from = tokenWithdrawn[_tokenId];
        }else{
            from = _tokenId;
        }
        uint to = tokens.length;

        return (to - from) * BASE_COST;
    }

    function getLastHash() public view returns(bytes32){
        return tokens[tokens.length - 1];
    }
    function getMiningState() public view returns(bytes32 _hash, uint _supply,uint blockNumber){
        return (tokens[tokens.length - 1], totalSupply(), block.number);
    }

    function burn(uint tokenId) public{
        require(mergeHasHappened() && winnerHasWithdrawn,"The game isn't over");
        require(ownerOf(tokenId) == msg.sender);

        if(getEthContained(tokenId) > 0){
            withdrawEth(tokenId);
        }

        _burn(tokenId);
    }
    function burnMultiple(uint[] calldata tokenIds) public{
        require(mergeHasHappened() && winnerHasWithdrawn,"The game isn't over");

        require(tokenIds.length > 0,"tokenIds");
        uint amount;
        for(uint i = 0; i < tokenIds.length; i++){
            require(ownerOf(tokenIds[i]) == msg.sender);

            if(getEthContained(tokenIds[i]) > 0){
                amount +=  _withdrawEth(tokenIds[i]);
            }
            _burn(tokenIds[i]);
        }
        payable(msg.sender).transfer(amount);
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
    string public name = "Miners of the Merge";
    string public symbol = "MERGE";

    address private __metadata;


    address constant VB = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

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

        burnCount++;

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


    function tokenURI(uint _tokenId) public view returns (string memory){
        return IMetadata(__metadata).tokenURI(_tokenId,hashOf(_tokenId));
    }


    function totalSupply() public view returns (uint256){
        return tokens.length - burnCount;
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

        uint start  = ownerWithdrawn;

        uint end = tokens.length - 1;
        uint n = (end - start) + 1;

        uint sum = n * (start + end)/2;

        uint toWithdraw = (sum * BASE_COST + (n) * PRIZE_FEE) * CREATOR_FEE_PERCENT / 100;

        require(toWithdraw > 0,"withdrawn");

        ownerWithdrawn = tokens.length;

        payable(msg.sender).transfer(toWithdraw);

    }
}