// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";

contract CheethV3 is ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 21_000_000;

    address private _rewarderAddress;
    address public genesisAddress;
    address public babyAddress;
    bool public isSignatureClaimEnabled;

    mapping(uint256 => bool) public claimedBabies;
    mapping(uint256 => bool) public claimedGenesis;
    mapping(address => bool) public claimedWallets;

    constructor() ERC20("Cheeth", "CHEETH") {
        isSignatureClaimEnabled = true;
    }

    function claimCheeth(uint256 outcome, bytes calldata signature) external {
        (
            uint256[] memory genesisTokens,
            uint256 genesisClaimableCheeth,
            uint256[] memory babyTokens,
            uint256 babyClaimableCheeth
        ) = getClaimableData(msg.sender);

        for (uint256 index = 0; index < genesisTokens.length; index++) {
            claimedGenesis[genesisTokens[index]] = true;
        }
        for (uint256 index = 0; index < babyTokens.length; index++) {
            claimedBabies[babyTokens[index]] = true;
        }

        if (outcome > 0) {
            _validateCheethClaimSignature(outcome, signature);
            claimedWallets[msg.sender] = true;
        }

        _safeMint(msg.sender, genesisClaimableCheeth + babyClaimableCheeth + outcome);
    }

    function _validateCheethClaimSignature(uint256 outcome, bytes calldata signature) internal view {
        require(isSignatureClaimEnabled, "signature claim disabled");
        require(!claimedWallets[msg.sender], "not allowed");
        bytes32 messageHash = keccak256(abi.encodePacked(outcome, msg.sender));
        require(_verifySignature(messageHash, signature), "invalid signature");
    }

    function getClaimableData(address owner)
        public
        view
        returns (
            uint256[] memory genesisTokens,
            uint256 genesisClaimableCheeth,
            uint256[] memory babyTokens,
            uint256 babyClaimableCheeth
        )
    {
        genesisTokens = _getClaimableGenesisTokens(owner);
        babyTokens = _getClaimableBabyTokens(owner);
        genesisClaimableCheeth = genesisTokens.length * 4500 ether;
        babyClaimableCheeth = babyTokens.length * 1125 ether;
        return (genesisTokens, genesisClaimableCheeth, babyTokens, babyClaimableCheeth);
    }

    function setIsSignatureClaimEnabled(bool _isSignatureClaimEnabled) external onlyOwner {
        isSignatureClaimEnabled = _isSignatureClaimEnabled;
    }

    function setAddresses(
        address _genesisAddress,
        address _babyAddress,
        address rewarderAddress
    ) external onlyOwner {
        genesisAddress = _genesisAddress;
        babyAddress = _babyAddress;
        _rewarderAddress = rewarderAddress;
    }

    function _getClaimableGenesisTokens(address owner) internal view returns (uint256[] memory) {
        uint256[] memory tokens = _getAllTokens(genesisAddress, owner);
        uint256 claimableTokensCount;
        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];
            if (!claimedGenesis[tokenId]) {
                claimableTokensCount++;
            }
        }

        uint256[] memory claimableTokens = new uint256[](claimableTokensCount);
        uint256 resultsIndex;

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];
            if (!claimedGenesis[tokenId]) {
                claimableTokens[resultsIndex] = tokenId;
                resultsIndex++;
            }
        }
        return claimableTokens;
    }

    function _getClaimableBabyTokens(address owner) internal view returns (uint256[] memory) {
        uint256[] memory tokens = _getAllTokens(babyAddress, owner);
        uint256 claimableTokensCount;
        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];
            if (!claimedBabies[tokenId]) {
                claimableTokensCount++;
            }
        }

        uint256[] memory claimableTokens = new uint256[](claimableTokensCount);
        uint256 resultsIndex;

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];
            if (!claimedBabies[tokenId]) {
                claimableTokens[resultsIndex] = tokenId;
                resultsIndex++;
            }
        }
        return claimableTokens;
    }

    function _getAllTokens(address tokenAddress, address owner) internal view returns (uint256[] memory) {
        uint256 tokenCount = IERC721Enumerable(tokenAddress).balanceOf(owner);
        uint256[] memory tokens = new uint256[](tokenCount);
        for (uint256 index = 0; index < tokenCount; index++) {
            tokens[index] = IERC721Enumerable(tokenAddress).tokenOfOwnerByIndex(owner, index);
        }
        return tokens;
    }

    function _safeMint(address to, uint256 amount) internal {
        uint256 newSupply = totalSupply() + amount;
        require(newSupply <= MAX_SUPPLY * 1 ether, "max supply");
        _mint(to, amount);
    }

    function _verifySignature(bytes32 messageHash, bytes memory signature) internal view returns (bool) {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature) == _rewarderAddress;
    }
}