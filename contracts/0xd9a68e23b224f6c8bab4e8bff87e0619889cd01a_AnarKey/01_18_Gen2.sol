// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./erc721x/contracts/ERC721X.sol";

/**
 * @title AnarKey
 * @notice ANARKEY ERC721X NFT collection
 */

contract AnarKey is Ownable, ERC721X, Pausable, IERC2981  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    IERC20 public USDT; // USDT token

    bool public isMetadataLocked;
    bool public isMaxSupplyLocked;
    bool public autoStageChange;
    uint256 public maxSupply = 1111;
    uint256 private BatchSize = 100;
    string public baseTokenURI;
    address public royalties;
    uint256 public royaltiesPercentage;

    uint256 public MaxMintPerTX = 10;
    uint256 public NFT_PRICE = 5000;
    uint256 public TokenDecimal = 1000000;
    uint256 public saleStage = 0;
    uint256 private publicSaleKey;
    uint256 public CurrentMintIndex = 0;
    uint256 public EndRoundMintIndex = 200;
    uint256 public NextEndRoundMintIndex = 400;
    uint256 public NextRoundMintPrice = 5000;
    uint256 public MaxMintIndex = 750;

    address public immutable withdrawWallet1 = 0x4Da56C7c284d56094b21fCC56888BeeaCac53365;
    address public immutable withdrawWallet2 = 0xac488462d5Ed9a904842e8946290698694B2391f;

    mapping(address => uint256) private _userMints;

    event Withdraw(uint256 amount);
    event LockMetadata();
    event LockMaxSupply();

    constructor() ERC721X("AnarKey", "ANARKEY", BatchSize, maxSupply) {
        autoStageChange = true;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @notice Allows the owner to lock the contract
     * @dev Callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(!isMetadataLocked, "Contract is locked");
        require(bytes(baseTokenURI).length > 0, "BaseUri not set");
        isMetadataLocked = true;
        emit LockMetadata();
    }

    function setAutoStageChange(bool _stage) external onlyOwner {
        autoStageChange = _stage;
    }

    /**
     * @notice Allows the owner to lock the max supply
     * @dev Callable by owner
     */
    function lockMaxSupply() external onlyOwner {
        require(!isMaxSupplyLocked, "Max supply is locked");
        require(maxSupply > 0, "Max supply not set");
        isMaxSupplyLocked = true;
        emit LockMaxSupply();
    }

    function mint(uint256 _quantity, uint256 _CallerPublicSaleKey) external callerIsUser whenNotPaused {
        uint256 userBalance = USDT.balanceOf(msg.sender);
        uint256 costToMint = NFT_PRICE * TokenDecimal * _quantity;

        require(totalSupply().add(_quantity) <= maxSupply, "NFT: Total supply reached");
        require(totalSupply().add(_quantity) <= MaxMintIndex, "Total supply reached max mint supply");
        require(totalSupply().add(_quantity) <= EndRoundMintIndex, "Your quantity is over than limit");
        require(publicSaleKey == _CallerPublicSaleKey, "Called with incorrect public sale key");
        require(costToMint <= userBalance, "User balance is not enough");
        require(_quantity <= MaxMintPerTX, "Mint exceed the limit per TX");      
        require(saleStage > 0, "Sale is not active at the moment");
        require(CurrentMintIndex + _quantity <= EndRoundMintIndex, "Supply over the swap supply limit");

        USDT.safeTransferFrom(msg.sender, address(this), costToMint); 
        _userMints[msg.sender] = _userMints[msg.sender] + _quantity;
        CurrentMintIndex = CurrentMintIndex + _quantity;
        _safeMint(msg.sender, _quantity);

        if (totalSupply() >= EndRoundMintIndex) {
            if (autoStageChange) {
                EndRoundMintIndex = NextEndRoundMintIndex;
                NFT_PRICE = NextRoundMintPrice;
                saleStage++;
            }       
        }
    }

    function ownerMintBulk(address[] memory _accounts, uint256[] memory _quantity) external onlyOwner{
        require(_accounts.length == _quantity.length,"arrays must have same length");

        for (uint256 i = 0; i < _accounts.length; i++) {
            require(totalSupply().add(_quantity[i]) <= maxSupply, "NFT: Total supply reached");
            CurrentMintIndex = CurrentMintIndex + _quantity[i];
            _safeMint(_accounts[i], _quantity[i]);
        }
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(!isMaxSupplyLocked, "Operations: Max supply is locked");
        setCollectionSize(_maxSupply);
        maxSupply = _maxSupply;
    }

    /**
     * @notice Allows the owner to set the base URI to be used for all token IDs
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        require(!isMetadataLocked, "Operations: Contract is locked");
        baseTokenURI = _uri;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for a token ID
     * @param tokenId: token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId");
        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json")) : "";
    }


    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function setRoyaltiesPercentage(uint256 _percentage) public onlyOwner {
        royaltiesPercentage = _percentage;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice / 100) * royaltiesPercentage;
        return (royalties, royaltyAmount);
    }


    function setUSDTAddress(IERC20 _address) external onlyOwner {
        USDT = _address;
    }

    function setTokenDecimal(uint256 _tokenDecimal) external onlyOwner {
        TokenDecimal = _tokenDecimal;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _withdraw(uint256 amount) private {
        require(amount <= USDT.balanceOf(address(this)), "amount > balance");
        require(amount > 0, "Empty amount");

        uint256 amount1 = amount.mul(50).div(100);
        uint256 amount2 = amount.mul(50).div(100);

        USDT.safeTransfer(withdrawWallet1, amount1);
        USDT.safeTransfer(withdrawWallet2, amount2);
        emit Withdraw(amount);
    }


    function withdraw(uint256 amount) external onlyOwner {
        _withdraw(amount);
    }


    function withdrawAll() external onlyOwner {
        _withdraw(USDT.balanceOf(address(this)));
    }

    function setMaxperTX(uint256 _MaxMintPerTX) external onlyOwner {
        MaxMintPerTX = _MaxMintPerTX;
    }

    function setMintPrice(uint256 _MintPrice) external onlyOwner {
        NFT_PRICE = _MintPrice;
    }

    function setCurrentMintIndex(uint256 _Index) external onlyOwner {
        CurrentMintIndex = _Index;
    }

    function setEndRoundMintIndex(uint256 _Index) external onlyOwner {
        EndRoundMintIndex = _Index;
    }

    function setNextEndRoundMintIndex(uint256 _Index) external onlyOwner {
        NextEndRoundMintIndex = _Index;
    }

    function setNextRoundPrice(uint256 _Index) external onlyOwner {
        NextRoundMintPrice = _Index;
    }

    function setMaxMintIndex(uint256 _Index) external onlyOwner {
        MaxMintIndex = _Index;
    }

    function setSaleStage(uint256 _SaleStage, uint256 _price, uint256 _endIndex) external onlyOwner {
        saleStage = _SaleStage;
        NFT_PRICE = _price;
        EndRoundMintIndex = _endIndex;
    }

    function setPublicSaleKey(uint256 _PublicSaleKey) external onlyOwner {
        publicSaleKey = _PublicSaleKey;
    }
}