// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

//-- _____ ______ ________ ________ _________ ________ ________ _______
//--|\ _ \ _ \ |\ __ \ |\ ___ \ |\___ ___\|\ __ \ |\ ____\ |\ ___ \
//--\ \ \\\__\ \ \\ \ \|\ \\ \ \\ \ \\|___ \ \_|\ \ \|\ \\ \ \___| \ \ __/|
//-- \ \ \\|__| \ \\ \ \\\ \\ \ \\ \ \ \ \ \ \ \ __ \\ \ \ ___\ \ \_|/__
//-- \ \ \ \ \ \\ \ \\\ \\ \ \\ \ \ \ \ \ \ \ \ \ \\ \ \|\ \\ \ \_|\ \
//-- \ \__\ \ \__\\ \_______\\ \__\\ \__\ \ \__\ \ \__\ \__\\ \_______\\ \_______\
//-- \|__| \|__| \|_______| \|__| \|__| \|__| \|__|\|__| \|_______| \|_______|
//--
//--
//-- Montage.io

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721A_INIT.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTcontract is ERC721A_INIT, OperatorFilterer, ERC2981 {
    //STAGE --- 0=INACTIVE 1=PREMINT 2=PUBLIC
    //PRICETYPE --- 0=FIXED 1=DYNAMIC (If fixed we don't need minPrices)

    bool public operatorFilteringEnabled;
    bool public updateBaseURIStatus;
    bool public putCap;
    uint16 public totalArtists;
    address public collectAddress;
    address public _owner;
    address public admin;
    string public baseURI;
    uint256 public mintsettings;

    mapping(address => uint256) public artistInfo;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event TokensMinted(
        uint256 mintQty,
        address indexed contractAddress,
        address indexed minter,
        address indexed artist,
        uint256 startID
    );
    event EthSent(
        string indexed _function,
        address sender,
        uint256 value,
        bytes data
    );
    event artistRegistered(address[] artists);
    error InputInvalidData();
    error NotExistedToken(uint256 tokenid);
    error TransferFailed();

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == _owner || msg.sender == admin,
            "Ownable: caller is not authorized"
        );
        _;
    }

    modifier isMintActive() {
        require(
            uint8(mintsettings >> 208) != 0,
            "Minting is not currently active."
        );
        _;
    }

    function initialize(
        address _collectAddress,
        address _deployer,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint96 _royalty
    ) public payable initializer {
        super.__ERC721A_init(_tokenName, _tokenSymbol);
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(_collectAddress, _royalty);
        collectAddress = _collectAddress;
        _owner = _deployer;
        baseURI = "https://montage.infura-ipfs.io/ipfs/QmPaYH7MVVoUGHzF8yK1Gp6isBqqZprMUoEjpEQXvn6Xk8";
    }

    receive() external payable {
        emit EthSent("receive()", msg.sender, msg.value, "");
    }

    ///@notice sets/updates mint settings compressing them to uint256 for gas savings
    ///@dev when updating all values must be included. Will update all of them.
    ///@param _pre prement price
    ///@param _pub public sale price
    ///@param _max max mint
    ///@param _stage mint stage must be one of 0=INACTIVE 1=PREMINT 2=PUBLIC"
    function setMintSettings(
        uint256 _pre,
        uint256 _pub,
        uint256 _max,
        uint256 _stage
    ) external onlyOwnerOrAdmin {
        require(
            _stage == 0 || _stage == 1 || _stage == 2,
            "Invalid stage. 0=INACTIVE 1=PREMINT 2=PUBLIC"
        );
        require(
            _max < 2**16 && _pre < 2**96 && _pub < 2**96,
            "invalid max,pre or pub"
        );
        mintsettings = _pre;
        mintsettings |= _pub << 96;
        mintsettings |= _max << 192;
        mintsettings |= _stage << 208;
    }

    ///@notice updates stage only value of mint settings
    ///@dev does not affect other variables
    ///@param _stage mint stage must be one of 0=INACTIVE 1=PREMINT 2=PUBLIC"
    function setStage(uint256 _stage) external onlyOwnerOrAdmin {
        require(
            _stage == 0 || _stage == 1 || _stage == 2,
            "Invalid stage. 0=INACTIVE 1=PREMINT 2=PUBLIC"
        );
        mintsettings |= _stage << 208;
    }

    ///@notice extracts all mint settings from compressed uint256 value
    ///@dev
    ///@return tuple of (uint256 premint price, uint256public price,uint16 max user mint,uint8 stage)
    function extractSettings()
        public
        view
        returns (
            uint256,
            uint256,
            uint16,
            uint8
        )
    {
        return (
            uint256(uint96(mintsettings)),
            uint256(uint96(mintsettings >> 96)),
            uint16(mintsettings >> 192),
            uint8(mintsettings >> 208)
        );
    }

    ///@notice returns total nfts minted per artist
    function getTotalMinted(address artist) public view returns (uint256) {
        return uint256(uint96(artistInfo[artist]));
    }

    ///@notice sets contract admin functions
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    ///@notice registers artist to the contract setting artistinfo for each one and incrementing the totalArtist counter
    ///@dev aristinfo store two values in a uint256: a 1 shifted over 96 bits to indicated the artist has been registered.The total minted nfts inthe first 96 bits
    /// the event artistRegistered can be used to track all registered artists
    ///@param artists array of artists to register
    function addArtists(address[] memory artists) public onlyOwner {
        for (uint256 i = 0; i < artists.length; i++) {
            require(
                artistInfo[artists[i]] == 0,
                "artist is already registered"
            );
            artistInfo[artists[i]] = 1 << 96;
        }
        totalArtists += uint16(artists.length);
        emit artistRegistered(artists);
    }

    ///@notice returns whether an artist is registered or not
    ///@dev uses bitshift to compare the 96 bit of the artistinfo uint256 to one.Used in mint and by buffer contract
    ///@param artist artist address
    ///@return bool
    function isArtist(address artist) public view returns (bool) {
        return (artistInfo[artist] >> 96) == 1;
    }

    // ============ MULTI-MINT ============
    ///@notice allows users to mint multiple nfts for a given artist
    ///@dev uses erc721a minting to save gas. NFT ids are minted incrementally.Valid artist must be supplied.Emits TokensMinted event to create a log associating all ids with supplied artist
    /// increments arist minted count for royalty claim. Current stage price *tokenAmt must be sent in ETH
    ///@param _tokenAmt  number of tokens to mint
    ///@param artist address of artist for token mint
    function mintWithQTY(uint256 _tokenAmt, address artist)
        external
        payable
        isMintActive
    {
        require(!putCap, "Supply has been capped");
        require(_tokenAmt > 0, "Mint at least 1 token.");
        require(isArtist(artist), "artist has not been registered");
        (
            uint256 fixedPresalePrice,
            uint256 fixedPublicSalePrice,
            uint16 maxMintPerWallet,
            uint8 stage
        ) = extractSettings();

        if (maxMintPerWallet > 0) {
            require(
                _tokenAmt + balanceOf(tx.origin) <= uint256(maxMintPerWallet),
                "Exceeds max amount of tokens per wallet address."
            );
        }
        uint256 stageFixedPrice = stage == 1
            ? uint256(fixedPresalePrice)
            : uint256(fixedPublicSalePrice);
        require(
            msg.value >= stageFixedPrice * _tokenAmt,
            "Amount of ether sent not enough for min price per token."
        );
        uint256 startID = _nextTokenId();
        _mint(tx.origin, _tokenAmt);
        artistInfo[artist] += _tokenAmt;
        _transfer(collectAddress, msg.value);
        emit TokensMinted(
            _tokenAmt,
            address(this),
            msg.sender,
            artist,
            startID
        );
    }

    // ============ FUNCTION TO READ TOKENRUI ============
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_exists(_tokenId) == false) {
            revert NotExistedToken(_tokenId);
        }
        if (updateBaseURIStatus == false) {
            return string(abi.encodePacked(baseURI));
        }
        return string(abi.encodePacked(baseURI, _toString(_tokenId), ".json"));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // ============ FUNCTION TO UPDATE ETH COLLECTADDRESS ============
    function setCollectAddress(address _collectAddress)
        external
        onlyOwnerOrAdmin
    {
        // TODO ensure that _collectAddress is a Buffer contract?
        collectAddress = _collectAddress;
    }

    // ============ FUNCTION TO UPDATE BASEURIS ============
    function updateBaseURI(string calldata _baseURI) external onlyOwnerOrAdmin {
        if (putCap == true) {
            revert InputInvalidData();
        }
        updateBaseURIStatus = true;
        baseURI = _baseURI;
    }

    // ============ FUNCTION TO TRIGGER TO CAP THE SUPPLY ============
    function capTrigger(bool _putCap) external onlyOwnerOrAdmin {
        putCap = _putCap;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A_INIT, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A_INIT.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwnerOrAdmin
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwnerOrAdmin {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol

    //============ Function to Transfer ETH to Address ============
    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}