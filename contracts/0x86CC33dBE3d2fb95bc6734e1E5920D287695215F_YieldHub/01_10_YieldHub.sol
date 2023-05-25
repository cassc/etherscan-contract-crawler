pragma solidity ^0.6.12;

import "IERC20.sol";
import "ERC20.sol";
import "IERC721.sol";
import "IERC1155.sol";
import "SafeMath.sol";
import "Ownable.sol";

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

interface IMintable20 is IERC20 {
	function mint(address _user, uint256 _amount) external;
	function burnFrom(address _from, uint256 _amount) external;
}

interface IMintable1155 is IERC1155 {
	function mint(address _to, uint256 _tokenId, uint256 _amount) external;
}

interface IKongz is IERC721 {
	function balanceOG(address _user) external view returns(uint256);
}

contract YieldHub is Ownable {
	using SafeMath for uint256;

	struct YieldToken {
		uint8 stake;
		uint8 issuanceType; // mint/transfer
		uint32 tokenType; // erc20/erc1155
		uint256 tokenId;
		uint256 start;
		uint256 end;
		uint256 rate;
	}

	struct UserData {
		uint256 rewards;
		uint256 lastUpdate;
	}

	IKongz public constant kongzContract = IKongz(0x57a204AA1042f6E66DD7730813f4024114d74f37);
	address public newNana;


	mapping(address => YieldToken) public yieldTokens;
	mapping(uint256 => address) public indexToAddress;
	uint256 public yieldTokenCount;

	// user => token => user data
	mapping(address => mapping(address => UserData)) public userData;

	///////////
	// admin //
	///////////
	function updateBanana(address _nana) external onlyOwner {
		newNana = _nana;
	}

	function addNewToken(
		address _token,
		uint256 _start,
		uint256 _end,
		uint256 _tokenType, // erc20/erc1155
		uint256 _tokenId,
		uint256 _rate,
		uint256 _issuanceType, // mint/transfer
		uint256 _stake
	) external onlyOwner {
		require(_start > 0);
		require(_token != address(0));
		require(_tokenType == 20 || _tokenType == 1155);
		require(_issuanceType <= 1);
		require(_stake <= 2);
		require(_start > yieldTokens[_token].end);

		indexToAddress[yieldTokenCount++] = _token;
		yieldTokens[_token] = YieldToken({
			stake: uint8(_stake),
			tokenType: uint32(_tokenType),
			issuanceType: uint8(_issuanceType),
			tokenId: _tokenId,
			start: _start,
			end: _end,
			rate: _rate
		});
	}

	function removeToken(address _token) external onlyOwner {
		require(block.timestamp >= yieldTokens[_token].end, "Can't remove token");
		uint256 count = yieldTokenCount;

		for (uint256 i = 0; i < count; i++) {
			if (_token == indexToAddress[i]) {
				if (i + 1 != count) {
					indexToAddress[i] = indexToAddress[count - 1];
				}
				yieldTokenCount--;
				delete indexToAddress[count - 1];
			}
		}
	}

	///////////////////////
	// User interactions //
	///////////////////////
	function getTokenReward(address _token) public {
		uint256 balOf = kongzContract.balanceOf(msg.sender);
		uint256 balOg = kongzContract.balanceOG(msg.sender);

		updateUserToken(msg.sender, _token, balOf, balOg);
		_getReward(_token, msg.sender);
	}

	function getTotalClaimable(address _user, address _token) external view returns(uint256) {
		UserData memory data = userData[_user][_token];
		YieldToken memory yieldToken = yieldTokens[_token];
		uint256 time = min(block.timestamp, yieldToken.end);
		uint256 bal;
		uint256 delta = time.sub(max(data.lastUpdate, yieldToken.start));

		if (yieldToken.stake == uint8(0))
			bal = kongzContract.balanceOG(_user);
		else if (yieldToken.stake == uint8(1))
			bal = kongzContract.balanceOf(_user);
		else if (yieldToken.stake == uint8(2))
			bal = kongzContract.balanceOf(_user) - kongzContract.balanceOG(_user);
		uint256 pending = bal.mul(yieldToken.rate.mul(delta)).div(86400);
		return data.rewards + pending;
	}

	function getReward(address _user) public {
		require(msg.sender == address(kongzContract), "!kongz contract");
		uint256 balOf = kongzContract.balanceOf(msg.sender);
		uint256 balOg = kongzContract.balanceOG(msg.sender);

		updateUserToken(_user, newNana, balOf, balOg);
		_getReward(newNana, _user);
	}

	// called on transfers
	function updateReward(address _from, address _to, uint256 _tokenId) external {
		require(msg.sender == address(kongzContract), "!kongz caller");
		uint256 tokensFarmed = yieldTokenCount;

		updateUser(_from, tokensFarmed);
		if (_to != address(0))
			updateUser(_to, tokensFarmed);
	}

	////////////
	// helper //
	////////////
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? a : b;
	}

	function updateUser(address _user, uint256 _tokensFarmed) internal {
		uint256 balOf = kongzContract.balanceOf(_user);
		uint256 balOg = kongzContract.balanceOG(_user);

		for (uint256 i = 0; i < _tokensFarmed; i++)
			updateUserToken(_user, indexToAddress[i], balOf, balOg);
	}

	function updateUserToken(address _user, address _token, uint256 _balOf, uint256 _balOg) internal {
		YieldToken memory yieldToken = yieldTokens[_token];
		UserData storage _userData = userData[_user][_token];

		if (block.timestamp > yieldToken.start) {
			uint256 trueLastUpdate = _userData.lastUpdate;
			uint256 userLastUpdate = trueLastUpdate;
			uint256 time = min(yieldToken.end, block.timestamp);
			uint256 delta;
			userLastUpdate = max(userLastUpdate, yieldToken.start);
			delta = time.sub(userLastUpdate);
			if (userLastUpdate > 0 && delta > 0) {
				if (yieldToken.stake == uint8(0))
					_userData.rewards += _balOg.mul(yieldToken.rate).mul(delta).div(86400);
				else if (yieldToken.stake == uint8(1))
					_userData.rewards += _balOf.mul(yieldToken.rate).mul(delta).div(86400);
				else if (yieldToken.stake == uint8(2))
					_userData.rewards += _balOf.sub(_balOg).mul(yieldToken.rate).mul(delta).div(86400);
			}
			if (trueLastUpdate < time)
				_userData.lastUpdate = time;
		}
	}

	function _getReward(address _token, address _user) internal {
		YieldToken memory yieldToken = yieldTokens[_token];
		require(yieldToken.start > 0);
		UserData storage _userData = userData[_user][_token];
		uint256 amount = _userData.rewards;

		if (amount == 0)
			return;
		uint256 tokenType = uint256(yieldToken.tokenType);
		_userData.rewards = 0;
		if (tokenType == 20) {
			if (yieldToken.issuanceType == 0) // mint
				IMintable20(_token).mint(_user, amount);
			else
				IERC20(_token).transfer(_user, amount);
		}
		else if (tokenType == 1155) {
			if (yieldToken.issuanceType == 0) // mint
				IMintable1155(_token).mint(_user, yieldToken.tokenId, amount);
			else
				IERC1155(_token).safeTransferFrom(address(this), _user, yieldToken.tokenId, amount, "");
		}
	}

	// needs to burn new banana
	function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(kongzContract), "!kongz contract");
		IMintable20(newNana).burnFrom(_from, _amount);
	}
}