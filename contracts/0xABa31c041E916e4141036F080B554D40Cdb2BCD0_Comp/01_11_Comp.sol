// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract  ICompRandom {
    function simpleRandom(string memory luckyData,uint pointer) public view virtual returns  (bytes32);
}

abstract contract INMT{
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
}
abstract contract IBContract{
    function balanceOf(address account) external view  virtual returns (uint256);
}

contract Comp is ERC721, Ownable{
    // Mapping from token ID to gene
    mapping (uint256 => string) public geneMap;
    // Mapping from gene to token ID
    mapping (string => uint256) public gene2TokenIdMap;

    //all mint history
    mapping (uint256 => uint256) public hourAmount;
    mapping (address => uint256) public addressNextMintDate;
    mapping (address => int256) public giftContract;

    mapping (address => uint256) private _addressNormalMintAmount;

    uint256  public tokenId=1;
    uint public totalSupply=10000;

    string private _uri;


    mapping(address => uint8) public airdropWhitelist;

    //all gene template
    uint8[][] private _geneTemplates =
[
[5,9,10,10,9,9,9,0,0],
[5,9,10,9,10,9,0,0,0],
[5,9,10,9,10,9,0,0,0],
[5,9,9,10,9,9,9,0,0],
[5,9,10,9,9,0,0,0,0],
[5,9,9,10,9,9,0,0,0],
[5,9,10,10,9,0,0,0,0],
[5,9,9,10,9,9,0,0,0],
[5,9,9,10,9,9,0,0,0],
[5,9,9,10,9,9,0,0,0],
[5,9,10,9,10,9,9,0,0],
[5,9,10,10,9,9,0,0,0],
[5,9,9,10,9,10,0,0,0],
[5,9,10,10,9,10,10,9,0],
[5,9,10,10,9,9,9,9,0],
[5,9,10,9,9,0,0,0,0],
[5,9,9,10,9,9,0,0,0],
[5,9,10,10,9,0,0,0,0],
[5,9,10,10,9,9,0,0,0],
[5,9,10,9,9,9,0,0,0],
[5,9,10,10,9,9,9,0,0],
[5,9,10,9,9,0,0,0,0],
[5,9,10,9,9,9,0,0,0],
[5,9,10,9,10,9,9,9,0],
[5,9,9,10,10,9,0,0,0],
[5,9,10,10,9,9,0,0,0],
[5,9,10,9,9,10,9,9,0],
[5,9,9,9,0,0,0,0,0],
[5,9,10,9,9,9,0,0,0],
[5,9,9,9,10,9,0,0,0],
[5,9,10,9,9,0,0,0,0],
[5,9,9,9,9,9,0,0,0],
[5,9,10,9,10,9,0,0,0],
[5,9,10,9,9,0,0,0,0],
[5,9,10,9,9,9,0,0,0],
[5,9,10,10,9,9,9,10,0],
[5,9,9,10,9,0,0,0,0],
[5,9,10,10,10,9,9,0,0],
[5,9,10,9,9,10,0,0,0],
[5,9,10,9,10,10,0,0,0],
[5,9,10,9,9,0,0,0,0],
[5,9,10,9,0,0,0,0,0],
[5,9,10,10,9,9,9,0,0],
[5,9,10,10,10,9,9,0,0],
[5,9,10,9,0,0,0,0,0],
[5,9,10,9,9,9,0,0,0],
[5,9,9,10,9,9,0,0,0],
[5,9,9,9,9,0,0,0,0],
[5,9,9,9,9,9,0,0,0],
[5,9,10,9,9,0,0,0,0],

[5,9,10,9,9,10,9,0,0],
[5,9,9,9,9,9,0,0,0],
[5,9,10,9,10,9,9,0,0],
[5,9,10,10,9,10,0,0,0],
[5,9,10,10,9,9,9,9,0],
[5,9,10,9,9,9,10,0,0],
[5,9,10,9,10,9,9,10,0],
[5,9,9,10,10,9,10,0,0],
[5,9,10,10,9,0,0,0,0],
[5,9,10,10,9,9,9,0,0],
[5,9,10,10,9,10,10,10,0],
[5,9,10,10,9,9,10,0,0],
[5,9,10,9,10,9,0,0,0],
[5,9,9,10,10,9,9,0,0],
[5,9,10,10,9,0,0,0,0],
[5,9,10,10,9,9,0,0,0],
[5,9,10,10,9,9,9,0,0],
[5,9,10,10,9,0,0,0,0],
[5,9,10,10,9,0,0,0,0],
[5,9,10,9,9,9,9,10,0],
[5,9,10,9,9,9,0,0,0],
[5,9,10,9,9,0,0,0,0],
[5,9,10,10,9,9,9,9,0],
[5,9,10,10,9,10,9,0,0],
[5,9,10,10,10,9,9,0,0],
[5,9,10,9,10,0,0,0,0],
[5,9,10,10,9,10,9,0,0],
[5,9,10,10,10,9,9,9,0],
[5,9,10,9,9,0,0,0,0],
[5,9,10,9,9,10,0,0,0],
[5,9,10,9,10,10,9,0,0],
[5,9,10,10,9,9,9,10,10],
[5,9,10,10,9,10,10,9,0],
[5,9,9,10,9,10,9,9,0],
[5,9,10,10,9,9,0,0,0],
[5,9,10,9,9,0,0,0,0],
[5,9,9,9,9,10,9,0,0],
[5,9,10,10,9,9,9,0,0],
[5,9,9,10,9,9,10,0,0],
[5,9,10,9,9,10,0,0,0],
[5,9,10,10,9,9,0,0,0],
[5,9,10,9,10,9,9,0,0],
[5,9,10,10,9,9,0,0,0],
[5,9,10,9,9,9,9,0,0],
[5,9,10,9,9,9,0,0,0],
[5,9,10,9,10,9,10,9,0],
[5,9,10,9,9,9,10,0,0],
[5,9,9,10,10,9,0,0,0],
[5,9,9,10,9,10,0,0,0],
[5,9,10,10,9,9,9,0,0]
];


    // random contract
    address  public randomContract= address(0x4373A302B3Fd99d91E9eF540f200FdCd856Fbb73);
    address private _nmtContractAddress = address(0xd81b71cBb89B2800CDb000AA277Dc1491dc923C3);

    event SetURI(string);
    event SetRandomContract(address);


    /**
    * Init metadata url
    *
    */
    constructor() ERC721("Chinese Opera Mask Plus","COMP"){

        _uri = "https://api.chineseoperamaskplus.com/assets/data/";

        //NMT
        giftContract[_nmtContractAddress]=-1;
        //CryptoPunks
        giftContract[0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB]=1;
        //Hashmasks
        giftContract[0xC2C747E0F7004F9E8817Db2ca4997657a7746928]=1;
        //CryptoKitties
        giftContract[0x06012c8cf97BEaD5deAe237070F9587f8E7A266d]=1;


    }

    /**
    * Update metadate url
    *
    * onlyOwner
    *
    * Emits a {SetURI} event.
    *
    * Requirements:
    * - `newuri`
    */
    function setURI(string memory newuri) public onlyOwner{

        _uri = newuri;
        emit SetURI(newuri);
    }

    function _baseURI() internal view override returns(string memory){
        return _uri;
    }

    /**
    * update random contract
    *
    * onlyOwner
    *
    *  Emits a {SetRandomContract} event.
    *
    * Requirements
    * - `randomAddress`   random contract address
    */
    function  setRandomContract(address randomAddress) public onlyOwner{

        require(randomAddress != address(0), "Comp: set zero address");
        randomContract = randomAddress;
        emit SetRandomContract(randomAddress);
    }

    /**
    * @dev Mint new NFT
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `luckyData` annot be the null
    * - `giftContractAddress` cannot be the null.
    */
    function mint(string memory luckyData,address giftContractAddress) public{

        //mint before 13600000
        require(  block.number <= 13600000, "Comp: Has reached 13600000 block number");

        //up to 10000
        require(  totalSupply >= tokenId, "Comp: Has reached totalSupply ");

        //up to 1000 per day
        uint256 hourTimestamp = block.timestamp - block.timestamp%3600;
        require(  hourAmount[hourTimestamp] < 200, "Comp: Up to 200 per hour");

        //daily mining
        bool whitelist = false;

        if(tokenId>100){
            int256  target = giftContract[giftContractAddress];
            require(  target != 0, "Comp: Does not meet the conditions");
            IBContract gift =  IBContract(giftContractAddress);
            uint256 amount = gift.balanceOf(msg.sender);

            if((target==-1)? amount<=tokenId: amount<uint256(target)){
                if(airdropWhitelist[msg.sender]>0){
                    whitelist=true;
                }else{
                    require(false, "Comp: Not enough holdings");
                }
            }
        }

        uint256 timestamp =  block.timestamp;

        if(addressNextMintDate[msg.sender] >=  timestamp){
            if(airdropWhitelist[msg.sender]>0){
                whitelist=true;
            }else{
                require( false , "Comp: during cooling time");
            }
        }

        (string memory gene,uint8 sex) = _generateGene(luckyData);

        //NMT
        INMT nmt = INMT(_nmtContractAddress);
        nmt.transferFrom(owner(),msg.sender, (20 - 5* sex) * 10** uint256(18) );

        while(gene2TokenIdMap[gene] >0 ){ //Whether the gene is occupied
            luckyData = string(abi.encodePacked(luckyData,"_")); //new luckyData
            (gene,sex) = _generateGene(luckyData);
        }
        geneMap[tokenId] = string(abi.encodePacked(gene,"_",Strings.toString(sex)));
        gene2TokenIdMap[gene] = tokenId;
        _mint(msg.sender,tokenId);

        hourAmount[hourTimestamp]++;

        if(whitelist){
            airdropWhitelist[msg.sender]--; //use airdrop
        }else{
            _addressNormalMintAmount[msg.sender]++;  //normal mint amount +1
        }
        addressNextMintDate[msg.sender] = timestamp + _addressNormalMintAmount[msg.sender] * 4 * 3600 ;
        tokenId++;  //start from 1
    }

    /**
    * show NFT uri with token id
    *
    * Requirements
    * - `id`  tokenId
    */
    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory gene = geneMap[id];
        return string(abi.encodePacked(_uri, Strings.toString(id),".json?gene=",gene));
    }

    /**
    *
    * generate gene from luckData
    *
    * Requirements
    * - `luckyData`  lucky key
    */
    function _generateGene(string memory luckyData) internal view returns(string memory,uint8){
        uint8 preGenes = 255;
        string memory geneStr = "";

        ICompRandom random = ICompRandom(randomContract);
        bytes32 str = random.simpleRandom(luckyData,tokenId);
        //1: template
        uint256 templateId =  uint8(str[0])%_geneTemplates.length;

        uint8[] memory templateInfo = _geneTemplates[templateId];
        geneStr = Strings.toString(templateId);
        //2: add eye + maskup
        for(uint8 i=0; i< templateInfo.length;i++){
            if(0==templateInfo[i]){
                break;
            }
            uint8 geneRandomNum = uint8(str[i+1]);
            uint8 gene = geneRandomNum % templateInfo[i]+1;
            if(preGenes==gene && (gene!=10) && (preGenes != 10)){
                geneRandomNum++;
                gene = geneRandomNum %templateInfo[i]+1;
            }
            geneStr = string(abi.encodePacked(geneStr, '_',Strings.toString(gene)));
            preGenes = gene;
        }
        uint8 sexNumber = uint8(str[str.length-1]) % 20 ;
        if(sexNumber==19){
            sexNumber=3;
        }else if(sexNumber<19&& sexNumber>=14){
            sexNumber=2;
        }else if(sexNumber<14&& sexNumber>=7){
            sexNumber=1;
        }else{
            sexNumber=0;
        }

        return (geneStr,sexNumber);
    }

    /**
    *
    * add new whitelist
    *
    * Requirements
    * - `whitelist`  whitelist
    */
    function addWhitelist(address[] memory whitelist,uint8 number) public onlyOwner{
        for(uint i=0;i<whitelist.length;i++){
            airdropWhitelist[whitelist[i]]=number;
        }
    }

    /**
     *
     * add new whitelist
     *
     * Requirements
     * - `gifts`  whitelist
     * - `number`
     */
    function addGiftContract(address[] memory gifts,int256 number) public onlyOwner{
        for(uint i=0;i<gifts.length;i++){
            giftContract[gifts[i]]= number;
        }
    }
}