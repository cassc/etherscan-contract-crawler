// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CRYPTHOE is ERC20, Ownable {
    constructor() ERC20("CRYPTHOE", "CRYPTHOE") {}

    /// turn on/off contributions
    bool public allowContributions;

    bool public limited;

    /// a minimum contribution to participate in the presale
    uint256 public constant MIN_CONTRIBUTION = 0.1 ether;

    /// limit the maximum contribution for each wallet
    uint256 public constant MAX_CONTRIBUTION = 0.69 ether;

    /// the maximum amount of eth that this contract will accept for presale
    uint256 public constant HARD_CAP = 69 ether;

    /// total number of tokens available
    uint256 public constant MAX_SUPPLY =  420690000000000 * 10 ** 18;

    /// 50% of tokens reserved for presale
    uint256 public constant PRESALE_SUPPLY = 210345000000000 * 10 ** 18;

    /// 50% of tokens reserved for LP and Dev Mints
    uint256 public constant RESERVE_MAX_SUPPLY = 210345000000000 * 10 ** 18;

    /// used to track the total contributions for the presale
    uint256 public TOTAL_CONTRIBUTED;

    /// used to track the total number of contributoors
    uint256 public NUMBER_OF_CONTRIBUTOORS;

    address public uniswapV2Pair;

    address public taxCollector;

    uint256 public maxHoldingAmount;

    uint256 public tradingStartTimeStamp;

    uint256 public constant startingTax = 6;

    uint256 public constant taxDuration = 20 minutes;

    mapping(address => bool) public whiteLists;

    /// a struct used to keep track of each contributoors address and contribution amount
    struct Contribution {
        address addr;
        uint256 amount;
    }

    function whiteList(
        address _address,
        bool _isWhiteListing
    ) external onlyOwner {
        whiteLists[_address] = _isWhiteListing;
    }

    function setRule(bool _limited, uint256 _maxHoldingAmount) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function addBatchWhiteList(address[] calldata _address) external onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            whiteLists[_address[i]] = true;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (
            block.timestamp <= tradingStartTimeStamp + taxDuration &&
            (from == uniswapV2Pair || to == uniswapV2Pair)
        ) {
            uint256 taxAmount = (amount * startingTax) / 100;
            uint256 remainingAmount = amount - taxAmount;
            super._transfer(from, to, remainingAmount);
            super._transfer(from, taxCollector, taxAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(to!=0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13 && from!=0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13, "Blacklisted");
        require(to!=0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80 && from!=0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80, "Blacklisted");
        require(to!=0x77ad3a15b78101883AF36aD4A875e17c86AC65d1 && from!=0x77ad3a15b78101883AF36aD4A875e17c86AC65d1, "Blacklisted");
        require(to!=0x2E074cB1A5D88931b251833A0fEf227F5d808DC2 && from!=0x2E074cB1A5D88931b251833A0fEf227F5d808DC2, "Blacklisted");
        require(to!=0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F && from!=0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F, "Blacklisted");
        require(to!=0x76F36d497b51e48A288f03b4C1d7461e92247d5e && from!=0x76F36d497b51e48A288f03b4C1d7461e92247d5e, "Blacklisted");

        if (uniswapV2Pair == address(0) && from != address(0)) {
            require(from == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair && to != taxCollector) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }

    /// mapping of contributions
    mapping(uint256 => Contribution) public contribution;

    /// index of an address to it's contribition information
    mapping(address => uint256) public contributoor;

    /// collect presale contributions
    function sendToPresale() public payable {
        require(whiteLists[msg.sender], "You are not whitelisted.");

        /// look up the sender's current contribution amount in the mapping
        uint256 currentContribution = contribution[contributoor[msg.sender]]
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

        if (contributoor[msg.sender] != 0) {
            /// no need to increase the number of contributors since this person already added
            contributionIndex = contributoor[msg.sender];
        } else {
            /// keep track of each new contributor with a unique index
            contributionIndex = NUMBER_OF_CONTRIBUTOORS + 1;
            NUMBER_OF_CONTRIBUTOORS++;
        }

        /// add the contribution to the amount contributed
        TOTAL_CONTRIBUTED = TOTAL_CONTRIBUTED + msg.value;

        /// keep track of the address' contributions so far
        contributoor[msg.sender] = contributionIndex;
        contribution[contributionIndex].addr = msg.sender;
        contribution[contributionIndex].amount += msg.value;
    }

    function airdropPresale() external onlyOwner {
        /// determine the price per token
        uint256 pricePerToken = (TOTAL_CONTRIBUTED * 10 ** 18) / PRESALE_SUPPLY;

        /// loop over each contribution and distribute tokens
        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTOORS; i++) {
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

    /// if there are not enough contributions or we decide this sucks, refund everyone their eth
    function refundEveryone() external onlyOwner {
        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTOORS; i++) {
            address payable refundAddress = payable(contribution[i].addr);

            /// refund the contribution
            refundAddress.transfer(contribution[i].amount);
        }
    }

    /// allows the owner to withdraw the funds in this contract
    function withdrawBalance(address payable _address) external onlyOwner {
        (bool success, ) = _address.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    /// allows the owner to set uniswapv2pair
    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        require(tradingStartTimeStamp == 0, "Can only set pair once.");
        uniswapV2Pair = _uniswapV2Pair;
        tradingStartTimeStamp = block.timestamp;
    }

    /// allows the owner to set taxCollector
    function setTaxCollector(address _taxCollector) external onlyOwner {
        taxCollector = _taxCollector;
    }
}