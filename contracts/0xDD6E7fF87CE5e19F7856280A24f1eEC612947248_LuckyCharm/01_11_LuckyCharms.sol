pragma solidity ^0.6.12;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "ERC1155.sol";
import "SafeMath.sol";
import "Ownable.sol";

contract LuckyCharm is ERC1155, Ownable {
	using SafeMath for uint256;

	uint256 constant SHARDS = 0;

	address public constant HUB = 0x86CC33dBE3d2fb95bc6734e1E5920D287695215F;
	mapping(address => bool) public approvedReceiver;
	mapping(uint256 => uint256) private _supplyOf;
	mapping(uint256 => string) public uris;

	constructor (string memory uri) public ERC1155(uri){
	}

	function changeReceiver(address _receiver, bool _val) external onlyOwner {
		approvedReceiver[_receiver] = _val;
	}

	function uri(uint256 _id) external view override returns (string memory) {
        return uris[_id];
    }

	function setUri(uint256 _id, string memory _uri) external onlyOwner {
		uris[_id] = _uri;
	}

	function mint(address _to, uint256 _tokenId, uint256 _amount) external {
		require(msg.sender == HUB, "!hub");
		_mint(_to, _tokenId, _amount, "");
		_supplyOf[_tokenId] = _supplyOf[_tokenId].add(_amount);
	}

	function totalSupply(uint256 _id) external view returns(uint256) {
		return _supplyOf[_id];
	}

	function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
		require(approvedReceiver[to] || approvedReceiver[from], "!receiver");
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
		require(approvedReceiver[to] || approvedReceiver[from], "!receiver");
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
	}
}