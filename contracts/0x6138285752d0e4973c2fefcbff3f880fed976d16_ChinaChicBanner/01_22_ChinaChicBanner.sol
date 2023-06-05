// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ChinaChicProof.sol";

// File: contracts/ChinaChicBanner.sol

/*
 ██████╗██╗  ██╗██╗███╗   ██╗ █████╗      ██████╗██╗  ██╗██╗ ██████╗
██╔════╝██║  ██║██║████╗  ██║██╔══██╗    ██╔════╝██║  ██║██║██╔════╝
██║     ███████║██║██╔██╗ ██║███████║    ██║     ███████║██║██║     
██║     ██╔══██║██║██║╚██╗██║██╔══██║    ██║     ██╔══██║██║██║     
╚██████╗██║  ██║██║██║ ╚████║██║  ██║    ╚██████╗██║  ██║██║╚██████╗
 ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚═╝ ╚═════╝
*/

contract ChinaChicBanner is
    ERC1155,
    ERC1155Burnable,
    ChinaChicProof,
    Pausable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 2600;

    // State variables
    // ------------------------------------------------------------------------
    string public name;
    string public symbol;
    uint256 public totalSupply;
    Counters.Counter private _tokenIds;
    bool public isClaimOpen = false;

    // Sale mappings and array
    // ------------------------------------------------------------------------
    mapping(string => bool) private nonces;
    mapping(uint256 => bool) private claimed;
    uint256[] private claimedIds;

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyClaimOpen() {
        require(isClaimOpen, "Claim is not open");
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
    }

    // Operational functions
    // ------------------------------------------------------------------------
    function collectReserves(uint256 quantity) external onlyOwner {
        require(totalSupply + quantity <= MAX_SUPPLY, "Exceed max supply");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 id = _tokenIds.current();
            _mint(msg.sender, id, 1, "");
            _tokenIds.increment();
        }
        totalSupply.add(quantity);
    }

    function getClaimed(uint256 tokenId) public view returns (bool) {
        return claimed[tokenId];
    }

    function getClaimedIds() public view returns (uint256[] memory) {
        return claimedIds;
    }

    function flipClaimOpen() public onlyOwner {
        isClaimOpen = !isClaimOpen;
    }

    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    // Claim functions
    // ------------------------------------------------------------------------
    function claim(
        string memory nonce,
        uint256[] calldata tokenIds,
        bytes memory signature
    ) public nonReentrant whenNotPaused onlyClaimOpen onlyEOA {
        require(!nonces[nonce], "Hash reused");

        string memory ids = concat(tokenIds);
        bytes32 digest = hashMessage(_msgSender(), nonce, ids);
        require(matchSigner(digest, signature), "Signature not authenticated");

        nonces[nonce] = true;
        uint256 quantity = tokenIds.length;

        require(totalSupply + quantity <= MAX_SUPPLY, "Exceed max supply");

        uint256 claimable = 0;

        for (uint256 i = 0; i < quantity; i++) {
            if (!claimed[tokenIds[i]]) {
                claimed[tokenIds[i]] = true;
                claimedIds.push(tokenIds[i]);
                claimable += 1;

                uint256 id = _tokenIds.current();
                _mint(msg.sender, id, 1, "");
                _tokenIds.increment();
            }
        }

        require(claimable > 0, "Already Claimed");
        totalSupply.add(claimable);
    }
}