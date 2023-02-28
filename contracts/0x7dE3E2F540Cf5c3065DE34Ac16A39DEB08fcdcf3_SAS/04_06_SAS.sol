//███████ ██ ███    ██ ███    ██ ███████ ██████  ███████        ██        ███████  █████  ██ ███    ██ ████████ ███████
//██      ██ ████   ██ ████   ██ ██      ██   ██ ██             ██        ██      ██   ██ ██ ████   ██    ██    ██
//███████ ██ ██ ██  ██ ██ ██  ██ █████   ██████  ███████     ████████     ███████ ███████ ██ ██ ██  ██    ██    ███████
//     ██ ██ ██  ██ ██ ██  ██ ██ ██      ██   ██      ██     ██  ██            ██ ██   ██ ██ ██  ██ ██    ██         ██
//███████ ██ ██   ████ ██   ████ ███████ ██   ██ ███████     ██████       ███████ ██   ██ ██ ██   ████    ██    ███████

// "The old shall die and the older shall rise"

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// "Do you know who we are? We are from [REDACTED]"

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

// "SAS is [REDACTED] for [REDACTED]"

error PortalNotOpen();
error SummonExceedsMaxSupply();
error FreeSummonLimitReached();
error PaidSummonLimitReached();
error InsufficientPayment();

// "Haha, this must be confusing for you. Don't worry, you'll understand soon enough..."
contract SAS is ERC721A, OperatorFilterer, Ownable {
    // Variables

    bool public portalOpen = false;
    uint256 public MAX_SUPPLY = 8888;
    uint256 public PAID_SUMMON_PRICE = 0.005 ether;

    uint256 public FREE_SUMMON_LIMIT = 1;
    uint256 public PAID_SUMMON_LIMIT = 10;

    string public baseURI;

    bool public operatorFilteringEnabled;

    // "Sacrifice your soul and be born a new. There is beauty in death while ugliness lingers in life. Don't you want to save that equilibrium you always talk about?"

    // Constructor

    constructor(string memory baseURI_) ERC721A("Sinners & Saints", "SAS") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        baseURI = baseURI_;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // "But, how do I know you aren't lying? You've lied before, and that almost cost me everything..."

    // Modifiers

    modifier nonContract() {
        require(tx.origin == msg.sender, "Contracts not allowed to mint");
        _;
    }

    // Mint

    function togglePortal() public onlyOwner {
        portalOpen = !portalOpen;
    }

    function summonFree() external nonContract {
        if (!portalOpen) revert PortalNotOpen();
        if (_totalMinted() >= MAX_SUPPLY) revert SummonExceedsMaxSupply();
        if (_getAux(msg.sender) != 0) revert FreeSummonLimitReached();
        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function summonPaid(uint256 qty) external payable nonContract {
        if (!portalOpen) revert PortalNotOpen();
        if (_totalMinted() + qty > MAX_SUPPLY) revert SummonExceedsMaxSupply();
        if (qty > PAID_SUMMON_LIMIT) revert PaidSummonLimitReached();
        if (msg.value < qty * PAID_SUMMON_PRICE) revert InsufficientPayment();
        _mint(msg.sender, qty);
    }

    // "Just trust me mortal, you are doing the right thing... Follow me through the flames."

    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Withdraw

    function withdraw() external onlyOwner {
        (bool hs, ) = payable(owner()).call{
            value: (address(this).balance * 25) / 100
        }("");
        require(hs);

        (bool os, ) = payable(0x0843EA83EE2E77AFC11C0d1290fd8fA868DB3973).call{
            value: address(this).balance
        }("");
        require(os);
    }
}

//Eldrin, an old warrior sat by the fire, his eyes distant as he stared into the flames. He had seen many things in his long years, battles, wars and brutalities that no man should ever have to witness. But nothing had prepared him for the destruction of the delicate equilibrium between sin and faith...
//In the old world, there had been a delicate balance between sin and faith, a balance that allowed people from all walks of life to find their purpose and meaning. But as the balance tipped, the world erupted into chaos, and the corrupted rose from the ground like weeds choking a garden.
//The old warrior had fought against the corrupted, battling their dark magic and twisted armies with his sword and shield. He had seen good men and women fall to corruption and madness, and the world had grown darker and darker with each passing day.
//Now, there were only 8888 warriors left, a small band of brave souls who had dedicated their lives to bringing balance back to the world. Their mission was a daunting one, for they knew that to restore balance, they must first sacrifice themselves.
//The old warrior knew that his time was coming soon, that he would join the ranks of the fallen who had given their lives for this cause. But he would do so with the knowledge that he had fought for something greater than himself, that he had stood for balance and justice in a world that sorely needed it.
//As the flames flickered and danced, the old warrior steeled himself for the battle to come. He would face the corrupted with all the strength he had left, knowing that his sacrifice would be one small step in the journey to restore the balance that had been lost.