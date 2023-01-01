// SPDX-License-Identifier: MIT

/*//================================================================================================================//

██╗  ██╗ █████╗ ██████╗ ██████╗ ██╗   ██╗    ███╗   ██╗███████╗██╗    ██╗    ██╗   ██╗███████╗ █████╗ ██████╗ ███████╗
██║  ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝    ████╗  ██║██╔════╝██║    ██║    ╚██╗ ██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝
███████║███████║██████╔╝██████╔╝ ╚████╔╝     ██╔██╗ ██║█████╗  ██║ █╗ ██║     ╚████╔╝ █████╗  ███████║██████╔╝███████╗
██╔══██║██╔══██║██╔═══╝ ██╔═══╝   ╚██╔╝      ██║╚██╗██║██╔══╝  ██║███╗██║      ╚██╔╝  ██╔══╝  ██╔══██║██╔══██╗╚════██║
██║  ██║██║  ██║██║     ██║        ██║       ██║ ╚████║███████╗╚███╔███╔╝       ██║   ███████╗██║  ██║██║  ██║███████║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝        ╚═╝       ╚═╝  ╚═══╝╚══════╝ ╚══╝╚══╝        ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝

*///================================================================================================================//                                                                                                                  

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

contract NewYear is ERC721A {

    uint256 public Year = 2023;
    string baseURI;
    bool open;
    address owner;
    constructor() ERC721A("New Years Party 2023", "2023") {
        owner = tx.origin;
    }

    modifier dumbContracts() {
        require(tx.origin == msg.sender, "CALLER IS A CONTRACT");
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"CALLER NOT OWNER");
        _;
    }

    function mint() external dumbContracts {
        require(open, "WAIT FOR MINT TO OPEN");
        require(balanceOf(msg.sender)<=2, "MAX 3 PER WALLET");
        require(_totalMinted() + 1 <= Year, "MINTED OUT");

        _mint(msg.sender, 1);
    }

    function sacrifice(uint256 tokenId) public returns(string memory) {
        _burn(tokenId, true);
        return "sacrificed";
    }

    function openMint() public onlyOwner{
        open = true;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory){
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : "ipfs://QmejZmFnV33cDmcDdo5kFjfq8fFCimoxGeWDQohscT8pGu/hidden.json";
    }

    function contractURI() public pure returns(string memory){
        return "ipfs://QmejZmFnV33cDmcDdo5kFjfq8fFCimoxGeWDQohscT8pGu/contractURI.json";
    }

    function mintedout() public view returns(bool){
        return _totalMinted() >= Year;
    }
}