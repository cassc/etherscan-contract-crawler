// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../ERC20/ERC20Custom.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../XSD/XSDStablecoin.sol";

contract BankXToken is ERC20Custom {

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    
    
    uint256 public genesis_supply; // 2B is printed upon genesis
    address public pool_address; //points to BankX pool address
    address public treasury; //stores the genesis supply
    address public router;
    XSDStablecoin private XSD; //XSD stablecoin instance
    address public smartcontract_owner;
    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(XSD.xsd_pools(msg.sender) == true, "Only xsd pools can mint new BankX");
        _;
    } 
    
    modifier onlyByOwner() {
        require(msg.sender == smartcontract_owner, "You are not an owner");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _pool_amount, 
        uint256 _genesis_supply,
        address _treasury,
        address _smartcontract_owner
    ) {
        require((_treasury != address(0)), "Zero address detected"); 
        name = _name;
        symbol = _symbol;
        genesis_supply = _genesis_supply + _pool_amount;
        treasury = _treasury;
        _mint(_msgSender(), _pool_amount);
        _mint(treasury, _genesis_supply);
        smartcontract_owner = _smartcontract_owner;

    
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setPool(address new_pool) external onlyByOwner {
        require(new_pool != address(0), "Zero address detected");

        pool_address = new_pool;
    }

    function setTreasury(address new_treasury) external onlyByOwner {
        require(new_treasury != address(0), "Treasury address cannot be 0");
        treasury = new_treasury;
    }

    function setRouterAddress(address _router) external onlyByOwner {
        require(_router != address(0), "Zero address detected");
        router = _router;
    }
    
    function setXSDAddress(address xsd_contract_address) external onlyByOwner {
        require(xsd_contract_address != address(0), "Zero address detected");

        XSD = XSDStablecoin(xsd_contract_address);

        emit XSDAddressSet(xsd_contract_address);
    }
    
    function mint(address to, uint256 amount) public onlyPools {
        _mint(to, amount);
        emit BankXMinted(address(this), to, amount);
    }
    
    function genesisSupply() public view returns(uint256){
        return genesis_supply;
    }

    // This function is what other xsd pools will call to mint new BankX (similar to the XSD mint) 
    function pool_mint(address m_address, uint256 m_amount) external onlyPools  {        
        super._mint(m_address, m_amount);
        emit BankXMinted(address(this), m_address, m_amount);
    }

    // This function is what other xsd pools will call to burn BankX 
    function pool_burn_from(address b_address, uint256 b_amount) external onlyPools {

        super._burnFrom(b_address, b_amount);
        emit BankXBurned(b_address, address(this), b_amount);
    }
    //burn bankx from the pool when bankx is inflationary
    function burnpoolBankX(uint _bankx_amount) public {
        require(msg.sender == router, "Only Router can access this function");
        require(totalSupply()>genesis_supply,"BankX must be deflationary");
        super._burn(pool_address, _bankx_amount);
        IBankXWETHpool(pool_address).sync();
        emit BankXBurned(msg.sender, address(this), _bankx_amount);
    }

    function setSmartContractOwner(address _smartcontract_owner) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(msg.sender != address(0), "Zero address detected");
        smartcontract_owner = _smartcontract_owner;
    }

    function renounceOwnership() external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        smartcontract_owner = address(0);
    }
    /* ========== EVENTS ========== */

    // Track BankX burned
    event BankXBurned(address indexed from, address indexed to, uint256 amount);

    // Track BankX minted
    event BankXMinted(address indexed from, address indexed to, uint256 amount);
    event XSDAddressSet(address addr);
}