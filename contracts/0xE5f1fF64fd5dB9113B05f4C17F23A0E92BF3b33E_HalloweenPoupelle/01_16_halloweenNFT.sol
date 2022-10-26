// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interface/ITokenURI.sol";
import "./interface/IHalloweenNFT.sol";
import "./ERC721AntiScam/extensions/ERC721AntiScamControl.sol";

contract HalloweenPoupelle is ERC721AntiScamControl, IHalloweenNFT, ReentrancyGuard {

    using Strings for uint256;
    uint256 public constant maxSupply = 10000;
    uint256 public constant mintPrice = 0.01 ether;
    uint256 public constant publicMaxMint = 10;
    uint256 public VIPSaleStartTime = 1667120400; //2022-10-30 18:00:00 +09:00
    uint256 public whiteListSaleStartTime = 1667206800; //2022-10-31 18:00:00 +09:00
    uint256 public addWhiteListSaleStartTime = 1667221200; //2022-10-31 22:00:00 +09:00
    uint256 public publicSaleStartTime = 1667224800;//2022-10-31 23:00:00 +09:00
    address public withdrawAddress = 0x4262098A3a607b263c414F3D16ABf2cc8C1F3711;
    bytes32 public whiteListSaleRoot;
    bytes32 public addWhiteListSaleRoot;
    string public baseExtension = '.json';
    string public baseURI = 'https://metadata.ctdao.io/hwp/';
    ITokenURI public tokenuri;
    mapping(address => uint256) public VIPList;

    constructor() ERC721A("Halloween Poupelle", "HWP") {
        _grantLockerRole(msg.sender);
        _grantLockerRole(withdrawAddress);
        contractLockStatus = LockStatus.UnLock;
        _safeMint(msg.sender, 100);
    }

   function wlMint(uint64 _saleType, uint256 _mintCount, uint256 _maxCount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        bytes32 root;
        if(_saleType == 0){
            // wl sale
            require(whiteListSaleStartTime <= block.timestamp , "can not mint, is not white sale");
            root = whiteListSaleRoot;
        }else if(_saleType == 1){
            //add wl sale
            require(addWhiteListSaleStartTime <= block.timestamp , "can not mint, is not private sale");
            root = addWhiteListSaleRoot;
        }else{
            require( false, 'can not mint, invalid value');
        }

        require(_mintCount > 0, 'can not mint, invalid value');
        require(totalSupply() + _mintCount <= maxSupply  , 'can not mint, over max size');
        require(tx.origin == msg.sender, "not eoa");
        require(msg.value == mintPrice * _mintCount, "not enough ETH");

        uint64 mintedCount = _getMintedCount(msg.sender,_saleType);

        require(
            _maxCount >=
                _mintCount +
                uint256(mintedCount),
            "exceeded allocated count"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender,_maxCount));
        require(
            MerkleProof.verify(
                _merkleProof,
                root,
                leaf
            ),
            "MerkleProof: Invalid proof."
        );
        _setMintedCount(msg.sender, _saleType, mintedCount + uint64(_mintCount));
        _safeMint(msg.sender, _mintCount);
    }

    function publicMint(uint256 _mintCount)
        external
        payable
        nonReentrant
    {
        require(publicSaleStartTime <= block.timestamp , "can not mint, is not public sale");
        require(_mintCount > 0, 'can not mint, invalid value');
        require(_mintCount <= publicMaxMint, 'can not mint, invalid value');
        require(totalSupply() + _mintCount <= maxSupply, 'can not mint, over max size');
        require(tx.origin == msg.sender, "not eoa");
        require(msg.value == mintPrice * _mintCount, "not enough ETH");

        _safeMint(msg.sender, _mintCount);
    }

    function mint(uint256 _mintCount)
        external
        payable
        nonReentrant
    {
        require(VIPSaleStartTime <= block.timestamp , "can not mint, is not VIP sale");
        require(_mintCount > 0, 'can not mint, invalid value');
        require(totalSupply() + _mintCount <= maxSupply, 'can not mint, over max size');
        require(tx.origin == msg.sender, "not eoa");
        require(msg.value == mintPrice * _mintCount, "not enough ETH");

        uint64 mintedCount = _getMintedCount(msg.sender,2);

        require(
            VIPList[msg.sender] >=
                _mintCount +
                uint256(mintedCount),
            "exceeded allocated count"
        );

        _setMintedCount(msg.sender, 2, mintedCount + uint64(_mintCount));
        _safeMint(msg.sender, _mintCount);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override (ERC721A)
        returns (string memory)
    {
        if(address(tokenuri) == address(0))
        {
            return string(abi.encodePacked(ERC721A.tokenURI(_tokenId), baseExtension));
        }else{
            // Full-on chain support
            return tokenuri.tokenURI_future(_tokenId);
        }
    }

    function getMintedCount(address _address, uint64 _index)
        external
        view
        returns (uint64)
    {
        return _getMintedCount(_address,_index);
    }

    //
    // onlyOwner functions
    //
    function setBaseURI(string memory _URI)
        external
        onlyOwner
    {
        baseURI = _URI;
    }

    function setBaseExtension(string memory _extension)
        external
        onlyOwner
    {
        baseExtension = _extension;
    }

    function setWhiteListRoot(uint64 _saleType, bytes32 _root)
        external
        onlyOwner
    {
        if(_saleType == 0){
            // wl sale
            whiteListSaleRoot = _root;
        }else if(_saleType == 1){
            //add wl sale
            addWhiteListSaleRoot = _root;
        }
    }

    function setSaleStartTime(uint64 _saleType, uint256 _time)
        external
        onlyOwner
    {
        if(_saleType == 0){
            // wl sale
            whiteListSaleStartTime = _time;
        }else if(_saleType == 1){
            //add wl sale
            addWhiteListSaleStartTime = _time;
        }else if(_saleType == 2){
            //VIP sale
            VIPSaleStartTime = _time;
        }else if(_saleType == 3){
            //VIP sale
            publicSaleStartTime = _time;
        }
    }

    function setVIPList(address[] calldata _address, uint256[] calldata _value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _address.length; i++) {
            VIPList[_address[i]] = _value[i];
        }
    }

    function setWithdrawAddress(address _address)
        external
        onlyOwner
    {
        withdrawAddress = _address;
    }

    function setTokenURI(ITokenURI _tokenuri)
        external
        onlyOwner
    {
        tokenuri = _tokenuri;
    }

    function withdraw()
        external
        onlyOwner
    {
        (bool result, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(result, "transfer failed");
    }

    //
    // internal functions
    //
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }
    
    function _startTokenId()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return 1;
    }

    // 00..15:WL 16..31:PRE 32..47:VIP 48..63:unused
    function _getMintedCount(address _owner, uint64 _index)
        internal
        view
        returns (uint64)
    {
        uint64 _aux = _getAux(_owner);
        uint64 _val = _aux & uint64(0xFFFF);
        if(_index > 0){
            _val = (_aux >> (16 * _index)) & uint64(0xFFFF);
        }
        return _val;       
    }

    // 00..15:WL 16..31:PRE 32..47:VIP 48..63:unused
    function _setMintedCount(address _owner, uint64 _index , uint64 _value)
        internal
    {
        uint64 _aux = _getAux(_owner);
        uint64 _maskdata = _aux & (~uint64(0xFFFF));
        uint64 _setvalue = _value;
        if(_index > 0){
            _maskdata = _aux & ~(uint64(0xFFFF) << (16 * _index));
            _setvalue = _setvalue << (16 * _index);
        }
        _setAux(_owner, (_maskdata | _setvalue));
    }

    //
    // for ERC721AntiScam
    //
    function setTokenLockOfTokenOwner(uint256[] calldata tokenIds, LockStatus[] calldata status) external {
        require(tokenIds.length == status.length, 'invalid value');
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address tokenOwner = ownerOf(tokenIds[i]);
            require( tokenOwner == msg.sender);
            _lock(status[i],tokenIds[i]);
        }
    }

    function setWalletLockOfWalletOwner(LockStatus status) external {
        _setWalletLock(msg.sender, status);
        emit WalletLock(msg.sender, msg.sender, uint(status));
    }

    function setWalletCALLevelOfWalletOwner(uint256 level) external {
        _setWalletCALLevel(msg.sender, level);
    }

    // return value: tokenid * 100 + tokenLockStatus * 10 + walletLockStatus;
    // example: tokenId=5678, tokenLockStatus=UnLock(1), walletLockStatus=UnSet(0), return=567810
    // maxSupply=10k,so it's not a problem.
    function tokensAndLocksOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256 walletLockStatus = uint256(_walletLockStatus[owner]);
            uint256[] memory returnValues = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    returnValues[tokenIdsIdx++] = i * 100 + uint256(_tokenLockStatus[i]) * 10 + walletLockStatus;
                }
            }
            return returnValues;
        }
    }

    //
    // LockerRole for ERC721AntiScamControl
    //
    function grantLockerRole(address _candidate) external onlyOwner {
        _grantLockerRole(_candidate);
    }

    function revokeLockerRole(address _candidate) external onlyOwner {
        _revokeLockerRole(_candidate);
    }
}