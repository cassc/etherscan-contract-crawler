// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Contract {
    function transfer_presale(address _wallet, uint256 amount) external returns (bool);
}

contract Presale is AccessControl {

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address public zfx_contract_address; 
    IERC20 public usd_contract;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    uint256 public presale_supply = 400_000_000 * 1 ether; 
    uint256 public presale_min_usd_purchase = 30 * 1 ether;
    uint256 public presale_max_usd_purchase = 1_200 * 1 ether; 

    uint256 public zfx_value_per_usd = 334;

    bool public presale_status = true;

    uint256 public presale_total_usd_purchased;
    mapping(address => uint256) public wallet_addresses_usd_purchased; 
    mapping(address => uint256) public wallet_addresses_zfx_purchased;

    event Purchased(address _wallet, uint256 _value);

    function purchase(uint256 amount) external {
        require(presale_status, "Presale is closed!");
        require(amount >= presale_min_usd_purchase,"Amount must be greater than or equal to minimum purchase amount.");
        require(amount <= presale_max_usd_purchase,"Amount must be less than or equal to maximum purchase amount.");
        
        uint256 total_zfx = (amount * zfx_value_per_usd);
        require(usd_contract.balanceOf(msg.sender) >= amount, "Insufficient usd balance.");     
        require((presale_supply - total_zfx)  >= 0, "Not enough supply");  
           
        presale_total_usd_purchased = presale_total_usd_purchased + amount;
        wallet_addresses_usd_purchased[msg.sender] = wallet_addresses_usd_purchased[msg.sender] + amount;
        wallet_addresses_zfx_purchased[msg.sender] = wallet_addresses_zfx_purchased[msg.sender] + total_zfx;
        presale_supply = presale_supply - total_zfx;

        usd_contract.transferFrom(msg.sender,address(this), amount);

        Contract _contract = Contract(zfx_contract_address);
        _contract.transfer_presale(msg.sender, total_zfx);

        emit Purchased(msg.sender,total_zfx);
    }

    function set_zfx_contract_address(address _contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
       zfx_contract_address = _contract;
    }

    function set_usd_contract_address(address _contract) external onlyRole(DEFAULT_ADMIN_ROLE){
       usd_contract = IERC20(_contract);
    }

    function set_presale_min_usd_purchase(uint256 _amount)  external onlyRole(DEFAULT_ADMIN_ROLE){
        presale_min_usd_purchase = _amount;
    }
    function set_presale_max_usd_purchase(uint256 _amount)  external onlyRole(DEFAULT_ADMIN_ROLE){
        presale_max_usd_purchase = _amount;
    }
   
    function set_zfx_value_per_usd(uint256 _amount)  external onlyRole(DEFAULT_ADMIN_ROLE){
        zfx_value_per_usd = _amount;
    }

    function set_presale_status() external onlyRole(PAUSER_ROLE){
        presale_status = !presale_status;
    }

    function burn_supply(uint256 _amount)  external onlyRole(BURNER_ROLE){
      
        presale_supply = presale_supply - _amount;

        Contract _contract = Contract(zfx_contract_address);
        _contract.transfer_presale(0x000000000000000000000000000000000000dEaD, _amount);

    }
   
    function transfer_native(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        payable(msg.sender).transfer(_amount);
    }

    function transfer_usd() external onlyRole(DEFAULT_ADMIN_ROLE) {
        usd_contract.transfer(msg.sender,usd_contract.balanceOf(address(this)));
    }
}