// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "./library/Mintable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/IERC721.sol";


/**
 * @title Airdrops
 * @dev Extends ERC1155 , ERC1155Supply, ERC1155Burnable, ERC1155Pausable
 * @author @FrankNFT.eth
 */

contract Airdrops is ERC1155Supply, ERC1155Burnable, Mintable {

    mapping(uint256 => string) private tokenUri;
    mapping(uint256 => bool) private saleIsActive;
    mapping(uint256 => mapping(uint256 => bool)) tokenUsed;

    IERC721 leaderContract;
    
    string constant private _name="Kiki Exchange Center";
    string constant private _symbol="KEC";

    constructor() ERC1155("ipfs://") {
        leaderContract = IERC721(0x2f5524b0973aEA012F9Afa0DF87d3b5BBA21130E);
    }

    /**
    *  @dev set contract 
    */
    function setContract(address token) external onlyOwner {
        leaderContract = IERC721(token);
    }

    /**
    *  @dev mint a reserve
    */
    function mintReserve(uint256 token, uint256 amount) external onlyMinter {
        _mint(msg.sender, token, amount, "");
    }
    
    /**
     * @dev airdrop a specific token to a list of addresses
     */
    function airdrop(address[] calldata addresses, uint256 token, uint amt_each) external onlyMinter {
        uint length = addresses.length;
        for (uint i=0; i < length;) {
            _mint(addresses[i], token, amt_each, "");
            unchecked{ i++;}
        }
    }

    /**
    * @dev allows to mint a tokens to the wallet of the msg.sender if he holds OneOnes
    */
    function mint(uint256 token, uint[] calldata tokenIds) external{
        require(saleIsActive[token],"Sale NOT active");
        uint length = tokenIds.length;
        require(length != 0, "numberOfNfts cannot be 0");
        uint amount;
        for (uint i=0; i < length;) {
            if (!tokenUsed[token][tokenIds[i]] && leaderContract.ownerOf(tokenIds[i])==msg.sender){ 
                tokenUsed[token][tokenIds[i]]=true;
                unchecked{ amount++;}
            }
            unchecked{ i++;}
        }
        require(amount != 0, "no Valid id's");
        _mint(msg.sender, token, amount, "");
    }

    /**
     * Pause sale if active, make active if paused for a specific token
     */
    function flipSaleState(uint256 token) external onlyOwner {
        saleIsActive[token] = !saleIsActive[token];
    }

    function isSaleActive(uint256 token) external view returns(bool){
        return saleIsActive[token];
    }

   function oneOneUsed(uint256 oneOnetoken, uint256 token) external view returns(bool){
        return tokenUsed[token][oneOnetoken];
    }

    /**
    *  @dev set token base uri
    */
    function setURI(string memory baseURI) public onlyOwner {
        _setURI(baseURI);
    }
    
    /**
    *  @dev set token hash
    */
    function setTokenURI(uint256 token, string memory tokenURI) public onlyMinter {
        tokenUri[token]=tokenURI;
    }    
    
    /**
     * @dev removing the token substituion and replacing it with the implementation of the ERC721
     */
    function uri(uint256 token) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(token);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenUri[token])) : "";
    }
    
    ///////////// Add name and symbol for etherscan /////////////////
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

   ///////////// Overwrites /////////////
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}