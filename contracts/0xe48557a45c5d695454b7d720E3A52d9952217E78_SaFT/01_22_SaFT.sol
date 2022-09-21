//SPDX-License-Identifier: MIT

//                         ███████╗ █████╗ ███████╗██╗   ██╗
//                         ██╔════╝██╔══██╗██╔════╝██║   ██║
//                         ███████╗███████║█████╗  ██║   ██║
//                         ╚════██║██╔══██║██╔══╝  ██║   ██║
//                         ███████║██║  ██║██║     ╚██████╔╝
//                         ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ 
//                            /~______________________~\
//                            .------------------------.
//                            (|https://safuchain.live|)
//                            '------------------------'
//                            \_~~~~~~~~~~~~~~~~~~~~~~_/

pragma solidity ^0.8.7;

import { Ownable } from './Ownable.sol';
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ERC721BurningERC20OnMint.sol";

contract SaFT is ERC721BurningERC20OnMint, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public MAX_SUPPLY = 1000;
    string private _baseURIBackingField;
    string private _contractURIBackingField;


    constructor() ERC721("SafuChain SaFTs", "SaFT") {
        _baseURIBackingField = "ipfs://QmS31KcduBjXpBxnPrbNdZbDVLYkee692hLQht7Qc9hwxn/";
        _contractURIBackingField = "ipfs://QmVMcMUyL6WM64yAifN6tEmRytr5MZCGT6QKXNdUAaNzQZ";
    }

    function mint() public nonReentrant override returns (uint256) {
        require(totalSupply() < MAX_SUPPLY, 'Fully minted out.');
        uint256 tokenId = _tokenIds.current();
        _mint(address(this), _msgSender(), tokenId);
        _tokenIds.increment();
        return tokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIBackingField;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        _baseURIBackingField = newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURIBackingField;
    }

    function setContractURI(string memory newURI) external onlyOwner() {
        _contractURIBackingField = newURI;
    }
}