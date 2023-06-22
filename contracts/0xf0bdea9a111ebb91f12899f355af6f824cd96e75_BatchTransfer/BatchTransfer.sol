/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
} 

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract BatchTransfer {

    function batchERC721Transfer(
        address erc721Address,
        address[] calldata tos,
        uint256[] calldata ids
    ) external {
        require(tos.length == ids.length, "PARAM_NOT_MATCH");
        for (uint8 i = 0; i < ids.length; i++) {
            IERC721(erc721Address).transferFrom(msg.sender,tos[i],ids[i]);
        }
    }

    function batchERC20Transfer(
        address _token,
        address[] calldata tos,
        uint256[] calldata amounts
    ) external {
        require(tos.length == amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        IERC20 token = IERC20(_token); 
        uint _amountSum = getSum(amounts); 
        require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token");
        
        for (uint256 i; i < tos.length; i++) {
            token.transferFrom(msg.sender, tos[i], amounts[i]);
        }
    }

    function batchETHTransfer(
        address payable[] calldata tos,
        uint256[] calldata amounts
    ) external payable {
        require(tos.length == amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        uint _amountSum = getSum(amounts);
        require(msg.value == _amountSum, "Transfer amount error");
        for (uint256 i = 0; i < tos.length; i++) {
            tos[i].transfer(amounts[i]);
        }
    }

    function getSum(uint256[] calldata _arr) private pure returns(uint sum)
    {
        for(uint i = 0; i < _arr.length; i++)
            sum = sum + _arr[i];
    }
}