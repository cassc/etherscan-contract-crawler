// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
abstract contract Presale is ERC20, Ownable{
    // events
    event ethRaised(address,uint256);

    // state variables
    uint256 public immutable LGESupply;
    uint256 public immutable endTime;

    bool public LGEComplete = false;
    address public pair;
    address public immutable  LPTokenReceiver;
    IUniswapV2Router02 public constant UniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public immutable UniswapV2Factory;

    /**
    * @dev constructor 
     */
    constructor(    
        uint256 _LGESupply,
        uint256 _devFee,                  
        address _LPTokenReceiver,   
        uint256 _endTime,
        string memory _name,
        string memory _symbol
        )                                     
    ERC20(_name, _symbol)
    Ownable()
    {
        LGESupply = _LGESupply;
        _mint(address(this),_LGESupply);
        _mint(owner(),_devFee);
        LPTokenReceiver = _LPTokenReceiver;
        endTime = _endTime;
        UniswapV2Factory = IUniswapV2Factory(UniswapV2Router02.factory());
    }

    receive() external payable {
        require(!LGEComplete, "LGE Already over");
        emit ethRaised(msg.sender, msg.value);
    }

    /**
    * @dev sweep function removes tokens in contract and sends em to owner
    * @notice sweep can only be prefomed after LGE so as to aleviate rug concerns
    * function is mostly for tokens sent by mistake, or for things with LP tokens
    * @param _token to sweep
     */
    function sweep(address _token) external onlyOwner{
        require(_isOver(), "LGE must be complete");
        uint256 bal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), bal);
    }

    /**
    * @dev for eth stuck in contract
     */
    function emergencySweepETH() external onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * @dev at end of LGE the liquidity is sent to uniswap
     */
    function endLGE() public virtual onlyOwner{
        //requires
        require(_isOver(), "endTime must be reached to end");
        require(!LGEComplete, "LGE already ended");        
                                                  
        _approve(address(this), address(UniswapV2Router02),LGESupply);       
        UniswapV2Router02.addLiquidityETH                                   
        {value:address(this).balance}                                              
        (
            address(this),                                                                
            LGESupply,                                                                            
            LGESupply,                                                                    
            address(this).balance,
            LPTokenReceiver,                                                                 
            block.timestamp+30
        );        
        pair = UniswapV2Factory.getPair(address(this), UniswapV2Router02.WETH());                                                      
        LGEComplete = true;                  
    }

    /// @dev same as endLGE but with 0 requirements for tokens back. In case of issues deploying liquidity
    function emergencyEndLGE() external onlyOwner{
        //requires
        require(_isOver(), "endTime must be reached to end");
        require(!LGEComplete, "LGE already ended");                                                  
        _approve(address(this), address(UniswapV2Router02),LGESupply);       
        UniswapV2Router02.addLiquidityETH                                   
        {value:address(this).balance}                                              
        (
            address(this),                                                                
            LGESupply,                                                                            
            0,                                                                    
            0,
            LPTokenReceiver,                                                                 
            block.timestamp+30
        );                                                              
       
        LGEComplete = true;                  
    }

    /**
    * @dev returns true if LGE is over 
    */
    function _isOver() private view returns(bool){
        if(block.timestamp >= endTime){
            return true;
        }else{
            return false;
        }
    }




}