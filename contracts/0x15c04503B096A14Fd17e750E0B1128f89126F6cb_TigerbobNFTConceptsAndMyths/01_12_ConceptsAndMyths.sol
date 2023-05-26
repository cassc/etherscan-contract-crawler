// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Ownable} from'@openzeppelin/contracts/access/Ownable.sol';

import './ERC1155.sol';

/*
 * @title – Tigerbob NFT Concepts & Myths
 * @author – Matthew Wall
 */

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                            ▄▄▄▄▄      ▄                      ▄▄▄           //
//               ▐███▄                      ▐█▓              █████████  ▀██    ▓█▌    ▀█▌     ▐████           //
//            ▄████████▌  ██████▓   ▓█████▓ ▐██  ▀▓▓▌   ▓▓▓▌ ██     ▀▀       ▓█████   ▓███▓   ▐██▀            //
//            ███▀        ██   ▀█▓  ▓█▌     ▐██   ███▌  ██▌  ███▓▓▓▌    ▄▓▌  ██▌▐██▓  ▓████▓  ▐██             //
//           ███▌         ██ ▄▓██▀  ▓██▌▌▌▌▄▐██    ▐▀█▌██▀   ▀▀▀█████▌  ▓██ ██▓▌▓███  ▓█▌ ▀██████             //
//           ███▌  ▄█████ █████▀▀   ▓██▀▀▀▀ ▐██▄▄▄   ▀██▀    ▄    ▐███  ▓██ ██   ▐██▄ ▓█▌   █████▄            //
//            ███▄  ▄██▌  ██ ▀██▄▄  ▓█▌ ▄▄  ▐█████  ▐██▀     ██▄▄▄▓██   ▓██ ██▄    █▀ ▓█▌    ▀████            //
//            ▀███████▌   ██  ▐███  ▓█████▄        ▐██▀       ▀████▀▀        ▀        ▀▀                      //
//              ▐▀▀▀▀     ▀▀                      ▄▓█▀                                                        //
//                                                                                                            //
//                                                                                                            //
//                             ▐████▄                  ████▌                  ████▓                           //
//                 ████▄    ▄▌▓██▀▀▀██▌   ████▌    ▐▌▓██▀▀▀▓█▓   ▐███▓     ▌▌██▌▀▀▀█▓                         //
//                ████████▀▀     ▀  ▐▀▀▌ ████████▀▀     ▀   ▀▀▌ ████████▌▀▀    ▐   ▀▀▌▄                       //
//                ██▀  ▐███ ▀▀▀▀▀▄▄▀▀  ▀▄██▓   ███ ▐▀▀▀▀▄▄▌▀▀ ▀▄███▀  ███▌ ▀▀▀▀▌▄▌▀▀ ▀▌▄                      //
//             ▐▌▀▀▀       ▄▄▄▄▄▄▄  ▄▄▓█▀▀▀       ▄▄▄▄▄▄▄  ▐▄▄█▀▀▀▀      ▐▄▄▄▄▄▄▄  ▄▄▀▀▀▀▄                    //
//           ▄▀▀▄  █   ▐▀▀▀       ▀▀▄▀▀▄  █▄   ▀▀▀       ▀▀▌▄▀▄  ▐▌   ▀▀▀▀      ▐▀▀ ▄▀▀▀▀▀▀▄                  //
//           █ ▐▌  ▀▄▄▄▄    ▀▀▀▀▀   ▓▌▐█  ▀▄▄▄▄    ▐▀▀▀▀   ▐█ █  ▐▌▄▄▄     ▀▀▀▀     ▄▀▀▀▀▀▀▀▀▀▄ ▄             //
//           █  ▐▀▄▄▄ ▄▐▀▀▀▀▀▀▀▀▀▄  ▓▌  ▀▄▄▄▄ ▄▀▀▀▀▀▀▀▀▀▄  ▐█  ▀▄▄▄▄ ▄▀▀▀▀▀▀▀▀▀▄    █ ▀▀▀▀▀▀▀ █▄█             //
//           █▓▀▌▄    ▓▌ ▀▀▀▀▀▀▀ █  ▓█▀▀▄    ▐█ ▀▀▀▀▀▀▀ █  ▐█▀▀▄     █ ▀▀▀▀▀▀▀ █   ▄▀▀▀▀▀▀█▀▀▌▄▓ ▄            //
//            ▀▄ ▐▓▓▓  ▀▀▀▀▀▀▀▀▀▀ ▓  ▀▌  ▓▓▓▄  ▀▀▀▀▀▀▀▀▀ ▀▄ ▐▓  ▀▓▓▌ ▄▀▀▀▀▀▀▀▀▀ ▐▌       ▓  ▓▓▀   █           //
//              ▐▓▓   ▓██▀▓▓        ▄▓██▓▓   ▐██▀▓▓▄       ▐▓▓█▓▓▄   ██▀▀▓▌        ▓▓▓▓▄  ▓ ██▓▓▌▀            //
//                 ▀▀▀▀▐▓▓  █▌   ▓   ▀▀█▀ ▀▀▀▀█▓▓  ▐▌   ▓   ▀▀█▀  ▀▀▀█▓▓▄  █   ▄▄  ▀▀█▌     █▌                //
//                        ▀▄ ▐▀▄   ▀   ▄▀▄▄▀█▌   ▀▄▄ ▀▄   ▐▀  ▄▀▄▄▌▀█   ▀▀▄ ▀▄    ▀  ▄▀▀▄▄▀█                  //
//                          ▀▌▄ ▀▀▄▄▄██▀ ▄▀▌▌▀     ▀▀▄ ▀▀▄▄▄▄█▀ ▄▌▀▄▀      ▀▄ ▀▀▀▄▄▄█▀ ▐▄▀▄▀                  //
//                            ▀▀▀▄█ ▓█▄▄▀             ▀▀▄█▌▐█▄▄▀             ▀▀▄▓▌ █▄▄▀                       //
//                                 ▀                      ▀▀                     ▀▀                           //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract TigerbobNFTConceptsAndMyths is ERC1155Supply, Ownable {
    string public baseTokenURI;

    enum MintStage {
        PAUSED,
        ACTIVE
    }
    MintStage public stage = MintStage.PAUSED;

    uint256 public price = 0 ether;

    uint256 public supply = 351;

    mapping(address => uint256) public minters;

    uint256 public tokenId = 1;

    function setURI(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    constructor(string memory uri) ERC1155(uri) {}

    modifier contractCheck() {
        require(tx.origin == msg.sender, 'beep boop');
        _;
    }

    modifier checkSaleActive() {
        require(MintStage.PAUSED != stage, 'sale not active');
        _;
    }

    modifier checkSupply(uint256 _amount) {
        require(
            totalSupply(tokenId) + _amount <= supply,
            'exceeds total supply for token'
        );
        _;
    }

    modifier checkTxnValue() {
        require(msg.value == price, 'invalid transaction value');
        _;
    }

    modifier checkAlreadyMinted() {
        uint256 minter = minters[msg.sender];
        require(minter != tokenId, 'already minted this drop');
        minters[msg.sender] = tokenId;
        _;
    }

    function mint()
        public
        payable
        contractCheck
        checkSaleActive
        checkSupply(1)
        checkTxnValue
        checkAlreadyMinted
    {
        _mint(msg.sender, tokenId, 1, '');
    }

    function airdrop(address[] calldata _to, uint256 _amount) public onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], tokenId, _amount, '');
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTokenId(uint256 _token) public onlyOwner {
        tokenId = _token;
    }

    function setMintStage(MintStage _newStage) public onlyOwner {
        stage = _newStage;
    }

    function setSupply(uint256 _supply) public onlyOwner {
        supply = _supply;
    }

    function withdraw(address payable dest, uint256 amount) public onlyOwner {
        dest.transfer(amount);
    }
}