//SPDX-License-Identifier: Unlicense

/**
'##::::'##:'########:'########::::'###::::'##::::'##:'########::::'###::::'########:::'######::
 ###::'###: ##.....::... ##..::::'## ##::: ##:::: ##: ##.....::::'## ##::: ##.... ##:'##... ##:
 ####'####: ##:::::::::: ##:::::'##:. ##:: ##:::: ##: ##::::::::'##:. ##:: ##:::: ##: ##:::..::
 ## ### ##: ######:::::: ##::::'##:::. ##: #########: ######:::'##:::. ##: ##:::: ##:. ######::
 ##. #: ##: ##...::::::: ##:::: #########: ##.... ##: ##...:::: #########: ##:::: ##::..... ##:
 ##:.:: ##: ##:::::::::: ##:::: ##.... ##: ##:::: ##: ##::::::: ##.... ##: ##:::: ##:'##::: ##:
 ##:::: ##: ########:::: ##:::: ##:::: ##: ##:::: ##: ########: ##:::: ##: ########::. ######::
..:::::..::........:::::..:::::..:::::..::..:::::..::........::..:::::..::........::::......:::
:'######:::'########:'##::: ##:'########::'######::'####::'######::                            
'##... ##:: ##.....:: ###:: ##: ##.....::'##... ##:. ##::'##... ##:                            
 ##:::..::: ##::::::: ####: ##: ##::::::: ##:::..::: ##:: ##:::..::                            
 ##::'####: ######::: ## ## ##: ######:::. ######::: ##::. ######::                            
 ##::: ##:: ##...:::: ##. ####: ##...:::::..... ##:: ##:::..... ##:                            
 ##::: ##:: ##::::::: ##:. ###: ##:::::::'##::: ##:: ##::'##::: ##:                            
. ######::: ########: ##::. ##: ########:. ######::'####:. ######::                            
:......::::........::..::::..::........:::......:::....:::......:::

@title Metaheads | GENESIS
@author: @Alts_Anonymous, @ethalorian, @Xelaversed, @aurealarcon
@dev Contrtact by: @aurealarcon aurelianoa.eth                             
*/

pragma solidity 0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { MetadataUpdatable } from "@aurelianoa/metadataupdatable/contracts/MetadataUpdatable.sol";

contract MetaheadsGenesis is 
    ERC721AQueryable, 
    Ownable, 
    ReentrancyGuard,
    MetadataUpdatable {
        using ECDSA for bytes32;

    bool private isMintOpen = false;
    uint256 public price = 0.10725 ether;
    uint256 private teamMax = 12;
    address private mintPass = 0x0000000000000000000000000000000000000000;

    constructor(
        string memory name,
        string memory symbol
        ) 
        ERC721A(name, symbol)
    {}

    /// Mint multiple ERC721 tokens
    /// @param _to address of the future owner of the token
    /// @param _amount number of tokens to mint
    /// @param _variant variant of the token
    function mint(address _to, uint256 _amount, string memory _variant) internal {
        require(_to != address(0), "Cannot mint to 0 address");
        require(_to != address(this), "Cannot mint to contract address");
        
        uint256 i = 0;
        uint256 tokenId = totalSupply() + 1;
        do {
            require(isValidVariant(_variant),"No valid variant provided");
            _mint(_to, 1);
            _setSelectedVariant(tokenId + i, _variant);
            unchecked { ++i; }
        } while (i < _amount);
    }

    /// TeamMint multiple ERC721 tokens
    /// @param _amount number of tokens to mint
    /// @param _variant variant of the token
    function teamMint(uint256 _amount, string memory _variant) external onlyOwner {
        require(_amount <= teamMax, "Cannot mint more than 12 tokens at once");
        
        mint(msg.sender, _amount, _variant);
    }

    /// Airdrop tokens to a list of addresses
    /// @param _to address of the future owner of the token
    /// @param _amount number of tokens to mint
    /// @param _variant variant of the token
    function airdrop(address[] memory _to, uint256 _amount, string memory _variant) external onlyOwner {
        uint256 i = 0;
        do {
            mint(_to[i], _amount, _variant);
            unchecked { ++i; }
        } while (i < _to.length);
    }

    /// mint with burning a ERC1155 token as a pass
    /// @param _amount number of tokens to mint
    /// @param _passId id of the ERC1155 token to burn
    /// @param _variant variant of the token
    function mintWithPass(uint256 _amount, uint256 _passId, string memory _variant) external payable nonReentrant {
        require(isMintOpen, "Mint is not open");
        require(_amount > 0, "Amount must be greater than 0");
        require(msg.value == price * _amount, "wrong ETH sent");
        /// check if _to owns a ERC1155 token with id _passId from the collection mintPass and burn it
        require(mintPass != address(0), "Mint Pass not set");
        ERC1155Burnable mintPasstoken = ERC1155Burnable(mintPass);
        uint256 mintPassBalance = mintPasstoken.balanceOf(msg.sender, _passId);
        require(mintPassBalance >= _amount, "ERC1155 token balance too low" );
 
        mintPasstoken.burn(msg.sender, _passId, _amount);

        mint(msg.sender, _amount, _variant);
    }

    /// Administrative functions

    /// Set the price of the token
    /// @param _price new price of the token
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /// Set the max number of tokens that can be minted at once by the team
    /// @param _teamMax new max number of tokens that can be minted at once by the team
    function setTeamMax(uint256 _teamMax) external onlyOwner {
        teamMax = _teamMax;
    }

    /// Set the address of the ERC1155 token that will be used as a pass
    /// @param _mintPass address of the ERC1155 token that will be used as a pass
    function setMintPass(address _mintPass) external onlyOwner {
        require(_mintPass != address(0), "Cannot set mint pass to 0 address");
        mintPass = _mintPass;
    }

    /// Set the state of the mint
    /// @param _isMintOpen new state of the mint
    function setIsMintOpen(bool _isMintOpen) external onlyOwner {
        isMintOpen = _isMintOpen;
    }

    /// Update variant
    /// @notice the holder can update the variant metadata of the given token
    /// @param tokenId uint256
    /// @param variant string
    function updateVariant(uint256 tokenId, string memory variant) external payable {
        require(isMetadataRevealed(), "Metadata not revealed yet");
        require(ownerOf(tokenId) == msg.sender, "you dont own this token");
        require(msg.value == getVariantPrice(variant), "wrong ETH Sent");
        _setSelectedVariant(tokenId,  variant);
    }

    /// get tokenMetadata
    /// @notice it will use the MetadataUpdatable
    /// @param tokenId uint256
    /// @return string
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return getTokenURI(tokenId);
    }

    /// withdraw funds from the contract
    /// @param _to address
    function withdraw(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /// Helper functions

    /// is the mint open
    /// @return bool
    function getIsMintOpen() external view returns (bool) {
        return isMintOpen;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

}