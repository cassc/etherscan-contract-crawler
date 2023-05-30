// SPDX-License-Identifier: MIT
//                   @@@//,@@                               @@
//                   @@@.*@//,@      @@@@@@@@@@@@@@      @@,/@
//                   @@@.**@@//,@@,,,/////%%%%%%%%%%##@@((((/@
//                   @@@.****@//////////////////////////,@@@/@
//                   @@@@.****@//////////////////%%%%%%%////,@
//              @@@(((@@@@...*((((//////////////////////////////@
//              @[email protected]@@@@@(((((((((//////.....////%%%/////%/////@
//               @@***[email protected](((((%%%((((**********..%%%/////%%.**[email protected]
//                 @*******%%((%%%((((((@@,,@@@@@***((((////(@,,@
//         @@@@@@@@@.*****%%%((%%%((((((@   @@@@@@**((//////@@  @@
//          @@...********%%%%((%%%%(((((@   @@@@@@..//////////,,@[email protected]
//             @*********%%%%(((((%%((((((@@@@@///@//////////////@*@@
//               @@@*****%%%%%(((((((((((//////////////@@********@@
//                 @.******%%%%((((((((@@(((//////[email protected]@@@@@[email protected]@
//               @@.**********%%%%(((@@(@@(((((((*@ @@[email protected]@@
//                    @@((@*****%%%(((((((@@@@@**@,,@@.....*@*@@*[email protected]
//                 @(((((((@@**********************@@@@@@@@*[email protected]@
//              @%%%%((((((((@*@@@(**@@@***********...........**@
//             @%%%%%%((((((((((((**...**********@************@@@
//            @(%%%%%%%%%%((((((**.*..........******@@@@@@@@@(//%@
//          @@((((((((((%%%%%%####.................********..%%%%@
//         @(((((((((((((((((**...#####..................###./////@
//        @%(((((((((((((((@@**.**..................**[email protected]/////@@
//       @%%%%%%((((((((((@********....**.............*[email protected]@//%%%@
//       @(((((((((((((((@*****.....*.................*[email protected]@%%////@  
pragma solidity ^0.8.0;

import "./PixelTigersERC721.sol";

contract PixelTigers is PixelTigers721 {
    
    modifier onlyOwnerToken(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "Do not own this tiger"); 
        _;
    }
   
    uint256 constant public BREED_PRICE = 1000 ether;

    mapping (address => uint256) public numberOfLegendaries;
    mapping (address => uint256) public numberOfUniques;

    mapping (uint256 => bool) public isLegendary;
    mapping (uint256 => bool) public isUnique;

    constructor(string memory baseURI) PixelTigers721(baseURI) {}

    function breed(uint256 tiger1, uint256 tiger2) external onlyOwnerToken(tiger1) onlyOwnerToken(tiger2) {
        uint256 supply = totalSupply();
        require(supply < totalMaxSupply,"No more babies can be bred");
        require(tiger1 < totalAmtGenesis && tiger2 < totalAmtGenesis,"Babies can't be bred");
        require(tiger1 != tiger2,"Use different parents");
        require(breedActive,"breeding not active");
    
        uint256 random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender)));
        uint256 tokenId = random%8888 + totalAmtGenesis;
        while (_exists(tokenId)) {
            if (tokenId == 13331) {
                tokenId = 4443;
                tokenId++;
            } else {
                tokenId++;
            }
        }
        Pixel.burn(msg.sender, BREED_PRICE);
        babyCount++;
        _safeMint(msg.sender, tokenId);
        ownsThisToken[tokenId] = msg.sender;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (tokenId < totalAmtGenesis) {
            Pixel.rewardSystemUpdate(from, to);
            ownerGenesisCount[from]--;
            ownerGenesisCount[to]++;
        }
        if (isLegendary[tokenId] == true) {
            numberOfLegendaries[from]--;
            numberOfLegendaries[to]++;
        }
        if (isUnique[tokenId] == true){
            numberOfUniques[from]--;
            numberOfUniques[to]++;
        }
        ERC721.transferFrom(from, to, tokenId);
        ownsThisToken[tokenId] = to;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (tokenId < totalAmtGenesis) {
            Pixel.rewardSystemUpdate(from, to);
            ownerGenesisCount[from]--;
            ownerGenesisCount[to]++;
        }
        if (isLegendary[tokenId] == true) {
            numberOfLegendaries[from]--;
            numberOfLegendaries[to]++;
        }
        if (isUnique[tokenId] == true){
            numberOfUniques[from]--;
            numberOfUniques[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId, data);
        ownsThisToken[tokenId] = to;
    }

    function setLegendaryList(uint256[] calldata tokenList) external onlyOwner {
        for(uint256 i; i < tokenList.length; i++){
            numberOfLegendaries[ownerOf(tokenList[i])]++;
            isLegendary[tokenList[i]] = true;
        }
    }

    function setUniqueList(uint256[] calldata tokenList) external onlyOwner {
        for(uint256 i; i < tokenList.length; i++){
            numberOfUniques[ownerOf(tokenList[i])]++;
            isUnique[tokenList[i]] = true;
        }
    }

    function tokenIdsOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 ownertokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](ownertokenCount);
        for(uint256 i; i < ownertokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function tokenGenesisOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 ownertokenCount = ownerGenesisCount[owner];
        uint256[] memory tokensId = new uint256[](ownertokenCount);
        for(uint256 i; i < ownertokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;   
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns(uint256 tokenId){
        require(index < balanceOf(owner));
        uint count;
        for(uint i; i< totalMaxSupply; i++){
            if(owner == ownsThisToken[i]){
                if(count == index) return i;
                else count++;
            }
        }
    }

    function addPresale(address[] calldata presaleAddresses, uint256 amount) external onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount;
        }
    }

    function addReserved(address[] calldata reservedAddresses, uint256 amount) external onlyOwner {
        for(uint256 i; i < reservedAddresses.length; i++){
            reservedList[reservedAddresses[i]] = amount;
            amtReserved = amtReserved + amount;
        }
    }

    function removeReserved(address[] calldata reservedAddresses, uint256 amount) external onlyOwner {
        for(uint256 i; i < reservedAddresses.length; i++){
            reservedList[reservedAddresses[i]] = reservedList[reservedAddresses[i]] - amount;
            amtReserved = amtReserved - amount;
        }
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }
    
    function toggleReserveSale() public onlyOwner {
        reserveActive = !reserveActive;
    }

    function toggleBreed() public onlyOwner {
        breedActive = !breedActive;
    }
}