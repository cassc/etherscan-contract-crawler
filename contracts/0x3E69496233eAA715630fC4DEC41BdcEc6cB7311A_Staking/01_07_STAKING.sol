// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    uint256 public NFT_BASE_RATE = 1000000000000000000; // 1 per day

    address public NFT_ADDRESS; //NFT Collection Address
    address public TOKEN_ADDRESS;

    bool public stakingLive = false;
    bool public locked = false;

    mapping(uint256 => uint256) internal NftTimeStaked;
    mapping(uint256 => address) internal NftToStaker;
    mapping(address => uint256[]) internal StakerToNft;

    mapping(uint256 => uint256) private NftToType;
    mapping(address => uint256) public claimable;

    uint256 type1Multiplier = 3;
    uint256 type2Multiplier = 5;
    uint256 type3Multiplier = 5;

    event ClaimVirtual(address indexed staker, uint256 amount);

    IERC721Enumerable private nft;

    constructor(address nft_address, address token_address) {
        if (token_address != address(0)) {
            TOKEN_ADDRESS = token_address;
        }
        NFT_ADDRESS = nft_address;
        nft = IERC721Enumerable(NFT_ADDRESS);
    }

    function getTokenIDsStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return StakerToNft[staker];
    }

    function stakeCount() public view returns (uint256) {
        return nft.balanceOf(address(this));
    }

    function removeIdFromArray(uint256[] storage arr, uint256 tokenId)
        internal
    {
        uint256 length = arr.length;
        for (uint256 i = 0; i < length; i++) {
            if (arr[i] == tokenId) {
                length--;
                if (i < length) {
                    arr[i] = arr[length];
                }
                arr.pop();
                break;
            }
        }
    }

    // covers single staking and multiple
    function stake(uint256[] calldata tokenIds) public {
        require(stakingLive, "Staking not Live!");
        uint256 id;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            id = tokenIds[i];
            require(
                nft.ownerOf(id) == msg.sender && NftToStaker[id] == address(0),
                "Token not owned by staker"
            );
            // set trait type to default if not set
            if (NftToType[id] == 0) {
                NftToType[id] = 1;
            }
            //NFT transfer
            nft.transferFrom(msg.sender, address(this), id);
            //Track data
            StakerToNft[msg.sender].push(id);
            NftTimeStaked[id] = block.timestamp;
            NftToStaker[id] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(
            StakerToNft[msg.sender].length > 0,
            "Need at least 1 staked to unstake"
        );
        uint256 total = 0;

        for (uint256 i = StakerToNft[msg.sender].length; i > 0; i--) {
            uint256 tokenId = StakerToNft[msg.sender][i - 1];

            nft.transferFrom(address(this), msg.sender, tokenId);
            //append calcuated field
            total += calculateRewardsByTokenId(tokenId);
            // count from end
            StakerToNft[msg.sender].pop();
            NftToStaker[tokenId] = address(0);
            // set total rewards to 0 , timestamp to 0
            NftTimeStaked[tokenId] = 0;
        }

        claimable[msg.sender] += total;
    }

    function unstake(uint256[] calldata tokenIds) public {
        uint256 total = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(NftToStaker[id] == msg.sender, "NOT the staker");

            nft.transferFrom(address(this), msg.sender, id);
            //append calcuated field
            total += calculateRewardsByTokenId(id);
            // remove specific id from array
            removeIdFromArray(StakerToNft[msg.sender], id);
            NftToStaker[id] = address(0);
            // set total rewards to 0 , timestamp to 0
            NftTimeStaked[id] = 0;
        }

        claimable[msg.sender] += total;
    }

    function claim(uint256 tokenId) external {
        require(NftToStaker[tokenId] == msg.sender, "NOT the staker");
        require(TOKEN_ADDRESS != address(0), "Token Withdraw disabled");
        //append calcuated field
        uint256 total = calculateRewardsByTokenId(tokenId);
        NftTimeStaked[tokenId] = block.timestamp;
        // add claimable
        if (claimable[msg.sender] > 0) {
            total += claimable[msg.sender];
            claimable[msg.sender] = 0;
        }
        IERC20(TOKEN_ADDRESS).transfer(msg.sender, total);
    }

    function claimAll() external {
        require(TOKEN_ADDRESS != address(0), "Token Withdraw disabled");
        uint256 total = 0;
        uint256[] memory TokenIds = StakerToNft[msg.sender];
        for (uint256 i = 0; i < TokenIds.length; i++) {
            uint256 id = TokenIds[i];
            require(NftToStaker[id] == msg.sender, "Sender not staker");
            //append calcuated field
            total += calculateRewardsByTokenId(id);
            NftTimeStaked[id] = block.timestamp;
        }
        // add claimable
        if (claimable[msg.sender] > 0) {
            total += claimable[msg.sender];
            claimable[msg.sender] = 0;
        }
        IERC20(TOKEN_ADDRESS).transfer(msg.sender, total);
    }

    // claims and burns all virtual tokens for shop use
    function claimVirtual() external {
        uint256 total = 0;
        uint256[] memory TokenIds = StakerToNft[msg.sender];
        for (uint256 i = 0; i < TokenIds.length; i++) {
            uint256 id = TokenIds[i];
            require(NftToStaker[id] == msg.sender, "Sender not staker");
            //append calcuated field
            total += calculateRewardsByTokenId(id);
            //set timestamp , set current rewards to 0
            NftTimeStaked[id] = block.timestamp;
        }
        // add claimable
        if (claimable[msg.sender] > 0) {
            total += claimable[msg.sender];
            claimable[msg.sender] = 0;
        }
        emit ClaimVirtual(msg.sender, total);
    }

    //maps token id to staker address
    function getNftStaker(uint256 tokenId) public view returns (address) {
        return NftToStaker[tokenId];
    }

    //return public is token id staked in contract
    function isStaked(uint256 tokenId) public view returns (bool) {
        return (NftToStaker[tokenId] != address(0));
    }

    function getType(uint256 tokenId) public view returns (uint256) {
        return NftToType[tokenId];
    }

    /* Calculate Reward functions */

    // calculate the rewards for a specific token id
    function calculateRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256 _rewards)
    {
        uint256 total = 0;
        // get the time staked for the token id
        uint256 tempRewards = (block.timestamp - NftTimeStaked[tokenId]);
        // calculate the rewards per time staked
        if (NftToType[tokenId] == 1) {
            tempRewards = (tempRewards * type1Multiplier);
        }
        if (NftToType[tokenId] == 2) {
            tempRewards = (tempRewards * type2Multiplier);
        }
        if (NftToType[tokenId] == 3) {
            tempRewards = (tempRewards * type3Multiplier);
        }
        // add the rewards to the total
        total += (((tempRewards * NFT_BASE_RATE) / 86400));
        return (total);
    }

    //total rewards for staker
    function getAllRewards(address staker) public view returns (uint256) {
        uint256 total = 0;
        uint256[] memory tokenIds = StakerToNft[staker];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //append calcuated field
            total += (calculateRewardsByTokenId(tokenIds[i]));
        }
        // add claimable
        total += claimable[staker];
        return total;
    }

    function getRewardsPerDay(uint256[] calldata tokenId)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < tokenId.length; i++) {
            if (NftToType[tokenId[i]] == 1) {
                total += type1Multiplier;
            }
            if (NftToType[tokenId[i]] == 2) {
                total += type2Multiplier;
            }
            if (NftToType[tokenId[i]] == 3) {
                total += type3Multiplier;
            }
        }
        return (total * (NFT_BASE_RATE / 1 ether));
    }

    /* Owner Functions */

    //set type list for specific token id
    function setTypeList(uint256 tokenId, uint256 typeNumber)
        external
        onlyOwner
    {
        NftToType[tokenId] = typeNumber;
    }

    // set full type list for specific token ids and override any previous type list
    function setFullTypeList(uint256[] calldata idList, uint256 typeNumber)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < idList.length; i++) {
            NftToType[idList[i]] = typeNumber;
        }
    }

    // set multiplier for specific token id
    function setTypeMultiplier(uint256 typeNumber, uint256 multiplier)
        external
        onlyOwner
    {
        if (typeNumber == 1) {
            type1Multiplier = multiplier;
        }
        if (typeNumber == 2) {
            type2Multiplier = multiplier;
        }
        if (typeNumber == 3) {
            type3Multiplier = multiplier;
        }
    }

    // set base rate
    function setBaseRate(uint256 baseRate) external onlyOwner {
        NFT_BASE_RATE = baseRate;
    }

    // set token address
    function setTokenAddress(address tokenAddress) external onlyOwner {
        TOKEN_ADDRESS = tokenAddress;
    }

    //unstake all tokens , used for emergency unstaking , requires deploying a new contract
    //  NftTimeStaked , NftToStaker ,  StakerToNft , nftStaked still defined
    function emergencyUnstake() external payable onlyOwner {
        require(locked == true, "lock is on");
        uint256 currSupply = nft.totalSupply();
        for (uint256 i = 0; i < currSupply; i++) {
            if (NftToStaker[i] != address(0)) {
                address sendAddress = NftToStaker[i];
                nft.transferFrom(address(this), sendAddress, i);
            }
        }
    }

    //return lock change
    function returnLockToggle() public onlyOwner {
        locked = !locked;
    }

    // activate staking
    function toggle() external onlyOwner {
        stakingLive = !stakingLive;
    }

    //withdraw amount of tokens or all tokens
    function withdraw(uint256 bal) external onlyOwner {
        uint256 balance = bal;
        if (balance == 0) {
            balance = IERC20(TOKEN_ADDRESS).balanceOf(address(this));
        }
        IERC20(TOKEN_ADDRESS).transfer(msg.sender, balance);
    }
}