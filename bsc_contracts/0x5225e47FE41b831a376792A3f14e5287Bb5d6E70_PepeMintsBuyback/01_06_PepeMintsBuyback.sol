pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./BoringOwnable.sol";


interface IPancakeFactory {
    function getPair(address token1, address token2) external pure returns (address);
}

interface IPepeMints {
    function burn(uint amounts) external;
}

contract PepeMintsBuyback is BoringOwnable, ReentrancyGuard {
  
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IPepeMints public pepeMints;

    address public _token1Receiver = 0x000000000000000000000000000000000000dEaD; // we want to burn IPepeMints tokens
    address public _token2Receiver = 0xBFF8a1F9B5165B787a00659216D7313354D25472; // TODO check if this is the right address to receive token 2 (Drip)
    address public _token3Receiver;

    address public contrAddr;

    address public addressToken1; // PepeMints, to set in constructor
    address public addressToken2 = 0x20f663CEa80FaCE82ACDFA3aAE6862d246cE0333;  // DRIP
    address public addressToken3 = 0x0000000000000000000000000000000000000000;  // 0x0

    address public constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02 _pancakeRouter;

    uint public share1 = 8000;
    uint public share2 = 2000;
    uint public share3 = 0;


    /* Time of contract launch */
    uint256 public LAUNCH_TIME;
    uint256 public oneWeek = 30 minutes;// TODO: change back to 7 days
    uint256 public currentWeek = 0;
    

    constructor(uint _LAUNCH_TIME, IPepeMints _pepeMints) {
        LAUNCH_TIME = _LAUNCH_TIME;
        pepeMints = _pepeMints;

        addressToken1 = address(pepeMints);

        _pancakeRouter = IUniswapV2Router02(_pancakeRouterAddress);
        contrAddr = address(this);
    }

    function setTokenReceivers(address token1Receiver,  address token2Receiver,  address token3Receiver) external onlyOwner {
        _token1Receiver = token1Receiver;
        _token2Receiver = token2Receiver;
        _token3Receiver = token3Receiver;
    }

    // Set lenght of "one Week"
    function lengtOfWeek (uint256 _oneWeek) external onlyOwner {
        oneWeek = _oneWeek;
    }

    // Set buyback schare 1 and 2
    function setBuyBackShare(uint _share1, uint _share2, uint _share3) external onlyOwner {
      require(_share1 + _share2 + _share3 <= 10000, "Share1 + Share2 + Share3 can`t be more than 100!");
        share1 = _share1;
        share2 = _share2;
        share3 = _share3;
    }

    // Set Address token1 token2
    // BOTH token need a Liquidity with WETH on the Pancake Router!
    function setTokenAddresses(address _token1, address _token2, address _token3) external onlyOwner {
        addressToken1 = _token1;
        addressToken2 = _token2;
        addressToken3 = _token3;
    }

    // function to see which week it is
    function thisWeek() public view returns (uint256) {
        if (LAUNCH_TIME > block.timestamp) return 0;
        return (block.timestamp - LAUNCH_TIME) / oneWeek;
    }

    // time in seconds until next week starts
    function whenNextWeek() public view returns (uint256) {
        if (LAUNCH_TIME > block.timestamp) return LAUNCH_TIME - block.timestamp;
        return oneWeek - (block.timestamp - (LAUNCH_TIME + thisWeek() * oneWeek));
    }

    // receive all token from contract
    function getAllToken(address token) public onlyOwner {
        uint256 amountToken = IERC20(token).balanceOf(contrAddr);
        IERC20(token).transfer(owner, amountToken);
    }

    function recoverETH(address to, uint amount) external onlyOwner {
        if (amount > 0) {
        (bool transferSuccess, ) = payable(to).call{
            value: amount
        }("");
        require(transferSuccess, "ETH transfer failed");
        }
    }

    // to make the contract being able to receive ETH
    receive() external payable {}

    // function to buyback 2 different token with the collected USDC
    function burnAndBuyback () public nonReentrant {   
        require(LAUNCH_TIME < block.timestamp, "BuyBacks not started yet!");
        require(currentWeek != thisWeek(), "BuyBack already happened this Week!");     
        currentWeek = thisWeek(); 
 
        uint256 ethBal = contrAddr.balance;

        if (ethBal > 1000000) {  // check if there is an usable amount of eth in the contract
            burnAndBuybackForPartner(addressToken1, _token1Receiver, share1, ethBal);
            burnAndBuybackForPartner(addressToken2, _token2Receiver, share2, ethBal);
            burnAndBuybackForPartner(addressToken3, _token3Receiver, share3, ethBal);
        }
    }

    function burnAndBuybackForPartner(address tokenAddress, address tokenReceiver, uint shareBP, uint ethBalance) internal {
        uint256 buyBackShare = ethBalance * shareBP / 10000;
        if (buyBackShare > 100000 && tokenAddress != address(0)) {
            uint256 tokenBalBefore = IERC20(tokenAddress).balanceOf(contrAddr);

            address[] memory path = new address[](2);
            path[0] = _pancakeRouter.WETH();
            path[1] = tokenAddress;
            
            // Buyback token 2 from LP from received USDC
            _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: buyBackShare}(
                0,
                path,
                contrAddr,
                block.timestamp+1
            );

            // send received Token to _tokenReceiver
            uint256 receivedToken = IERC20(tokenAddress).balanceOf(contrAddr) - tokenBalBefore;
            if (receivedToken > 10000){
                if (tokenAddress == address(pepeMints) && (tokenReceiver == BURN_ADDRESS || tokenReceiver == address(0)))
                    pepeMints.burn(receivedToken);
                else
                    IERC20(tokenAddress).transfer(tokenReceiver, receivedToken);
            }
        }
    }
}