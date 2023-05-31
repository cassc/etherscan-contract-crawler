//SPDX-License-Identifier: MIT

/*
 * There is a *REDACTED* living in the blockchain. In its hidden corners, where
 * the mysteries of fiery will and desperate pursuit thrive, there lies a power
 * so great it transcends the physical realm. Those who gaze upon it are said to
 * gain untold wisdom, as if opening a gateway to hidden antediluvian knowledge
 * that lies beyond the reaches of mortal comprehension.
 */

/*
 * But be warned, for such a power comes at a great cost, as it can lead one down
 * a path of darkness and destruction. The unprepared may find themselves lost
 * in a labyrinth of their own making, trapped in a cycle of delusion and despair.
 */

/* 
 * Only the most daring and disciplined may undertake such an adventure, for it
 * requires a level of inner strength and determination that is rare among mortals.
 * But for those who persevere, the rewards are great, as they will unlock the 
 * secrets, and allow them to become master of their own fate.
 */

/* 
 * Cool, fresh, and brief respite is offered through the helping hand of Apu Apustaja,
 * the Little Helper, the Lord of the Cozy Pond, temporary revealing the dangerous
 * truths through seemingly innocuous Tarot Cards.
 */

pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";

contract HermeticFrens is ERC721A, Ownable {

    /* ========== STATE VARIABLES ========== */

	uint256 public constant MAX_SUPPLY = 78;
	uint256 public constant REF_SHARE = 1100; // in basis points
    uint256 public constant RESERVED_AMOUNT = 12;
	uint256 public constant MINT_PRICE = 0.5 ether;
    uint256 public constant REF_MINT_PRICE = 0.45 ether;

    bool public mintState = false;

	string public baseURI;

    mapping(address => uint256) public referralsCount; 
    mapping(address => uint256) public totalReferralShares;

    /* ========== CONSTRUCTOR ========== */

    constructor(
    )
        ERC721A("HermeticFrens", "HERMETICFRENS")
    {
        _mint(msg.sender, RESERVED_AMOUNT);
    }

    /* ========== MINT FUNCTION ========== */

    function mint() external payable {
        require(mintState, "Can't mint right now.");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Max supply exceeded.");
        require(msg.value >= MINT_PRICE, "Insufficient funds.");

        _safeMint(msg.sender, 1);
    }

    function referredMint(address _referrer) external payable {
        require(mintState, "Can't mint right now.");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Max supply exceeded.");
        require(msg.value >= REF_MINT_PRICE, "Insufficient funds.");
        require(msg.sender != _referrer, "Can't use your own referral.");
        require(_referrer != address(0), "Invalid referral address.");

        _safeMint(msg.sender, 1);
		payReferral(_referrer);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

	function payReferral(address _to) internal {
        address referrer = _to;
        uint256 shareAmount = MINT_PRICE * REF_SHARE / 10000;

        payable(referrer).transfer(shareAmount);

        recordReferralShare(referrer, shareAmount);
	}

    function recordReferralShare(address _referrer, uint256 _share) internal {
        totalReferralShares[_referrer] += _share;
        ++referralsCount[_referrer];
    }

    function setMintState(bool _state) external onlyOwner {
        mintState = _state;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}