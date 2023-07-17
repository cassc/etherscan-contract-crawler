/*
██ ██ ██
░░ ░░ ░░

           ████
          ░░███
 ████████  ░███   ██████   ████████               █████████
░░███░░███ ░███  ░░░░░███ ░░███░░███  ██████████ ░█░░░░███
 ░███ ░███ ░███   ███████  ░███ ░███ ░░░░░░░░░░  ░   ███░
 ░███ ░███ ░███  ███░░███  ░███ ░███               ███░   █
 ░███████  █████░░████████ ████ █████             █████████ ██
 ░███░░░  ░░░░░  ░░░░░░░░ ░░░░ ░░░░░             ░░░░░░░░░ ░░
 ░███
 █████
░░░░░

we want to make things right.
we want closure.
we want to end things the way we would’ve wanted them.

POWER TO THE CREATORS. XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {ERC721Pausable} from "openzeppelin/token/ERC721/extensions/ERC721Pausable.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

/// @title Plan Z
/// @author bayu (github.com/pyk)
/// @author █████████ (github.com/█████████)
/// @notice We just want to make things right, lmeow
contract PlanZ is ERC721, ERC721Pausable, Ownable {
    /// ███ Storages █████████████████████████████████████████████████████████

    // address public immutable ███ = 0x37b7458C5f14822BF423965aed077a20269011C5;

    /// @notice Supply distribution
    uint256 public maxSupply = 888;
    uint256 public maxSummon = 1;

    mapping(address => uint256) private summonedAmount;

    /// @notice Total supply tracker
    uint256 public totalSupply = 0;

    /// @notice Base URI and Contract URI
    string public baseURI;
    string public contractURI;

    /// @notice Custom token URI
    mapping(uint256 => string) internal customURI;

    /// ███ Events ███████████████████████████████████████████████████████████

    event MaxSummonUpdated(uint256 newAmount);
    event CustomURIConfigured(uint256 tokenID, string uri);
    event URIConfigured(string b, string c);

    /// ███ Errors ███████████████████████████████████████████████████████████

    error SummonAmountInvalid(uint256 maxSummon, uint256 got);
    error OutOfStock();

    /// ███ Constructor ██████████████████████████████████████████████████████

    constructor(string memory _baseURI, string memory _contractURI)
        ERC721("plan-z", "ZZZZZZ")
    {
        // Set storages
        baseURI = _baseURI;
        contractURI = _contractURI;

        // Reserve 10 for ███
        for (uint256 i = 0; i < 10; i++) {
            totalSupply++;
            _mint(msg.sender, totalSupply);
        }

        // // Transfer ownership to ███
        // // _transferOwnership(███);
        _pause();
    }

    /// ███ Owner actions ████████████████████████████████████████████████████

    /// @notice Set max summon
    /// @param _amount Max summon amount per addy
    /// @dev Only owner can call this function
    function setMaxSummon(uint256 _amount) external onlyOwner {
        maxSummon = _amount;
        emit MaxSummonUpdated(_amount);
    }

    /// @notice Set the base URI
    /// @param _base The Base URI
    /// @param _contract The Contract URI
    /// @dev Only owner can call this function
    function setURI(string memory _base, string memory _contract)
        external
        onlyOwner
    {
        baseURI = _base;
        contractURI = _contract;
        emit URIConfigured(_base, _contract);
    }

    /// @notice Set the custom token URI
    /// @dev Only owner can call this function
    function invoke(uint256 _tokenId, string memory _uri) external onlyOwner {
        customURI[_tokenId] = _uri;
        emit CustomURIConfigured(_tokenId, _uri);
    }

    /// @notice Pause the contract
    /// @dev Only owner can call this function
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only owner can call this function
    function unpause() external onlyOwner {
        _unpause();
    }

    /// ███ User actions █████████████████████████████████████████████████████

    /// @notice Summon some cool ZZZZZZ
    /// @param _amount The amount of ZZZZZZ
    function summon(uint256 _amount) external payable {
        // Checks
        uint256 samount = summonedAmount[msg.sender];
        if (samount + _amount > maxSummon) {
            revert SummonAmountInvalid({
                maxSummon: maxSummon,
                got: samount + _amount
            });
        }
        if (totalSupply + _amount > maxSupply) revert OutOfStock();

        for (uint256 i = 0; i < _amount; i++) {
            // Effects
            totalSupply++;
            summonedAmount[msg.sender]++;

            // Interaction
            _mint(msg.sender, totalSupply);
        }
    }

    /// ███ Internal functions ███████████████████████████████████████████████

    /// @notice Implement pausable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// ███ External functions ███████████████████████████████████████████████

    /// @notice Returns metadata for each tokenID
    function tokenURI(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (tokenID == 0 || tokenID > totalSupply) return "";
        bytes32 uri = keccak256(abi.encodePacked(customURI[tokenID]));
        if (uri != keccak256(abi.encodePacked(""))) {
            // Custom URI
            return customURI[tokenID];
        } else {
            // Use global URI
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        Strings.toString(tokenID),
                        ".json"
                    )
                );
        }
    }
}