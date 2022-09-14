// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Base.sol";
 
contract ERC721Orderinbox is ERC721Base {
    /// @dev true if collection is private, false if public
    bool isPrivate;

    event CreateERC721Orderinbox(address owner, string name, string symbol);
    event CreateERC721OrderinboxPrivate(address owner, string name, string symbol);

    function __ERC721Orderinbox_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory defaultOperators) external initializer {
        __ERC721Orderinbox_init_unchained(_name, _symbol, baseURI, contractURI, defaultOperators);

        isPrivate = false;
        emit CreateERC721Orderinbox(_msgSender(), _name, _symbol);        
    }

    function __ERC721OrderinboxPrivate_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory defaultOperators, address[] memory operators) external initializer {
        __ERC721Orderinbox_init_unchained(_name, _symbol, baseURI, contractURI, defaultOperators);

        for(uint i = 0; i < operators.length; i++) {
            setApprovalForAll(operators[i], true);
        }

        isPrivate = true;
        emit CreateERC721OrderinboxPrivate(_msgSender(), _name, _symbol);        
    }

    function __ERC721Orderinbox_init_unchained(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory defaultOperators) internal onlyInitializing {
        _setBaseURI(baseURI);
        __ERC721Mint_init_unchained();
        __RoyaltiesUpgradeable_init_unchained();
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721Burnable_init_unchained();
        __ERC721URIStorage_init_unchained();
        __Mint721Validator_init_unchained();
        __HasContractURI_init_unchained(contractURI);
        __ERC721_init_unchained(_name, _symbol);

        //setting default approver for transferProxy
        for(uint i = 0; i < defaultOperators.length; i++) {
            _setDefaultApproval(defaultOperators[i], true);
        }
        
        // Start from 1
        AutoTokenId._increment();
    }

    function mintAndTransfer(Mint721AutoIdData memory data, address to) public virtual {
        if (isPrivate){
            require(owner() == data.creators[0].account, "minter is not the owner");
        }
        _mintAndTransfer(data, to);
    }     

    uint256[255] private __gap;
}