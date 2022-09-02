// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/* solhint-disable max-line-length */

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { ERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { ERC721RoyaltyUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IMembershipsFactory } from "./interfaces/IMembershipsFactory.sol";
import { IMemberships } from "./interfaces/IMemberships.sol";
import { IMembershipsMetadataRegistry } from "../memberships-metadata-registry/interfaces/IMembershipsMetadataRegistry.sol";

/* solhint-enable max-line-length */

/// @title Memberships
/// @author Coinvise
/// @notice Implementation contract for Coinvise Memberships
/// @dev Proxies for this contract will be deployed by registered MembershipsFactory contract.
///      Allows owner to pause/unpause purchases, mint, withdraw funds and change royalty info.
///      Allows anyone to purchase and renew memberships
contract Memberships is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721RoyaltyUpgradeable,
    IMemberships
{
    using SafeERC20 for IERC20;

    /// @notice Emitted when being initialized by other than registered factory contract
    error Unauthorized();

    /// @notice Emitted when incorrect msg.value is passed during purchase or renewal
    error IncorrectValue();

    /// @notice Emitted when there is insufficient balance during ether transfer
    error InsufficientBalance();

    /// @notice Emitted when ether transfer reverted
    error TransferFailed();

    /// @notice Emitted when allowed number of memberships have been completely purchased/minted
    error SaleComplete();

    /// @notice Emitted when accessing token that has not been minted yet
    error NonExistentToken();

    /// @notice Emitted when trying to renew lifetime membership
    error InvalidRenewal();

    /// @notice Emitted when no baseTokenURI set for proxy when changing
    error InvalidBaseTokenURI();

    /// @notice Emitted when `tokenId` is purchased by `recipient`
    /// @param tokenId tokenId of membership purchased
    /// @param recipient recipient of the membership
    /// @param expirationTimestamp expiration timestamp of membership token
    event MembershipPurchased(uint256 indexed tokenId, address indexed recipient, uint256 expirationTimestamp);

    /// @notice Emitted when `tokenId` is minted by `owner` for `recipient`
    /// @param tokenId tokenId of membership minted
    /// @param recipient recipient of the membership
    /// @param expirationTimestamp expiration timestamp of membership token
    event MembershipMinted(uint256 indexed tokenId, address indexed recipient, uint256 expirationTimestamp);

    /// @notice Emitted when a membership is renewed
    /// @param tokenId tokenId of membership renewed
    /// @param newExpirationTimestamp updated expiration timestamp of membership token
    event MembershipRenewed(uint256 indexed tokenId, uint256 newExpirationTimestamp);

    /// @notice Emitted when funds are withdrawn
    /// @param amount amount of funds withdrawn to `treasury`
    /// @param treasury treasury address to which funds are withdrawn
    /// @param fee amount of funds withdrawn to `feeTreasury` as fee
    /// @param feeTreasury treasury address to which fees are withdrawn
    event Withdrawal(uint256 amount, address indexed treasury, uint256 fee, address indexed feeTreasury);

    /// @notice Address used to represent ETH
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice MembershipsMetadataRegistry to use for `changeBaseTokenURI()`
    IMembershipsMetadataRegistry internal immutable membershipsMetadataRegistry;

    /// @notice Factory contract that deployed this proxy
    address public factory;

    /// @notice Treasury address to withdraw sales funds
    address payable public treasury;

    /// @notice Membership contractURI
    string internal _contractURI;

    /// @notice Membership baseURI
    string internal _baseTokenURI;

    /// @notice Membership price token address
    address public tokenAddress;

    /// @notice Membership price
    uint256 public price;

    /// @notice Membership validity duration in seconds for which a membership is valid after each purchase or renewal
    /// @dev Can be type(uint256).max for lifetime validity
    uint256 public validity;

    /// @notice Membership cap
    uint256 public cap;

    /// @notice Membership airdrop token address
    /// @dev Can be address(0) when there should be no airdrop
    address public airdropToken;

    /// @notice Membership airdrop amount
    /// @dev Should be in `airdropToken` decimals.
    ///      Automatically set to 0 if `airdropToken` is address(0)
    uint256 public airdropAmount;

    /// @notice Mapping to store expiration timestamps of each token: tokenId => expirationTimestamp
    mapping(uint256 => uint256) internal _expirationTimestamps;

    /// @notice Sets `membershipsMetadataRegistry`
    /// @param _membershipsMetadataRegistry MembershipsMetadataRegistry address to use
    constructor(IMembershipsMetadataRegistry _membershipsMetadataRegistry) initializer {
        membershipsMetadataRegistry = _membershipsMetadataRegistry;
    }

    /// @notice Initializes Membership contract
    /// @dev Reverts if called by other than registered factory contract.
    ///      Reverts if `cap` <= 0.
    ///      Initializes ERC721, ERC2981 with 10% default royalty to `_owner`.
    ///      Automatically sets `airdropToken`, `airdropAmount` to zero if they're both not set
    /// @param _owner Membership owner
    /// @param _treasury treasury address to withdraw sales funds
    /// @param _name name for Membership
    /// @param _symbol symbol for Membership
    /// @param contractURI_ contractURI for Membership
    /// @param baseURI_ baseURI for Membership
    /// @param _membership membership parameters: tokenAddress, price, validity, cap, airdropToken, airdropAmount
    function initialize(
        address _owner,
        address payable _treasury,
        string memory _name,
        string memory _symbol,
        string memory contractURI_,
        string memory baseURI_,
        IMemberships.Membership memory _membership
    ) external initializer {
        require(_membership.cap > 0, "Invalid Cap");

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __ERC721Royalty_init();

        transferOwnership(_owner);

        factory = msg.sender;

        treasury = _treasury;

        _baseTokenURI = baseURI_;
        _contractURI = contractURI_;
        tokenAddress = _membership.tokenAddress;
        price = _membership.price;
        validity = _membership.validity;
        cap = _membership.cap;

        if (_membership.airdropToken != address(0) && _membership.airdropAmount != 0) {
            airdropToken = _membership.airdropToken;
            airdropAmount = _membership.airdropAmount;
        } else {
            airdropToken = address(0);
            airdropAmount = 0;
        }

        _setDefaultRoyalty(_owner, 1000);
    }

    /// @notice Pause Membership purchases and renewals
    /// @dev Callable only by `owner`
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause Membership purchases and renewals
    /// @dev Callable only by `owner`
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Purchase a Membership by paying `price`
    /// @dev Transfers payment token.
    ///      Reverts if purchases are paused.
    ///      Reverts if `msg.value` is not set to `price`.
    ///      Emits `MembershipPurchased`
    /// @param recipient recipient of the membership
    /// @return tokenId of the purchased membership
    /// @return expirationTimestamp of the purchased membership
    function purchase(address recipient) external payable whenNotPaused returns (uint256, uint256) {
        (uint256 tokenId, uint256 expirationTimestamp) = _mintMembership(recipient);

        emit MembershipPurchased(tokenId, recipient, expirationTimestamp);

        if (tokenAddress != ETH_ADDRESS) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), price);
        } else if (msg.value != price) {
            revert IncorrectValue();
        }

        return (tokenId, expirationTimestamp);
    }

    /// @notice Mint a Membership without having to purchase it
    /// @dev Callable only by `owner`.
    ///      Emits `MembershipMinted`
    /// @param recipient recipient of the membership
    /// @return tokenId of the minted membership
    /// @return expirationTimestamp of the minted membership
    function mint(address recipient) external onlyOwner returns (uint256, uint256) {
        (uint256 tokenId, uint256 expirationTimestamp) = _mintMembership(recipient);

        emit MembershipMinted(tokenId, recipient, expirationTimestamp);

        return (tokenId, expirationTimestamp);
    }

    /// @notice Renew membership for a token
    /// @dev Transfers payment token.
    ///      Reverts if renewals are paused.
    ///      Reverts if `msg.value` is not set to `price`.
    ///      Emits `MembershipRenewed`
    /// @param tokenId tokenId of the token to renew
    /// @return updated expirationTimestamp of the token
    function renew(uint256 tokenId) external payable whenNotPaused returns (uint256) {
        uint256 newExpirationTimestamp = _extendExpiration(tokenId);

        emit MembershipRenewed(tokenId, newExpirationTimestamp);

        if (tokenAddress != ETH_ADDRESS) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), price);
        } else if (msg.value != price) {
            revert IncorrectValue();
        }

        return newExpirationTimestamp;
    }

    /// @notice Withdraw sales proceedings along with fees
    /// @dev Calculates and transfers fee from balance and `feeBPS` to `feeTreasury`.
    ///      Callable only by `owner`.
    ///      Emits `Withdrawal`
    function withdraw() external onlyOwner nonReentrant {
        address payable feeTreasury = IMembershipsFactory(factory).feeTreasury();

        uint256 balance;
        if (tokenAddress != ETH_ADDRESS) {
            balance = IERC20(tokenAddress).balanceOf(address(this));
        } else {
            balance = address(this).balance;
        }
        uint256 fee = (balance * IMembershipsFactory(factory).feeBPS()) / 10_000;
        if (fee > 0) {
            _transferFunds(tokenAddress, feeTreasury, fee);
            balance = balance - fee;
        }
        _transferFunds(tokenAddress, treasury, balance);

        emit Withdrawal(balance, treasury, fee, feeTreasury);
    }

    /// @notice Change baseTokenURI for Membership
    /// @dev Callable only by `owner`.
    ///      Reinitializes into version 2 to restrict as callable only once.
    //       Reverts if `baseTokenURI` not set for calling proxy on MembershipsMetadataRegistry
    function changeBaseTokenURI() external onlyOwner reinitializer(2) {
        string memory baseTokenURI = membershipsMetadataRegistry.baseTokenURI(address(this));

        if (bytes(baseTokenURI).length == 0) revert InvalidBaseTokenURI();

        _baseTokenURI = baseTokenURI;
    }

    /// @notice Get expiration timestamp for a given token
    /// @dev Reverts if checking non-existent token
    /// @param tokenId tokenId of the token
    /// @return Expiration timestamp for the given token
    function expirationTimestampOf(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NonExistentToken();

        return _expirationTimestamps[tokenId];
    }

    /// @notice Check if a token is valid
    /// @dev Checks whether a token's _expirationTimestamp > now.
    ///      Reverts if checking non-existent token
    /// @param tokenId tokenId to check validity
    /// @return boolean whether token is valid
    function isValid(uint256 tokenId) public view returns (bool) {
        return expirationTimestampOf(tokenId) > block.timestamp;
    }

    /// @notice Check if `owner` has at least one non-expired token
    /// @dev Checks validity of all tokens owned by `owner` using `tokenOfOwnerByIndex()` and `isValid()`
    /// @param _owner owner address to check for valid token
    /// @return boolean whether `owner` has at least one non-expired token
    function hasValidToken(address _owner) public view returns (bool) {
        uint256 length = balanceOf(_owner);

        if (length > 0) {
            for (uint256 i; i < length; i++) {
                if (isValid(tokenOfOwnerByIndex(_owner, i))) return true;
            }
        }

        return false;
    }

    /// @notice Set ERC2981 default royalty for all tokenIds
    /// @dev Exposes ERC2981Upgradeable._setDefaultRoyalty().
    ///      Callable only by `owner`
    /// @param _receiver royalty receiver address
    /// @param _feeNumerator royaltyFraction basis points
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @notice Get Memberships implementation version
    /// @return Memberships implementation version
    function version() public pure returns (uint16) {
        return 2;
    }

    /// @notice Get contract-level metadata URI
    /// @return URI to fetch contract-level metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Mints membership.
    ///      Sets expirationTimestamp for purchased token.
    ///      Sends airdrop tokens to `recipient` iff `airdropToken` and `airdropAmount` are set
    /// @param recipient recipient of the membership
    /// @return tokenId of the minted membership
    /// @return expirationTimestamp of the minted membership
    function _mintMembership(address recipient) internal returns (uint256, uint256) {
        uint256 tokenId = _mintMembershipToken(recipient);

        uint256 expirationTimestamp;
        if (validity == type(uint256).max) {
            // if Membership validity is lifetime, set expiration for token as type(uint256).max
            expirationTimestamp = type(uint256).max;
        } else {
            // else, set expiration as now + validity
            expirationTimestamp = block.timestamp + validity;
        }
        _expirationTimestamps[tokenId] = expirationTimestamp;

        if (airdropToken != address(0) && airdropAmount != 0)
            IERC20(airdropToken).safeTransfer(recipient, airdropAmount);

        return (tokenId, expirationTimestamp);
    }

    /// @dev Mints membership token by checking totalSupply against `cap`.
    ///      Reverts if all memberships have already been minted
    /// @param recipient recipient of the membership
    /// @return tokenId of the minted membership
    function _mintMembershipToken(address recipient) internal returns (uint256) {
        uint256 tokenId = totalSupply() + 1;

        if (tokenId > cap)
            // if tokenId surpasses cap, sale is complete
            revert SaleComplete();

        _mint(recipient, tokenId);

        return tokenId;
    }

    /// @dev Extends non-expired token by it's _expirationTimestamp + validity.
    ///      Extends expired token by now + validity.
    ///      Reverts if renewing non-existent token.
    ///      Reverts if renewing lifetime membership
    /// @param tokenId tokenId of the token to extend expiration
    /// @return tokenId of the minted membership
    function _extendExpiration(uint256 tokenId) internal returns (uint256) {
        uint256 expirationTimestamp = expirationTimestampOf(tokenId);

        // prevent extending lifetime memberships
        if (expirationTimestamp == type(uint256).max) revert InvalidRenewal();

        uint256 newExpirationTimestamp;
        if (expirationTimestamp > block.timestamp) {
            // if non-expired, extend by _expirationTimestamp + validity
            newExpirationTimestamp = expirationTimestamp + validity;
        } else {
            // if expired, extend by now + validity
            newExpirationTimestamp = block.timestamp + validity;
        }
        _expirationTimestamps[tokenId] = newExpirationTimestamp;

        return newExpirationTimestamp;
    }

    /// @dev Utility method to handle ether or token transfers.
    ///      Reverts if contract does not have enough ether balance
    /// @param recipient recipient of the ether transfer
    /// @param amount amount of ether to transfer in wei
    function _transferFunds(
        address _tokenAddress,
        address recipient,
        uint256 amount
    ) internal {
        if (_tokenAddress != ETH_ADDRESS) {
            IERC20(tokenAddress).safeTransfer(recipient, amount);
        } else {
            if (!(address(this).balance >= amount)) revert InsufficientBalance();

            (bool success, ) = recipient.call{ value: amount }(""); // solhint-disable avoid-low-level-calls
            if (!success) revert TransferFailed();
        }
    }

    /// @dev Override for ERC721Upgradeable._baseURI() to be used in `tokenURI()`
    /// @return `_baseTokenURI`
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // The functions below are overrides required by Solidity.

    function owner() public view virtual override(IMemberships, OwnableUpgradeable) returns (address) {
        return super.owner();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev `_burn` is not currently exposed to prevent burning of any token
    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}