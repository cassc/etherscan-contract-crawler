pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract The313RABBIT is ERC721AQueryable, Ownable, ReentrancyGuard {
    mapping(uint256 => uint256) public status;

    mapping(uint256 => bool) public returned;

    mapping(uint256 => bool) public passUsed;

    mapping(address => uint256) public wlMined;

    mapping(address => uint256) public publicMined;

    string public baseURI;

    string public defaultURI;

    uint256 public sleepReturnTime;

    IERC20 public USDT;

    uint256 public returnUSDTAmount;

    IERC721Enumerable public littelMamiPASS;

    uint256 public publicPrice;

    uint256 public wlPrice;

    uint256 public PASSPrice;

    uint256 public maxSupply;

    bytes32 public wlRoot;

    uint256 public maxWlSupply;

    uint256 public maxPASSSupply;

    uint256 public wlNum;

    uint256 public PASSNum;

    uint256 public PASSStartTime;

    uint256 public PASSEndTime;

    uint256 public wlStartTime;

    uint256 public wlEndTime;

    uint256 public publicStartTime;

    uint256 public publicEndTime;

    uint256 public maxPublicMint;

    uint256 public maxWlMint;

    uint256 public partnerPrice;

    bytes32 public partnerRoot;

    bool public turnSleep;

    using Strings for uint256;

    event RemoveSleep(uint256 indexed tokenId);

    event ToggleSleep(uint256 indexed tokenId, uint256 startTime);

    constructor() public ERC721A("313 RABBIT", "313 RABBIT") {
        publicPrice = 0.3 ether;
        wlPrice = 0.27 ether;
        partnerPrice = 0.24 ether;
        PASSPrice = 0.24 ether;
        maxSupply = 666;
        maxWlSupply = 166;
        maxPASSSupply = 300;
        maxPublicMint = 2;
        maxWlMint = 1;
        PASSStartTime = 1664713800;
        PASSEndTime = 1664886600;
        wlStartTime = 1664713800;
        wlEndTime = 1664886600;
        publicStartTime = 1664886600;
        publicEndTime = 1665318600;
        littelMamiPASS = IERC721Enumerable(
            0x6F555695B057c081F0A0f7c1d1a854EF7e2FEAa2
        );
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        returnUSDTAmount = 0;
        sleepReturnTime = 60 days;
        defaultURI = "ipfs://bafkreidxgd6vbljc5s436zxub3iarcntpzzayiicotzvkevkrn4tcdi52u";
    }

    function adminMint(address _address, uint256 _num) external onlyOwner {
        mint(_address, _num);
    }

    function adminMintBatch(
        address[] calldata _address,
        uint256[] calldata _num
    ) external onlyOwner {
        require(_address.length == _num.length);
        for (uint256 i = 0; i < _address.length; i++) {
            mint(_address[i], _num[i]);
        }
    }

    function withdrawETH(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken(IERC20 _token, address _to) external onlyOwner {
        _token.transfer(_to, _token.balanceOf(address(this)));
    }

    function setSleep(uint256 _sleepReturnTime, uint256 _returnUSDTAmount)
        external
        onlyOwner
    {
        sleepReturnTime = _sleepReturnTime;
        returnUSDTAmount = _returnUSDTAmount;
    }

    function setReturnAmount(uint256 _returnUSDTAmount) external onlyOwner {
        returnUSDTAmount = _returnUSDTAmount;
    }

    function setContract(IERC721Enumerable _littelMamiPASS, IERC20 _USDT)
        external
        onlyOwner
    {
        littelMamiPASS = _littelMamiPASS;
        USDT = _USDT;
    }

    function setMaxMint(uint256 _maxPublicMint, uint256 _maxWlMint)
        external
        onlyOwner
    {
        maxPublicMint = _maxPublicMint;
        maxWlMint = _maxWlMint;
    }

    function setRoot(bytes32 _wlRoot, bytes32 _partnerRoot) external onlyOwner {
        wlRoot = _wlRoot;
        partnerRoot = _partnerRoot;
    }

    function setMaxSupply(uint256 _maxPASSSupply, uint256 _maxWlSupply)
        external
        onlyOwner
    {
        maxPASSSupply = _maxPASSSupply;
        maxWlSupply = _maxWlSupply;
    }

    function setTime(
        uint256 _PASSStartTime,
        uint256 _PASSEndTime,
        uint256 _wlStartTime,
        uint256 _wlEndTime,
        uint256 _publicStartTime,
        uint256 _publicEndTime
    ) external onlyOwner {
        PASSStartTime = _PASSStartTime;
        PASSEndTime = _PASSEndTime;
        wlStartTime = _wlStartTime;
        wlEndTime = _wlEndTime;
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
    }

    function setPrice(
        uint256 _publicPrice,
        uint256 _wlPrice,
        uint256 _PASSPrice,
        uint256 _partnerPrice
    ) external onlyOwner {
        publicPrice = _publicPrice;
        wlPrice = _wlPrice;
        PASSPrice = _PASSPrice;
        partnerPrice = _partnerPrice;
    }

    //If anyone is sleeping and hanging a low-priced floor, the sleep will be forcibly canceled
    function removeSleep(uint256 _tokenId) external onlyOwner {
        status[_tokenId] = 0;
        emit RemoveSleep(_tokenId);
    }

    function turnToggleSleep(bool _turnSleep) external onlyOwner {
        turnSleep = _turnSleep;
    }

    function toggleSleep(uint256 _tokenId) external {
        require(
            ownerOf(_tokenId) == _msgSender(),
            "313 RABBIT : Not the owner"
        );
        require(turnSleep, "313 RABBIT : Sleep function is not open yet");
        if (status[_tokenId] == 0) {
            status[_tokenId] = block.timestamp;
            emit ToggleSleep(_tokenId, block.timestamp);
        } else {
            if (
                block.timestamp - status[_tokenId] >= sleepReturnTime &&
                !returned[_tokenId]
            ) {
                USDT.transfer(_msgSender(), returnUSDTAmount);
                returned[_tokenId] = true;
            }
            status[_tokenId] = 0;
            emit ToggleSleep(_tokenId, 0);
        }
    }

    function PASSMint(uint256 _num) external payable {
        require(
            block.timestamp >= PASSStartTime && block.timestamp <= PASSEndTime,
            "313 RABBIT : Not at mint time"
        );
        require(
            msg.value >= PASSPrice * _num,
            "313 RABBIT : Too little ether sent"
        );

        uint256 holdNum = littelMamiPASS.balanceOf(_msgSender());
        require(holdNum > 0, "313 RABBIT : HoldNum is zero");
        require(
            _num > 0 && _num <= holdNum,
            "313 RABBIT : Num must greater than 0 and lower than holdNum"
        );
        uint256 mintNum = 0;
        for (uint256 i = 0; i < holdNum; i++) {
            if (mintNum == _num) break;
            uint256 tokenId = littelMamiPASS.tokenOfOwnerByIndex(
                _msgSender(),
                i
            );
            if (!passUsed[tokenId]) {
                passUsed[tokenId] = true;
                mintNum++;
            }
        }
        require(
            mintNum == _num,
            "313 RABBIT : Exceeds the maximum eligible PASS mint"
        );
        require(
            PASSNum + mintNum <= maxPASSSupply,
            "313 RABBIT : Exceeds the maximum PASS supply number"
        );
        mint(_msgSender(), mintNum);
        PASSNum += mintNum;
    }

    function partnerMint(uint256 _num, bytes32[] memory _proof)
        external
        payable
    {
        require(
            block.timestamp >= wlStartTime && block.timestamp <= wlEndTime,
            "313 RABBIT : Not at mint time"
        );
        require(
            msg.value >= partnerPrice * _num,
            "313 RABBIT : Too little ether sent"
        );
        require(
            wlMined[_msgSender()] + _num <= maxWlMint,
            "313 RABBIT : Mint exceeds the maximum wl number"
        );
        require(
            _num > 0 && _num <= maxWlMint,
            "313 RABBIT : Num must greater than 0 and lower than maxWlMint"
        );
        require(
            wlNum + _num <= maxWlSupply,
            "313 RABBIT : Exceeds the maximum PASS supply number"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_proof, partnerRoot, leaf),
            "313 RABBIT : Merkle verification failed"
        );
        mint(_msgSender(), _num);
        wlNum += _num;
        wlMined[_msgSender()] += _num;
    }

    function wlMint(uint256 _num, bytes32[] memory _proof) external payable {
        require(
            block.timestamp >= wlStartTime && block.timestamp <= wlEndTime,
            "313 RABBIT : Not at mint time"
        );
        require(
            msg.value >= wlPrice * _num,
            "313 RABBIT : Too little ether sent"
        );
        require(
            wlMined[_msgSender()] + _num <= maxWlMint,
            "313 RABBIT : Mint exceeds the maximum wl number"
        );
        require(
            _num > 0 && _num <= maxWlMint,
            "313 RABBIT : Num must greater than 0 and lower than maxWlMint"
        );
        require(
            wlNum + _num <= maxWlSupply,
            "313 RABBIT : Exceeds the maximum PASS supply number"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_proof, wlRoot, leaf),
            "313 RABBIT : Merkle verification failed"
        );
        mint(_msgSender(), _num);
        wlNum += _num;
        wlMined[_msgSender()] += _num;
    }

    function publicMint(uint256 _num) external payable {
        require(
            block.timestamp >= publicStartTime &&
                block.timestamp <= publicEndTime,
            "313 RABBIT : Not at mint time"
        );
        require(
            publicMined[_msgSender()] + _num <= maxPublicMint,
            "313 RABBIT : Mint exceeds the maximum public number"
        );
        require(
            _num > 0 && _num <= maxPublicMint,
            "313 RABBIT : Num must greater than 0 and lower than maxPublicMint"
        );
        require(
            msg.value >= publicPrice * _num,
            "313 RABBIT : Too little ether sent"
        );
        mint(_msgSender(), _num);
        publicMined[_msgSender()] += _num;
    }

    function mint(address _address, uint256 _num) internal nonReentrant {
        require(
            totalSupply() + _num <= maxSupply,
            "313 RABBIT : Exceeds the maximum supply number"
        );
        _mint(_address, _num);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
            require(status[startTokenId] == 0, "313 RABBIT : Sleepping");
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory imageURI = bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
            : defaultURI;

        return imageURI;
    }
}