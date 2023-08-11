// SPDX-License-Identifier: MIT

// $KATZ by Katz.Community
// author: sadat.eth

pragma solidity ^0.8.20;

/*

                .-=+**######**+=-.                
            :=*####################*=:            
         :=############################+:         
       :*################################*-       
     .*#*########*++==+####*==++*########*#*:     
    =##*==+*##*+======+####*=======*##*+==*##+    
   *###*============+*######*+============*###*   
  *####*==========*############*==========*####*  
 =#####*=========#######**######*=========*#####+ 
.######*========+######====*#####=========*######:
=######*========+######*==================*######+
*######*=========#########**+=============*#######
#######*==========*###########*+==========*#######
*#######============+**#########*=========*#######
+#######=================+*######*========#######+
.#######*=======+******====######*=======*#######:
 +#######*======+######*++*######+======+#######+ 
  *#######*======+##############+======*#######*  
   *########+======*#########*+======+########*.  
    =#########*=======+#####=======*#########+    
     :*##########*++==+####*==++*###########:     
       -*#################################-       
         :+############################+:         
            :=*####################*=:            
                .-=+**#######*+=-:                

*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface NFT { function balanceOf(address owner) external view returns (uint256 balance); }

contract $KATZ is ERC20, Ownable {

    // =========================================================================
    //                         37.5% DISTRIBUTION
    // =========================================================================

    constructor() ERC20("KATZ", "KATZ") {
        _mint(msg.sender, 500000 * 10 ** decimals());
        _mint(0x01c466c5DbEdDec87BFEb43B9D64bC21800233B9, 1450000 * 10 ** decimals());
        _mint(0x1779769E01a5B954d813E85446318441D322F2f6, 1000000 * 10 ** decimals());
        _mint(0x2d4d806b60737422b66Dae8D83b60912e11821B3, 500000 * 10 ** decimals());
        _mint(0x44eb189EAf8Fef9Fc518E99344E70d327cf8E83F, 100000 * 10 ** decimals());
        _mint(0xFaeE491442d408191c6e6702cF1910b7211E5042, 100000 * 10 ** decimals());
        _mint(0x562ADBaBE7F3912A67a9FC52b4D9ca600650dbE3, 100000 * 10 ** decimals());
    }

    // =========================================================================
    //                         62.5% BURN NFT TO CLAIM
    // =========================================================================

    address private KM = 0xb5C2c4bdd64379DDA029F04340598EE9EBA7A7aF;
    address private KW = 0x8D28EB8079aE341cA45Bb91E4900974b6999b959;
    mapping (address => uint256) public unclaimed;

    function getReward(address _address) external {
        if (msg.sender == KM) { unclaimed[_address] += 2000 * 10 ** decimals(); }
        else if (msg.sender == KW) { unclaimed[_address] += 500 * 10 ** decimals(); }
    }

    function claimReward() external {
        if (unclaimed[msg.sender] > 0) {
            _mint(msg.sender, unclaimed[msg.sender]);
            unclaimed[msg.sender] = 0;
        }
    }

    // =========================================================================
    //                         POOL & TOKEN LIMITS
    // =========================================================================
    
    bool private onlyKatz;

    function setOnlyKatz(bool _onlyKatz) external onlyOwner {
        onlyKatz = _onlyKatz;
    }

    address private pool;
    uint256 private antiPump;
    uint256 private antiDump;
    uint256 private antiWhale;

    function setPool(address _pool, uint256 _antiPump, uint256 _antiDump, uint256 _antiWhale) external onlyOwner {
        pool = _pool;
        antiPump = _antiPump;
        antiDump = _antiDump;
        antiWhale = _antiWhale;
    }

    mapping (address => bool) private badKatz;

    function setBadKatz(address _address) external onlyOwner {
        badKatz[_address] = !badKatz[_address];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!badKatz[from] && !badKatz[to], "badKatz");
        if (antiPump != 0 && from == pool) { require(amount <= antiPump, "antiPump"); }
        if (antiDump != 0 && to == pool) { require(amount <= antiDump, "antiDump"); }
        if (antiWhale != 0 && from == pool) { require(balanceOf(to) + amount <= antiWhale, "antiWhale"); }
        if (onlyKatz && from != address(0)) {
            require(NFT(KM).balanceOf(to) > 0 || NFT(KW).balanceOf(to) > 0 || balanceOf(to) > 0, "onlyKatz");
        }
    }

    // =========================================================================
    //                         SUPPLY INFO & BURN
    // =========================================================================

    uint256 private maxSupply = 10000000 * 10 ** decimals();

    function totalSupply() public view virtual override returns (uint256) {
        return maxSupply;
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
        maxSupply -= value;
    }
}