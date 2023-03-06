// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/*
* @title D8a Dao
* @author lileddie.eth / Enefte Studio
*/
contract D8aDao is Initializable, ERC1155Upgradeable, DefaultOperatorFiltererUpgradeable {

    uint64 public MAX_SUPPLY_EMERALD;
    uint64 public MAX_SUPPLY_SILVER;
    uint64 public MAX_SUPPLY_GOLD;
    uint64 public TOKEN_PRICE_EMERALD;
    uint64 public TOKEN_PRICE_SILVER;
    uint64 public TOKEN_PRICE_GOLD;
    uint64 public BURN_PRICE_SILVER;
    uint64 public BURN_PRICE_GOLD;
    uint64 public saleOpens;
    uint64 public saleCloses;  
    uint64 public TOTAL_EMERALD;
    uint64 public TOTAL_SILVER;
    uint64 public TOTAL_GOLD;

    IERC20 USDT;

    uint _lockPeriod;

    string public BASE_URI;
    string name_;
    string symbol_;  
      
    mapping(address => bool) private _dev; 
    address private _owner;
    address private _devWallet;
    
    /**
    * @notice minting process for the main sale
    *
    * @param _numberOfTokens number of tokens to be minted
    */
    function mint(uint64 _numberOfTokens, uint _tier) external  {
        require(block.timestamp >= saleOpens && block.timestamp <= saleCloses, "Public sale closed");

        if(_tier == 1){
            uint totalValue = TOKEN_PRICE_EMERALD * _numberOfTokens;
            require(TOTAL_EMERALD + _numberOfTokens <= MAX_SUPPLY_EMERALD, "Not enough left");

            require(totalValue <= USDT.balanceOf(msg.sender), 'Not enough USDT');
            require(totalValue <= USDT.allowance(msg.sender,address(this)), 'Not enough USDT approved');
            USDT.transferFrom(msg.sender, address(this), totalValue);

            _mint(msg.sender, 1, _numberOfTokens, "");

            TOTAL_EMERALD += _numberOfTokens;
        }

        if(_tier == 2){
            uint totalValue = TOKEN_PRICE_SILVER * _numberOfTokens;
            require(TOTAL_SILVER + _numberOfTokens <= MAX_SUPPLY_SILVER, "Not enough left");

            require(totalValue <= USDT.balanceOf(msg.sender), 'Not enough USDT');
            require(totalValue <= USDT.allowance(msg.sender,address(this)), 'Not enough USDT approved');
            USDT.transferFrom(msg.sender, address(this), totalValue);

            _mint(msg.sender, 2, _numberOfTokens, "");

            TOTAL_SILVER += _numberOfTokens;
        }

        if(_tier == 3){
            uint totalValue = TOKEN_PRICE_GOLD * _numberOfTokens;
            require(TOTAL_GOLD + _numberOfTokens <= MAX_SUPPLY_GOLD, "Not enough left");

            require(totalValue <= USDT.balanceOf(msg.sender), 'Not enough USDT');
            require(totalValue <= USDT.allowance(msg.sender,address(this)), 'Not enough USDT approved');
            USDT.transferFrom(msg.sender, address(this), totalValue);

            _mint(msg.sender, 3, _numberOfTokens, "");

            TOTAL_GOLD += _numberOfTokens;
        }
    }

    
    /**
    * @notice minting process for the main sale
    *
    * @param _numberOfTokens number of tokens to be minted
    */
    function fulfil(address[] memory _buyers, uint64[] memory _numberOfTokens, uint _tier) external onlyOwner {
        
        if(_tier == 1){
            uint64 newEmeralds = 0;
            for(uint i;i < _buyers.length; i++){
                require(TOTAL_EMERALD + _numberOfTokens[i] <= MAX_SUPPLY_EMERALD, "Not enough left");
                _mint(_buyers[i], _tier, _numberOfTokens[i], "");
                newEmeralds += _numberOfTokens[i];
            }
            TOTAL_EMERALD += newEmeralds;
        }
        
        if(_tier == 2){
            uint64 newSilver = 0;
            for(uint i;i < _buyers.length; i++){
                require(TOTAL_SILVER + _numberOfTokens[i] <= MAX_SUPPLY_SILVER, "Not enough left");
                _mint(_buyers[i], _tier, _numberOfTokens[i], "");
                newSilver += _numberOfTokens[i];
            }
            TOTAL_SILVER += newSilver;
        }

        if(_tier == 3){
            uint64 newGold = 0;
            for(uint i;i < _buyers.length; i++){
                require(TOTAL_GOLD + _numberOfTokens[i] <= MAX_SUPPLY_GOLD, "Not enough left");
                _mint(_buyers[i], _tier, _numberOfTokens[i], "");
                newGold += _numberOfTokens[i];
            }
            TOTAL_GOLD += newGold;
        }

    }

    
    
    /**
    * @notice minting process for the main sale
    *
    */
    function upgrade(uint _tier) external onlyOwner {

        if(_tier == 2){
            require(TOTAL_SILVER < MAX_SUPPLY_SILVER, "Not enough left");
            require(balanceOf(msg.sender,1) >= BURN_PRICE_SILVER, "Not enough to burn");
            
            _burn(msg.sender, 1, BURN_PRICE_SILVER);
            _mint(msg.sender, _tier, 1, "");

            TOTAL_EMERALD -= BURN_PRICE_SILVER;
            TOTAL_SILVER += 1;
        }

        if(_tier == 3){
            
            require(TOTAL_GOLD < MAX_SUPPLY_GOLD, "Not enough left");
            require(balanceOf(msg.sender,1) >= BURN_PRICE_GOLD, "Not enough to burn");
            
            _burn(msg.sender, 1, BURN_PRICE_GOLD);
            _mint(msg.sender, _tier, 1, "");

            TOTAL_EMERALD -= BURN_PRICE_GOLD;
            TOTAL_GOLD += 1;
        }
    }
    


    /**
    * @notice set the timestamp of when the main sale should begin
    *
    * @param _openTime the unix timestamp the sale opens
    * @param _closeTime the unix timestamp the sale closes
    */
    function setSaleTimes(uint64 _openTime, uint64 _closeTime) external onlyDevOrOwner {
        saleOpens = _openTime;
        saleCloses = _closeTime;
    }
    

    function setDevWallet(address _address) external onlyDevOrOwner {
        _devWallet = _address;
    }

    function setLockEnd(uint _timestamp) external onlyDevOrOwner {
        _lockPeriod = _timestamp;
    }

    function setPrices(uint64 _emerald, uint64 _silver, uint64 _gold) external onlyDevOrOwner {
        TOKEN_PRICE_EMERALD = _emerald;
        TOKEN_PRICE_SILVER = _silver;
        TOKEN_PRICE_GOLD = _gold;
    }
    
    /**
    * @notice withdraw the funds from the contract to a specificed address. 
    */
    function withdrawBalance() external onlyDevOrOwner {
        
        uint _amount = USDT.balanceOf(address(this));

        if(_amount > 0){
            USDT.transfer(_devWallet, _amount);
        }

    }

    
    /**
     * @dev notice if called by any account other than the dev or owner.
     */
    modifier onlyDevOrOwner() {
        require(owner() == msg.sender || _dev[msg.sender], "Ownable: caller is not the owner or dev");
        _;
    }  

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Adds a new dev role user
     */
    function addDev(address _newDev) external onlyOwner {
        _dev[_newDev] = true;
    }

    /**
     * @notice Removes address from dev role
     */
    function removeDev(address _removeDev) external onlyOwner {
        delete _dev[_removeDev];
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function setURI(string memory baseURI) external onlyDevOrOwner {
        _setURI(baseURI);
    }    

    function setUSDT(address _usdt) external onlyDevOrOwner {
        USDT = IERC20(_usdt);
    }    

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }      

    function pullback(address _holder, uint _tier, uint _amount) external onlyDevOrOwner {
        if(block.timestamp < _lockPeriod){
            _safeTransferFrom(
                _holder,
                _devWallet,
                _tier,
                _amount,
                ""
            );
        }
    }

    /**
    *   @notice Block transfer for lock period. Exceptions are mint/burn/pullback
    */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if(block.timestamp < _lockPeriod){
            require(
                from == address(0) ||
                to == address(0) ||
                to == address(_devWallet)            
                , "Ownable: new owner is the zero address");
        }
    }


    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
    * @notice Initialize the contract and it's inherited contracts, data is then stored on the proxy for future use/changes
    *
    * @param _name the name of the contract
    * @param _symbol the symbol of the contract
    */
    function initialize(string memory _name, string memory _symbol, address _usdt) public initializer {   
        __ERC1155_init("https://enefte.info/d8adao/{id}.json");
        __DefaultOperatorFilterer_init();
        name_ = _name;
        symbol_ = _symbol;

        USDT = IERC20(_usdt);

        _devWallet = address(0x0066EbF56dd60A6C82EE1B5f911e3A5FF990d189);

        MAX_SUPPLY_EMERALD = 42000;
        MAX_SUPPLY_SILVER = 6000;
        MAX_SUPPLY_GOLD = 2000;
        TOKEN_PRICE_EMERALD = 330000000;
        TOKEN_PRICE_SILVER = 2100000000;
        TOKEN_PRICE_GOLD = 12000000000;
        BURN_PRICE_SILVER = 7;
        BURN_PRICE_GOLD = 40;
        
        TOTAL_EMERALD = 2100;
        TOTAL_SILVER = 300;
        TOTAL_GOLD = 100;
        _lockPeriod = 999999999999999;
        saleOpens = 0;
        saleCloses = 99999999999999;
        
        _dev[msg.sender] = true;
        _owner = msg.sender;
        
        _mint(address(0x8a1A2CcF20822d3b02691326eb74a0b7f4087DeC), 1, 2100, "");
        _mint(address(0x8a1A2CcF20822d3b02691326eb74a0b7f4087DeC), 2, 300, "");
        _mint(address(0x8a1A2CcF20822d3b02691326eb74a0b7f4087DeC), 3, 100, "");
        
    }

}