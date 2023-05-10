/*
We are cooking the $SAUCE
https://t.me/saucecoineth
https://twitter.com/saucecoinoneth
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SAUCE is ERC20, Ownable {
    /// Enable the spicy sauce
    bool public enableSauce;

    /// Minimum contribution (presale)
    uint256 public constant MIN_CONTRIBUTION = .03 ether;

    /// Maximum contribution (presale)
    uint256 public constant MAX_CONTRIBUTION = .3 ether;

    /// The maximum acceptable eth
    uint256 public HARD_CAP = 40 ether;

    /// Total number of tokens available
    uint256 public constant MAX_SUPPLY = 200000000000000 * 10**18;

    /// 50% of tokens reserved for presale
    uint256 public constant PRESALE_SUPPLY = 100000000000000 * 10**18;

    /// 50% = 40% LP + 10% Team
    uint256 public constant RESERVE_MAX_SUPPLY = 100000000000000 * 10**18;

    /// Total contributions
    uint256 public TOTAL_CONTRIBUTED;

    /// Total number of contributoors
    uint256 public NUMBER_OF_CONTRIBUTOORS;

    struct Contribution {
        address addr;
        uint256 amount;
    }

    mapping(uint256 => Contribution) public contribution;
    mapping(address => uint256) public contributoor;

    constructor() ERC20("SAUCE", "SAUCE") {
        _mint(_msgSender(), 200000000000000 * 10**18);
    }

    /// The sauce is burning
    function burn(uint256 amount) public virtual {
        require(
            balanceOf(_msgSender()) >= amount,
            "ERC20: burn amount exceeds sauce balance"
        );
        _burn(_msgSender(), amount);
    }

    /// jaredfromsubway.eth had to much sauce
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal virtual override {
        require(
            to != 0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13 &&
                from != 0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13,
            "Blacklisted"
        );
        require(
            to != 0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80 &&
                from != 0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80,
            "Blacklisted"
        );
        require(
            to != 0x77ad3a15b78101883AF36aD4A875e17c86AC65d1 &&
                from != 0x77ad3a15b78101883AF36aD4A875e17c86AC65d1,
            "Blacklisted"
        );
        require(
            to != 0x2E074cB1A5D88931b251833A0fEf227F5d808DC2 &&
                from != 0x2E074cB1A5D88931b251833A0fEf227F5d808DC2,
            "Blacklisted"
        );
        require(
            to != 0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F &&
                from != 0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F,
            "Blacklisted"
        );
        require(
            to != 0x76F36d497b51e48A288f03b4C1d7461e92247d5e &&
                from != 0x76F36d497b51e48A288f03b4C1d7461e92247d5e,
            "Blacklisted"
        );
    }

    /// We are cooking
    function sendToPresale() public payable {
        uint256 currentContribution = contribution[contributoor[msg.sender]]
            .amount;

        uint256 contributionIndex;

        require(enableSauce, "The sauce is still closed");

        require(
            msg.value >= MIN_CONTRIBUTION,
            "Not enough sauce in your wallet"
        );
        require(
            msg.value + currentContribution <= MAX_CONTRIBUTION,
            "Too much sauce ahhhh"
        );
        require(
            msg.value + TOTAL_CONTRIBUTED <= HARD_CAP,
            "Too much sauce ahhhh"
        );

        if (contributoor[msg.sender] != 0) {
            contributionIndex = contributoor[msg.sender];
        } else {
            contributionIndex = NUMBER_OF_CONTRIBUTOORS + 1;
            NUMBER_OF_CONTRIBUTOORS++;
        }

        TOTAL_CONTRIBUTED = TOTAL_CONTRIBUTED + msg.value;

        contributoor[msg.sender] = contributionIndex;
        contribution[contributionIndex].addr = msg.sender;
        contribution[contributionIndex].amount += msg.value;
    }

    /// Sauce airdrop incoming
    function airdropPresale() external onlyOwner {
        uint256 pricePerToken = (TOTAL_CONTRIBUTED * 10**18) / PRESALE_SUPPLY;

        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTOORS; i++) {
            uint256 contributionAmount = contribution[i].amount * 10**18;
            uint256 numberOfTokensToTransfer = contributionAmount / pricePerToken;
            transfer(contribution[i].addr, numberOfTokensToTransfer);
        }
    }

    /// The sauce is out
    function setSauce(bool _value) external onlyOwner {
        enableSauce = _value;
    }

    /// ngmi sauce
    function refundSauce() external onlyOwner {
        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTOORS; i++) {
            address payable refundAddress = payable(contribution[i].addr);
            refundAddress.transfer(contribution[i].amount);
        }
    }

    function setHardCAP(uint256 _hcap) external onlyOwner {
        HARD_CAP = _hcap;
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        bool success = true;
        (success, ) = payable(owner()).call{value: contractBalance}("");
        require(success, "Transfer failed");
    }
}