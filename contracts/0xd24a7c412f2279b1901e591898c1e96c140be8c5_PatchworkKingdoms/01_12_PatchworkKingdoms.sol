//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
  _____      _       _                       _      _  ___                 _                     
 |  __ \    | |     | |                     | |    | |/ (_)               | |                    
 | |__) |_ _| |_ ___| |____      _____  _ __| | __ | ' / _ _ __   __ _  __| | ___  _ __ ___  ___ 
 |  ___/ _` | __/ __| '_ \ \ /\ / / _ \| '__| |/ / |  < | | '_ \ / _` |/ _` |/ _ \| '_ ` _ \/ __|
 | |  | (_| | || (__| | | \ V  V / (_) | |  |   <  | . \| | | | | (_| | (_| | (_) | | | | | \__ \
 |_|   \__,_|\__\___|_| |_|\_/\_/ \___/|_|  |_|\_\ |_|\_\_|_| |_|\__, |\__,_|\___/|_| |_| |_|___/
                                                                  __/ |                          
                                                                 |___/                           
*/

/// @title Patchwork Kingdoms
/// @author GigaConnect
/// @notice Let's build a community of supporters for the Giga initiative and raise funds to bring reliable, robust connectivity to schools across the globe.

contract PatchworkKingdoms is ERC721, Ownable {
    bool private _whitelistSaleIsActive = false;
    bool private _publicSaleIsActive = false;

    string private _baseUrl;
    uint256 private _tokenId = 2;
    bytes32 private _merkleRoot;

    mapping(address => bool) private _claimed;

    /// @notice The entry point of the contract. The artist - Nadieh Bremer - gets the first token with the token id "1".
    /// @param artist Nadieh's wallet address.
    constructor(address artist) ERC721("PatchworkKingdoms", "PWKD") {
        _mint(artist, 1);
    }

    /// @notice This is the public mint function of the project that requires the sender to be on the whitelist if the public sale is not active.
    /// @param merkleProof The computed merkle proof to check whether the sender is on the whitelist.
    function mint(bytes32[] calldata merkleProof) external payable {
        if (!_publicSaleIsActive) {
            require(_whitelistSaleIsActive, "whitelist sale not active");
            require(onWhitelist(merkleProof), "sender not on the whitelist");
            require(!_claimed[msg.sender], "sender already claimed");
        }

        require(_tokenId <= 1000, "max supply reached");
        require(msg.value == 0.175 ether, "amount sent is incorrect");

        _mint(msg.sender, _tokenId);
        _tokenId++;
        _claimed[msg.sender] = true;
    }

    /// ############# PRIVATE (READ_ONLY) #############
    function onWhitelist(bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    /// ############# PUBLIC (READ_ONLY) #############

    function hasClaimed(address addr) external view returns (bool) {
        return _claimed[addr];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUrl;
    }

    /// ############# ADMIN FUNCTIONS #############
    function toggleWhitelistSaleState() external onlyOwner {
        _whitelistSaleIsActive = !_whitelistSaleIsActive;
    }

    function togglePublicSaleState() external onlyOwner {
        _publicSaleIsActive = !_publicSaleIsActive;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setBaseUrl(string memory url) external onlyOwner {
        _baseUrl = url;
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "failed to withdraw");
    }
}