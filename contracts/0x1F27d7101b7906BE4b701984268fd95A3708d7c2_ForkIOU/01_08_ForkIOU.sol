// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Mintable.sol";

/// @title ForkIOU
/// @author D3Y3R, Kyoko Kirigiri
/// @notice Contract to issue ether and ETHW IOUs to enable liquidity for ETHW on mainnet pre-merge
contract ForkIOU is Ownable, ReentrancyGuard {
    /// @notice Difficulty threshold < 2**64 for pre-merge blocks
    uint256 private constant DIFFICULTY_THRESHOLD = type(uint64).max;

    /// @notice Function permitted to run only on ethereum mainnet, both before and after merge
    modifier notEthMainnet() {
        require(getChainId() != 1, "IEM");
        _;
    }

    /// @notice Function permitted to run only on ethereum mainnet, before merge
    modifier onlyBeforeMerge() {
        require(getChainId() == 1, "NEM");
        require(getBlockDifficulty() <= DIFFICULTY_THRESHOLD, "NBM");
        _;
    }

    /// @notice Function permitted to run only on ethereum mainnet, after merge
    modifier onlyAfterMerge() {
        require(getChainId() == 1, "NEM");
        require(getBlockDifficulty() > DIFFICULTY_THRESHOLD, "NAM");
        _;
    }

    /// @notice Return block chainid, can be overridden for testing
    function getChainId() public virtual view returns (uint256) {
        return block.chainid;
    }

    /// @notice Return block difficulty, can be overridden for testing
    function getBlockDifficulty() public virtual view returns (uint256) {
        return block.difficulty;
    }

    /// @notice IOU for ETH that is claimable after merge on mainnet
    ERC20Mintable public ethIOU = new ERC20Mintable("Post-Merge ETH IOU", "ETH-IOU");

    /// @notice IOU for ETHW that is claimable after fork on PoW chain
    ERC20Mintable public ethwIOU = new ERC20Mintable("Post-Fork ETHW IOU", "ETHW-IOU");

    /// @notice Display value, counts total ETH sent to contract pre-merge
    uint256 public totalEthVolume;

    /// @notice Display value, counts total ETHW withdrawn
    uint256 public totalWithdrawnEthw;

    /// @notice Fee taken from ETHW withdrawals after merge
    uint256 public immutable fee = 500;

    /// @notice Emergency IOU issuance pause
    bool public isPaused;

    // Events
    event IOUsIssued(address indexed sender, uint256 value);
    event IsPausedToggled(address toggler, bool isPaused);
    event EthRedeemed(address indexed sender, uint256 ethIOUBalance);
    event EthwRedeemed(address indexed sender, uint256 ethwIOUBalance, uint256 feeAmountEthw);

    constructor() {}

    /// @notice Issue ethereum mainnet and ethereum pow chain IOUs for deposited ether on mainnet
    function issueIOUs() public payable onlyBeforeMerge nonReentrant {
        require(!isPaused, "SP");
        require(msg.value > 0, "NZE");

        // Mint IOUs
        ethwIOU.mint(msg.sender, msg.value);
        ethIOU.mint(msg.sender, msg.value);

        totalEthVolume += msg.value;
        emit IOUsIssued(msg.sender, msg.value);
    }

    /// @notice After merge, users may redeem ether on mainnet
    function redeemEth() public onlyAfterMerge nonReentrant {
        // Get user's ether IOU balance and ensure they have more than 0 to redeem
        uint256 ethIOUBalance = ethIOU.balanceOf(msg.sender);
        require(ethIOUBalance > 0, "NZB");

        // Burn IOUs and transfer ether back to user
        ethIOU.burn(msg.sender, ethIOUBalance);
        (bool sent, ) = msg.sender.call{value: ethIOUBalance}("");
        require(sent, "FTS");

        emit EthRedeemed(msg.sender, ethIOUBalance);
    }

    /// @notice Redeem ETHW on PoW chain
    function redeemEthw() public notEthMainnet nonReentrant {
        // Get user's ETHW IOU balance and ensure they have more than 0 to redeem
        uint256 ethwIOUBalance = ethwIOU.balanceOf(msg.sender);
        require(ethwIOUBalance > 0, "NZB");

        // Contract takes a 5% fee
        uint256 feeAmountEthw = (ethwIOUBalance * fee) / 10_000;

        // Burn IOUs and transfer ETHW to user and contract owner
        ethwIOU.burn(msg.sender, ethwIOUBalance);

        (bool sent, ) = msg.sender.call{value: ethwIOUBalance - feeAmountEthw}("");
        require(sent, "FTS");
        (sent, ) = owner().call{value: feeAmountEthw}("");
        require(sent, "FTS");

        totalWithdrawnEthw += ethwIOUBalance;
        emit EthwRedeemed(msg.sender, ethwIOUBalance, feeAmountEthw);
    }

    /// @notice Pause deposits and disable issuing new IOUs
    function pause() public onlyOwner {
        isPaused = true;
        emit IsPausedToggled(msg.sender, true);
    }

    /// @notice Unpause deposits and re-enable disabling issuing new IOUs
    function unpause() public onlyOwner {
        isPaused = false;
        emit IsPausedToggled(msg.sender, false);
    }
}