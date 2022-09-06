// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MT_NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;
    mapping(uint => uint) public cardIdMap;
    struct Types{
        uint ID;
        uint currentAmount;
        uint maxAmount;
        string uri;
    }
    mapping(uint => Types) public types;

    constructor() ERC721('MT NFT', 'MT') {
        myBaseURI = 'https://ipfs.io/ipfs/';
        superMinter = _msgSender();
        newTypes(1,200,'QmQQnScEjYvBviqGa3Qiuh5ttxER9D9av4rf1mms5L9vmz');
        newTypes(2,30,'QmQEijQah6pXxYKR5nmmLov47JJzhK21q5rnw3YivK2Bz4');
        newTypes(3,200,'QmaSVpfPU4KPX2QCKQ9ViukdywaEPkHoqXBHU5849suMxU');
        newTypes(4,200,'QmUt71633ujLtvsn9iMS1ALs7EUrjpDQaBLEFerTgEVYYo');
        newTypes(5,5,'QmcmRW5j8VEtjzz38t47odeDygavA6pdu8cD1d12KTh8BC');
        newTypes(6,200,'QmSJ61phdwjbzRJtkqNosjKFwfYSrmXyb7ebu5owxwZfRQ');
        newTypes(7,200,'QmcC6Yb8fQfeX8eZcwqt8QunWArvTtmRMFT281brCrowpe');
        newTypes(8,30,'QmXdh4Z1y7KakQ7iCwr5hrpw2bjqquupLXhu8jsKeKbW8D');
        newTypes(9,200,'QmZaEsHji8FuM6rtmXbM47AqrXghtxTxiFzheAk4imz9sb');
        newTypes(10,200,'QmdTDXnFfQaZBdzXcVaonJkGwJTirJPNYnKYzrY2ZjrVMG');
        newTypes(11,30,'QmYa2vMq41sBSXL3hBTNJhizM8LB9ikWTdxnQverE8zRcK');
        newTypes(12,5,'QmRGnDgptMPsJe5TtzB5i2M1EdEpwEHToeJ3zmN6zf8nqB');
    }

    function newTypes(uint id,uint maxAmount,string memory uri)public onlyOwner{
        require(types[id].ID == 0,'exist tokenId');
        types[id] = Types({
        ID : id,
        currentAmount: 0,
        maxAmount : maxAmount,
        uri : uri
        });

    }

    function editTypes(uint id,uint maxAmount,string memory uri)public onlyOwner{
        require(types[id].ID != 0,'nonexistent tokenId');
        types[id] = Types({
        ID : id,
        currentAmount : types[id].currentAmount,
        maxAmount : maxAmount,
        uri : uri
        });

    }
    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player,uint ID) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        require(types[ID].currentAmount < types[ID].maxAmount,'out of limit');
        cardIdMap[currentId] = ID;
        types[ID].currentAmount ++;
        _mint(player, currentId);
        currentId ++;
    }


    function checkUserCardList(address player,uint ID) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint amount;
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(types[cardIdMap[token]].ID == ID){
                amount ++;
            }
        }
        uint[] memory list = new uint[](amount);
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(types[cardIdMap[token]].ID == ID){
                list[amount - 1] = token;
                amount --;
            }
        }
        return list;
    }

    function checkUserAllCard(address addr) public view returns(uint[] memory tokenIds,uint[] memory cardIds){
        uint tempBalance = balanceOf(addr);
        tokenIds = new uint[](tempBalance);
        cardIds = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(addr, i);
            tokenIds[i] = token;
            cardIds[i] = cardIdMap[token];
        }
    }

    function checkCardLeft(uint cardId) public view returns(uint){
        return (types[cardId].maxAmount - types[cardId].currentAmount);
    }

    function setBaseUri(string memory uri) public onlyOwner{
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");

        return string(abi.encodePacked(myBaseURI,types[cardIdMap[tokenId_]].uri));
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        types[cardIdMap[tokenId_]].currentAmount--;
        return true;
    }

}