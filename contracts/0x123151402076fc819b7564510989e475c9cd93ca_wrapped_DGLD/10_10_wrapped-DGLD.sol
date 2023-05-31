pragma solidity ^0.5.16;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";

/// @title wrapped-DGLD
/// @author The CommerceBlock Developers
/// @notice This is the contract for the wrapped-DGLD ERC20 token.
contract wrapped_DGLD is ERC20Detailed, ERC20Mintable {

  //wrapped-DGLD pegout address
  address constant private _pegoutAddress = 0x00000000000000000000000000000000009ddEAd;

  using SafeMath for uint256;

  mapping (address => uint256) private _peginID;

  //name, symbol, decimals
  constructor() public ERC20Detailed("wrapped-DGLD", "wDGLD", 8)
                       ERC20Mintable(){
  }

  /**	
     * @notice A function to get the pegout address.
     * 
     * ***WARNING*** any tokens transferred to this address will be destroyed. Please follow the instructions below.
     *
     * This address can be used to transfer wrapped-DGLD tokens from this ethereum contract to the
     * DGLD federated sidechain. Failure to follow the procedure outlined below will result
     * in permanent loss of tokens. Your tokens may then be reminted and returned to you
     * (minus a fee) but this is not guaranteed.
     *
     * Whitelisting must be completed and approved on a DGLD federated sidechain wallet prior to conducting
     * a pegout. Please see the instructions to whitelist your wallet here: https://dgld.ch/wallet-id.
     *
     * PEGOUT INSTRUCTIONS
     * To transfer wrapped-DGLD tokens to an address on the DGLD side chain:
     * 1) Obtain a whitelisted DGLD sidechain address (`receiver` address).
     * 2) Import the `receiver` address private key into an Ethereum wallet in order to generate the corresponding Ethereum account (`sender` account).
     * 3) Transfer the required number of wrapped-DGLD tokens to the sender account.
     * 4) Obtain the pegout address using the pegoutAddress() function.
     * 5) Transfer the required number of tokens from the sender account to the pegout address.
     *
     *
     * ALTERNATIVE PEGOUT INSTRUCTIONS
     * To transfer tokens to an address on the DGLD side chain:
     * 1) Import the private key(s) from an Ethereum account (`sender` account) into a DGLD sidechain wallet. To do this in the DGLD Ocean Wallet version 1.0.2: 
     * In the menu click File -> New. Choose a name for the new wallet and click next. Select 'Import Ocean addresses or private keys' from the list of options
     * and click Next. Enter the list of private keys and click Next. Then ensure that the wallet is whitelisted (instructions to whitelist your wallet here:
     * https://dgld.ch/wallet-id).
     * 2) Transfer the required number of wrapped-DGLD tokens to the sender account.
     * 3) Obtain the pegout address using the pegoutAddress() function.
     * 4) Transfer the required number of tokens from the sender account to the pegout address.
     *
     *
     * 24/7 operational uptime for the service is not guaranteed by the service provider.  
    */
  function pegoutAddress() public pure returns (address) {
      return _pegoutAddress;
  }


     /**
     * @dev Calls super._transfer(sender, recipient, amount). If the recipient is _pegoutAddress, the tokens are then burned.
     *
     * See {super._transfer} and {super._burn} 
     */
 function _transfer(address sender, address recipient, uint256 amount) internal {
      super._transfer(sender, recipient, amount);
      if (recipient == _pegoutAddress) {
        _burn(_pegoutAddress, amount);
      }
  }


  /**	
     * @dev Mints tokens and transfers them, emitting a Pegin event containg the pegin ID.
     * The pegin ID must begin at 1 and be incremented by 1 for successive pegins to the same address.
     *
     * See {super.mint} and {Pegin}
     *
     */
  function pegin(address to, uint256 amount, uint256 id) public onlyMinter returns (bool){
  	require(id == _peginID[to].add(1), "wrong pegin id");
	_peginID[to] = id;
	super.mint(to, amount);
        emit Pegin(id);
	return true;
  }

 /**
   * @dev The event emitted when the 'pegin' function is called.  
   * Includes a indexed "id" variable.
   *
   * see {pegin}.
   *
   */
   event Pegin(uint256 indexed id);
}

