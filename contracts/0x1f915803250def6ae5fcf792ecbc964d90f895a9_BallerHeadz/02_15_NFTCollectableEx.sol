// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollectableEx is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mintPrice,
        uint256 _initialSupply
    ) ERC721(_name, _symbol) {
        canMint = true;
        mintPrice = _mintPrice;
        setInitialSupply(_initialSupply);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //all funds redrawall function
    function withdrawAllFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    //minting
    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenURI
    ) external virtual payable mintingAllowed {
        require(
            msg.value >= mintPrice,
            "Sent value is insufficient for minting token!"
        );
        require(availableSupply() > 0, "Out of supply!");
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    //batch minting
    function mintBatch(
        address _to,
        uint256[] memory _tokenIds,
        string[] memory _tokenURIs
    ) external virtual payable mintingAllowed {
       
        require(
            _tokenIds.length == _tokenURIs.length,
            "Number of provided tokenIds must be exactly the same as number of provided tokenURIs!"
        );

        uint256 numberOfItemsToMint = _tokenIds.length;
        require(availableSupply() - numberOfItemsToMint >= 0, "Out of supply!");

        uint256 totalPrice = mintPrice * numberOfItemsToMint;

        require(
            msg.value >= totalPrice,
            "Sent value is insufficient for minting tokens!"
        );

        for (uint256 i = 0; i < numberOfItemsToMint; i++) {
            _safeMint(_to, _tokenIds[i]);
            _setTokenURI(_tokenIds[i], _tokenURIs[i]);
        }
    }

    
    // //minting owner (no value required - "for free")
    // function mintByOwner(
    //     address _to,
    //     uint256 _tokenId,
    //     string memory _tokenURI
    // ) external virtual payable mintingAllowed onlyOwner {
    //     require(availableSupply() > 0, "Out of supply!");
    //     _safeMint(_to, _tokenId);
    //     _setTokenURI(_tokenId, _tokenURI);
    // }

    // //batch minting owner (no value required - "for free")
    // function mintBatchByOwner(
    //     address _to,
    //     uint256[] memory _tokenIds,
    //     string[] memory _tokenURIs
    // ) external virtual payable mintingAllowed onlyOwner {
       
    //     require(
    //         _tokenIds.length == _tokenURIs.length,
    //         "Number of provided tokenIds must be exactly the same as number of provided tokenURIs!"
    //     );

    //     uint256 numberOfItemsToMint = _tokenIds.length;
    //     require(availableSupply() - numberOfItemsToMint >= 0, "Out of supply!");

    //     for (uint256 i = 0; i < numberOfItemsToMint; i++) {
    //         _safeMint(_to, _tokenIds[i]);
    //         _setTokenURI(_tokenIds[i], _tokenURIs[i]);
    //     }
    // }

    uint16 public mintBatchLimit = 10;
    function setMintBatchLimit(uint16 _mintBatchLimit) external onlyOwner {
        mintBatchLimit = _mintBatchLimit;
    }

    //determines if minting is possible, default is true
    bool public canMint;

    //disable minting
    function disableMint() external onlyOwner {
        canMint = false;
    }

    //enable minting
    function enableMint() external onlyOwner {
        canMint = true;
    }

    modifier mintingAllowed() {
        require(canMint, "Minting is currently not allowed!");
        _;
    }

    //price of minting one item in wei
    uint256 public mintPrice;

    //set mint price (in wei)
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    //ukupno dostupna količina
    uint256 public initialSupply;

    //set initial supply
    function setInitialSupply(uint256 _initialSupply) public onlyOwner {
        require(totalSupply() == 0, "Initial token supply can only be set if there is no minted tokens (totalSupply must be 0)!");
        require(_initialSupply > 0, "Initial token supply must be greater then 0!");
        initialSupply = _initialSupply;
    }

    //get available supply
    function availableSupply() public view returns(uint) {
        return initialSupply - reservedSupply() - totalSupply() ;
    }

    //reserved supply by owner
    uint256 private reservedSupplyByOwner;
    //this function is only for owner, because function reservedSupply for owner allways returns 0. This returns actual set reserve.
    function getReservedSupply() view public onlyOwner returns(uint256) {
        return reservedSupplyByOwner;
    }

    function reservedSupply() view public returns(uint) {
        if (msg.sender == owner()){
            //owner ignores reserved supply! that only applies to users
            return 0;
        }
        else{
            //for not owner return this:
            return reservedSupplyByOwner;
        }
    }

    //set reserved supply
    function setReservedSupply(uint256 _reservedSupply) external onlyOwner {
        require(_reservedSupply < initialSupply, "Reserved supply must be less then initial supply!");
        require(_reservedSupply <= availableSupply(), "Reserved supply must be less then available supply!");

        reservedSupplyByOwner = _reservedSupply;
    }

}

//31.08.2021. 22:49: ovo je ispravan template za kreiranje nft collectibila, testirano i prikazuje se na OpenSea
//01.09.2021. 09:41: dodana mintPrice, setMintPrice i require na mint
//01.09.2021. 22:04: dodan mintBatch
//02.09.2021. 11:15: dodana reservedSupply logika