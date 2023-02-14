//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IDXBL.sol";
import "hardhat/console.sol";

/**
 * The DXBL Token. It uses a minter role to control who can mint and burn tokens. That is 
 * set to the CommunityVault contract so that it completely controls the supply of DXBL.
 */
contract DXBL is ERC20, IDXBL {

    //minter allowed to mint/burn. This should be revshare contract
    address public minter;
    
    //discount bps per DXBL owned 5 = .05%
    uint32 public discountPerTokenBps;


    //restrict function to only minter address
    modifier onlyMinter() {
        require(msg.sender == minter, "Unauthorized");
        _;
    }

    event DiscountRateChanged(uint32 newRate);
    event MinterProposed(address newMinter);
    event NewMinter(address minter);

    //minter is revshare vault
    constructor(address _minter, 
                uint32 discountRate,
                string memory name, 
                string memory symbol) ERC20(name, symbol) {
                    
        _minterIsContract(_minter);
        minter = _minter;
        discountPerTokenBps = discountRate;
    }

    //time-locked change from revshare vault configuration
    function setDiscountRate(uint32 discount) external override onlyMinter {
        discountPerTokenBps = discount;
        emit DiscountRateChanged(discount);
    }

    /**
     * Minter can change minter address if there was a fork of the minter contract. All security
     * associated with minter changes is managed at the revshare vault level.
     */
    function setNewMinter(address newMinter) external override onlyMinter {
        _minterIsContract(newMinter);
        minter = newMinter;
        emit NewMinter(minter);
    }

    /**
     * Compute how much of a discount to give for a trade based on how many
     * DXBL tokens the trader owns. Apply a min fee if total is less than 
     * min required.
     */
    function computeDiscountedFee(FeeRequest calldata request) external view override returns(uint) {

        //compute the standard rate fee
        uint fee = ((request.amt * request.stdBpsRate) / 10000);
        if(request.referred) {
            //apply 10% discount if referred by affiliate
            fee -= ((fee * 10) / 100);
        }
        
       //get the trader's DXBL token balance
        uint bal = request.dxblBalance;
        if(bal == 0) {
            return fee;
        }
        
        //determine what their discount is based on their balance
        uint discRate = (bal * discountPerTokenBps)/10000;
        
        //and the min fee required
        uint minFee = ((request.amt * request.minBpsRate) / 10000);
        
        uint disc = (fee * discRate) / 1e18;
        if(disc > fee) {
            return minFee;
        }

        //apply the discount percentage but divide out DXBL token decimals
        fee -= disc;
        if(fee < minFee) {
            fee = minFee;
        }
        return fee;
    }

    /**
     * Mint new tokens for a trader. Only callable by the assigned minter contract
     */
    function mint(address receiver, uint amount) public override onlyMinter {
        _mint(receiver, amount);
    }

    /**
     * Burn tokens from a trader. Only callable by the assigned minter contract
     */
    function burn(address burner, uint amount) public override onlyMinter {
        _burn(burner, amount);
    }

    /**
        NO OP
     */
    function _beforeTokenTransfer(address from, address to, uint amount) internal override  {

    }

    /**
        NO OP
     */
    function _afterTokenTransfer(address from, address to, uint amount) internal override  {

    }

    /**
     * Mostly public assurance that address is a contract and not a random wallet
     */
    function _minterIsContract(address _minter) internal view {

        //sanity to make sure minter is a contract and not a random address
        require(_minter != address(0), "Invalid minter");
        uint32 size;
        assembly {
            size := extcodesize(_minter)
        }
        require (size > 0, "Minter must be a contract");
    }
}