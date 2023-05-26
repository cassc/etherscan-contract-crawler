// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/*

██████╗  █████╗ ██╗    ██╗
██╔══██╗██╔══██╗██║    ██║
██║  ██║███████║██║ █╗ ██║
██║  ██║██╔══██║██║███╗██║
██████╔╝██║  ██║╚███╔███╔╝
╚═════╝ ╚═╝  ╚═╝ ╚══╝╚══╝

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract DesperateApeWives is Ownable, ERC721Enumerable, PaymentSplitter {

    uint public constant MAX_WIVES = 10000;
    uint private DAW_PRICE = 0.08 ether;
    uint private walletLimit = 3;
    string public PROVENANCE_HASH;
    string private _baseURIExtended;
    string private _contractURI;
    bool public _isSaleLive = false;
    bool private locked;
    bool private PROVENANCE_LOCK = false;
    uint public _reserved;

    //Desperate Ape Wives Release Time -
    uint public presaleStart = 1635260400; // October 26th 11AM EST
    uint public presaleEnd = 1635303600;   // October 26th 11PM EST
    uint public publicSale = 1635350400;   // October 27th 12PM EST

    struct Account {
        uint nftsReserved;
        uint walletLimit;
        uint mintedNFTs;
        bool isEarlySupporter;
        bool isWhitelist;
        bool isAdmin;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);

    address[] private _team;
    uint[] private _team_shares;

    address private donation;

    constructor(address[] memory team, uint[] memory team_shares, address[] memory admins, address d1)
        ERC721("Desperate ApeWives", "DAW")
        PaymentSplitter(team, team_shares)
    {
        _baseURIExtended = "ipfs://QmbmjFdnvbYzvD6QfQzLg75TT6Du3hw4rx5Kh1uuqMqevV/";

        accounts[msg.sender] = Account( 0, 0, 0, true, true, true);

        accounts[admins[0]] = Account( 12, 0, 0, false, false, true);
        accounts[admins[1]] = Account( 13, 0, 0, false, false, true);
        accounts[admins[2]] = Account( 12, 0, 0, false, false, true);
        accounts[admins[3]] = Account( 13, 0, 0, false, false, true);
        accounts[admins[4]] = Account( 16, 0, 0, false, false, true);
        accounts[admins[5]] = Account( 17, 0, 0, false, false, true);
        accounts[admins[6]] = Account( 17, 0, 0, false, false, true);
        accounts[admins[7]] = Account( 90, 0, 0, false, false, true);

        _reserved = 190;

        _team = team;
        _team_shares = team_shares;

        donation = d1;
    }

    // Modifiers

    modifier onlyAdmin() {
        require(accounts[msg.sender].isAdmin == true, "Nice try! You need to be an admin");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // End Modifier

    // Setters

    function setAdmin(address _addr) external onlyOwner {
        accounts[_addr].isAdmin = !accounts[_addr].isAdmin;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        require(PROVENANCE_LOCK == false);
        PROVENANCE_HASH = _provenanceHash;
    }

    function lockProvenance() external onlyOwner {
        PROVENANCE_LOCK = true;
    }

    function setBaseURI(string memory _newURI) external onlyAdmin {
        _baseURIExtended = _newURI;
    }

    function setContractURI(string memory _newURI) external onlyAdmin {
        _contractURI = _newURI;
    }

    function deactivateSale() external onlyOwner {
        _isSaleLive = false;
    }

    function activateSale() external onlyOwner {
        _isSaleLive = true;
    }

    function setEarlySupporters(address[] memory _addr) external onlyAdmin {
        for(uint i = 0; i < _addr.length; i++) {
            accounts[_addr[i]].walletLimit = 10;
            accounts[_addr[i]].isEarlySupporter = true;
        }
    }

    function setEarlySupporters5(address[] memory _addr) external onlyAdmin {
        for(uint i = 0; i < _addr.length; i++) {
            accounts[_addr[i]].walletLimit = 5;
            accounts[_addr[i]].isEarlySupporter = true;
        }
    }

    function setWhitelist(address[] memory _addr) external onlyAdmin {
        for(uint i = 0; i < _addr.length; i++) {
            accounts[_addr[i]].walletLimit = 2;
            accounts[_addr[i]].isWhitelist = true;
        }
    }

    function setSaleTimes(uint[] memory _newTimes) external onlyAdmin {
        require(_newTimes.length == 3, "You need to update all times at once");
        presaleStart = _newTimes[0];
        presaleEnd = _newTimes[1];
        publicSale = _newTimes[2];
    }

    // End Setter

    // Getters

    function getSaleTimes() public view returns (uint, uint, uint) {
        return (presaleStart, presaleEnd, publicSale);
    }

    // For OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // End Getter

    // Business Logic

    function claimDonations() external onlyAdmin {
        require(totalSupply() + 2 <= (MAX_WIVES - _reserved), "You would exceed the limit");

        _safeMint(donation, 1); // Good Dollar Donation
        _safeMint(donation, 2); // Brest Cancer Donation
        emit Mint(msg.sender, totalSupply());
    }

    function adminMint() external onlyAdmin {
        uint _amount = accounts[msg.sender].nftsReserved;
        require(accounts[msg.sender].isAdmin == true,"Nice Try! Only an admin can mint");
        require(_amount > 0, 'Need to have reserved supply');
        require(totalSupply() + _amount <= MAX_WIVES, "You would exceed the limit");

        accounts[msg.sender].nftsReserved -= _amount;
        _reserved = _reserved - _amount;

        uint id = totalSupply();

        for (uint i = 0; i < _amount; i++) {
            id++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }
    }

    function airDropMany(address[] memory _addr) external onlyAdmin {
        require(totalSupply() + _addr.length <= (MAX_WIVES - _reserved), "You would exceed the limit");

        // DO MINT
        uint id = totalSupply();

        for (uint i = 0; i < _addr.length; i++) {
            id++;
            _safeMint(_addr[i], id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function mintWife(uint _amount) external payable noReentrant {
        // CHECK BASIC SALE CONDITIONS
        require(_isSaleLive, "Sale must be active to mint");
        require(block.timestamp >= presaleStart, "You must wait till presale begins to mint");
        require(_amount > 0, "Must mint at least one token and under 10");
        require(totalSupply() + _amount <= (MAX_WIVES - _reserved), "Purchase would exceed max supply of Apes");
        require(msg.value >= (DAW_PRICE * _amount), "Ether value sent is not correct");
        require(!isContract(msg.sender), "Contracts can't mint");

        if(block.timestamp >= publicSale) {
            require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Sorry you can only mint 3 per wallet");
        } else if(block.timestamp >= presaleEnd) {
            require(false, "Presale has Ended please Wait till Public sale");
        } else if(block.timestamp >= presaleStart) {
            require(accounts[msg.sender].isWhitelist || accounts[msg.sender].isEarlySupporter, "Sorry you need to be on Whitelist");
            require((_amount + accounts[msg.sender].mintedNFTs) <= accounts[msg.sender].walletLimit, "Wallet Limit Reached");
        }

        // DO MINT
        uint id = totalSupply();

        for (uint i = 0; i < _amount; i++) {
            id++;
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, id);
            emit Mint(msg.sender, totalSupply());
        }

    }

    function releaseFunds() external onlyAdmin {
        for (uint i = 0; i < _team.length; i++) {
            release(payable(_team[i]));
        }
    }

    // helper

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }

}