// SPDX-License-Identifier: MIT
/**
     ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄ ▄▄    ▄ ▄▄▄▄▄▄▄    ▄▄▄▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄▄ ▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄    ▄▄▄   ▄ ▄▄▄ ▄▄▄▄▄▄  ▄▄▄▄▄▄▄ 
    █       █  █ █  █      █  █  █ █       █  █       █      █   ▄  █ █  ▄    █      █       █       █  █   █ █ █   █      ██       █
    █   ▄   █  █▄█  █  ▄   █   █▄█ █▄     ▄█  █   ▄▄▄▄█  ▄   █  █ █ █ █ █▄█   █  ▄   █   ▄▄▄▄█    ▄▄▄█  █   █▄█ █   █  ▄    █  ▄▄▄▄▄█
    █  █▄█  █       █ █▄█  █       █ █   █    █  █  ▄▄█ █▄█  █   █▄▄█▄█       █ █▄█  █  █  ▄▄█   █▄▄▄   █      ▄█   █ █ █   █ █▄▄▄▄▄ 
    █       █       █      █  ▄    █ █   █    █  █ █  █      █    ▄▄  █  ▄   ██      █  █ █  █    ▄▄▄█  █     █▄█   █ █▄█   █▄▄▄▄▄  █
    █   ▄   ██     ██  ▄   █ █ █   █ █   █    █  █▄▄█ █  ▄   █   █  █ █ █▄█   █  ▄   █  █▄▄█ █   █▄▄▄   █    ▄  █   █       █▄▄▄▄▄█ █
    █▄▄█ █▄▄█ █▄▄▄█ █▄█ █▄▄█▄█  █▄▄█ █▄▄▄█    █▄▄▄▄▄▄▄█▄█ █▄▄█▄▄▄█  █▄█▄▄▄▄▄▄▄█▄█ █▄▄█▄▄▄▄▄▄▄█▄▄▄▄▄▄▄█  █▄▄▄█ █▄█▄▄▄█▄▄▄▄▄▄██▄▄▄▄▄▄▄█

    Artist: Jon Swartz
    Developer: Shawn Barto
 */
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AvantGarbageKids is ERC721Enumerable, Ownable {

    bool public freeMint = false;
    bool public isMinting = false;
    bool public usePurchaseLimits = true;
    uint8 public purchaseLimit = 30;
    uint8 public singleMintLimit = 10;
    uint8 public freeMintNonce = 0;
    uint8 public freeMintLimit = 100;
    uint8 public freeMintAllowance = 3;
    uint8 public freeMintCollected = 0;
    uint16 public MAX_DUDES = 8008;
    uint16 public totalFreeMints = 0;
    uint16 public totalOwnerMints = 0;
    uint256 public price = 0.00808 ether;
    string public baseTokenURI = "https://www.avantgarbagekids.com/trash/";
    string public provenanceHash = "14b6cfdbf7bfc36c58a2caf7b7ae6998a00b44318b23d4d32a0862347f48d775";
    mapping(address => uint8) public purchased;
    mapping(uint8 => mapping(address => uint8)) public freeDudes;
    mapping(uint16 => uint16) public freeMintedIds;
    mapping(uint16 => uint16) public ownerMintedIds;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    modifier checkFreeMint(uint8 amount) {
        if(freeMint){
            uint8 _allowance = freeDudes[freeMintNonce][msg.sender];
            require(amount > 0, "Invalid Amount");
            require(_allowance < freeMintAllowance, "You got them already!");
            require(_allowance + amount <= freeMintAllowance, "Invalid Amount! Much Trash!");
            require(freeMintCollected + amount <= freeMintLimit, "Theres not enough left for that. Sorry.");
            freeDudes[freeMintNonce][msg.sender] = _allowance + amount;
            freeMintCollected = freeMintCollected + amount;
        } else {
            require(price * uint256(amount) <= msg.value, "Sorry bud. Not enough funds for that.");
        }
        _;
    }
    
    modifier mintCheckPassed(uint8 amount) {
        require(totalSupply() < uint256(MAX_DUDES), "Sorry! Minting has completed.");
        require(isMinting, "Minting is Disabled!");
        if(usePurchaseLimits){
            uint8 _purchased = purchased[msg.sender];
            require(_purchased + amount <= purchaseLimit && amount > 0 && amount <= singleMintLimit, "Invalid quantity.");
            purchased[msg.sender] = _purchased + amount;
        }
        _;
    }

    /** @notice ETH transfer wrapper. */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "Transfer FAILED");
    }

    /** @notice Override for managing the token uri.*/
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseTokenURI;
    }

    /** @notice Internal minting function.*/
    function _mintDudes(uint8 amount, address to, bool ownerMint) internal  {
        for (uint8 i = 0; i < amount; i++){
            uint256 _total = totalSupply();
            if (_total < uint256(MAX_DUDES)){ 
                uint256 _newId = _total + 1;
                _safeMint(to, _newId);
                if(ownerMint){
                    ownerMintedIds[totalOwnerMints] = uint16(_newId);
                    totalOwnerMints = totalOwnerMints + 1;
                } else if(freeMint){
                    freeMintedIds[totalFreeMints] = uint16(_newId);
                    totalFreeMints = totalFreeMints + 1;
                }
            }
        }
    }

    /** @notice Owner toggle for disabling Free Mint. */
    function disableFreeMint() external onlyOwner {
        freeMint = false;
    }

    /** @notice Owner toggle for enabling Free Mint. */
    function enableFreeMint(uint8 allowance, uint8 limit) external onlyOwner {
        freeMint = true;
        freeMintNonce++;
        freeMintLimit = limit;
        freeMintAllowance = allowance;
        freeMintCollected = 0;
    }

    /** @notice Owner toggle for setting mint state. */
    function enableMinting(bool enabled) external onlyOwner {
        isMinting = enabled;
    }

    /** @notice Owner toggle for setting purchase limits. */
    function enablePurchaseLimits(bool enabled) external onlyOwner {
        usePurchaseLimits = enabled;
    }

    /** @notice Owner can mint, free giveaways & more fun @ festivals, come find us! */
    function mintFreeTrash(uint8 amount, address to) external onlyOwner {
        _mintDudes(amount, to, true);
    }

    /** @notice Mint A Dude, Pay the price, or if its Free Mint time Donations are always welcome!! */
    function mintGarbageKid(uint8 amount) external payable mintCheckPassed(amount) checkFreeMint(amount) {
        _mintDudes(amount, msg.sender, false);
    }
 
    /** @notice Gift some trash to a friend. I'm sure they'd love it!! */
    function mintGarbageKidGift(uint8 amount, address reciever) external payable mintCheckPassed(amount) checkFreeMint(amount) {
        _mintDudes(amount, reciever, false);
    }

    /** @notice For the move to IPFS after mint. Update Base Token URI */
    function setBaseTokenURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    /** @notice We may decide to add more later? Crazy things? Who knows? Owner Only. */
    function setMaxSupply(uint16 maxSupply) external onlyOwner {
        require(MAX_DUDES < maxSupply, "Can't decrease supply!");
        MAX_DUDES = maxSupply;
    }

    /** @notice Updates the price for minting an AGK, disables Free Minting Owner Only. */
    function setPrice(uint256 amount) external onlyOwner {
        price = amount;
    }
    
    /** @notice Updates the purchase limits per address, Owner Only. */
    function setPurchaseLimits(uint8 _purchaseLimit, uint8 _singleMintLimit) external onlyOwner {
        purchaseLimit = _purchaseLimit;
        singleMintLimit = _singleMintLimit;
    }

    /** @notice  Emergency Set the provenance hash. To be used if we extend collection etc... */ 
    function setProvenance(string memory _provenance) external onlyOwner {
        provenanceHash = _provenance;
    }

    /** @notice  Withdraw Contracts Balance, if any. */
    function withdrawFunds() external onlyOwner {
        _safeTransferETH(msg.sender, address(this).balance);
    }

}