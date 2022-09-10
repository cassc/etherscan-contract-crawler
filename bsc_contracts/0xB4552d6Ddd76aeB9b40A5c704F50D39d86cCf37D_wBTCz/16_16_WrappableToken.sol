// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./SafeMath.sol";

import "./Pausable.sol";
import "./StandardToken.sol";
import "./Wrappable.sol";

contract WrappableToken is StandardToken, Wrappable, Pausable {
    using SafeMath for uint256;

    address private _mintingAddress;

    constructor() {}

    /*          MODIFIERS            */
    // modifiers use too much bytecode
    function onlyMintingAddress() internal view {
        require(_msgSender()==_mintingAddress,"BT01");
    }
/*          INTERFACES            */

    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply()-super.balanceOf(_mintingAddress);
        
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        if(account==_mintingAddress){
            return 0;
        }
        return super.balanceOf(account);
    }
    function balanceWrappable() public view virtual returns (uint256) {
        return super.balanceOf(_mintingAddress);
    }
    
    //MINTING_ADDRESS
	function _changeMintingAddress(address newMintingAddress) internal {
        require(super.balanceOf(newMintingAddress)==0, "BT07");
        if(super.balanceOf(_mintingAddress)>0){
            _tokenTransfer(_mintingAddress, newMintingAddress, super.balanceOf(_mintingAddress));
        }
		_mintingAddress=newMintingAddress;
	}
	function _getMintingAddress() internal view returns (address) {
		return _mintingAddress;
	}


   function _beforeTokenTransfer(
    ) internal override view {
        whenNotPaused();
    }
    
    // EXTERNAL transfer from user to mintingAddress storing btcz recipient address
    function unwrap(string calldata BTCZrecipient, uint256 amount) external override returns (bool) {
        _unwrap(msg.sender, BTCZrecipient, amount);
        return true;
    }

    // EXTERNAL transfer from mintingAddress to user storing btcz sender address
    function wrap(string calldata BTCZsender, address recipient, uint256 amount) external override returns (bool) {
        onlyMintingAddress();
        _wrap(BTCZsender, recipient, amount);
        return true;
    }





    // INTERNAL transfer from user to mintingAddress storing btcz recipient address
	function _unwrap(address sender, string memory BTCZrecipient, uint256 amount) private {
        require(sender != _mintingAddress, "BT05");
		
        _tokenTransfer(sender, _mintingAddress, amount);
		
		emit UNWRAP(sender, BTCZrecipient, amount);
	}
	
    // INTERNAL transfer from mintingAddress to user storing btcz sender address
	function _wrap(string memory BTCZsender, address recipient, uint256 amount) private {
        require(recipient != _mintingAddress, "BT06");
		
        _tokenTransfer(_mintingAddress, recipient, amount);
        
		emit WRAP(BTCZsender, recipient, amount);
	}

}
