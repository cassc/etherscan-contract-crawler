pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

//  __   __  _______  ___      __   __  _______  _______  _______  ___     
//  |  | |  ||       ||   |    |  | |  ||       ||       ||       ||   |    
//  |  | |  ||    ___||   |    |  |_|  ||    _  ||   _   ||   _   ||   |    
//  |  |_|  ||   | __ |   |    |       ||   |_| ||  | |  ||  | |  ||   |    
//  |       ||   ||  ||   |___ |_     _||    ___||  |_|  ||  |_|  ||   |___ 
//  |       ||   |_| ||       |  |   |  |   |    |       ||       ||       |
//  |_______||_______||_______|  |___|  |___|    |_______||_______||_______|

// This version has been simplified + is not upgradable.
             
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface NFTContract {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function name() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract UglyPool is IERC721Receiver, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct pool {
        IERC721 registry; // NFT contract address
        address owner; // Pool owner
        uint256 fee; // Fee to swap
        uint256 balance; // Balance from fees of this pool
    }

    pool[] public pools; // all pools
    mapping(uint => EnumerableSet.UintSet) tokenIds; // map pool id to set of tokenIds
    uint public contractFee;  // percent of pool fees 
    address private contractFeePayee; // this contract owner

    event CreatedPool(    uint indexed poolId, address indexed sender);
    event PoolFee(         uint indexed poolId, uint256 newFee, address indexed sender);
    event DepositNFT(      uint indexed poolId, uint256 tokenId, address indexed sender);
    event WithdrawNFT(     uint indexed poolId, uint256 tokenId, address indexed sender);
    event DepositEth(      uint indexed poolId, uint amount, address indexed sender);
    event WithdrawEth(     uint indexed poolId, uint amount, address indexed sender);
    event TradeExecuted(  uint indexed poolId, address indexed user, uint256 inTokenId, uint256 outTokenId);

    constructor(){
        uint[] memory emptyArray;
        createPool(IERC721(0x0000000000000000000000000000000000000000),emptyArray, 0);         // set pools[0] to nothing
        contractFeePayee = msg.sender;
        contractFee = 10;
    }

// Create Pool

    function createPool(IERC721 _registry, uint[] memory _tokenIds, uint _fee) public whenNotPaused { 
        pool memory _pool = pool({
            registry : _registry,
            owner : msg.sender,
            fee : _fee, 
            balance : 0
        });
        uint _poolId = pools.length;
        pools.push(_pool);
        emit CreatedPool(_poolId, msg.sender);
        for (uint i; i < _tokenIds.length; i++){
            tokenIds[_poolId].add(_tokenIds[i]); 
            _registry.safeTransferFrom(msg.sender,  address(this), _tokenIds[i]);
            emit DepositNFT(_poolId, _tokenIds[i], msg.sender);
        }
    }

// Deposits

    function depositNFTs(uint _poolId, uint[] memory _tokenIds) public payable whenNotPaused { 
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        for (uint i; i < _tokenIds.length; i++){
            pools[_poolId].registry.safeTransferFrom(msg.sender,  address(this), _tokenIds[i]);
            tokenIds[_poolId].add(_tokenIds[i]);
            emit DepositNFT(_poolId, _tokenIds[i], msg.sender);
        }
    }

// Swap

    function swapSelectedUgly(uint _poolId, uint _idFromPool, uint _idToPool) public payable whenNotPaused { 
        require(tokenIds[_poolId].length() > 0, "Nothing in pool.");
        require(msg.value >= pools[_poolId].fee, "Not enough ETH to pay fee");
        pools[_poolId].registry.safeTransferFrom(msg.sender,  address(this), _idFromPool);
        pools[_poolId].registry.safeTransferFrom( address(this), msg.sender, _idToPool);
        uint _contractFee = msg.value * contractFee / 100;         // Take % for contractRoyaltyPayee
        pools[_poolId].balance += msg.value - _contractFee;
        tokenIds[_poolId].remove(_idToPool);
        tokenIds[_poolId].add(_idFromPool);
        Address.sendValue(payable(contractFeePayee), _contractFee);
        emit TradeExecuted(_poolId, msg.sender, _idFromPool, _idToPool); 
    }

// Withdrawals

    function withdrawPoolNFTs(uint _poolId, uint[] memory _ids) public whenNotPaused { 
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        for (uint i;i < _ids.length;i++){
            require (tokenIds[_poolId].contains(_ids[i]), "NFT is not in your pool.");
           pools[_poolId].registry.safeTransferFrom( address(this), msg.sender, _ids[i]);
           tokenIds[_poolId].remove(_ids[i]);
           emit WithdrawNFT(_poolId, _ids[i], msg.sender);
        }
    }

    function withdrawPoolBalance(uint _poolId) public whenNotPaused { 
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        require(pools[_poolId].balance > 0, "There are no fees to withdraw.");
        uint256 balance = pools[_poolId].balance;
        pools[_poolId].balance = 0;
        Address.sendValue(payable(msg.sender), balance);
    }

// Setters 

    function setPoolFee(uint _poolId, uint _newFee) public {
        require(pools[_poolId].owner == msg.sender, "Not the owner of pool");
        pools[_poolId].fee = _newFee;
    }    

// Contract Owner Functions

    function setContractFee(uint _percentage) public onlyOwner {
        contractFee = _percentage;
    }

    function setContractFeePayee(address _address) public onlyOwner {
        contractFeePayee = _address;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

// View Functions

    function getPoolNFTIds(uint _poolId) public view returns (uint[] memory){  
        return tokenIds[_poolId].values();
    }

    function poolIdsByOwner(address _owner) public view returns (uint256[] memory) {
        uint poolCount = 0;
        uint[] memory _ids = new uint[](numPoolsByOwner(_owner));
         for (uint i = 0; i < pools.length; i++){
            if (pools[i].owner == _owner){
                _ids[poolCount] = i;
                poolCount++;
            }
        }       
        return _ids;
    }

    function numPoolsByOwner(address _owner) private view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < pools.length; i++){
            if (pools[i].owner == _owner)
                count++;
        }
        return count;
    }

    function numPools() public view returns (uint) {
        return pools.length;
    }

// View Functions (Balances)

   function poolBalance(uint _poolId) public view returns (uint) { 
        return pools[_poolId].balance;
    }

   function poolFee(uint _poolId) public view returns (uint) { 
        return pools[_poolId].fee;
    }

    function poolNFTBalance(uint _poolId) public view returns (uint) { 
        return tokenIds[_poolId].length();
    }

// Misc

    function onERC721Received( address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

// Proxy Methods

    function allNFTsByAddress(address _wallet, address _registry) public view returns(uint[] memory){
        uint[] memory nfts = new uint[](balanceOfNFTs(_wallet, _registry));
        for (uint i = 0; i < nfts.length;i++){
            nfts[i] = tokenOfOwnerByIndex(_wallet, i, _registry);
        }
        return nfts;
    }

    // All NFTs in collection owned by wallet address
    function balanceOfNFTs(address _address, address _registry) private view returns (uint) {
        return NFTContract(_registry).balanceOf(_address);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index, address _registry) private view returns (uint256) {
        return NFTContract(_registry).tokenOfOwnerByIndex(_owner,_index);
    }

    function registryName(address _registry) public view returns (string memory){
        return NFTContract(_registry).name();
    }

    function tokenURI(address _registry, uint256 tokenId) public view returns (string memory){
        return NFTContract(_registry).tokenURI(tokenId);
    }

}