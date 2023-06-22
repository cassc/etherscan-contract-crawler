pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Owned.sol";

contract Sale is Owned {
    /*/////////////////////////////////////////////////
                          EVENTS
    /////////////////////////////////////////////////*/

    event SaleEntered(address indexed user, uint256 amount);
    event SaleClaimed(address indexed user, uint256 amount);
    event TokensSupplied(uint256 amount);
    event ProceedsWithdrawn(uint256 amount);

    /*/////////////////////////////////////////////////
                            STATE 
    /////////////////////////////////////////////////*/

    /// @notice token being sold off
    ERC20 public immutable token;

    /// @notice start time of sale (starts upon deployment)
    uint256 public immutable startTime;

    /// @notice duration of sale
    uint256 public immutable SALE_TIME;

    /// @notice buffer time post sale to provide liquidity
    uint256 public immutable POST_SALE;

    /// @notice max amount per address to mint. Zyzz says don't sybil
    uint256 public constant MAX_SALE = 777000000000000000; // .777 ether

    /// @notice maximum amount of total ether accepted for sale
    uint256 public constant HARDCAP = 44400000000000000000; // 44.4 ether

    /// @notice internal accounting of tokens supplied to sale, can be upped before sale ends
    uint256 public suppliedTokens;

    /// @notice internal accounting of total deposits
    /// @dev lp may be filled before everyone has claimed, so this maintains eth proceeds accounting
    uint256 public totalDeposits;

    /// @notice total eth deposits for each address, cannot exceed MAX_SALE
    mapping(address => uint256) public deposits;

    constructor(
        ERC20 token_,
        address owner_,
        uint256 SALE_TIME_,
        uint256 POST_SALE_
    ) Owned(owner_) {
        token = token_;
        startTime = block.timestamp;
        SALE_TIME = SALE_TIME_;
        POST_SALE = POST_SALE_;
    }

    receive() external payable {
        if (!saleLive()) revert("sale ended");

        if (deposits[msg.sender] + msg.value > MAX_SALE)
            revert("max sale amount");

        // The total supply of ether will never overflow
        unchecked {
            deposits[msg.sender] += msg.value;
            totalDeposits += msg.value;
        }

        emit SaleEntered(msg.sender, msg.value);
    }

    function claimTokens() external {
        if (!claimLive()) revert("sale or post sale period live");

        uint256 share = getCurrentShare(msg.sender);
        delete deposits[msg.sender];

        token.transfer(msg.sender, share);
        emit SaleClaimed(msg.sender, share);
    }

    function getCurrentShare(address account) public view returns (uint256) {
        return (suppliedTokens * deposits[account]) / totalDeposits;
    }

    function withdrawProceeds() external onlyOwner {
        if (saleLive()) revert("sale live");

        emit ProceedsWithdrawn(address(this).balance);
        payable(owner).transfer(address(this).balance);
    }

    function supplyTokens() external onlyOwner {
        if (!saleLive()) revert("sale ended");
        suppliedTokens = token.balanceOf(address(this));

        emit TokensSupplied(token.balanceOf(address(this)));
    }

    function saleLive() internal view returns (bool) {
        return
            block.timestamp <= startTime + SALE_TIME &&
            block.timestamp >= startTime;
    }

    function claimLive() internal view returns (bool) {
        return block.timestamp >= startTime + SALE_TIME + POST_SALE;
    }
}
