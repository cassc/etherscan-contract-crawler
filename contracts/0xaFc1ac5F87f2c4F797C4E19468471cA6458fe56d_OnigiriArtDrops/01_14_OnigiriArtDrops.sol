//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OnigiriArtDrops is ERC1155Burnable, Ownable {
    // @dev admin of the contract (different from the owner = artist)
    address private _admin;

    // NFTs that can't be minted anymore
    uint256[] public lockedNFTs;

    // Mapping of Signatures
	mapping(bytes => uint256[]) public signatureUsed;

    // struct Allowlists {
    //     uint hpcclaimcards;
    //     mapping(bytes => bool) public signatureUsed;
    // }
    
    constructor() ERC1155("placeholder") {
        transferAdmin(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner or the admin.
     */
    modifier OnlyOwnerandAdmin() {
        _checkAdmins();
        _;
    }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if the sender is not the owner or the admin.
     */
    function _checkAdmins() internal view virtual {
        require(owner() == _msgSender() || admin() == _msgSender(), "Caller is not the owner or admin");
    }

    /**
     * @dev Transfers administration of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferAdmin(address newAdmin) public virtual onlyOwner {
        _admin = newAdmin;
    }

    /**
     * @dev Allowlist addresses
     */
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ECDSA.recover(messageDigest, signature);
    }

    function checkSignatureForDrop(bytes memory signature, uint256 dropId) internal view returns (bool){
    	bool hasNotBeenUsed = true;

    	if (signatureUsed[signature].length > 0){
	    	for (uint i = 0; i < signatureUsed[signature].length; i++) {
	    		if (signatureUsed[signature][i] == dropId){
					hasNotBeenUsed = false;
					break;
	    		}
	    	}
	    }
    	return hasNotBeenUsed;
    }

    /**
     * @dev Claim NFTs function for allowlists
     */
    function claimNFTs(address wAddress, uint256[] memory ids, uint256[] memory numbers, uint256 dropId, bytes32 hash, bytes memory signature) public {
        require(recoverSigner(hash, signature) == owner(), "Address is not allowlisted");
        require(checkSignatureForDrop(signature, dropId), "Signature has already been used.");

        _mintBatch(wAddress, ids, numbers, "");

        signatureUsed[signature].push(dropId);
    }

    /**
     * @dev Owner & admin can lock supply for an NFT
     */
    function lockSupply(uint256 id) public OnlyOwnerandAdmin {
        lockedNFTs.push(id);
    }

    /**
     * @dev View if the supply of an NFT is locked
     */
    function isNFTLocked(uint256 id) public view returns (bool){
        bool islocked = false;

        for (uint i = 0; i < lockedNFTs.length; i++) {
            if (lockedNFTs[i] == id) {
                islocked = true;
                break;
            }
        }
        return islocked;
    }

    /**
     * @dev View if the supply of one of the NFTs is locked
     */
    function isOneNFTLocked(uint256[] memory ids) public view returns (bool){
        bool islocked = false;

        for (uint i = 0; i < ids.length; i++) {
            if (isNFTLocked(ids[i])){
            	islocked = true;
                break;
            }
        }
        return islocked;
    }

    /**
     * @dev Owner & admin can airdrop NFTs to selected addresses.
     */
    function airdropNfts(address[] calldata wAddresses, uint256[][] memory ids, uint256[][] memory number) public OnlyOwnerandAdmin {
        for (uint i = 0; i < wAddresses.length; i++) {
            _mintBatch(wAddresses[i], ids[i], number[i], "");
        }
    }

    /**
     * @dev Owner & admin can mint
     */
    function mintBatch(address wAddress, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal OnlyOwnerandAdmin {
        require(!isOneNFTLocked(ids), "No new NFT can be minted for one the ids.");
        _mintBatch(wAddress, ids, amounts, data);
    }

    /**
     * @dev Owner & admin can change Metadata URL
     */
    function replaceURI(string memory newuri) public OnlyOwnerandAdmin {
        _setURI(newuri);
    }
}