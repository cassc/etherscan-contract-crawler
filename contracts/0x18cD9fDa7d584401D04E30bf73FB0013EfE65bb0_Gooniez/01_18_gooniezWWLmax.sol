// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
contract Gooniez is ERC721, Ownable, IERC2981, PaymentSplitter {
    using Strings for uint256;
    using SafeMath for uint256;
    string baseURI;
    string baseExtension = ".json";
    string public contractUri;
    string public notRevealedUri;
    uint256 public cost = 0.25 ether;
    uint256 public whitelistCost = 0.15 ether;
    uint256 public maxSupply = 8888;
    uint256 public maxSupplyWhitelist = 4000;
    uint256 public maxMintAmount = 2;
    uint256 public maxMintAmountWhitelist = 1;
    uint256 public nftPerAddressLimit = 3;
    bool public paused = true;
    bool public revealed = false;
    bool public onlyWhitelisted = true;
    mapping(address => bool) public whitelistedAddresses;
    uint256 public whiteListSaleStart = 1644418800;
    uint256 public publicSaleStart = 1644433200;
    bool public allowMarketingMint = true;
    uint256 public immutable totalPayees;
    address[] public _payees = [0xea7c3a066E343DA79d9381F02B7a85879999E039,0x9B8ACEE8d67e8ff8ef8B2A86112eDE91210e68de,0x2E79FCF1327DA12725c9FaB64C37F47695768a4E,0xaC4ed7804f6596D51C7a46A8fCA4D0A3a5d163C7,0xFE2d9A345768c146C0a0f37474F3f6E1b635E0B8,0xC04a344363598eF498E6FF9ACD1f922d9357F2da,0xC15993bDee0921d4C62E392bE86ebA726841507a];
    uint256[] public _shares = [4,27,27,27,5,5,5];
    // emit when royalties recieved
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    event RoyaltiesReceived(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    );
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        string memory initContractUri
    ) ERC721(_name, _symbol) PaymentSplitter(_payees, _shares) payable {
        for (uint256 i = 0; i < _payees.length; i++) {
            require(_payees[i].code.length == 0, "Contracts is not allowed as payees");
        }
        totalPayees = _payees.length;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        contractUri = initContractUri;
    }
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function mintToMarketingWallet() public onlyOwner {
        require(allowMarketingMint == true, "Marketing mint can only occur once.");
        for (uint256 i = 1; i < 351; i++) {
            _tokenSupply.increment();
            _safeMint(0xFE2d9A345768c146C0a0f37474F3f6E1b635E0B8, _tokenSupply.current());
        }

        // allow marketing mint to occur once.
        allowMarketingMint = false;
    }
    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "Minting is paused");
        require(block.timestamp > whiteListSaleStart, "Not started");
        uint256 supply = _tokenSupply.current();
        require(_mintAmount > 0, "Mint amount should be greater than 0");
        if (onlyWhitelisted == true && block.timestamp < publicSaleStart) {
            require(_mintAmount < maxMintAmountWhitelist + 1, "Limit is 1 token per one mint during the whitelist");
            require(balanceOf(msg.sender) + _mintAmount < 2, "Limit is 1 token per account during the whitelist");
        } else {
            require(_mintAmount < maxMintAmount + 1, "Limit is 2 tokens per one mint");
            require(balanceOf(msg.sender) + _mintAmount < nftPerAddressLimit + 1, "Limit is 3 tokens per account");
        }
        
        if (onlyWhitelisted == true && block.timestamp < publicSaleStart) {
            require(supply + _mintAmount < maxSupplyWhitelist + 1, "Max supply overflow for the whitelist sale");
        } else {
            require(supply + _mintAmount < maxSupply + 1, "Max supply overflow");
        }
        if (msg.sender != owner()) {
            if (onlyWhitelisted == true && block.timestamp < publicSaleStart) {
                require(isWhitelisted(msg.sender), "Account is not whitelisted");
                require(msg.value >= whitelistCost * _mintAmount, "Not enough funds sent for the whitelist sale");
            } else {
                require(msg.value >= cost * _mintAmount, "Not enough funds sent");
            }
        }
        for (uint256 i = 1; i < _mintAmount + 1; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }
    function isWhitelisted(address user) public view returns (bool) {
        return whitelistedAddresses[user];
    }
    function currentTotalTokens() public view returns (uint256) {
        return _tokenSupply.current();
    }
    function isWhitelistSoldOut() public view returns (bool) {
        return _tokenSupply.current() >= maxSupplyWhitelist;
    }
    function isSoldOut() public view returns (bool) {
        return _tokenSupply.current() >= maxSupply;
    }
    function isOnlyWhitelisted() public view returns (bool) {
        return onlyWhitelisted == true && block.timestamp < publicSaleStart;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }
    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }
    function setNftPerAddressLimit(uint256 _nftPerAddressLimit)
        public
        onlyOwner
    {
        nftPerAddressLimit = _nftPerAddressLimit;
    }
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whitelistCost = _newCost;
    }
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }
    function whitelistUsers(address[] calldata users) external onlyOwner {
        for (uint256 i; i < users.length; i++) {
            whitelistedAddresses[users[i]] = true;
        }
    }
    function deleteFromWhitelist(address user) external onlyOwner {
        whitelistedAddresses[user] = false;
    }
    function setDates(uint256 _whiteListSaleStart, uint256 _publicSaleStart) external onlyOwner {
        whiteListSaleStart = _whiteListSaleStart;
        publicSaleStart = _publicSaleStart;
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    /**
     * @notice Returns royalty reciever address and royalty amount
     * @param _tokenId Token Id
     * @param _salePrice Value to calculate royalty from
     * @return receiver Royalty reciever address
     * @return amount Royalty amount
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 amount)
    {
        require(_tokenId > 0);
        receiver = this.owner();
        if (_salePrice <= 100) {
            amount = 0;
        } else {
            amount = _salePrice.mul(5).div(100);
        }
    }
    /**
     * @notice Calls when royalty recieved
     */
    function onRoyaltiesReceived(
        address _royaltyRecipient,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    ) external returns (bytes4) {
        emit RoyaltiesReceived(
            _royaltyRecipient,
            _buyer,
            _tokenId,
            _tokenPaid,
            _amount,
            _metadata
        );
        return
            bytes4(
                keccak256(
                    "onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)"
                )
            );
    }

    /**
     * @notice Withdraw all ETH amount to all payees according to their percentage of the
     * total shares. Will fail if at least one of payees already has withdrawn all his portion
     */
    function batchRelease() external onlyOwner {
        for (uint256 i = 0; i < totalPayees; i++) {
            address payeeAddress = payee(i);
            release(payable(payeeAddress));
        }
    }
}