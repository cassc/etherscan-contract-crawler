pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

import "./ERC1155Receiver.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";


contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

interface ERC20 {
    function BurnCrab(uint256 amt) external;

    function StakeTokens(uint256 amt, address _referrer) external;

    function ClaimStakeInterest() external;

    function calcStakingRewards(address _user) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ContractEvents {
    //when user stakes nfts
    event NFTstake(address indexed user, uint256 value);

    //when user unstakes nfts
    event NFTunstake(address indexed user, uint256 value);

    //when a user distributes interest tokens
    event TokenDistribution(address indexed user, uint256 value);
    //when a user claims interest tokens
    event TokenClaim(address indexed user, uint256 value);

    //when contract stakes tokens
    event TokenStake(address indexed user, uint256 value);

    //when contract rolls tokens
    event TokenRoll(address indexed user, uint256 value);

    //when contract burns tokens
    event TokenBurn(address indexed user, uint256 value);
}

contract CrabStakingNFT is ContractEvents, ERC1155Holder {
    using SafeMath for uint256;

    bool private sync;

    //protects against potential reentrancy
    modifier synchronized() {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    // Contract deployer
    address dev;
    // The address of the CRAB contract.
    address crabContract = 0x24BCeC1AFda63E622a97F17cFf9a61FFCfd9b735; 
    //The address of the Genesis NFT contract.
    address nftContract = 0x45036a8C1234A2d42992688c5EAf83d2F7E3496A; 

    //Array of active stakers
    address[] public activeStakers; // Array count (max 32)
    // Mapping from user address to number of staked NFTs.
    mapping(address => uint256) public usersStakedNFTs;
    // Mapping from user to amount of interest available to claim.
    mapping(address => uint256) public stakerInterest;
    // Yield data
    uint256 public totalStakedNfts;
    uint256 public availableToBurn;
    uint256 public availableToRoll;

    constructor() {
        dev = msg.sender;
    }

    // Stakes an NFT.
    function StakeNFT(uint256 _nfts) external synchronized {
        // Ensure the contract has been approved to receive the NFT.
        require(
            IERC1155(nftContract).isApprovedForAll(msg.sender, address(this)),
            "Contract has not been approved to receive the NFT."
        );
        require(_nfts > 0, "Define amount of Genesis NFTs to stake");
        // Do not allow yield dist on first ever NFT stake.
        if (totalStakedNfts > 0) {
            distributeYield();
        }
        //Add user to active array if not already.
        if (usersStakedNFTs[msg.sender] == 0) {
            activeStakers.push(msg.sender);
        }
        // Increase value of total NFTs staked at current
        totalStakedNfts += _nfts;
        // Increase value of NFTs staked by user
        usersStakedNFTs[msg.sender] += _nfts;
        // Transfer the appropriate amount of NFTs to the contract.
        IERC1155(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            1,
            _nfts,
            ""
        );
        emit NFTstake(msg.sender, _nfts);
    }

    // Unstakes an NFT.
    function UnstakeNFT(uint256 _nfts) external synchronized {
        require(_nfts > 0, "Define amount of Genesis NFTs to unstake");
        // Ensure the caller cannot unstake NFTs they do not own.
        require(
            usersStakedNFTs[msg.sender] >= _nfts,
            "Input amount is larger than users staked NFTs."
        );
        distributeYield();
        // Decrease value of total NFTs staked at current
        totalStakedNfts -= _nfts;
        // Decrease value of NFTs staked by user
        usersStakedNFTs[msg.sender] -= _nfts;
        // Remove user from active staker array if NFT stake count 0.
        if (usersStakedNFTs[msg.sender] == 0) {
            for (uint256 i; i < activeStakers.length; i++) {
                // Find staker
                if (activeStakers[i] == msg.sender) {
                    // Remove staker
                    delete activeStakers[i];
                    removeElement(i);
                    break;
                }
            }
        }
        // Send the NFT/s to user
        IERC1155(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            1,
            _nfts,
            ""
        );
        if (stakerInterest[msg.sender] > 0) {
            claimYield();
        }
        emit NFTunstake(msg.sender, _nfts);
    }

    // Reset staker array
    function removeElement(uint256 index) internal {
        activeStakers[index] = activeStakers[activeStakers.length - 1];
        activeStakers.pop();
    }

    // Distributes the yield accrued from the NFT staking contract.
    function DistributeYield() external synchronized {
        distributeYield();
    }

    function distributeYield() internal {
        // Calculate the total yield.
        uint256 yield = ERC20(crabContract).calcStakingRewards(address(this));
        // Calculate distributions
        if (yield > 0) {
            uint256 distributable = yield.mul(85).div(100); //85% to stakers
            uint256 yieldPerNft = distributable.div(totalStakedNfts); //equal yield per Genesis NFT
            availableToBurn += yield.mul(10).div(100); //10% burn to raise NFT staking APY
            availableToRoll += yield.mul(5).div(100); //5% roll to compound stake while maintaining APY rise(add to stake)
            // Distribute the yield equally among all staked NFTs
            for (uint256 i = 0; i < activeStakers.length; i++) {
                stakerInterest[activeStakers[i]] += yieldPerNft.mul(
                    usersStakedNFTs[activeStakers[i]]
                );
            }
            ERC20(crabContract).ClaimStakeInterest();
            emit TokenDistribution(msg.sender, yield);
        }
    }

    //Claims the yield allocated for an individual user
    function ClaimYield() external synchronized {
        claimYield();
    }

    function claimYield() internal {
        uint256 yield = stakerInterest[msg.sender];
        stakerInterest[msg.sender] = 0;
        require(yield > 0, "Nothing to claim");
        ERC20(crabContract).transfer(msg.sender, yield);
        emit TokenClaim(msg.sender, yield);
    }

    //Adds CRAB from callers wallet to the NFT contract stake, also claims any interest
    function AddToStake(uint256 _amt) external synchronized {
        //send tokens from user wallet to NFT contract (approval needed)
        require(
            ERC20(crabContract).transferFrom(msg.sender, address(this), _amt)
        );
        distributeYield();
        //stake _amt to CRAB contract on behalf of NFT contract (dev is ref)
        ERC20(crabContract).StakeTokens(_amt, dev);
        emit TokenStake(msg.sender, _amt);
    }

    //Rolls allocated CRAB into the NFT contract stake
    function RollAllocated() external synchronized {
        uint256 toRoll = availableToRoll;
        require(availableToRoll > 0, "Nothing to roll");
        availableToRoll = 0;
        distributeYield();
        // Stake tokens to CRAB contract on behalf of NFT contract, also claims any interest (dev is ref)
        ERC20(crabContract).StakeTokens(toRoll, dev);
        emit TokenRoll(msg.sender, toRoll);
    }

    // Burn allocated CRAB on behalf of NFT contract to increase NFT staking APY
    function BurnAllocated() external synchronized {
         uint256 toBurn = availableToBurn;
        require(availableToBurn > 0, "Nothing to burn");
        availableToBurn = 0;
        distributeYield();
        ERC20(crabContract).BurnCrab(toBurn);
        emit TokenBurn(msg.sender, toBurn);
    }

    // Retrieves the staked NFTs for a given user.
    function getUserStakedNFTs(address _staker)
        external
        view
        returns (uint256)
    {
        return usersStakedNFTs[_staker];
    }
}
