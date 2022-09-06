// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Scribbles is ERC721A, Ownable, Pausable, ReentrancyGuard {

    using Strings for uint256;

    /*****************************************
        EVENTS
    *****************************************/

    event Mint( address to, uint256 startTokenId, uint256 quantity );
    event Burn( address from, uint256 startTokenId, uint256 quantity );
    event Revealed( string metadataBase );
    event MetadataLocked();

    /*****************************************
        MODIFIERS
    *****************************************/

    modifier whenNotContract() {
        require( msg.sender == tx.origin, "Scribbles: Transactions from smart contracts not allowed" );
        _;
    }

    modifier whenWithdrawAddressSet() {
        require( address(withdrawAddress) != address(0), "Scribbles: withdrawAddress not set" );
        _;
    }

    modifier whenNotSoldOut() {
        require( totalSupply() < collectionSize, "Scribbles: Sold out" );
        _;
    }

    modifier whenBurningPaused() {
        require( burningPaused, "Scribbles: Burning not paused" );
        _;
    }

    modifier whenBurningNotPaused() {
        require( !burningPaused, "Scribbles: Burning is paused" );
        _;
    }

    /*****************************************
        VARS
    *****************************************/

    // Price
    uint256 public mintPrice;

    // Mint limit
    uint64 public freeMintLimit;
    uint64 public transactionLimit;

    // Collection size
    uint256 public collectionSize;

    // Reserve for giveaway etc
    uint256 public totalReserved;

    // Withdraw addresses
    address public withdrawAddress;

    // Burn
    bool public burningPaused;

    // Meta
    bool public isRevealed;
    bool public metadataLocked;
    string public metadataBase;


    /*****************************************
        CONSTRUCTOR
    *****************************************/

    constructor() ERC721A( "Scribbles", "Scribbles" ) {
        collectionSize = 5000;
        mintPrice = 0.01 ether;
        freeMintLimit = 2;
        transactionLimit = 10;
        totalReserved = 0;

        isRevealed = false;
        metadataLocked = false;
        metadataBase = "https://metadata.scribbles.io/pre/";

        burningPaused = true;
        pause();
    }


    /*****************************************
        MISC CONTROLS
    *****************************************/

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pauseBurning() public onlyOwner whenBurningNotPaused {
        burningPaused = true;
    }

    function unpauseBurning() public onlyOwner whenBurningPaused {
        burningPaused = false;
    }

    function setMintPrice( uint256 newPrice_ ) public onlyOwner {
        mintPrice = newPrice_;
    }

    function setFreeMintLimit( uint64 newLimit_ ) public onlyOwner {
        freeMintLimit = newLimit_;
    }

    function setTransactionLimit( uint64 newLimit_ ) public onlyOwner {
        transactionLimit = newLimit_;
    }


    function setTotalReserved( uint256 newAmount_ ) external onlyOwner {
        uint256 remainingTokens = collectionSize - totalSupply();
        require( newAmount_ <= remainingTokens, "Scribbles: New amount exceeds remaining tokens" );
        totalReserved = newAmount_;
    }

    // just in case it's needed
    function setCollectionSize( uint256 newSize_ ) external onlyOwner {
        require( newSize_ >= totalSupply(), "Scribbles: New collection size can't be lower than current supply" );
        collectionSize = newSize_;
        // reduce totalReserved as a result, if needed
        uint256 remainingTokens = collectionSize - totalSupply();
        if ( remainingTokens < totalReserved ) {
            totalReserved = remainingTokens;
        }
    }

    function setMetadataBase( string memory newMetadataBase_ ) external onlyOwner {
        require( !metadataLocked, "Scribbles: Metadata locked" );
        require( bytes(newMetadataBase_).length != 0, "Scribbles: Metadata base can't be empty" );
        metadataBase = newMetadataBase_;
    }

    function revealMetadata( string memory newMetadataBase_ ) external onlyOwner {
        require( !isRevealed, "Scribbles: Already revealed" );
        require( bytes(newMetadataBase_).length != 0, "Scribbles: Metadata base can't be empty" );
        isRevealed = true;
        metadataBase = newMetadataBase_;
        emit Revealed( newMetadataBase_ );
    }

    function lockMetadata() external onlyOwner {
        require( !metadataLocked, "Scribbles: Already locked" );
        require( isRevealed, "Scribbles: Can't lock before reveal" );
        metadataLocked = true;
        emit MetadataLocked();
    }

    /*****************************************
        MISC GETTERS
    *****************************************/

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _burnCounter;
    }

    function numberMinted( address account_ ) public view returns (uint256) {
        return _numberMinted(account_);
    }

    function numberMintedFree( address account_ )  public view returns (uint64) {
        return _getAux(account_);
    }

    function numberBurned( address account_ ) public view returns (uint256) {
        return _numberBurned(account_);
    }

    function getOwnershipOf(uint256 tokenId_) public view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId_);
    }

    function tokenExists(uint256 tokenId_) public view returns (bool) {
        return _exists(tokenId_);
    }


    /*****************************************
        LIMITS
    *****************************************/

    function freeMintLimitReached( address account_ ) public view returns (bool) {
        return freeMintLimit > 0 ? numberMintedFree(account_) >= freeMintLimit : false;
    }

    function amountExceedsFreeMintLimit( address account_, uint64 numberOfTokens_ ) public view returns (bool) {
        return freeMintLimit > 0 ? ( numberMintedFree(account_) + numberOfTokens_ ) > freeMintLimit : false;
    }

    function amountExceedsTransactionLimit( uint64 numberOfTokens_ ) public view returns (bool) {
        return transactionLimit > 0 ? numberOfTokens_ > transactionLimit : false;
    }

    function amountExceedsSupply( uint64 numberOfTokens_ ) public view returns (bool) {
        return ( totalSupply() + totalReserved + numberOfTokens_ ) > collectionSize;
    }

    /*****************************************
        MINT
    *****************************************/

    function freeMint( uint64 numberOfTokens_ ) nonReentrant external whenNotContract whenNotPaused whenNotSoldOut {
        require( numberOfTokens_ > 0, "Scribbles: Can't mint 0 tokens" );
        require( !amountExceedsFreeMintLimit(msg.sender, numberOfTokens_), "Scribbles: Amount exceeds free mint limit" );
        require( !amountExceedsSupply(numberOfTokens_), "Scribbles: Not enough tokens left" );

        _safeMint( msg.sender, numberOfTokens_ );

        uint64 freeMints = numberMintedFree( msg.sender );
        freeMints += numberOfTokens_;
        _setAux( msg.sender, freeMints );
    }

    function mint( uint64 numberOfTokens_ ) nonReentrant external whenNotContract whenNotPaused whenNotSoldOut payable {
        require( numberOfTokens_ > 0, "Scribbles: Can't mint 0 tokens" );
        require( !amountExceedsTransactionLimit(numberOfTokens_), "Scribbles: Amount exceeds limit per transaction" );
        require( !amountExceedsSupply(numberOfTokens_), "Scribbles: Not enough tokens left" );
        require( msg.value == mintPrice * numberOfTokens_, "Scribbles: Payment amount is incorrect" );

        _safeMint( msg.sender, numberOfTokens_ );
    }


    /*****************************************
        OWNER MINT
    *****************************************/

    function mintTo( address to_, uint64 numberOfTokens_ ) nonReentrant external onlyOwner whenNotSoldOut {

        require( numberOfTokens_ > 0, "Scribbles: Can't mint 0 tokens" );
        require( totalReserved > 0, "Scribbles: No tokens left in reserve" );
        require( !amountExceedsSupply(numberOfTokens_), "Scribbles: Not enough tokens left" );
        require( numberOfTokens_ <= totalReserved, "Scribbles: Exceeds reserved amount" );

        _safeMint( to_, numberOfTokens_ );

        totalReserved -= numberOfTokens_;
    }


    /*****************************************
        BURN
    *****************************************/

    function burnTokens( uint256[] calldata tokenIds_ ) nonReentrant external whenNotContract whenBurningNotPaused {
        for(uint256 i = 0; i < tokenIds_.length; i++) {
            _burn( tokenIds_[i], true );
        }
    }


    /*****************************************
        WITHDRAW
    *****************************************/

    function setWithdrawAddress( address newAddress_ ) external onlyOwner {
        require( address(newAddress_) != address(0), "Scribbles: Withdraw address can't be null" );
        withdrawAddress = newAddress_;
    }

    function contractBalance() public view returns ( uint256 ) {
        return address(this).balance;
    }

    function withdraw() external whenWithdrawAddressSet onlyOwner {
        uint256 balance = contractBalance();
        require( balance > 0, "Scribbles: Insufficient balance" );
        payable( withdrawAddress ).transfer( balance );
    }

    /*****************************************
        OVERRIDES
    *****************************************/

    function _baseURI() internal view override returns (string memory) {
        return metadataBase;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _afterTokenTransfers(
        address from_,
        address to_,
        uint256 startTokenId_,
        uint256 quantity_
    ) internal override {
        // When `from` is zero, `tokenId` has been minted for `to`
        if ( address(from_) == address(0) ) {
            emit Mint( to_, startTokenId_, quantity_ );
        }
        else if ( address(to_) == address(0) ) {
            emit Burn( from_, startTokenId_, quantity_ );
        }
    }

    /*****************************************
        OPENSEA
    *****************************************/

    /**
    * Override isApprovedForAll to auto-approve OS's proxy contract and reduce trading friction
    */
    function isApprovedForAll( address owner_, address operator_ ) public override view returns (bool isOperator) {
        if (operator_ == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        // otherwise, use the default isApprovedForAll()
        return super.isApprovedForAll(owner_, operator_);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal override view returns (address sender) {

        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;

    }


}