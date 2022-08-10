/**
  Not This is not the complete code it will pushed soon.
*/
pragma solidity 0.5.17;

// import "../../other/token.sol";
import "../../other/1inch.sol";
import "../../other/Initializable.sol";

interface Iitokendeployer{
	function createnewitoken(string calldata _name, string calldata _symbol) external returns(address);
}

interface IOracle{
	function getiTokenDetails(uint _poolIndex) external returns(string memory, string memory);
     function getTokenDetails(uint _poolIndex) external returns(address[] memory,uint[] memory,uint ,uint);
}

contract PoolConfiguration is Initializable {
    
    using SafeMath for uint;
	// Astra contract address
	address public ASTRTokenAddress;
	// Manager address
	address public managerAddresses;
	//Oracle contract addressess
	address public Oraclecontract;
	// Early exit fees
	uint256 public earlyexitfees;
	// Performance fees
	uint256 public performancefees;
    // Maximum number of tokens supported by indices
	uint256 private maxTokenSupported;

	// Slippage rate.
	uint256 public slippagerate;
	//Supported stable coins
	mapping(address => bool) public supportedStableCoins;

	// Enabled DAO address
	mapping(address => bool) public enabledDAO;
	
	// Admin addresses
	mapping(address => bool) public systemAddresses;
	/**
     * @dev Modifier to check if the caller is Admin or not.
     */
	modifier systemOnly {
	    require(systemAddresses[msg.sender], "system only");
	    _;
	}
	/**
     * @dev Modifier to check if the caller is dao or not
     */
	modifier DaoOnly{
	    require(enabledDAO[msg.sender], "dao only");
	    _;
	}
	/**
     * @dev Modifier to check if the caller is manager or not
     */
	modifier whitelistManager {
	    require(managerAddresses == msg.sender, "Manager only");
	    _;
	}

	/**
	 * @dev Add admin address who has overall access of contract.
	 */
		
	function addSystemAddress(address newSystemAddress) public systemOnly {
		require(newSystemAddress != address(0), "Zero Address"); 
	    systemAddresses[newSystemAddress] = true;
	}
	
	function initialize(address _ASTRTokenAddress) public initializer{
		require(_ASTRTokenAddress != address(0), "Zero Address");
		systemAddresses[msg.sender] = true;
		ASTRTokenAddress = _ASTRTokenAddress;
		managerAddresses = msg.sender;
		earlyexitfees = 2;
		performancefees = 20;
		maxTokenSupported = 10;
		slippagerate = 10;
	}
	/**
	 * @notice WhiteList DAO Address
	 * @param _address DAO conractaddress
	 * @dev Add DAO address who can update the function details.
	 */
	
	function whitelistDAOaddress(address _address) external whitelistManager {
		require(_address != address(0), "Zero Address");
	    require(!enabledDAO[_address],"whitelistDAOaddress: Already whitelisted");
	    enabledDAO[_address] = true;
	  
	}

	/**
	 * @notice Set Oracle Address
	 * @param _address Oracle conractaddress
	 * @dev Add Oracle address from where PoolV1 get the details. Only manager can update no proposal required for this.
	 */

	function setOracleaddress(address _address) external whitelistManager {
		require(_address != address(0), "Zero Address");
		require(_address != Oraclecontract, "setOracleaddress: Already set");
		Oraclecontract = _address;
	}

	/**
	 * @notice Remove DAO Address
	 * @param _address DAO conractaddress
	 * @dev Remove DAO address who can update the function details. To remove the access from DAO.
	 */
	function removeDAOaddress(address _address) external whitelistManager {
		require(_address != address(0), "Zero Address");
	    require(enabledDAO[_address],"removeDAOaddress: Not whitelisted");
	    enabledDAO[_address] = false;
	  
	}

	function addStable(address _stable) external DaoOnly{
		require(_stable != address(0), "Zero Address");
		require(supportedStableCoins[_stable] == false,"addStable: Stable coin already added");
		supportedStableCoins[_stable] = true;
	}

	function removeStable(address _stable) external DaoOnly{
		require(_stable != address(0), "Zero Address");
		require(supportedStableCoins[_stable] == true,"removeStable: Stable coin already removed");
		supportedStableCoins[_stable] = false;
	}
	
	/**
	 * @notice Remove whitelist manager address
	 * @param _address User address
	 * @dev Update the address of manager. By default it is contract deployer. Manager has permission to update the dao address.
	 */
	function updatewhitelistmanager(address _address) external whitelistManager{
		require(_address != address(0), "Zero Address");
	    require(_address != managerAddresses,"updatewhitelistmanager: Already Manager");
	    managerAddresses = _address;
	}  

	/**
	 * @notice Update Early Exit Fees
	 * @param _feesper New Fees amount
	 * @dev Only DAO can update the Early Exit fees. This will only be called by creating proposal.
	 */  

	function updateEarlyExitFees (uint256 _feesper) external DaoOnly{
        require(_feesper<100,"updateEarlyExitFees: Only less than 100");
        earlyexitfees = _feesper;
    }

	/**
	 * @notice Update Performance Fees
	 * @param _feesper New Fees amount
	 * @dev Only DAO can update the Performance fees.  This will only be called by creating proposal.
	 */ 

     function updatePerfees (uint256 _feesper) external DaoOnly{
        require(_feesper<100,"updatePerfees: Only less than 100");
        performancefees = _feesper;
    }

    /**
	 * @notice Update maximum token for indices
	 * @param _maxTokenSupported New maximum tokens in a indices
	 * @dev Only DAO can update the maximum tokens.  This will only be called by creating proposal.
	 */ 

     function updateMaxToken (uint256 _maxTokenSupported) external DaoOnly{
        require(_maxTokenSupported<100,"updateMaxToken: Only less than 100");
        maxTokenSupported = _maxTokenSupported;
    }

	/**
	 * @notice Update Slippage Rate
	 * @param _slippagerate New slippage amount
	 * @dev Only DAO can update the Early Exit fees. This will only be called by creating proposal.
	 */ 

	function updateSlippagerate (uint256 _slippagerate) external DaoOnly{
        require(_slippagerate<100,"updateSlippagerate: Only less than 100");
        slippagerate = _slippagerate;
    }

	/** 
	 * @dev Get the Early exit fees. This will be called by the poolV1 contract to calculate early exit fees.
	 */

	function getEarlyExitfees() external view returns(uint256){
		return earlyexitfees;
	}

	/** 
	 * @dev Get the Performance fees This will be called by the poolV1 contract to calculate performance fees.
	 */

	function getperformancefees() external view returns(uint256){
		return performancefees;
	 } 

	 /** 
	 * @dev Get the max token supported  This will be called by the poolV1 contract to create/update indices.
	 */

	function getmaxTokenSupported() external view returns(uint256){
		return maxTokenSupported;
	 }

	 /** 
	 * @param daoAddress Address to check
	 * @dev Check if Address has dao permission or not. This will be used to check if the account is whitelisted or not.
	 */   
	  function checkDao(address daoAddress) external view returns(bool){
		  return enabledDAO[daoAddress];
	  }

	  /** 
	 * @dev Get the Oracle Address.This will be called by the poolV1 contract to get oracle contract address.
	 */

	  function getoracleaddress() external view returns(address){
		  return Oraclecontract;
	  }

	 /** 
	 * @dev Get the Performance fees. This will be called by the poolV1 contract to calculate slippage.
	 */

	 function getslippagerate() external view returns(uint256){
		 return slippagerate;
	 }  

	 function checkStableCoin(address _stable) external view returns(bool){
		 return supportedStableCoins[_stable];
	 }
}