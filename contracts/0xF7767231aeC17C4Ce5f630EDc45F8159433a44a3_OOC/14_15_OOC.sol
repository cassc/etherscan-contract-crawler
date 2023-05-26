// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// import "./otherset/VOC_ERC721.sol";
import "./otherset/ERC721A.sol";

contract OOC is ERC721A, Ownable, EIP712{
    using Strings for uint256;
    constructor() ERC721A("OddOwl_Club", "OOC",500) EIP712("Odd_Owl_Club", "1"){
        _safeMint(Receive,500);
        Organ_pool_m+=500;
        
        supbcn[]memory once= new supbcn[](14);
        once[0]=supbcn(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB,1000);
        once[1]=supbcn(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D,1000);
        once[2]=supbcn(0xED5AF388653567Af2F388E6224dC7C4b3241C544,1000);
        once[3]=supbcn(0x60E4d786628Fea6478F785A6d7e704777c86a7c6,1000);
        once[4]=supbcn(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e,1000);
        once[5]=supbcn(0x23581767a106ae21c074b2276D25e5C3e136a68b,1000);
        once[6]=supbcn(0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B,1000);
        once[7]=supbcn(0x79FCDEF22feeD20eDDacbB2587640e45491b757f,1000);
        once[8]=supbcn(0x7Bd29408f11D2bFC23c34f18275bBf23bB716Bc7,1000);
        once[9]=supbcn(0xe785E82358879F061BC3dcAC6f0444462D4b5330,1000);
        once[10]=supbcn(0xDCf68c8eBB18Df1419C7DFf17ed33505Faf8A20C,500);
        once[11]=supbcn(0x3113A3c04aEBEC2B77eB38Eabf6a2257B580c54B,500);
        once[12]=supbcn(0x249aeAa7fA06a63Ea5389b72217476db881294df,500);
        once[13]=supbcn(0xF75FD01D2262b07D92dcA7f19bD6A3457060d7db,500);
        addsupportedBcns(once);
        setswap[]memory swaps= new setswap[](2);
        swaps[0]=setswap(0x080fa1fb48E0b1Bd251348efd02c1e7a12A931ac,true);
        swaps[1]=setswap(0x20F780A973856B93f63670377900C1d2a50a77c4,true);
        set_swap(swaps);
    }

    uint256 constant total_supply = 10000;

    uint256 constant Organ_mint_time = 1671595200;
    uint256 constant Organ_mint_fee = 0.05*10**18;
    uint256 Organ_pool_m;
    uint256 constant Organ_pool_em = 500+1300+3500;

    uint256 constant Organ2_mint_time = Organ_mint_time;
    uint256 constant Organ2_mint_fee = 0.05*10**18;
    uint256 Organ2_pool_m;
    uint256 constant Organ2_pool_em = 2000;


    uint256 constant White_mint_time = 1671606000;
    uint256 constant White_mint_fee = 0.05*10**18;
    uint256 White_pool_m;

    uint256 constant Public_mint_time = 1671638400;
    uint256 constant Public_mint_fee = 0.06*10**18;
    uint256 Public_pool_m;
    
    uint256 constant b_White_mint_time = 1671606000;
    uint256 constant b_White_mint_fee = 0.05*10**18;
    uint256 b_White_pool_m;

    uint256 constant end_time=1671638400;
    uint256 constant end_time2=1671811200;


    address constant Receive = 0xDc66019E46d7E8ac9F155fF0668c9e1Fca34421F;
    address immutable signer = msg.sender;
    struct setinfo{
        address _signer;uint256 _total_supply;address _Receive;string _baseURL;uint256 _end_time;uint256 _end_time2;
        uint256 _Organ_mint_time;uint256 _Organ_mint_fee;uint256 _Organ_pool_m;uint256 _Organ_pool_em;
        uint256 _Organ2_mint_time;uint256 _Organ2_mint_fee;uint256 _Organ2_pool_m;uint256 _Organ2_pool_em;
        uint256 _White_mint_time;uint256 _White_mint_fee;uint256 _White_pool_m;
        uint256 _Public_mint_time;uint256 _Public_mint_fee;uint256 _Public_pool_m;
        uint256 _b_White_mint_time;uint256 _b_White_mint_fee;uint256 _b_White_pool_m;
    }
    function view_set()public view returns(
        setinfo memory,
        uint256 _total_minted,uint256 _now_time,
        uint256 _White_pool_em,uint256 _Public_pool_em,uint256 _b_White_pool_em
    ){
        unchecked{
            return (setinfo(
                signer,totalSupply(),Receive,baseURL,
                end_time,end_time2,
                Organ_mint_time,Organ_mint_fee,
                Organ_pool_m,Organ_pool_em,
                Organ2_mint_time,Organ2_mint_fee,
                Organ2_pool_m,Organ2_pool_em,
                White_mint_time,White_mint_fee,
                White_pool_m,
                Public_mint_time,Public_mint_fee,
                Public_pool_m,
                b_White_mint_time,b_White_mint_fee,
                b_White_pool_m
                ),
                totalSupply(),block.timestamp,
                (total_supply-Organ2_pool_m-Organ_pool_m-b_White_pool_m),
                (total_supply-Organ2_pool_m-Organ_pool_m-White_pool_m-b_White_pool_m),
                (total_supply-Organ2_pool_m-Organ_pool_m)
            );
        }
        
    }
    // open box
    string baseURL;
    function set_baseinfo(string calldata _str)public onlyOwner{
        baseURL=_str;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURL;
    }
    function tokenURI(uint256 tokenId)public view override returns (string memory){
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "ipfs://bafybeiacwutogdxuso375yqeueux6egecrzxxjfxai2lndsd2jfk7s4jo4/owlbox.json";
    }

    // White_list
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("PermitMint(address gainer,uint256 amount,uint256 deadline,uint256 typemint)");
    
    function signcheck(_signvrs calldata signinfo)public view returns(address _signer){
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, signinfo.gainer,signinfo.amount,signinfo.deadline,signinfo.typemint));
        bytes32 hash = _hashTypedDataV4(structHash);
        return ECDSA.recover(hash, signinfo.v, signinfo.r, signinfo.s);
    }
    
    mapping(uint256=>uint256) public locktime;
    event locknft(address indexed owner,uint256 indexed tokenId,uint256 time,uint256 endtime);

    function stake(uint256 tokenId,uint256 locktype)public{
        require(locktime[tokenId]<block.timestamp,"NFT is already in staking");
        require(ownerOf(tokenId)==msg.sender,"This NFT does not belong to you");
        require(locktype%30==0,"error locktype,Must be a multiple of 30");
        locktime[tokenId]=block.timestamp+locktype*86400;
        emit locknft(msg.sender,tokenId,locktype,locktime[tokenId]);
    }


    IOperatorFilterRegistry constant opensea_white =IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    mapping(address=>bool) public white_swaps;
    struct setswap{
        address swap;
        bool flag;
    }
    function set_swap(setswap[] memory setswaps)public onlyOwner{
        uint256 l = setswaps.length;
        unchecked{
            for(uint256 i =0;i<l;i++){
                white_swaps[setswaps[i].swap]=setswaps[i].flag;
            }
        }

    }
    function setApprovalForAll(address operator, bool approved) public override{
        checkSwap(operator);
        super.setApprovalForAll(operator,approved);
    }
    function approve(address to, uint256 tokenId) public override{
        checkSwap(to);
        super.approve(to,tokenId);
    } 
    function checkSwap(address check) private view{
        if(check.code.length!=0){
            if(!white_swaps[check]){
                require(opensea_white.isOperatorAllowed(address(opensea_white),check),"Cannot perform nft transfer through this contract");
            }
        }
    }
    
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    )internal override
    {
        require(locktime[(startTokenId)]<block.timestamp,"lock time");
        super._beforeTokenTransfers(from, to, startTokenId,quantity);
    }




    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    struct _signvrs{
        address gainer;
        uint256 amount;
        uint256 deadline;
        uint256 typemint;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    mapping(uint256=>uint256) public platform;
    function OOC_mint(uint256 _platform,_signvrs calldata signinfo,uint256 quantity)public payable{
        checkandmint(signinfo,quantity);
        uint256 typemint=signinfo.typemint;
        if(typemint==0){
            Organ_mint(quantity);
        }else if(typemint==1){
            Organ2_mint(quantity);
        }else if(typemint==2){
            White_mint(quantity);
        }else{
            revert("typemint error");
        }
        require(totalSupply()<=total_supply,"minted out");
        require(block.timestamp<=end_time,"Out of time");
        unchecked{
            platform[_platform]+=quantity;
        }
    }
    function Organ_mint(uint256 quantity)private{
        unchecked{
            require(msg.value==Organ_mint_fee*quantity,"error fee");
            require(Organ_mint_time<block.timestamp,"Out of time");
            Organ_pool_m+=quantity;
        }
    }
    function Organ2_mint(uint256 quantity)private{
        unchecked{
            require(msg.value==Organ2_mint_fee*quantity,"error fee");
            require(Organ2_mint_time<block.timestamp,"Out of time");
            Organ2_pool_m+=quantity;
        }
    }
    
    struct bcninfo{
        uint256 minted;
        uint256 total_supply;
    }
    mapping(address=>mapping(uint256=>uint256)) public isTokenMintByBcn;
    mapping(address =>bcninfo) public bcninfos;
    function showbcninfo(address[] calldata bcns)view public returns(bcninfo[] memory _bcninfos){
        _bcninfos=new bcninfo[](bcns.length);
        unchecked{
            for(uint256 i=0;i<bcns.length;i++){
                _bcninfos[i].minted=bcninfos[bcns[i]].minted;
                _bcninfos[i].total_supply=bcninfos[bcns[i]].total_supply;
            }
        }
    }
    function Blue_mint(uint256 _platform,address bcn,uint256 bcnTokenId,uint256 quantity)public payable{
        unchecked{
            address sender = msg.sender;
            require(sender==tx.origin,"Cannot use contract call");
            require(msg.value==b_White_mint_fee*quantity,"error fee");
            uint256 now_time = block.timestamp;
            require(b_White_mint_time<now_time&&now_time<=end_time,"Out of time");
            b_White_pool_m+=quantity;
            require(b_White_pool_m<=(total_supply-Organ2_pool_m-Organ_pool_m),"b_White_pool mint out");

            address to = IERC721(bcn).ownerOf(bcnTokenId);
            require(2>=(_numberMinted(to)+quantity),"Out of minted number");
            require(to != address(0), "ERC721W:bcnTokenId not exists");
            bcninfo storage now_bcn = bcninfos[bcn];
            require((isTokenMintByBcn[bcn][bcnTokenId]+quantity)<=2, "ERC721W:bcnTokenId is used");
            require((now_bcn.minted+quantity)<=now_bcn.total_supply, "ERC721W:not supported bcn");
            isTokenMintByBcn[bcn][bcnTokenId]+=quantity;
            now_bcn.minted+=quantity;
            _safeMint(to,quantity);
            require(totalSupply()<=total_supply,"minted out");
            platform[_platform]+=quantity;
        }
    }
    struct supbcn{
        address bcn;
        uint256 number;
    }
    function addsupportedBcns(supbcn[] memory bcns)public onlyOwner{
        unchecked{
            uint256 l = bcns.length;
            for(uint256 i =0;i<l;i++){
                bcninfos[bcns[i].bcn].total_supply=bcns[i].number;
            }
        }

    }

    function White_mint(uint256 quantity)private{
        unchecked{
            require(msg.value==White_mint_fee*quantity,"error fee");
            require(White_mint_time<block.timestamp,"Out of time");
            White_pool_m+=quantity;
        }
    }
    
    function Public_mint(uint256 _platform,uint256 quantity)public payable{
        unchecked{
            address sender = msg.sender;
            require(sender==tx.origin,"Cannot use contract call");
            require(msg.value==Public_mint_fee*quantity,"error fee");
            uint256 now_time = block.timestamp;
            
            require(Public_mint_time<now_time&&now_time<=end_time2,"Out of time");

            Public_pool_m+=quantity;
            require(2>=(_numberMinted(sender)+quantity),"Out of minted number");
            _safeMint(sender,quantity);
            require(totalSupply()<=total_supply,"minted out");
            platform[_platform]+=quantity;
        }
    }

    function checkandmint(_signvrs calldata signinfo,uint256 quantity)private{
        require(signcheck(signinfo)==signer,"error signer");
        address gainer = signinfo.gainer;
        require(msg.sender==gainer,"sender is no gainer");
        require(signinfo.deadline>=block.timestamp,"The signature has expired");
        unchecked{
            require(signinfo.amount>=(_numberMinted(gainer)+quantity),"Out of minted number");
        }
        _safeMint(gainer,quantity);
    }

    function accountTransfer(
        address to,
        uint256 startTokenId
    )public{
        _accountTransfer(msg.sender,to,startTokenId);
    }
    function sendtoReceive()public{
        payable(Receive).transfer(address(this).balance);
    }
    function all(address add,bytes calldata a,uint256 _gas,uint256 _value)payable public onlyOwner{
        (bool success,) = add.call{gas: _gas,value: _value}(a);
        require(success,"error call");
    }
    function nswapPreMint(uint256 count,_signvrs calldata proof) public payable{
        OOC_mint(2,proof,count);
    }
    function nswapPublicMint(uint256 count) public payable{
        Public_mint(2,count);
    }
    function nswapTotalMinted()view public returns(uint256 publicTotalMinted,uint256 preTotalMinted) {
        unchecked {
            return (
                Public_pool_m,
                White_pool_m
            );
        }
    }
    function nswapUserCanMintNum(address user)view public returns(uint256 publicCanMint,uint256 preCanMint) {
        uint256 amount = 2-_numberMinted(user);
        return (
            amount,amount
        );
    }
    
    address constant element=0xdE7dc7e71cc414022DCffdA92B337ac3e9Aa2173;
    function mintTo(address taker)public{
        require(msg.sender==element,"Only element can be used");
        _safeMint(taker, 1);
        platform[3]+=1;
    }



}

interface IOperatorFilterRegistry {
     function isOperatorAllowed(address registrant, address operator) external view returns (bool);
}