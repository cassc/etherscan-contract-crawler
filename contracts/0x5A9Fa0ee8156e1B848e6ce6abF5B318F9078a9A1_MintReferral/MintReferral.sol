/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//
struct MintData {
    uint8 coreMinted;
    uint8 teamMinted;
    uint8 partnersMinted;
    uint8 seedMinted;
    uint8 publicMinted;
    uint96 seedSalePrice;
    uint96 publicSalePrice;
    bool seedActive;
    bool publicActive;
}

interface ICryptoHubShares {
    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function decreaseWhitelist(
        address[] calldata _addresses,
        uint8[] calldata _quantity
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function getMintData() external view returns (MintData memory);

    function getWhitelistedQuantity(
        address _address
    ) external view returns (uint8);

    function increaseWhitelist(
        address[] calldata _addresses,
        uint8[] calldata _quantity
    ) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function mintCore(address _ceo, address _cto, address _cmo) external;

    function mintPartners(address[] calldata _to) external;

    function mintPublic(uint8 _quantity) external;

    function mintPublicFor(address _for, uint8 _quantity) external;

    function mintSeed(uint8 _quantity) external;

    function mintSeedFor(address _for, uint8 _quantity) external;

    function mintTeam(address[] calldata _to) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renounceOwnership() external;

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setPublicActive(bool _active) external;

    function setPublicPrice(uint96 _price) external;

    function setRoyalty(address _newOwner, uint96 _newRoyalty) external;

    function setSeedActive(bool _active) external;

    function setSeedPrice(uint96 _price) external;

    function shareFor(uint256 _tokenId) external pure returns (uint256);

    function sharesOf(address _address) external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256 total);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function transferOwnership(address newOwner) external;

    function withdraw() external;
}

//
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//
uint256 constant SEED_MINT_PRICE = 1 ether;

// 1 ETH per NFT
uint256 constant PUBLIC_MINT_PRICE = 2 ether;

// 2 ETH per NFT
uint256 constant REFERAL_PERCENTAGE = 20;

// 20% of the mint price
contract MintReferral is Ownable {
    uint256 publicPrice = PUBLIC_MINT_PRICE;
    /*
    uint256 seedPrice = SEED_MINT_PRICE;
    */
    mapping(address => uint256) public earnings;

    ICryptoHubShares public immutable shares;
    address payable public immutable treasury;

    receive() external payable {
        require(msg.sender == address(shares), "Invalid sender");
    }

    constructor(ICryptoHubShares _shares, address payable _treasury) {
        shares = _shares;
        treasury = _treasury;
        _transferOwnership(0xDD48fA33AB3e6A094B1cA89c1578B9ca96d0e563);
    }

    /*
    function mintSeed(
        address _for,
        uint8 _quantity,
        address payable _referrer
    ) external payable {
        require(msg.value == seedPrice * _quantity, "Invalid payment");
        shares.mintSeedFor(_for, _quantity);

        uint256 _referralAmount;

        if (_referrer != address(0)) {
            // send referral amount to referrer safely
            _referralAmount =
                (_quantity * seedPrice * REFERAL_PERCENTAGE) /
                100;

            (bool success, ) = _referrer.call{value: _referralAmount}("");
            if (success) {
                earnings[_referrer] += _referralAmount;
            } else {
                _referralAmount = 0;
            }
        }

        // send the rest to treasury
        treasury.transfer(msg.value - _referralAmount);
    }
*/
    function mintPublic(
        uint8 _quantity,
        address payable _referrer
    ) external payable {
        address _for = msg.sender;
        require(msg.value == publicPrice * _quantity, "Invalid payment");
        shares.mintPublicFor(_for, _quantity);

        uint256 _referralAmount;

        if (_referrer != address(0)) {
            // send referral amount to referrer safely
            _referralAmount =
                (_quantity * publicPrice * REFERAL_PERCENTAGE) /
                100;

            (bool success, ) = _referrer.call{value: _referralAmount}("");
            if (success) {
                earnings[_referrer] += _referralAmount;
            } else {
                _referralAmount = 0;
            }
        }

        // send the rest to treasury
        treasury.transfer(msg.value - _referralAmount);
    }

    /*
    function setSeedPrice(uint256 _price) external onlyOwner {
        seedPrice = _price;
    }
    */

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function transferOwnershipOfShares(address _newOwner) external onlyOwner {
        shares.transferOwnership(_newOwner);
    }

    function withdrawFromShares() external onlyOwner {
        shares.withdraw();
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        treasury.transfer(address(this).balance);
    }

    function increaseWhitelist(
        address[] calldata _whitelist,
        uint8[] calldata _amount
    ) external onlyOwner {
        shares.increaseWhitelist(_whitelist, _amount);
    }

    function decreaseWhitelist(
        address[] calldata _whitelist,
        uint8[] calldata _amount
    ) external onlyOwner {
        shares.decreaseWhitelist(_whitelist, _amount);
    }

    function mintTeam(address[] calldata _team) external onlyOwner {
        shares.mintTeam(_team);
    }

    function mintPartners(address[] calldata _partners) external onlyOwner {
        shares.mintPartners(_partners);
    }
}