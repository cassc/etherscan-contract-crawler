// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./util/Util.sol";
import "./IPriceHandler.sol";
import "./ISupplyManager.sol";


/**
* @title Mystic Galactic Mission One
* @author Mystic Galactic Mission One LLC
* @notice Mystic Galactic Mission One (MGM1) Smart Contract.
* This contract implements the legally binding Bottle Deposit Agreement for the minting, management, and sale of ERC721 tokens related to the Mystic Galactic Mission 1 project.
* The full text of the Bottle Deposit Agreement is available at https://w3s.link/ipfs/bafybeigtlvzhcwa22gcmmqsps2w5uf4qcchqlixa4bx7cwq3fnxnto4z5y.
* The Bottle Deposit Agreement is the only source of the binding terms and conditions.
* All comments below are for the convenience of persons examining the code, but are superseded by any terms of the Bottle Deposit Agreement that conflict with these comments.
* The contract is designed to facilitate distribution and management of tokens, with built-in administrative controls and a refund mechanism for NFT owners.
* The contract includes a refund mechanism which enables the contract owner to refund deposits to owners of specific tokens.
* In the case that 1000 deposit NFTs are not minted, at the owner's discretion, all token owner(s) may be refunded or the mission may proceed.
* Upon successful execution of the refund, the contract emits a 'RefundProcessed' event and transfers the refund amount to the token owner(s)
* Note: This contract represents a contract for pre-sale deposit per the terms of the Bottle Deposit Agreement.
* @dev The contract uses the OpenZeppelin library for standard ERC721 functionality,
* additional features such as contract pausing, ownership management, and access control.
* Custom pricing and supply management contracts can be set at the discretion of the contract owner.
* The contract includes a refund mechanism which enables the contract owner to refund token owner(s) of specific tokens.
* In case all deposits are not minted, at the owner's discretion, or if the mission fails, all token owner(s) can be refunded.
* Upon successful execution of the refund, the contract emits a 'RefundProcessed' event and transfers the refund amount to the token owner(s).
*/
contract MysticGalacticMission1 is ERC721, Ownable, Pausable, AccessControl {
    using Util for uint256;

    /**
     * @dev The initial total supply of tokens available for minting at the contract deployment.
     * This value is immutable, meaning it can only be set once during contract deployment and cannot be changed afterwards.
     */
    uint16  public  immutable initialSupply;

    /**
     * @dev The initial supply of tokens that is reserved for specific purposes or individuals at the contract deployment.
     * This value is immutable, meaning it can only be set once during contract deployment and cannot be changed afterwards.
     */
    uint16  public  immutable initialReservedSupply;

    /**
     * @dev The maximum number of tokens that can be minted in a single day.
     * This value is immutable, meaning it can only be set once during contract deployment and cannot be changed afterwards.
     */
    uint16  public  immutable supplyPerDay;

    /**
     * @dev The `callerKey` is an immutable variable that is used to validate the caller of the contract.
     * It ensures that only the authorized contract can call certain functions.
     */
    bytes32 private immutable callerKey;

    /**
     * @dev The `depositAcct` is where all the deposit funds are sent.
     * This address is set once at the time of contract deployment.
     */
    address private depositAcct;

    /**
     * @dev The `baseURI` is a string that represents the base Uniform Resource Identifier (URI)
     * where the metadata of each token is stored.
     */
    string private baseURI;

    /**
     * @dev The `DEPOSIT_ROLE` is a constant hash of the string "DEPOSIT_ROLE",
     * used to assign and manage deposit account roles in the contract.
     */
    bytes32 private immutable DEPOSIT_ROLE;

    /**
     * @dev The `DEPOSIT_ROLE` is a constant hash of the string "RESERVE_ROLE",
     * used to assign and manage administrative roles in the contract.
     */
    bytes32 private immutable RESERVE_ROLE;

    // Sub Contracts

    /**
     * @dev The `ph` variable represents an instance of the IPriceHandler interface.
     * This contract is used to handle the pricing logic of the tokens.
     */
    IPriceHandler private ph;

    /**
     * @dev The `phAddr` is the address of the PriceHandler contract.
     */
    address private phAddr;

    /**
     * @dev The `sm` variable represents an instance of the ISupplyManager interface.
     * This contract is used to manage the supply of the tokens.
     */
    ISupplyManager private sm;

    /**
     * @dev The `smAddr` is the address of the SupplyManager contract.
     */
    address private smAddr;


    /**
     * @dev Modifier function to restrict access to only the contract owner or accounts with the DEFAULT_ADMIN_ROLE.
     * Ensures that the caller of the function in which this modifier is used has the DEFAULT_ADMIN_ROLE,
     * otherwise it reverts the transaction.
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not owner or admin");
        _;
    }

    /**
     * @dev Modifier function to restrict access to only the designated reserve minter account.
     * Ensures that the caller of the function in which this modifier is used is the reserve minter,
     * otherwise it reverts the transaction.
     */
    modifier onlyReserveMinter () {
        require(hasRole(RESERVE_ROLE, msg.sender), "Caller is not reserve minter");
        _;
    }

    /**
     * @dev Modifier function to restrict access to only the designated deposit account.
     * Ensures that the caller of the function in which this modifier is used is the deposit account,
     * otherwise it reverts the transaction.
     */
    modifier onlyDepositAcct () {
        require(hasRole(DEPOSIT_ROLE, msg.sender), "Caller is not deposit account");
        _;
    }


    /**
     * @dev Initializes the contract by setting the initial base URI, price in Wei, maximum tokens,
     * and maximum tokens per day. Inherits from ERC721, Ownable, Pausable, and AccessControlEnumerable.
     * Sets up the DEFAULT_ADMIN_ROLE and ADMIN_ROLE for the contract creator and pauses the contract.
     * @param _depositAcct The Account where funds from mints should go
     * @param _reserveAcct The Account that is allowed to mint from the reserved supply
     * @param _initialSupply The initial supply
     * @param _initialReservedSupply The amount of the supply reserved for the owner of this contract
     * @param _supplyPerDay  The maximum amount per day all purchasers combined may make
     */
    constructor( bytes32 _depositRole, address _depositAcct, bytes32 _reserveRole, address _reserveAcct, uint16 _initialSupply, uint16 _initialReservedSupply, uint16 _supplyPerDay, bytes32 _callerKey ) ERC721("Mystic Galactic Mission 1", "MYGM1") {
        require(_initialSupply > 0, "Supply <= 0");
        require((_initialSupply - _initialReservedSupply)  > 0, "Reserved supply > Total supply");

        // Set immutable values
        callerKey = _callerKey;
        initialSupply = _initialSupply;
        supplyPerDay = _supplyPerDay;
        initialReservedSupply = _initialReservedSupply;
        depositAcct = _depositAcct;
        DEPOSIT_ROLE = _depositRole;
        RESERVE_ROLE = _reserveRole;

        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEPOSIT_ROLE, depositAcct);
        _setupRole(RESERVE_ROLE, _reserveAcct);

        // Pause the contract initially
        _pause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }


    /**
     * @dev Sets the price handler contract address, which is responsible for handling the price logic of the NFTs.
     * Can only be called by an account with the ADMIN_ROLE.
     * @param _priceHandlerAddr The address of the price handler contract.
     */
    function setPriceHandler (address _priceHandlerAddr) external onlyAdmin {
        phAddr = _priceHandlerAddr;
        ph = IPriceHandler(_priceHandlerAddr);
    }

    /**
     * @dev Sets the supply manager contract address, which is responsible for managing the supply of the NFTs.
     * It also initializes the supply of NFTs in the supply manager contract.
     * Can only be called by an account with the ADMIN_ROLE.
     * @param _supplyManagerAddr The address of the supply manager contract.
     */
    function setSupplyManager (address _supplyManagerAddr) external onlyAdmin {
        smAddr = _supplyManagerAddr;
        sm = ISupplyManager(_supplyManagerAddr);
        sm.initializeSupply();
    }



    /**
     * @dev Mints new NFTs for the caller. This function can also refund any excess payment to the caller.
     * Can only be called when the contract is not paused.
     * @param bottles The number of NFTs to be minted.
     */
    function mintNFT(uint16 bottles) public payable whenNotPaused {
        (uint256 totalAmount, int256 refundAmount ) = sm.mintFromPublicSupply(msg.sender, bottles, msg.value, ph.price(), hasRole(DEPOSIT_ROLE, msg.sender));

        if (refundAmount > 0) {
            payable(msg.sender).transfer(uint256(refundAmount));
        }

        payable(depositAcct).transfer(totalAmount);
    }

    /**
     * @dev Mints new NFTs from the reserved supply for the caller.
     * Can only be called by the reserve minter account and when the contract is not paused.
     * @param bottles The number of NFTs to be minted from the reserved supply.
     */
    function mintNFTReserved(uint256 bottles) public onlyReserveMinter whenNotPaused {
        sm.mintFromReservedSupply(msg.sender, bottles);
    }

    /**
     * @dev Safely mints a new NFT and emits a TokenMinted event.
     * Can only be called by the supply manager contract.
     * @param minter The account that will own the minted NFT.
     * @param tokenId The ID for the NFT to be minted.
     * @param tokenPrice The price at which the NFT was minted.
     * @param _callerKey The key used to verify the caller's identity.
     */
    function _safeMinter(address minter, uint256 tokenId, uint256 tokenPrice, bytes32 _callerKey) external {
        require ((msg.sender == smAddr) && (_callerKey == callerKey), "Unauthorized");
        _safeMint(minter, tokenId);
        emit TokenMinted(minter, tokenPrice, tokenId, tokenURI(tokenId));
    }

    event TokenMinted(address indexed to, uint256 paymentReceived, uint256 tokenId, string tokenURI);

    /**
     * @dev Returns the URI for a given NFT.
     * Reverts if the NFT does not exist.
     * @param tokenId The ID of the NFT to query.
     * @return The URI of the NFT.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, '/nft/', tokenId.toString())) : "";
    }


    /**
     * @dev Returns the metadata URI (IPFS Address) for the contract metadata that can be used by marketplaces such as Opensea for describing
     * the collection of NFT's minted herein.
     * @return The metadata URI for the project description
     */
    function contractURI() public view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, '/metadata')) : "";
    }

    /**
     * @dev Updates the base URI (IPFS address)  for NFT metadata.
     * Can only be called by an admin account and will only update informational metadata.
     * The Deposit Agreement URI(IPFS Address) described in the metadata will never change.
     * Emits a BatchMetadataUpdate Event to notify marketplaces such as Opensea of the change in metadata
     * @param _baseURI The new base URI
     */
    function updateMetadata( string memory _baseURI ) external onlyAdmin {
        baseURI = _baseURI;
        uint16 _supplyUsed = sm.supplyUsed();
        if ( _supplyUsed != 0 ) {
            emit BatchMetadataUpdate(0, _supplyUsed - 1);
        }
    }

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);


    // Refunding

    /**
     * @dev Refunds the token owner(s) and burns the NFTs. There are two possible models based on forever.  If forever the contract is refunding for the purpose of closing the
     * the contract and refunding all deposits.  If forever is false, the accounts are refunded and the NFT may be minted again (recycled) to be used by another token owner.
     * Tokens can not be burnt unless the token owner is refunded. However, these refund mechanism does not guarantee the price that a token owner(s) will receive upon refund
     * Can only be called by the deposit account.
     * @param _tokenIds An array of token IDs to be refunded.
     * @param forever The if forever is true the NFTs burt may never be reused.  If it is false than the NFT's may be re-used by the by the supply manager.
     */
    function refundMinters(uint256[] calldata _tokenIds, bool forever) external payable onlyDepositAcct {
        for ( uint256 i = 0; i < _tokenIds.length; i++ ) {
            address minter = ownerOf(_tokenIds[i]);
            payable(minter).transfer(msg.value/_tokenIds.length);

            // Burn the NFT
            _burn(_tokenIds[i]);
            if ( !forever ) {
                sm.tokenBurnt(i);
            }

            emit RefundProcessed(minter, (msg.value / _tokenIds.length));
            emit TokenBurnt(i);
        }
    }

    event RefundProcessed(address to, uint256 amount);
    event TokenBurnt(uint256 tokenId);


    // Security Functions

    /**
     * @dev Pause the contract
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() public onlyAdmin {
        _unpause();
    }

    /**
     * @dev Overrides the grantRole function to restrict modifications of certain roles.
     * There can only be one deposit account as such granting the role to DEPOSIT_ROLE revokes the
     * permissions for the previous Deposit Acct
     */
    function grantRole(bytes32 role, address acct) public virtual override onlyOwner {
        if ( role == DEPOSIT_ROLE ) {
            revokeRole(DEPOSIT_ROLE, depositAcct);
            depositAcct = acct;
        }
        super.grantRole(role, acct);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        address oldOwner = owner();
        super.transferOwnership(newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }


    /**
     * @dev Verifies that the caller is a sub contract such as SupplyManager or PriceHandler.  Only valid contracts can execute methods
     * in the main contract
     * @param _callerKey Private key exchanged between contracts
     */
    function validateKey(bytes32 _callerKey) external view {
       require((msg.sender == phAddr || msg.sender == smAddr) && callerKey == _callerKey, "Contract caller is not authorized");
    }


    // Pricing

    /**
     * @dev Sets a new price for minting a token in USD. The USD price should be 2 decimal places not the 18 decimal places of an ETHER
     * @param _usdPrice The new price in usdPrice.
     */
    function setPrice(uint256 _usdPrice) external onlyOwner {
        ph.setPrice(_usdPrice);
        emit PriceUpdated(_usdPrice);
    }
    event PriceUpdated(uint256 newPrice);

    /**
     * @dev Sets the feed for the price conversion to native currency for price() method
     * @param _priceFeedAddress The address of the price feed oracle
     */
    function setPriceFeed( address _priceFeedAddress ) external onlyAdmin {
        ph.setPriceFeed(_priceFeedAddress);
    }

    /**
     * @dev Returns the current price for minting a token in the native currency
     * @return The current price in the native currency with 18 decimals of accuracy.
     */
    function price() external view returns (uint256) {
        return ph.price();
    }

    /**
     * @dev Returns the current price for minting a token in USD.
     * @return The current price in USD.
     */
    function priceInUSD() external view returns (uint256) {
        return ph.priceInUSD();
    }

    /**
     * @dev Returns the number of tokens minted today.
     * @return uint16 Number of tokens minted today.
     */
    function supplyMintedToday() external view returns (uint16) {
        return sm.supplyMintedToday();
    }

    /**
     * @dev Resets the daily supply limit.
     * Can only be called by an admin account.
     */
    function resetSupplyPerDay() external onlyAdmin {
        emit SupplyPerDayReset();
        return sm.resetSupplyPerDay();
    }
    event SupplyPerDayReset();

    /**
     * @dev Returns the total supply of tokens.
     * @return uint16 Total supply of tokens.
     */
    function supply() external view returns (uint16) {
        return sm.supply();
    }

    /**
     * @dev Returns the number of tokens used from the total supply.
     * @return uint16 Number of tokens used from the total supply.
     */
    function supplyUsed() external view returns (uint16) {
        return sm.supplyUsed();
    }

    /**
     * @dev Returns the total reserved supply of tokens.
     * @return uint16 Total reserved supply of tokens.
     */
    function reservedSupply() external view returns (uint16) {
        return sm.reservedSupply();
    }

    /**
     * @dev Returns the number of tokens used from the reserved supply.
     * @return uint16 Number of tokens used from the reserved supply.
     */
    function reservedSupplyUsed() external view returns (uint16) {
        return sm.reservedSupplyUsed();
    }

}