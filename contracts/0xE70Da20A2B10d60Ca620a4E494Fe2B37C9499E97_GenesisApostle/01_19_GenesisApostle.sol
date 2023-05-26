// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// External interfaces
import "./interface/IBYOKey.sol";
import "./interface/IBYOPill.sol";

// Base interfaces
import "./interface/IApostle.sol";

contract GenesisApostle is IApostle {
    
    // Constants
    uint256 private constant KEY_IDX = 0;
    uint256 private constant MAX_APOSTLES_PER_TX = 50;
    
    // Options
    bool public m_redeemOpen = false;
    
    // External
    IBYOPill public m_pillContract;
    IBYOKey public m_keyContract;
    
    constructor(string memory _name, string memory _symbol, string memory _baseURI, address pillContract, address keyContract) 
        IApostle (_name, _symbol, _baseURI) {
        m_pillContract = IBYOPill(pillContract);
        m_keyContract = IBYOKey (keyContract);
    }
    
    // OWNER ONLY
    
    function toggleRedeemActive () public onlyOwner {
        m_redeemOpen = !m_redeemOpen;
    }
    
    // PUBLIC
    
    function redeem(uint256[] calldata pillIds) public isRedeemActive {
        uint256 redeemCount = pillIds.length;

        require (redeemCount > 0, "At least one.");
        require (redeemCount <= MAX_APOSTLES_PER_TX, "Exceeding per tx redeems.");
        require (m_keyContract.balanceOf (msg.sender, KEY_IDX) >= redeemCount, "Not enough keys.");
        checkPills (pillIds);
        
        for (uint256 i = 0; i < redeemCount; i++) {
            _safeMint(msg.sender, pillIds[i]);
        }
        
        m_keyContract.burnFromRedeem (msg.sender, KEY_IDX, redeemCount);
    }
    
    // VIEWS
    
    function isPillUsed (uint256 _pillId) public view returns (bool) {
        return _exists (_pillId);
    }

    
    // INTERNALS
    
    function checkPills (uint256[] memory pills) internal view {
        for (uint256 i = 0; i < pills.length; i++) {
            require (!isPillUsed(pills[i]), "One of pills is used !");
            require (m_pillContract.ownerOf(pills[i]) == msg.sender, "Not your pill.");
        }
    }
	
	// MODIFIERS
	
    modifier isRedeemActive() {
        require(m_redeemOpen || 
        owner() == _msgSender(), "Redeeming is not active.");
        _;
    }
    
}