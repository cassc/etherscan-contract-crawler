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
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';

contract SomeContract is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    /*
        Max supply
    */
    uint256 public constant MAX_SUPPLY = 502;

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
        __ERC721A_init("KARTAL CLUB MemberPass", "KARTMEB");

        // Ownable for onlyOwner modifier
        __Ownable_init();

        // ReentrancyGuard for nonReentrant modifier
        __ReentrancyGuard_init();

        /*
            Variables from contract should be initialized here
        */
        metadataBaseURI = "https://dizg9hyp01a3f.cloudfront.net/";
    }

    // === Airdrop method ===

    function performAirdrop(address[] calldata addresses, uint256 amount) external onlyOwner {
        // Check max supply
        require(SafeMathUpgradeable.add(totalSupply(), SafeMathUpgradeable.mul(addresses.length, amount)) <= MAX_SUPPLY, "Max supply reached");

        // Mint tokens
        for (uint256 i = 0; i < addresses.length;) {
            address airdropAddress = addresses[i];
            _mint(airdropAddress, amount);

            unchecked {
                i++;
            }
        }
    }

    // === Only owner methods ===

    function setMetadataBaseURI(string calldata _metadataBaseURI) external onlyOwner {
        metadataBaseURI = _metadataBaseURI;
    }

    // === Public methods ===

    function getMetadataBaseURI() public view returns (string memory) {
        return metadataBaseURI;
    }

    // === Metadata ===

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(metadataBaseURI, StringsUpgradeable.toString(tokenId), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(metadataBaseURI, "contract.json"));
    }

}