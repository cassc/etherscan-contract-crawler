// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;



import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./interfaces/IERC721xHelper.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

// import "hardhat/console.sol";

contract DigiMonkzGen2 is
    ERC721x,
    DefaultOperatorFiltererUpgradeable,
    IERC721xHelper
{
    uint256 public MAX_SUPPLY;

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

    uint256 public MINT_PRICE;
    bool public canMint;

    mapping(uint256 => bool) public sendNFTLocked;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory baseURI
    ) public initializer {
        ERC721x.__ERC721x_init("DigiMonkzGen2", "DigiMonkzGen2");
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        baseTokenURI = baseURI;
        MAX_SUPPLY = 1111;
    }

    // =============== AIR DROP ===============

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        safeMint(receiver, tokenAmount);
    }

    function airdropList(address[] calldata receivers) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], 1);
        }
    }

    function airdropListWithAmounts(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], amounts[i]);
        }
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== MINTING ===============
    function setupMint(bool mintOpen, uint256 price) external onlyOwner {
        canMint = mintOpen;
        MINT_PRICE = price;
    }

    function mint(uint256 amount) payable external {
        require(canMint, "Mint not open");
        require(msg.value == MINT_PRICE * amount, "Incorrect ETH amount");
        safeMint(msg.sender, amount);
    }

    function withdrawSales() public onlyOwner {
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }

    // =============== BASE URI ===============

    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (bytes(tokenURIOverride).length > 0) {
            return tokenURIOverride;
        }
        return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTokenURISuffix(
        string calldata _tokenURISuffix
    ) external onlyOwner {
        if (compareStrings(_tokenURISuffix, "!empty!")) {
            tokenURISuffix = "";
        } else {
            tokenURISuffix = _tokenURISuffix;
        }
    }

    function setTokenURIOverride(
        string calldata _tokenURIOverride
    ) external onlyOwner {
        if (compareStrings(_tokenURIOverride, "!empty!")) {
            tokenURIOverride = "";
        } else {
            tokenURIOverride = _tokenURIOverride;
        }
    }

    // =============== MARKETPLACE CONTROL ===============
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable override(ERC721x) onlyAllowedOperator(_from) {
        require(sendNFTLocked[_tokenId] == false, "Cannot transfer - currently locked");
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public payable override(ERC721x) onlyAllowedOperator(_from) {
        require(sendNFTLocked[_tokenId] == false, "Cannot transfer - currently locked");
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    // =============== IERC721xHelper ===============
    function isUnlockedMultiple(
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isUnlocked(tokenIds[i]);
        }
        return part;
    }

    function ownerOfMultiple(
        uint256[] calldata tokenIds
    ) external view returns (address[] memory) {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    function setNFTLock(uint256 _nftNumber) public {
        require(ownerOf(_nftNumber) == tx.origin, "Not Owner");
        sendNFTLocked[_nftNumber] = true;
    }
    
    function setNFTUnLock(uint256 _nftNumber) public {
        require(ownerOf(_nftNumber) == tx.origin, "Not Owner");
        sendNFTLocked[_nftNumber] = false;
    }

    // function tokenNameByIndexMultiple(
    //     uint256[] calldata tokenIds
    // ) external view returns (string[] memory) {
    //     string[] memory part = new string[](tokenIds.length);
    //     for (uint256 i = 0; i < tokenIds.length; i++) {
    //         part[i] = tokenNameByIndex(tokenIds[i]);
    //     }
    //     return part;
    // }
}