// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBatt {
    function balanceOf(address owner) external view returns (uint);
    function burn(address account, uint amount) external;
}

interface IForest {
    function randomHunterOwner(uint256 seed) external returns (address);
    function addTokensToStake(address account, uint16[] calldata tokenIds) external;
}

interface IRandomNumGenerator {
    function getRandomNumber(uint _seed, uint _limit) external view returns (uint16);
}

interface IFreeFromUpTo {
    function freeUpTo(uint256 value) external returns (uint256);
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

contract MetaMoose is ERC721, Ownable {
    string private baseURI;

    uint public maxMint = 10;
    uint public mintPrice = 0.088 ether;
    mapping(uint16 => uint) public phasePrice;

    uint public tokensMinted;
    uint16 public phase;
    uint16 public hunterStolen;
    uint16 public harvesterStolen;
    uint16 public hunterMinted;

    uint16[] private _availableTokens;

    mapping(uint16 => bool) private _isHunter;

    bool public publicSaleIsEnabled;
    bool public privateSaleIsEnabled;

    IForest public forest;
    IBatt public batt;
    IRandomNumGenerator randomGen;

    address private constant fundWallet = 0xA3f447f39201957c3F904E20a8F116b9EE28F993;
    address private constant admin = 0x719deC089084C98d505695A2cdC82238024D0bAD;

    string public constant CONTRACT_NAME = "Metamoose Contract";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant MINT_TYPEHASH = keccak256("Mint(address user,uint256 num)");

    bool public burnEnabled;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    event TokenStolen(address owner, uint16 tokenId, address thief);
    event Lucky(address owner, uint16 tokenId);
    event PrivateMint(address user, uint256 num);

    constructor() ERC721("Meta Moose", "METAMOOSE") {
        _safeMint(msg.sender, 0);
        tokensMinted += 1;

        // Set default price for each phase
        phasePrice[1] = 100000 ether;
        phasePrice[2] = 220000 ether;
        phasePrice[3] = 480000 ether;
    }

    modifier discountCHI(uint256 chiAmount) {
        if (chiAmount > 0) {
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            uint256 minAmount = Math.min((gasSpent + 14154) / 41947, chiAmount);
            chi.freeUpTo(minAmount);
        } else {
            _;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function isHunter(uint16 id) public view returns (bool) {
        return _isHunter[id];
    }

    function availableTokens() public view onlyOwner returns (uint256, uint16[] memory) {
        return (_availableTokens.length, _availableTokens);
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function totalSupply() external view returns (uint) {
        return tokensMinted;
    }

    function transferFrom(address from, address to, uint tokenId) public virtual override {
        if (_msgSender() != address(forest))
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }


    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMintPrice(uint _price) external onlyOwner {
        mintPrice = _price;
    }

    function setPhasePrice(uint price1, uint price2, uint price3) external onlyOwner {
        phasePrice[1] = price1;
        phasePrice[2] = price2;
        phasePrice[3] = price3;
    }

    function setMaxMint(uint _maxValue) external onlyOwner {
        maxMint = _maxValue;
    }

    function setPublicSaleState() external onlyOwner {
        publicSaleIsEnabled = !publicSaleIsEnabled;
    }

    function setPrivateSaleState() external onlyOwner {
        privateSaleIsEnabled = !privateSaleIsEnabled;
    }

    function setHunters(uint16[] calldata ids, bool value) external onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            _isHunter[ids[i]] = value;
        }
    }

    function setContracts(IForest _forest, IBatt _batt, IRandomNumGenerator _randomGen) external onlyOwner {
        forest = _forest;
        batt = _batt;
        randomGen = _randomGen;
    }

    function setBurnEnabled(bool _state) external onlyOwner {
        burnEnabled = _state;
    }

    function addAvailableTokens(uint16 _from, uint16 _to, uint256 chiAmount) external onlyOwner discountCHI(chiAmount) {
        require(!privateSaleIsEnabled && !publicSaleIsEnabled, "Sale is live");
        _addAvailableTokens(_from, _to);
    }

    function removeFromAvailableTokens(uint256 index) external onlyOwner {
        _availableTokens[index] = _availableTokens[_availableTokens.length - 1];
        _availableTokens.pop();
    }

    function switchToSalePhase(uint16 _phase) external onlyOwner {
        phase = _phase;
    }


    function reserveMoose(address to, uint amount) external onlyOwner {
        require(_availableTokens.length >= amount, "All tokens for this Phase are already sold");

        for (uint i = 0; i < amount; i++) {
            uint16 tokenId = _getTokenToBeMinted();
            _safeMint(to, tokenId);
            if (isHunter(tokenId)) {
                hunterMinted += 1;
            }
        }
        tokensMinted += amount;
    }

    function reserveMooseById(address to, uint16[] calldata ids) external onlyOwner {
        require(_availableTokens.length == 0, "Available tokens exists");

        for (uint i = 0; i < ids.length; i++) {
            _safeMint(to, ids[i]);
            if (isHunter(ids[i])) {
                hunterMinted += 1;
            }
        }
        tokensMinted += ids.length;
    }

    /**
    * Mints Moose in public sale
    */
    function publicMint(uint amount, bool stake) external payable discountCHI(amount * 5) {
        require(tx.origin == msg.sender, "Only EOA");
        require(publicSaleIsEnabled, "Public sale must be enabled");
        require(0 < amount && amount <= maxMint, "Invalid amount to mint");
        require(_availableTokens.length >= amount, "All tokens for this Phase are already sold");

        uint totalPennyCost = 0;
        if (phase == 0) {
            // Paid mint
            require(mintPrice * amount == msg.value, "Invalid payment amount");
        } else {
            // Mint via Penny token burn
            require(msg.value == 0, "Now minting is done via Penny");
            totalPennyCost = phasePrice[phase] * amount;
            if (totalPennyCost > 0) {
                batt.burn(msg.sender, totalPennyCost);
            }
        }

        uint _tokensMinted = tokensMinted;
        uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
        bool isLucky;
        uint16[] memory luckyTokenIds = stake && phase != 0 ? new uint16[](amount) : new uint16[](0);
        for (uint i = 0; i < amount; i++) {
            address recipient = _selectRecipient(i);

            uint16 tokenId = _getTokenToBeMinted();

            if (isHunter(tokenId)) {
                hunterMinted += 1;
            }

            if (recipient != msg.sender) {
                isHunter(tokenId) ? hunterStolen += 1 : harvesterStolen += 1;
                emit TokenStolen(msg.sender, tokenId, recipient);
            }

            if (!stake || recipient != msg.sender) {
                _safeMint(recipient, tokenId);
            } else {
                _safeMint(address(forest), tokenId);
                tokenIds[i] = tokenId;
            }
            _tokensMinted++;

            // 10% chance to be a lucky man
            if (phase != 0 && _availableTokens.length > (amount - i - 1) && randomGen.getRandomNumber(_tokensMinted, 100) < 10) {
                if (!isLucky) {
                    isLucky = true;
                }
                uint16 luckyTokenId = _getTokenToBeMinted();
                if (isHunter(luckyTokenId)) {
                    hunterMinted += 1;
                }
                if (!stake) {
                    _safeMint(msg.sender, luckyTokenId);
                } else {
                    _safeMint(address(forest), luckyTokenId);
                    luckyTokenIds[i] = luckyTokenId;
                }
                _tokensMinted++;

                emit Lucky(msg.sender, luckyTokenId);
            }
        }
        tokensMinted = _tokensMinted;

        if (stake) {
            forest.addTokensToStake(msg.sender, tokenIds);
        }
        if (stake && isLucky) {
            forest.addTokensToStake(msg.sender, luckyTokenIds);
        }
    }

    /**
    * Mints Moose in private sale
    */
    function privateMint(address user, uint amount, uint8 v, bytes32 r, bytes32 s, bool stake) external payable discountCHI(amount * 5) {
        require(tx.origin == msg.sender, "Only EOA");
        require(privateSaleIsEnabled, "Private sale must be enabled");
        require(0 < amount && amount <= maxMint, "Invalid amount to mint");
        require(_availableTokens.length >= amount, "All tokens for this Phase are already sold");
        require(mintPrice * amount == msg.value, "Invalid payment amount");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(MINT_TYPEHASH, user, amount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        uint _tokensMinted = tokensMinted;
        uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
        for (uint i = 0; i < amount; i++) {
            uint16 tokenId = _getTokenToBeMinted();

            if (isHunter(tokenId)) {
                hunterMinted += 1;
            }

            if (!stake) {
                _safeMint(msg.sender, tokenId);
            } else {
                _safeMint(address(forest), tokenId);
                tokenIds[i] = tokenId;
            }
            _tokensMinted++;
        }
        tokensMinted = _tokensMinted;

        if (stake) {
            forest.addTokensToStake(msg.sender, tokenIds);
        }

        emit PrivateMint(msg.sender, amount);
    }

    function burn(uint16[] calldata tokenIds, bool mint) public virtual {
        require(burnEnabled, "Burn is not allowed");

        for (uint i = 0; i < tokenIds.length; i++) {
            require(_msgSender() == owner() || _isApprovedOrOwner(_msgSender(), tokenIds[i]), "ERC721Burnable: caller is not owner nor approved");
            _burn(tokenIds[i]);
            tokensMinted = tokensMinted - 1;
            if (isHunter(tokenIds[i])) {
                hunterMinted = hunterMinted - 1;
            }
        }
        if (mint && _msgSender() != owner() && tokenIds.length > 1) {
            uint16 tokenId = _getTokenToBeMinted();

            _safeMint(_msgSender(), tokenId);
            if (isHunter(tokenId)) {
                hunterMinted += 1;
            }
            tokensMinted++;
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(fundWallet).transfer(balance);
    }

    function _addAvailableTokens(uint16 _from, uint16 _to) private {
        for (uint16 i = _from; i <= _to; i++) {
            if (!exists(i)) {
                _availableTokens.push(i);
            }
        }
    }

    function _getTokenToBeMinted() private returns (uint16) {
        uint random = randomGen.getRandomNumber(_availableTokens.length, _availableTokens.length);
        uint16 tokenId = _availableTokens[random];

        _availableTokens[random] = _availableTokens[_availableTokens.length - 1];
        _availableTokens.pop();

        return tokenId;
    }

    function _selectRecipient(uint seed) private returns (address) {
        if (phase == 0) {
            return msg.sender; // During ETH sale there is no chance to steal NTF
        }

        // 10% chance to steal NTF
        if (randomGen.getRandomNumber(tokensMinted + seed, 100) >= 10) {
            return msg.sender; // 90%
        }

        address thief = forest.randomHunterOwner(tokensMinted + seed);
        if (thief == address(0x0)) {
            return msg.sender;
        }
        return thief;
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}