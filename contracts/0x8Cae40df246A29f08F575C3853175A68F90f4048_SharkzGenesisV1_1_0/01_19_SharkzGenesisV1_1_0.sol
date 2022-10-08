// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █
 *******************************************************************************
 * Sharkz NFT (ERC721A)
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../lib-upgradeable/sharkz/AdminableUpgradeable.sol";
import "../lib-upgradeable/721AStruct/ERC721AStructUpgradeable.sol";
import "../lib-upgradeable/721AStruct/extensions/ERC721ABurnableUpgradeable.sol";
import "../lib-upgradeable/721AStruct/extensions/ERC4907Upgradeable.sol";
import "../lib-upgradeable/712/EIP712WhitelistTypedUpgradeable.sol";
import "../lib/sharkz/IScore.sol";
import "./MintSetupUpgradeable.sol";

interface IBalanceOf {
    function balanceOf(address owner) external view returns (uint256 balance);
}

// @credit: Azuki https://github.com/chiru-labs/ERC721A
contract SharkzGenesisV1_1_0 is Initializable, UUPSUpgradeable, AdminableUpgradeable, ERC721AStructUpgradeable, ERC721ABurnableUpgradeable, ERC4907Upgradeable, IScore, EIP712WhitelistTypedUpgradeable, MintSetupUpgradeable {
    // Implementation version number
    function version() external pure virtual returns (string memory) { return "1.1.0"; }

    string public PROVENANCE;
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public burnedSupply;
    string public baseTokenURI;
    string public unrevealURI;
    // Soul ID linking
    address public soulIdContract;
    // Soulbound base score
    uint256 internal _baseScore;

    // Init this upgradeable contract
    function initialize() public initializer onlyProxy {
        __Adminable_init();
        __ERC721AStruct_init("Sharkz Genesis", "SHARKZG");
        __EIP712WhitelistTyped_init();
        __MintSetup_init();
        soulIdContract = 0x12DEb1Cb5732E40Dd55B89aBB6D5C31dF13A6e38;
        _baseScore = 1;
    }

    // only admins can upgrade the contract
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721AStructUpgradeable, ERC4907Upgradeable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AStructUpgradeable, ERC4907Upgradeable) returns (bool) {
        // See: https://eips.ethereum.org/EIPS/eip-165
        // return true to show proof of supporting following interface, we use bytes4 
        // interface id to avoid importing the whole interface codes.
        return super.supportsInterface(interfaceId) || 
               interfaceId == type(IScore).interfaceId;
    }

    // Set provenance hash
    function setProvenance(string memory _hash) external onlyAdmin {
        PROVENANCE = _hash;
    }

    // Change linking Soul ID contract address
    function setSoulIdContract(address _contract) external onlyAdmin {
        soulIdContract = _contract;
    }
    
    // Change base score
    function setBaseScore(uint256 _score) external virtual onlyAdmin {
        _baseScore = _score;
    }

    /**
     * @dev See {IScore-baseScore}.
     */
    function baseScore() public view virtual override returns (uint256) {
        return _baseScore;
    }

    /**
     * @dev See {IScore-scoreByToken}.
     */
    function scoreByToken(uint256 _tokenId) external view virtual override returns (uint256) {
        if (_exists(_tokenId)) {
          return _baseScore;
        } else {
          return 0;
        }
    }

    /**
     * @dev See {IScore-scoreByAddress}.
     */
    function scoreByAddress(address _addr) external view virtual override returns (uint256) {
        return balanceOf(_addr) * _baseScore;
    }

    // first token start at 1 instead of 0
    function _startTokenId() internal view virtual override(ERC721AStructUpgradeable) returns (uint256) {
        return 1;
    }

    // do not allow contract to call
    modifier callerIsWallet() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function getMintSupply() public view returns (uint256) {
        return MAX_SUPPLY - burnedSupply;
    }

    modifier checkMintQuantity(uint256 _qty) {
        require(_totalMinted() + _qty <= getMintSupply(), "Reached max supply of the collection");
        _;
    }

    // ======== Minting methods ========
    function ownerMint(address _to, uint256 _qty) 
        external 
        onlyAdmin 
        checkMintQuantity(_qty)
    {
        _mint(_to, _qty);
    }

    function soulIdMint(uint256 _qty) 
        external 
        payable 
        callerIsWallet 
        checkMintQuantity(_qty) 
        isFreeMintActive
    {
        require(_isExternalTokenOwner(soulIdContract, msg.sender), "Caller is not Soul ID owner");
        require(_numberSoulIdFreeMinted(msg.sender) + _qty <= mintConfig.freeMintBySoulIdPerWallet, "Reached minting limit per wallet");
        _increaseSoulIdFreeMinted(msg.sender, _qty);
        _mint(msg.sender, _qty);
    }
    
    function freeMint(uint256 _qty, bytes calldata _signature) 
        external 
        payable 
        callerIsWallet 
        checkMintQuantity(_qty) 
        isFreeMintActive
        checkWhitelist(_signature,"freemint")
    {
        require(_numberFreeMinted(msg.sender) + _qty <= mintConfig.freeMintByWLPerWallet, "Reached minting limit per wallet");
        _increaseFreeMinted(msg.sender, _qty);
        _mint(msg.sender, _qty);
    }
    
    function presaleMint(uint256 _qty, bytes calldata _signature) 
        external 
        payable 
        callerIsWallet 
        checkMintQuantity(_qty) 
        isPresaleActive
        checkWhitelist(_signature,"presale")
    {
        require(msg.value >= mintConfig.presaleMintPrice * _qty, "Need to send more ether");
        require(_numberPresaleMinted(msg.sender) + _qty <= mintConfig.presaleMintPerWallet, "Reached minting limit per wallet");
        _increasePresaleMinted(msg.sender, _qty);
        _mint(msg.sender, _qty);
    }

    function publicMint(uint256 _qty) 
        external 
        payable 
        callerIsWallet 
        checkMintQuantity(_qty) 
        isPublicMintActive
    {        
        require(msg.value >= mintConfig.publicMintPrice * _qty, "Need to send more ether");
        require(_numberPublicMinted(msg.sender) + _qty <= mintConfig.publicMintPerWallet, "Reached minting limit per wallet");
        _increasePublicMinted(msg.sender, _qty);
        _mint(msg.sender, _qty);
    }

    // count NFT token minted by any owner even the owner may have transferred to other already
    function numberMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }

    // reduce collection MAX SUPPLY to decrease collection size
    function reduceMaxSupply(uint256 _amount) external onlyAdmin {
        require(totalSupply() <= (MAX_SUPPLY - burnedSupply), "Burn amount too much");
        unchecked {
            burnedSupply += _amount;
        }
    }

    // ======== Unreveal/Reveal token URI functions =========
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string calldata _uri) external onlyAdmin {
        baseTokenURI = _uri;
    }

    function setUnrevealURI(string calldata _uri) external onlyAdmin {
        unrevealURI = _uri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? 
            string(abi.encodePacked(baseURI, _toString(_tokenId))) : 
            string(abi.encodePacked(unrevealURI, _toString(_tokenId)));
    }

    // ======== Extra functions =========
    // Token ownership data {address addr, uint64 startTimestamp}
    function ownershipOf(uint256 _tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(_tokenId);
    }

    // Address data for owner
    function addressDataOf(address _owner) external view returns (AddressData memory) {
        return _addressDataOf(_owner);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 index;

        unchecked {
           uint256 total = _totalMinted();
           for (uint256 i = 1; i <= total; i++) {
                if (_owner == ownerOf(i)) {
                    tokenIds[index] = i;
                    index++;
                }
           }
        }
        return tokenIds;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        uint256 balance = balanceOf(_owner);
        require(_index < balance, "Invalid token index");

        uint256 index;
        uint256 tokenId;
        unchecked {
            uint256 total = _totalMinted();
            for (uint256 i = 1; i <= total; i++) {
                  if (_owner == ownerOf(i)) {
                      if (index == _index) {
                          tokenId = i;
                          break;
                      }
                      index++;
                  }
            }
        }
        return tokenId;
    }
    
    // ======== Withdraw =========
    function withdraw(address payable _to) public onlyAdmin {
        // Call returns a boolean value indicating success or failure.
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev Returns whether an address is external NFT owner
     */
    function _isExternalTokenOwner(address _contract, address _ownerAddress) internal view returns (bool) {
        try IBalanceOf(_contract).balanceOf(_ownerAddress) returns (uint256 balance) {
            return balance > 0;
        } catch (bytes memory) {
          // when reverted, just returns...
          return false;
        }
    }
}