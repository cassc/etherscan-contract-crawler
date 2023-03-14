// SPDX-License-Identifier: MIT

//     ______   ____     ____     ______ _    __    ______    ____            ___    ______   ______    ______   _____   _____
//    / ____/  / __ \   / __ \   / ____/| |  / /   / ____/   / __ \          /   |  / ____/  / ____/   / ____/  / ___/  / ___/
//   / /_     / / / /  / /_/ /  / __/   | | / /   / __/     / /_/ /         / /| | / /      / /       / __/     \__ \   \__ \ 
//  / __/    / /_/ /  / _, _/  / /___   | |/ /   / /___    / _, _/         / ___ |/ /___   / /___    / /___    ___/ /  ___/ / 
// /_/       \____/  /_/ |_|  /_____/   |___/   /_____/   /_/ |_|         /_/  |_|\____/   \____/   /_____/   /____/  /____/  
                                                                                                                           
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefaultOperatorFilterer.sol";

contract FOREVERACCESS is ERC721Enumerable, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    bool public RevealedActive = true;
    bool public MintPassMode = true;
    bool public PublicSaleMode = true;

    uint256 public PublicPrice = 0.1 ether;
    uint256 public MaxPhaseSupply = 50;
    uint256 public MaxSupply = 100;

    uint256 public MintPassCount;
    uint256 public PublicSaleCount;
    
    ERC1155Burnable public MintPass;

    constructor(address _erc1155Address) ERC721("FOREVER ACCESS", "4SHIBA") {
        MintPass = ERC1155Burnable(_erc1155Address);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    uint256 public nextTokenId = 1;

    function FreeMint(uint256 _Amount) public payable callerIsUser {
        require(MintPassMode == true, "Mint pass Sale not started");
        require(_Amount > 0, "Incorrect Amount");
        require(MintPassCount + _Amount <= MaxPhaseSupply, "Sold Out");
        
        require(
            MintPass.balanceOf(msg.sender, 0) >= _Amount,
            "You don't own enough Mint Pass"
        );

       
        MintPass.burn(msg.sender, 0, _Amount);

        for (uint256 i = 1; i <= _Amount; i++) {
            MintPassCount++;
            _safeMint(msg.sender, nextTokenId++);
        }
    }

    uint256 public nextPublicTokenId = 51;

    function PublicMint(uint256 _Amount) public payable callerIsUser {
        require(MintPassMode == true, "Public Sale not started");
        require(_Amount > 0, "Incorrect Amount");
        require(PublicSaleCount + _Amount <= MaxPhaseSupply, "Sold Out"); 

        require(msg.value >= PublicPrice * _Amount, "Balance Insufficient");
         
        for (uint256 i = 0; i < _Amount; i++) {
            PublicSaleCount++;
            _safeMint(msg.sender, nextPublicTokenId++);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "");
        if (RevealedActive == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }


    // Withdraw smart contract funds
    function withdraw() public payable onlyOwner {
        (bool bq, ) = payable(owner()).call{value: address(this).balance}("");
        require(bq);
    }

    function OwnerMint(uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MaxSupply, "Sold Out");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function AirdropMint(address _to, uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MaxSupply, "Sold Out");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }


    // Set phases
    function TurnFreeMode(bool _state) public onlyOwner {
        MintPassMode = _state;
    }

    function TurnPublicMode(bool _state) public onlyOwner {
        PublicSaleMode = _state;
    }

    // Set Public Price & Presale Price
    function setPublicPrice(uint256 _newPublicPrice) public onlyOwner {
        PublicPrice = _newPublicPrice;
    }


    // Set NFTs CID and Place Holder CID
    function setURIBase(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // Reveal the NFTs
    function Reveal() public onlyOwner {
        RevealedActive = true;
    }

    // Opensea royalties
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}