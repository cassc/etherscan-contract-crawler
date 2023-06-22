// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;
pragma abicoder v2;


import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract AT_Stake is Ownable, Pausable, IERC721Receiver{

	event AT_Staked(address indexed owner, uint16 indexed token_id, uint256 indexed timestamp);
	event AT_UnStaked(address indexed owner, uint16 indexed token_id, uint256 indexed timestamp);

	uint256 public MIN_STAKE_TIME; //in seconds
	uint16 public total_staked;

	struct Stake {
		address owner;
		uint256 timestamp;
	}

	mapping (uint16 => Stake) public at_stakes;
	ERC721 public AT;

	constructor(address _address){
		AT = ERC721(_address);
		_pause();
		MIN_STAKE_TIME = 1209600; //2 weeks in seconds
		total_staked = 0;
	}

	function stake(uint16 _token_id) external whenNotPaused{
		require(AT.ownerOf(_token_id) == msg.sender, "Sender does not own the token");
		require(AT.isApprovedForAll(msg.sender, address(this)) == true, "Contract is not approved to transfer token");
		AT.transferFrom(msg.sender, address(this), _token_id);
		at_stakes[_token_id] = Stake(msg.sender, block.timestamp);
		total_staked += 1;
		emit AT_Staked(msg.sender, _token_id, block.timestamp);
	}

	function bulkStake(uint16[] memory _token_ids) external whenNotPaused{
		require(AT.isApprovedForAll(msg.sender, address(this)) == true, "Contract is not approved to transfer token");
		for(uint i = 0; i < _token_ids.length; i++){
			require(AT.ownerOf(_token_ids[i]) == msg.sender, "Sender does not own the token");
			AT.transferFrom(msg.sender, address(this), _token_ids[i]);
			at_stakes[_token_ids[i]] = Stake(msg.sender, block.timestamp);
			total_staked += 1;
			emit AT_Staked(msg.sender, _token_ids[i], block.timestamp);
		}
	}

	function unStake(uint16 _token_id) external whenNotPaused{
		require(at_stakes[_token_id].owner != address(0x0), "Token not staked");
		require(at_stakes[_token_id].owner == msg.sender, "Only owner can unstake");
		require((at_stakes[_token_id].timestamp + MIN_STAKE_TIME) < block.timestamp, "Token has not been staked for the minimum staking duration");
		AT.safeTransferFrom(address(this), msg.sender, _token_id);
		delete at_stakes[_token_id];
		total_staked -= 1;
		emit AT_UnStaked(msg.sender, _token_id, block.timestamp);
	}

    function unpause() external onlyOwner{
        _unpause();
    }

	function pause() external onlyOwner{
	    _pause();
	}

	function setMinStakeTime(uint256 _time) external onlyOwner{
		MIN_STAKE_TIME = _time;
	}

	function onERC721Received(address operator, address, uint, bytes calldata) external view override returns (bytes4) {
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        }
        else {
            return 0x00000000;
        }
    }
}