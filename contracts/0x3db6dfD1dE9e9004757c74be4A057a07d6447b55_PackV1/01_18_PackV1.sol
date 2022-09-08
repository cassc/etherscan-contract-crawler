// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                          G#BBBBBBBBBBBBBBBBBB#P    P#BBBBBBBBBBBBBBBBBB#G                          
                          @@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@@                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
             [email protected]@@@@@@@&[email protected]@@@@@@@@[email protected]@@@@@@@@JJJJ&@@@@@@@@Y?!^.                     
             @@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@&5^                  
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@&~                
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@B               
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@&              
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@@5             
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@@&             
             [email protected]@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@@&             
             [email protected]@@@@@@@@@@@@@@@@@@@#    [email protected]@@@@@@@@@@@@@@@@@@@B    #@@@@@@@@@@@@@@@@@@@@&             
              :&@@@@@@@@@@@@@@@@@@#    [email protected]@@@@@@@@@@@@@@@@@@@.    #@@@@@@@@@@@@@@@@@@@@&             
                [email protected]@@@@@@@@@@@@@@@@#     .#@@@@@@@@@@@@@@@@#.     #@@@@@@@@@@@@@@@@@@@@&             
                  [email protected]@@@@@@@@@@@@@&       [email protected]@@@@@@@@@@@B~       &@@@@@@@@@@@@@@@@@@@@@             
                     :7YGBBBBBBBB#5         .^?PBBBBP?^.         5#BBBBBBBBBBBBBBBBBB#G             
*/

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract PackV1 is
    Initializable,
    ERC721Upgradeable,
    ERC721RoyaltyUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ECDSAUpgradeable for bytes32;

    struct Config {
        string name;
        string symbol;
        string baseURI;
        uint256 cost;
        uint256 presaleCost;
        uint256 maxSupply;
        uint256 maxPresaleSupply;
        address signer;
        address saleSplitter;
        address royaltySplitter;
        uint96 royaltyBPS;
    }

    string public baseURI;
    uint256 public cost;
    uint256 public presaleCost;
    uint256 public maxSupply;
    uint256 public maxPresaleSupply;
    address public saleSplitter;
    address public royaltySplitter;

    address private _signer;
    mapping(string => bool) private _usedNonces;
    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(Config memory config) public initializer {
        __ERC721_init_unchained(config.name, config.symbol);
        __ERC2981_init_unchained();
        __ERC721Royalty_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();

        baseURI = config.baseURI;
        cost = config.cost;
        presaleCost = config.presaleCost;
        maxSupply = config.maxSupply;
        maxPresaleSupply = config.maxPresaleSupply;
        _signer = config.signer;
        saleSplitter = config.saleSplitter;
        royaltySplitter = config.royaltySplitter;

        // Set the default royalty info for secondary sales using ERC-2981 standard.
        _setDefaultRoyalty(config.royaltySplitter, config.royaltyBPS);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "storefront"));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setCost(uint256 cost_) public onlyOwner {
        cost = cost_;
    }

    function setPresaleCost(uint256 presaleCost_) public onlyOwner {
        presaleCost = presaleCost_;
    }

    function _verifySigner(
        bytes32 hash,
        bytes memory signature,
        address account
    ) internal pure returns (bool) {
        return hash.toEthSignedMessageHash().recover(signature) == account;
    }

    function _verifyHash(
        bytes32 hash,
        address sender,
        string memory nonce
    ) internal pure returns (bool) {
        return hash == keccak256(abi.encode(sender, nonce));
    }

    function safeMint(
        bytes32 hash,
        bytes calldata signature,
        string calldata nonce
    ) external payable whenNotPaused {
        require(msg.sender == tx.origin, "Contracts are not allowed to mint");

        // Verify the off-chain signature.
        require(_verifySigner(hash, signature, _signer), "Invalid signature");
        require(_verifyHash(hash, msg.sender, nonce), "Invalid hash");
        require(!_usedNonces[nonce], "Nonce already used");

        // Set the minting cost depending on the sale stage.
        uint256 mintingFee;
        uint256 tokenId = _tokenIdCounter.current();
        if (keccak256(bytes(nonce[:7])) == keccak256("presale")) {
            mintingFee = presaleCost;
            require(
                tokenId < maxPresaleSupply,
                "Exceed the max presale supply"
            );
        } else {
            mintingFee = cost;
        }

        require(tokenId < maxSupply, "Exceed the max supply");
        require(msg.value >= mintingFee, "Not enough ether paid");

        _usedNonces[nonce] = true; // Mark the nonce as used.
        AddressUpgradeable.sendValue(payable(saleSplitter), msg.value);
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function airdrop(address[] memory recipients)
        external
        onlyOwner
        whenNotPaused
    {
        uint256 tokenId = _tokenIdCounter.current();
        require(
            (tokenId + recipients.length) <= maxSupply,
            "Exceed the max supply"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            _tokenIdCounter.increment();
            _safeMint(recipients[i], tokenId);
            tokenId = _tokenIdCounter.current();
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}