//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";   

/// @title SixthRéseau - MysteryBox Contract
/// @author SphericonIO
contract SixthReseauColorizer is ERC1155, Ownable, ERC1155Burnable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    string public name = "SixthReseau: Colorizer";
    string public symbol = "SRCL";

    string public tokenUri;

    bool migrationActive = false;

    mapping (uint=>bool) claimedTokens;
    mapping(address => EnumerableSet.UintSet) claimedTokensByAdress;

    constructor(string memory _tokenURI) ERC1155("") {
        tokenUri = _tokenURI;
    }
    
    function mint(address _to, uint _amount) public onlyOwner {
        _mint(_to, 1, _amount, "");
    }

    function migrateToken(uint _colorizedToken) public {
        require(migrationActive, "SixthReseau: Colorizer: Colorizing is not active!");
        require(balanceOf(msg.sender, 1) > 0, "SixthReseau: Colorizer: Account does not have any tokens!");
        require(!claimedTokens[_colorizedToken], "SixthReseau: Colorizer: This token has already been colorized!");
        burn(msg.sender, 1, 1);
        claimedTokens[_colorizedToken] = true;
        claimedTokensByAdress[msg.sender].add(_colorizedToken);
    }

    function setTokenUri(string calldata newUri) public onlyOwner {
        tokenUri = newUri;
    }

    function toggleMigration() public onlyOwner {
        migrationActive = !migrationActive;
    }

    function colorizedByWallet(address _wallet) public view returns (uint[] memory _tokens) {
        uint tokensNumber = claimedTokensByAdress[_wallet].length();
        uint[] memory tokens = new uint[](tokensNumber);

        for(uint i = 0; i < tokensNumber; i++) {
            tokens[i] = claimedTokensByAdress[_wallet].at(i);
        }

        return tokens;
    }

    /// @notice Metadata of each token
    /// @param _tokenId Token id to get metadata of
    /// @return Metadata URI of the token
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(tokenUri, Strings.toString(_tokenId)));
    }
}