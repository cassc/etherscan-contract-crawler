// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../nft/BitHotelCollection.sol";

contract BithotelPaymentReceiver is Initializable, ReentrancyGuard, AccessControl {
    address private _owner;
    address private _claimProcess;
    address private _royaltyRecipient;
    uint256 private _royaltyValue;
    uint256 private _gasfee;

    bool public initializerRan;
    bytes32 public constant CLAIM_ROLE = keccak256("CLAIM_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant WHITELISTED_COLLECTION = keccak256("WHITELISTED_COLLECTION");

    mapping(address => uint256) private _balanceOf;
    mapping(address => uint256) private _claimedOf;
    mapping(address => mapping(address => uint256)) public addressBought;

    event PaymentReceived(address account, uint256 amount, address collectionAddress);
    event RewardReleased(address account, uint256 amount);
    event WhitelistNFT(address collectionAddress, uint256 price);
    event DelistNFT(address collectionAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address mOwner,
        address mClaimProcess,
        address royaltyRecipient,
        uint256 royaltyValue
    ) {
        require(mOwner != address(0), "owner is the zero address");
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, mOwner);
        _grantRole(CLAIM_ROLE, mClaimProcess);
        _grantRole(UPGRADER_ROLE, _msgSender());
        _gasfee = 3000000000000000; // 0.0003 BNB ($0.12)
        _claimProcess = mClaimProcess;
        _royaltyRecipient = royaltyRecipient;
        _royaltyValue = royaltyValue;
        initializerRan = true;
    }

    fallback() external payable virtual {
        // receiveBNB();
    }

    receive() external payable virtual {
        // receiveBNB();
    }

    function version() external pure virtual returns (string memory) {
        return "1.0";
    }

    function claim(address account, address collectionAddress) external virtual nonReentrant onlyRole(CLAIM_ROLE) {
        require(account != address(0), "account is the zero address");
        require(bnbBalanceOf(account) > 0, "no balance available");

        uint256 oldBalance = bnbBalanceOf(account);
        _balanceOf[account] = 0;
        _claimedOf[account] = block.timestamp;

        // Mint NFT
        BitHotelCollection erc721Token = BitHotelCollection(collectionAddress);
        erc721Token.mint(account, _royaltyRecipient, _royaltyValue);

        addressBought[account][collectionAddress] += 1;
        emit RewardReleased(account, oldBalance);
    }

    function changeGasFee(uint256 gasfee) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(gasfee > 0, "gasfee is the zero value");
        require(gasfee != _gasfee, "gasfee already set");
        _gasfee = gasfee;
    }

    function receiveBNB(address collectionAddress) public payable nonReentrant {
        address account = _msgSender();

        require(hasRole(WHITELISTED_COLLECTION, collectionAddress), "collection is not whitelisted");
        require(claimedOf(account) < (block.timestamp + 1 days), "claim available once a day");
        require(addressBought[account][collectionAddress] < 2);
        // require(_balanceOf[account] == 0, "account already has balance");
        require(msg.value == _gasfee, "amount must be equal to gasfee");

        _balanceOf[account] += msg.value;
        _forwardFunds(_claimProcess);

        emit PaymentReceived(account, msg.value, collectionAddress);
    }

    function resetBNB(address account) public payable nonReentrant onlyRole(CLAIM_ROLE) {
        require(account != address(0), "account is not zero address");
        require(bnbBalanceOf(account) > 0, "no balance available");
        require(msg.value == (_gasfee * 2) / 3, "amount not equal to 2/3 gasfee");

        _balanceOf[account] = 0;
        _forwardFunds(account);
    }

    function bnbBalanceOf(address account) public view virtual returns (uint256) {
        return _balanceOf[account];
    }

    function claimedOf(address account) public view virtual returns (uint256) {
        return _claimedOf[account];
    }

    function whitelistNft(address collectionAddress, uint256 price) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(collectionAddress != address(0), "address is the zero address");

        _grantRole(WHITELISTED_COLLECTION, collectionAddress);

        emit WhitelistNFT(collectionAddress, price);
    }

    function delistNft(address collectionAddress) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(collectionAddress != address(0), "address is the zero address");
        require(hasRole(WHITELISTED_COLLECTION, collectionAddress), "collection is not whitelisted");

        _revokeRole(WHITELISTED_COLLECTION, collectionAddress);

        emit DelistNFT(collectionAddress);
    }

    /**
     * @dev See {IBitHotelRoomCollection-setController}.
     */
    function setController(address collectionAddress, address controller_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BitHotelCollection(collectionAddress).setController(controller_);
    }

    /**
     * @dev Determines how BNB is stored/forwarded on received.
     */
    function _forwardFunds(address _recipient) internal {
        payable(_recipient).transfer(msg.value);
    }
}