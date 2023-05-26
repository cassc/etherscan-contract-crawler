// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                                  
     ▄█▀▀▀█▄█   ▀████▀   ▀███▀    ▄█▀▀▀█▄█
    ▄██    ▀█     ▀██    ▄▄█     ▄██    ▀█
    ▀███▄          ██▄  ▄██      ▀███▄    
     ▀█████▄       ██▄  ▄█        ▀█████▄
    ▄     ▀██       ▀████▀       ▄     ▀██
    ██     ██        ▄██▄        ██     ██
    █▀█████▀          ██         █▀█████▀ 
    
    SVS X 888 / 2021
*/
                                          
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SVSx888 is ERC1155, Ownable {
    using ECDSA for bytes32;
    
    mapping(address => bool) public claimed;
    
    address private _signerAddress = 0x801FD7eB0b813F0eB0E20409e23b63D3C3aDB39c;
    bool public live;
    bool public upgradingLive;
    
    constructor() ERC1155("https://svs.gg/api/888/metadata/{id}") {}
    
    function verifyTransaction(address sender, uint256 amount, bytes memory signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, amount));
        return _signerAddress == hash.recover(signature);
    }
    
    function claim(uint256 amount, bytes memory signature) external {
        require(live, "NOT_RELEASED");
        require(verifyTransaction(msg.sender, amount, signature), "INVALID_TRANSACTION");
        require(!claimed[msg.sender], "ALREADY_CLAIMED");
        claimed[msg.sender] = true;
        
        _mint(msg.sender, 1, amount, "");
    }
    
    function upgrade(uint256 amount, uint256 fromTier, uint256 toTier) external {
        require(upgradingLive, "UPGRADING_NOT_LIVE");
        require(fromTier > 0 && toTier <= 8, "INVALID_TIERS");
        require(fromTier != toTier, "CANT_UPGRADE_SAME_TIER");
        
        uint256 requiredFromTiers = amount * (2 ** (toTier - fromTier));
        require(balanceOf(msg.sender, fromTier) >= requiredFromTiers, "NOT_ENOUGH_BALANCE");
        
        _burn(msg.sender, fromTier, requiredFromTiers);
        _mint(msg.sender, toTier, amount, "");
    }
    
    function toggle() external onlyOwner {
        live = !live;
    }

    function toggleUpgrading() external onlyOwner {
        upgradingLive = !upgradingLive;
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
}