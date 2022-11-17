// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { EnumerableSet } from 'openzeppelin-contracts/utils/structs/EnumerableSet.sol';
// import { console } from 'forge-std/console.sol';

import { VBep20Interface, VTokenInterface } from '../interfaces/Venus/VTokenInterfaces.sol';
import { EIP20NonStandardInterface } from '../interfaces/Venus/EIP20NonStandardInterface.sol';
import { ComptrollerInterface } from "../interfaces/Venus/ComptrollerInterface.sol";

// import { IHedgerWhitelist } from './interfaces/IHedgerWhitelist.sol';

contract HedgerWhitelist {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private whitelist;

  EnumerableSet.AddressSet private supportedVTokens;
  
  EnumerableSet.AddressSet private delegates;

	address private router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PancakeRouter

	ComptrollerInterface constant private comptroller = ComptrollerInterface(0xfD36E2c2a6789Db23113685031d7F16329158384); // Unitroller proxy

  address private _owner;
  
  bool public isFrozen = false;

  modifier notFrozen() {
    require(!isFrozen, 'Whitelist frozen');
    _;
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  modifier onlyDelegates() {
    require(owner() == msg.sender || delegates.contains(msg.sender), 'Delegateable: caller is not the owner or delegates');
    _;
  }

  constructor() {
		// whitelist.add(router); // PancakeRouter
    _owner = msg.sender;
	}

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    _owner = newOwner;
  }

  function addDelegate(address newDelegate) public virtual onlyOwner {
    delegates.add(newDelegate);
  }

  function removeDelegate(address newDelegate) public virtual onlyOwner {
    delegates.remove(newDelegate);
  }

  function approved(address addr) public view notFrozen returns (bool) {
    require(whitelist.contains(addr), 'Address not whitelisted');
    return true;
  }

  function add(address addr) public onlyDelegates {
    whitelist.add(addr);
  }

  function addBulk(address[] memory addrs) public onlyDelegates {
    for (uint i = 0; i < addrs.length;) {
      whitelist.add(addrs[i]);
      unchecked {
        i++;
      }
    }
  }

  function remove(address addr) public onlyDelegates {
    whitelist.remove(addr);
  }

  function removeBulk(address[] memory addrs) public onlyDelegates {
    for (uint i = 0; i < addrs.length;) {
      whitelist.remove(addrs[i]);
      unchecked {
        i++;
      }
    }
  }

  function clear() public onlyDelegates {
    address[] memory addrs = dump();
    for (uint256 i = 0; i < addrs.length; i++) {
      whitelist.remove(addrs[i]);
    }
  }

  function freeze() public onlyDelegates {
    isFrozen = true;
  }

  function unfreeze() public onlyDelegates {
    isFrozen = false;
  }

  /// @dev Show all whitelisted addresses
  function dump() public view onlyDelegates returns (address[] memory) {
    return whitelist.values();
  }

	function supportVToken(address vToken) public onlyDelegates {
		supportedVTokens.add(vToken);
		whitelist.add(address(vToken));
		if (vToken != address(0xA07c5b74C9B40447a954e1466938b865b6BBea36)) { // non vBNB
			// underlying token of vToken
			// EIP20NonStandardInterface vuToken = EIP20NonStandardInterface(address(VBep20Interface(vToken).underlying()));
			// console.log(address(vuToken));
			// vuToken.approve(address(vToken), type(uint).max); // For minting vToken
			// vuToken.approve(address(router), type(uint).max); // For swapping vToken
			// console.log(vuToken.allowance(address(this), address(vToken)));
			// console.log(vuToken.allowance(address(this), address(router)));

			whitelist.add(address(VBep20Interface(vToken).underlying()));
		} else {
			// EIP20NonStandardInterface BNB = EIP20NonStandardInterface(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
			// BNB.approve(address(vToken), type(uint).max);
			// BNB.approve(address(router), type(uint).max);
			whitelist.add(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
		}

		address[] memory vTokens = new address[](1);
		vTokens[0] = vToken;
		// comptroller.enterMarkets(vTokens);
    (bool success, bytes memory data) = address(comptroller).delegatecall(
      abi.encodeWithSignature("enterMarkets(address[])", vTokens)
    );
    require(success, 'Delegate call failed');
	}

	function supportVTokens(address[] memory vTokens) public onlyDelegates {
		for (uint i = 0; i < vTokens.length; i++) {
			supportedVTokens.add(vTokens[i]);
			whitelist.add(address(vTokens[i]));
			if (vTokens[i] != address(0xA07c5b74C9B40447a954e1466938b865b6BBea36)) { // non vBNB
				whitelist.add(address(VBep20Interface(vTokens[i]).underlying()));
			} else {
				whitelist.add(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
			}
		}

    // TODO: delegate call comptroller to enter market as msg.sender = address(hedger)
		// comptroller.enterMarkets(vTokens);
    // (bool success, bytes memory data) = address(comptroller).delegatecall(
    //   abi.encodeWithSignature("enterMarkets(address[])", vTokens)
    // );
    // require(success, 'Delegate call failed');
	}

	function unsupportVToken(address vToken) public onlyDelegates {
		supportedVTokens.remove(address(vToken));
		// underlying token of vToken
		EIP20NonStandardInterface vuToken = EIP20NonStandardInterface(address(VBep20Interface(vToken).underlying()));
		// For minting vToken
		vuToken.approve(address(vToken), 0);
		// For swapping vToken
		vuToken.approve(address(router), 0);
	}

	function getSupportedVTokens() public view returns (address[] memory) {
		return supportedVTokens.values();
	}

	function isSupportedVToken(address token) public view returns (bool) {
		return supportedVTokens.contains(token);
	}

	/// @dev Converts the input VToken amount to USDC value 
	function getVTokenValue(VTokenInterface token, uint256 amount) public view returns (uint256) {
		return token.exchangeRateStored() * amount / 1e18;
	}
}