// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/utils/math/SafeMath.sol";
import "openzeppelin/contracts/utils/math/Math.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Presale is Context, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Contribute(
        uint256 round,
        address indexed contributor,
        uint256 amountInput,
        uint256 tokenOutput
    );

    IERC20 public BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 public ETRNL;

    uint256 public amountSold;

    bool public finalized;

    uint256 constant public salePrice1 = 1.25 ether;
    uint256 constant public salePrice2 = 1.50 ether;

    uint256 public startTime1 = 1676556000;
    uint256 public startTime2 = 1676988000; //change to unix time at mainnet

    mapping(address => bool) public contributed1;
    mapping(address => bool) public contributed2;

    mapping(address => uint256) public contributedAmounts;
    mapping(address => uint256) public amountSpent;

    //------------------------Round 1------------------------//

    function contributeRound1(uint256 contributionAmount) external {

        require(block.timestamp > startTime1, "Round 1 not yet started.");
        require(!finalized, "Round 1 has ended");
        require(!contributed1[msg.sender], "Can only contribute once.");
        require(contributionAmount >= 50 ether, "Amount too low");
        require(contributionAmount <= 2500 ether, "Amount too high");

        BUSD.safeTransferFrom(msg.sender, address(this), contributionAmount);
        uint256 tokensOutput = _quote(contributionAmount);
        ETRNL.safeTransfer(msg.sender, tokensOutput);

        amountSpent[msg.sender] += contributionAmount;
        contributedAmounts[msg.sender] += tokensOutput;
        contributed1[msg.sender] = true;
        emit Contribute(1, msg.sender, contributionAmount, tokensOutput);
        amountSold += contributionAmount;
    }
    //--------------------------------------------------------//

    //------------------------Round 2-------------------------//
    function contributeRound2(uint256 contributionAmount) external {

        require(block.timestamp > startTime2, "Round 2 not yet started.");
        require(finalized, "Round 1 should end before round 2 starts");
        require(!contributed2[msg.sender], "Can only contribute once.");
        require(contributionAmount >= 100 ether, "Amount too low");
        require(contributionAmount <= 5000 ether, "Amount too high");

        BUSD.safeTransferFrom(msg.sender, address(this), contributionAmount);
        uint256 tokensOutput = _quote(contributionAmount);
        ETRNL.safeTransfer(msg.sender, tokensOutput);

        amountSpent[msg.sender] += contributionAmount;
        contributedAmounts[msg.sender] += tokensOutput;
        contributed2[msg.sender] = true;
        emit Contribute(2, msg.sender, contributionAmount, tokensOutput);
        amountSold += contributionAmount;
    }
    
    function _quote(uint256 amount) internal view returns (uint256) {
        if(!finalized){
            return uint256(1e18).mul(amount).div(salePrice1);
        }else {
            return uint256(1e18).mul(amount).div(salePrice2);
        }
    }

    function quote(uint256 amount) external view returns (uint256) {
        return _quote(amount);
    }

    // read functions
    function getAmountSold() external view returns (uint256) {
        return amountSold;
    }

    function getAvailableETRNLforPresale() external view returns (uint256) {
        return ETRNL.balanceOf(address(this));
    }

    function setAddressETRNL(address etrnl) external onlyOwner {
        require(Address.isContract(etrnl), "Not a contract address");
        ETRNL = IERC20(etrnl);
    }

    // only owner functions to get unused ETRNL tokens and withdraw pre-sale funds.
    function withdrawTokens(address tokenToWithdraw) external onlyOwner {
        IERC20(tokenToWithdraw).safeTransfer(
            msg.sender,
            IERC20(tokenToWithdraw).balanceOf(address(this))
        );
    }

    function finalizeRound1() external onlyOwner {
        require(!finalized, "Already finalized");
        finalized = true;
    }
}