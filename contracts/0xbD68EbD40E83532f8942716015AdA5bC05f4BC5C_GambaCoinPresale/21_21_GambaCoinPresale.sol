// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./GambaCoin.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

// IUniswapV2Router01 constant UNISWAP_V2_ROUTER = IUniswapV2Router01(
//     UNISWAP_V2_ROUTER_ADDRESS
// );

/**
 * @title Gamba Coin Presale
 * @author @gambacoin: https://twitter.com/gambacoin
 * @notice Total Supply: 777,777,777
 */
contract GambaCoinPresale is Ownable {
    GambaCoin public gambaCoin;

    address public constant UNISWAP_V2_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 private _totalContribution;
    uint256 public finalizedOnBlock;

    bytes32 public whitelistMerkleRoot;
    uint256 public whitelistStartTime;
    uint256 public publicStartTime;

    uint256 public vestingPeriod = 50400; // blocks

    uint256 public constant PRESALE_HARD_CAP = 150 ether;
    uint256 public constant MAX_INDIVIDUAL_CONTRIBUTION = 0.5 ether;
    uint256 public constant LIQUIDITY_ALLOCATION = 388_888_888 ether; // 50% of total supply
    uint256 public constant PRESALE_ALLOCATION = 233_333_333 ether; // 30% of total supply

    struct Contribution {
        uint256 amount;
        uint256 claimed;
    }

    mapping(address => Contribution) public contributions;

    function updatePresaleSettings(
        bytes32 whitelistMerkleRoot_,
        uint256 whitelistStartTime_,
        uint256 publicStartTime_,
        uint256 vestingPeriod_
    ) external onlyOwner {
        whitelistMerkleRoot = whitelistMerkleRoot_;
        whitelistStartTime = whitelistStartTime_;
        publicStartTime = publicStartTime_;
        vestingPeriod = vestingPeriod_;
    }

    function setGambaCoin(address gambaCoin_) external onlyOwner {
        gambaCoin = GambaCoin(gambaCoin_);
    }

    function finalize() external payable onlyOwner {
        _totalContribution = address(this).balance;
        finalizedOnBlock = block.number;

        gambaCoin.approve(UNISWAP_V2_ROUTER_ADDRESS, type(uint256).max);

        // 223/1000 = 22.3%
        (bool success, ) = owner().call{
            value: (_totalContribution * 223) / 1000
        }("");

        require(success, "Presale: failed to transfer funds");

        IUniswapV2Router01(UNISWAP_V2_ROUTER_ADDRESS).addLiquidityETH{
            value: address(this).balance
        }(
            address(gambaCoin),
            LIQUIDITY_ALLOCATION,
            0,
            0,
            msg.sender,
            block.timestamp + 30 minutes
        );
    }

    function contribute() external payable {
        require(publicStartTime > 0, "Presale: not started");
        require(block.timestamp >= publicStartTime, "Presale: paused");
        _contribute(msg.sender, msg.value);
    }

    function contributeWhitelist(bytes32[] calldata proof) external payable {
        require(whitelistStartTime > 0, "Presale: not started");
        require(
            block.timestamp >= whitelistStartTime,
            "Presale: not in whitelist phase"
        );

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(
            MerkleProof.verify(proof, whitelistMerkleRoot, leaf),
            "Presale: Invalid proof"
        );

        _contribute(msg.sender, msg.value);
    }

    function _contribute(address account, uint256 amount) internal {
        require(
            contributions[account].amount + amount <=
                MAX_INDIVIDUAL_CONTRIBUTION,
            "Presale: max contribution exceeded"
        );

        require(
            address(this).balance <= PRESALE_HARD_CAP,
            "Presale: hardcap exceeded"
        );

        contributions[account].amount += amount;
    }

    function getTotalContribution() public view returns (uint256) {
        return
            finalizedOnBlock > 0 ? _totalContribution : address(this).balance;
    }

    function getContribution(address account) public view returns (uint256) {
        return contributions[account].amount;
    }

    function getClaimed(address account) external view returns (uint256) {
        return contributions[account].claimed;
    }

    function getClaimableShares(
        address account
    ) public view returns (uint256 claimable) {
        if (finalizedOnBlock == 0) return 0;
        uint256 blocksElapsed = block.number - finalizedOnBlock;

        if (blocksElapsed > vestingPeriod) {
            return getContribution(account);
        }

        claimable = getContribution(account) * 3; // initial 30 %
        claimable +=
            (getContribution(account) * 7 * blocksElapsed) /
            vestingPeriod; // vested 70 %

        claimable = claimable / 10; // 10 = 3 + 7 divisor
    }

    function getClaimableGamba(
        address account
    ) external view returns (uint256 gambaAmount) {
        if (finalizedOnBlock == 0) return 0;
        uint256 claimableShares = getClaimableShares(account);
        uint256 unclaimedShares = claimableShares -
            contributions[account].claimed;
        gambaAmount =
            (unclaimedShares * PRESALE_ALLOCATION) /
            getTotalContribution();
    }

    function claim() external {
        require(finalizedOnBlock > 0, "Presale: not finalized");
        uint256 claimableShares = getClaimableShares(msg.sender);

        uint256 prevClaimed = contributions[msg.sender].claimed;
        contributions[msg.sender].claimed = claimableShares;
        uint256 unclaimedShares = claimableShares - prevClaimed;
        uint256 gambaAmount = (unclaimedShares * PRESALE_ALLOCATION) /
            getTotalContribution();

        gambaCoin.transfer(msg.sender, gambaAmount);
    }
}