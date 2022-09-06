// SPDX-License-Identifier: none

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { INFTToken } from "./NFTToken.sol";

contract NFTBridgeETH is IERC721ReceiverUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public chainId;
    address public signer;

    uint128 public migrationId;
    mapping (uint128 => Migration) public migrations;
    mapping (address => uint128[]) public accountMigrationList; 
            
    function initialize(address signer_, uint256 chainId_) public initializer {
        __Ownable_init();
        setSigner(signer_); 
        chainId = chainId_;      
    }

    function setSigner(address signer_) public onlyOwner {
		signer = signer_;
		emit SetSigner(signer_);
	}

    function accountMigrations(address account) public view returns (uint256) {
		return accountMigrationList[account].length;        
	}

    function migrationById(uint128 migrationId_) public view returns (Migration memory) {
		return migrations[migrationId_];        
	}
    
    function accountData(address account) public view returns (
		uint256 _total,
		Migration[] memory _migrations        
	) {
		_total = accountMigrations(account);
        if (_total != 0) {
            _migrations = new Migration[](_total);
            for (uint256 index = 0; index < _total; index++) {
                _migrations[index] = migrations[accountMigrationList[account][index]];
            }
        }                       
	}
    
    struct Migration { 
        uint128 migrationId;       
        uint128 chainId;
        address token;
        uint256[] tokenIds;
        address owner;
    }

    function start(Migration calldata migration, bytes calldata signature) public {
        require(_isSignatureValid(signature, keccak256(abi.encode(migration))), "Signature error");
        require(migration.migrationId == 0, "Wrong migration id");
        
        for (uint256 i = 0; i < migration.tokenIds.length; i++) {
            IERC721Upgradeable(migration.token).safeTransferFrom(msg.sender, address(this), migration.tokenIds[i]);
        }   

        migrationId ++;
                
        migrations[migrationId] = migration;     
        migrations[migrationId].migrationId = migrationId; 
        migrations[migrationId].owner = msg.sender; 
        accountMigrationList[msg.sender].push(migrationId);

        emit MigrateStart(migration);
    }
        
    function _isSignatureValid(
		bytes memory signature,
		bytes32 dataHash
	) internal view returns (bool) {
		return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(dataHash), signature) == signer;
	}
        
    function onERC721Received(
		address operator_,
		address from_,
		uint256 tokenId_,
		bytes memory data_
	) public override returns (bytes4) {
		emit ERC721Received(operator_, from_, tokenId_, data_);
		return IERC721ReceiverUpgradeable.onERC721Received.selector;        
	}

    /* ======= AUXILIARY ======= */
	
	function recover(
		address token_,
		uint256 amount_,
		address recipient_,
        bool nft
	) external onlyOwner {
        if (nft) {
            IERC721Upgradeable(token_).safeTransferFrom(address(this), recipient_, amount_);
        } else if (token_ != address(0)) {
			IERC20Upgradeable(token_).safeTransfer(recipient_, amount_);
		} else {
			(bool success, ) = recipient_.call{ value: amount_ }("");
			require(success, "Can't send ETH");
		}
		emit Recover(token_, amount_, recipient_, nft);		
	}
    event Recover(address token, uint256 amount, address recipient, bool nft);

    event SetSigner(address signer);    
    event MigrateStart(Migration migration);
    event ERC721Received(address operator, address from, uint256 tokenId, bytes data);  
    	  
}