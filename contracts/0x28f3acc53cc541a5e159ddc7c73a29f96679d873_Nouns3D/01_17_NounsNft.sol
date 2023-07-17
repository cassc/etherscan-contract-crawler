// SPDX-License-Identifier: UNLICENSED

//  author Name: Alex Yap
//  author-email: <[email protected]>
//  author-website: https://alexyap.dev

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NounsToken.sol";


contract Nouns3D is ERC721Enumerable, Ownable {

    string public NOUNS3D_PROVENANCE = "";
    string public baseTokenURI;

    uint256 public maxNouns3dPerTxn;
    uint256 public nouns3dPrice;
    uint256 public constant MAX_NOUNS3D = 100000;
    uint256 MintCycleTierA = 2099;
    uint256 MintCycleTierB = 7099;
    uint256 public nameChangeTokenPrice = 300 ether;
    uint256 public claimTokenPrice = 900 ether;

    bool public saleIsActiveTierA = false;
    bool public saleIsActiveTierB = false;
    bool public saleIsActiveTierC = false;

    mapping(uint256 => string) public nameN3D;
    mapping(address => uint256) public balanceN3D;

    YieldToken public yieldToken;

    event NameChanged(string name);

    function setYieldToken(address _yield) external onlyOwner {
        yieldToken = YieldToken(_yield);
    }

    function setBurnRate(uint256 _namingPrice, uint256 _claimingPrice) external onlyOwner {
        nameChangeTokenPrice = _namingPrice;
        claimTokenPrice = _claimingPrice;
    }

    function changeName(uint256 _tokenId, string memory _newName) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(validateName(_newName) == true, "Invalid name");
        yieldToken.burn(msg.sender, nameChangeTokenPrice);
        nameN3D[_tokenId] = _newName;

        emit NameChanged(_newName);
    }

    function validateName(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);

        if(b.length < 1) return false;
        if(b.length > 25) return false;
        if(b[0] == 0x20) return false; // Leading space
        if(b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) {
                return false;
            }

            lastChar = char;
        }

        return true;
    }

    function claim() external {
        yieldToken.burn(msg.sender, claimTokenPrice);

        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    function getReward() external {
        yieldToken.updateReward(msg.sender, address(0), 0);
        yieldToken.getReward(msg.sender);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        yieldToken.updateReward(from, to, tokenId);
        if (tokenId < 7400)
        {
            balanceN3D[from]--;
            balanceN3D[to]++;
        }
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        yieldToken.updateReward(from, to, tokenId);
        if (tokenId < 7400)
        {
            balanceN3D[from]--;
            balanceN3D[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    constructor(string memory baseURI) ERC721("Nouns3D", "N3D") {
        setBaseURI(baseURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(msg.sender).transfer(balance);
    }

    function reserveNouns3d(uint256 _maxMint) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < _maxMint; i++) {
            if (totalSupply() < MAX_NOUNS3D) {
                uint256 mintIndex = supply + i;

                _safeMint(msg.sender, mintIndex);

                if (mintIndex < 7400) {
                    balanceN3D[msg.sender]++;
                }
            }
        }

        yieldToken.updateRewardOnMint(msg.sender);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        NOUNS3D_PROVENANCE = provenanceHash;
    }

    function setMaxperTransaction(uint256 _maxNFTPerTransaction) internal onlyOwner {
        maxNouns3dPerTxn = _maxNFTPerTransaction;
    }

    function flipSaleStateTierA(uint256 price, uint256 _maxMint) public onlyOwner {
        nouns3dPrice = price;
        setMaxperTransaction(_maxMint);
        saleIsActiveTierA = !saleIsActiveTierA;
    }

    function flipSaleStateTierB(uint256 price, uint256 _maxMint) public onlyOwner {
        nouns3dPrice = price;
        setMaxperTransaction(_maxMint);
        saleIsActiveTierB = !saleIsActiveTierB;
    }

    function flipSaleStateTierC(uint256 price, uint256 _maxMint) public onlyOwner {
        nouns3dPrice = price;
        setMaxperTransaction(_maxMint);
        saleIsActiveTierC = !saleIsActiveTierC;
    }

    function mintTierA(uint256 numberOfTokens) public payable {
        require(saleIsActiveTierA, "Sale must be active to mint Nouns3D");
        require(maxNouns3dPerTxn > 0);
        require(totalSupply() <= MintCycleTierA);
        require(numberOfTokens <= maxNouns3dPerTxn, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + numberOfTokens <= MAX_NOUNS3D, "Purchase would exceed max supply of Nouns3D");
        require(nouns3dPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() <= MintCycleTierA) {
                _safeMint(msg.sender, mintIndex);
                //update balance count if it part of the genesis nouns
                if (mintIndex < 7400) {
                    balanceN3D[msg.sender]++;
                }
            }
        }
        //update reward on mint
        yieldToken.updateRewardOnMint(msg.sender);
    }

    function mintTierB(uint256 numberOfTokens) public payable {
        require(saleIsActiveTierB, "Sale must be active to mint Nouns3D");
        require(maxNouns3dPerTxn > 0);
        require(totalSupply() <= MintCycleTierB);
        require(numberOfTokens <= maxNouns3dPerTxn, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + numberOfTokens <= MAX_NOUNS3D, "Purchase would exceed max supply of Nouns3D");
        require(nouns3dPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() <= MintCycleTierB) {
                _safeMint(msg.sender, mintIndex);
                //update balance count if it part of the genesis nouns
                if (mintIndex < 7400) {
                    balanceN3D[msg.sender]++;
                }
            }
        }
        //update reward on mint
        yieldToken.updateRewardOnMint(msg.sender);
    }

    function mintTierC(uint256 numberOfTokens) public payable {
        require(saleIsActiveTierC, "Sale must be active to mint Nouns3D");
        require(maxNouns3dPerTxn > 0);
        require(numberOfTokens <= maxNouns3dPerTxn, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + numberOfTokens <= MAX_NOUNS3D, "Purchase would exceed max supply of Nouns3D");
        require(nouns3dPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_NOUNS3D) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}