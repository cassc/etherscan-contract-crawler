// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GroundUp721A is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    enum Status {
        TeamMint, //团队mint阶段
        FirstcomeMint, //先到先得白名单阶段
        PublicSale, //必中白名单阶段
        Finished //结束,或者暂停
    }
    Status public status;
    bytes32 public merkleRoot;
    mapping(address => uint256) public Firstcome; //先到先得白名单,买家=>已经获得NFT的数量
    mapping(address => uint256) public Public; //必得白名单,买家=>已经获得NFT的数量
    string public uriPrefix = ""; //前缀
    string public uriSuffix = ".json"; //后缀
    string public hiddenMetadataUri =
        "https://genesis-groundupstudios.mypinata.cloud/ipfs/QmbVR67Lsm7s6Shks9ZoVKEkYDaZT5VVMAQus6115h1mjt/"; //初始化URI

    uint256 public cost = 0.02 ether; //价格
    uint256 public maxSupply = 2500; //总数
    uint256 public maxFirstcomeMintAmountPerTx = 2; //先到先得阶段,每次最大mint数量
    uint256 public minternumber = 3; //买家当前允许拥有NFT的最大值
    uint256 public maxMintAmountPerTx = 1; //必中阶段,每次最大mint数量

    bool public revealed = false; //开图开关

    constructor() ERC721A("GroundUp Studios", "GUS") {
        setStatus(Status.TeamMint); //启动,设置状态为teamMint,然后调用mintForAddress(300,ox....)
    }

    function Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
    {
        require(
            status != Status.Finished && status != Status.TeamMint,
            "The whitelist sale is not enabled!"
        ); //先判断是不是finish和teammint阶段
        require(msg.value >= cost * _mintAmount, "Insufficient funds!"); //看他的余额对不对
        require(_mintAmount > 0, "Invalid mint amount!"); //购买的数量是不是大于0
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        ); //购买的数量是不是大于库存
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        ); //默克尔树验证白名单
        //判断是先到先得状态还是必中状态
        if (status == Status.FirstcomeMint) {
            //先到先得状态
            require(
                _mintAmount <= maxFirstcomeMintAmountPerTx,
                "Invalid mint amount!"
            ); //判断mint数量是不是小于等于允许的单次最大购买数量
            require(
                Firstcome[msg.sender] < maxFirstcomeMintAmountPerTx,
                "Address already claimed!"
            ); //判断用户拥有数量是不是小于规定数,当前状态拥有数量等于单次最大允许购买数量,所以用了同一个变量maxFirstcomeMintAmountPerTx
            Firstcome[msg.sender] += _mintAmount; //拥有数量+1
            //他的需求是  先到先得阶段.可以一次性买一个.也可以一次性买两个.也可以买了一个再买一个.但是先到先得阶段,最多买两个.
            //这里有一个问题,如果用户买了,马上转出去.再来买会不会有问题.
        } else {
            //必中阶段
            require(_mintAmount <= maxMintAmountPerTx, "Invalid mint amount!"); //判断mint数量是不是小于等于允许的单次最大购买数量
            require(
                Public[msg.sender] + Firstcome[msg.sender] <
                    maxMintAmountPerTx + maxFirstcomeMintAmountPerTx,
                "Address already claimed!"
            ); //判断用户拥有数量是不是小于规定数量(这里因为必中白名单和先到先得白名单可以重复,所以我就让他们相加,结果为3)
            //需求是先到先得白名单mint结束.进入这个阶段,不管他先到先得有没有mint过,mint了几个.这一轮,他只能买一次,一次只能买一个.
            Public[msg.sender] += _mintAmount; //拥有数量+1
        }
        _safeMint(_msgSender(), _mintAmount); //MINT
    }

    function mintForAddress(
        uint256 _mintAmount,
        address _receiver //暴力mint
    ) public onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        ); //购买的数量是不是大于库存
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(
        address _owner //查询这个地址下有哪几个nft,返回NFT 的token
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return
                string(
                    abi.encodePacked(hiddenMetadataUri, _tokenId.toString())
                );
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setStatus(Status _status) public onlyOwner {
        status = _status;
    }

    function Merkletest(
        address add,
        bytes32 merkleRoot,
        bytes32[] calldata _merkleProof
    ) public onlyOwner returns(string memory) {
        bytes32 leaf = keccak256(abi.encodePacked(add));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        return "OK";
    }
}