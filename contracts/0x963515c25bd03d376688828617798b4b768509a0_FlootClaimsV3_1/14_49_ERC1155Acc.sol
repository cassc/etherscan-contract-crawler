// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./FlootClaimV3P.sol";
import "hardhat/console.sol";

contract Accounting1155 is Ownable{
	event LuckyHolder1155(uint256 indexed luckyHolder, address indexed sender, uint, uint);
	event ChosenHolder1155(uint256 indexed chosenHolder, address indexed sender, uint, uint);

	FlootClaimsV3 _claimContract;
		struct TokenIDClaimInfo {
			uint index;
			uint balance;
		}

    struct NFTClaimInfo {
			uint index;
			uint[] tokenID;
      mapping(uint => TokenIDClaimInfo) claimTokenStruct;
    }

		struct ContractInfo {
			address[] contractIndex;
			mapping(address => NFTClaimInfo) contractInfos;
		}

    mapping (uint256 => ContractInfo) private _userInventory;
		
	constructor(){}

	modifier onlyClaimContract() { // Modifier
		require(
			msg.sender == address(_claimContract),
			"Only Claim contract can call this."
		);
		_;
	}

	function isContractForUser(address _contract, uint dojiID) public view returns(bool) {
		if (_userInventory[dojiID].contractIndex.length == 0) return false;
		return (_userInventory[dojiID].contractIndex[_userInventory[dojiID].contractInfos[_contract].index] == _contract);
	}

	function isTokenIDForContractForUser(address _contract, uint dojiID, uint tokenID) public view returns(bool) {
		if (_userInventory[dojiID].contractInfos[_contract].tokenID.length == 0) return false;
		return (
			_userInventory[dojiID].contractInfos[_contract]
				.tokenID[ _userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index ] == tokenID
		);
	}

	function insertContractForUser (
		address _contract, 
		uint dojiID,
    uint tokenID, 
    uint balance
	) 
    public
    returns(uint index)
  {
    require(!isContractForUser(_contract, dojiID), "Contract already exist"); 
		_userInventory[dojiID].contractIndex.push(_contract);
    _userInventory[dojiID].contractInfos[_contract].index = _userInventory[dojiID].contractIndex.length - 1;
		if (!isTokenIDForContractForUser(_contract, dojiID, tokenID)){
			_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].balance = balance;
			_userInventory[dojiID].contractInfos[_contract].tokenID.push(tokenID);
    	_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index = _userInventory[dojiID].contractInfos[_contract].tokenID.length - 1;
		}
    return _userInventory[dojiID].contractIndex.length-1;
  }

	function _addBalanceOfTokenId(address _contract, uint dojiID, uint tokenID, uint _amount) 
    private
    returns(bool success) 
  {
    require(isContractForUser(_contract, dojiID), "Contract doesn't exist");
		if (!isTokenIDForContractForUser(_contract, dojiID, tokenID)) {
			_userInventory[dojiID].contractInfos[_contract].tokenID.push(tokenID);
    	_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].index = _userInventory[dojiID].contractInfos[_contract].tokenID.length - 1;
		}
    if (_userInventory[dojiID].contractInfos[_contract].claimTokenStruct[tokenID].balance == 0) {
			_userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].balance = _amount;
		} else {
			_userInventory[dojiID]
				.contractInfos[_contract]
				.claimTokenStruct[tokenID].balance += _amount;
		}
    return true;
  }

	function removeBalanceOfTokenId(address _contract, uint dojiID, uint tokenID, uint _amount) 
    public onlyClaimContract
    returns(bool success) 
  {
    require(isContractForUser(_contract, dojiID), "Contract doesn't exist"); 
		require(isTokenIDForContractForUser(_contract, dojiID, tokenID));
		_userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].balance -= _amount;
    return true;
  }

	function getTokenBalanceByID(address _contract, uint dojiID, uint tokenID) public view returns(uint){
		return _userInventory[dojiID]
			.contractInfos[_contract]
			.claimTokenStruct[tokenID].balance;
	}

	function getTokenIDCount(address _contract, uint dojiID) public view returns(uint){
		return _userInventory[dojiID]
			.contractInfos[_contract].tokenID.length;
	}

	function getTokenIDByIndex(address _contract, uint dojiID, uint index) public view returns(uint){
		return _userInventory[dojiID]
			.contractInfos[_contract].tokenID[index];
	}

	function getContractAddressCount(uint dojiID) public view returns(uint){
		return _userInventory[dojiID].contractIndex.length;
	}

	function getContractAddressByIndex(uint dojiID, uint index) public view returns(address){
		return _userInventory[dojiID].contractIndex[index];
	}

	function random1155(address _contract, uint tokenID, uint _amount) external onlyClaimContract {
	  require(_amount > 0);
	  uint256 luckyFuck = _pickLuckyHolder();
		if (isContractForUser(_contract, luckyFuck)) {
			_addBalanceOfTokenId(_contract, luckyFuck, tokenID,  _amount);
		} else {
			insertContractForUser (_contract, luckyFuck, tokenID, _amount);
		}
	  emit LuckyHolder1155(luckyFuck, msg.sender, tokenID, _amount);
	}

	function send1155(address _contract, uint tokenID, uint _amount, uint256 chosenHolder) public {
		require(_amount > 0);
		require(chosenHolder > 0 && chosenHolder <= 11111, "That Doji ID is does not exist");
		if (isContractForUser(_contract, chosenHolder)) {
			_addBalanceOfTokenId(_contract, chosenHolder, tokenID, _amount);
		} else {
			insertContractForUser (_contract, chosenHolder, tokenID, _amount);
		}
		ERC1155(_contract).safeTransferFrom(msg.sender,  address(_claimContract), tokenID, _amount, 'true');
		emit ChosenHolder1155(chosenHolder, msg.sender, tokenID, _amount);
	}

	function _pickLuckyHolder() private view returns (uint) {
		uint256 rando = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _claimContract.currentBaseTokensHolder())));
		uint index = (rando % _claimContract.currentBaseTokensHolder());
		uint result = IERC721Enumerable(_claimContract.baseTokenAddress()).tokenByIndex(index);
		return result;
	}

	function setClaimProxy (address proxy) public onlyOwner {
	  _claimContract = FlootClaimsV3(payable(proxy));
	}
}