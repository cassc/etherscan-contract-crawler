// SPDX-License-Identifier: ISC

/*
 * Commercial Use of Boho Beats Music Library
 * All Bohobeats music loops may be used in commercial recordings by BohoBones NFT owners/holders.
 * BohoBones NFT holders will have full commercial rights to the entire boho beats music library.
 * If royalties from commercial recordings exceeds 25K USD then 20% of Gross sales must be reallocated
 * to the BohoBones community wallet to help promote and fund future Boho Art & Music community projects.
 */

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/payment/PaymentSplitter.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BohoBones
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BohoBones is ERC721, Ownable, PaymentSplitter, ReentrancyGuard {
    using SafeMath for uint256;

    // Provenance and reveal mechanisms
    string public BOHOBONE_PROVENANCE = "";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public REVEAL_TIMESTAMP;

    // Default boho bone token metrics
    uint256 public bohoBonePrice = 8e16; //0.08 ETH
    uint256 public maxBohoBonePurchase = 3;
    uint256 public MAX_BOHOBONES = 12345;
    uint256 public numReservationsLeft = 500;
    
    // Storage for treasury wallets.
    address[] private _treasuryWallets;

    // Enum for encapturing sale states
    enum SaleState {
        PAUSED,
        PRESALE,
        ACTIVE
    }

    // Variable for storing sale state
    SaleState public saleStatus;

    // Mapping to store addresses allowed for presale, and how
    // many Boho Bones remain that they can purchase during presale.
    mapping (address => uint256) public presaleVouchers;

    constructor(string memory name, string memory symbol, uint256 saleStart, address[] memory treasuryWallets, uint256[] memory treasuryShares)
      ERC721(name, symbol)
      PaymentSplitter(treasuryWallets, treasuryShares) {
        REVEAL_TIMESTAMP = saleStart + 172800; // 48 Hours after sale start
        _treasuryWallets = treasuryWallets;

        // Default sale state to paused
        saleStatus = SaleState.PAUSED;
    }

    /**
     * @param newPrice The new price for an individual boho bone.
     * @dev Sets a new price for an individual boho bone.
     * @dev Can only be called by owner.
     */
    function setBohoBonePrice(uint256 newPrice) public onlyOwner {
        bohoBonePrice = newPrice;
    }

    /**
     * @param newMaxBohoBonePurchase The new maximum number of boho bones that can be minted per transaction.
     * @dev Sets the new maximum number of boho bone purchases per transaction.
     * @dev Can only be called by owner.
     */
    function setMaxBohoBonePurchase(uint256 newMaxBohoBonePurchase) public onlyOwner {
        maxBohoBonePurchase = newMaxBohoBonePurchase;
    }

    /**
     * @param numBohoBones The number of boho bones to reserve.
     * @dev Reserves boho bones for giveaways.
     * @dev Will not allow reservations above maximum reserve threshold.
     * @dev Can only be called by owner.
     */
    function reserveBohoBones(uint256 numBohoBones) public onlyOwner {
        require(numBohoBones <= numReservationsLeft, "BohoBones: Reservations would exceed max reservation threshold of 500.");
        require(totalSupply().add(numBohoBones) <= MAX_BOHOBONES, "BohoBones: Reservations would exceed max supply of BohoBones.");
        
        uint256 supply = totalSupply();
        uint256 i;
        
        for (i = 0; i < numBohoBones; i++) {
            _safeMint(msg.sender, supply.add(i));

            // Reduce num reservations left
            numReservationsLeft = numReservationsLeft.sub(1);
        }
    }
    
    /**
     * @param presaleAddress Address to be added to the list of verified presale addresses.
     * @param numPresaleBohoBones Amount of presale boho bones to give to the address.
     * @dev Can only be called by owner.
     */
    function addPresaleAddress(address presaleAddress, uint256 numPresaleBohoBones) public onlyOwner {
        require(presaleAddress != address(0), "BohoBones: Cannot add burn address to the presale.");
         
        presaleVouchers[presaleAddress] = numPresaleBohoBones;
    }

    /**
     * @param newPresaleAddresses Addresses to be added to the list of verified presale addresses.
     * @param voucherAmount Amount of presale boho bones to give per address.
     * @dev Can only be called by owner.
     */
    function addPresaleAddresses(address[] memory newPresaleAddresses, uint256 voucherAmount) public onlyOwner {
        for (uint256 i = 0; i < newPresaleAddresses.length; i++) {
            addPresaleAddress(newPresaleAddresses[i], voucherAmount);
        }
    }

    /**
     * @param addressToDelete The address to remove from the verified presale list.
     * @dev Can only be called by owner.
     */
    function removePresaleAddress(address addressToDelete) public onlyOwner {
        delete presaleVouchers[addressToDelete];
    }

    /**
     * @param revealTimeStamp The timestamp, in epoch format, of the reveal.
     * @dev Can only be called by owner.
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    /**
     * @param provenanceHash The combined hash string of the NFT assets.
     * @dev Can only be called by owner.
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        BOHOBONE_PROVENANCE = provenanceHash;
    }

    /**
     * @param baseURI The base URI for the contract's NFTs.
     * @dev Can only be called by owner.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * @param saleStateIndex Determines what state the sale will be switched to,
     * e.g., 0 = Paused, 1 = Presale, 2 = Active Sale.
     * @dev Pause, set to presale, or active sale.
     * @dev Can only be called by contract owner.
     */
    function setSaleState(uint256 saleStateIndex) public onlyOwner {
        saleStatus = SaleState(saleStateIndex);
    }

    /**
     * @param numberOfTokens The number of tokens to be minted.
     * @dev Non-reentrant, minting entry point.
     */
    function mintBohoBone(uint256 numberOfTokens) public payable nonReentrant {
        require(saleStatus == SaleState.ACTIVE || saleStatus == SaleState.PRESALE, "BohoBones: Sale must be active or in presale mint boho bone.");

        if (saleStatus == SaleState.PRESALE) {
            require(presaleVouchers[msg.sender] >= numberOfTokens, "BohoBones: You don't not have enough presale vouchers to mint that many boho bones.");
        }

        require(numberOfTokens <= maxBohoBonePurchase, "BohoBones: Please try to mint a lower amount of Boho Bones.");
        require(totalSupply().add(numberOfTokens) <= MAX_BOHOBONES, "BohoBones: Purchase would exceed max supply of BohoBones.");
        require(bohoBonePrice.mul(numberOfTokens) <= msg.value, "BohoBones: Ether value sent is not correct.");
        
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_BOHOBONES) {
                _safeMint(msg.sender, mintIndex);

                // If we are in the presale, decrease 
                if (saleStatus == SaleState.PRESALE) {
                    presaleVouchers[msg.sender] = presaleVouchers[msg.sender].sub(1);
                }
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_BOHOBONES || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    /**
     * @dev Sets the starting index for the collection.
     * @dev Can only be called by owner.
     */
    function setStartingIndex() public onlyOwner  {
        require(startingIndex == 0, "BohoBones: Starting index is already set");
        require(startingIndexBlock != 0, "BohoBones: Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_BOHOBONES;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_BOHOBONES;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev Sets the starting index block for the collection in the event
     * of an emergency.
     * @dev Can only be called by owner.
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "BohoBones: Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    /**
     * @dev Withdraws all contract funds and distributes across treasury wallets.
     * @dev Can only be called by owner.
     */
    function withdrawAll() public onlyOwner {
        for (uint256 i = 0; i < _treasuryWallets.length; i++) {
            address payable wallet = payable(_treasuryWallets[i]);
            release(wallet);
        }
    }
}