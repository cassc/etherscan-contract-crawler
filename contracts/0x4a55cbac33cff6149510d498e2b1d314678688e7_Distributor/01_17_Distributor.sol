// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "src/H4CK3R5.sol";

contract Distributor is Ownable {

    uint256 public constant MAX_MINT = 1507;
    uint256 public constant DISCOUNT_MINT_COST = 0.05 ether;
    uint256 public constant MINT_COST = 0.069 ether;

    address public immutable SKULLS;
    address public immutable CHAIN_RUNNERS;
    address public immutable BASED_GHOULS;

    address public constant FEE_RECEIVER = 0xFb34Fc2a64BB863015145370554B5fbA5eFc5DC8;
    
    H4CK3R5 public immutable hackers;  // we can only set this once, if we mess up we need to redeploy and update the NFT contract
    
    // we group the bools to determine if an NFT has minted from both collections to save storage

    struct Discounted_Mint {
        bool skulls;
        bool chainRunners;
        bool basedGhouls;
    }

    mapping(uint256 => Discounted_Mint) public discountedMints;
    mapping(address => uint8) public mintedByAddress;

    uint16[MAX_MINT] public ids;
    uint16 private index;
    
    constructor(
        address _hackers,
        address _skulls,
        address _chain_runners,
        address _based_ghouls
    ) {
        hackers = H4CK3R5(_hackers);
        SKULLS = _skulls;
        CHAIN_RUNNERS = _chain_runners;
        BASED_GHOULS = _based_ghouls;
    }

    function _payReceiver(uint256 amount) internal {
        bool success;

        address to = FEE_RECEIVER;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    // just in case fees get stuck we should be able to force them to pay the receiver wallet
    function withdraw() public onlyOwner {
        _payReceiver(address(this).balance);
    }

    function withdraw(uint256 amt) public onlyOwner {
        _payReceiver(amt);
    }

    // in the event that there is a problem with the fund withdrawal we can force the withdraw to owner wallet
    function emergencyWithdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _pickPseudoRandomUniqueId(uint256 seed) private returns (uint256 id) {
        uint256 len = ids.length - index++;
        require(len > 0, 'Mint closed');
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, block.timestamp))) % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
        id++;
    }

    function discountedMint(address collection, uint256 id) public payable {
        require(collection == address(SKULLS) || collection == address(CHAIN_RUNNERS) || collection == address(BASED_GHOULS), "Invalid collection");
        require(msg.sender == IERC721(collection).ownerOf(id), "Caller not owner of Id");
        bool hasMinted;
        if(collection == address(SKULLS)) {
            hasMinted = discountedMints[id].skulls;
            discountedMints[id].skulls = true;
        } else if(collection == address(CHAIN_RUNNERS)) {
            hasMinted = discountedMints[id].chainRunners;
            discountedMints[id].chainRunners = true;
        } else if(collection == address(BASED_GHOULS)) {
            hasMinted = discountedMints[id].basedGhouls;
            discountedMints[id].basedGhouls = true;
        }
        
        require(!hasMinted, "Already claimed");
        require(msg.value == DISCOUNT_MINT_COST, "Insufficient payment");
        mintedByAddress[msg.sender]++;

        hackers.mintFromDistributor(msg.sender, _pickPseudoRandomUniqueId(uint160(msg.sender)*id));

    }

    function publicMint(uint8 amt) public payable {
        // owner not subjected to maxes
        if(msg.sender != owner()){
            require(amt <= 10 , "Max 10 mints");
            require(mintedByAddress[msg.sender]+amt <= 10, "Max 10 per address");
            require(msg.value == amt * MINT_COST, "Insufficient payment");
            mintedByAddress[msg.sender] += amt;
        }

        for(uint256 i = 0; i<amt; ++i) {
            hackers.mintFromDistributor(msg.sender, _pickPseudoRandomUniqueId(uint160(msg.sender)*i));
        }
    }
}