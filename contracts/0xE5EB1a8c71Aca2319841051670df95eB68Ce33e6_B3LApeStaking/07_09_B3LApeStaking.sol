// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DashboardPair,DashboardStake} from "./structs/Structs.sol";
import {IERC721Minimal,IApeCoinStakingMinimal} from "./interfaces/Interfaces.sol";

contract B3LApeStaking is Ownable {
    using ECDSA for bytes32;

    uint private constant APE_COIN_PRECISION = 18;
    uint private MAX_APE_COIN_SINGLE_NFT_CAN_STAKE = 70  * (10 ** APE_COIN_PRECISION);
    // IERC20Minimal public immutable APE_COIN;
    // IApeCoinStakingMinimal public immutable APE_COIN_STAKING;
    IERC20 private immutable APE_COIN;
    IApeCoinStakingMinimal private immutable APE_COIN_STAKING;
    mapping(uint => uint) private claimedRewards;
    mapping(uint => uint) private stakedApeCoin;

    IERC721Minimal public immutable B3L;
    address private signer;




    event Staked(address indexed user, uint[] tokenIds, uint[] amounts);
    event Claim(address indexed user, uint[] tokenIds, uint[] amounts);

    constructor(address b3lAddress, address _signer, address ape_coin, address ape_coin_staking) {
        B3L = IERC721Minimal(b3lAddress);
        signer = _signer;
        APE_COIN = IERC20(ape_coin);
        APE_COIN_STAKING = IApeCoinStakingMinimal(ape_coin_staking);
    }

    //** STAKE FUNCTION **//
    function stakeApeCoin(uint[] calldata nftIds,uint expirationTimestamp,bytes calldata signature,uint[] calldata amounts) external {
        //Must own all the nftIds
        uint totalToStake;
        for(uint i = 0; i < nftIds.length; i++) {
            uint amount = amounts[i];
            require(B3L.ownerOf(nftIds[i]) == msg.sender, "You do not own this NFT");
            require(amount + stakedApeCoin[nftIds[i]] <= MAX_APE_COIN_SINGLE_NFT_CAN_STAKE, "You cannot stake more than 70 ApeCoin per NFT");
            stakedApeCoin[nftIds[i]] += amount;
            totalToStake += amount;
        }

        bytes32 hash = keccak256(abi.encodePacked(nftIds,expirationTimestamp,true));
        address signerAddress = hash.toEthSignedMessageHash().recover(signature);
        require(signerAddress == signer, "Invalid signature");
        if(block.timestamp > expirationTimestamp) revert("Signature expired");
        
        APE_COIN.transferFrom(msg.sender, address(this), totalToStake);
        // APE_COIN.approve(address(APE_COIN_STAKING), totalToStake);
        // APE_COIN_STAKING.depositSelfApeCoin(totalToStake);
        emit Staked(msg.sender, nftIds, amounts);

        
    }



    //** CLAIM REWARDS FUNCTION **//
    function claimRewards(uint[] calldata nftIds, uint[] calldata totalAmountsEarnedOverTimePerNFTIds,bytes calldata signature) external {
        bytes32 hash = keccak256(abi.encodePacked(nftIds,totalAmountsEarnedOverTimePerNFTIds,true));
        address signerAddress = hash.toEthSignedMessageHash().recover(signature);
        require(signerAddress == signer, "Invalid signature");
        uint totalAmountToClaim = 0;
        for(uint i = 0; i < nftIds.length; i++) {
            require(B3L.ownerOf(nftIds[i]) == msg.sender, "You do not own this NFT");
            uint amountToClaim = totalAmountsEarnedOverTimePerNFTIds[i] - claimedRewards[nftIds[i]];
            claimedRewards[nftIds[i]] += amountToClaim;
            totalAmountToClaim += amountToClaim;
        }
        APE_COIN.transfer(msg.sender, totalAmountToClaim);
        emit Claim(msg.sender, nftIds, totalAmountsEarnedOverTimePerNFTIds);
    }

    function withdrawAllApeAndClaimRewards(uint[] calldata nftIds, uint[] calldata totalAmountsEarnedOverTimePerNFTIds,bytes memory signature) external {
        bytes32 hash = keccak256(abi.encodePacked(nftIds,totalAmountsEarnedOverTimePerNFTIds,true));
        address signerAddress = hash.toEthSignedMessageHash().recover(signature);
        require(signerAddress == signer, "Invalid signature");
        uint totalAmountToClaim = 0;
        for(uint i = 0; i < nftIds.length; ++i) {
            require(B3L.ownerOf(nftIds[i]) == msg.sender, "You do not own this NFT");
            uint amountToClaim = totalAmountsEarnedOverTimePerNFTIds[i] - claimedRewards[nftIds[i]];
            claimedRewards[nftIds[i]] += amountToClaim;
            totalAmountToClaim += amountToClaim;
            totalAmountToClaim += stakedApeCoin[nftIds[i]];
            stakedApeCoin[nftIds[i]] = 0;
        }
        require(totalAmountToClaim > 0, "You have already claimed all your rewards");
        APE_COIN.transfer(msg.sender, totalAmountToClaim);
        emit Claim(msg.sender, nftIds, totalAmountsEarnedOverTimePerNFTIds);
    }

    
    
    

    //************ GETTERS ***************//
    function getClaimedRewardsForToken(uint tokenId) external view returns (uint) {
        return claimedRewards[tokenId];
    }

    function getBatchClaimedRewardsForTokens(uint[] calldata tokenIds) external view returns (uint[] memory) {
        uint[] memory claimedRewardsForTokens = new uint[](tokenIds.length);
        for(uint i = 0; i < tokenIds.length; i++) {
            claimedRewardsForTokens[i] = claimedRewards[tokenIds[i]];
        }
        return claimedRewardsForTokens;
    }
    function getStakedApeCoinForTokenId(uint tokenId) external view returns (uint) {
        return stakedApeCoin[tokenId];
    }

    function getBatchStakedApeCoinForTokenIds(uint[] calldata tokenIds) external view returns (uint[] memory) {
        uint[] memory stakedApeCoinForTokens = new uint[](tokenIds.length);
        for(uint i = 0; i < tokenIds.length; i++) {
            stakedApeCoinForTokens[i] = stakedApeCoin[tokenIds[i]];
        }
        return stakedApeCoinForTokens;
    }


    function getBatchAmountDeposited(uint[] calldata nftIds) external view returns (uint[] memory) {
        uint[] memory amountsDeposited = new uint[](nftIds.length);
        for(uint i = 0; i < nftIds.length; i++) {
            amountsDeposited[i] = stakedApeCoin[nftIds[i]];
        }
        return amountsDeposited;
    }




    //***************** SETTERS *****************//
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
    
    function setMaxApeCoinSingleNftCanStake(uint _maxApeCoinSingleNftCanStake) external onlyOwner {
        MAX_APE_COIN_SINGLE_NFT_CAN_STAKE = _maxApeCoinSingleNftCanStake;
    }

    //***************** GETTERS *****************//
    function getDashboardStake() public view returns (DashboardStake memory) {
        DashboardStake memory dashboardStake = APE_COIN_STAKING.getApeCoinStake(address(this));
        return dashboardStake;

    }
        function getApeCoinAmountDepositedAndUnclaimedSelf() internal view returns(uint,uint){
        DashboardStake memory dashboardStake = getDashboardStake();
        uint amountDeposited = dashboardStake.deposited;
        uint amountUnclaimed = dashboardStake.unclaimed;
        return (amountDeposited, amountUnclaimed);
    }
    

    function getPendingRewardsForContract() external view returns (uint256) {
        return APE_COIN_STAKING.pendingRewards(0, address(this), 0);
    }

    function getDepositAmountInApeCoinContract() external view returns (uint256) {
        return getDashboardStake().deposited;
    }

    //***************** ONLY OWNER METHODS *****************//
    function withdrawApeCoin(uint amount,address to) external onlyOwner {
        APE_COIN_STAKING.withdrawApeCoin(amount, to);
    }
    function stakeApeCoinSelf(uint amount) external onlyOwner {
        APE_COIN.approve(address(APE_COIN_STAKING), amount);
        APE_COIN_STAKING.depositSelfApeCoin(amount);
    }
    function sendApeCoinToApeCoinStaking(uint amount) external onlyOwner {
        APE_COIN.transferFrom(msg.sender, address(this), amount);
        APE_COIN.approve(address(APE_COIN_STAKING), amount);
        APE_COIN_STAKING.depositSelfApeCoin(amount);
    } 



    function claimAndRestakeOwnerOnly() external onlyOwner {
        DashboardStake memory dashboardStake = getDashboardStake();
        uint amountDeposited = dashboardStake.deposited;
        uint amountUnclaimed = dashboardStake.unclaimed;
        APE_COIN_STAKING.withdrawSelfApeCoin(amountDeposited);
        APE_COIN.approve(address(APE_COIN_STAKING), amountDeposited + amountUnclaimed);
        APE_COIN_STAKING.depositSelfApeCoin(amountDeposited + amountUnclaimed);
    }
    function emergencyWithdraw() external onlyOwner {
        DashboardStake memory dashboardStake = getDashboardStake();
        uint amountDeposited = dashboardStake.deposited;
        APE_COIN_STAKING.withdrawSelfApeCoin(amountDeposited);
    }
    function emergencyWithdrawAndSendToOwner() external onlyOwner {
        (uint amountDeposited,uint amountUnclaimed) = getApeCoinAmountDepositedAndUnclaimedSelf();
        APE_COIN_STAKING.withdrawSelfApeCoin(amountDeposited);
        uint balance = APE_COIN.balanceOf(address(this));
        APE_COIN.transfer(owner(),balance);
    }

    function emergencyWithdrawEverythingInside() external onlyOwner {
        uint balance = APE_COIN.balanceOf(address(this));
        APE_COIN.transfer(owner(),balance);
    }

    function fundApeCoinNoStake(uint amount) external onlyOwner {
        APE_COIN.transferFrom(msg.sender, address(this), amount);
    }
       
}