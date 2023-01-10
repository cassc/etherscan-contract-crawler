// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";
interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external returns (address);
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address user) external returns (uint256);
    
    function deposit() external payable;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract AsterFi is ERC721A, ReentrancyGuard {
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant PRICE = 0.5 ether;
    uint256 public tokenPerWL = 3;

    uint256 public constant WLBackupPercentage = 40;
    uint256 public constant PublicBackupPercentage = 30;
    uint256 public supplyCounter;
    address public owner;

    address[10] private rewardsCoins = [
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, //WBTC
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, //WETH
        0x4d224452801ACEd8B2F0aebE155379bb5D594381, //APE
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, //Uniswap
        0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0, //MATIC
        0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72, //ENS
        0x514910771AF9Ca656af840dff83E8264EcF986CA, //LINK
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, //Aave
        0x4E15361FD6b4BB609Fa63C81A2be19d873717870, //FTM
        0x0D8775F648430679A709E98d2b0Cb6250d2887EF //Bat
    ];
    uint16[10] private traitWeights = [
        700, //WBTC
        400, //WETH
        300, //APE
        250, //Uniswap
        90,  //MATIC
        80,  //ENS
        70,  //LINK
        50,  //Aave
        40,  //FTM
        20   //Bat
    ];

    string public BaseURI;
    string public NotRevealedURI;
    bytes32 public merkleRoot;
    mapping(address => uint256) public tokensPerWallet;
    bool private pubSaleActive;
    enum ContractStatus {
        DEPLOY,
        WL,
        SALE,
        SOLD
    }
    bool public REVEAL;
    ContractStatus public contractStatus;
    uint256 public AdminBalance;
    mapping(address => uint256) public adminTokenBalance;
    struct NFTInformation {
        bool revealed;
        uint8 tokenDecimal;
        uint256 backupLimit;
        uint256 backupAmount;
        address tokenBackup;
    }
    mapping(uint256 => NFTInformation) public nftInfos;

    constructor() ERC721A("AsterFi", "ASFI") {
        owner = msg.sender;
        contractStatus = ContractStatus.DEPLOY;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "youAreNotOwner!");
        _;
    }

    function verifyAddress(bytes32[] calldata _merkleProof, address _address)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function WhitelistMint(bytes32[] calldata _merkleProof, uint256 _amount)
        external
        payable
        nonReentrant
    {
        require(verifyAddress(_merkleProof, msg.sender), "INVALID_PROOF");
        require(contractStatus != ContractStatus.SOLD, "SOLD OUT");
        require(
            contractStatus == ContractStatus.WL,
            "WL NOT STARTED OR IS ENDED"
        );
        uint256 _price = PRICE * _amount;
        require(msg.value >= _price, "wrong value is sended");
        require(_amount > 0, "you need to mint more than 0 tokens");
        require(totalSupply() + _amount <= MAX_SUPPLY, "all nfts are minted");
        require(
            tokensPerWallet[msg.sender] + _amount <= tokenPerWL,
            "you are only allowed to mint 3 NFT"
        );
        if (totalSupply() + _amount == MAX_SUPPLY) {
            contractStatus = ContractStatus.SOLD;
        }
        _mintTokens(msg.sender, _amount, _price, msg.value, true);
    }

    function Mint(uint256 _amount) external payable nonReentrant {
        require(contractStatus != ContractStatus.SOLD, "SOLD OUT");
        require(contractStatus == ContractStatus.SALE, "SALE NOT STARTED");
        uint256 _price = PRICE * _amount;
        require(msg.value >= _price, "wrong value is sended");
        require(_amount > 0, "you need to mint more than 0 tokens");
        require(
            tokensPerWallet[msg.sender] + _amount <= tokenPerWL,
            "you are only allowed to mint 8 NFT"
        );
        require(totalSupply() + _amount <= MAX_SUPPLY, "all nfts are minted");
        if (totalSupply() + _amount == MAX_SUPPLY) {
            contractStatus = ContractStatus.SOLD;
        }
        _mintTokens(msg.sender, _amount, _price, msg.value, false);
    }

    function _mintTokens(
        address _user,
        uint256 _amount,
        uint256 _price,
        uint256 _msgValue,
        bool _isWL
    ) internal {
        for (uint256 i = 1; i <= _amount; i++) {
            uint256 _newID = supplyCounter;
            tokensPerWallet[_user] += 1;
            NFTInformation storage _nftInformation = nftInfos[_newID];
            if (_isWL) {
                _nftInformation.backupAmount =
                    (PRICE * WLBackupPercentage) /
                    100;
            } else {
                _nftInformation.backupAmount =
                    (PRICE * PublicBackupPercentage) /
                    100;
            }
            AdminBalance += PRICE - _nftInformation.backupAmount;
            supplyCounter++;
        }
        _safeMint(_user, _amount);
        if (_msgValue > _price) {
            payable(_user).transfer(_msgValue - _price);
        }
    }

    function getRandomCoin(uint256 tokenId) internal view returns (uint16) {
        uint256 pseudoRandomBase = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );
        return weightRarity(uint16(uint16(pseudoRandomBase >> 1) % MAX_SUPPLY));
    }

    function weightRarity(uint256 pseudoRandomNumber)
        internal
        view
        returns (uint16)
    {
        uint16 lowerBound = 0;
        for (uint8 i = 0; i < traitWeights.length; i++) {
            uint16 weight = traitWeights[i];
            if (
                pseudoRandomNumber >= lowerBound &&
                pseudoRandomNumber < lowerBound + weight
            ) {
                return i;
            }
            lowerBound = lowerBound + weight;
        }
        revert();
    }

    function RevealNFT(uint256 _id) external {
        require(ownerOf(_id) == msg.sender, "you are not the owner of the NFT");
        require(REVEAL, "reveal is not active yet");
        NFTInformation storage _nftInformation = nftInfos[_id];
        require(!_nftInformation.revealed, "you already revealed your NFT");
        uint16 _getRandomCoinIndex = getRandomCoin(_id);
        _nftInformation.tokenBackup = rewardsCoins[_getRandomCoinIndex];
        _nftInformation.tokenDecimal = IERC20(_nftInformation.tokenBackup)
            .decimals();
        _nftInformation.revealed = true;
        IERC20(WETH).deposit{value: _nftInformation.backupAmount}();
        transferERC20(WETH, address(this), _nftInformation.backupAmount);
        if (_nftInformation.tokenBackup != WETH) {
            uint256 _amountOutMin = getTokenAmountIn(
                WETH,
                _nftInformation.tokenBackup,
                _nftInformation.backupAmount
            );
            swapToken(
                _nftInformation.tokenBackup,
                _nftInformation.backupAmount,
                _amountOutMin
            );

            _nftInformation.backupAmount = _amountOutMin;
        }

        _nftInformation.backupLimit = _nftInformation.backupAmount;
    }

    function WithdrawNFTBackup(uint256 _id, uint256 _amount) external {
       require(ownerOf(_id) == msg.sender, "you are not the owner of the NFT");
        NFTInformation storage _nftInformation = nftInfos[_id];
        require(_nftInformation.revealed, "you need to reveal your NFT first");
        uint256 _backupAmount = _nftInformation.backupAmount;
        require(_amount <= _backupAmount, "the amount you sended is wrong");
        if ((_backupAmount - _amount) < _nftInformation.backupLimit) {
            uint256 _fee = (_backupAmount * 10) / 100; //  10%
            adminTokenBalance[_nftInformation.tokenBackup] += _fee;
            super._burn(_id);
            transferERC20(
                _nftInformation.tokenBackup,
                msg.sender,
                _nftInformation.backupAmount - _fee
            );
            _nftInformation.backupAmount = 0;
        } else {
            _nftInformation.backupAmount -= _amount;
            transferERC20(_nftInformation.tokenBackup, msg.sender, _amount);
        }
    }

    function DepositNFT(uint256 _id) external payable {
        require(ownerOf(_id) == msg.sender, "you are not the owner of the NFT");
        NFTInformation storage _nftInformation = nftInfos[_id];
        require(_nftInformation.revealed, "you need to reveal your NFT first");

        IERC20(WETH).deposit{value: msg.value}();
        transferERC20(WETH, address(this), msg.value);
        if (_nftInformation.tokenBackup != WETH) {
            uint256 _amountOutMin = getTokenAmountIn(
                WETH,
                _nftInformation.tokenBackup,
                msg.value
            );
            swapToken(_nftInformation.tokenBackup, msg.value, _amountOutMin);
            _nftInformation.backupAmount += _amountOutMin;
        } else {
            _nftInformation.backupAmount += msg.value;
        }
    }

    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner {
        merkleRoot = merkleRootHash;
    }

    function startSale() external onlyOwner {
        require(!pubSaleActive, "pubSaleAlreadyActive");
        pubSaleActive = true;
        contractStatus = ContractStatus.SALE;
        tokenPerWL += 5;
    }

    function startWL() external onlyOwner {
        require(!pubSaleActive, "salehasBeenStartedCanNotStartWL");
        contractStatus = ContractStatus.WL;
    }

    function startReveal() external onlyOwner {
        REVEAL = true;
    }

    function setNotRevealedURI(string memory _URI) public onlyOwner {
        NotRevealedURI = _URI;
    }
    function transferOwnership(address _NewOwner) public onlyOwner {
        owner = _NewOwner;
    }
    function setBaseURI(string memory _URI) public onlyOwner {
        BaseURI = _URI;
    }

    function tokenURI(uint256 _id)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        NFTInformation storage _nftInformation = nftInfos[_id];
        if (!_nftInformation.revealed) {
            return NotRevealedURI;
        }
        return
            bytes(BaseURI).length > 0
                ? string(abi.encodePacked(BaseURI, _toString(_id)))
                : "";
    }

    function swapToken(
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) internal {
        address _tokenIn = WETH;
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function getTokenAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal view returns (uint256) {
        address[] memory path;

        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    // need to be updated!
    function adminFullBalance()
        public
        view
        returns (
            uint256 ETH,
            uint256 token1,
            uint256 token2,
            uint256 token3,
            uint256 token4,
            uint256 token5,
            uint256 token6,
            uint256 token7,
            uint256 token8,
            uint256 token9,
            uint256 token10
        )
    {
        return (
            AdminBalance,
            adminTokenBalance[rewardsCoins[0]],
            adminTokenBalance[rewardsCoins[1]],
            adminTokenBalance[rewardsCoins[2]],
            adminTokenBalance[rewardsCoins[3]],
            adminTokenBalance[rewardsCoins[4]],
            adminTokenBalance[rewardsCoins[5]],
            adminTokenBalance[rewardsCoins[6]],
            adminTokenBalance[rewardsCoins[7]],
            adminTokenBalance[rewardsCoins[8]],
            adminTokenBalance[rewardsCoins[9]]
        );
    }

    function adminWithdrawTokens(address _tokenAddr) external onlyOwner {
        require(_tokenAddr != address(0), "token can not be dead token");
        require(
            adminTokenBalance[_tokenAddr] != 0,
            "admin token balance is 0!"
        );
        transferERC20(_tokenAddr, msg.sender, adminTokenBalance[_tokenAddr]);
        adminTokenBalance[_tokenAddr] = 0;
    }

    function withdraw() external onlyOwner {
        require(AdminBalance != 0, "admin balance is 0!");
        payable(msg.sender).transfer(AdminBalance);
        AdminBalance = 0;
    }
    function transferERC20(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_token).transfer(_to, _amount);
    }
}