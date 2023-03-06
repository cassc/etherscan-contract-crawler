// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "IPancakeRouter02.sol";
import "IPancakePair.sol";
import "IERC20.sol";
import "IWETH.sol";
import "IERC3156FlashBorrower.sol";
import "Ownable.sol";


contract SathnaStableArb is Ownable, IERC3156FlashBorrower{

    address wrappedNative;
    address Beneficiary;
    address bank;

    RouterArgs[] routerArgsList;

    constructor(address _wrappedNative, address _Beneficiary, address _bank) public {
        wrappedNative = _wrappedNative;
        Beneficiary = _Beneficiary;
        bank = _bank;

    }
    function changeWrappedNative(address _wrappedNative) external onlyOwner {
        wrappedNative = _wrappedNative;
    }
    function changeBeneficiary(address _beneficiary) external onlyOwner {
        Beneficiary = _beneficiary;
    }
    function changeBank(address _bank) external onlyOwner {
        bank = _bank;
    }

    function getBank() view public onlyOwner returns(address) {

        return bank;
    }

    function getBeneficiary() view public onlyOwner returns(address) {

        return Beneficiary;
    }
    function getWrappedNative() view public onlyOwner returns(address) {

        return wrappedNative;
    }


    struct RouterArgs {
        address tokenIn; 
        address tokenOut;
        uint amountIn;
        uint amountOutMin;
        address router;
        uint16 timeOutSecs;
    }

    event BalanceChanged(uint256 tokenA, uint256 tokenB);

    // to receive native from external contracts
    receive() payable external{}

    // just returns amountIn or balance of a token that contract stored
    function getAmountIn(IERC20 _tokenIn, uint _amountIn) private returns(uint) {
        
        if (_amountIn == 0) {

            return _tokenIn.balanceOf(address(this));
            
        }
        else {
            return _amountIn;
        }
        
        

    } 

    // just do a swap on UniswapV2 like exchanges
    function swapExactInputForOutput(
        RouterArgs memory routerArgs
        )

     private {
        // Initialize router and tokens
        address[] memory path = new address[](2);
        path[0] =   routerArgs.tokenIn;
        path[1] = routerArgs.tokenOut;
        

        IERC20 tokenIn = IERC20(routerArgs.tokenIn);
        IERC20 tokenOut = IERC20(routerArgs.tokenOut);
        IPancakeRouter02 router = IPancakeRouter02(routerArgs.router);

        uint amountIn = getAmountIn(tokenIn, routerArgs.amountIn);

        if (tokenIn.allowance(address(this), address(router)) < amountIn) {
            require(tokenIn.approve(address(router), amountIn), "Approval Failed");
        }
        
        
        uint deadline = block.timestamp + routerArgs.timeOutSecs; // e.d. timeOutSecs=10,  10 secs
        // swapping
        router.swapExactTokensForTokens(amountIn, routerArgs.amountOutMin, path, address(this), deadline);
        
        emit BalanceChanged(tokenIn.balanceOf(address(this)), tokenOut.balanceOf(address(this)));

    }
    
    // merge all deals in a single for loop
    function swapThemAll() public {
        
        require(address(msg.sender) == bank || address(msg.sender) == owner(), "YOU SHALL NOT PASS!");
        
        for (uint i=0; i <routerArgsList.length; i++ ) {
            
            swapExactInputForOutput(routerArgsList[i]);


        }
    }


    // filling routerArgsList variable
    function fillRouterArgsList(RouterArgs[] memory _routerArgsList) external onlyOwner {
        
        // delete all previous elements from routerArgsList
        if (routerArgsList.length>0) {
            delete routerArgsList;
        }

        for(uint256 i = 0; i < _routerArgsList.length; i++)
            routerArgsList.push(_routerArgsList[i]);
        } 


    // withdraw funds
    function withdraw(uint percentFee) onlyOwner external  {

        // casting all currencies to the wrapped native
        castToWrappedNative();
        
        IWETH WRAPPED = IWETH(wrappedNative);

        address payable owner = payable(owner());
        address payable ben = payable(Beneficiary);
        uint balance = WRAPPED.balanceOf(address(this));
        WRAPPED.withdraw(balance);
        uint gasFee = address(this).balance * percentFee / 100;
        owner.transfer(gasFee);
        ben.transfer(address(this).balance);

    }

    // casting all lefted currencies to the wrapped native
    function castToWrappedNative() private {
        
        for (uint i=0; i <routerArgsList.length; i++ ) {

            IWETH WRAPPED = IWETH(wrappedNative);
            IERC20 tokenIn = IERC20(routerArgsList[i].tokenIn);
            IERC20 tokenOut = IERC20(routerArgsList[i].tokenOut);
            address routerAddress = routerArgsList[i].router;
            
            uint tokenInBalance = tokenIn.balanceOf(address(this));
            uint tokenOutBalance = tokenOut.balanceOf(address(this));

            if (tokenInBalance > 0 && address(tokenIn) != address(WRAPPED))
            {

                swapExactInputForOutput(
                    RouterArgs(
                        address(tokenIn),
                        address(WRAPPED),
                        tokenInBalance,
                        0,
                        routerAddress,
                        routerArgsList[i].timeOutSecs
                    )
                );
                emit BalanceChanged(tokenIn.balanceOf(address(this)), WRAPPED.balanceOf(address(this)));

            }

            else if (tokenOutBalance > 0 && address(tokenOut) != address(WRAPPED))
            {

                swapExactInputForOutput(
                    RouterArgs(
                        address(tokenOut),
                        address(WRAPPED),
                        tokenOutBalance,
                        0,
                        routerAddress,
                        routerArgsList[i].timeOutSecs
                    )
                );

                emit BalanceChanged(tokenOut.balanceOf(address(this)), WRAPPED.balanceOf(address(this)));

            }

        }
    }


    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
        // RouterArgs[] memory routerArgsList
    ) external override returns (bytes32) {
        

        // Set the allowance to payback the flash loan
        IERC20(token).approve(address(msg.sender), amount);
        
        // Build your trading business logic here
        swapThemAll();
        emit BalanceChanged(IERC20(token).balanceOf(address(this)), 0);

        // Return success to the lender, he will transfer get the funds back if allowance is set accordingly
        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }
}