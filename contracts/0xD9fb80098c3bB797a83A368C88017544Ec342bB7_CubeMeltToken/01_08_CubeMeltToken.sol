pragma solidity ^0.8.4;

interface IIP {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external returns (bool);
}

pragma solidity ^0.8.4;

interface ICM {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CubeMeltToken is ERC20, Ownable, Pausable, ERC20Burnable {

    uint256 public maxSupply = 5000000 * 10 ** 18;

    IIP public ipContract = IIP(0xc547542A21124803019928e6cd26a847431F9bd6);
    ICM public cmContract = ICM(0x1963F1F1d1a6E094628C86CA3347e9185a6df056);
    bool public nftRewardsActive = true;
    uint256 public weeklyRewardAmount = 10 * 10 ** 18;
    uint256[] public rateList = [100, 120, 150, 200];

    uint256 public claimTimestamp = 1664467200;
    mapping(uint256 => uint256) public tokenClaimTimestamp;

    address public t1 = 0x2283BF4705A9D4E850a4C8dEF2aAe9Ac98F4c495;
    
    constructor() ERC20("CubeMelt Token", "CMT") {
        _mint(msg.sender, 100000 * 10 ** 18);
    }

    event ItemPurchased(address indexed user, uint256 itemSKU, uint256 price);

    event UserClaimedNftRewards(address indexed user, uint256[] cmIds, uint256[] ipIds, uint256 tokens);

    function mint(address to, uint256 amount) internal {
        _mint(to, amount);
    }

    function claimNFTRewards(uint256[] calldata _cmIds, uint256[] calldata _ipIds) external whenNotPaused {
        require(nftRewardsActive, "NFT rewards not active");
        require(_cmIds.length > 0, "No NFT input");

        uint256 totalRewards = 0;

        for (uint256 i = 0; i < _cmIds.length; i++) {
            uint256 cmId = _cmIds[i];
            require(cmContract.ownerOf(cmId) == msg.sender, "Not owner of the cm");
            
            uint256 timestamp = tokenClaimTimestamp[cmId];

            if(timestamp == 0) {
                timestamp = claimTimestamp;
            }

            uint256 reward = 0;
            uint256 difference = (block.timestamp - timestamp) / 1 weeks;
            reward = weeklyRewardAmount * difference;
            
            uint256 timestampDifference = difference * 1 weeks;
            uint256 newTimestamp = timestamp + timestampDifference;

            tokenClaimTimestamp[cmId] = newTimestamp;
            totalRewards += reward;
        }

        if(_ipIds.length != 0) {

            for(uint256 i = 0; i < _ipIds.length; i++)
            {
                uint256 ipId = _ipIds[i];
                require(ipContract.ownerOf(ipId) == msg.sender, "Not owner of the ip");
            }

            uint256 rate = rateList[0];

            if(_ipIds.length == 1) {
                rate = rateList[1];
            } else if(_ipIds.length == 2) {
                rate = rateList[2];
            } else if(_ipIds.length >= 3) {
                rate = rateList[3];
            }

            totalRewards = totalRewards * rate / 100;
        }

        require(totalRewards > 0, "No token to be claim");
        require(totalSupply() + totalRewards <= maxSupply, "Out of token supply");
        _mint(msg.sender, totalRewards);
        emit UserClaimedNftRewards(msg.sender, _cmIds, _ipIds, totalRewards);
    }

    function calculateNFTReward(uint256 _nftIndex) public view returns (uint256)  {
        uint256 timestamp = tokenClaimTimestamp[_nftIndex];

        if(timestamp == 0) {
            timestamp = claimTimestamp;
        }

        uint256 reward = 0;
        
        reward = weeklyRewardAmount * ((block.timestamp - timestamp) / 1 weeks);
        
        return reward;
    }

    function purchaseItem(uint256 _itemSKU, uint256 _amount) public whenNotPaused {
        require(balanceOf(msg.sender) >= _amount, "Not enough tokens.");
        transfer(t1, _amount);
        emit ItemPurchased(msg.sender, _itemSKU, _amount);
    }

    function purchaseItemUsingBurn(uint256 _itemSKU, uint256 _amount) public whenNotPaused {
        require(balanceOf(msg.sender) >= _amount, "Not enough tokens.");
        _burn(msg.sender, _amount);
        emit ItemPurchased(msg.sender, _itemSKU, _amount);
    }

///// ONLY OWNER
    function toggleNftRewards() public onlyOwner {
        nftRewardsActive = !nftRewardsActive;
    }

    function updateNftRewardAmount(uint256 _amount) public onlyOwner {
        weeklyRewardAmount = _amount * 10 ** 18;
    }

    function changeCMContractAddress(address _cmContractAddress) public onlyOwner {
        cmContract = ICM(_cmContractAddress);
    }

    function changeIPContractAddress(address _ipContractAddress) public onlyOwner {
        ipContract = IIP(_ipContractAddress);
    }

    function changeTokenClaimTimestamp(uint256[] calldata _index, uint256[] calldata _timestamp) external onlyOwner {
        for(uint256 i = 0; i < _index.length; i++) {
            tokenClaimTimestamp[_index[i]] = _timestamp[i];
        }
    }

    function setRangeOfTokenClaimTimestamp(uint256 _start, uint256 _end, uint256 _timestamp) external onlyOwner {
        for(uint256 i = _start; i <= _end; i++) {
            tokenClaimTimestamp[i] = _timestamp;
        }
    }

    function changeInitialClaimTimestamp(uint256 _timestamp) external onlyOwner {
        claimTimestamp = _timestamp;
    }

    function changeMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(maxSupply >= totalSupply(), "Must be more than or equal total supply.");
        require(maxSupply <= 20000000, "Cannot be more than or equal 20,000,000.");

        maxSupply = _maxSupply * 10 ** 18;
    }

    function changeRatePercentage(uint256[] calldata _rate) external onlyOwner {
        rateList = _rate;
    }

    function changeTreasuryWallet(address _t1) public onlyOwner {
        t1 = _t1;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function burn(uint256 _amount) public onlyOwner override(ERC20Burnable) {
        require(balanceOf(msg.sender) >= _amount, "Not enough tokens.");
        _burn(msg.sender, _amount);
    }

    function burnFrom(address _from, uint256 _amount) public onlyOwner override(ERC20Burnable) {
        require(balanceOf(_from) >= _amount, "Not enough tokens.");
        _burn(_from, _amount);
    }
}