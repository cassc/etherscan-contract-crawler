// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../contracts/Delegated.sol";


/*
░█████╗░██████╗░████████╗  ░██████╗░██╗░░░░░░█████╗░██████╗░░█████╗░██╗░░░░░
██╔══██╗██╔══██╗╚══██╔══╝  ██╔════╝░██║░░░░░██╔══██╗██╔══██╗██╔══██╗██║░░░░░
███████║██████╔╝░░░██║░░░  ██║░░██╗░██║░░░░░██║░░██║██████╦╝███████║██║░░░░░
██╔══██║██╔══██╗░░░██║░░░  ██║░░╚██╗██║░░░░░██║░░██║██╔══██╗██╔══██║██║░░░░░
██║░░██║██║░░██║░░░██║░░░  ╚██████╔╝███████╗╚█████╔╝██████╦╝██║░░██║███████╗
╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ░╚═════╝░╚══════╝░╚════╝░╚═════╝░╚═╝░░╚═╝╚══════╝

░█████╗░░█████╗░███╗░░██╗██╗░░░██╗░█████╗░░██████╗
██╔══██╗██╔══██╗████╗░██║██║░░░██║██╔══██╗██╔════╝
██║░░╚═╝███████║██╔██╗██║╚██╗░██╔╝███████║╚█████╗░
██║░░██╗██╔══██║██║╚████║░╚████╔╝░██╔══██║░╚═══██╗
╚█████╔╝██║░░██║██║░╚███║░░╚██╔╝░░██║░░██║██████╔╝
░╚════╝░╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚═════╝░
*/

// @title Art Tokyo Global
// @author 0xjikangu
// @notice This is the ERC20 AGC Token Smart Contract

contract AGC is ERC20Burnable, Delegated, Pausable   {

    using Address for address;
    bytes32 public merkleRoot;
    address  public treasuryAddress = 0xA107E9f9D382244F3a669340cf53014ABbc58629;
    uint256 public maxSupply = ( 999999999 * 10**uint(decimals()) );

    /**
     * @dev Claim Token Structure
     */
    struct ClaimToken {
        uint256 claimQty;
    }

    /**
     * @dev Mapping of the owner's address with claimQty
     */
    mapping(address => ClaimToken) public ClaimedToken;

    constructor() ERC20("AGC", "AGC") {
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the totalSupply but not exceeding maxSupply
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function claim(address toAddress, uint256 amount) external onlyDelegates {
        require( totalSupply() + amount * 10**uint(decimals()) <= maxSupply, "ATG: TotalSupply is capped");
        _mint(toAddress, amount * 10**uint(decimals()) );
    }

    /**
     * @dev OnlyDelegates/Owner can burn `amount` tokens.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public override onlyDelegates {
        _burn(_msgSender(), amount * 10**uint(decimals()));
    }

    /**
     * @dev OnlyDelegates/Owner can burn `amount` tokens from `account`, deducting from the caller's
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
        _burn(account, amount * 10**uint(decimals()));
    }

    /**
     * @dev Only Delegates/Owner can set the Merkleroot
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyDelegates {
        require(merkleRoot != _merkleRoot,"ATG: Merkle root is the same as the previous merkleRoot");
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Only Delegates/Owner can perform massPublicClaim
     */
    function massTokenDrop(address[] memory _toAddress, uint256[] memory _amounts) external onlyDelegates {
        require(_toAddress.length == _amounts.length, "ATG: toAddress and Amounts length does not tally!");
        for (uint256 i = 0; i < _toAddress.length; i++) {
            require( totalSupply() + _amounts[i] * 10**uint(decimals()) <= maxSupply, "ATG: TotalSupply is capped");
            _mint(_toAddress[i], _amounts[i] * 10**uint(decimals()));
        }
    }

     /**
     * @dev Only Delegates/Owner can perform massTransfer
     */
    function massTransfer(address[] memory _fromAddress, address[] memory _toAddress, uint256[] memory _amounts) external onlyDelegates {
        require(_fromAddress.length == _toAddress.length && _fromAddress.length == _amounts.length, "ATG: fromAddress && toAddress && Amounts length does not tally!");
        for (uint256 i = 0; i < _fromAddress.length; i++) {
            transferFrom(_fromAddress[i], _toAddress[i], _amounts[i]);
        }
    }
    
    /**
     * @dev Public can perform claimToken if they are one of the collection's holder
     * Snapshot is done daily to determine if they are in the claim list
     * Amount is determine by the number of ATG's Collections NFT holding and assigned accordingly
     */
    function claimToken(uint256 _claimAmt, uint256 _totalClaimAmt, bytes32[] calldata _merkleProof, bytes32 _leaf) public whenNotPaused {

        require( totalSupply() + _claimAmt * 10**uint(decimals()) <= maxSupply, "ATG: TotalSupply is capped");
        require(keccak256(abi.encodePacked(convertQtyWithOwnerToStr(_totalClaimAmt,msg.sender))) == _leaf,"ATG: Invalid of totalClaimAmt to merkleLeafNode!");
        require((ClaimedToken[msg.sender].claimQty + _claimAmt) <= _totalClaimAmt,"ATG: claimQty && claimAmt must not greater than totalClaimAmt!");
        require( MerkleProof.verify(_merkleProof,merkleRoot, _leaf),"ATG: Invalid MerkleProof!");

        _mint(msg.sender,_claimAmt * 10**uint(decimals()) );
        ClaimedToken[msg.sender].claimQty += _claimAmt;
    }

    /**
     * @dev Conversion of amt && owner address to string
     */
    function convertQtyWithOwnerToStr(uint256 _amounts, address _ownerAddress) internal pure returns(string memory) {

        string memory _amtToStr = Strings.toString(_amounts);
        string memory _ownerAddressToStr = Strings.toHexString(uint256(uint160(_ownerAddress)), 20);
        
        return string(abi.encodePacked(_amtToStr,_ownerAddressToStr));
    }

     /**
     * @dev Only Owner can set the Treasury Wallet Account
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(treasuryAddress != _treasuryAddress, "ATG: Treasury Address must not be the same as previous!");
        treasuryAddress = _treasuryAddress;
    }

     /**
     * @dev Anyone can transfer to Treasury Wallet Account.
     */
    function transferToTreasury(uint256 amounts) external {
       transfer(treasuryAddress,amounts * 10**uint(decimals()) );
    }


     /**
     * @dev Only Delegates/Owner can perform pause
     */
    function pause() public onlyDelegates {
        _pause();
    }

     /**
     * @dev Only Delegates/Owner can perform unpause
     */
    function unpause() public onlyDelegates {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = ( _maxSupply * 10**uint(decimals()) );
    }
}