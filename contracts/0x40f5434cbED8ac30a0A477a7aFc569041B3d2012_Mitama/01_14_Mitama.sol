// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 *  ___  ___ _____  _____   ___  ___  ___  ___  
 *  |  \/  ||_   _||_   _| / _ \ |  \/  | / _ \ 
 *  | .  . |  | |    | |  / /_\ \| .  . |/ /_\ \
 *  | |\/| |  | |    | |  |  _  || |\/| ||  _  |
 *  | |  | | _| |_   | |  | | | || |  | || | | |
 *  \_|  |_/ \___/   \_/  \_| |_/\_|  |_/\_| |_/
 * 
 * produced by http://mitama-mint.com/
 * inspired by Kiwami.sol
 * written by zkitty.eth
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MerkleWhitelist.sol";
import "./DAHelper.sol";

contract Mitama is ERC721A, ERC2981, Ownable, MerkleWhitelist, ReentrancyGuard{
    using Strings for uint256;
    using Strings for uint8;

    /**
     * Mitama Dutch Auction configration: configured by the team at deployment.
     */
    uint256 public DA_STARTING_PRICE = 0.25 ether;
    uint256 public DA_ENDING_PRICE = 0.07 ether;
    // Decrement 0.015 ether every 1 hours ~= 0.00002 ether every 5 sec.
    uint256 public DA_DECREMENT = 0.00002 ether;
    uint256 public DA_DECREMENT_FREQUENCY = 5;
    // Mint starts: Sunday, October 30, 2022 9:00:00 PM GMT+09:00: 1667131200
    uint256 public DA_STARTING_TIMESTAMP = 1667131200;
    uint256 public DA_QUANTITY = 8580;
    // wait 1 week:
    uint256 public WAITING_FINAL_WITHDRAW = 60*60*24*7;
    // Withdraw address
    address public TEAM_WALLET = 0x7a1Bf181867703d6Fe21BaDf71e68D704751672A;

    /**
     * Mitama NFT configuration: configured by the team at deployment.
     */
    uint256 public TOKEN_QUANTITY = 10000;
    uint256 public FREE_MINT_QUANTITY = 420;
    uint256 public MAX_MINTS_PUBLIC = 1;
    uint256 public MAX_MINTS_NORMAL_WL = 2;
    uint256 public MAX_MINTS_SPECIAL_WL = 1;
    uint256 public DISCOUNT_PERCENT_NORMAL_WL = 10;
    uint256 public DISCOUNT_PERCENT_SPECIAL_WL = 30;
    
    /**
     * Internal storages for Dutch Auction
     */
    uint256 public DA_FINAL_PRICE;
    // How many each WL have been minted
    uint16 public PUBLIC_MINTED;
    uint16 public NORMAL_WL_MINTED;
    uint16 public SPECIAL_WL_MINTED;
    // Withdraw status
    bool public INITIAL_FUNDS_WITHDRAWN;
    bool public REMAINING_FUNDS_WITHDRAWN;
    // Event:
    event DAisFinishedAtPrice(uint256 finalPrice);
    //Struct for storing batch price data.
    //userAddress to token price data
    mapping(address => TokenBatchPrice[]) public userToTokenBatchPrices;
    mapping(address => TokenBatchPrice[]) public normalWLToTokenBatchPrices;
    mapping(address => TokenBatchPrice[]) public specialWLToTokenBatchPrices;
    mapping(address => bool) public userToHasMintedFreeMint;

    /**
     * Internal storages for NFT Collection
     */
    // tokenURI
    string public baseURI;
    string public UNREVEALED_URI;
    bool public REVEALED;
    // auraLevel by tokenId
    mapping(uint256 => uint8) public auraLevel;

    /**
     * ERC2981 Rolyalty Standard
     */ 
    address public receiver = TEAM_WALLET;
    uint96 public feeNumerator = 330;

    /**
     * Custom error
     */
    error DAIsNotStarted();
    error DAMustBeOver();
    error InvalidTiming();
    error InsuficientFunds(uint256 actual, uint256 expect);
    error ExceedsMaxMint();
    error ExceedsMaxSupply();
    error InvalidMintRequest();
    error TransferFailed();
    error InvalidTokenId();

    /**
     * Initializate contract
     */
    constructor(
        string memory _unrevealedURI
    ) ERC721A ('Mitama', 'MTM') {
        setRevealData(false, _unrevealedURI);
    }
    
    /**
     * Mint
     */

    function currentPrice() public view returns (uint256) {
        if(block.timestamp < DA_STARTING_TIMESTAMP) revert DAIsNotStarted();

        if (DA_FINAL_PRICE > 0) return DA_FINAL_PRICE;

        //Seconds since we started
        uint256 timeSinceStart = block.timestamp - DA_STARTING_TIMESTAMP;

        //How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart / DA_DECREMENT_FREQUENCY;

        //How much eth to remove
        uint256 totalDecrement = decrementsSinceStart * DA_DECREMENT;

        //If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= DA_STARTING_PRICE - DA_ENDING_PRICE) {
            return DA_ENDING_PRICE;
        }

        //If not, return the starting price minus the decrement.
        return DA_STARTING_PRICE - totalDecrement;
    }

    function mintDAPublic (uint8 quantity) public payable {
        if(!canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_PUBLIC, userToTokenBatchPrices))
            revert InvalidMintRequest();
        userToTokenBatchPrices[msg.sender].push(
            TokenBatchPrice(uint128(msg.value), quantity)
        );
        PUBLIC_MINTED += quantity;
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }
    
    function mintDANormalWL(bytes32[] calldata merkleProof, uint8 quantity)
        public
        payable 
        onlyNormalWhitelist(merkleProof)
    {
        if(!canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_NORMAL_WL, normalWLToTokenBatchPrices))
            revert InvalidMintRequest();
        normalWLToTokenBatchPrices[msg.sender].push(
            TokenBatchPrice(uint128(msg.value), quantity)
        );
        NORMAL_WL_MINTED += quantity;
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }


    /* Mint for Special WL */
    function mintSpecialWL(bytes32[] calldata merkleProof, uint8 quantity)
        public
        payable 
        onlySpecialWhitelist(merkleProof)
    {
        if(!canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_SPECIAL_WL, specialWLToTokenBatchPrices))
            revert InvalidMintRequest();
        specialWLToTokenBatchPrices[msg.sender].push(
            TokenBatchPrice(uint128(msg.value), quantity)
        );
        SPECIAL_WL_MINTED += quantity;
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }

    function freeMint(bytes32[] memory proof)
        public
        onlyFreeMintWhitelist(proof)
    {
        if(DA_FINAL_PRICE == 0) revert DAMustBeOver();
        if(userToHasMintedFreeMint[msg.sender]) revert ExceedsMaxMint();

        //Require max supply just in case.
        if(totalSupply() + 1 > TOKEN_QUANTITY) revert ExceedsMaxSupply();

        userToHasMintedFreeMint[msg.sender] = true;

        //Mint them
        _safeMint(msg.sender, 1);
    }
    
    function teamMint(uint256 quantity, address user) public onlyOwner {
        //Max supply
        if(totalSupply() + quantity > TOKEN_QUANTITY) revert ExceedsMaxSupply();
        if(DA_FINAL_PRICE == 0) revert DAMustBeOver();

        //Mint the quantity
        _safeMint(user, quantity);
    }

    /**
     * Refund and Withdraw
     */

    function withdrawInitialFunds() public onlyOwner nonReentrant{
        //Should be invoked only one time. 
        if(INITIAL_FUNDS_WITHDRAWN)revert("Already invoked.");
        if(DA_FINAL_PRICE == 0) revert DAMustBeOver();

        uint256 DAFunds = DA_QUANTITY * DA_FINAL_PRICE;
        uint256 normalWLRefund = NORMAL_WL_MINTED *
            ((DA_FINAL_PRICE / 100) * 20);
        uint256 specialWLRefund = SPECIAL_WL_MINTED *
            ((DA_FINAL_PRICE / 100) * 20);
        
        uint256 initialFunds = DAFunds - normalWLRefund - specialWLRefund;

        INITIAL_FUNDS_WITHDRAWN = true;

        (bool succ, ) = payable(TEAM_WALLET).call{
            value: initialFunds
        }("");
        if(!succ) revert TransferFailed();
    }

    function withdrawFinalFunds() public onlyOwner nonReentrant{
        //Should 1 weeks after DA Starts.
        if(block.timestamp < DA_STARTING_TIMESTAMP + WAITING_FINAL_WITHDRAW)
            revert InvalidTiming();

        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(TEAM_WALLET).call{
            value: finalFunds
        }("");
        if(!succ) revert TransferFailed();
    }

    /* Refund by owner */
    function refundExtraETH() public nonReentrant{
        if(DA_FINAL_PRICE == 0) revert DAMustBeOver();

        uint256 publicRefund = DAHelper._getRefund(msg.sender, userToTokenBatchPrices, 0, DA_FINAL_PRICE);
        uint256 normalWLRefund = DAHelper._getRefund(msg.sender, normalWLToTokenBatchPrices, DISCOUNT_PERCENT_NORMAL_WL, DA_FINAL_PRICE);
        uint256 specialWLRefund = DAHelper._getRefund(msg.sender, specialWLToTokenBatchPrices, DISCOUNT_PERCENT_SPECIAL_WL, DA_FINAL_PRICE);
        uint256 totalRefund = publicRefund + normalWLRefund + specialWLRefund;

        if(totalRefund > address(this).balance) revert('Contract runs out of funds.');
        payable(msg.sender).transfer(totalRefund);
    }


    /**
     * Update NFT's AuraLevel
     */
    function updateAuraLevel(uint256 tokenId, uint8 level) public onlyOwner {
        if(!_exists(tokenId)) revert InvalidTokenId();
        if(6 > level || level < auraLevel[tokenId]) revert ('Invalid Aura Level.');
        auraLevel[tokenId] = level;
    }

    /**
     * Internal functions for Dutch Auction
     */

    function canMintDA(
        address user,
        uint256 amount,
        uint8 quantity, 
        uint256 _MAX_MINT,
        mapping(address => TokenBatchPrice[]) storage _userToTokenBatchPrices
    ) internal returns (bool) {
        if(block.timestamp < DA_STARTING_TIMESTAMP) revert DAIsNotStarted();

        if(_userToTokenBatchPrices[user].length > _MAX_MINT -1) {
            revert ExceedsMaxMint();
        } else if(_userToTokenBatchPrices[user].length > 0){
            if(_userToTokenBatchPrices[user].length > _MAX_MINT)
                revert ExceedsMaxMint();         
        } else if(quantity > _MAX_MINT){
            revert ExceedsMaxMint();
        }

        uint256 _currentPrice = currentPrice();

        //Require enough ETH
        if(amount < quantity * _currentPrice) revert InsuficientFunds(amount, quantity * _currentPrice);

        //Max supply
        if(totalSupply() + quantity > DA_QUANTITY) revert ExceedsMaxSupply();

        //This is the final price
        if (totalSupply() + quantity == DA_QUANTITY) {
            DA_FINAL_PRICE = _currentPrice;
            emit DAisFinishedAtPrice(DA_FINAL_PRICE);
        }
        return true;
    }
    
    /**
     * House keeping funcitons
     */
    
    /* ERC721 Setters */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    
    function setRevealData(bool _revealed, string memory _unrevealedURI)
        public
        onlyOwner
    {
        REVEALED = _revealed;
        UNREVEALED_URI = _unrevealedURI;
    }

    /* ERC721 primitive */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) revert InvalidTokenId();
        uint8 auraLevel_ = auraLevel[tokenId];
        if (REVEALED){
            return bytes(baseURI).length > 0 
                ? string(abi.encodePacked(baseURI, tokenId.toString(), "-", auraLevel_.toString())) 
                : "";
        } else {
            return UNREVEALED_URI;           
        }
    }
    
    /**
    * inherited: ERC2981 Royalty Standard
    */ 
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
        receiver = _receiver;
        feeNumerator = _feeNumerator;
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    //inherited: {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}