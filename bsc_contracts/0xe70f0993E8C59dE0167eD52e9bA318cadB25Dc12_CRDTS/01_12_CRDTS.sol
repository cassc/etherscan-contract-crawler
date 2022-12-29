// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CRDTS is ERC20, ERC20Burnable, Pausable, AccessControl {


    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    string public tokenName = "Crypto Drift Unlimited Token";
    string public tokenSymbol = "CRDTS";

    constructor() ERC20(tokenName, tokenSymbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(TRANSFER_ROLE, msg.sender);
        _grantRole(TRANSFER_ROLE, address(this));

        _mint(address(this),(300000000 * 1 ether)); 

        initialFunding();
        addVestingDates();
    }

    address public gameRewardWalletAddress = 0x1c90e4f64ae084b26ebD857086089ffa5c0C3f74;
    address public developmentWalletAddress = 0xF1b88631fc4e73Fa611C2CdC64883C3aae4c6acE;
    address public airdropWalletAddress = 0x428bc49c16F83557CAD1e32A3d133fb593aD0f7E;
    address public liquidityWalletAddress = 0x9010D2F95940819De3a20E059BA4eE463A351874;
    address public marketingWalletAddress = 0xB0bAFAA7331881c1f246D2294F20BA69869D04c9;
    address public teamWalletAddress = 0xf58A11A90870e1436dE75CcF44e9f43eeD38F961;
    address public stakingWalletAddress = 0x0b3F2460f26B98A77b1b571199673e6d4dF87ced;

    uint256 public developmentSupply = 15000000 * 1 ether; 
    uint256 public marketingSupply = 6000000 * 1 ether; 
    uint256 public teamSupply = 15000000 * 1 ether; 
    uint256 public stakingSupply = 24000000 * 1 ether;

    address public publicSaleContractAddress;
    uint256 public publicSalePhase1Supply = 20000000 * 1 ether;
    uint256 public publicSalePhase2Supply = 40000000 * 1 ether;

    uint256 private constant Jan_01_2023 = 1672531200;
    uint256 private constant Feb_01_2023 = 1675209600;
    uint256 private constant  Mar_01_2023 = 1677628800;
    uint256 private constant  Apr_01_2023 = 1680307200;
    uint256 private constant  May_01_2023 = 1682899200;
    uint256 private constant  Jun_01_2023 = 1685577600;
    uint256 private constant  Jul_01_2023 = 1688169600;
    uint256 private constant  Aug_01_2023 = 1690848000;
    uint256 private constant  Sep_01_2023 = 1693526400;
    uint256 private constant  Oct_01_2023 = 1696118400;
    uint256 private constant  Nov_01_2023 = 1698796800;
    uint256 private constant  Dec_01_2023 = 1701388800;

    uint256 private constant  Jan_01_2024 = 1704067200;
    uint256 private constant  Feb_01_2024 = 1706745600;
    uint256 private constant  Mar_01_2024 = 1709251200;
    uint256 private constant  Apr_01_2024 = 1711929600;
    uint256 private constant  May_01_2024 = 1714521600;
    uint256 private constant  Jun_01_2024 = 1717200000;
    uint256 private constant  Jul_01_2024 = 1719792000;
    uint256 private constant  Aug_01_2024 = 1722470400;
    uint256 private constant  Sep_01_2024 = 1725148800;
    uint256 private constant  Oct_01_2024 = 1727740800;

    struct vesting{
      uint256 date;
      uint256 amount;
      bool isClaimed;
    }

    mapping(string => vesting[]) public VESTING_SCHEDULES;
    mapping(address => bool) public ENABLED_TRANSFERS;

    function initialFunding() private {

      _transfer(address(this), gameRewardWalletAddress, (159000000 * 1 ether));
      _transfer(address(this), airdropWalletAddress, (6000000 * 1 ether)); 
      _transfer(address(this), liquidityWalletAddress, (15000000 * 1 ether)); 
      _transfer(address(this), marketingWalletAddress, (1200000 * 1 ether)); 

    }

    function addVestingDates() private {

        VESTING_SCHEDULES["Development"].push(vesting(Feb_01_2024,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Development"].push(vesting(Mar_01_2024,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Development"].push(vesting(Apr_01_2024,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Development"].push(vesting(May_01_2024,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Development"].push(vesting(Jun_01_2024,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Development"].push(vesting(Jul_01_2024,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Development"].push(vesting(Aug_01_2024,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Development"].push(vesting(Sep_01_2024,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Development"].push(vesting(Oct_01_2024,(1500000 * 1 ether),false)); 
        VESTING_SCHEDULES["Development"].push(vesting(Nov_01_2023,(1500000 * 1 ether),false)); 
        
        VESTING_SCHEDULES["Marketing"].push(vesting(Feb_01_2023,(960000 * 1 ether),false)); 
        VESTING_SCHEDULES["Marketing"].push(vesting(Mar_01_2023,(960000 * 1 ether),false)); 
        VESTING_SCHEDULES["Marketing"].push(vesting(Apr_01_2023,(960000 * 1 ether),false)); 
        VESTING_SCHEDULES["Marketing"].push(vesting(May_01_2023,(960000 * 1 ether),false)); 
        VESTING_SCHEDULES["Marketing"].push(vesting(Jun_01_2023,(960000 * 1 ether),false)); 

        VESTING_SCHEDULES["Team"].push(vesting(Jul_01_2023,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Team"].push(vesting(Aug_01_2023,(1500000 * 1 ether),false)); 
        VESTING_SCHEDULES["Team"].push(vesting(Sep_01_2023,(1500000 * 1 ether),false)); 
        VESTING_SCHEDULES["Team"].push(vesting(Oct_01_2023,(1500000 * 1 ether),false)); 
        VESTING_SCHEDULES["Team"].push(vesting(Nov_01_2023,(1500000 * 1 ether),false)); 
        VESTING_SCHEDULES["Team"].push(vesting(Dec_01_2023,(1500000 * 1 ether),false));
        VESTING_SCHEDULES["Team"].push(vesting(Jan_01_2024,(1500000 * 1 ether),false)); 
        VESTING_SCHEDULES["Team"].push(vesting(Feb_01_2024,(1500000 * 1 ether),false)); 
        VESTING_SCHEDULES["Team"].push(vesting(Mar_01_2024,(1500000 * 1 ether),false)); 
        VESTING_SCHEDULES["Team"].push(vesting(Apr_01_2024,(1500000 * 1 ether),false)); 

        VESTING_SCHEDULES["Staking"].push(vesting(Apr_01_2024,(24000000 * 1 ether),false)); 

    }

    function sendVestingDevelopment() external onlyRole(DEFAULT_ADMIN_ROLE){
      for(uint256 i=0;i < VESTING_SCHEDULES["Development"].length;i++){
        vesting storage vest = VESTING_SCHEDULES["Development"][i];
        if(block.timestamp >= vest.date && !vest.isClaimed ){
          require(developmentSupply - vest.amount >= 0,"Not enough supply");
          vest.isClaimed = true;
          developmentSupply = developmentSupply - vest.amount;

          _transfer(address(this), developmentWalletAddress, vest.amount);
        }
      }
    }

    function sendVestingMarketing() external onlyRole(DEFAULT_ADMIN_ROLE){
      for(uint256 i=0;i < VESTING_SCHEDULES["Marketing"].length;i++){
        vesting storage vest = VESTING_SCHEDULES["Marketing"][i];
        if(block.timestamp >= vest.date && !vest.isClaimed ){
          require(marketingSupply - vest.amount >= 0,"Not enough supply");
          vest.isClaimed = true;
          marketingSupply = marketingSupply - vest.amount;

          _transfer(address(this), marketingWalletAddress, vest.amount);
        }
      }
    }

    function sendVestingTeam() external onlyRole(DEFAULT_ADMIN_ROLE){
      for(uint256 i=0;i < VESTING_SCHEDULES["Team"].length;i++){
        vesting storage vest = VESTING_SCHEDULES["Team"][i];
        if(block.timestamp >= vest.date && !vest.isClaimed ){
          require(teamSupply - vest.amount >= 0,"Not enough supply");
          vest.isClaimed = true;
          teamSupply = teamSupply - vest.amount;

          _transfer(address(this), teamWalletAddress, vest.amount);
        }
      }
    }

    function sendVestingStaking() external onlyRole(DEFAULT_ADMIN_ROLE){
      for(uint256 i=0;i < VESTING_SCHEDULES["Staking"].length;i++){
        vesting storage vest = VESTING_SCHEDULES["Staking"][i];
        if(block.timestamp >= vest.date && !vest.isClaimed ){
          require(stakingSupply - vest.amount >= 0,"Not enough supply");
          vest.isClaimed = true;
          stakingSupply = stakingSupply - vest.amount;

          _transfer(address(this), stakingWalletAddress, vest.amount);
        }
      }
    }

    function sendPublicSalePhase1(address recipient, uint256 amount) external isPublicSaleContract returns (bool){
        require(publicSalePhase1Supply - amount >= 0,"Insufficient supply");

        publicSalePhase1Supply = publicSalePhase1Supply - amount;
        _transfer(address(this), recipient, amount);

        return true;
    }

    function sendPublicSalePhase2(address recipient, uint256 amount) external isPublicSaleContract returns (bool){
        require(publicSalePhase2Supply - amount >= 0,"Insufficient supply");

        publicSalePhase2Supply = publicSalePhase2Supply - amount;
        _transfer(address(this), recipient, amount);

        return true;
    }

    function retVestings(string memory _type) public view returns(vesting[] memory _vestings, uint256 _time){

      vesting[] memory _newList = new vesting[](VESTING_SCHEDULES[_type].length);

      for(uint256 i=0;i < VESTING_SCHEDULES[_type].length;i++){
         vesting storage vest = VESTING_SCHEDULES[_type][i];
         _newList[i] = vest;
      }

      return (_newList,block.timestamp);
    }

    function setPublicSaleContractAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE){
      publicSaleContractAddress = _address;
    }

    function setGameRewardWalletAddress(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      gameRewardWalletAddress = _wallet;
    }
    function setDevelopmentWalletAddress(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      developmentWalletAddress = _wallet;
    }

    function setAirdropWalletAddress(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      airdropWalletAddress = _wallet;
    }

    function setLiquidityWalletAddress(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      liquidityWalletAddress = _wallet;
    }

    function setMarketingWalletAddress(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      marketingWalletAddress = _wallet;
    }
    
    function setTeamWalletAddress(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      teamWalletAddress = _wallet;
    }

    function setStakingWalletAddress(address _wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      stakingWalletAddress = _wallet;
    }

    modifier isPublicSaleContract() {
        require(msg.sender == publicSaleContractAddress);
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
          bool _canTransfer = canTransfer(from, to);
          require(_canTransfer, "Cannot Transfer");
          super._beforeTokenTransfer(from, to, amount);
        }
    }
    function canTransfer(address from, address to) view internal returns(bool stmt){
       if((hasRole(TRANSFER_ROLE, from)) || (hasRole(TRANSFER_ROLE, to))){
        return true;
       }else{
        return false;
       }
    }
}