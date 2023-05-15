// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Zetfinex is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor() ERC20("ZetFinex Token", "ZFX") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(TRANSFER_ROLE, msg.sender);
        _grantRole(TRANSFER_ROLE, address(this));

        _mint(address(this),(5_000_000_000 * 1 ether)); 

        set_date();
    }

    address private wallet_revenue_rewards;
    address private wallet_development;
    address private wallet_marketing;
    address private wallet_reserve;
    address private wallet_devs_team;
    address private wallet_liquidity;

    uint256 public supply_development = 500_000_000 * 1 ether; 
    uint256 public supply_reserve = 250_000_000 * 1 ether;
    uint256 public supply_devs_team = 100_000_000 * 1 ether;

    address public presale_contract_address;
    uint256 public presale_supply = 400_000_000 * 1 ether;
   
    uint256 private constant _06_01_2023 = 1685577600;
    uint256 private constant _07_01_2023 = 1688169600;
    uint256 private constant _08_01_2023 = 1690848000;
    uint256 private constant _09_01_2023 = 1693526400;
    uint256 private constant _10_01_2023 = 1696118400;
    uint256 private constant _11_01_2023 = 1698796800;
    uint256 private constant _12_01_2023 = 1701388800;

    uint256 private constant _01_01_2024 = 1704067200;
    uint256 private constant _02_01_2024 = 1706745600;
    uint256 private constant _03_01_2024 = 1709251200;
    uint256 private constant _04_01_2024 = 1711929600;
    uint256 private constant _05_01_2024 = 1714521600;
    uint256 private constant _06_01_2024 = 1717200000;
    uint256 private constant _07_01_2024 = 1719792000;
    uint256 private constant _08_01_2024 = 1722470400;
    uint256 private constant _09_01_2024 = 1725148800;
    uint256 private constant _10_01_2024 = 1727740800;
    uint256 private constant _11_01_2024 = 1730419200;
    uint256 private constant _12_01_2024 = 1733011200;

    uint256 private constant _01_01_2025 = 1735689600;
    uint256 private constant _02_01_2025 = 1738368000;
    uint256 private constant _03_01_2025 = 1740787200;
    uint256 private constant _04_01_2025 = 1743465600;
    uint256 private constant _05_01_2025 = 1746057600;
    uint256 private constant _06_01_2025 = 1748736000;
    uint256 private constant _07_01_2025 = 1751328000;
    uint256 private constant _08_01_2025 = 1754006400;
    uint256 private constant _09_01_2025 = 1756684800;
    uint256 private constant _10_01_2025 = 1759276800;
    uint256 private constant _11_01_2025 = 1761955200;
    uint256 private constant _12_01_2025 = 1764547200;

    uint256 private constant _01_01_2026 = 1767225600;
    uint256 private constant _02_01_2026 = 1769904000;
    uint256 private constant _03_01_2026 = 1772323200;
    uint256 private constant _04_01_2026 = 1775001600;
    uint256 private constant _05_01_2026 = 1777593600;
    uint256 private constant _06_01_2026 = 1780272000;
    uint256 private constant _07_01_2026 = 1782864000;
    uint256 private constant _08_01_2026 = 1785542400;
    uint256 private constant _09_01_2026 = 1788220800;
    uint256 private constant _10_01_2026 = 1790812800;
    uint256 private constant _11_01_2026 = 1793491200;
    uint256 private constant _12_01_2026 = 1796083200;

    struct data{
      uint256 date;
      uint256 amount;
      bool claimed;
    }

    mapping(string => data[]) public VESTINGS;

    function set_date() private {

        VESTINGS["development"].push(data(_06_01_2024,(50_000_000 * 1 ether),false)); 
        VESTINGS["development"].push(data(_07_01_2024,(50_000_000 * 1 ether),false));
        VESTINGS["development"].push(data(_08_01_2024,(50_000_000 * 1 ether),false));
        VESTINGS["development"].push(data(_09_01_2024,(50_000_000 * 1 ether),false));
        VESTINGS["development"].push(data(_10_01_2024,(50_000_000 * 1 ether),false));
        VESTINGS["development"].push(data(_11_01_2024,(50_000_000 * 1 ether),false));
        VESTINGS["development"].push(data(_12_01_2024,(50_000_000 * 1 ether),false));
        VESTINGS["development"].push(data(_01_01_2025,(50_000_000 * 1 ether),false));
        VESTINGS["development"].push(data(_02_01_2025,(50_000_000 * 1 ether),false));
        VESTINGS["development"].push(data(_03_01_2025,(50_000_000 * 1 ether),false)); 

        VESTINGS["reserve"].push(data(_11_01_2023,(25_000_000 * 1 ether),false));
        VESTINGS["reserve"].push(data(_12_01_2023,(25_000_000 * 1 ether),false));
        VESTINGS["reserve"].push(data(_01_01_2024,(25_000_000 * 1 ether),false));
        VESTINGS["reserve"].push(data(_02_01_2024,(25_000_000 * 1 ether),false));
        VESTINGS["reserve"].push(data(_03_01_2024,(25_000_000 * 1 ether),false)); 
        VESTINGS["reserve"].push(data(_04_01_2024,(25_000_000 * 1 ether),false));
        VESTINGS["reserve"].push(data(_05_01_2024,(25_000_000 * 1 ether),false));
        VESTINGS["reserve"].push(data(_06_01_2024,(25_000_000 * 1 ether),false));
        VESTINGS["reserve"].push(data(_07_01_2024,(25_000_000 * 1 ether),false));
        VESTINGS["reserve"].push(data(_08_01_2024,(25_000_000 * 1 ether),false));

        VESTINGS["devs_team"].push(data(_06_01_2025,(10_000_000 * 1 ether),false));
        VESTINGS["devs_team"].push(data(_07_01_2025,(10_000_000 * 1 ether),false)); 
        VESTINGS["devs_team"].push(data(_08_01_2025,(10_000_000 * 1 ether),false)); 
        VESTINGS["devs_team"].push(data(_09_01_2025,(10_000_000 * 1 ether),false)); 
        VESTINGS["devs_team"].push(data(_10_01_2025,(10_000_000 * 1 ether),false)); 
        VESTINGS["devs_team"].push(data(_11_01_2025,(10_000_000 * 1 ether),false));
        VESTINGS["devs_team"].push(data(_12_01_2025,(10_000_000 * 1 ether),false)); 
        VESTINGS["devs_team"].push(data(_01_01_2026,(10_000_000 * 1 ether),false)); 
        VESTINGS["devs_team"].push(data(_02_01_2026,(10_000_000 * 1 ether),false)); 
        VESTINGS["devs_team"].push(data(_03_01_2026,(10_000_000 * 1 ether),false)); 

    }

    function initial_capital() external onlyRole(DEFAULT_ADMIN_ROLE) {

     _transfer(address(this), wallet_revenue_rewards, (3_000_000_000 * 1 ether));
     _transfer(address(this), wallet_marketing, (250_000_000 * 1 ether));
     _transfer(address(this), wallet_liquidity, (500_000_000 * 1 ether));
     
    }
    
    function transfer_vesting_development() external onlyRole(DEFAULT_ADMIN_ROLE){
      for(uint256 i=0;i < VESTINGS["development"].length;i++){
        data storage _data = VESTINGS["development"][i];
        if(block.timestamp >= _data.date && !_data.claimed ){
          require(supply_development - _data.amount >= 0);
          _data.claimed = true;
          supply_development = supply_development - _data.amount;
          _transfer(address(this), wallet_development, _data.amount);
        }
      }
    }

    function transfer_vesting_reserve() external onlyRole(DEFAULT_ADMIN_ROLE){
      for(uint256 i=0;i < VESTINGS["reserve"].length;i++){
        data storage _data = VESTINGS["reserve"][i];
        if(block.timestamp >= _data.date && !_data.claimed ){
          require(supply_reserve - _data.amount >= 0);
          _data.claimed = true;
          supply_reserve = supply_reserve - _data.amount;
          _transfer(address(this), wallet_reserve, _data.amount);
        }
      }
    }

    function transfer_vesting_devs_team() external onlyRole(DEFAULT_ADMIN_ROLE){
      for(uint256 i=0;i < VESTINGS["devs_team"].length;i++){
        data storage _data = VESTINGS["devs_team"][i];
        if(block.timestamp >= _data.date && !_data.claimed ){
          require(supply_devs_team - _data.amount >= 0);
          _data.claimed = true;
          supply_devs_team = supply_devs_team - _data.amount;
          _transfer(address(this), wallet_devs_team, _data.amount);
        }
      }
    }
   
    function transfer_presale(address _wallet, uint256 amount) external is_presale returns (bool){
        require(presale_supply - amount >= 0,"Not enough supply");
        presale_supply = presale_supply - amount;
        _transfer(address(this), _wallet, amount);
        return true;
    }

    function retVestings(string memory _type) public view returns(data[] memory _vestings, uint256 _time){

      data[] memory _newList = new data[](VESTINGS[_type].length);
      for(uint256 i=0;i < VESTINGS[_type].length;i++){
         data storage vest = VESTINGS[_type][i];
         _newList[i] = vest;
      }
      return (_newList,block.timestamp);
    }

    function set_wallet_revenue_rewards(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      wallet_revenue_rewards = _wallet;
    }

    function set_wallet_development(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      wallet_development = _wallet;
    }

    function set_wallet_marketing(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      wallet_marketing = _wallet;
    }

    function set_wallet_reserve(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      wallet_reserve = _wallet;
    }

    function set_wallet_devs_team(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      wallet_devs_team = _wallet;
    }

    function set_wallet_liquidity(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      wallet_liquidity = _wallet;
    }

    function set_presale_contract_address(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      presale_contract_address = _wallet;
    }

    modifier is_presale() {
        require(msg.sender == presale_contract_address);
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if(!paused()){
         super._beforeTokenTransfer(from, to, amount);
        }else{
          require(hasRole(TRANSFER_ROLE, from),"Role not added");
          super._beforeTokenTransfer(from, to, amount);
        }
    }
}