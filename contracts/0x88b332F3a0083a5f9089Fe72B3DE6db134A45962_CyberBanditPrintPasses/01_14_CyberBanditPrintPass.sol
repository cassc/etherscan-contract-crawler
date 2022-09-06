// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC721 {
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

/*

                    $$$$$$$$$$$$$$$$
              $$$$$$$$$$$$$$$$$$$$$$$$$$$$
           $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
     $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$       $$$$$$$$$$$$$$$$$$$$       $$$$
$$$$$$$$$$$$$$$$$         $$$$$$$$$$$$$$$$$$         $$$
$$$$$$$$$$$$$$$$$$       $$$$$$$$$$$$$$$$$$$$       $$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$   $$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$     $$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$      $$$$$$$$$$$$$$$$$
  $  $$$$$$$$$$$$$$$$$$$$$$$$$$$   $    $$$$$$$$$$$$$$$$
 $$$$  $$$$$$$$$$$$$$$$$$$$$$$$$   $$    $$$$$$$$$$$$$
  $$$$$$$$      $$$$$$$$$$$$$$$    $$   $$$$$$$$$$
  $$$$$$$$        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$          $$$$$    $$$$$$$$$$$$$$$$$$$$
   $$$$$$$$         $$$$$    $$$$$$$ $$$$$ $$$$$$
   $$$$$$$$$$$                               $$$$
   $$$$$$$$$$$$$$$$$     $$$$$$$$$ $$$$ $$$$$$$$$
   $$$$$$$$$$$$$$$$$$$$  $$$$$$$$$$$$$$$$$$$$$$$$$
     $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
          $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
              $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                        $$$$$$$$$$$$$$$$$$$$$
                               $$$$$$$$$$$

 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $          Cyber Bandits ~ By Michael Reeder          $
 $  cyber-bandits.com • michael-reeder.com • 0x420.io  $
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

 */
/// @title Cyber Bandit Print Passes
/// @notice Cyber Bandit Print Passes ERC1155 NFT
/// @custom:website https://cyber-bandits.com
contract CyberBanditPrintPasses is ERC1155Supply, Ownable {
	error TokenNotFound();
	error ExceedsMaximum();
	error InvalidSignature();
	error NFTAlreadyPrinted();
	error NFTNotOwned();
	error NoPrintPasses();
	error OutOfBounds();

	using ECDSA for bytes32;

	string public name = "Cyber Bandit Print Passes";
	string public symbol = "CBPP";
	uint256 public constant MAX_TOKENS = 500;
	uint256 public totalMinted;
	address public mintSigner;
	mapping(address => mapping(uint256 => address)) private usedTokenOwners;
	mapping(address => uint256[]) private usedTokens;

	constructor(string memory uri_, address mintSigner_) ERC1155(uri_) {
		mintSigner = mintSigner_;
	}

	function uri(uint256 id)
		public
		view
		virtual
		override
		tokenExists(id)
		returns (string memory)
	{
		return super.uri(id);
	}

	function tokenURI(uint256 id) public view returns (string memory) {
		return uri(id);
	}

	modifier tokenExists(uint256 id) {
		if (id != 1) revert TokenNotFound();
		_;
	}

	/*
    PASS REDEMPTION
    PASS REDEMPTION
    PASS REDEMPTION
  */

	function redeem(
		address nft,
		uint256 tokenId,
		bytes memory signature
	) external payable {
		bytes32 hash = getHash(nft, tokenId, msg.value);
		address signer = recover(hash, signature);
		if (signer != mintSigner) revert InvalidSignature();
		if (usedTokenOwners[nft][tokenId] != address(0))
			revert NFTAlreadyPrinted();
		if (IERC721(nft).ownerOf(tokenId) != msg.sender) revert NFTNotOwned();
		if (balanceOf(msg.sender, 1) == 0) revert NoPrintPasses();
		usedTokenOwners[nft][tokenId] = msg.sender;
		usedTokens[nft].push(tokenId);
		_burn(msg.sender, 1, 1);
	}

	function redeemerOf(address nft, uint256 tokenId)
		external
		view
		returns (address)
	{
		return usedTokenOwners[nft][tokenId];
	}

	function redeemedTokenByIndex(address nft, uint256 index)
		external
		view
		returns (uint256)
	{
		if (index >= usedTokens[nft].length) revert OutOfBounds();
		return usedTokens[nft][index];
	}

	function totalRedeemed(address nft) external view returns (uint256) {
		return usedTokens[nft].length;
	}

	/*
    OWNER ONLY
    OWNER ONLY
    OWNER ONLY
  */

	function setSigner(address mintSigner_) external onlyOwner {
		mintSigner = mintSigner_;
	}

	function setURI(string memory newuri) external onlyOwner {
		_setURI(newuri);
	}

	function mintTo(address[] memory to, uint256[] memory qty)
		public
		onlyOwner
	{
		unchecked {
			for (uint256 i = 0; i < to.length; i++) {
				totalMinted += qty[i];
			}
		}
		if (totalMinted > MAX_TOKENS) revert ExceedsMaximum();
		for (uint256 i = 0; i < to.length; i++) {
			_mint(to[i], 1, qty[i], "");
		}
	}

	function withdraw() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function withdrawERC20(IERC20 token) public onlyOwner {
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

	/*
    INTERNAL
    INTERNAL
    INTERNAL
  */

	/// @notice Hashes the NFT symbol, sender address, redeeming nft address, tokenid, and payment
	/// @return hash the 256 bit keccak hash
	function getHash(
		address nft,
		uint256 tokenId,
		uint256 value
	) internal view returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(symbol, msg.sender, nft, tokenId, value)
			);
	}

	/// @notice Recovers the signer of a message
	/// @return address the signer address
	function recover(bytes32 hash, bytes memory signature)
		internal
		pure
		returns (address)
	{
		return hash.toEthSignedMessageHash().recover(signature);
	}
}