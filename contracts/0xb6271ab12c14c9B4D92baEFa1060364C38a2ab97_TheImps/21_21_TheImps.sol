// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Manager.sol";
import "./BloodDiamond.sol";

contract TheImps is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private mintingCounter;
    string public provenance = "32d4be36b5234825722463c387684836a3bb0d2e65807228f85bdb4cbb807185";
    string private baseURI = "ipfs://Qmf4GrF8PwLURhtwYEUCF15udKFEocgiJM3PADgr8r4zbD/";
    string private myContractURI = "ipfs://QmNg6ZATbjzqEdxUKp5nhkNhbRRRjgyHUQnvpPrnDDNWs8/imps-contract";

    
    uint256 private seed;

    Manager manager;
    BloodDiamond bloodDiamond;


    mapping(uint256 => bool) reservedImps;
    mapping(uint256 => bool) staking;
    mapping(uint256 => uint256) stakingTime;
    mapping(uint256 => uint256) public updateTime;
    uint256 addition = 0;

    uint256 public maxSupply = 6666;
    uint256 unrevealTime = 1673640000;
    uint256[]  reserved = [3, 5, 44, 50, 51, 52, 53, 54, 55, 187, 213, 418, 555, 888, 1337, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 5555];

    constructor(address _managerAddress) ERC721("The Imps", "THEIMPS") {
        seed = block.timestamp;
        manager = Manager(_managerAddress);
    }


    function contractURI() public view returns (string memory) {
        return myContractURI;
    }

    function setContractURI(string memory _uri) external onlyOwner {
        myContractURI = _uri;
    }

    function setBaseURI(string memory _base) external onlyOwner {
        baseURI = _base;
    }

    function setUnrevealTime(uint256 _time) external onlyOwner{
        unrevealTime = _time;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

        function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        if (block.timestamp < unrevealTime) {
            return "ipfs://QmR9iJre1dDzx3oi9U5Ebw7Fzmk9SqAFUU2GsMTe5c1nEX/imps-unreveal";
        } else {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString())
                );
        }
    }

    function stakeImp(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Only Owner can Stake");
        staking[tokenId] = true;
        stakingTime[tokenId] = block.timestamp;
    }

    function stakingRewards(uint256 tokenId) public view returns (uint256) {
        if (staking[tokenId]) {
            uint256 current = block.timestamp;
            if (current - stakingTime[tokenId] > 0) {
                return (((current - stakingTime[tokenId]) / manager.minRewardingTime()) * 10**18) * 3;
            }
        }
        return 0;
    }

    function unStakeImp(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Only Owner can unstake");
        require(staking[tokenId], "Only staked imps can be unstaked");
        uint256 reward = stakingRewards(tokenId);
        staking[tokenId] = false;
        stakingTime[tokenId] = block.timestamp;
        if (reward > 0) {
            bloodDiamond.mint(reward, msg.sender);
        }
    }

    function _approve(address to, uint256 tokenId) internal virtual override {
        require(!staking[tokenId], "Staked Token can not be approved");
        super._approve(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    )  internal virtual override {
        require(!staking[firstTokenId], "Staked Token can not be transfered");
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        updateTime[firstTokenId] = block.timestamp;
    }



    function getId(uint256 current) public returns (uint256) {
        uint256 calculator = addition;
        for(uint i = 0; i < reserved.length; i++) {
            uint256 my = current + calculator;
            if(my == reserved[i]){
                calculator=calculator+1;
            }
        }
        addition = calculator;
        return current + addition;
    }

    function mint(address target) external {
        require(manager.isMinter(msg.sender), "You are not allowed to mint");
        require(
            canMintUnsaved(),
            "We are outmint"
        );
        mintingCounter.increment();
        uint256 myId = (mintingCounter.current() + seed) % 6666 + 1;
        uint256 nftID = getId(myId);
        _mint(target, nftID);
    }

    function canMintUnsaved() public returns(bool){
        return mintingCounter.current() < maxSupply - 28;
    }

    function mintSaved(address target, uint256 id) external {
        require(manager.isMinter(msg.sender), "You are not allowed to mint");
        require(!_exists(id), "Is minted before");
        require(isSavedId(id),
            "You try to mint a non reserved IMP"
        );
        _mint(target, id);
    }

    function isSavedId(uint256 id) public view returns(bool){
        for (uint i = 0; i < reserved.length; i++) {
            if(id == reserved[i]){
                return true;
            }
        }
        return false;
    }

    function burn(uint256 id) external {
        require(manager.isBurner(msg.sender), "You are not allowed to burn");
        _burn(id);
    }
}