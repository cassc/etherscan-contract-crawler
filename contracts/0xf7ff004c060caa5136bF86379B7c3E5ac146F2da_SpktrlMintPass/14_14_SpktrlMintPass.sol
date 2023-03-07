//SPDX-License-Identifier: Unlicense

/*
:'######::'########::'##:::'##:'########:'########::'##:::::::
'##... ##: ##.... ##: ##::'##::... ##..:: ##.... ##: ##:::::::
 ##:::..:: ##:::: ##: ##:'##:::::: ##:::: ##:::: ##: ##:::::::
. ######:: ########:: #####::::::: ##:::: ########:: ##:::::::
:..... ##: ##.....::: ##. ##:::::: ##:::: ##.. ##::: ##:::::::
'##::: ##: ##:::::::: ##:. ##::::: ##:::: ##::. ##:: ##:::::::
. ######:: ##:::::::: ##::. ##:::: ##:::: ##:::. ##: ########:
:......:::..:::::::::..::::..:::::..:::::..:::::..::........::
'##::::'##:'####:'##::: ##:'########:                         
 ###::'###:. ##:: ###:: ##:... ##..::                         
 ####'####:: ##:: ####: ##:::: ##::::                         
 ## ### ##:: ##:: ## ## ##:::: ##::::                         
 ##. #: ##:: ##:: ##. ####:::: ##::::                         
 ##:.:: ##:: ##:: ##:. ###:::: ##::::                         
 ##:::: ##:'####: ##::. ##:::: ##::::                         
..:::::..::....::..::::..:::::..:::::                         
'########:::::'###:::::'######:::'######::                    
 ##.... ##:::'## ##:::'##... ##:'##... ##:                    
 ##:::: ##::'##:. ##:: ##:::..:: ##:::..::                    
 ########::'##:::. ##:. ######::. ######::                    
 ##.....::: #########::..... ##::..... ##:                    
 ##:::::::: ##.... ##:'##::: ##:'##::: ##:                    
 ##:::::::: ##:::: ##:. ######::. ######::                    
..:::::::::..:::::..:::......::::......:::                                      
*/

/// Metaheads | SPKTRL Mint Pass
/// Creators: @Alts_Anonymous, @ethalorian, @Xelaversed, @aurealarcon
/// Contrtact by: @aurealarcon aurelianoa.eth 

pragma solidity ^0.8.17;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract SpktrlMintPass is ERC1155, ERC1155Burnable, Ownable {

    using ECDSA for bytes32;

    string private _contractURI = "";
    uint256 private maxPerWallet = 10;

    /// @dev token info
    struct Token {
        string uri;
        bool mint;
    }

    /// @dev allowList mapping(address => minted)
    mapping (address => uint256) private walletsMinted;
    /// @dev info for each token
    mapping (uint256 => Token) private tokens;

    ///events
    event ContractURIUpdated(address indexed _account);
    event TokenInfoUpdated(uint256 _tokenId);
    event TokenMintStateUpdated(uint256 _tokenId, bool _active);

    constructor() 
        ERC1155("") 
    {}

    ///ADMINISTRATIVE TOOLS

    /// @dev set the token Info
    /// @param tokenId uint256
    /// @param _uri string
    function setTokenInfo(uint256 tokenId, string calldata _uri) external onlyOwner {

        Token memory token = Token(
            _uri,
            false
        );

        tokens[tokenId] = token;

        emit TokenInfoUpdated(tokenId);
    }


    /// @dev set Mint State
    /// @param active bool
    /// @param tokenId uint256
    function setMintState(uint256 tokenId, bool active) external onlyOwner {
        tokens[tokenId].mint = active;

        emit TokenMintStateUpdated(tokenId, active);
    }

    ///  @dev Airdrop function
    ///  @param owners address[]
    ///  @param tokenIds uint256[]
    ///  @param amount uint256[]
    function airdropTokens(address[] calldata owners, uint256[] calldata tokenIds, uint256[] calldata amount) external onlyOwner {
        require(owners.length > 0, "onwers cant be 0");
        require(owners.length == tokenIds.length && owners.length == amount.length);

        uint256 i = 0;
        do {
            require(tokens[tokenIds[i]].mint, "Mint is not active");
            require(owners[i] != address(0), "address cant be 0");
            
            _mint(owners[i], tokenIds[i], amount[i], "");

            unchecked { ++i; }
        } while(i < tokenIds.length);
    }

    /// @dev Public Mint
    /// @param tokenId uint256
    /// @param amount uint256
    function publicMint(uint256 tokenId, uint256 amount) external {
        require(tokens[tokenId].mint, "Mint is not active");
        require(amount <= maxPerWallet - walletsMinted[msg.sender], "Maximum per wallet exceeded");

        walletsMinted[msg.sender] += amount;

        _mint(msg.sender, tokenId, amount, "");
    }

    /// @dev set the uri metadata by tokenId
    /// @param _uri string
    function setTokenURI(uint256 tokenId, string memory _uri) external onlyOwner {
        tokens[tokenId].uri = _uri;

        emit TokenInfoUpdated(tokenId);
    }

    /// URI metadata by tokenId
    /// @param tokenId uint256
    /// @return string
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return tokens[tokenId].uri;
    }

    /// @dev set contract Metadata
    /// @param newContractURI string
    function setContractURI(string calldata newContractURI) external onlyOwner {
        _contractURI = newContractURI;

        emit ContractURIUpdated(msg.sender);
    }

    /// @dev get contract meta data
    /// @return string
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// Helpers

    /// @dev get minted per wallet
    /// @param wallet address
    /// @return uint256
    function getMintedPerWallet(address wallet) external view returns (uint256) {
        return walletsMinted[wallet];
    }

    /// @dev get max per wallet
    /// @return uint256
    function getMaxPerWallet() external view returns (uint256) {
        return maxPerWallet;
    }

    /// @dev set max per wallet
    /// @param _maxPerWallet uint256
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /// @dev get remaining to mint per wallet
    /// @param wallet address
    /// @return uint256
    function getRemainingToMintPerWallet(address wallet) external view returns (uint256) {
        return maxPerWallet - walletsMinted[wallet];
    }

    /// @dev get token mint state
    /// @param tokenId uint256
    /// @return bool
    function getTokenMintState(uint256 tokenId) external view returns (bool) {
        return tokens[tokenId].mint;
    }

}