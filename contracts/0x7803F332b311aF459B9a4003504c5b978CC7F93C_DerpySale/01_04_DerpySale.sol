// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DerpySale is Ownable {
    enum PresaleStatus {
        NotStarted,
        Started,
        Ended,
        Refund
    }

    // ERC20 token details
    IERC20 public DERPY_COIN;
    uint256 public presaleSupply = 30.1 gwei * 10 ** 18; // Total supply of the presale tokens

    // Presale status
    PresaleStatus public presaleStatus;
    uint256 public totalETHDeposited;
    uint256 public ethThreshold = 69 ether;

    uint256 public constant MAX_ETH_DEPOSIT = 0.69 ether;
    uint256 public constant MIN_ETH_DEPOSIT = 0.069 ether;

    // Mapping to keep track of user deposits
    mapping(address => uint256) public deposits;

    // Event emitted when a user claims their tokens
    event TokensClaimed(address user, uint amount);

    constructor() {
        presaleStatus = PresaleStatus.NotStarted;
    }

    modifier onlyDuringPresale() {
        require(
            presaleStatus == PresaleStatus.Started,
            "Presale not active"
        );
        _;
    }

    modifier onlyAfterPresale() {
        require(
            presaleStatus == PresaleStatus.Ended,
            "Presale has not ended yet"
        );
        _;
    }

    modifier onlyRefundOpen() {
        require(presaleStatus == PresaleStatus.Refund, "Refund not open");
        _;
    }

    function setPresaleStatus(PresaleStatus _status) external onlyOwner {
        presaleStatus = _status;
    }

    function setEthThreshold(uint _threshold) external onlyOwner {
        ethThreshold = _threshold;
    }

    function setCoinAddress(address _address) external onlyOwner {
        DERPY_COIN = IERC20(_address);
    }

    function deposit() public payable onlyDuringPresale {
        require(
            totalETHDeposited + msg.value <= ethThreshold,
            "Presale threshold reached"
        );
        require(
            deposits[msg.sender] + msg.value >= MIN_ETH_DEPOSIT,
            "Too little deposit"
        );
        require(
            deposits[msg.sender] + msg.value <= MAX_ETH_DEPOSIT,
            "Too large deposit"
        );

        deposits[msg.sender] += msg.value;
        totalETHDeposited += msg.value;
    }

    function claimTokens() external onlyAfterPresale {
        uint256 tokensToClaim = availableToClaim();
        require(tokensToClaim > 0, "No tokens to claim");

        DERPY_COIN.transfer(msg.sender, tokensToClaim);
        deposits[msg.sender] = 0;

        emit TokensClaimed(msg.sender, tokensToClaim);
    }

    function setPresaleSupply(uint256 _supply) external onlyOwner {
        presaleSupply = _supply;
    }

    function availableToClaim()
        public
        view
        onlyAfterPresale
        returns (uint256 tokens)
    {
        uint256 tokensToClaim = (deposits[msg.sender] * presaleSupply) /
            totalETHDeposited;

        return tokensToClaim;
    }

    function withdrawETH() external onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os, "Withdraw not successful");
    }

    function refund() external onlyRefundOpen {
        require(deposits[msg.sender] > 0, "No amount to refund");
        (bool os, ) = payable(msg.sender).call{value: deposits[msg.sender]}("");
        require(os, "Withdraw not successful");
        deposits[msg.sender] = 0;
    }

    function withdrawTokens() external onlyOwner {
        DERPY_COIN.transfer(owner(), DERPY_COIN.balanceOf(address(this)));
    }

    // Fallback function to receive ETH
    receive() external payable onlyDuringPresale {
        deposit();
    }
}