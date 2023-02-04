// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;
import "./IPancakeRouter02.sol";
import "./IERC20.sol";

contract callerContract{
    uint256 public value;
    address public sender;
    string  public name;
    bool    public callSuccess;
    event teste(string retorno);
    constructor() payable{
  
    }
    receive() external payable{

    }
    function swapTokensForTokensToCreator(address router, uint256 tokenAmount, address _token, address _tokenReceive) public  {
        IERC20(_token).approve(router, tokenAmount);
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _tokenReceive;
        IERC20(_token).approve(router, tokenAmount);
        IPancakeRouter02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function swapTokensForEthToCreator(address router, uint256 _tokenAmount, address _token) public {
        IERC20(_token).approve(router, _tokenAmount);
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = IPancakeRouter02(router).WETH();
        IERC20(_token).approve(router, _tokenAmount);
        IPancakeRouter02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    function swapEthForTokensToCreator(address router, uint256 _tokenAmount, address _token) public {
        address[] memory path = new address[](2);
        path[0] = IPancakeRouter02(router).WETH();
        path[1] = _token;
        IERC20(_token).approve(router, _tokenAmount);
        IPancakeRouter02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value:_tokenAmount}(
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    function destroy() public{
        selfdestruct(payable(msg.sender));
    }
}

contract targetContractDelegate{
    
    address public sender;
    uint256 public value;
    string  public name;
    address public senderLocal;
    
    event Test(uint value, address sender, string texto);

    function targetFunction(string memory _nameTarget) public payable{
        if(bytes(_nameTarget).length > 10){
            require(false, "Erro do destino");
        }
        emit Test(msg.value, msg.sender, _nameTarget);
    }
    function targetFunction2(string memory _nameTarget) public payable{
        emit Test(msg.value, msg.sender, _nameTarget);
    }
    function buyToken(address pancakeRouter, address token0, address token1, uint256 amount) public{
        (bool success, bytes memory return_data) = pancakeRouter.delegatecall(abi.encodeWithSelector(IPancakeRouter02.swapExactTokensForTokensSupportingFeeOnTransferTokens.selector,
            amount,
            0,
            [token0, token1],
            msg.sender,
            block.timestamp)
        );
        if(!success){
            if(return_data.length > 0){
                /// @solidity memory-safe-assembly
                assembly {
                    let return_data_size := mload(return_data)
                    revert(add(32,return_data),return_data_size)
                }
            }else {
                revert("Error at rebuy with StableCoin");
            }
        }
    }
}