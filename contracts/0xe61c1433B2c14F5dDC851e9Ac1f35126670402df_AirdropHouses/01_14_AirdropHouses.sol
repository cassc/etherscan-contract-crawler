//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AirdropHouses is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // 0 - Not started, 100 - presale, 199 - presale finished, 200 - public sale, 299 - public sale finished
    uint256 private _saleMode = 0;

    mapping(uint256 => mapping(uint256 => bytes32)) private _merkleRoots;

    uint256 private _presalePrice = 15 * 10**16; // 0.15 eth
    uint256 private _publicSalePrice = 3 * 10**17; // 0.3 eth
    uint256 private _risingPrice = 5 * 10**16; // 0.05 eth
    uint256 private _priceLastChangeTime; // price last change time

    uint256 private _sheetsPerPrice = 500;

    uint256 private _batchDuration = 1 hours;

    uint256 private _publicMintLimit = 10;

    uint256 private _adminMintCount = 0;

    uint256 _startDate;

    bool _reveal = false;
    string private _strBaseTokenURI =
        "https://airdrophouses.mypinata.cloud/ipfs/QmbrBECWQEq71ty4DR9VvEGHr3bJkRv5TffdGp3Yyvq664/";
    string private _strRevealTokenURI;

    event MerkelRootChanged(uint256 _groupNum, bytes32 _merkleRoot);
    event SaleModeChanged(uint256 _saleMode);
    event RisingPriceChanged(uint256 _risingPrice);
    event SheetsPerPriceChanged(uint256 _sheetsPerPrice);
    event BatchDurationChanged(uint256 _batchDuration);
    event publicMintLimitChanged(uint256 _publicMintLimit);
    event StartDateChanged(uint256 startDate);
    event MintNFT(address indexed _to, uint256 _number);
    event BaseURIChanged(string newURI);
    event RevealURIChanged(string revealURI);
    event Reveal(bool reveal);

    constructor() ERC721("AirdropHouses #1", "ADH") {
        _merkleRoots[1][
            2
        ] = 0xe97e36fe94ab55299bd6fc71e5bb372d6c6ec3c025a12d0b3abd74262e29518b;
        _merkleRoots[1][
            4
        ] = 0xb90a60f9dfa68cbf0fcdbfb13d1ee139e231a442e0a5bc4ccae80f3f597d7277;
        _merkleRoots[1][
            10
        ] = 0x7050923a8778164983621a0ed6efcbc90fc20bfee2b8ee5e2b9550a6930acc1a;
        _merkleRoots[2][
            2
        ] = 0x6a1875ff2c5da58feeb1fcdeb70959a85adb77c3b0a175f712f330cbb9dafdb0;
        _merkleRoots[2][
            4
        ] = 0x0096fec144dba363af0fdc820b2d27ceabd6c5f39b83e02c5d33e30f9706efff;
        _merkleRoots[2][
            40
        ] = 0x4e3a914bcefca51773ee88728998a00722e923dfef44ca959a115bcf04081bf5;
        _merkleRoots[3][
            2
        ] = 0x72ce262ec9701bcef075296b04891c5a423c4aef8e67b3a7c3d2a11c9f8cbf2c;
        _merkleRoots[4][
            2
        ] = 0xdec189405e58dd32a45ea81ea92fd3801b3f57877801fc49d9ea66e749852c89;
    }

    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }

    function _baseURI() internal view override returns (string memory) {
        return _strBaseTokenURI;
    }

    function totalCount() public pure returns (uint256) {
        return 2000;
    }

    function getTimePast() public view returns (uint256) {
        return block.timestamp - _startDate;
    }

    // get count of sheets by past time and count of sheets that are sold out
    function getLeftPresale() public view returns (uint256) {
        uint256 normalCount = totalSupply() - _adminMintCount;
        if (normalCount >= _sheetsPerPrice * 3) return 0;
        uint256 batchNum = getUnlimitedBatchNum() / 3 + 1;
        return _sheetsPerPrice * batchNum - (normalCount % _sheetsPerPrice);
    }

    function getUnlimitedBatchNum() public view returns (uint256) {
        uint256 batch = getTimePast() / _batchDuration;
        return batch;
    }

    function getBatchNum() public view returns (uint256) {
        uint256 batch = getTimePast() / _batchDuration + 1;

        return batch >= 3 ? 3 : batch;
    }

    function price() public view returns (uint256) {
        if (_saleMode == 0) {
            return _presalePrice;
        }
        if (_saleMode == 199 || _saleMode == 200 || _saleMode == 299) {
            return _publicSalePrice;
        }
        uint256 normalCount = totalSupply() - _adminMintCount;
        uint256 countLevel = normalCount / _sheetsPerPrice;
        uint256 timeLevel = getTimePast() / _batchDuration / 3;
        uint256 max = countLevel > timeLevel ? countLevel : timeLevel;

        return _presalePrice + (max >= 2 ? 2 : max) * _risingPrice;
    }

    function safeMint(address to, uint256 number) public onlyOwner {
        for (uint256 i = 0; i < number; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(to, tokenId);
        }
        _adminMintCount += number;

        emit MintNFT(to, number);
        // _setTokenURI(tokenId, tokenURI(tokenId));
    }

    function _burn(uint256 _tokenId) internal override {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for non-existent token"
        );

        string memory baseURI = _baseURI();
        if (!_reveal) return baseURI;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        _strRevealTokenURI,
                        (tokenId + 1).toString(),
                        ".json"
                    )
                )
                : "";
    }

    function payToMint(address recipiant, uint256 number) public payable {
        require(
            (_saleMode == 200),
            _saleMode == 299
                ? "Public mint finished"
                : "Public mint not started yet!"
        );

        require(msg.value >= price() * number, "Money is not enough!");

        require(
            (number <= totalCount() - count()),
            "There are less sheets left than you want!"
        );

        require(
            (balanceOf(recipiant) + number <= _publicMintLimit),
            "You can NOT buy more than _publicMintLimit sheets!"
        );

        for (uint256 i = 0; i < number; i++) {
            uint256 newItemid = totalSupply();
            _mint(recipiant, newItemid);
        }

        emit MintNFT(recipiant, number);
    }

    function payToWhiteMint(
        address recipiant,
        uint256 limit,
        bytes32[] memory proof,
        uint256 number
    ) public payable {
        require(
            _saleMode == 100,
            _saleMode == 199 ? "Presale finished" : "Presale is not suppoted!"
        );

        require(
            totalSupply() < _sheetsPerPrice * 3,
            "Too late, all presale NFTs are sold out"
        );

        require(
            getTimePast() <= 9 * _batchDuration,
            "You are too late, presale is finished"
        ); // check if preSale is finished

        require(msg.value >= price() * number, "Money is not enough!");

        require(
            balanceOf(recipiant) + number <= limit,
            "Mint amount limitation!"
        );

        require(
            (getLeftPresale() >= number),
            "There aren't enough nfts for you in this batch!"
        );

        bool isWhitelisted = verifyWhitelist(
            getBatchNum(),
            _leaf(recipiant),
            limit,
            proof
        );

        require(isWhitelisted, "Sorry, You are not a whitelist member.");

        if (getLeftPresale() == number) {
            setLastPriceChangeTime(block.timestamp);
        }

        for (uint256 i = 0; i < number; i++) {
            uint256 newItemid = totalSupply();

            _mint(recipiant, newItemid);
        }

        emit MintNFT(recipiant, number);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function count() public view returns (uint256) {
        return totalSupply();
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function saleMode() external view returns (uint256) {
        return _saleMode;
    }

    function sheetsPerPrice() external view returns (uint256) {
        return _sheetsPerPrice;
    }

    function batchDuration() external view returns (uint256) {
        return _batchDuration;
    }

    function fromLastPriceTimeToNow() external view returns (uint256) {
        return block.timestamp - _priceLastChangeTime;
    }

    function verifyWhitelist(
        uint256 batchNum,
        bytes32 leaf,
        uint256 limit,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        for (uint256 i = 1; i <= batchNum; i++) {
            if (_merkleRoots[i][limit] == computedHash) {
                return true;
            }
        }
        return false;
        // return computedHash == _merkleRoots[batchNum][limit] ;
    }

    function setMerkleRoot(
        uint256 batchNum,
        uint256 groupNum,
        bytes32 merkleRoot
    ) external onlyOwner {
        _merkleRoots[batchNum][groupNum] = merkleRoot;

        emit MerkelRootChanged(groupNum, merkleRoot);
    }

    function setStartDate(uint256 lunchTime) private {
        _startDate = lunchTime;

        emit StartDateChanged(lunchTime);
    }

    function setLastPriceChangeTime(uint256 lastTime) private {
        _priceLastChangeTime = lastTime;
    }

    function setSaleMode(uint256 mode) external onlyOwner {
        _saleMode = mode;
        if (mode == 100) {
            setStartDate(block.timestamp);
            setLastPriceChangeTime(block.timestamp);
        }
        emit SaleModeChanged(mode);
    }

    function setRisingPrice(uint256 risingPrice) external onlyOwner {
        _risingPrice = risingPrice;

        emit RisingPriceChanged(risingPrice);
    }

    function setSheetsPerPrice(uint256 sheets) external onlyOwner {
        _sheetsPerPrice = sheets;

        emit SheetsPerPriceChanged(sheets);
    }

    function setTimePerBatch(uint256 duration) external onlyOwner {
        _batchDuration = duration;

        emit BatchDurationChanged(duration);
    }

    function setPublicMintLimit(uint256 publicMintLimit) external onlyOwner {
        _publicMintLimit = publicMintLimit;

        emit publicMintLimitChanged(publicMintLimit);
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        _strBaseTokenURI = newURI;
        emit BaseURIChanged(newURI);
    }

    function setRevealURI(string memory revealURI) external onlyOwner {
        _strRevealTokenURI = revealURI;
        emit RevealURIChanged(revealURI);
    }

    function setReveal(bool reveal) external onlyOwner {
        _reveal = reveal;
        emit Reveal(reveal);
    }
}