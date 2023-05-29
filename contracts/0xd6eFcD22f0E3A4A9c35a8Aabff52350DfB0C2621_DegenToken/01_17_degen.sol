// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

interface IERC721 {
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract DegenToken is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit, ReentrancyGuard {
	using SafeERC20 for IERC20;

	struct TokenInfo {
		uint256 lastClaimTs; // last claim timestamp
		uint256 claimedTokensNum; // how many tokens were already claimed for this NFT
	}

	struct Claimable {
		address addr;
		bool active;
		uint256 maxDegensPerToken;
		uint256 claimNumPerInterval;
		uint256 claimTimeInterval;
		mapping(uint256 => TokenInfo) tokens;
	}

	struct UserClaim {
		address addr;
		uint256[] tokens;
	}

	struct UserClaimLog {
		address addr;
		uint256 token;
	}

	event TokensClaimed(address indexed token, uint256[] tokens);
	event NewTokenAdded(
		address indexed token,
		uint256 maxDegensPerToken,
		uint256 claimNumPerInterval,
		uint256 claimTimeInterval,
		bool initInPast
	);
	event ClaimActiveChanged(address indexed token, bool active);
	event ClaimAttributesChanged(address indexed token, ClaimContractAttribute attribute, uint256 value);

	Claimable[] claims;

	constructor() ERC20("DegenLabsToken", "DEGLAB") ERC20Permit("DegenLabsToken") {
		_mint(address(this), 1000000 * (10**decimals()));
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function addNewContractForClaims(
		address _addr,
		bool _active,
		uint256 _maxDegensPerToken,
		uint256 _claimNumPerInterval,
		uint256 _claimTimeInterval,
		bool _initInPast
	) public onlyOwner {
		for (uint256 i = 0; i < claims.length; i++) {
			require(claims[i].addr != _addr, "already added");
		}

		Claimable storage newC = claims.push();
		newC.addr = _addr;
		newC.active = _active;
		newC.maxDegensPerToken = _maxDegensPerToken;
		newC.claimNumPerInterval = _claimNumPerInterval;
		newC.claimTimeInterval = _claimTimeInterval;

		emit NewTokenAdded(
			_addr,
			newC.maxDegensPerToken,
			newC.claimNumPerInterval,
			newC.claimTimeInterval,
			_initInPast
		);
	}

	function setClaimContractActive(address _addr, bool _active) public onlyOwner {
		for (uint256 i = 0; i < claims.length; i++) {
			if (claims[i].addr == _addr) {
				claims[i].active = _active;
				emit ClaimActiveChanged(_addr, _active);
				return;
			}
		}
		revert("contract not found");
	}

	enum ClaimContractAttribute {
		MAX_DEGENS_PER_TOKEN, // 0
		CLAIM_NUM_PER_INTERVAL, // 1
		CLAIM_TIME_INTERVAL // 2
	}

	function setClaimContractAttributes(
		address _addr,
		ClaimContractAttribute _attributeType,
		uint256 _value
	) public onlyOwner {
		for (uint256 i = 0; i < claims.length; i++) {
			if (claims[i].addr == _addr) {
				if (_attributeType == ClaimContractAttribute.MAX_DEGENS_PER_TOKEN) {
					claims[i].maxDegensPerToken = _value;
				} else if (_attributeType == ClaimContractAttribute.CLAIM_NUM_PER_INTERVAL) {
					claims[i].claimNumPerInterval = _value;
				} else if (_attributeType == ClaimContractAttribute.CLAIM_TIME_INTERVAL) {
					claims[i].claimTimeInterval = _value;
				} else {
					revert("invalid attribute");
				}
				emit ClaimAttributesChanged(_addr, _attributeType, _value);
				return;
			}
		}
		revert("contract not found");
	}

	function isTokenFullyClaimed(address _addr, uint256 _tokenID) external view returns (bool) {
		for (uint256 i = 0; i < claims.length; i++) {
			if (claims[i].addr == _addr) {
				return claims[i].tokens[_tokenID].claimedTokensNum >= claims[i].maxDegensPerToken;
			}
		}

		revert("contract not found");
	}

	function getClaimedDegensForToken(address _addr, uint256 _tokenID) external view returns (uint256) {
		for (uint256 i = 0; i < claims.length; i++) {
			if (claims[i].addr == _addr) {
				return claims[i].tokens[_tokenID].claimedTokensNum;
			}
		}

		revert("contract not found");
	}

	function getLastTimeTokenWasClaimed(address _addr, uint256 _tokenID) external view returns (uint256) {
		for (uint256 i = 0; i < claims.length; i++) {
			if (claims[i].addr == _addr) {
				return claims[i].tokens[_tokenID].lastClaimTs;
			}
		}

		revert("contract not found");
	}

	function getClaimContractAttributes(address _addr)
		external
		view
		returns (
			bool active,
			uint256 maxDegensPerToken,
			uint256 claimNumPerInterval,
			uint256 claimTimeInterval
		)
	{
		for (uint256 i = 0; i < claims.length; i++) {
			if (claims[i].addr == _addr) {
				return (
					claims[i].active,
					claims[i].maxDegensPerToken,
					claims[i].claimNumPerInterval,
					claims[i].claimTimeInterval
				);
			}
		}

		revert("contract not found");
	}

	function claim(UserClaim[] calldata _toClaim) external nonReentrant whenNotPaused {
		require(_toClaim.length > 0, "empty params");

		for (uint256 i = 0; i < _toClaim.length; i++) {
			require(_toClaim[i].tokens.length > 0, "empty tokens");
		}

		uint256 claimableTokensNum = 0;
		uint256 possibleTokensToClaim = 0;
		uint256 totalRewardsNum = 0;

		for (uint256 i = 0; i < _toClaim.length; i++) {
			possibleTokensToClaim += _toClaim[i].tokens.length;
		}

		UserClaimLog[] memory claimedTokens = new UserClaimLog[](possibleTokensToClaim);

		for (uint256 i = 0; i < _toClaim.length; i++) {
			for (uint256 j = 0; j < claims.length; j++) {
				if (!claims[j].active) {
					continue;
				}
				if (claims[j].addr == _toClaim[i].addr) {
					for (uint256 k = 0; k < _toClaim[i].tokens.length; k++) {
						uint256 tokenID = _toClaim[i].tokens[k];
						if (
							(claims[j].tokens[tokenID].claimedTokensNum == 0 &&
								claims[j].tokens[tokenID].lastClaimTs == 0) ||
							(claims[j].tokens[tokenID].claimedTokensNum < claims[j].maxDegensPerToken &&
								block.timestamp >= claims[j].tokens[tokenID].lastClaimTs + claims[j].claimTimeInterval)
						) {
							// not set, check if owner of token
							if (IERC721(claims[j].addr).ownerOf(tokenID) == msg.sender) {
								claims[j].tokens[tokenID].claimedTokensNum += claims[j].claimNumPerInterval;
								claims[j].tokens[tokenID].lastClaimTs = block.timestamp;

								claimedTokens[totalRewardsNum] = UserClaimLog(claims[j].addr, tokenID);

								claimableTokensNum += claims[j].claimNumPerInterval;
								totalRewardsNum++;
							}
						}
					}
				}
			}
		}

		require(claimableTokensNum > 0, "nothing to claim");

		IERC20(this).transfer(msg.sender, claimableTokensNum);

		// emit logs for every collection
		for (uint256 i = 0; i < claims.length; i++) {
			// count tokens for current collection, needed to get size for allocating dynamic array used in log
			uint256 tokensNum = 0;
			for (uint256 j = 0; j < claimedTokens.length; j++) {
				if (claimedTokens[j].addr == claims[i].addr) {
					tokensNum++;
				}
			}

			// skip if no tokens for that collection
			if (tokensNum == 0) {
				continue;
			}

			uint256[] memory claimedForAddr = new uint256[](tokensNum);

			uint256 currentlogLength = 0;
			for (uint256 j = 0; j < claimedTokens.length; j++) {
				if (claimedTokens[j].addr == claims[i].addr) {
					claimedForAddr[currentlogLength] = claimedTokens[j].token;
					currentlogLength++;
				}
			}
			if (claimedForAddr.length > 0) {
				emit TokensClaimed(claims[i].addr, claimedForAddr);
			}
		}
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override whenNotPaused {
		super._beforeTokenTransfer(from, to, amount);
	}

	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
	}
}