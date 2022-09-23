pragma solidity ^0.8.2;

import "IERC721.sol";
import "IERC1155.sol";
import "Ownable.sol";
import "VRFConsumberBase.sol";
import "IERC1155Burnable.sol";

contract TheKlaw is VRFConsumerBaseV2 {
	struct NFT {
		address contractAddress;
		uint256 tokenId;
	}

	address public immutable GOLDEN_TICKET;
	uint256 immutable TICKED_ID;
	address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;


	uint256 totalCount;
	mapping(uint256 => NFT) public nfts;
	mapping(uint256 => address) public requestIds;
	mapping(address => bool) authorised;

	event NFTClaimed(address indexed receiver, address indexed tokenAddress, uint256 tokenId);

	constructor(address _gold, uint256 _ticketId, address _vrfCoordinator, address _link) VRFConsumerBaseV2(_vrfCoordinator, _link) {
		GOLDEN_TICKET = _gold;
		TICKED_ID = _ticketId;
	}

	modifier isAuthorised() {
		require(authorised[msg.sender] || msg.sender == owner());
        _;
	}

	function setAuthorised(address _user, bool _val) external onlyOwner {
		authorised[_user] = _val;
	}

	function viewNFTs(uint256 _start, uint256 _maxLen) external view returns(NFT[] memory) {
		// return empty array if _start is out of bounds
		if (_start >= totalCount)
			return new NFT[](0);

		// limits _maxLen so we only return existing NFTs 
		if (_start + _maxLen > totalCount)
			_maxLen = totalCount - _start;

		NFT[] memory _nfts = new NFT[](_maxLen);
		for (uint256 i = 0; i < _maxLen; i++) {
			_nfts[i] = nfts[i + _start];
		}
		return _nfts;
	}

	function depositNFTs(address[] calldata _contracts, uint256[] calldata _tokenIds) external isAuthorised {
		require(_contracts.length == _tokenIds.length);
		
		uint256 len = _contracts.length;
		uint256 currentCount = totalCount;
		for (uint256 i = 0; i < len; i++) {
			nfts[currentCount++] = NFT(_contracts[i], _tokenIds[i]);
		}
		totalCount = currentCount;
	}

	function removeNFTs(uint256[] calldata _nfts) external isAuthorised {
		uint256 total = totalCount;
		for (uint256 i = 0 ; i < _nfts.length; i++) {
			address nftContract = nfts[_nfts[i]].contractAddress;
			uint256 tokenId = nfts[_nfts[i]].tokenId;

			nfts[_nfts[i]] = nfts[total - i - 1];
			delete nfts[total - i - 1];
			IERC721(nftContract).transferFrom(address(this), owner(), tokenId);
		}
		totalCount -= _nfts.length;
	}

	function claimNft() external {
		uint256 requestId = requestRandomWords();
		requestIds[requestId] = msg.sender;
		IERC1155Burnable(GOLDEN_TICKET).burnFor(msg.sender, TICKED_ID, 1);
	}

	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
		address receiver = requestIds[requestId];
		uint256 total = totalCount--;
		uint256 index = randomWords[0] % total;
		address nftContract = nfts[index].contractAddress;
		uint256 tokenId = nfts[index].tokenId;

		nfts[index] = nfts[total - 1];
		delete nfts[total - 1];
		IERC721(nftContract).transferFrom(address(this), receiver, tokenId);
		emit NFTClaimed(receiver, nftContract, tokenId);
	}

	function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
		return TheKlaw.onERC1155Received.selector;
	}
}