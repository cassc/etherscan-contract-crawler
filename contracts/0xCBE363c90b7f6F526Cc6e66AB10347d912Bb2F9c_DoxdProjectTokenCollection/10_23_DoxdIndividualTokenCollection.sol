// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*

            d$$//                                       d$$//
            $$$||                                       $$$||
           $$$$||                                      $$$$||
   d$$$$$$$$$$|/ d$$$$$$$$$$\\ d$$||    d$$$||d$$$$$$$$$$|/
  $$$$//    /$||$$$$//    /$||q$$$$$$$$$$$$p/$$$$$//   /$||
  $$$//    /$|| $$$//    /$$|| e$$$$$$$$$e/  $$$$//   /$$||
 /$$//    /$$|/$$$//    /$$||d$$$||    $$$$||$$$//   /$$$||
 `$$$$$$$$$$/  `$$$$$$$$$$$/.$$$$'     $$$/'`.$$$$$$$$$$/'

*/
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/// @custom:security-contact [email protected]
contract DoxdIndividualTokenCollection is Initializable, ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC721BurnableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    string public CONTRACT_METADATA_URI;
    string public COLLECTION_BASE_URI;
    address public PROJECT_CONTRACT_ADDRESS;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    event TokensMintedForProject(uint projectTokenId, uint256 tokensStartingId, uint256 tokensCreated);

    function initialize(address _projectContractAddress) public initializer {
        __ERC721_init("doxd: Individual", "DOXD-I");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        CONTRACT_METADATA_URI = "https://us-central1-doxd-thenftysetup.cloudfunctions.net/individual-contract-metadata";
        COLLECTION_BASE_URI = "https://us-central1-doxd-thenftysetup.cloudfunctions.net/individual-token-metadata/";
        PROJECT_CONTRACT_ADDRESS = _projectContractAddress;
    }

    modifier onlyProjectContractCallable {
        require(PROJECT_CONTRACT_ADDRESS != address(0), "Invalid Project Address");
        require(msg.sender == PROJECT_CONTRACT_ADDRESS, "Invalid Operation");
        _;
    }

    function setProjectContractAddress(address _projectContractAddress)
        public
        onlyOwner
    {
        require(_projectContractAddress != address(0), "Invalid Project Address");
        PROJECT_CONTRACT_ADDRESS = _projectContractAddress;
    }

    function setURIs(string memory _contractUri, string memory _collectionUri) public onlyOwner {
        CONTRACT_METADATA_URI = _contractUri;
        COLLECTION_BASE_URI = _collectionUri;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_METADATA_URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return COLLECTION_BASE_URI; // Token Id is appended: string(abi.encodePacked(baseURI, tokenId.toString()))
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint _projectTokenId, address[] calldata _addresses)
        external
        whenNotPaused
        onlyProjectContractCallable
        nonReentrant
    {
        uint256 startingId = _tokenIdCounter.current();
        uint256 addedCount = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            // Ensure the destination address does not have a token already
            if (balanceOf(_addresses[i]) == 0) {
                _safeMint(_addresses[i], startingId + addedCount);
                addedCount++;
                _tokenIdCounter.increment();
            }
        }
        emit TokensMintedForProject(_projectTokenId, startingId, addedCount);
    }

    function burnEverything()
        external
        onlyProjectContractCallable
    {
        uint256 currentTokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < currentTokenId; i++) {
            _burn(i);
        }
        _tokenIdCounter.reset();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override
        whenNotPaused
    {
        require(from == address(0) || to == address(0), "doxd tokens cannot be sold or transferred");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        revert("doxd tokens cannot be sold or transferred");
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("doxd tokens cannot be sold or transferred");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract DoxdIndividualTokenCollectionUpgradeTest is DoxdIndividualTokenCollection {
    function test() public pure returns (bool isTestContract) {
        return true;
    }
}