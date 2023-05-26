pragma solidity ^0.8.11;

import "communal/ReentrancyGuard.sol";
import "communal/Owned.sol";
import "communal/SafeERC20.sol";
import "communal/TransferHelper.sol";
import "forge-std/console.sol";

/*
* LSD Vault Contract:
* This contract is responsible for holding and managing the deposited LSDs. It mints unshETH to depositors.
*/


interface ILSDRegistry {
    function vaultAddress() external view returns (address);
    //ratios should be in the form of [0.25e18, 0.25e18, 0.25e18, 0.25e18] for 4 LSDs
    function targetRatio() external view returns (uint256[] memory);
    function lsdAddresses() external view returns (address[] memory);
    function shanghaiTime() external view returns (uint256);
    function nonce() external view returns (uint256);
}

interface IunshETH {
    function minter_mint(address m_address, uint256 m_amount) external;
    function minter_burn_from(address b_address, uint256 b_amount) external;
}

interface IDarknet {
    function checkPrice(address lsd) external view returns (uint256);
}

contract LSDVault is Owned, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /*
    ============================================================================
    State Variables
    ============================================================================
    */
    // address public admin;
    uint256 public shanghaiTime = 1680307199; //timestamp for March 31, 2023
    address public unshETHAddress;
    address[] public supportedLSDs;
    address public registryAddress;
    address private darknetAddress;
    uint256 public tabs;
    bool paused = false;
    //mapping for fast lookup to see if an LSD is supported
    mapping(address => bool) isSupported; 

    uint256 public nonce; 
    /*
    ============================================================================
    Events
    ============================================================================
    */

    /*
    ============================================================================
    Constructor
    ============================================================================
    */
    constructor(address _owner, address _registryAddress, address _darknetAddress, address _unshethAddress) Owned(_owner){
        registryAddress = _registryAddress;
        darknetAddress = _darknetAddress;
        unshETHAddress = _unshethAddress;
        _synchronize();
        tabs = supportedLSDs.length;
        console.log('tabs: %s', tabs);
    }
    /*
    ============================================================================
    Functions
    ============================================================================
    */
    modifier requireSync {
        require(nonce == ILSDRegistry(registryAddress).nonce(), "Out of sync with registry");
        _;
    }

    //updates isSupported so we can quickly check if an LSD is supported before deposit
    //needs to be called each time the supportedLSDs are changed

    function synchronize() external {
        require(nonce != ILSDRegistry(registryAddress).nonce(), "Already synchronized");
        _synchronize();
    }

    function _synchronize() internal {
        supportedLSDs = ILSDRegistry(registryAddress).lsdAddresses();
        //update lookup table 
        for (uint256 i = 0; i < supportedLSDs.length; i++) {
            isSupported[supportedLSDs[i]] = true;
        }
        nonce = ILSDRegistry(registryAddress).nonce();
    }

    function disableLSD(address lsd) external returns(bool) {
        require(msg.sender == registryAddress, "Only registry can disable");
        isSupported[lsd] = false;
        return true;
    }

    function setLSDRegistry(address _registryAddress) external onlyOwner {
        require(registryAddress == address(0), "Registry address already set" );
        registryAddress = _registryAddress;
        _synchronize();
    }
    
    function setUnshethAddress(address _unshethAddress) external onlyOwner {
        require(unshETHAddress == address(0), "UnshETH address already set" );
        unshETHAddress = _unshethAddress;
    }

    function getPrice(address lsd) public view returns(uint256) {
        require(isSupported[lsd], "Unsupported token");
        uint256 marketRate = IDarknet(darknetAddress).checkPrice(lsd);
        if(IERC20(unshETHAddress).totalSupply() == 0){
            return marketRate;
        }
        else {
            return 1e18*stakedETHperunshETH()/marketRate;
        }
    }

    //takes a supported LSD and mints unshETH to the user in proportion
    function deposit(address lsd, uint256 amount) public requireSync {
        //check if not paused
        require(paused == false);
        //check that the LSD is supported
        require(isSupported[lsd], "Unsupported token");
        uint256 price = getPrice(lsd);
        TransferHelper.safeTransferFrom(lsd, msg.sender, address(this),amount) ; 
        //TODO: check success; maybe test with insufficient gas? 
        IunshETH(unshETHAddress).minter_mint(msg.sender, price*amount/1e18);
    }

    function shanghaiDelayed() public view returns (bool) {
        //check if shanghai has been delayed
        return (shanghaiTime < ILSDRegistry(registryAddress).shanghaiTime());
    }

    function balanceInUnderlying() public view returns (uint256) {
        uint256 underlyingBalance = 0;
        for (uint256 i = 0; i < tabs; i++) {
            uint256 rate = IDarknet(darknetAddress).checkPrice(supportedLSDs[i]);
            console.log('rate: %s', rate);
            underlyingBalance += rate*IERC20(supportedLSDs[i]).balanceOf(address(this))/1e18;
            console.log('underlyingBalance: %s', underlyingBalance);
        }
        return underlyingBalance;
    }

    //always lowercase u
    function stakedETHperunshETH() public view returns (uint256) {
        return 1e18*balanceInUnderlying()/IERC20(unshETHAddress).totalSupply();
    }

    //post-shanghai cases
    
    //calculate and store the payout ratio once so every exit tx doesn't need a loop
    // uint256[] public lsdPayoutRatios;
    // function preparePayout() external {
    //     require(block.timestamp > shanghaiTime, "Too early to payout");
    //     uint256 num_unshETH = IERC20(unshETHAddress).totalSupply();
    //     paused = true;
    //     uint256[] memory heldRatios = new uint256[](tabs);
    //     for (uint256 i = 0; i < supportedLSDs.length; i++) {
    //         uint256 rate = IDarknet(darknetAddress).checkPrice(supportedLSDs[i]);
    //         heldRatios[i] = IERC20(supportedLSDs[i]).balanceOf(address(this))*rate/num_unshETH;
    //     }
    //     lsdPayoutRatios = heldRatios;
    // }
    
    function exit(uint256 amount) external {
        require(block.timestamp > shanghaiTime, "Cannot exit until shanghaiTime");
        require(IERC20(unshETHAddress).balanceOf(msg.sender) >= amount,  "Insufficient unshETH");
        //transfer underlying LSDs to caller on a proportional basis
        uint256 balanceInUnderLying = balanceInUnderlying();
        uint256 totalLsdAmount = amount * balanceInUnderLying/IERC20(unshETHAddress).totalSupply();
        IunshETH(unshETHAddress).minter_burn_from(msg.sender, amount);
        for (uint256 i = 0; i < supportedLSDs.length; i++) {
            uint256 rate = IDarknet(darknetAddress).checkPrice(supportedLSDs[i]);
            uint256 stakedETHperLSD = IERC20(supportedLSDs[i]).balanceOf(address(this))*rate/1e18;
            uint256 lsdRatio = 1e18*stakedETHperLSD/balanceInUnderLying;
            uint256 amountPerLSDinEth = lsdRatio*totalLsdAmount/1e18;
            uint256 amountPerLSD = 1e18*amountPerLSDinEth/rate;
            IERC20(supportedLSDs[i]).safeTransfer(msg.sender, amountPerLSD);
        }
    }

    //Emergency functions 
    function pause() onlyOwner external {
        require(paused == false, "Already paused");
        paused = true; 
    }
}