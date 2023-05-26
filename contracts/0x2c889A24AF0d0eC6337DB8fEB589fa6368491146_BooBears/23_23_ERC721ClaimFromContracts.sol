// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {AccessControl} from "AccessControl.sol";
import {Address} from "Address.sol";
import {ERC721} from "ERC721.sol";
import {ERC721Enumerable} from "ERC721Enumerable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";

/* Internal Imports */
import {ERC721Essentials} from "ERC721Essentials.sol";
import {ClaimFromContractErrorCodes} from "ErrorCodes.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

/**
 * @dev Lightweight package to allow users to mint token(s) for free if they own tokens in
 * another set of contracts.
 */

abstract contract ERC721ClaimFromContracts is ERC721Essentials, ClaimFromContractErrorCodes {
    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    /* Internal */
    address[] internal _claimContractAddrs;
    bool internal _claimingEnabled;
    mapping(address => bool) internal _userHasClaimed;
    uint16 internal _numPurchased = 0;
    uint16 internal _numClaimed = 0;

    // TODO: Future we can calculate maxForClaim by reading other contracts totalSupply()
    uint16 internal _maxForPurchase;
    uint16 internal _maxForClaim;

    /* Private */
    string private constant kBalanceOfAbi = "balanceOf(address)"; /* solhint-disable-line */

    constructor(
        address[] memory contractAddrs_,
        uint16 maxForPurchase_,
        uint16 maxForClaim_
    ) {
        setContractAddrsForClaim(contractAddrs_);
        setMaxForPurchase(maxForPurchase_);
        setMaxForClaim(maxForClaim_);
        setClaimingEnabled(false);
    }

    //=================================================================================================================
    /// Claiming Functionality
    //=================================================================================================================

    /**
     * @dev Public function that claims new tokens based on owning tokens from other contracts.
     */
    function claim() public nonReentrant whenClaimingEnabled {
        _claim();
    }

    /**
     * @dev An internal function to claim a certain number of new ERC721 tokens based on ownership from a set of previous
     * contracts. This function calls the balanceof(address) function in each contract to determine the number of tokens a user holds
     * and then mints them the corresponding number of tokens in this contract. Contains NO safety checks, as it should be
     * implied that if all eligible users run the claim function token supply numbers for this contract stay valid.
     * You can add safety checks to an external / public wrapping of this function if you wish to do so.
     */
    function _claim() internal {
        require(!_userHasClaimed[_msgSender()], kErrAlreadyClaimed);
        bytes memory payload = abi.encodeWithSignature(kBalanceOfAbi, address(_msgSender()));
        uint16 length = uint16(_claimContractAddrs.length);
        uint16 sum = 0;
        _userHasClaimed[_msgSender()] = true;
        for (uint16 i = 0; i < length; i += 1) {
            bytes memory result = Address.functionStaticCall(_claimContractAddrs[i], payload); /* solhint-disable-line */
            sum += uint16(abi.decode(result, (uint256)));
        }
        _numClaimed += sum;
        require(_numClaimed <= _maxForClaim, kErrOutOfClaimable);
        _safeMintTokens(_msgSender(), uint16(sum));
    }

    /**
     * @dev Public function that mints a specified number of ERC721 tokens.
     * @param numMint uint16: The number of tokens that are going to be minted.
     */
    function mint(uint16 numMint) public payable virtual override(ERC721Essentials) limitAndTrackPurchases(numMint) {
        return super.mint(numMint); // ERC721Essentials.sol
    }

    //=================================================================================================================
    /// Mutators
    //=================================================================================================================

    /**
     * @dev A public function to set what contracts will be queired during the execution of _claim.
     * @param addrs address[] memory: The list of addresses to be queried
     */
    function setContractAddrsForClaim(address[] memory addrs) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _claimContractAddrs = addrs;
    }

    /**
     * @dev A public function to set the number of tokens that can be minted via a payment.
     * @param maxForPurchase_ uint16: The max number that can be payable minted.
     */
    function setMaxForPurchase(uint16 maxForPurchase_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxForPurchase = maxForPurchase_;
    }

    /**
     * @dev A public function to set the number of tokens that can be minted via a claim.
     * @param maxForClaim_ uint16: The max number that can be claim minted.
     */
    function setMaxForClaim(uint16 maxForClaim_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxForClaim = maxForClaim_;
    }
    
    /**
     * @dev A public function to enable/disable claiming.
     */
    function setClaimingEnabled(bool claiming_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _claimingEnabled = claiming_;
    }

    //=================================================================================================================
    /// Accessors
    //=================================================================================================================

    function contractAddrsForClaim() public view returns (address[] memory) {
        return _claimContractAddrs;
    }

    //=================================================================================================================
    /// Useful Checks & Modifiers
    //=================================================================================================================

    /**
     * @dev Modifier to limit the number of mints for purchase.
     */
    modifier limitAndTrackPurchases(uint16 numMint) {
        _numPurchased += numMint;
        require(_numPurchased <= _maxForPurchase, kErrOutOfPurchasable);
        _;
    }
    
    /**
     * @dev Modifier to ensure claiming is enabled
     */
    modifier whenClaimingEnabled() {
        require(_claimingEnabled, kErrClaimingNotEnabled);
        _;
    }
}