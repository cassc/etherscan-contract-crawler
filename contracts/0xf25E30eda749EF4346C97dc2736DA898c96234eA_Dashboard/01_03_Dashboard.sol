//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC721.sol";

contract Dashboard is ReentrancyGuard {
    struct Admin {
        string email;
        address wallet;
        uint256 createdAt;
    }

    struct User {
        string fullName;
        string email;
        address wallet;
        uint16 level;
        uint64 investmentUpTo;
    }

    uint16 public investmentPerCard = 5000;

    // Available NFT Cards. Can be created by admins.
    address[] private _nftCards;

    // Mapping to easily find a specific NFT Card by the index.
    mapping(address => uint256) private _nftCardIndexes;

    // All authenticated holders. It's unique.
    string[] private _holderEmails;

    // Mapping for fast lookup
    mapping(address => uint256) private _emailIndexes;
    mapping(string => string) private _holderNames;
    mapping(string => address) private _holderAddresses;
    mapping(string => uint256) private _holderCreatedAt;

    mapping(address => bool) private _admins;
    mapping(address => string) private _adminEmails;
    mapping(address => uint256) private _adminCreatedAt;
    address[] private _adminAddresses;

    constructor() {
        _holderEmails.push(""); // ignore index 0 so we can use index 0 as an indication that the email is not in the list
        _admins[address(msg.sender)] = true;
        _adminAddresses.push(address(msg.sender));
        _adminCreatedAt[address(msg.sender)] = block.timestamp;
    }

    function addAdmin(address adminWallet) external onlyAdmins {
        if (!_admins[adminWallet]) {
            _admins[adminWallet] = true;
            _adminAddresses.push(adminWallet);
            _adminCreatedAt[adminWallet] = block.timestamp;
            _adminEmails[adminWallet] = "";
        }
    }

    function authenticate(string memory email, string memory fullName) external onlyCardHolders {
        if (_emailIndexes[address(msg.sender)] == 0) {
            _emailIndexes[address(msg.sender)] = _holderEmails.length;
            _holderEmails.push(email);
        } else {
            _holderEmails[_emailIndexes[address(msg.sender)]] = email;
        }
        _holderNames[email] = fullName;
        _holderAddresses[email] = address(msg.sender);
        _holderCreatedAt[email] = block.timestamp;
    }

    function addNftContract(address _nft) external onlyAdmins {
        if (_nftCardIndexes[_nft] == 0) {
            _nftCardIndexes[_nft] = _nftCards.length;
            _nftCards.push(_nft);
        }
    }

    function deleteAdmin(address adminWallet) external onlyAdmins {
        if (_admins[adminWallet]) {
            _admins[adminWallet] = false;
            for (uint256 i = 0; i < _adminAddresses.length; i++) {
                if (_adminAddresses[i] == adminWallet) {
                    _adminAddresses[i] = _adminAddresses[_adminAddresses.length - 1];
                    break;
                }
            }
            _adminAddresses.pop(); // remove the last item
            _adminEmails[adminWallet] = "";
        }
    }

    function getAdmins() external view returns (Admin[] memory) {
        Admin[] memory admins = new Admin[](_adminAddresses.length);
        for (uint256 i = 0; i < _adminAddresses.length; i++) {
            address adminAddress = _adminAddresses[i];
            admins[i] = Admin(_adminEmails[adminAddress], adminAddress, _adminCreatedAt[adminAddress]);
        }
        return admins;
    }

    function getCardCount(address wallet) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _nftCards.length; i++) {
            IERC721 nftCard = IERC721(_nftCards[i]);
            count += nftCard.balanceOf(wallet);
        }
        return count;
    }

    function getNftCards() external view returns (address[] memory) {
        return _nftCards;
    }

    function getUserEmails() external view returns (string[] memory) {
        return _holderEmails;
    }

    function getUserCreatedAt(address wallet) external view returns (uint256) {
        string memory email = _holderEmails[_emailIndexes[wallet]];
        return _holderCreatedAt[email];
    }

    function getUsers() external view returns (User[] memory) {
        User[] memory users = new User[](_holderEmails.length - 1);
        for (uint256 i = 1; i < _holderEmails.length; i++) {
            string memory email = _holderEmails[i];
            address wallet = _holderAddresses[email];
            string memory fullName = _holderNames[email];
            uint256 cardCount = getCardCount(wallet);
            uint64 investmentUpTo = uint64(cardCount * investmentPerCard);
            users[i - 1] = User(
                fullName,
                email,
                wallet,
                12, // ???
                investmentUpTo
            );
        }
        return users;
    }

    function isAdmin(address walletAddress) external view returns (bool) {
        return _admins[walletAddress];
    }

    function isAuthenticated(address walletAddress) external view returns (bool) {
        return _emailIndexes[walletAddress] > 0;
    }

    function ownsNftCard(address wallet) public view returns (bool) {
        for (uint256 i = 0; i < _nftCards.length; i++) {
            IERC721 nftCard = IERC721(_nftCards[i]);
            if (nftCard.balanceOf(wallet) > 0) return true;
        }
        return false;
    }

    /**
        @dev Replaces from's email and address with the last email and address in the arrays.
     */
    function signOut(address from) public {
        require(from == address(msg.sender) || _admins[address(msg.sender)], "Dashboard: Only admins or the user itself can sign out");
        uint256 fromEmailIdx = _emailIndexes[from];
        uint256 lastEmailIdx = _holderEmails.length - 1;
        _holderEmails[fromEmailIdx] = _holderEmails[lastEmailIdx];
        _holderEmails.pop();
    }

    function updateAdminEmail(string memory email) external onlyAdmins {
        _adminEmails[address(msg.sender)] = email;
    }

    function updateInvestmentPerCard(uint16 value) external onlyAdmins {
        investmentPerCard = value;
    }

    modifier onlyAdmins() {
        require(_admins[address(msg.sender)], "Not admin");
        _;
    }

    modifier onlyCardHolders() {
        require(ownsNftCard(address(msg.sender)), "Not a card holder");
        _;
    }

    modifier onlyFromNft() {
        for (uint256 i = 0; i < _nftCards.length; i++) {
            if (_nftCards[i] == address(msg.sender)) return;
        }
        require(false, "Only callable from VCX NFT Contract");
        _;
    }
}