// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGnosisSettlement{
    function setPreSignature(
        bytes calldata orderUid, 
        bool signed) external;
}

interface IERC20{
    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);
    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IDSProxy {
    function execute(
        address _targetAddress,
        bytes calldata _data
    ) external payable returns (bytes32);

    function setOwner(address _newOwner) external;
}

contract CowContract {

    address owner;
    address gnosisSettlement = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;

    constructor(){
        owner = msg.sender;
    }

    function sendSetSignatureTx(
        bytes calldata orderUid, 
        bool signed) 
        external
    {
        require(msg.sender == owner, "NotOwner");
        IGnosisSettlement(gnosisSettlement).setPreSignature(orderUid,signed);
    }   

    function approveRelayer(
        address token,
        uint256 amount
    ) external {
        require(msg.sender == owner, "NotOwner");
        address gnosisVaultRelayer = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;
        IERC20(token).approve(gnosisVaultRelayer, amount);
    }

    function withdrawToken(
        address token,
        uint256 amount
    ) 
        external
    {
        require(msg.sender == owner, "NotOwner");
        IERC20(token).transfer(msg.sender,amount);
    }

}