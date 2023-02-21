/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed



/**

 * @dev Interface of the ERC20 standard as defined in the EIP.

 */

interface IERC20 {

    /**

     * @dev Emitted when `value` tokens are moved from one account (`from`) to

     * another (`to`).

     *

     * Note that `value` may be zero.

     */

    event Transfer(address indexed from, address indexed to, uint256 value);



    /**

     * @dev Emitted when the allowance of a `spender` for an `owner` is set by

     * a call to {approve}. `value` is the new allowance.

     */

    event Approval(address indexed owner, address indexed spender, uint256 value);



    /**

     * @dev Returns the amount of tokens in existence.

     */

    function totalSupply() external view returns (uint256);



    /**

     * @dev Returns the amount of tokens owned by `account`.

     */

    function balanceOf(address account) external view returns (uint256);



    /**

     * @dev Moves `amount` tokens from the caller's account to `to`.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

    function transfer(address to, uint256 amount) external returns (bool);



    /**

     * @dev Returns the remaining number of tokens that `spender` will be

     * allowed to spend on behalf of `owner` through {transferFrom}. This is

     * zero by default.

     *

     * This value changes when {approve} or {transferFrom} are called.

     */

    function allowance(address owner, address spender) external view returns (uint256);



    /**

     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * IMPORTANT: Beware that changing an allowance with this method brings the risk

     * that someone may use both the old and the new allowance by unfortunate

     * transaction ordering. One possible solution to mitigate this race

     * condition is to first reduce the spender's allowance to 0 and set the

     * desired value afterwards:

     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

     *

     * Emits an {Approval} event.

     */

    function approve(address spender, uint256 amount) external returns (bool);
    /**

     * @dev Moves `amount` tokens from `from` to `to` using the

     * allowance mechanism. `amount` is then deducted from the caller's

     * allowance.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

    function transferFrom(

        address from,

        address to,

        uint256 amount

    ) external returns (bool);

}

contract EDAOTre  {
    IERC20 public EDAO = IERC20(0x900882Be74c5Cb53eF02D603fCF006CDEf0495c9);
    address  Owner;

    modifier onlyOwner() {
        require(Owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
         Owner = newOwner;
    }

    constructor ()  {
        Owner = 0x3573A9A5ad01c14BD2b42c6aa7132455F43ec054; 
    }

     function _getRandomIndex() internal view returns (uint16) {
        // NOTICE: We do not to prevent miner from front-running the transaction and the contract.
        return
            uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.timestamp,
                            msg.sender,
                            blockhash(block.number - 1)
                        )
                    )
                ) % 9
            );
    }

    function EDAOreturn(address[] calldata PlayerAddrs,uint256[] calldata Quantity,uint256   SQuantity) public onlyOwner {
        for (uint256 i=0; i<PlayerAddrs.length; i++) {
            address add = PlayerAddrs[i];
            uint256 amount = 0;
            if (SQuantity  ==  1){
                amount = _getRandomIndex()+1;
            }else  if (SQuantity  >  1){
                amount =  SQuantity;
            }else{
                amount = Quantity[i];
            }
            EDAO.transferFrom(address(msg.sender), add, amount*10**18);
        }
    }    
}