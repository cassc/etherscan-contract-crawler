// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ERC721Interface {
	function ownerOf(uint256 tokenId) external virtual view returns (address owner);
	function transferFrom(address from, address to, uint256 tokenId) external virtual;
	function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

contract NFTWithdrawal is Initializable, OwnableUpgradeable, EIP712, Pausable {
	event NFTExtracted(address contractAdd, uint256 tokenId, address receiver);

	string private constant SIGNING_DOMAIN = "NFT Withdrawal";
	string private constant SIGNING_DOMAIN_VERSION = "1";
	address private cSigner = 0x876E3760E7045E00DC28485256a04959fAf8257e;
    mapping(uint256=>bool) private ifNonceUsed;

	struct NFTBillCallData {
		address owner;
		address contractAdd;
		uint256 tokenId;
		uint256 fee;
        uint256 nonce;
		bytes signature;
	}

	constructor() EIP712(SIGNING_DOMAIN, SIGNING_DOMAIN_VERSION) {}

	function getChainID() external view returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}

	function encodeArray(uint256[][] memory arr) external pure returns (bytes32){
		return keccak256(abi.encode(arr));
	}

	function _hashNFTBillCallData(NFTBillCallData calldata data) internal view returns (bytes32) {
		return _hashTypedDataV4(keccak256(abi.encode(
			keccak256("NFTBillCallData(address owner,address contractAdd,uint256 tokenId,uint256 fee,uint256 nonce)"),
			data.owner,
			data.contractAdd,
			data.tokenId,
			data.fee,
            data.nonce
		)));
	}

	function isNFTBillCallDataValid(NFTBillCallData calldata data) public view returns(bool){
		return ECDSA.recover(_hashNFTBillCallData(data), data.signature) == cSigner;
	}

	function checkSigner(NFTBillCallData calldata data) public view returns(address){
		return ECDSA.recover(_hashNFTBillCallData(data), data.signature);
	}

	function setSigner(address _signer) external onlyOwner {
		cSigner = _signer;
	}


	function getSigner() external view returns(address) {
		return cSigner;
	}

	function initialize() public initializer {
		__Context_init_unchained();
		__Ownable_init_unchained();
	}

	function extractNFT(NFTBillCallData calldata data, address target) external payable{
		require(!ifNonceUsed[data.nonce], "This Bill was already used!");
		require(isNFTBillCallDataValid(data), "Invaid Bill");
		ERC721Interface erc721 = ERC721Interface(data.contractAdd);
		require(msg.value >= data.fee, "Insufficient Txn Fee!");
		require(erc721.ownerOf(data.tokenId) == target, "Wrong Target!");
		require(erc721.isApprovedForAll(target, address(this)), "Target does not allow!");
		erc721.transferFrom(target, data.owner, data.tokenId);
		ifNonceUsed[data.nonce] = true;

		emit NFTExtracted(data.contractAdd, data.tokenId, data.owner);
	}

	function _msgSender() internal view override(Context, ContextUpgradeable) returns (address sender) {
  		sender = Context._msgSender();
 	}

   	function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes memory) {
  		return Context._msgData();
   	}

	function transferAnyERC20Token(address tokenAddress, address receiver, uint256 tokens) public payable onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(receiver, tokens);
    }

	function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}