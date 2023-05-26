// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./lib/ERC721A.sol";
import "./lib/MintStageWithReset.sol";
import "./lib/PaymentSplitterConnector.sol";

error TokenSupplyExceeded();
error BatchLengthMismatch();
error NoAvailableFreeClaim();

contract AppreciatorsS2 is
    PaymentSplitterConnector,
    ERC721A,
    Ownable,
    Pausable,
    MintStageWithReset
{
    uint256 public constant TOKEN_SUPPLY_LIMIT = 5555;
    string public baseExtension = ".json";
    string public baseURI = "";

    mapping (address => uint256) public freeClaimList;

    constructor(address splitterAdmin, address splitterAddress)
        ERC721A("Appreciators", "APR")
        PaymentSplitterConnector(splitterAdmin, splitterAddress)
    {}

    function pauseFreeClaim() public onlyOwner {
        _pause();
    }

    function unpauseFreeClaim() public onlyOwner {
        _unpause();
    }

    function batchAirdrop(
        address[] calldata recipients,
        uint256[] calldata quantity
    ) public onlyOwner {
        if (recipients.length != quantity.length) {
            revert BatchLengthMismatch();
        }

        for (uint256 i; i < recipients.length; ++i) {
            if ((_totalMinted() + quantity[i]) > TOKEN_SUPPLY_LIMIT) {
                revert TokenSupplyExceeded();
            }

            _safeMint(recipients[i], quantity[i]);
        }
    }

    function mint(bytes32[] calldata merkleProof, uint256 quantity)
        public
        payable
    {
        _verifyMint(merkleProof, quantity, _totalMinted(), 0);
        _updateWalletMintCount(msg.sender, quantity);
        _safeMint(msg.sender, quantity);
    }

    function freeClaim() public whenNotPaused
    {
        address sender = msg.sender;
        uint256 freeClaimQty = freeClaimList[sender];
        uint256 remainingFree = TOKEN_SUPPLY_LIMIT - _totalMinted();
        uint256 mintAmount = 0;

        if (remainingFree > freeClaimQty) {
            mintAmount = freeClaimQty;
        } else {
            mintAmount = remainingFree;
        }
        if (mintAmount == 0) {
            revert TokenSupplyExceeded();
        }

        if (freeClaimQty == 0) {
            revert NoAvailableFreeClaim();
        }

        freeClaimList[sender] = 0;

        _safeMint(sender, mintAmount);
    }

    function updateFreeClaim(
        address[] calldata recipients,
        uint256[] calldata quantity
    ) public onlyOwner {
        if (recipients.length != quantity.length) {
            revert BatchLengthMismatch();
        }

        for (uint256 i; i < recipients.length; ++i) {
            freeClaimList[recipients[i]] = quantity[i];
        }
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), baseExtension)
                )
                : baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseExtension(string memory extension) public onlyOwner {
        baseExtension = extension;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}