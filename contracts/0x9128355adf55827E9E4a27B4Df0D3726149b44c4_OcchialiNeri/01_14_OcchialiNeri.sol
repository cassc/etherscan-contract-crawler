//SPDX-License-Identifier: MIT
//solhint-disable no-empty-blocks

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OcchialiNeri is ERC721Enumerable, Ownable {
    using Strings for uint256;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    mapping(address => uint256) private maxMintsPerAddress;

    uint256 public constant MINT_PRICE = 0.12 ether;

    address public constant FEES_RECEIVER = 0x84c8e944a3be9Bc369b3a7c34274AB48d46333fC;

    uint256 public constant MAX_SUPPLY = 588;
    uint256 public constant MAX_WHITELIST_MINT = 2;
    uint256 public MAX_PUBLIC_MINT = 2;

    bool public publicSale = false;
    bool public isBaseURILocked = false;

    string private baseURI;

    bytes32 public reservedMerkleRoot;
    bytes32 public whitelistMerkleRoot;

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

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        payable(FEES_RECEIVER).transfer(_balance);
    }

    function flipSaleState() public onlyOwner {
        publicSale = !publicSale;
    }

    function lockBaseURI() public onlyOwner {
        isBaseURILocked = true;
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
            if (totalSupply() < MAX_SUPPLY) {
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
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
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
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++;
            } else {
                break;
            }
        }
    }
}