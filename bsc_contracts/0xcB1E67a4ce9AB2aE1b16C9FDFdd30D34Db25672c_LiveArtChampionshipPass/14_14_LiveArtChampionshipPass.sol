// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract LiveArtChampionshipPass is ERC721Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 public constant MAX_SUPPLY = 50_000;
    CountersUpgradeable.Counter private _tokenIdTracker;
    string public baseURI;
    address public operator;

    error NotOperator();
    error MaxSupply();
    error NonExistentTokenURI();

    event MintPass(address indexed to, uint256 indexed id);

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        _;
    }

    function initialize(string memory _baseURI, address _operator) public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC721_init_unchained("LiveArt Championship Pass", "CPass");
        baseURI = _baseURI;
        operator = _operator;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function setBaseURI(string memory _baseURI) public onlyOperator {
        baseURI = _baseURI;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdTracker.current();
    }

    function mintTo(address recipient) public onlyOperator {
        _tokenIdTracker.increment();
        uint id = _tokenIdTracker.current();
        if (id > MAX_SUPPLY) {
            revert MaxSupply();
        }
        _mint(recipient, id);
        emit MintPass(recipient, id);
    }

    function batchMintTo(address[] calldata recipients) public onlyOperator {
        for (uint256 i = 0; i < recipients.length; i++) {
            mintTo(recipients[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function pause() external onlyOperator {
        super._pause();
    }

    function unpause() external onlyOperator {
        super._unpause();
    }
}