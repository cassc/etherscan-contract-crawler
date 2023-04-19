// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/contracts-upgradable/token/onft/ERC721/ONFT721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/RevokableDefaultOperatorFiltererUpgradeable.sol";

contract CedenMintPassV2 is Initializable, ONFT721Upgradeable, ERC2981Upgradeable, RevokableDefaultOperatorFiltererUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => uint) public freeMintList;
    mapping(address => uint) public allowList;
    mapping(address => uint) public openMint;
    IERC20Upgradeable public stableToken;
    address public feeCollectorAddress;
    bool public exclusiveWindow;
    uint public freeMintsLeft;
    uint public price;
    uint public nextMintId;
    /// @custom:oz-renamed-from MAX_MINT_ID
    uint public maxMintId;
    string public baseTokenURI;

    function initialize(string memory _name, string memory _symbol, uint256 _minGasToStore, address _layerZeroEndpoint, address _stableTokenAddress, uint _stableTokenDecimals,  address _feeCollectorAddress) public initializer {
        __ONFT721Upgradeable_init(_name, _symbol, _minGasToStore, _layerZeroEndpoint);
        __ERC2981_init();
        __RevokableDefaultOperatorFilterer_init();
        __Ownable_init();
        stableToken = IERC20Upgradeable(_stableTokenAddress);
        feeCollectorAddress = _feeCollectorAddress;
        exclusiveWindow = true;
        price = 500 * 10**_stableTokenDecimals;
        nextMintId = 0;
        maxMintId = 4444;
        _setDefaultRoyalty(feeCollectorAddress, 269);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ONFT721Upgradeable, ERC2981Upgradeable)
    returns (bool)
    {
        return ONFT721Upgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function owner()
    public
    view
    override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
    returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return _baseURI();
    }

    function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721Upgradeable, IERC721Upgradeable)
    onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
    public
    override(ERC721Upgradeable, IERC721Upgradeable)
    onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721Upgradeable, IERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721Upgradeable, IERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(ERC721Upgradeable, IERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function mint(uint _quantity) external {
        //check if address has free mints left
        if(freeMintList[msg.sender] >= _quantity) {
            freeMintList[msg.sender] -= _quantity;
            freeMintsLeft -= _quantity;
        } else {
            // check if in exclusive time window
            // if so only allowed users can mint
            if(exclusiveWindow) {
                // check if address is in allowList
                require(allowList[msg.sender] >= _quantity, "Allow List amount < mint amount");
                allowList[msg.sender] -= _quantity;
            }
            // else free for all until mint out
            require(nextMintId + _quantity <= maxMintId - freeMintsLeft, "Ceden: Mint exceeds supply");
            stableToken.safeTransferFrom(msg.sender, feeCollectorAddress, price * _quantity);
        }
        for(uint i; i < _quantity;) {
            _safeMint(msg.sender, ++nextMintId);
        unchecked{++i;}
        }
    }

    function addToFreeMintList(address _address, uint _amount) external onlyOwner {
        freeMintsLeft += _amount;
        freeMintList[_address] = _amount;
    }

    function removeFromFreeMintList(address _address) external onlyOwner {
        freeMintsLeft -= freeMintList[_address];
        delete freeMintList[_address];
    }

    function addToAllowList(address _address, uint _amount) external onlyOwner {
        require(_amount <= 10, "Allow List mint range is 1-10");
        allowList[_address] = _amount;
    }

    function setMintPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setExclusiveWindow(bool _exclusiveWindow) public onlyOwner {
        exclusiveWindow = _exclusiveWindow;
    }

    function setMaxMintId(uint _maxMintId) public onlyOwner {
        maxMintId = _maxMintId;
    }

    uint256[50] private __gap;
}