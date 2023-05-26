// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IShowBiz {
    function mint(address to, uint256 amount) external;
}

contract DHStakingV2 is Ownable, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    
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
        uint[] availablePeriods;
        uint[] monthlyRewards;
    }
    
    mapping(address => mapping(uint => StakedToken)) public tokenIdToStakedToken;
    mapping(address => mapping(uint => uint)) public tokenIdToClaimedRewards;
    mapping(address => mapping(address => EnumerableSet.UintSet)) addressToStakedTokensSet;
        
    mapping(address => PartnerContract) public contracts;

    uint public totalClaimedRewards;
    
    EnumerableSet.AddressSet activeContracts;
    
    event Stake(address contractAddress, uint contractTokenId, address owner, uint endsAt);
    event Unstake(address contractAddress, uint contractTokenId, address owner);
    event ClaimTokenRewards(address contractAddress, uint contractTokenId, address owner, uint rewards);
    
    function onERC721Received(address _operator, address, uint256, bytes calldata) external view override returns(bytes4) {
        require(_operator == address(this), "token must be staked over stake method");
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
        
        tokenIdToStakedToken[contractAddress][tokenId] = StakedToken({
            tokenId: tokenId,
            stakedAt: block.timestamp,
            endsAt: endsAt,
            monthlyRewards: monthlyRewards,
            months: months,
            owner: msg.sender
        });
        
        tokenIdToClaimedRewards[contractAddress][tokenId] = 0;
        _contract.instance.safeTransferFrom(msg.sender, address(this), tokenId);
        addressToStakedTokensSet[contractAddress][msg.sender].add(tokenId);
        
        emit Stake(contractAddress, tokenId, msg.sender, endsAt);   
    }

    function renewStake(address contractAddress, uint[] memory tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            StakedToken storage stakedToken = tokenIdToStakedToken[contractAddress][tokenIds[i]];
            require(stakedToken.owner != msg.sender, "caller does not have this token");
            stakedToken.endsAt = block.timestamp + stakedToken.months * 28 days;
        }
    }
    
    function stakeBatch(address contractAddress, uint[] calldata tokenIds, uint months) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            stake(contractAddress, tokenIds[i], months);
        }
    }
    
    function unclaimedRewards(address contractAddress, uint tokenId) public view returns (uint) {
        StakedToken storage stakedToken = tokenIdToStakedToken[contractAddress][tokenId];
        require(stakedToken.owner != address(0), "cannot query an unstaked token");
        
        uint rewardLimit = (stakedToken.endsAt - stakedToken.stakedAt) / 7 days;
        uint rewardsUntilNow = (block.timestamp - stakedToken.stakedAt) / 7 days;
        return (rewardsUntilNow > rewardLimit ? rewardLimit : rewardsUntilNow)
            * stakedToken.monthlyRewards / 4 - tokenIdToClaimedRewards[contractAddress][tokenId];
    }
    
    function claimTokenRewards(address contractAddress, uint tokenId) public {
        StakedToken storage stakedToken = tokenIdToStakedToken[contractAddress][tokenId];
        require(stakedToken.owner == msg.sender, "caller did not stake this token");
        
        uint _unclaimedRewards = unclaimedRewards(contractAddress, tokenId);
        
        if (_unclaimedRewards > 0) {
            _showBiz.mint(msg.sender, _unclaimedRewards);
            tokenIdToClaimedRewards[contractAddress][tokenId] += _unclaimedRewards;
            totalClaimedRewards += _unclaimedRewards;
            emit ClaimTokenRewards(contractAddress, tokenId, msg.sender, _unclaimedRewards);
        }
    }
    
    function claimContractRewards(address contractAddress) public {
        EnumerableSet.UintSet storage stakedTokens = addressToStakedTokensSet[contractAddress][msg.sender];
        uint totalStakedTokens = stakedTokens.length();

        for (uint i = 0; i < totalStakedTokens; i++) {
            claimTokenRewards(contractAddress, stakedTokens.at(i));
        }
    }
    
    function claimRewards() public {
        for (uint i = 0; i < activeContracts.length(); i++) {
            claimContractRewards(activeContracts.at(i));
        }
    }
    
    function unstake(address contractAddress, uint tokenId) public {
        PartnerContract storage _contract = contracts[contractAddress];
        StakedToken storage stakedToken = tokenIdToStakedToken[contractAddress][tokenId];
        require(stakedToken.owner == msg.sender, "caller not owns this token");
        require(block.timestamp > stakedToken.endsAt, "staked period did not finish yet");
        
        claimTokenRewards(contractAddress, tokenId);
        
        _contract.instance.safeTransferFrom(address(this), msg.sender, stakedToken.tokenId);
        
        addressToStakedTokensSet[contractAddress][msg.sender].remove(stakedToken.tokenId);
        
        emit Unstake(contractAddress, stakedToken.tokenId, msg.sender);
        
        delete tokenIdToStakedToken[contractAddress][tokenId];
    }
    
    function unstakeBatch(address contractAddress, uint[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            unstake(contractAddress, tokenIds[i]);
        }
    }

    function stakedTokensOfOwner(address contractAddress, address accountAddress) external view returns (uint[] memory tokenIds) {
        EnumerableSet.UintSet storage stakedTokens = addressToStakedTokensSet[contractAddress][accountAddress];
        tokenIds = new uint[](stakedTokens.length());
        
        for (uint i = 0; i < stakedTokens.length(); i++) {
            tokenIds[i] = stakedTokens.at(i);
        }

        return tokenIds;
    }
    
    function addContract(address contractAddress, uint[] memory availablePeriods, uint[] memory monthlyRewards) public onlyOwner {
        contracts[contractAddress] = PartnerContract(
            true,
            IERC721(contractAddress),
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
}