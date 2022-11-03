//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IMinter.sol";

contract LACGold is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MAX_MINT_AMOUNT = 5;

    uint256 private _ethPrice;

    address erc20Contract = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC ethereum mainnet
    uint256 public constant PRESALE_PRICE = 750 * 10 ** 6; // 750 USDC (mainnet value)
    uint256 public constant PUBLIC_PRICE = 2500 * 10 ** 6; // 2500 USDC (mainnet value)
    uint256 public constant UPGRADE_PRICE = 750 * 10 ** 6; // 750 USDC (mainnet value)

    // address erc20Contract = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; 
    // uint256 public constant PRESALE_PRICE = 1 * 10 ** 4; // 0.01 USDC (testnet value)
    // uint256 public constant PUBLIC_PRICE = 2 * 10 ** 4; // 0.02 USDC (testnet value)
    // uint256 public constant UPGRADE_PRICE = 3 * 10 ** 4; // 0.03 USDC (testnet value)

    uint256 public presaleAt;
    uint256 public launchAt;

    address public minterAddress;
    address public presaleSigner;

    uint256 public burnedTokenCount = 0;

    bool public operational = true;
    mapping(address => uint256) public addressMintBalance;

    constructor(
        string memory baseURI_,
        uint256 presaleAt_,
        uint256 launchAt_,
        address minterAddress_,
        address presaleSigner_
    ) ERC721("LACGold", "LACGold") {
        _baseTokenURI = baseURI_;

        presaleAt = presaleAt_;
        launchAt = launchAt_;

        minterAddress = minterAddress_;
        presaleSigner = presaleSigner_;
    }

    modifier mintValidation(uint256 _mintQty) {
        uint256 supply = totalSupply();
        require(operational, "Operation is paused");
        require(_mintQty > 0, "Must mint minimum of 1 token");
        require(burnedTokenCount + supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");

        uint256 ownerMintedCount = addressMintBalance[msg.sender];
        require(ownerMintedCount + _mintQty <= MAX_MINT_AMOUNT, "Max NFT per address exceeded");
        _;
    }

    function isPresale() public view returns (bool) {
        return block.timestamp >= presaleAt && block.timestamp < launchAt;
    }

    function isLaunched() public view returns (bool) {
        return block.timestamp >= launchAt;
    }

    function ethPrice() external view returns (uint256) {
        return _ethPrice;
    }

    function presaleMint(
        uint256 _mintQty,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external mintValidation(_mintQty) {
        require(block.timestamp >= presaleAt, "Presale has not begun");
        require(block.timestamp < launchAt, "Presale has ended");

        bytes32 digest = keccak256(abi.encode(msg.sender));

        require(_validMint(presaleSigner, digest, r, s, v), "Invalid mint signature");

        uint256 totalPrice = _mintQty * PRESALE_PRICE;

        IERC20 tokenContract = IERC20(erc20Contract);

        bool transferred = tokenContract.transferFrom(msg.sender, address(this), totalPrice);
        require(transferred, "ERC20 tokens failed to transfer");
        
        mint(msg.sender, _mintQty);
    }

    function launchMint(uint256 _mintQty) external mintValidation(_mintQty) {
        require(block.timestamp >= launchAt, "Public sale has not begun");

        uint256 totalPrice = _mintQty * PUBLIC_PRICE;

        IERC20 tokenContract = IERC20(erc20Contract);

        bool transferred = tokenContract.transferFrom(msg.sender, address(this), totalPrice);
        require(transferred, "ERC20 tokens failed to transfer");
        
        mint(msg.sender, _mintQty);
    }

    function ethMint(uint256 _mintQty) external payable {
        require(block.timestamp >= launchAt, "Public sale has not begun");

        uint256 supply = totalSupply();
        require(operational, "Operation is paused");
        require(_mintQty > 0, "Must mint minimum of 1 token");
        require(burnedTokenCount + supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");

        require(msg.value == _mintQty * _ethPrice, "Amount of Ether sent is not correct");
        
        mint(msg.sender, _mintQty);
    }

    function devMint(uint256 _mintQty) external onlyOwner {
        uint256 supply = totalSupply();

        require(burnedTokenCount + supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");
        
        for (uint256 i = 1; i <= _mintQty; i++) {
            _safeMint(msg.sender, burnedTokenCount + supply + i);
        }
    }

    function mint(address _to, uint256 _mintQty) internal {
        uint256 supply = totalSupply();

        addressMintBalance[msg.sender] += _mintQty;

        for (uint256 i = 1; i <= _mintQty; i++) {
            _safeMint(_to, burnedTokenCount + supply + i);
        }
    }

    function upgrade(uint256[2] calldata tokenIds) external {
        IMinter minter = IMinter(minterAddress);
        IERC20 tokenContract = IERC20(erc20Contract);
        
        bool canUpgrade = false;
        bool transferred = tokenContract.transferFrom(msg.sender, address(this), UPGRADE_PRICE);

        require(transferred, "ERC20 tokens failed to transfer");

        for (uint256 i = 0; i < 2; i++) {
            address owner = ERC721.ownerOf(tokenIds[i]);
            if (msg.sender == owner) {
                canUpgrade = true;
            } else {
                canUpgrade = false;
            }
        }

        if (canUpgrade) {
            for (uint256 i = 0; i < 2; i++) {
                _burn(tokenIds[i]);
            }

            burnedTokenCount += 2;
            minter.mint(msg.sender);
        }
    }

    function _validMint(
        address administrator,
        bytes32 digest,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        internal view
        returns (bool)
    {
        address signer = ecrecover(digest, v, r, s);
        return signer == administrator;
    }

    function setPresaleAt(uint256 value) external onlyOwner {
        presaleAt = value;
    }

    function setLaunchAt(uint256 value) external onlyOwner {
        launchAt = value;
    }

    function setEthPrice(uint256 value) public onlyOwner {
        _ethPrice = value;
    }

    function setMinter(address _minterAddress) external onlyOwner {
        minterAddress = _minterAddress;
    }

    function toggleOperational() external onlyOwner {
        operational = !operational;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    address private constant creator1Address = 0x24D76404CC8A641E74D06beE456587D11bE4B87D;
    address private constant creator2Address = 0x3004AacF8008E7e91048bd63da7444a0AA3d777b;
    address private constant creator3Address = 0xccdd6139f18dc9C5840F4Bed78217e2c4D0F7Cae;
    address private constant creator4Address = 0x21a49877B5c5fDd7BEB43911d632FB3F3cA14c6d;

    function withdraw() external onlyOwner {
        (bool success, ) = creator1Address.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function withdrawERC20() external onlyOwner
    {
        IERC20 tokenContract = IERC20(erc20Contract);

        uint256 totalBalance = tokenContract.balanceOf(address(this));

        bool transfer1 = tokenContract.transfer(payable(creator2Address), totalBalance.mul(7).div(100));
        bool transfer2 = tokenContract.transfer(payable(creator3Address), totalBalance.mul(7).div(100));
        bool transfer3 = tokenContract.transfer(payable(creator4Address), totalBalance.mul(7).div(100));
        bool transfer4 = tokenContract.transfer(payable(creator1Address), tokenContract.balanceOf(address(this)));

        require(transfer1, "Creator 2 transfer failed");
        require(transfer2, "Creator 3 transfer failed");
        require(transfer3, "Creator 4 transfer failed");
        require(transfer4, "Creator 1 transfer failed");
    }
}