//SPDX-License-Identifier: MIT
//solhint-disable no-empty-blocks

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BirdezGang is ERC721Enumerable, Ownable {
    using Strings for uint256;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    mapping(address => uint256) private maxMintsPerAddress;

    // address -> tokenId -> holdingStart
    mapping(address => mapping(uint256 => uint256)) private holdingStart;

    uint256 public constant MINT_PRICE = 0.07777 ether;

    uint256 public constant MAX_BIRDEZ = 1333;
    uint256 public constant MAX_WHITELIST_MINT = 2;
    uint256 public MAX_PUBLIC_MINT = 5;

    bool public publicSale = false;
    bool public isBaseURILocked = false;

    string private baseURI;

    bytes32 public reservedMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    address[] public teamPayments = [
        0x4665c4cb577676C9302530C744f1f2053c707695, // Founders
        0x8a5012aAB7718Ef8e215bD3b51e3285aAb644323, // Strategic
        0xA124714045023cd46AC85F46a6D51af485888369, // Marketing
        0x5d2A3368d9Aa1E8ab86282Ed348FE210F5B1526A, // Charity
        0xFcb17F310424D0c786C4042b7CE0A8E7E3dD6e22, // Advisor
        0x2f5BD298c1812Ee2acEC29dC6A7649864FA0A182, // Dev Team
        0x167b5c463E42939D321473B9F9dddd772b2b7cF2, // Marketing team
        0xC2a8814258F0bb54F9CC1Ec6ACb7a6886097b994 // SC Dev
    ];

    uint256[] public teamPaymentShares = [
        410, // founders: 41%
        100, // strategic: 10%
        280, // marketing: 28%
        10, // charity: 1%
        100, // advisor: 10%
        45, // marketing team: 4.5%
        45, // dev team: 4.5%
        10 // SC Dev
    ];

    function updateWhitelistMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _newMerkleRoot;
    }

    function updateReservedMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner
    {
        reservedMerkleRoot = _newMerkleRoot;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        require(!isBaseURILocked, "locked-base-uri");
        baseURI = newURI;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        for (uint256 i = 0; i < teamPayments.length; i++) {
            uint256 _shares = (_balance / 1000) * teamPaymentShares[i];
            uint256 _currentBalance = address(this).balance;
            _shares = (_shares < _currentBalance) ? _shares : _currentBalance;
            payable(teamPayments[i]).transfer(_shares);
        }
    }

    function flipSaleState() public onlyOwner {
        publicSale = !publicSale;
    }

    function lockBaseURI() public onlyOwner {
        isBaseURILocked = true;
    }

    function holdingTime(address _owner, uint256 _tokenId)
        external
        view
        returns (uint256 _time)
    {
        if (holdingStart[_owner][_tokenId] == 0) return 0;
        _time = block.timestamp - holdingStart[_owner][_tokenId];
    }

    function mint(uint256 _numberOfTokens) public payable {
        require(publicSale, "sale-not-active");
        require(!isContract(msg.sender), "mint-via-contract");
        require(
            _numberOfTokens > 0 && _numberOfTokens <= MAX_PUBLIC_MINT,
            "mint-number-out-of-range"
        );
        require(
            msg.value == MINT_PRICE * _numberOfTokens,
            "incorrect-ether-value"
        );
        require(
            maxMintsPerAddress[msg.sender] + _numberOfTokens <= MAX_PUBLIC_MINT,
            "max-mint-limit"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_BIRDEZ) {
                _safeMint(msg.sender, totalSupply());
                maxMintsPerAddress[msg.sender]++;
            } else {
                payable(msg.sender).transfer(
                    (_numberOfTokens - i) * MINT_PRICE
                );
                break;
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        holdingStart[from][tokenId] = 0;
        holdingStart[to][tokenId] = block.timestamp;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId.toString()));
    }

    function whitelistedMint(
        uint256 _numberOfTokens,
        bytes32[] calldata merkleProof
    ) external payable {
        address _user = msg.sender;

        require(
            totalSupply() + _numberOfTokens <= MAX_BIRDEZ,
            "max-supply-reached"
        );
        require(
            maxMintsPerAddress[_user] + _numberOfTokens <= MAX_WHITELIST_MINT,
            "max-mint-limit"
        );

        // Minter mustbe either in the reserved list or the whitelisted list
        bool isReserved = MerkleProof.verify(
            merkleProof,
            reservedMerkleRoot,
            keccak256(abi.encodePacked(_user))
        );

        bool isWhitelisted = MerkleProof.verify(
            merkleProof,
            whitelistMerkleRoot,
            keccak256(abi.encodePacked(_user))
        );

        require(isReserved || isWhitelisted, "invalid-proof");
        require(
            isReserved || msg.value == MINT_PRICE * _numberOfTokens,
            "incorrect-ether-value"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_BIRDEZ) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++;
            } else {
                break;
            }
        }
    }
}