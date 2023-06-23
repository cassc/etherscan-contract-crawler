// SPDX-License-Identifier: MIT
// Author: sqrtofpi (square root of pi) https://twitter.com/sqrt_of_pi_314

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CHROMAMORPHS is
    ERC1155,
    Ownable,
    PaymentSplitter
{
    using SafeMath for uint256;
    using SafeMath for uint16;

    uint256 public MAX_AC_SUPPLY = 100;
    uint256 public MAX_REG_SUPPLY = 233;
    uint256 public MAX_COL_SUPPLY = 100;
    uint256 public COL_TOKEN_ID = MAX_AC_SUPPLY + MAX_REG_SUPPLY + 1;

    uint256 public MAX_SUPPLY = MAX_AC_SUPPLY+MAX_REG_SUPPLY + MAX_COL_SUPPLY;

    uint256 public AC_MINT_COUNT = 0;
    uint256 public REG_MINT_COUNT = 0;
    uint256 public COLLECTOR_MINT_COUNT = 0;
    
    uint256[] reg_mint_order;
    bool mint_order_created = false;
    bool permanent_end_AC_sale = false;

    uint16 _maxPurchaseCount = 5;
    uint256 _mintPrice = 0.08 ether;
    string _baseURIValue;

    mapping(uint256 => address) _AC_owner;
    mapping(uint256 => bool) _AC_claimed;
    mapping(uint256 => bool) _REG_claimed;
    mapping(uint256 => bool) _COL_claimed;
    mapping(uint256 => bool) _AC_added;
    uint256[] registeredACs;

    bool public saleIsActive = false;
    bool public ACsaleIsActive = false;
    bool public CMsaleIsActive = false;

    // Splitter inputs
    address LCLMACHINE = 0x78eF20A8aBc67E4E1B8C882D332D58154F242E27;
    uint256 LCLMACHINE_SHARE = 40;
    address TANGO = 0xf7CBbA9dACF655e16f3226b280301907f2d30CCF;
    uint256 TANGO_SHARE = 40;
    address SQRTOFPI = 0xDb214A3FD7f81c68bfb74047D6e02d11dc0E2076;
    uint256 SQRTOFPI_SHARE = 20;
    
    address[] payee_addresses = [LCLMACHINE,TANGO,SQRTOFPI];
    uint256[] payee_shares = [LCLMACHINE_SHARE,TANGO_SHARE,SQRTOFPI_SHARE];

    constructor() ERC1155("") PaymentSplitter(payee_addresses, payee_shares) {}

    function setBaseURI(string memory newBase) public onlyOwner {
        _baseURIValue = newBase;
    }

    function uri(uint256 _tokenID) public view override returns (string memory) {
    return string(abi.encodePacked(_baseURIValue, Strings.toString(_tokenID),".json"));

    }
    
    // Toggles for Sale and Presale states
    function startSaleState() public onlyOwner {
        require(mint_order_created, "mint order not yet created");
        saleIsActive = true;

    }

    function stopSaleState() public onlyOwner {
        saleIsActive = false;
    }
    
    function startACSaleState() public onlyOwner {
        require(!permanent_end_AC_sale, "AC sale permanently ended");
        ACsaleIsActive = true;
        CMsaleIsActive = true;
    }

    function stopACSaleState() public onlyOwner {
        ACsaleIsActive = false;
    }

    function startCOLSaleState() public onlyOwner {
        CMsaleIsActive = true;
    }

    function stopCOLSaleState() public onlyOwner {
        CMsaleIsActive = false;
    }

    // getters and setters for minting limits
    function maxPurchaseCount() public view returns (uint256) {
        return _maxPurchaseCount;
    }

    function setMaxPurchaseCount(uint16 count) public onlyOwner {
        _maxPurchaseCount = count;
    }

    function create_mint_order() public onlyOwner {
        require(!mint_order_created, "already created mint order");
        ACsaleIsActive = false;
        permanent_end_AC_sale = true;

        for (uint256 i = 1; i < registeredACs.length + 1; i++){
            if (_AC_added[i] && !_AC_claimed[i]){
            reg_mint_order.push(i);
            }
        }

        for (uint256 i = MAX_REG_SUPPLY+MAX_AC_SUPPLY; i > MAX_AC_SUPPLY; i--){
            reg_mint_order.push(i);
        }

        mint_order_created = true;
    }

    function getRegisteredLength() public view returns (uint256){
        return registeredACs.length;
    }

    function getMintOrderLength() public view returns (uint256){
        return reg_mint_order.length;
    }

    function getMintOrderItem(uint256 item) public view returns (uint256){
        return reg_mint_order[item];
    }
    
    // getters and setters for mint price
    function baseMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setBaseMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function mintPrice(uint256 numberOfTokens) public view returns (uint256) {
        return _mintPrice.mul(numberOfTokens);
    }
    
    
    // Validate AC holders
    function addACOwners(uint8[] calldata ACtokenIDs,address[] calldata addresses) external onlyOwner{
        require(ACtokenIDs.length == addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            require(ACtokenIDs[i]>=1 && ACtokenIDs[i] <= MAX_AC_SUPPLY);

            _AC_owner[ACtokenIDs[i]] = addresses[i];
            if (!_AC_added[ACtokenIDs[i]]){
                _AC_added[ACtokenIDs[i]] = true;
                registeredACs.push(ACtokenIDs[i]);
            }
        }
    }
    
    
    function ownsAllACs(uint256[] calldata requested_tokens) public view returns (bool) {
        for (uint256 i = 0; i < requested_tokens.length; i++) {
            require(_AC_owner[requested_tokens[i]] == msg.sender);
        }
        return true;
    }
    
    function checkIfACclaimed(uint256 AC_id) public view returns (bool) {
           return _AC_claimed[AC_id];
    }

    function checkIfCOLclaimed(uint256 AC_id) public view returns (bool) {
           return _COL_claimed[AC_id];
    }

    function getOwnerOfAC(uint256 AC_id) public view returns (address) {
        return _AC_owner[AC_id];
    }
    
    // MODIFIERS
    modifier REGmintCountMeetsSupply(uint256 numberOfTokens) {
        require(
            numberOfTokens <= reg_mint_order.length,
            "Purchase would exceed remaining supply"
        );
        _;
    }
    

    modifier doesNotExceedMaxPurchaseCount(uint256 numberOfTokens) {
        require(
            numberOfTokens <= _maxPurchaseCount,
            "Cannot mint more than 5 token at a time"
        );
        _;
    }

    modifier validatePurchasePrice(uint256 numberOfTokens) {
        require(
            mintPrice(numberOfTokens) == msg.value,
            "Ether value sent is not correct"
        );
        _;
    }


    // Minting Functions
    
    // Minting Functions: internals

    // mint Chromamorph by the owner of the corresponding AutoChroma holder
    function _mintCMTokensfromAC(uint256[] calldata tokens_to_mint, address to)
        internal
    {
        for (uint256 i = 0; i < tokens_to_mint.length; i++) {
            require(tokens_to_mint[i]<=MAX_AC_SUPPLY);
            require(!_AC_claimed[tokens_to_mint[i]]);
            _AC_claimed[tokens_to_mint[i]] = true;
            _mint(to, tokens_to_mint[i],1,"");
            AC_MINT_COUNT +=1;
        }
    }

    function _mintREGTokens(uint256 numberOfTokens, address to) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 token_id = reg_mint_order[reg_mint_order.length-1];
            require(!_REG_claimed[token_id]);
            _REG_claimed[token_id] = true;
            reg_mint_order.pop();
            _mint(to, token_id,1,"");
            REG_MINT_COUNT += 1;
        }
    }

    // mint Collectos Edition by the owner of the corresponding AutoChroma holder
    function _mintCOLTokens(uint256[] calldata tokens_to_mint, address to)
        internal
    {
        for (uint256 i = 0; i < tokens_to_mint.length; i++) {
            require(!_COL_claimed[tokens_to_mint[i]]);
            _COL_claimed[tokens_to_mint[i]] = true;
            _mint(to, COL_TOKEN_ID,1,"");        
            COLLECTOR_MINT_COUNT +=1;
        }
    }
    
    // Minting Functions: public

    function ContractOwnerMint(uint256 numberOfTokens)
        public
        REGmintCountMeetsSupply(numberOfTokens)
        onlyOwner
    {
        require(mint_order_created, "mint order not created yet");
        _mintREGTokens(numberOfTokens, msg.sender);
    }

    
    function mintAutochromaOwner(uint256[] calldata tokens_to_mint)
        public
        payable
        validatePurchasePrice(tokens_to_mint.length)
    {
        require(ACsaleIsActive, "Sale has not started yet");
        require(ownsAllACs(tokens_to_mint));
        _mintCMTokensfromAC(tokens_to_mint, msg.sender);
    }
    
    function mintCollectors(uint256[] calldata tokens_to_mint)
        public
    {
        require(CMsaleIsActive, "Sale has not started yet");
        require(ownsAllACs(tokens_to_mint));
        _mintCOLTokens(tokens_to_mint, msg.sender);
    }
    
    function mintMorphs(uint256 numberOfTokens)
        public
        payable
        REGmintCountMeetsSupply(numberOfTokens)
        doesNotExceedMaxPurchaseCount(numberOfTokens)
        validatePurchasePrice(numberOfTokens)
    {
        require(saleIsActive, "Sale has not started yet");
        require(mint_order_created, "mint order not created yet");
        _mintREGTokens(numberOfTokens, msg.sender);
    }
    
}