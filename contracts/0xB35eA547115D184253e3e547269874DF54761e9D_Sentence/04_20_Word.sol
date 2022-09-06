// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./common/EnumerableMap.sol";
import "./common/Descriptor.sol";

contract Word is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    // lib
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using Strings for uint256;
    using ECDSA for bytes32;

    // struct

    // constant
    uint256 public constant mintPrice = 0.1 ether;
    uint256 public constant sentenceWordPrice = 0.01 ether;
    uint256 public constant publicMintDate = 1662408000;

    uint256 public constant whitelistMintMaxNum = 10;
    uint256[] public whitelistMintPrize = [0.08 ether, 0.04 ether, 0.01 ether];
    uint256[] public whitelistMintDate = [1662321600, 1662235200, 1662148800];

    // storage
    uint256 private _counter;

    uint256 public maxSupply;

    mapping(bytes32 => uint256) public wordHash2TokenID;
    mapping(uint256 => bytes32) public wordTokenID2Hash;
    mapping(bytes32 => string) public wordHash2String;

    EnumerableMap.Bytes32ToUintMap private _lockWord;

    string private _basePath;

    uint256 public mintRevenue;

    address public senteceAddress;
    mapping(bytes32 => uint256[]) public sentenceMintTokenIDs;
    mapping(uint256 => uint256) public sentenceMintRevenue;

    address public mineAddress;

    uint256 public feePer = 0;

    mapping(address => uint256) public whitelistMintNum;
    address public signAddress;

    // event
    event ClaimSentenceRevenue(uint256 tokenID);
    event FeePerChange(uint256 newFee);

    constructor(address _mineAddress, address _signAddress) ERC721("Word", "WD") {
        mineAddress = _mineAddress;
        signAddress = _signAddress;
    }

    function setSignAddress(address _signAddress) public onlyOwner{
        signAddress = _signAddress;
    }

    function setSentenceAddress(address addr) public onlyOwner {
        senteceAddress = addr;
    }

    function setMineAddress(address addr) public onlyOwner{
        mineAddress = addr;
    }

    function setMaxSupply(uint256 num) public onlyOwner {
        maxSupply = num;
    }

    function setFeePer(uint256 per) public onlyOwner{
        require(per <= 1000, "per overflow");
        feePer = per;
        emit FeePerChange(per);
    }

    function updateLockWord(string[] memory words, uint256[] memory wordDates)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < words.length; ++i) {
            string memory tempStr = toLowerCase(words[i]);
            bytes32 tempHash = keccak256(bytes(tempStr));
            _lockWord.set(tempHash, wordDates[i]);
            wordHash2String[tempHash] = tempStr;
        }
    }

    function getAllLockWord()
        public
        view
        returns (string[] memory, uint256[] memory)
    {
        uint256 len = _lockWord.length();
        string[] memory words = new string[](len);
        uint256[] memory dates = new uint256[](len);
        bytes32 tempHash;
        for (uint256 i = 0; i < len; ++i) {
            (tempHash, dates[i]) = _lockWord.at(i);
            words[i] = wordHash2String[tempHash];
        }

        return (words, dates);
    }

    function toLowerCase(string memory word)
        public
        pure
        returns (string memory)
    {
        unchecked {
            bytes memory s = bytes(word);
            for (uint256 i = 0; i < s.length; ++i) {
                uint8 temp = uint8(s[i]);
                require(
                    (temp >= 0x30 && temp <= 0x39) ||
                        (temp >= 0x41 && temp <= 0x5a) ||
                        (temp >= 0x61 && temp <= 0x7a),
                    "word contains illegal characters!"
                );
                if (temp >= 0x41 && temp <= 0x5a) {
                    s[i] = bytes1(temp + 32);
                }
            }
        }

        return word;
    }

    function whitelistMint(string memory word, uint256 level, bytes calldata sig) public payable{
        require(level < whitelistMintDate.length, "level error");
        require(block.timestamp >= whitelistMintDate[level], "mint date is not enabled");
        require(whitelistMintNum[msg.sender] < whitelistMintMaxNum, "mint num limit");
        require(block.timestamp < publicMintDate, "public mint enabled");

        bytes32 hash = keccak256(abi.encode(msg.sender, level, address(this)));
        require(hash.recover(sig) == signAddress, "sign error");
        whitelistMintNum[msg.sender]++;
        _mint(word, whitelistMintPrize[level]);
    }

    function mint(string memory word) public payable {
        require(block.timestamp >= publicMintDate, "mint date is not enabled");
        _mint(word, mintPrice);
    }

    function _mint(string memory word, uint256 price) private {
        require(
            maxSupply <= 0 || totalSupply() < maxSupply,
            "max supply limit"
        );
        word = toLowerCase(word);
        bytes memory s = bytes(word);
        bytes32 wordHash = keccak256(s);

        require(s.length > 0 && s.length <= 18, "word length illegal!");
        require(msg.value == price, "eth illegal!");
        require(_exists(wordHash2TokenID[wordHash]) == false, "word exist!");
        (bool suc, uint256 date) = _lockWord.tryGet(wordHash);
        if (suc) {
            require(date > 0 && block.timestamp >= date, "word locked!");
        }
        unchecked {
            mintRevenue += msg.value;
            _counter++;
        }
        _mint(msg.sender, _counter);
        wordHash2TokenID[wordHash] = _counter;
        wordHash2String[wordHash] = word;
        wordTokenID2Hash[_counter] = wordHash;
    }

    function sentenceMint(uint256 tokenID, string[] memory words)
        public
        payable
    {
        require(msg.sender == senteceAddress, "sentence address error!");
        unchecked {
            uint256 price = 0;
            uint256 mineAmount = 0;
            uint256 feeRevenueUnit = (sentenceWordPrice / 10000) * feePer;
            uint256 priceUnit = sentenceWordPrice - feeRevenueUnit;
            uint256 feeRevenue = 0;
            string memory word;
            bytes32 wordHash;
            uint256 wordTokenID;
            bytes32[] memory wordHashs = new bytes32[](words.length);
            for (uint256 i = 0; i < words.length; ++i) {
                word = toLowerCase(words[i]);
                wordHash = keccak256(bytes(word));

                bool find = false;
                for (uint256 j = 0; j < i; ++j) {
                    if (wordHash == wordHashs[j]) {
                        find = true;
                        continue;
                    }
                }
                if (find) {
                    continue;
                }
                wordHashs[i] = wordHash;

                if (!isWordLock(wordHash)) {
                    wordTokenID = wordHash2TokenID[wordHash];
                    price += sentenceWordPrice;
                    feeRevenue += feeRevenueUnit;
                    if (wordTokenID != 0){
                        sentenceMintRevenue[wordTokenID] += priceUnit;
                    }
                    else{
                        mineAmount += priceUnit;
                    }
                }

                sentenceMintTokenIDs[wordHash].push(tokenID);
            }

            mintRevenue += feeRevenue;

            require(msg.value == price, "eth not enough");
            if (mineAmount > 0){
                _sendEth(mineAddress, mineAmount);
            }
        }
    }

    function sentenceMintNum(bytes32 wordHash) public view returns (uint256){
        return sentenceMintTokenIDs[wordHash].length;
    }

    function queryTokenID(string memory word) public view returns (uint256) {
        return wordHash2TokenID[keccak256(bytes(toLowerCase(word)))];
    }

    function queryWord(uint256 tokenID) public view returns (string memory) {
        return wordHash2String[wordTokenID2Hash[tokenID]];
    }

    function isWordLock(bytes32 wordHash) public view returns (bool) {
        if (_exists(wordHash2TokenID[wordHash])) {
            return false;
        }
        (bool suc, uint256 date) = _lockWord.tryGet(wordHash);
        if (suc && (date == 0 || block.timestamp < date)) {
            return true;
        }

        return false;
    }

    function getWordHash(string memory word) public pure returns (bytes32) {
        return keccak256(bytes(toLowerCase(word)));
    }

    function ownerClaimMintRevenue() public onlyOwner nonReentrant {
        _sendEth(msg.sender, mintRevenue);
        mintRevenue = 0;
    }

    function claimSentenceRevenue(uint256[] memory tokenIDs)
        public
        nonReentrant
    {
        unchecked {
            uint256 amount = 0;
            uint256 tokenID;
            for (uint256 i = 0; i < tokenIDs.length; ++i) {
                tokenID = tokenIDs[i];
                require(ownerOf(tokenID) == msg.sender, "not owned!");
                amount += sentenceMintRevenue[tokenID];
                sentenceMintRevenue[tokenID] = 0;

                emit ClaimSentenceRevenue(tokenID);
            }
            _sendEth(msg.sender, amount);
        }
    }

    function _sendEth(address to, uint256 value) private{
        (bool suc,) = to.call{value:value}("");
        require(suc, "sendEth fail");
    }

    // url
    function setBaseURI(string calldata path) public onlyOwner {
        _basePath = path;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (bytes(_basePath).length > 0) {
            return string(abi.encodePacked(_basePath, tokenId.toString()));
        }

        return Descriptor.GetWordDesc(tokenId, queryWord(tokenId));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}