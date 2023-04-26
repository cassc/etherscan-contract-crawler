// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//   .--,-``-.                                   ,-.----.
//  /   /     '.           ,--,     ,--,         \    /  \
// / ../        ;          |'. \   / .`|         |   :    \
// \ ``\  .`-    '         ; \ `\ /' / ;         |   |  .\ :
//  \___\/   \   :         `. \  /  / .'         .   :  |: |
//       \   :   |          \  \/  / ./          |   |   \ :
//       /  /   /            \  \.'  /           |   : .   /
//       \  \   \             \  ;  ;            ;   | |`-'
//   ___ /   :   |           / \  \  \           |   | ;
//  /   /\   /   :          ;  /\  \  \          :   ' |
// / ,,/  ',-    .        ./__;  \  ;  \         :   : :
// \ ''\        ;         |   : / \  \  ;        |   | :
//  \   \     .'          ;   |/   \  ' |        `---'.|
//   `--`-,,-'            `---'     `--`           `---`
// 3XP - https://3XP.art
// Follow us at https://twitter.com/3XPart
//

error NoETHLeft();
error ETHTransferFailed();

contract Token is ERC20Burnable, Ownable {
    bool public allowContributions;
    uint256 public constant MIN_CONTRIBUTION = .01 ether;
    uint256 public constant MAX_CONTRIBUTION = 0.69 ether;
    uint256 public HARD_CAP;
    uint256 public constant MAX_SUPPLY = 1969000000 * 10 ** 18;
    uint256 public constant PRESALE_SUPPLY = 738375000 * 10 ** 18;
    uint256 public constant RESERVE_MAX_SUPPLY = 1230625000 * 10 ** 18;
    uint256 public TOTAL_CONTRIBUTED;
    uint256 public NUMBER_OF_CONTRIBUTORS;

    struct Contribution {
        address addr;
        uint256 amount;
    }

    mapping(uint256 => Contribution) public contribution;
    mapping(address => uint256) public contributor;

    constructor(uint256 HARD_CAP_) ERC20("MoonBois", "MOONBOIS") {
        HARD_CAP = HARD_CAP_;
    }

    fallback() external payable {
        sendToPresale();
    }

    receive() external payable {
        sendToPresale();
    }

    /// collect presale contributions
    function sendToPresale() public payable {
        /// look up the sender's current contribution amount in the mapping
        uint256 currentContribution = contribution[contributor[msg.sender]]
            .amount;

        /// initialize a contribution index so we can keep track of this address' contributions
        uint256 contributionIndex;

        require(msg.value >= MIN_CONTRIBUTION, "Contribution too low");

        /// check to see if contributions are allowed
        require(allowContributions, "Contributions not allowed");

        /// enforce per-wallet contribution limit
        require(
            msg.value + currentContribution <= MAX_CONTRIBUTION,
            "Contribution exceeds per wallet limit"
        );

        /// enforce hard cap
        require(
            msg.value + TOTAL_CONTRIBUTED <= HARD_CAP,
            "Contribution exceeds hard cap"
        );

        if (contributor[msg.sender] != 0) {
            /// no need to increase the number of contributors since this person already added
            contributionIndex = contributor[msg.sender];
        } else {
            /// keep track of each new contributor with a unique index
            contributionIndex = NUMBER_OF_CONTRIBUTORS + 1;
            NUMBER_OF_CONTRIBUTORS++;
        }

        /// add the contribution to the amount contributed
        TOTAL_CONTRIBUTED = TOTAL_CONTRIBUTED + msg.value;

        /// keep track of the address' contributions so far
        contributor[msg.sender] = contributionIndex;
        contribution[contributionIndex].addr = msg.sender;
        contribution[contributionIndex].amount += msg.value;
    }

    function airdropPresale() external onlyOwner {
        /// determine the price per token
        uint256 pricePerToken = (TOTAL_CONTRIBUTED * 10 ** 18) / PRESALE_SUPPLY;

        /// loop over each contribution and distribute tokens
        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTORS; i++) {
            /// convert contribution to 18 decimals
            uint256 contributionAmount = contribution[i].amount * 10 ** 18;

            /// calculate the percentage of the pool based on the address' contribution
            uint256 numberOfTokensToMint = contributionAmount / pricePerToken;

            /// mint the tokens to the address
            _mint(contribution[i].addr, numberOfTokensToMint);
        }
    }

    /// dev mint the remainder of the pool to round out the supply
    function devMint() external onlyOwner {
        /// calculate the remaining supply
        uint256 numberToMint = MAX_SUPPLY - totalSupply();

        /// don't allow the dev mint until the tokens have been airdropped
        require(
            numberToMint <= RESERVE_MAX_SUPPLY,
            "Dev mint limited to reserve max"
        );

        /// mint the remaining supply to the dev's wallet
        _mint(msg.sender, numberToMint);
    }

    /// set whether or not the contract allows contributions
    function setAllowContributions(bool _value) external onlyOwner {
        allowContributions = _value;
    }

    function setHardCap(uint256 HARD_CAP_) external onlyOwner {
        HARD_CAP = HARD_CAP_;
    }

    /// if there are not enough contributions or we decide this sucks, refund everyone their eth
    function refundEveryone() external onlyOwner {
        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTORS; i++) {
            address payable refundAddress = payable(contribution[i].addr);

            /// refund the contribution
            refundAddress.transfer(contribution[i].amount);
        }
    }

    function withdrawETH(address payable _address) external onlyOwner {
        if (address(this).balance <= 0) {
            revert NoETHLeft();
        }

        (bool success, ) = _address.call{value: address(this).balance}("");

        if (!success) {
            revert ETHTransferFailed();
        }
    }
}