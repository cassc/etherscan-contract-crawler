// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IPancakeSwapV2Factory.sol";

interface IStaking {
   function updatePool(uint256 amount) external;
}

interface IFarm {
   function updatePool(uint256 amount) external;
}

interface ITeam {
   function updatePool(uint256 amount) external;
}

interface IInsurance {
   function updatePool(uint256 amount) external;
}

interface IBounty {
   function updatePool(uint256 amount) external;
}

interface ICharity {
   function updatePool(uint256 amount) external;
}

interface IPartnersInvestors {
   function updatePool(uint256 amount) external;
}

contract INFLIV is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, UUPSUpgradeable {
	struct PartnersInvestorsPool {
       uint256 initialSupply;
	   uint256 maxSupply;
	   uint256 supplyMinted;
	   uint256 startTime;
	   uint256 timeInterval;
	   uint256 unlockAmount;
    }
	PartnersInvestorsPool public partnersInvestorsPool;
	
	struct BountyBonusesPool {
       uint256 initialSupply;
	   uint256 maxSupply;
	   uint256 supplyFromGovernance;
	   uint256 supplyMinted;
	   uint256 startTime;
	   uint256 timeInterval;
	   uint256 unlockAmount;
    }
	BountyBonusesPool public bountyBonusesPool;

	struct ListingsLiquidityPool {
       uint256 initialSupply;
	   uint256 maxSupply;
	   uint256 supplyFromGovernance;
	   uint256 supplyMinted;
	   uint256 startTime;
	   uint256 timeInterval;
	   uint256 unlockAmount;
	   uint256 lastClaimTime;
	   uint256 claimInterval;
    }
	ListingsLiquidityPool public listingsLiquidityPool;

	struct CommunityPool {
	   uint256 maxSupply;
	   uint256 supplyFromGovernance;
	   uint256 supplyMinted;
	   uint256 supplyPerBlock;
	   uint256 startingBlock;
	   uint256 lastClaimTime;
	   uint256 claimInterval;
    }
	CommunityPool public communityPool;
	
	struct TreasuryPool {
	   uint256 maxSupply;
	   uint256 supplyFromGovernance;
	   uint256 supplyMinted;
	   uint256 supplyPerBlock;
	   uint256 startingBlock;
    }
	TreasuryPool public treasuryPool;
	
	struct TeamPool {
	   uint256 maxSupply;
	   uint256 supplyFromGovernance;
	   uint256 supplyMinted;
	   uint256 supplyPerBlock;
	   uint256 startingBlock;
	   uint256 lastClaimTime;
	   uint256 claimInterval;
    }
	TeamPool public teamPool;
	
	struct InsurancePool {
	   uint256 maxSupply;
	   uint256 supplyMinted;
    }
	InsurancePool public insurancePool;
	
	struct CharityPool {
	   uint256 maxSupply;
	   uint256 supplyMinted;
    }
	CharityPool public charityPool;
	
	struct ReservePool {
	   uint256 maxSupply;
	   uint256 supplyMinted;
    }
	ReservePool public reservePool;
	
	struct GovernanceFeeShare {
	   uint256 communityPoolShare;
	   uint256 liquidityPoolShare;
	   uint256 teamPoolShare;
	   uint256 treasuryPoolShare;
	   uint256 bountyBonusesPool;
	   uint256 insurancePoolShare;
	   uint256 charityPoolShare;
	   uint256 reservePoolShare;
	}
	GovernanceFeeShare public governanceFeeShare;
	
    bool private swapping;
	bool public initialized;
	
	address public stakingAddress;
	address public teamAddress;
	address public farmAddress;
	address public insuranceAddress;
	address public bountyAddress;
	address public charityAddress;
	address public partnersInvestorsAddress;
	
	uint256[] public GovernanceFee;

	IPancakeSwapV2Router02 public pancakeSwapV2Router;
    address public pancakeSwapV2Pair;
	
    mapping(address => bool) public whitelistedAddress;
	mapping(address => bool) public automatedMarketMakerPairs;
	
    event WhitelistAddressUpdated(address whitelistAccount, bool value);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event SwapTokenAmountUpdated(uint256 indexed amount);
	event StakingAddressUpdated(address stakingAddress);
	event FarmAddressUpdated(address farmAddress);
	event InsuranceAddressUpdated(address insuranceAddress);
	event BountyAddressUpdated(address bountyAddress);
	event TeamAddressUpdated(address teamAddress);
	event CharityAddressUpdated(address charityAddress);
	event PartnersInvestorsAddressUpdated(address partnersInvestors);
	event RouterAddressUpdated(address routerAddress);
	event GovernanceFeeUpdated(uint256 buy, uint256 sell, uint256 p2p);
	
    function initialize() initializer public {
	    require(!initialized, "Contract instance has already been initialized");
		initialized = true;
		
		__ERC20_init("INFLIV", "IFV");
        __Ownable_init();
        __ERC20Permit_init("IFV");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();
		
        _mint(msg.sender, 15000000 * (10**18)); // Partners & Investors Initial Supply
		_mint(msg.sender, 1000 * (10**18)); // Bounty & Bonuses Initial Supply
		_mint(msg.sender, 6000 * (10**18)); // Listings & Liquidity Initial Supply
		
		// Partner & Investors Pool
		partnersInvestorsPool.initialSupply = 15000000 * (10**18);
		partnersInvestorsPool.maxSupply = 27900000 * (10**18);
		partnersInvestorsPool.supplyMinted = 15000000 * (10**18); 
		partnersInvestorsPool.unlockAmount = 268750 * (10**18);
		partnersInvestorsPool.startTime = block.timestamp + 365 days;
		partnersInvestorsPool.timeInterval = 30 days;
		
		// Bounty & Bonuses Pool 
		bountyBonusesPool.initialSupply = 1000 * (10**18);
		bountyBonusesPool.maxSupply = 3100000 * (10**18);
		bountyBonusesPool.supplyMinted = 1000 * (10**18); 
		bountyBonusesPool.unlockAmount = 1000 * (10**18);
		bountyBonusesPool.startTime = block.timestamp + 30 days;
		bountyBonusesPool.timeInterval = 1 days;
		
		// Listings & Liquidity Pool 
		listingsLiquidityPool.initialSupply = 6000 * (10**18);
		listingsLiquidityPool.maxSupply = 9300000 * (10**18);
		listingsLiquidityPool.supplyMinted = 6000 * (10**18); 
		listingsLiquidityPool.unlockAmount = 6000 * (10**18);
		listingsLiquidityPool.startTime = block.timestamp + 30 days;
		listingsLiquidityPool.timeInterval = 2 days;
		listingsLiquidityPool.lastClaimTime = block.timestamp;
		listingsLiquidityPool.claimInterval = 2 days;
		
		// Community Pool 
		communityPool.maxSupply = 207700000 * (10**18);
	    communityPool.supplyPerBlock = 23106 * (10**14);
		communityPool.startingBlock = block.number;
		communityPool.lastClaimTime = block.timestamp;
		communityPool.claimInterval = 15 minutes;
		
		// Treasury Pool 
		treasuryPool.maxSupply = 15500000 * (10**18);
	    treasuryPool.supplyPerBlock = 1722 * (10**14); 
		treasuryPool.startingBlock = block.number;
		
		// Team Pool 
		teamPool.maxSupply = 46500000 * (10**18); 
	    teamPool.supplyPerBlock = 5172 * (10**14); 
		teamPool.startingBlock = block.number;
		teamPool.claimInterval = 300 hours;
		teamPool.lastClaimTime = block.timestamp;
		
		// Governance Constructor 
		governanceFeeShare.communityPoolShare = 7000;
	    governanceFeeShare.liquidityPoolShare = 1000;
	    governanceFeeShare.treasuryPoolShare = 400;
	    governanceFeeShare.bountyBonusesPool = 200;
	    governanceFeeShare.insurancePoolShare = 100;
	    governanceFeeShare.charityPoolShare = 200;
	    governanceFeeShare.teamPoolShare = 1000;
	    governanceFeeShare.reservePoolShare = 100;
		
		IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pancakeSwapV2Pair = IPancakeSwapV2Factory(_pancakeSwapV2Router.factory()).createPair(address(this), _pancakeSwapV2Router.WETH());

        pancakeSwapV2Router = _pancakeSwapV2Router;
        pancakeSwapV2Pair   = _pancakeSwapV2Pair;
		
        _setAutomatedMarketMakerPair(_pancakeSwapV2Pair, true);
		
		whitelistedAddress[address(this)] = true;
		whitelistedAddress[owner()] = true;
       
	    GovernanceFee.push(200);
		GovernanceFee.push(0);
		GovernanceFee.push(200);
    }
	
	receive() external payable {}
	 
	function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

	function _mint(address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }
	
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable){
        super._afterTokenTransfer(from, to, amount);
    }
	
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }
	
    function setWhitelistAddress(address _whitelist, bool _status) external onlyOwner{
        require(_whitelist != address(0), "setWhitelistAddress: Zero address");
		
        whitelistedAddress[_whitelist] = _status;
        emit WhitelistAddressUpdated(_whitelist, _status);
    }

    function _maxSupply() internal view virtual override(ERC20VotesUpgradeable) returns (uint224) {
        return type(uint224).max;
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != pancakeSwapV2Pair, "INFLIV: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
		require(pair != address(0), "INFLIV: Zero address");
		
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
		
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
	
	function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();
		
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
	function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);
        pancakeSwapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            address(this),
            block.timestamp + 300
        );
    }
	
	function setRouterAddress(address newAddress) external onlyOwner {
	    require(newAddress != address(0), "INFLIV: Zero address");
		
        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(newAddress);
        pancakeSwapV2Router = _pancakeSwapV2Router;
		emit RouterAddressUpdated(newAddress);
    }
	
	function setStakingAddress(address newAddress) external onlyOwner {
	    require(newAddress != address(0), "INFLIV: Zero address");
		
        stakingAddress = newAddress;
		emit StakingAddressUpdated(stakingAddress);
    }
	
	function setFarmAddress(address newAddress) external onlyOwner {
	    require(newAddress != address(0), "INFLIV: Zero address");
		
        farmAddress = newAddress;
		emit FarmAddressUpdated(farmAddress);
    }
	
	function setInsuranceAddress(address newAddress) external onlyOwner {
	    require(newAddress != address(0), "INFLIV: Zero address");
		
        insuranceAddress = newAddress;
		emit InsuranceAddressUpdated(insuranceAddress);
    }
	
	function setCharityAddress(address newAddress) external onlyOwner {
	    require(newAddress != address(0), "INFLIV: Zero address");
		
        charityAddress = newAddress;
		emit CharityAddressUpdated(charityAddress);
    }
	
	function setPartnersInvestorsAddress(address newAddress) external onlyOwner {
	    require(newAddress != address(0), "INFLIV: Zero address");
		
        partnersInvestorsAddress = newAddress;
		emit PartnersInvestorsAddressUpdated(partnersInvestorsAddress);
    }
	
	function setBountyAddress(address newAddress) external onlyOwner {
	    require(newAddress != address(0), "INFLIV: Zero address");
		
		bountyAddress = newAddress;
		emit BountyAddressUpdated(bountyAddress);
    }
	
	function setTeamAddress(address newAddress) external onlyOwner {
	    require(newAddress != address(0), "INFLIV: Zero address");
		
		teamAddress = newAddress;
		emit TeamAddressUpdated(teamAddress);
    }
	
	function withdrawalTokenFromPartnersInvestorsPool(address to, uint256 amount) external onlyOwner {
	   uint256 available = availablePartnersInvestorsPoolTokens();
	   
	   require(to != address(0), "INFLIV: Zero address");
	   require(available >= amount, "INFLIV: Amount is not available for mint or amount is zero");
	   
	   partnersInvestorsPool.supplyMinted += amount;
	   _mint(to, amount);
    }
	
	function availablePartnersInvestorsPoolTokens() public view returns (uint256) {
	    if(block.timestamp >= partnersInvestorsPool.startTime){
		
		    uint256 available = ((block.timestamp - partnersInvestorsPool.startTime) / partnersInvestorsPool.timeInterval) * partnersInvestorsPool.unlockAmount;
			        available = (available > partnersInvestorsPool.maxSupply) ? 
	                            partnersInvestorsPool.maxSupply - partnersInvestorsPool.supplyMinted : 
						        available - partnersInvestorsPool.supplyMinted;
	        return  available;						  
		}
		else
		{
		    return 0;
		}
    }
	
	function availableListingsLiquidityPoolTokens() public view returns (uint256) {
	    if(block.timestamp >= listingsLiquidityPool.startTime)
		{
		
		    uint256 available = ((block.timestamp - listingsLiquidityPool.startTime) / listingsLiquidityPool.timeInterval) * listingsLiquidityPool.unlockAmount + listingsLiquidityPool.supplyFromGovernance;
			        available = (available > listingsLiquidityPool.maxSupply + listingsLiquidityPool.supplyFromGovernance) ? 
	                            listingsLiquidityPool.maxSupply + listingsLiquidityPool.supplyFromGovernance - listingsLiquidityPool.supplyMinted : 
						        available - listingsLiquidityPool.supplyMinted;
	        return  available;						  
		}
		else
		{
		    return 0;
		}
    }
	
	function withdrawalTokenFromBountyBonusesPool(address to, uint256 amount) external onlyOwner{
	   uint256 available = availableBountyBonusesPoolTokens();
	   
	   require(to != address(0), "INFLIV: Zero address");
	   require(available >= amount && amount > 0, "INFLIV: Amount is not available for mint or amount is zero");
	   
	   bountyBonusesPool.supplyMinted += amount;
	   _mint(to, amount);
    }
	
	function availableBountyBonusesPoolTokens() public view returns (uint256) {
	    if(block.timestamp >= bountyBonusesPool.startTime)
		{
		    uint256 available = ((block.timestamp - bountyBonusesPool.startTime) / bountyBonusesPool.timeInterval) * bountyBonusesPool.unlockAmount + 
			                     bountyBonusesPool.supplyFromGovernance;
								
			        available = (available > bountyBonusesPool.maxSupply + bountyBonusesPool.supplyFromGovernance) ? 
	                            bountyBonusesPool.maxSupply + bountyBonusesPool.supplyFromGovernance - bountyBonusesPool.supplyMinted : 
						        available - bountyBonusesPool.supplyMinted;
	        return  available;						  
		}
		else
		{
		    return 0;
		}
    }
	
	function withdrawalTokenFromTreasuryPool(address to, uint256 amount) external onlyOwner {
	   uint256 available = availableTreasuryPoolTokens();
	   
	   require(to != address(0), "INFLIV: Zero address");
	   require(available >= amount && amount > 0, "INFLIV: Amount is not available for mint or amount is zero");
	   
	   treasuryPool.supplyMinted += amount;
	   _mint(to, amount);
    }
	
	function availableTreasuryPoolTokens() public view returns (uint256) {
  	    uint256 available = (block.number - treasuryPool.startingBlock) * treasuryPool.supplyPerBlock + treasuryPool.supplyFromGovernance;
	            available = (available > treasuryPool.maxSupply + treasuryPool.supplyFromGovernance) ? 
	                        treasuryPool.maxSupply + treasuryPool.supplyFromGovernance - treasuryPool.supplyMinted : 
						    available - treasuryPool.supplyMinted;
	    return available;
    }
	
	function availableCommunityPoolTokens() public view returns (uint256) {
  	    uint256 available = (block.number - communityPool.startingBlock) * communityPool.supplyPerBlock + communityPool.supplyFromGovernance;
	            available = (available > communityPool.maxSupply + communityPool.supplyFromGovernance) ? 
	                        communityPool.maxSupply + communityPool.supplyFromGovernance - communityPool.supplyMinted : 
						    available - communityPool.supplyMinted;
	    return available;
    }
	
	function availableTeamPoolTokens() public view returns (uint256) {
  	    uint256 available = (block.number - teamPool.startingBlock) * teamPool.supplyPerBlock + teamPool.supplyFromGovernance;
	            available = (available > teamPool.maxSupply + teamPool.supplyFromGovernance) ? 
	                        teamPool.maxSupply + teamPool.supplyFromGovernance - teamPool.supplyMinted : 
						    available - teamPool.supplyMinted;
	    return available;
    }
	
	function availableInsurancePoolTokens() public view returns (uint256) {
  	    uint256 available = insurancePool.maxSupply - insurancePool.supplyMinted;
	    return available;
    }

	function availableCharityPoolTokens() public view returns (uint256) {
  	   uint256 available = charityPool.maxSupply - charityPool.supplyMinted;
	   return available;
    }
	
	function withdrawalTokenFromReservePool(address to, uint256 amount) external onlyOwner {
	   uint256 available = availableReservePoolTokens();
	   
	   require(to != address(0), "INFLIV: Zero address");
	   require(available >= amount && amount > 0, "INFLIV: Amount is not available for mint or amount is zero");
	   
	   reservePool.supplyMinted += amount;
	   _mint(to, amount);
    }
	
	function availableReservePoolTokens() public view returns (uint256) {
  	    uint256 available = reservePool.maxSupply - reservePool.supplyMinted;
	    return available;
    }
	
	function migrateBNB(address payable recipient) external onlyOwner{
	    require(recipient != address(0), "Zero address");
        recipient.transfer(address(this).balance);
    }
	
    function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20Upgradeable){      
        require(sender != address(0), "INFLIV: transfer from the zero address");
        require(recipient != address(0), "INFLIV: transfer to the zero address");
		
		 _updatePools();
		
		if(block.timestamp >= listingsLiquidityPool.lastClaimTime + listingsLiquidityPool.claimInterval && !swapping && automatedMarketMakerPairs[recipient]) {
		    swapping = true;
		    uint256 LLPAmount = availableListingsLiquidityPoolTokens();
			if(LLPAmount > 0) 
			{  
			    _mint(address(this), LLPAmount);
				
			    uint256 half = LLPAmount / 2;
				uint256 otherhalf = LLPAmount - half;
				
			    swapTokensForBNB(half);
				uint256 newBalance = address(this).balance;
				addLiquidity(otherhalf, newBalance);
				
				listingsLiquidityPool.lastClaimTime = block.timestamp;
				listingsLiquidityPool.supplyMinted += LLPAmount;
			}
			swapping = false;
		}
		
		if(whitelistedAddress[sender] || whitelistedAddress[recipient]) 
		{
             super._transfer(sender, recipient, amount);
        }
		else  
		{
            if(!automatedMarketMakerPairs[sender] && !automatedMarketMakerPairs[recipient])
			{
			    uint256 fee = amount * GovernanceFee[2] / 10000; 
				if(fee > 0)
				{
				    _burn(sender, fee);
					super._transfer(sender, recipient, amount);
					_distributeFee(fee);
				}
				else
				{
				    super._transfer(sender, recipient, amount);
				}
			}
			else if(automatedMarketMakerPairs[recipient])
			{
			    uint256 fee = amount * GovernanceFee[1] / 10000; 
			    if(fee > 0)
				{
				    _burn(sender, fee);
					super._transfer(sender, recipient, amount - fee);
					_distributeFee(fee);
				}
				else
				{
				    super._transfer(sender, recipient, amount);
				}
			}
			else
			{
			    uint256 fee = amount * GovernanceFee[0] / 10000; 
			    if(fee > 0)
				{
				    _burn(sender, fee);
					super._transfer(sender, recipient, amount - fee);
				    _distributeFee(fee);
				}
				else
				{
				    super._transfer(sender, recipient, amount);
				}
			}
        }
    }
	
	function _updatePools() public
	{
	   uint256 TAmount = availableTeamPoolTokens();
	   if(block.timestamp >= (teamPool.lastClaimTime + teamPool.claimInterval) && address(teamAddress) != address(0) && TAmount > 0) 
	   {
		  _mint(address(teamAddress), TAmount);
		  ITeam(teamAddress).updatePool(TAmount);
		  
		  teamPool.lastClaimTime = block.timestamp;
		  teamPool.supplyMinted += TAmount;
	   }
	   
	   uint256 CPAmount = availableCommunityPoolTokens();
	   if(block.timestamp >= (communityPool.lastClaimTime + communityPool.claimInterval) && address(stakingAddress) != address(0) && address(farmAddress) != address(0) && CPAmount > 0) 
	   {
		   uint256 stakingPoolShare = CPAmount * 20 / 100;
		   uint256 farmPoolShare = CPAmount - stakingPoolShare;
		   
		   _mint(address(stakingAddress), stakingPoolShare);
		   _mint(address(farmAddress), farmPoolShare);
		  
		   IStaking(stakingAddress).updatePool(stakingPoolShare);
		   IFarm(farmAddress).updatePool(farmPoolShare);
		   
		   communityPool.lastClaimTime = block.timestamp;
		   communityPool.supplyMinted += CPAmount;
	    }
		
	    uint256 BAmount= availableBountyBonusesPoolTokens();
	    if(BAmount > 0 && address(bountyAddress) != address(0))
	    { 
	        _mint(address(bountyAddress), BAmount);
			
		    IBounty(bountyAddress).updatePool(BAmount);
			bountyBonusesPool.supplyMinted += BAmount;
	    }
		
		uint256 IAmount = availableInsurancePoolTokens();
	    if(IAmount > 0 && address(insuranceAddress) != address(0))
	    {
	        _mint(address(insuranceAddress), IAmount);
		    
			IInsurance(insuranceAddress).updatePool(IAmount);
			insurancePool.supplyMinted += IAmount;
	    }
		
		uint256 CPPAmount= availableCharityPoolTokens();
	    if(CPPAmount > 0 && address(charityAddress) != address(0))
	    {
	        _mint(address(charityAddress), CPPAmount);
			
		    ICharity(charityAddress).updatePool(CPPAmount);
			charityPool.supplyMinted += CPPAmount;
	    }
		
		uint256 PIAmount= availablePartnersInvestorsPoolTokens();
	    if(CPAmount > 0 && address(partnersInvestorsAddress) != address(0))
	    {
	        _mint(address(partnersInvestorsAddress), PIAmount);
			
		    IPartnersInvestors(partnersInvestorsAddress).updatePool(PIAmount);
		    partnersInvestorsPool.supplyMinted += PIAmount;
	    }
	}
	
	function _distributeFee(uint256 amount) private {
	
	   uint256 communityPoolShare = amount * governanceFeeShare.communityPoolShare / 10000;
	   uint256 liquidityPoolShare = amount * governanceFeeShare.liquidityPoolShare / 10000;
	   uint256 treasuryPoolShare = amount * governanceFeeShare.treasuryPoolShare / 10000;
	   uint256 bountyBonusesPoolShare = amount * governanceFeeShare.bountyBonusesPool / 10000;
	   uint256 insurancePoolShare = amount * governanceFeeShare.insurancePoolShare / 10000;
	   uint256 charityPoolShare = amount * governanceFeeShare.charityPoolShare / 10000;
	   uint256 teamPoolShare = amount * governanceFeeShare.teamPoolShare / 10000;
	   uint256 reservePoolShare = amount * governanceFeeShare.reservePoolShare / 10000;
		
	   reservePool.maxSupply += reservePoolShare;
	   charityPool.maxSupply += charityPoolShare;
	   insurancePool.maxSupply += insurancePoolShare;
	   
	   teamPool.supplyFromGovernance += teamPoolShare;
	   treasuryPool.supplyFromGovernance += treasuryPoolShare;
	   communityPool.supplyFromGovernance += communityPoolShare;
	   listingsLiquidityPool.supplyFromGovernance += liquidityPoolShare;
	   bountyBonusesPool.supplyFromGovernance += bountyBonusesPoolShare;
	}
	
	function distributeFee(uint256 amount) external {
	   _burn(address(msg.sender), amount);
	   _distributeFee(amount);
	   _updatePools();
	}
}