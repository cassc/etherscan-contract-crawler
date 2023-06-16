// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../Common/Context.sol";
import "../ERC20/ERC20Custom.sol";
import "../ERC20/IERC20.sol";
import "../XUSD/XUSD.sol";
import "../Math/SafeMath.sol";

contract XUSDShares is ERC20Custom {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    
    uint256 public constant genesis_supply = 500e18; // 500 is printed to bootstrap uniswap pool

    address public owner_address;
    address public oracle_address;
    address public timelock_address; // Governance timelock address
    XUSDStablecoin private XUSD;


    // LP staking reward pools
    mapping (address => bool) public rewardPools;
    // LP staking pool max reward
    mapping (address => uint256) public rewardCapOf;
    mapping (address => uint256) public rewardedAmountOf;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(XUSD.xusd_pools(msg.sender) == true, "Only xusd pools can mint new XUS");
        _;
    }

    modifier onlyRewardPools() {
        require(rewardPools[msg.sender] == true, "Only staking reward pools can mint new XUS");
        _;
    }
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol, 
        address _oracle_address,
        address _timelock_address
    ) public {
        name = _name;
        symbol = _symbol;
        owner_address = msg.sender;
        oracle_address = _oracle_address;
        timelock_address = _timelock_address;
        _mint(owner_address, genesis_supply);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setOracle(address new_oracle) external onlyByOwnerOrGovernance {
        oracle_address = new_oracle;
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }
    
    function setXUSDAddress(address xusd_contract_address) external onlyByOwnerOrGovernance {
        XUSD = XUSDStablecoin(xusd_contract_address);
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function addRewardPool(address pool_address, uint256 reward_cap) external onlyByOwnerOrGovernance {
        require(rewardPools[pool_address] == false, "address already exists");
        rewardPools[pool_address] = true;
        rewardCapOf[pool_address] = reward_cap;
        rewardedAmountOf[pool_address] = 0;
    }

    function setRewardCap(address pool_address, uint256 reward_cap) external onlyByOwnerOrGovernance {
        require(rewardPools[pool_address] == true, "address not exist");
        rewardCapOf[pool_address] = reward_cap;
    }

    function removeRewardPool(address pool_address) external onlyByOwnerOrGovernance {
        require(rewardPools[pool_address] == true, "address not exist");
        rewardPools[pool_address] = false;
        rewardCapOf[pool_address] = 0;
    }

    function mint_reward(address to, uint256 amount) public onlyRewardPools {
        require(rewardedAmountOf[msg.sender].add(amount) < rewardCapOf[msg.sender]);
        rewardedAmountOf[msg.sender] = rewardedAmountOf[msg.sender].add(amount);
        _mint(to, amount);
    }

    function mint(address to, uint256 amount) public onlyPools {
        _mint(to, amount);
    }
    
    // This function is what other xusd pools will call to mint new XUS (similar to the XUSD mint) 
    function pool_mint(address m_address, uint256 m_amount) external onlyPools {        
        super._mint(m_address, m_amount);
        emit XUSMinted(address(this), m_address, m_amount);
    }

    // This function is what other xusd pools will call to burn XUS 
    function pool_burn_from(address b_address, uint256 b_amount) external onlyPools {
        super._burnFrom(b_address, b_amount);
        emit XUSBurned(b_address, address(this), b_amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    // Track XUS burned
    event XUSBurned(address indexed from, address indexed to, uint256 amount);

    // Track XUS minted
    event XUSMinted(address indexed from, address indexed to, uint256 amount);

}