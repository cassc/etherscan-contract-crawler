pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IWETH.sol";
import "./INamingCredits.sol";
import "./INFTRegistry.sol";
import "./IRNM.sol";

/**
 * @title NamingCredits
 * @notice Allows naming credits to be bought in bulk, and later consumed by NFTRegistry contract to name. Proceeds are forwarded to a protocol fee receiver contract. Owner is the NFTRegistry contract
 */
contract NamingCredits is ReentrancyGuard, Ownable, INamingCredits {

    // Enums
    enum AssignmentsAllowed {
        NO,
        YES
    }  

    enum BuyWithETH { 
        NO, 
        YES
    }

    AssignmentsAllowed public assignmentsAllowed;
    AssignmentsAllowed public assignerAssignmentsAllowed;
    bool public allowUpdatingFeeRecipient = true;

    uint256 public constant MAX_CREDITS_ASSIGNED = 10; // number of credits
    uint256 public constant MAX_BULK_ASSIGNMENT = 50; // number of addresses
    uint256 public constant MAX_ASSIGNER_CREDITS = 100; // number of credits

    // Credit balances
    mapping (address => uint256) public override credits;

    // Relevant addresses
    INFTRegistry public immutable nftrAddress;
    address public protocolFeeRecipient;
    address public immutable WETH;
    mapping (address => uint256) public assigners;
    address private tempAdmin;
    IRNM public rnmAddress;

    // Events
    event RNMAddressSet(address rnmAddress);   
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event CreditsBought(address indexed sender, uint256 numberOfCredits, BuyWithETH buyWithETH, uint256 totalCost);
    event CreditsConsumed(address indexed sender, uint256 numberOfCredits);
    event AssignerCreditsAdded(address indexed assigner, uint256 numberOfCredits);
    event CreditsAssigned(address indexed assigner, address indexed receiver, uint256 numberOfCredits);
    event AssignmentsShutOff();    
    event AssignerAssignmentsShutOff(); 

    /**
     * @dev Throws if called by any account other than the tempAdmin.
     */
    modifier onlyTempAdmin() {
        require(tempAdmin == msg.sender, "NamingCredits: caller is not tempAdmin");
        _;
    }

    /**
     * @notice Constructor
     * @param _protocolFeeRecipient protocol fee recipient
     * @param _WETH address of the WETH contract. It's input to constructor to allow for testing.
     * @param _nftrAddress address of the NFT Registry contract
     */
    constructor(address _protocolFeeRecipient, address _WETH, address _nftrAddress) {
        require(_protocolFeeRecipient != address(0), "NamingCredits: protocolFeeRecipient can't be set to the zero address");       
        require(_WETH != address(0), "NamingCredits: WETH can't be set to the zero address");              
        require(_nftrAddress != address(0), "NamingCredits: nftrAddress can't be set to the zero address");                 
        protocolFeeRecipient = _protocolFeeRecipient;
        WETH = _WETH;
        assignmentsAllowed = AssignmentsAllowed.YES;
        assignerAssignmentsAllowed = AssignmentsAllowed.YES;
        nftrAddress = INFTRegistry(_nftrAddress);
        tempAdmin = msg.sender;
        transferOwnership(_nftrAddress);
    }  

    /**
     * @notice Transfer tempAdmin status to another address
     * @param newAdmin address of the new tempAdmin address
     */
    function transferTempAdmin(address newAdmin) external onlyTempAdmin {
        require(newAdmin != address(0), "NamingCredits: tempAdmin can't be set to the zero address");               
        
        tempAdmin = newAdmin;
    }        

    /**
     * @notice Set the address of the RNM contract. Can only be set once.
     * @param _rnmAddress address of the RNM contract
     */
    function setRNMAddress(address _rnmAddress) external onlyTempAdmin {
        require(address(rnmAddress) == address(0), "NamingCredits: RNM address can only be set once");
        
        rnmAddress = IRNM(_rnmAddress);

        emit RNMAddressSet(address(rnmAddress));
    }       

    /**
     * @notice Update the recipient of protocol (naming credit) fees in WETH
     * @param _protocolFeeRecipient protocol fee recipient
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external override onlyOwner {
         require(allowUpdatingFeeRecipient, "NFTRegistry: Updating the protocol fee recipient has been shut off");
        require(_protocolFeeRecipient != address(0), "NamingCredits: protocolFeeRecipient can't be set to the zero address");                
        require(protocolFeeRecipient != _protocolFeeRecipient, "NamingCredits: Setting protocol recipient to the same value isn't allowed");
        protocolFeeRecipient = _protocolFeeRecipient;

        emit NewProtocolFeeRecipient(protocolFeeRecipient);
    }        

    /**
     * @notice Shut off protocol fee recipient updates
     */
    function shutOffFeeRecipientUpdates() external onlyTempAdmin {
        allowUpdatingFeeRecipient = false;
    }        

    /**
     * @notice Buy naming credits
     * @param numberOfCredits number of credits to buy
     * @param buyWithETH whether to buy with ETH or RNM
     * @param currencyQuantity quantity of naming currency to spend. This disables the NFTRegistry contract owner from being able to front-run naming to extract unintended quantiy of assets (WETH or RNM)
     */
    function buyNamingCredits(uint256 numberOfCredits, BuyWithETH buyWithETH, uint256 currencyQuantity) external payable nonReentrant {     

        if (buyWithETH == BuyWithETH.YES) {
            require(currencyQuantity == (numberOfCredits * nftrAddress.namingPriceEther()), "NamingCredits: when purchasing with Ether, currencyQuantity must be equal to namingPriceEther multiplied by number of credits");             

            // If not enough ETH to cover the price, use WETH
            if (currencyQuantity > msg.value) {
                require(IERC20(WETH).balanceOf(msg.sender) >= (currencyQuantity - msg.value), "NFTRegistry: Not enough ETH sent or WETH available");
                IERC20(WETH).transferFrom(msg.sender, address(this), currencyQuantity - msg.value);
            } else {
                require(currencyQuantity == msg.value, "NFTRegistry: Too much Ether sent");
            }

            // Wrap ETH sent to this contract
            IWETH(WETH).deposit{value: msg.value}();
            IERC20(WETH).transfer(protocolFeeRecipient, currencyQuantity);

        }
        else { // Buying with RNM
            require(address(rnmAddress) != address(0), "NamingCredits: RNM address hasn't been set yet");
            require(currencyQuantity == (numberOfCredits * nftrAddress.namingPriceRNM()), "NamingCredits: when purchasing with RNM, currencyQuantity must be equal to namingPriceRNM multiplied by number of credits");          

            IERC20(rnmAddress).transferFrom(msg.sender, address(this), currencyQuantity);
            rnmAddress.burn(currencyQuantity);
        }

        // Add credits
        credits[msg.sender] += numberOfCredits;

        emit CreditsBought(msg.sender, numberOfCredits, buyWithETH, currencyQuantity);
    }

    /**
     * @notice Assign naming credits as incentives. There is the ability to shut this down and never bring it back.
     * @param user the address to which naming credits will be assigned
     * @param numberOfCredits number of credits to assign
     */
    function assignNamingCredits(address user, uint256 numberOfCredits) external override nonReentrant  {

        require((msg.sender == owner()) || (assigners[msg.sender] >= numberOfCredits && assignerAssignmentsAllowed == AssignmentsAllowed.YES), "NamingCredits: Only owner (until maxed out) or assigner (temporarily) can assign credits.");
        require((credits[user] + numberOfCredits) <= MAX_CREDITS_ASSIGNED, "NamingCredits: Too many credits to assign");
        require(assignmentsAllowed == AssignmentsAllowed.YES, "NamingCredits: Assigning naming credits has been shut off forever");

        // Add credits
        if (msg.sender != owner()) {
            assigners[msg.sender] -= numberOfCredits;
        }
        credits[user] += numberOfCredits;

        emit CreditsAssigned(msg.sender, user, numberOfCredits);
    } 

    /**
     * @notice Assign naming credits as incentives in bulk. There is the ability to shut this down and never bring it back.
     * @param numberOfCredits number of credits to assign
     */
    function assignNamingCreditsBulk(address[] calldata user, uint256[] calldata numberOfCredits) external nonReentrant {

        require((msg.sender == owner()) || (assigners[msg.sender] != 0 && assignerAssignmentsAllowed == AssignmentsAllowed.YES), "NamingCredits: Only owner (until maxed out) or assigner (temporarily) can assign credits.");
        require(assignmentsAllowed == AssignmentsAllowed.YES, "NamingCredits: Assigning naming credits has been shut off forever");    
        require(user.length == numberOfCredits.length, "NamingCredits: Assignment arrays must have the same length");   
        require(user.length <= MAX_BULK_ASSIGNMENT, "NamingCredits: Can't assign to so many addresses in bulk");
        uint256 len = user.length;
        uint256 creditNum;
        for (uint256 i; i < len;) {
            creditNum = numberOfCredits[i];
            require((credits[user[i]] + creditNum) <= MAX_CREDITS_ASSIGNED, "NamingCredits: Too many credits to assign");

            // Add credits
            if (msg.sender != owner()) {
                require(assigners[msg.sender] >= creditNum, "NamingCredits: Not enough credits left to assign by this assigner");
                assigners[msg.sender] -= creditNum;
            }            
            credits[user[i]]+=creditNum;

            emit CreditsAssigned(msg.sender, user[i], creditNum);
            
            unchecked {i += 1;}
        }
    }     

    /**
     * @notice Add assignment credit to an assigner
     * @param assigner new assigner
     * @param numberOfCredits number of credits to assign to assigner
     */
     function addAssignerCredits(address assigner, uint256 numberOfCredits) external onlyTempAdmin {
        require((assigners[assigner] + numberOfCredits) <= MAX_ASSIGNER_CREDITS, "NamingCredits: That assignment would take assigner balance over the limit");
        assigners[assigner] += numberOfCredits;
        emit AssignerCreditsAdded(assigner, numberOfCredits);
     }     

    /**
     * @notice Null an assigner's assignment allowance
     * @param assigner credit assigner
     */
     function nullAssignerCredits(address assigner) external onlyTempAdmin {
        assigners[assigner] = 0;
     }        

    /**
     * @notice Shut off naming credit assignments by assigner. It can't be turned back on.
     */
    function shutOffAssignerAssignments() external override onlyTempAdmin {        

        assignerAssignmentsAllowed = AssignmentsAllowed.NO;

        emit AssignerAssignmentsShutOff();
    }        

    /**
     * @notice Shut off naming credit assignments in general. It can't be turned back on.
     */
    function shutOffAssignments() external override onlyOwner {

        assignmentsAllowed = AssignmentsAllowed.NO;

        emit AssignmentsShutOff();
    }        

    /**
     * @notice Consume naming credits. Meant to be consumed by the owner which is the NFTRegistry contract.
     * @param sender the account naming the NFT
     * @param numberOfCredits number of credits to consume
     */
    function reduceNamingCredits(address sender, uint256 numberOfCredits) external override onlyOwner {
        require(credits[sender] >= numberOfCredits, "NamingCredits: Not enough credits");
        credits[sender] -= numberOfCredits;
        
        emit CreditsConsumed(sender, numberOfCredits);
    }

}