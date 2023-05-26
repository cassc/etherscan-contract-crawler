pragma solidity ^0.6.12;

import "ERC20.sol";
import "IERC721.sol";
import "SafeMath.sol";
import "Ownable.sol";

interface IHub is IERC20 {
	function getTotalClaimable(address _user, address _token) external view returns(uint256);
}

interface IKongz is IERC721 {
	function getReward() external;
}

contract WrappedKongzV2 is ERC20("Wrapped Genesis Kongz", "WGK"), Ownable {
	using SafeMath for uint256;

	IKongz constant public KONGZ = IKongz(0x57a204AA1042f6E66DD7730813f4024114d74f37);
	IHub  public HUB = IHub(0x86CC33dBE3d2fb95bc6734e1E5920D287695215F);
	IERC20  public BANANA = IERC20(0x94e496474F1725f1c1824cB5BDb92d7691A4F03a);
	uint256 constant public END = 1931622407;

	address public mainLpAddress;

	uint256[] public genIds;

	uint256 public globalScore;
	uint256 public globalLastUpdate;
	uint256 public globalClaimed;

	mapping(address => uint256) public holderScores;
	mapping(address => uint256) public holderLastUpdate;
	mapping(address => uint256) public holderClaimed;
	mapping(address => uint256) public holderLastScoreClaim;

	event KongzWrapped(uint256 kongId);
	event KongzUnwrapped(uint256 kongId);
	event NanasClaimed(address indexed holder, uint256 amount);

	constructor() public {
		globalLastUpdate = block.timestamp;
	}

	modifier syncScore(address _from, address _to) {
		uint256 time = min(block.timestamp, END);
		uint256 lastUpdateFrom = holderLastUpdate[_from];
		if (lastUpdateFrom > 0) {
			uint256 interval = time.sub(lastUpdateFrom);
			holderScores[_from] = holderScores[_from].add(balanceOf(_from).mul(interval));
		}
		if (lastUpdateFrom != END)
			holderLastUpdate[_from] = time;
		if (_to != address(0)) {
			uint256 lastUpdateTo = holderLastUpdate[_to];
			if (lastUpdateTo > 0) {
				uint256 interval = time.sub(lastUpdateTo);
				holderScores[_to] = holderScores[_to].add(balanceOf(_to).mul(interval));
			}
			if (lastUpdateTo != END)
				holderLastUpdate[_to] = time;
		}
		_;
	}

	modifier syncGlobalScore() {
		uint256 time = min(block.timestamp, END);
		uint256 lastUpdate = globalLastUpdate;
		if (lastUpdate > 0) {
			uint256 interval = time.sub(lastUpdate);
			globalScore = globalScore.add(totalSupply().mul(interval));
		}
		if (lastUpdate != END)
			globalLastUpdate = time;
		_;
	}

	function setLpAddress(address _lpAddress) external onlyOwner {
		require(_isContract(_lpAddress));
		mainLpAddress = _lpAddress;
	}

	function syncRewards() external onlyOwner {
		uint256 before = BANANA.balanceOf(address(this));

		KONGZ.getReward();
		uint256 post = BANANA.balanceOf(address(this));
		globalClaimed = globalClaimed.add(post.sub(before));
	}

	function claimLpNanas() external syncScore(mainLpAddress, address(0)) syncGlobalScore() {
		require(mainLpAddress != address(0), "WrappedKongz: LP address not set");
		_claimNanas(mainLpAddress, owner());
	}

	function getClaimableNanas(address _holder) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);

		uint256 gInterval = time.sub(globalLastUpdate);
		uint256 uInterval = time.sub(holderLastUpdate[_holder]);

		uint256 _globalScore = globalScore.add(totalSupply().mul(gInterval));
		uint256 userScore = holderScores[_holder].add(balanceOf(_holder).mul(uInterval));

		uint256 totalFarmed = globalClaimed + HUB.getTotalClaimable(address(this), address(BANANA));
		uint256 userShare = totalFarmed.mul(userScore).div(_globalScore);
		uint256 claimable = userShare.sub(holderClaimed[_holder]);
		return claimable;
	}


	function wrap(uint256[] calldata _kongzIdsToWrap) external syncScore(msg.sender, address(0)) syncGlobalScore() {
		for (uint256 i = 0; i < _kongzIdsToWrap.length; i++) {
			require(_kongzIdsToWrap[i] <= 1000, "WrappedKongz: Kongz is not genesis");
			genIds.push(_kongzIdsToWrap[i]);
			KONGZ.safeTransferFrom(msg.sender, address(this), _kongzIdsToWrap[i]);
			emit KongzWrapped(_kongzIdsToWrap[i]);
		}
		_mint(msg.sender, _kongzIdsToWrap.length * 100 * (1e18));
	}

	function unwrap(uint256 _amount) external {
		unwrapFor(_amount, msg.sender);
	}

	function unwrapFor(uint256 _amount, address _recipient) public syncScore(msg.sender, address(0)) syncGlobalScore() {
		require(_recipient != address(0), "WrappedKongz: Cannot send to void address.");

		_burn(msg.sender, _amount * 100 * (1e18));
		uint256 _seed = 0;
		for (uint256 i = 0; i < _amount; i++) {
			_seed = _getSeed(_seed, msg.sender);
			uint256 _index = _seed % genIds.length;
			uint256 _tokenId = genIds[_index];

			genIds[_index] = genIds[genIds.length - 1];
			genIds.pop();
			KONGZ.safeTransferFrom(address(this), _recipient, _tokenId);
			emit KongzUnwrapped(_tokenId);
		}
	}

	function transfer(address _to, uint256 _amount) public override syncScore(msg.sender, _to) returns (bool) {
		return ERC20.transfer(_to, _amount);
	}

	function transferFrom(address _from, address _to, uint256 _amount) public override syncScore(_from, _to) returns (bool) {
		return ERC20.transferFrom(_from, _to, _amount);
	}

	function claimNanas() external syncScore(msg.sender, address(0)) syncGlobalScore() {
		_claimNanas(msg.sender, msg.sender);
	}

	function _claimNanas(address _holder, address _to) internal {
		uint256 holderScore = holderScores[_holder];
		if (holderScore == holderLastScoreClaim[_holder])
			return;
		uint256 totalFarmed = globalClaimed + HUB.getTotalClaimable(address(this), address(BANANA));
		// share = (total * holder_score / total_score)
		uint256 userShare = totalFarmed.mul(holderScore).div(globalScore);
		uint256 toSend = userShare.sub(holderClaimed[_holder]);
		holderClaimed[_holder] = userShare;
		holderLastScoreClaim[_holder] = holderScore;
		if (BANANA.balanceOf(address(this)) < toSend) {
			uint256 before = BANANA.balanceOf(address(this));
			KONGZ.getReward();
			uint256 post = BANANA.balanceOf(address(this));
			globalClaimed = globalClaimed.add(post.sub(before));
		}
		BANANA.transfer(_to, toSend);
		emit NanasClaimed(_holder, toSend);
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function _getSeed(uint256 _seed, address _sender) internal view returns (uint256) {
		if (_seed == 0)
			return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _sender)));
		else
			return uint256(keccak256(abi.encodePacked(_seed)));
	}

	function _isContract(address _addr) internal view returns (bool) {
		uint32 _size;
		assembly {
			_size:= extcodesize(_addr)
		}
		return (_size > 0);
	}

	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
		return WrappedKongzV2.onERC721Received.selector;
	}

}