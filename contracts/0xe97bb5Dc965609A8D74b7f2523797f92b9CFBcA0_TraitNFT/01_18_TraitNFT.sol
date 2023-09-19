// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TraitNFT is Ownable, ERC1155, ERC1155Supply {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    struct PreMintTrait {
        uint256 maxSupply;
        uint256 priceInETH;
        uint256 priceInERC20;
    }

    struct TraitWallet {
        uint256 lockAmount;
        uint256 unlockAmount;
    }

    mapping(uint256 => string) private _tokenURIs;
    Counters.Counter public idCounter;
    IERC20 public erc20Token;
    address payable public withdrawalAddress;
    mapping(uint256 id => PreMintTrait) public preMintTrait;
    mapping(uint256 id => mapping(address collector => TraitWallet)) public traitWallet;

    event PreMintTraitInitialized(
        uint256 indexed traitId,
        uint256 maxSupply,
        uint256 priceInETH,
        uint256 priceInERC20
    );

    event PreMintTraitEdited(
        uint256 indexed traitId,
        uint256 maxSupply,
        uint256 priceInETH,
        uint256 priceInERC20
    );

    event MintedWithETH(
        address indexed collector,
        uint256 indexed traitId,
        uint256 amount
    );

    event MintedWithERC20(
        address indexed collector,
        uint256 indexed traitId,
        uint256 amount
    );

    event BatchMintedWithETH(
        address indexed collector,
        uint256[] ids,
        uint256[] amounts
    );

    event BatchMintedWithERC20(
        address indexed collector,
        uint256[] ids,
        uint256[] amounts
    );

    event TraitLocked(
        address indexed collector,
        uint256 indexed traitId
    );

    event TraitUnlocked(
        address indexed collector,
        uint256 indexed traitId
    );

    event BaseUriSet(
        address indexed owner, 
        string uri
    );

    // Emit on-chain event to refresh token metadata on OpenSea
    event MetadataUpdate(
        uint256 _tokenId
    );

    event ERC20TokenSet(
        address indexed owner, 
        address indexed erc20Token
    );

    event WithdrawalAddressSet(
        address indexed owner, 
        address indexed withdrawalAddress
    );
    event ETHWithdrawn(
        address indexed owner, 
        address indexed withdrawalAddress, 
        uint256 amount
    );
    event ERC20Withdrawn(
        address indexed owner, 
        address indexed withdrawalAddress, 
        uint256 amount
    );

    constructor(address _erc20Token, address payable _withdrawalAddress, string memory _baseUri) ERC1155(_baseUri) {
        require(_erc20Token != address(0), "Invalid ERC20 token address");
        require(_withdrawalAddress != address(0), "Invalid withdrawal address");
        withdrawalAddress = _withdrawalAddress;
        erc20Token = IERC20(_erc20Token);
    }

    function calculateMintableAmount(uint256 id) public view returns (uint256) {
        return preMintTrait[id].maxSupply - totalSupply(id);
    }

    function currentId() external view returns (uint256 _currentId) {
        _currentId = idCounter.current();
    }

    function initPreMintTrait(uint256 maxSupply, uint256 priceInETH, uint256 priceInERC20)
        external
        onlyOwner
    {
        require(maxSupply != 0, "Maximum supply must be greater than zero");
        
        uint256 id = idCounter.current();
        preMintTrait[id].maxSupply = maxSupply;
        preMintTrait[id].priceInETH = priceInETH;
        preMintTrait[id].priceInERC20 = priceInERC20;
        idCounter.increment();
        
        emit PreMintTraitInitialized(id, maxSupply, priceInETH, priceInERC20);
    } 

    function editPreMintTrait(uint256 id, uint256 maxSupply, uint256 priceInETH, uint256 priceInERC20)
        external
        onlyOwner
    {
        PreMintTrait memory _preMintTrait = preMintTrait[id];
        require(_preMintTrait.maxSupply != 0, "Trait with the given id does not exist");
        require(maxSupply != 0 && maxSupply >= totalSupply(id), "Invalid maximum supply");

        _preMintTrait.maxSupply = maxSupply;
        _preMintTrait.priceInETH = priceInETH;
        _preMintTrait.priceInERC20 = priceInERC20;

        preMintTrait[id] = _preMintTrait;

        emit PreMintTraitEdited(id, maxSupply, priceInETH, priceInERC20);
    }

    function mintWithETH(uint256 id, uint256 amount) 
        external 
        payable 
    {
        uint256 mintableAmount = calculateMintableAmount(id);
        require(amount != 0 && amount <= mintableAmount, "Invalid minting amount");

        PreMintTrait memory _preMintTrait = preMintTrait[id];
        uint256 totalMintingPriceInETH = _preMintTrait.priceInETH * amount;
        require(msg.value == totalMintingPriceInETH, "Insufficient funds for minting with ETH");

        address collector = _msgSender();
        traitWallet[id][collector].lockAmount += amount;

        _mint(collector, id, amount, "");

        emit MintedWithETH(collector, id, amount);
    }

    function mintWithERC20(uint256 id, uint256 amount) external {
        uint256 mintableAmount = calculateMintableAmount(id);
        require(amount != 0 && amount <= mintableAmount, "Invalid minting amount");

        address collector = _msgSender();
        traitWallet[id][collector].lockAmount += amount;

        uint256 totalMintingPriceInERC20 = preMintTrait[id].priceInERC20 * amount;
        erc20Token.safeTransferFrom(collector, address(this), totalMintingPriceInERC20);
        
        _mint(collector, id, amount, "");

        emit MintedWithERC20(collector, id, amount);
    }

    function mintBatchWithETH(uint256[] memory ids, uint256[] memory amounts) 
        external 
        payable 
    {
        address collector = _msgSender();
        uint256 totalMintingPriceInETH;

        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 mintableAmount = calculateMintableAmount(id);
            require(amount != 0 && amount <= mintableAmount, "Invalid minting amount");

            PreMintTrait memory _preMintTrait = preMintTrait[id];
            totalMintingPriceInETH += _preMintTrait.priceInETH * amount;

            traitWallet[id][collector].lockAmount += amount;
        }

        require(msg.value == totalMintingPriceInETH, "Insufficient funds for minting with ETH");
        _mintBatch(collector, ids, amounts, "");

        emit BatchMintedWithETH(collector, ids, amounts);
    }

    function mintBatchWithERC20(uint256[] memory ids, uint256[] memory amounts) external {
        address collector = _msgSender();
        uint256 totalMintingPriceInERC20;

        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 mintableAmount = calculateMintableAmount(id);
            require(amount != 0 && amount <= mintableAmount, "Invalid minting amount");

            PreMintTrait memory _preMintTrait = preMintTrait[id];
            totalMintingPriceInERC20 += _preMintTrait.priceInERC20 * amount;

            traitWallet[id][collector].lockAmount += amount;
        }

        erc20Token.safeTransferFrom(collector, address(this), totalMintingPriceInERC20);
        
        _mintBatch(collector, ids, amounts, "");

        emit BatchMintedWithERC20(collector, ids, amounts);
    }

    function lockTrait(uint256 id) external {
        address collector = _msgSender();
        uint256 balance = balanceOf(collector, id);
        require(balance != 0, "Enable only trait owner");
        TraitWallet memory _traitWallet = traitWallet[id][collector];
        require(_traitWallet.unlockAmount >= 1, "Invalid locking amount");

        _traitWallet.lockAmount += 1;
        _traitWallet.unlockAmount -= 1;

        require(balance == _traitWallet.lockAmount + _traitWallet.unlockAmount, "Invalid balance when locking");
        traitWallet[id][collector] = _traitWallet;

        emit TraitLocked(collector, id);
    }

    function unlockTrait(uint256 id) external {
        address collector = _msgSender();
        uint256 balance = balanceOf(collector, id);
        require(balance != 0, "Enable only trait owner");
        TraitWallet memory _traitWallet = traitWallet[id][collector];
        require(_traitWallet.lockAmount >= 1, "Invalid unlocking amount");

        _traitWallet.unlockAmount += 1;
        _traitWallet.lockAmount -= 1;

        require(balance == _traitWallet.lockAmount + _traitWallet.unlockAmount, "Invalid balance when unlocking");
        traitWallet[id][collector] = _traitWallet;

        emit TraitUnlocked(collector, id);
    }

    function _updateTransferableTrait(address from, address to, uint256[] memory ids, uint256[] memory amounts) internal {
        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            require(amount != 0, "Invalid amount when transfer");

            TraitWallet memory fromTraitWallet = traitWallet[id][from];
            TraitWallet memory toTraitWallet = traitWallet[id][to];

            require(amount <= fromTraitWallet.unlockAmount, "Amount is exceed transferable trait");

            fromTraitWallet.unlockAmount -= amount;
            toTraitWallet.unlockAmount += amount;

            traitWallet[id][from] = fromTraitWallet;
            traitWallet[id][to] = toTraitWallet;
        }
    }

    function setBaseUri(string memory _uri)
        external
        onlyOwner
    {
        _setURI(_uri);
        emit BaseUriSet(_msgSender(), _uri);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI)
        external 
        onlyOwner
    {
        _tokenURIs[tokenId] = tokenURI;
        emit MetadataUpdate(tokenId);
    }

    function uri(uint256 tokenId) override(ERC1155) public view returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        return bytes(tokenURI).length > 0 ? tokenURI : string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId)));
    }

    function setERC20Token(address _erc20Token)
        external
        onlyOwner
    {
        require(_erc20Token != address(0), "Invalid ERC20 token");
        erc20Token = IERC20(_erc20Token);

        emit ERC20TokenSet(owner(), _erc20Token);
    }
    function setWithdrawAddress(address payable _withdrawalAddress)
        external
        onlyOwner
    {
        require(_withdrawalAddress != address(0), "Withdrawal address can't be zero address");
        withdrawalAddress = _withdrawalAddress;

        emit WithdrawalAddressSet(owner(), withdrawalAddress);
    }

    function withdrawETH(uint256 amount) 
        external 
        onlyOwner 
    {
        require(amount <= address(this).balance, "Amount exceeds ETH withdrawal limit");
        require(payable(withdrawalAddress).send(amount), "Sending ETH failed");

        emit ETHWithdrawn(owner(), withdrawalAddress, amount);
    }

    function withdrawERC20(uint256 amount)
        external
        onlyOwner
    {
        require(amount <= erc20Token.balanceOf(address(this)), "Amount exceeds ERC20 withdrawal limit");
        erc20Token.safeTransfer(withdrawalAddress, amount);

        emit ERC20Withdrawn(owner(), withdrawalAddress, amount);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        if (from != address(0)) {
            _updateTransferableTrait(from, to, ids, amounts);
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}