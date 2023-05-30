// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/*                                                                    
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        
          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        
         @@@@@@                                                    @@@@@        
         @@@@@                                                     @@@@@        
         @@@@@                                                     @@@@@        
         @@@@@                      @@                             @@@@@        
         @@@@@                      @@@@@@                         @@@@         
         @@@@@                        @@@@@@@                                   
         @@@@@            @@@         @@@@@@@@@@@                               
         @@@@@             @@@@@@    @@@@@@@@@@@@@@@                            
         @@@@@              @@@@@@@@@@@@@@@@@@@@   @@@@                         
         @@@@@               @@@@@@@@@@@@@@@    @@  @@@@@@                       
         @@@@@                @@@@@@@@@@  @@@     @@@@@@@                       
         @@@@@                 @@@@@   @@  @@@@@@@@@@@@                         
         @@@@@                  @@@@       @@@@@@@@@@@                          
         @@@@@                   @@@@@@@@@@@@@@@@@@@@@                          
         @@@@@                   @@@@@@@@@@@@@@@@@@@@@@@                        
         @@@@@                      @@@@@       @@@@@@@@@                       
         @@@@@                                  @@@@@@@@@@                      
          @@@@@                                @@@@@@@@@@@@                     
           @@@@@                              @@@@@@@@@@@@@                     
            @@@@@@                          @@@@@@@@@@@@@@@                     
              @@@@@@                       @@@@@@@@@@@@@@@@                     
                @@@@@@@                  @@@@@@@@@@@@@@@@@@                     
                   @@@@@@@@@          @@@@@@@@@@@@@@@@@@@@                      
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20Extended {
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract catinaboxcdp1point1 is Multicall, AccessControl {

    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    address public synthetic;
    IERC20 public collateral;
    address public feeSplitAddress;
    address public psm;
    address public incentivesModule;

    mapping(address => uint256) public deposited;
    mapping(address => uint256) public debt;
    mapping(address => uint256) public lastPoints;
    mapping(address => bool) public enableRepaying;

    uint256 public ltv; // expressed in 10000 points
    uint256 public totaldeposits;
    uint256 public idleFee; // expressed in 100 points
    uint256 public mintingFee; // expressed in 10000 points

    // allocation logic for depositors
    uint256 public pointMultiplier = 10e18;
    uint256 public totalPoints;
    uint256 public unclaimed;
    uint256 public totalDebt;

    function Owing(address _depositor) public view returns(uint256) {
        uint256 newPoints = totalPoints - lastPoints[_depositor];
        uint256 weight = debt[_depositor];
        return (weight * newPoints) / pointMultiplier;
    }

    modifier fetch(address _depositor) {
        uint256 owing = Owing(_depositor);
        if (owing > 0) {      
            unclaimed = unclaimed - owing;
            if (debt[_depositor] < owing) {
                deposited[_depositor] += owing;
            }
            if (enableRepaying[_depositor] && debt[_depositor] >= owing) {
                collateral.transfer(psm, owing);
                totaldeposits -= owing;
                debt[_depositor] -= owing;
                totalDebt -= owing;
            }
            if (!enableRepaying[_depositor] && debt[_depositor] >= owing) {
                deposited[_depositor] += owing;
            }
        }
        lastPoints[_depositor] = totalPoints;
        _;
    }

    modifier sync() {
        uint256 excess;
        if (collateral.balanceOf(address(this)) > totaldeposits) {
            excess = collateral.balanceOf(address(this)) - totaldeposits;
        }
        if (excess > 100 && totalDebt > 0) {
            // flat % of yield 
            uint256 protocolFees = excess * idleFee / 100;
            uint256 value = excess - protocolFees;
            uint256 totalWeight = totalDebt;
            totalPoints = totalPoints + (value * pointMultiplier / totalWeight);
            unclaimed += value;
            totaldeposits += value;
            // send amount to staking module
            collateral.transfer(feeSplitAddress, protocolFees/2);
            // send amount to lp incentive module
            collateral.transfer(incentivesModule, protocolFees/2);
        }
        _;
    }

    constructor(address _synthetic, IERC20 _collateral, uint256 _ltv, address _feeSplitAddress, address _psm) {
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        synthetic = _synthetic;
        collateral = _collateral;
        feeSplitAddress = _feeSplitAddress;
        psm = _psm;
        ltv = _ltv;
        idleFee = 1;
    }

    function deposit(uint256 amount) external sync() fetch(msg.sender) {
        collateral.safeTransferFrom(msg.sender, address(this), amount);
        deposited[msg.sender] += amount;
        totaldeposits += amount;
        emit _deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external sync() fetch(msg.sender) {
        // health check
        require(amount <= deposited[msg.sender] - debt[msg.sender] * 10000 / ltv);
        deposited[msg.sender] -= amount; 
        totaldeposits -= amount;
        collateral.safeTransfer(msg.sender, amount);
        emit _withdrawal(msg.sender, amount);
    }

    function mint(uint256 amount) external sync() fetch(msg.sender) {
        require(amount <= deposited[msg.sender] * ltv / 10000 - debt[msg.sender]);
        // minting fee addition
        uint256 _size = amount*mintingFee/10000;
        debt[msg.sender] += amount + _size + _size;
        totalDebt += amount+ _size + _size;
        IERC20Extended(synthetic).mint(msg.sender, amount);
        IERC20Extended(synthetic).mint(incentivesModule, _size);
        IERC20Extended(synthetic).mint(psm, _size);
        emit _mint(msg.sender, amount);
    }

    function repay(uint256 amount) external sync() fetch(msg.sender) {
        if (amount > debt[msg.sender]) {
            amount = debt[msg.sender];
        }
        IERC20Extended(synthetic).burnFrom(msg.sender, amount);
        debt[msg.sender] -= amount;
        totalDebt -= amount;
        emit _repay(msg.sender, amount);
    }

    function liquidate(uint256 amount) external sync() fetch(msg.sender) {
        // no more than the debt can be liquidated
        if (amount > debt[msg.sender]) {
            amount = debt[msg.sender];
        }        
        totaldeposits -= amount;
        debt[msg.sender] -= amount;
        totalDebt -= amount;
        deposited[msg.sender] -= amount;
        collateral.transfer(psm, amount);
        emit _liquidate(msg.sender, amount);
    }

    function setRepayFlag(bool flag) external sync() fetch(msg.sender) {
        enableRepaying[msg.sender] = flag;
        emit _flagset(msg.sender, flag);
    }

    function stabilisePeg(uint256 amount, address _depositor) external sync() fetch(_depositor) {
        // limit the amount to 25% of the debt
        uint256 maxRedeemable = debt[_depositor] / 4;
        if (amount > maxRedeemable){
            amount = maxRedeemable;
        }
        uint256 redemptionFrictionfee = amount / 10 - amount / 10 * debt[_depositor] / deposited[_depositor]; 
        IERC20(synthetic).safeTransferFrom(msg.sender, psm, redemptionFrictionfee);
        IERC20Extended(synthetic).burnFrom(msg.sender, amount);        
        deposited[_depositor] -= amount;
        debt[_depositor] -= amount;
        totalDebt -= amount;
        totaldeposits -= amount;
        collateral.safeTransfer(msg.sender, amount);
        emit _stabilisePeg(_depositor, amount, redemptionFrictionfee);
    }

    function poke(address _depositor) external sync() fetch(_depositor)  {
        // the purpose of this function is to trigger the modifiers
    }

    function setFee(uint256 _fee) external onlyRole(ADMIN_ROLE) {
        require(_fee <= 99, "the fees are too damn high");
        idleFee = _fee;
    }

    function setMintingFee(uint256 _fee) external onlyRole(ADMIN_ROLE) {
        require(_fee <= 50, "the fees are too damn high");
        mintingFee = _fee;
    }

    function setIncentivesModule(address _module) external onlyRole(ADMIN_ROLE) {
        incentivesModule = _module;
    }

    function setFeeSplitAddress(address _feeSplitAddress) external onlyRole(ADMIN_ROLE) {
        feeSplitAddress = _feeSplitAddress;
    }
    
    function setpsm(address _psm) external onlyRole(ADMIN_ROLE) {
        psm = _psm;
    }

    event _deposit(address indexed user, uint256 indexed amount);
    event _withdrawal(address indexed user, uint256 indexed amount);
    event _mint(address indexed user, uint256 indexed amount);
    event _repay(address indexed user, uint256 indexed amount);
    event _liquidate(address indexed user, uint256 indexed amount);
    event _flagset(address indexed user, bool indexed amount);
    event _stabilisePeg(address indexed user, uint256 indexed amount, uint256 indexed fee);

    function resolvingFeePerToken(address _depositor) public view returns(uint256) {
        uint256 _amount = 1 ether / 10 - 1 ether / 10 * debt[_depositor] / deposited[_depositor];
        return (_amount);
    }

    function resolvingFeePerTokenAfterMoreDebt(address _depositor, uint256 _additionalDebt) public view returns(uint256) {
        uint256 _amount = 1 ether / 10 - 1 ether / 10 * (debt[_depositor] + _additionalDebt) / deposited[_depositor];
        return (_amount) ;
    }
}