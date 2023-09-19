/*
 /$$$$$$$$                     /$$$$$$$$                                          /$$          
| $$_____/                    | $$_____/                                         |__/          
| $$        /$$$$$$   /$$$$$$$| $$     /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$      /$$  /$$$$$$ 
| $$$$$    /$$__  $$ /$$_____/| $$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$    | $$ /$$__  $$
| $$__/   | $$  \__/| $$      | $$__/| $$  \ $$| $$  \__/| $$  \ $$| $$$$$$$$    | $$| $$  \ $$
| $$      | $$      | $$      | $$   | $$  | $$| $$      | $$  | $$| $$_____/    | $$| $$  | $$
| $$$$$$$$| $$      |  $$$$$$$| $$   |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$ /$$| $$|  $$$$$$/
|________/|__/       \_______/|__/    \______/ |__/       \____  $$ \_______/|__/|__/ \______/ 
                                                          /$$  \ $$                            
                                                         |  $$$$$$/                            
                                                          \______/                             
*/
//SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ErcForgeNftCore.sol";
import "../interface/IErcForgeERC721Mintable.sol";
import "../interface/IErcForgeInitiable.sol";

contract ErcForge721Template is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    ErcForgeNftCore,
    IErcForgeInitiable
{
    string public _name;
    string public _symbol;
    string public contractURI;
    string private _baseTokenURI;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public maxSupply;
    uint256 public price;

    constructor() ERC721("", "") {}

    function init(
        address newOwner,
        string memory newName,
        string memory newSymbol,
        string memory newBaseTokenURI,
        string memory newContractURI,
        address royaltyReceiver,
        uint96 royaltyFee
    ) public {
        _init(newOwner, royaltyReceiver, royaltyFee);
        _name = newName;
        _symbol = newSymbol;
        _baseTokenURI = newBaseTokenURI;
        contractURI = newContractURI;
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setBaseURI(string memory newURI) public onlyAdmin {
        _baseTokenURI = newURI;
    }

    function setContractURI(string memory newURI) public onlyAdmin {
        contractURI = newURI;
    }

    function setTokenPriceAndSupply(
        uint256 _price,
        uint256 _maxSupply
    ) public onlyAdmin {
        price = _price;
        maxSupply = _maxSupply;
    }

    function mint(address to) external payable {
        if (_tokenIdTracker.current() > maxSupply) {
            revert NoSupply();
        }
        if (msg.value < price) {
            revert NotEnoughFunds();
        }

        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function airdrop(address[] calldata to) external onlyAdmin {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public onlyAdmin {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev OperatorFilter
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}