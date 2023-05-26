// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./IShowBiz.sol";

contract DHStaking is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter _tokenIdCounter;
    
    IShowBiz _showBiz = IShowBiz(0x136209a516D1C2660F045e70634c9d95D64325F9);
    
    struct StakedToken {
        uint tokenId;
        uint stakedAt;
        uint endsAt;
        uint monthlyRewards;
        uint months;
        address owner;
    }
    
    struct PartnerContract {
        bool active;
        IERC721 instance;
        string baseURI;
        uint[] availablePeriods;
        uint[] monthlyRewards;
    }
    
    mapping(address => mapping(uint => StakedToken)) public localTokenIdToStakedToken;
    mapping(address => mapping(address => EnumerableSet.UintSet)) addressToStakedTokensSet;
    mapping(address => mapping(uint => uint)) public localTokenIdToClaimedRewards;
    mapping(address => mapping(uint => uint)) public tokenIdToLocalTokenId;
        
    mapping(address => PartnerContract) public contracts;
    mapping(uint => address) public localTokenIdToContract;
    uint public totalClaimedRewards;
    
    EnumerableSet.AddressSet activeContracts;
    
    event Stake(uint tokenId, address contractAddress, uint contractTokenId, address owner, uint endsAt);
    event Unstake(uint tokenId, address contractAddress, uint contractTokenId, address owner);
    event ClaimTokenRewards(uint tokenId, address owner, uint rewards);
    
    constructor() ERC721("Staked DeadHeads", "sDEAD") { }
    
    function onERC721Received(address operator, address, uint256, bytes calldata) external returns(bytes4) {
        require(operator == address(this), "token must be staked over stake method");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
    function stake(address contractAddress, uint tokenId, uint months) public {
        PartnerContract storage _contract = contracts[contractAddress];
        require(_contract.active, "token contract is not active");
        require(months >= 1, "invalid minimum period");
        
        uint endsAt = block.timestamp + months * 28 days;
        
        uint monthlyRewards = 0;
        
        for (uint i = 0; i < _contract.availablePeriods.length; i++) {
            if (_contract.availablePeriods[i] == months) {
                monthlyRewards = _contract.monthlyRewards[i];
            }
        }
        
        require(monthlyRewards != 0, "invalid stake period");
        
        localTokenIdToStakedToken[contractAddress][_tokenIdCounter.current()] = StakedToken({
            tokenId: tokenId,
            stakedAt: block.timestamp,
            endsAt: endsAt,
            monthlyRewards: monthlyRewards,
            months: months,
            owner: msg.sender
        });
        
        localTokenIdToClaimedRewards[contractAddress][tokenId] = 0;
        _contract.instance.safeTransferFrom(msg.sender, address(this), tokenId);
        addressToStakedTokensSet[contractAddress][msg.sender].add(tokenId);
        tokenIdToLocalTokenId[contractAddress][tokenId] = _tokenIdCounter.current();
        
        _mint(msg.sender, _tokenIdCounter.current());
        localTokenIdToContract[_tokenIdCounter.current()] = contractAddress;
        
        emit Stake(_tokenIdCounter.current(), contractAddress, tokenId, msg.sender, endsAt);
        
        _tokenIdCounter.increment();
    }
    
    function stakeBatch(address contractAddress, uint[] calldata tokenIds, uint months) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            stake(contractAddress, tokenIds[i], months);
        }
    }
    
    function unclaimedRewards(uint localTokenId) public view returns (uint) {
        address tokenContract = localTokenIdToContract[localTokenId];
        
        StakedToken storage stakedToken = localTokenIdToStakedToken[tokenContract][localTokenId];
        require(stakedToken.owner != address(0), "cannot query an unstaked token");
        
        uint rewardLimit = (stakedToken.endsAt - stakedToken.stakedAt) / 7 days;
        uint rewardsUntilNow = (block.timestamp - stakedToken.stakedAt) / 7 days;
        return (rewardsUntilNow > rewardLimit ? rewardLimit : rewardsUntilNow)
            * stakedToken.monthlyRewards / 4 - localTokenIdToClaimedRewards[tokenContract][localTokenId];
    }
    
    function claimTokenRewards(uint localTokenId) public {
        address tokenContract = localTokenIdToContract[localTokenId];
        StakedToken storage stakedToken = localTokenIdToStakedToken[tokenContract][localTokenId];
        require(stakedToken.owner == msg.sender, "caller did not stake this token");
        
        uint _unclaimedRewards = unclaimedRewards(localTokenId);
        
        if (_unclaimedRewards > 0) {
            _showBiz.mint(msg.sender, _unclaimedRewards);
            localTokenIdToClaimedRewards[tokenContract][localTokenId] += _unclaimedRewards;
            totalClaimedRewards += _unclaimedRewards;
            emit ClaimTokenRewards(localTokenId, msg.sender, _unclaimedRewards);
        }
    }
    
    function claimContractRewards(address contractAddress) public {
        EnumerableSet.UintSet storage stakedTokens = addressToStakedTokensSet[contractAddress][msg.sender];
        uint totalStakedTokens = stakedTokens.length();
        
        require(totalStakedTokens > 0, "caller does not have any staked token");
        
        for (uint i = 0; i < totalStakedTokens; i++) {
            claimTokenRewards(tokenIdToLocalTokenId[contractAddress][stakedTokens.at(i)]);
        }
    }
    
    function claimRewards() public {
        for (uint i = 0; i < activeContracts.length(); i++) {
            claimContractRewards(activeContracts.at(i));
        }
    }
    
    function unstake(uint localTokenId) public {
        require(_exists(localTokenId), "query for non existent token");
        address tokenContract = localTokenIdToContract[localTokenId];
        PartnerContract storage _contract = contracts[tokenContract];
        StakedToken storage stakedToken = localTokenIdToStakedToken[tokenContract][localTokenId];
        require(stakedToken.owner == msg.sender, "caller not owns this token");
        require(block.timestamp > stakedToken.endsAt, "staked period did not finish yet");
        
        claimTokenRewards(localTokenId);
        
        _contract.instance.safeTransferFrom(address(this), msg.sender, stakedToken.tokenId);
        
        addressToStakedTokensSet[tokenContract][msg.sender].remove(stakedToken.tokenId);
        
        _burn(localTokenId);
        
        emit Unstake(localTokenId, tokenContract, stakedToken.tokenId, msg.sender);
        
        delete localTokenIdToStakedToken[tokenContract][localTokenId];
    }
    
    function unstakeBatch(uint[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            unstake(tokenIds[i]);
        }
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 localTokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(localTokenId), "query for non existent token");
        address tokenContract = localTokenIdToContract[localTokenId];
        PartnerContract storage _contract = contracts[tokenContract];
        StakedToken storage token = localTokenIdToStakedToken[tokenContract][localTokenId];
        return string(abi.encodePacked(_contract.baseURI, token.tokenId.toString(), '?sa=', token.stakedAt.toString(), '&ra=', token.endsAt.toString()));
    }
    
    function addContract(address contractAddress, string memory baseURI, uint[] memory availablePeriods, uint[] memory monthlyRewards) public onlyOwner {
        contracts[contractAddress] = PartnerContract(
            true,
            IERC721(contractAddress),
            baseURI,
            availablePeriods,
            monthlyRewards
        );
        activeContracts.add(contractAddress);
    }
    
    function updateContract(address contractAddress, bool active, uint[] memory availablePeriods, uint[] memory monthlyRewards) public onlyOwner {
        require(activeContracts.contains(contractAddress), "contract not added");
        contracts[contractAddress].active = active;
        contracts[contractAddress].availablePeriods = availablePeriods;
        contracts[contractAddress].monthlyRewards = monthlyRewards;
    }
    
    function setBaseURI(address contractAddress, string memory baseURI) public onlyOwner {
        contracts[contractAddress].baseURI = baseURI;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        require(to == address(0) || from == address(0));
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function approve(address, uint256) public virtual override {
        revert();
    }
    
    function setApprovalForAll(address, bool) public virtual override {
        revert();   
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}