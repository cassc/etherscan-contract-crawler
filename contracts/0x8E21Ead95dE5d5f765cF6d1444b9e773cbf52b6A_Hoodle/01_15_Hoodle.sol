// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//          ___   ___   _________   _________   _______
//         /  /  /  /  /  ___   /  /  ___   /  /  ___  \
//        /xx/  /xx/  /xx/  /xx/  /xx/  /xx/  /xx/  /xx/
//       /xx/__/xx/  /xx/  /xx/  /xx/  /xx/  /xx/  /xx/
//      /xxxxxxxx/  /xx/  /xx/  /xx/  /xx/  /xx/  /xx/
//     /xxxxxxxx/  /xx/  /xx/  /xx/  /xx/  /xx/  /xx/
//    /xx/  /xx/  /xx/  /xx/  /xx/  /xx/  /xx/  /xx/
//   /xx/  /xx/  /xx/__/xx/  /xx/__/xx/  /xx/__/xx/
//  /__/  /__/  /________/  /________/  /________/
//
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

contract Hoodle is Ownable, ReentrancyGuard, ERC721ABurnable {
    using SafeMath for uint256;
    using Strings for uint256;

    // Max token supply of 3333,
    uint256 public constant MAX_TOKENS = 3333;
    uint256 public constant PRESALE_PURCHASE_LIMIT = 4;
    uint256 public constant PUBLIC_SALE_PURCHASE_LIMIT = 6;
    uint256 public tokenPrice = 0.07 ether;

    bool public revealStatus;
    bool public presaleActive;
    bool public publicSaleActive;

    // wallet addresses
    address public hoodlesTreasury;
    address public beneficiary;

    mapping(address => uint256) public presaleClaimed;
    mapping(address => uint256) public publicSaleClaimed;
    mapping(address => bool) public isGiveawayClaimed;
    mapping(address => uint256) public giveawayAddresses;
    mapping(address => bool) public presaleAddresses;

    string public baseTokenURI;
    string public hiddenTokenURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _beneficiary,
        address _hoodlesTreasury,
        string memory _initialTokenURI,
        string memory _hiddenTokenURI
    ) ERC721A(_name, _symbol) {
        beneficiary = _beneficiary;
        hoodlesTreasury = _hoodlesTreasury;
        baseTokenURI = _initialTokenURI;
        hiddenTokenURI = _hiddenTokenURI;
    }

    function setPresaleStatus(bool _state) public onlyOwner {
        presaleActive = _state;
        publicSaleActive = false;
    }

    function setPublicSaleStatus(bool _state) public onlyOwner {
        presaleActive = false;
        publicSaleActive = _state;
    }

    // Function to reveal NFTs to their holders
    function changeRevealStatus(bool _state) external onlyOwner {
        revealStatus = _state;
    }

    // functions to modify or view the base token uri
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Function to get ownershipdata of a token
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    // Function to mint new NFTs, presale
    function presaleMint(uint256 numOfTokens) external payable nonReentrant {
        require(presaleActive, "Presale not ongoing");
        require(msg.sender == tx.origin, "Wallet Error");
        require(presaleAddresses[msg.sender], "Not whitelisted");
        require(
            presaleClaimed[msg.sender] + numOfTokens <= PRESALE_PURCHASE_LIMIT,
            "Address limit reached"
        );
        require(numOfTokens * tokenPrice == msg.value, "Ether value mismatch");

        presaleClaimed[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
        payable(beneficiary).transfer(msg.value);
    }

    // Function to mint new NFTs, public sale
    function publicSaleMint(uint256 numOfTokens) external payable nonReentrant {
        require(publicSaleActive, "Public Sale not ongoing");
        require(msg.sender == tx.origin, "Wallet Error");
        require(
            totalSupply() + numOfTokens <= MAX_TOKENS,
            "Supply limit reached"
        );
        require(numOfTokens * tokenPrice == msg.value, "Ether value mismatch");
        require(
            publicSaleClaimed[msg.sender] + numOfTokens <=
                PUBLIC_SALE_PURCHASE_LIMIT,
            "Address limit reached"
        );
        publicSaleClaimed[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
        payable(beneficiary).transfer(msg.value);
    }

    // Function setPresaleAddresses to give presale access to addresses
    function setPresaleAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            presaleAddresses[_addresses[i]] = true;
        }
    }

    // Function to get total supply minted
    function getTotalSupplyMinted() external view returns (uint256) {
        return totalSupply();
    }

    // Function to allow only the contract owner to withdraw
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Zero Balance");
        payable(beneficiary).transfer(address(this).balance);
    }

    // Function to set giveaway addresses (tokenIds should be below 60)
    function setGiveawayAddresses(
        address[] memory _addresses,
        uint256[] memory _tokenAmounts
    ) external onlyOwner {
        require(_addresses.length == _tokenAmounts.length, "array size mismatch");
        for (uint256 i = 0; i < _addresses.length; i++) {
            giveawayAddresses[_addresses[i]] = _tokenAmounts[i];
        }
    }

    // Function to claim giveaway
    function claimGiveaway() external nonReentrant {
        require(!isGiveawayClaimed[msg.sender], "Error: user already claimed giveaway");
        isGiveawayClaimed[msg.sender] = true;
        _safeMint(msg.sender, giveawayAddresses[msg.sender]);
    }

    /// Function to burn supply
    function burnSupply(uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            burn(_tokenIds[i]);
        }
    }

    /// Function to get token URI of given token ID
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory json = ".json";
        require(_exists(_tokenId), "Non existent Token");
        if (!revealStatus) {
            return string(abi.encodePacked(hiddenTokenURI, _tokenId.toString(), json));
        } else {
            return string(abi.encodePacked(baseTokenURI, _tokenId.toString(), json));
        }
    }
}