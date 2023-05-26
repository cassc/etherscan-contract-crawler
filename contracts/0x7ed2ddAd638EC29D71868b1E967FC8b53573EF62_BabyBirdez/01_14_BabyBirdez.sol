//SPDX-License-Identifier: MIT
//solhint-disable no-empty-blocks

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BabyBirdez is ERC721Enumerable, Ownable {
    using Strings for uint256;

    address public constant DAO = 0xF5599b2fB8C9DB34876C1C9A585721cFd4252eEB;
    address public genesisBirdez;
    address public breeder;

    modifier onlyAllowed() {
        require(msg.sender == breeder, "not-allowed-to-mint");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _genesisBirdez
    ) ERC721(_name, _symbol) {
        genesisBirdez = _genesisBirdez;

        for (uint256 i = 0; i < 10; i++)
            _safeMint(DAO, totalSupply());

    }

    mapping(address => uint256) private maxMintsPerAddress;
    mapping(uint256 => bool) public isHatch;

    uint256 public constant MINT_PRICE = 0.07 ether;
    uint256 public constant MAX_BABY_FIRST_PHASE = 1444;
    uint256 public constant MAX_WHITELIST_MINT = 4;

    bool public publicSale = false;
    bool public isBaseURILocked = false;

    string private baseURI;

    bytes32 public whitelistMerkleRoot;

    address[] public teamPayments = [
        DAO, // DAO
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
        400, // DAO: 40%
        226, // founders: 22.6%
        50, // strategic: 5%
        168, // marketing: 16.8%
        6, // charity: 0.6%
        60, // advisor: 6%
        40, // marketing team: 4%
        40, // dev team: 4%
        10 // SC Dev: 1%
    ];

    function hatch(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "only-owner-can-hatch");
        isHatch[_tokenId] = true;
    }

    function updateWhitelistMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _newMerkleRoot;
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

    function setBreeder(address _newBreeder) public onlyOwner {
        breeder = _newBreeder;
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
            totalSupply() + _numberOfTokens <= MAX_BABY_FIRST_PHASE,
            "max-supply-reached"
        );
        require(
            maxMintsPerAddress[_user] + _numberOfTokens <= MAX_WHITELIST_MINT,
            "max-mint-limit"
        );

        bool isWhitelisted = MerkleProof.verify(
            merkleProof,
            whitelistMerkleRoot,
            keccak256(abi.encodePacked(_user))
        );

        require(isWhitelisted, "invalid-proof");

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_BABY_FIRST_PHASE) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++;
            } else {
                break;
            }
        }
    }

    // Allowed address will be the breeding contract
    function mintTo(address _to, uint256 _numberOfTokens) external onlyAllowed {
        for (uint256 i = 0; i < _numberOfTokens; i++)
            _safeMint(_to, totalSupply());
    }

    function mint(uint256 _numberOfTokens) public payable {
        require(publicSale, "sale-not-active");
        uint256 genesisBalance = IERC721Enumerable(genesisBirdez).balanceOf(
            msg.sender
        );
        require(genesisBalance >= 2, "not-enough-genesis");
        require(
            _numberOfTokens > 0 && _numberOfTokens <= genesisBalance * 2,
            "mint-number-out-of-range"
        );
        require(
            msg.value == MINT_PRICE * _numberOfTokens,
            "incorrect-ether-value"
        );
        require(
            maxMintsPerAddress[msg.sender] + _numberOfTokens <=
                genesisBalance * 2,
            "max-mint-limit"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_BABY_FIRST_PHASE) {
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
}