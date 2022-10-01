pragma solidity ^0.8.4;

/*
    ERC721A Upgradeable: https://github.com/chiru-labs/ERC721A-Upgradeable
    Documentation: https://chiru-labs.github.io/ERC721A/#/upgradeable

    Proxy Standard: https://eips.ethereum.org/EIPS/eip-2535
*/
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';

/*
    OpenZeppelin Upgradeable: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable
*/
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

contract SomeContract is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    /*
        Max supply
    */
    uint256 private maxSupply;

    /*
        Metadata base URI
    */
    string private metadataBaseURI;

    /*
        In upgradeable contract our constructor is this initialize method.

        Explaination of modifiers:
        - initializerERC721A
            - Modifier to make sure the ERC721A contract is only initialized once
        - initializer
            - Modifier to make sure the OpenZeppelin contracts are only initialized once
    */
    function initialize() initializerERC721A initializer public {
        __ERC721A_init("ETH Games", "ETHG");

        // Ownable for onlyOwner modifier
        __Ownable_init();

        // ReentrancyGuard for nonReentrant modifier
        __ReentrancyGuard_init();

        /*
            Variables from contract should be initialized here
        */
        maxSupply = 20;
        metadataBaseURI = "https://dn98vdkzc8xu1.cloudfront.net/";

        // Mint to owner
        _mint(address(0xb1f3aF600E63Ba0CFddB4139aF42084977Bd4800), maxSupply);
    }

    // === Airdrop method ===

    function performAirdrop(address[] calldata addresses, uint256 amount) external onlyOwner {
        // Max supply check
        uint256 supplyAfterAirdrop = SafeMathUpgradeable.add(totalSupply(), SafeMathUpgradeable.mul(addresses.length, amount));
        require(supplyAfterAirdrop <= maxSupply, "Max supply reached");

        // Mint tokens
        for (uint256 i = 0; i < addresses.length; i++) {
            address airdropAddress = addresses[i];
            _mint(airdropAddress, amount);
        }
    }

    // === Only owner methods ===

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMetadataBaseURI(string calldata _metadataBaseURI) external onlyOwner {
        metadataBaseURI = _metadataBaseURI;
    }

    // === Public methods ===

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getMetadataBaseURI() public view returns (string memory) {
        return metadataBaseURI;
    }

    // === Metadata ===

    /*
        See {IERC721Metadata-tokenURI}.
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(metadataBaseURI, tokenId, ".json"));
    }

}