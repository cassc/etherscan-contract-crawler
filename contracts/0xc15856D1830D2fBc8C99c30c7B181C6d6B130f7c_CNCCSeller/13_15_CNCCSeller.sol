// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "./AdminAccessControl.sol";
import "./interface/ICryptNinjaChildrenCoin.sol";
import "./interface/ICryptNinjaChildren.sol";

contract CNCCSeller is AdminAccessControl, ReentrancyGuard {
    event exchangeCoinToMakimonoEvent(address indexed user, uint256 afterTokenId, uint256 amount);
    event exchangeMakimonoToCharacterEvent(address indexed user, uint256 beforeTokenId, uint256 afterTokenId, uint256 amount);
    event burninEvent(address indexed user, uint256 burnTokenId, uint256 mintTokenId);

    struct phaseStruct {
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 cost;
        uint256 maxMintAmountPerTransaction;
        bytes32 merkleRoot;
        mapping(address => uint256) userMintedAmount;
    }
    struct pauseStruct {
        bool coinMint;
        bool exchangeCoinToMakimono;
        bool exchangeMakimonoToCharacter;
        bool exchangeCoinToKatasiro;
        bool burnin;
    }

    uint256 public phaseId;
    pauseStruct public pauseData;
    mapping(uint256 => phaseStruct) public phaseStructMap;
    mapping(uint256 => uint256) public exchangeTokenIdMap;
    ICryptNinjaChildren public immutable cnc;
    ICryptNinjaChildrenCoin public immutable cncc;
    uint256 public cncNextTokenId = 11111;

    uint256 public constant COIN_TOKEN_ID = 1;
    uint256 public constant MAKIMONO_TEN_TOKEN_ID = 2; // 天
    uint256 public constant MAKIMONO_KAI_TOKEN_ID = 3; // 海
    uint256 public constant MAKIMONO_CHI_TOKEN_ID = 4; // 地
    uint256 public constant CHARACTER_KANEKO_TOKEN_ID = 5; // カネコ
    uint256 public constant CHARACTER_SATORU_TOKEN_ID = 6; // サトル
    uint256 public constant CHARACTER_SARAO_TOKEN_ID = 7;  // サラオ
    uint256 public constant KATASIRO_TOKEN_ID = 8;  // 形代

    constructor(ICryptNinjaChildrenCoin _cncc, ICryptNinjaChildren _cnc) {
        grantAdmin(_msgSender());

        cnc = ICryptNinjaChildren(_cnc);
        cncc = ICryptNinjaChildrenCoin(_cncc);

        setPhaseId(1);

        setExchangeTokenIdMap(MAKIMONO_TEN_TOKEN_ID, CHARACTER_KANEKO_TOKEN_ID);
        setExchangeTokenIdMap(MAKIMONO_KAI_TOKEN_ID, CHARACTER_SATORU_TOKEN_ID);
        setExchangeTokenIdMap(MAKIMONO_CHI_TOKEN_ID, CHARACTER_SARAO_TOKEN_ID);

        setPauseCoinMint(true);
        setPauseExchangeCoinToMakimono(true);
        setPauseExchangeMakimonoToCharacter(true);
        setPauseExchangeCoinToKatasiro(true);
        setPauseBurnin(true);
    }

    modifier amountCheck(uint256 _mintAmount, uint256 _wlCount) {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(_mintAmount <= phaseStructMap[phaseId].maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require(phaseStructMap[phaseId].totalSupply + _mintAmount <= phaseStructMap[phaseId].maxSupply, "max NFT limit exceeded");
        require(
            phaseStructMap[phaseId].userMintedAmount[msg.sender] + _mintAmount <= _wlCount,
            'Address already claimed max amount'
        );
        _;
    }

    modifier senderCheck(address _sender, uint248 _wlCount, bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(_sender, _wlCount));
        require(MerkleProof.verifyCalldata(_merkleProof, phaseStructMap[phaseId].merkleRoot, leaf), 'Invalid Merkle Proof');
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier enouthEth(uint256 _amount) {
        require(msg.value >= phaseStructMap[phaseId].cost * _amount, "not enough eth.");
        _;
    }

    function setPauseCoinMint(bool _isPause) public onlyAdmin { pauseData.coinMint = _isPause; }
    function setPauseExchangeCoinToMakimono(bool _isPause) public onlyAdmin { pauseData.exchangeCoinToMakimono = _isPause; }
    function setPauseExchangeMakimonoToCharacter(bool _isPause) public onlyAdmin { pauseData.exchangeMakimonoToCharacter = _isPause; }
    function setPauseExchangeCoinToKatasiro(bool _isPause) public onlyAdmin { pauseData.exchangeCoinToKatasiro = _isPause; }
    function setPauseBurnin(bool _isPause) public onlyAdmin { pauseData.burnin = _isPause; }

    function mint(
        uint256 _mintAmount,
        uint248 _wlCount,
        bytes32[] calldata _merkleProof
    ) external payable amountCheck(_mintAmount, _wlCount) senderCheck(msg.sender, _wlCount, _merkleProof) nonReentrant callerIsUser enouthEth(_mintAmount) {
        require(!pauseData.coinMint, 'is not active.');
        phaseStructMap[phaseId].userMintedAmount[msg.sender] += _mintAmount;
        phaseStructMap[phaseId].totalSupply += _mintAmount;
        cncc.mint(msg.sender, COIN_TOKEN_ID, _mintAmount, "");
    }

    function exchangeCoinToMakimono(uint256 _amount) external nonReentrant callerIsUser {
        require(!pauseData.exchangeCoinToMakimono, 'is not active.');
        require(0 < _amount && _amount <= cncc.balanceOf(msg.sender, COIN_TOKEN_ID), 'amount cannot be zero');

        cncc.burn(msg.sender, COIN_TOKEN_ID, _amount);
        uint256[] memory randCounts = new uint256[](3);
        for (uint256 i = 0; i < _amount; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), i))) % 3; // 0,1,2
            randCounts[rand] += 1;
        }
        uint256[] memory tokenIds;
        uint256[] memory amounts;
        (tokenIds, amounts) = _forBatchMint(randCounts);
        cncc.mintBatch(msg.sender, tokenIds, amounts, "");
    }

    function _forBatchMint(uint256[] memory _randCounts) private returns (uint256[] memory tokenIds, uint256[] memory amounts) {
        tokenIds = new uint256[](_randCounts.length);
        amounts = new uint256[](_randCounts.length);
        uint256 tokenAmountIndex = 0;
        for(uint256 i = 0; i < 3; i++) {
            if (_randCounts[i] > 0) {
                tokenIds[tokenAmountIndex] = MAKIMONO_TEN_TOKEN_ID + i;
                amounts[tokenAmountIndex] = _randCounts[i];
                emit exchangeCoinToMakimonoEvent(msg.sender, tokenIds[tokenAmountIndex], amounts[tokenAmountIndex]);

                tokenAmountIndex += 1;
            }
        }

        return (tokenIds, amounts);
    }

    function setExchangeTokenIdMap(uint256 _beforeTokenId, uint256 _afterTokenId) public onlyAdmin {
        require(_beforeTokenId != _afterTokenId, 'beforeTokenId and afterTokenId cannot be same');

        exchangeTokenIdMap[_beforeTokenId] = _afterTokenId;
    }

    function exchangeMakimonoToCharacter(uint256[] calldata _burnTokenIds, uint256[] calldata _amounts) external nonReentrant {
        require(!pauseData.exchangeMakimonoToCharacter, 'is not active.');
        require(_burnTokenIds.length > 0, 'length cannot be zero');
        require(_burnTokenIds.length == _amounts.length, 'lengths are not equal');

        uint256[] memory mintTokenIds = new uint256[](_burnTokenIds.length);
        for(uint256 i = 0; i < _burnTokenIds.length; i++) {
            require(_amounts[i] > 0, 'amount cannot be zero');
            require(cncc.balanceOf(msg.sender, _burnTokenIds[i]) >= _amounts[i], 'Insufficient balance');
            uint256 mintTokenId = exchangeTokenIdMap[_burnTokenIds[i]];
            require(mintTokenId > 0, 'Invalid burn token id');

            mintTokenIds[i] = mintTokenId;
            emit exchangeMakimonoToCharacterEvent(msg.sender, _burnTokenIds[i], mintTokenId, _amounts[i]);
        }

        cncc.burnBatch(msg.sender, _burnTokenIds, _amounts);
        cncc.mintBatch(msg.sender, mintTokenIds, _amounts, "");
    }

    function exchangeCoinToKatasiro(uint256 _amount) external nonReentrant callerIsUser {
        require(!pauseData.exchangeCoinToKatasiro, 'is not active.');
        require(0 < _amount && _amount <= cncc.balanceOf(msg.sender, COIN_TOKEN_ID), 'amount cannot be zero');

        cncc.burn(msg.sender, COIN_TOKEN_ID, _amount);
        cncc.mint(msg.sender, KATASIRO_TOKEN_ID, _amount, "");
    }

    function burnin(uint256[] calldata _CNCTokenIds) external nonReentrant {
        require(!pauseData.burnin, 'is not active.');
        uint256 tokenLength = _CNCTokenIds.length;
        require(tokenLength > 0, 'length cannot be zero');
        require(cncc.balanceOf(msg.sender, KATASIRO_TOKEN_ID) >= tokenLength, "Insufficient Katasiro balance");
        for(uint256 i = 0; i < tokenLength; ++i) {
            require(cnc.ownerOf(_CNCTokenIds[i]) == msg.sender, 'Not CNC owner');
        }
        cncc.burn(msg.sender, KATASIRO_TOKEN_ID, _CNCTokenIds.length);

        bytes32[] memory merkleProof = new bytes32[](0);
        cnc.exchange(_CNCTokenIds, 11111, merkleProof);

        uint256 baseTokenId = cncNextTokenId;
        for(uint256 i = 0; i < tokenLength; ++i) {
            uint256 mintTokenId = baseTokenId + i;
            cnc.safeTransferFrom(address(this), msg.sender, mintTokenId);
            emit burninEvent(msg.sender, _CNCTokenIds[i], mintTokenId);
        }
        cncNextTokenId += tokenLength;
    }

    function adminMint(uint256 _tokenId, uint256 _mintAmount, address _to) external onlyAdmin {
        require(_mintAmount > 0, 'Mint amount cannot be zero');

        phaseStructMap[phaseId].totalSupply += _mintAmount;
        cncc.mint(_to, _tokenId, _mintAmount, "");
    }

    function airdropMint(address[] calldata _airdropAddresses , uint256 _tokenId, uint256[] memory _userMintAmount) external onlyAdmin {
        require(_airdropAddresses.length == _userMintAmount.length , "Array lengths are different");
        require(_tokenId > 0, "Token ID cannot be zero");

        uint256 mintAmount = 0;
        for (uint256 i = 0; i < _userMintAmount.length; ++i) {
            mintAmount += _userMintAmount[i];
        }
        require(mintAmount > 0, "need to mint at least 1 NFT");
        require(phaseStructMap[phaseId].totalSupply + mintAmount <= phaseStructMap[phaseId].maxSupply, "max NFT limit exceeded");
        for(uint256 i = 0; i < _userMintAmount.length; ++i) {
            phaseStructMap[phaseId].totalSupply += _userMintAmount[i];
            cncc.mint(_airdropAddresses[i], _tokenId, _userMintAmount[i], "");
        }
    }

    function setPhaseData(
        uint256 _id,
        uint256 _maxSupply,
        uint256 _cost,
        uint256 _maxMintAmountPerTransaction,
        bytes32 _merkleRoot
    ) external onlyAdmin {
        phaseStructMap[_id].maxSupply = _maxSupply;
        phaseStructMap[_id].cost = _cost;
        phaseStructMap[_id].maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
        phaseStructMap[_id].merkleRoot = _merkleRoot;
    }

    function setPhaseId(uint256 _id) public onlyAdmin {
        phaseId = _id;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyAdmin {
        phaseStructMap[phaseId].maxSupply = _maxSupply;
    }

    function setCost(uint256 _newCost) external onlyAdmin {
        phaseStructMap[phaseId].cost = _newCost;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) external onlyAdmin {
        phaseStructMap[phaseId].maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
        phaseStructMap[phaseId].merkleRoot = _merkleRoot;
    }

    function getUserMintedAmount(address _address) external view returns(uint256){
        return phaseStructMap[phaseId].userMintedAmount[_address];
    }

    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}