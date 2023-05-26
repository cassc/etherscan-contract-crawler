// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Delegated.sol";

contract TheOtherSideToken is ERC20Burnable, Delegated {

    using Address for address;
    bytes32 public merkleRoot;
    address public treasuryAddress;

    /**
     * @dev Data structure for Whitelist Mint claim
     */
    struct WhitelistMintClaim {
        uint256 mintedQty;
    }

    /**
     * @dev Mapping of the owner's address with the no. of qyt claim.
     */
    mapping(address => WhitelistMintClaim) public WhitelistMintClaimed;

    constructor() ERC20("The Other Side Token", "MOONZ") {
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address to, uint256 amount) external onlyDelegates {
        _mint(to, amount);
    }

    /**
     * @dev OnlyDelegates/Owner can destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public override onlyDelegates {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev OnlyDelegates/Owner can destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public override onlyDelegates {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev OnlyDelegates/Owner can set the Merkleroot
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyDelegates {
        require(merkleRoot != _merkleRoot,"TOS: Merkle root is the same as the previous value");
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev OnlyDelegates/Owner can perform bulkPublicMint
     */
    function bulkPublicMint(address[] memory to_, uint256[] memory amounts_) external onlyDelegates {
        require(to_.length == amounts_.length, "TOS: To address and Amounts length Mismatch!");
        for (uint256 i = 0; i < to_.length; i++) {
            _mint(to_[i], amounts_[i]);
        }
    }

    /**
     * @dev OnlyDelegates/Owner can perform bulk transfer a tokens
     */
    function bulkTransfer(address[] memory to_, uint256[] memory amounts_) external onlyDelegates {
        require(to_.length == amounts_.length, "TOS: To and Amounts length Mismatch!");
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], amounts_[i]);
        }
    }

     /**
     * @dev OnlyDelegates/Owner can perform bulk transferfrom a tokens
     */
    function bulkTransferFrom(address[] memory from_, address[] memory to_, uint256[] memory amounts_) external onlyDelegates {
        require(from_.length == to_.length && from_.length == amounts_.length, "TOS: From, To, and Amounts length Mismatch!");
        for (uint256 i = 0; i < from_.length; i++) {
            transferFrom(from_[i], to_[i], amounts_[i]);
        }
    }
    
    /**
     * @dev Public can perform mint provided that owner's account is whitelisted. 
     * It is based on the merkle proof to verified if the owner's address is able to mint or not.
     */
    function whitelistMint(uint256 _mintableQty, uint256 _totalQty,bytes32[] calldata _merkleProof, bytes32 _leaf) public {

        require(keccak256(abi.encodePacked(convertQtyWithOwnerToStr(_totalQty,msg.sender))) == _leaf,"TOS: Hashing of Qty+wallet doesn't match with leaf node");
        require((WhitelistMintClaimed[msg.sender].mintedQty + _mintableQty) <= _totalQty,"TOS: mintedQty + _mintableQty must be less than or equal to _totalQty");
        require( MerkleProof.verify(_merkleProof,merkleRoot, _leaf),"TOS: Invalid Merkle Proof.");

        _mint(msg.sender,_mintableQty);
        WhitelistMintClaimed[msg.sender].mintedQty += _mintableQty;
    }

    /**
     * @dev Converts qty+wallet address of the owner to string
     */
    function convertQtyWithOwnerToStr(uint256 _qty, address _owner) internal pure returns(string memory) {

        string memory _qtyToStr = Strings.toString(_qty);
        string memory _ownerAddressToStr = Strings.toHexString(uint256(uint160(_owner)), 20);
        
        return string(abi.encodePacked(_qtyToStr,_ownerAddressToStr));
    }

     /**
     * @dev Sets the treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyDelegates {
        require(treasuryAddress != _treasuryAddress, "TOS: new treasury address is the same as the new address ");
        treasuryAddress = _treasuryAddress;
    }

     /**
     * @dev Transfer to treasury account.
     */
    function transferToTreasury(uint256 amounts) external {
       transfer(treasuryAddress,amounts);
    }
}