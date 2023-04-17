pragma solidity ^0.8.0;

interface IFountain 
{

    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)  external view returns (uint256);
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve)  external view returns (uint256);
    
    function bnbToTokenSwapInput(uint256 min_tokens) external payable returns (uint256);
    function bnbToTokenSwapOutput(uint256 tokens_bought) external payable returns (uint256);
    


   function getBnbToTokenInputPrice(uint256 bnb_sold) external view returns (uint256);
   function getBnbToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);
   function getTokenToBnbInputPrice(uint256 tokens_sold) external view returns (uint256);
   function getTokenToBnbOutputPrice(uint256 bnb_bought) external view returns (uint256);
   function tokenAddress() external view returns (address);
   function getBnbToLiquidityInputPrice(uint256 bnb_sold) external view returns (uint256);
   function getLiquidityToReserveInputPrice(uint amount) external view returns (uint256, uint256);


}