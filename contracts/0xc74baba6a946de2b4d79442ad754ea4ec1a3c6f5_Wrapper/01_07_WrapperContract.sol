// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "@openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

interface IToken {
    function transferWithLock(address to, uint256 amount) external;
}
contract Wrapper is Ownable {
  using SafeERC20 for IERC20;  

  /// custom error
  error NotABeneficiary();  
  error AmountExceedLimit();
  error ChangeBoolValue();
  error ZeroAddressNotAllowed();
  error NativeTokenClaimNotAllowed();
  /// @notice mapping for beneficiaries
  mapping (address => bool) isBeneficiary;
  /// @notice maxTx amount (token per transaction that can sent)
  uint256 maxTxAmount = 100000 * 1e9;
  /// @notice token address
  IToken immutable public token;
  constructor (){
      /// Following wallets will be able to transfer tokens from this contract to anyone
      /// with maxTxAmount limit per transaction
      isBeneficiary[msg.sender] = true;
      isBeneficiary[0x1d5393bda55199494b7845F8a2c7BA986145BC02]=true;
      isBeneficiary[0x46C5Ca6f51A67F380259b76bb17A58bD25F64359]=true;
      token = IToken(0xEF414BaBeC56d13e96eCB2bB65ded583C1c4becE); /// Ares baby      
  }

  /// modifier to check if caller is beneficiary or not
  modifier onlyBeneficiary () {
      if(!isBeneficiary[msg.sender]){
          revert NotABeneficiary();
      }
      _;
  }
  
  ///@dev transfer token with lock period, 10% unlock per day
  /// @param to: token receiver
  /// @param amount: amount to sent
  /// Requirements -- To should not be a zero address
  ///                 receiver amount must be less than equal to maxTxAmount lifetime (using this function)
  ///                 Amount that can be sent per tx should be less than or equals to maxTxAmount
  function transferWithLock(address to, uint256 amount) external onlyBeneficiary {
      if(to == address(0)){
          revert ZeroAddressNotAllowed();
      }
      if(amount > maxTxAmount){
          revert AmountExceedLimit();
      }
      token.transferWithLock(to, amount);
  }
  
  /// @dev owner can add or remove beneficiary which can call transferWithLock function
  /// @param beneficiary: new beneficiary address
  /// @param value: boolean value, true or false
  function addOrRemoveBenificiary (address beneficiary, bool value) external onlyOwner {
      if(beneficiary == address(0)){
          revert ZeroAddressNotAllowed();
      }
      if(isBeneficiary[beneficiary] == value){
          revert ChangeBoolValue();
      }
      isBeneficiary[beneficiary] = value;
  }
  
  /// @dev claim other erc20 tokens if accidently sent to this contract
  /// @param otherToken: token address to rescue
  function claimOtherERC20Tokens(address otherToken) external onlyOwner {
     if(otherToken == address(0)){
         revert ZeroAddressNotAllowed();
     }
     if(otherToken == address(token)){
         revert NativeTokenClaimNotAllowed();
     }
     IERC20 OtherERC20Token = IERC20(otherToken);
     uint256 balance = OtherERC20Token.balanceOf(address(this));
     OtherERC20Token.safeTransfer(owner(), balance);
  }

}