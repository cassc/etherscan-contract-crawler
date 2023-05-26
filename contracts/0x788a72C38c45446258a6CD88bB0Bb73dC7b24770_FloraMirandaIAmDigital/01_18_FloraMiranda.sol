// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

pragma solidity >=0.8.17 <0.9.0;

contract FloraMirandaIAmDigital is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    ERC2981
{
    using Strings for uint256;

    // ================== Variables Start =======================

    // merkletree root hash - p.s set it after deploy from scan
    bytes32 public merkleRoot;

    // reveal uri - p.s set it in contructor (if sniper proof, else put some dummy text and set the actual revealed uri just before reveal)
    string internal uri;
    string public uriExtension = ".json";

    // hidden uri - replace it with yours
    string public hiddenMetadataUri = "ipfs://bafybeialbrcvcyl2kouoyzhz4qx3fk3to25dzt2exgttfxdgmnpu4pfike/1.json";

    // eth prices - replace it with yours
    uint256 public price = 10 ether;
    uint256 public wlprice = 10 ether;

    // usdc prices - replace it with yours | Please note 1 usdc = 100,000 points
    uint256 public usdcprice = 100000000;
    uint256 public usdcwlprice = 100000000 ether;

    // supply - replace it with yours
    uint256 public supplyLimit = 10;
    uint256 public wlsupplyLimit = 10;

    // max per tx - replace it with yours
    uint256 public maxMintAmountPerTx = 10;
    uint256 public wlmaxMintAmountPerTx = 10;

    // max per wallet - replace it with yours
    uint256 public maxLimitPerWallet = 10;
    uint256 public wlmaxLimitPerWallet = 10;

    // enabled
    bool public whitelistSale = false;
    bool public publicSale = true;

    // reveal
    bool public revealed = false;

    // mapping to keep track
    mapping(address => uint256) public wlMintCount;
    mapping(address => uint256) public publicMintCount;

    // total mint trackers
    uint256 public publicMinted;
    uint256 public wlMinted;

    // usdc address and interface - mainnet address is 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address usdcAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    IERC20 usdcContract = IERC20(usdcAddress);

    // Transfer lock
    bool public transferLock = false;

    // royalties info
    uint96 internal royaltyFraction = 1000; // 100 = 1% , 1000 = 10%
    address internal royaltiesReciever =
        0xF5D8e634252653E37aB936A7bE203069D31cf666;

    // ================== Variables End =======================

    // ================== Constructor Start =======================

    // Token NAME and SYMBOL - Replace it with yours
    constructor(string memory _uri) ERC721A("Flora Miranda", "FMIAD") {
        seturi(_uri);
        setRoyaltyInfo(royaltiesReciever, royaltyFraction);
    }

    // ================== Constructor End =======================

    // ================== Mint Functions Start =======================

    // Minting with eth functions

    function WlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
    {
        // Verify wl requirements
        require(whitelistSale, "The WlSale is paused!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        // Normal requirements
        require(
            _mintAmount > 0 && _mintAmount <= wlmaxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= wlsupplyLimit,
            "Max supply exceeded!"
        );
        require(
            wlMintCount[msg.sender] + _mintAmount <= wlmaxLimitPerWallet,
            "Max mint per wallet exceeded!"
        );
        require(msg.value >= wlprice * _mintAmount, "Insufficient funds!");

        // Mint
        _safeMint(_msgSender(), _mintAmount);

        // Mapping update
        wlMintCount[msg.sender] += _mintAmount;
        wlMinted += _mintAmount;
    }

    function PublicMint(uint256 _mintAmount) public payable {
        // Normal requirements
        require(publicSale, "The PublicSale is paused!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= supplyLimit,
            "Max supply exceeded!"
        );
        require(
            publicMintCount[msg.sender] + _mintAmount <= maxLimitPerWallet,
            "Max mint per wallet exceeded!"
        );
        require(msg.value >= price * _mintAmount, "Insufficient funds!");

        // Mint
        _safeMint(_msgSender(), _mintAmount);

        // Mapping update
        publicMintCount[msg.sender] += _mintAmount;
        publicMinted += _mintAmount;
    }

    function OwnerMint(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount <= supplyLimit,
            "Max supply exceeded!"
        );
        _safeMint(_receiver, _mintAmount);
    }

    function MassAirdrop(address[] calldata receivers) external onlyOwner {
        for (uint256 i; i < receivers.length; ++i) {
            require(totalSupply() + 1 <= supplyLimit, "Max supply exceeded!");
            _mint(receivers[i], 1);
        }
    }

    // Minting with usdc functions

    function WlMintWithUSDC(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable {
        // Verify wl requirements
        require(whitelistSale, "The WlSale is paused!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        // Normal requirements
        require(
            _mintAmount > 0 && _mintAmount <= wlmaxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= wlsupplyLimit,
            "Max supply exceeded!"
        );
        require(
            wlMintCount[msg.sender] + _mintAmount <= wlmaxLimitPerWallet,
            "Max mint per wallet exceeded!"
        );

        // transfer usdc from minter to the contract
        uint256 amountToSend = usdcwlprice * _mintAmount;
        require(
            usdcContract.allowance(msg.sender, address(this)) >= amountToSend,
            "Allowance not met"
        );
        usdcContract.transferFrom(msg.sender, address(this), amountToSend);

        // Mint
        _safeMint(_msgSender(), _mintAmount);

        // Mapping update
        wlMintCount[msg.sender] += _mintAmount;
        wlMinted += _mintAmount;
    }

    function PublicMintWithUSDC(uint256 _mintAmount) public payable {
        // Normal requirements
        require(publicSale, "The PublicSale is paused!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= supplyLimit,
            "Max supply exceeded!"
        );
        require(
            publicMintCount[msg.sender] + _mintAmount <= maxLimitPerWallet,
            "Max mint per wallet exceeded!"
        );

        // transfer usdc from minter to the contract
        uint256 amountToSend = usdcprice * _mintAmount;
        require(
            usdcContract.allowance(msg.sender, address(this)) >= amountToSend,
            "Allowance not met"
        );
        usdcContract.transferFrom(msg.sender, address(this), amountToSend);

        // Mint
        _safeMint(_msgSender(), _mintAmount);

        // Mapping update
        publicMintCount[msg.sender] += _mintAmount;
        publicMinted += _mintAmount;
    }

    // ================== Mint Functions End =======================

    // ================== Set Functions Start =======================

    // reveal
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    // uri
    function seturi(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function seturiExtension(string memory _uriExtension) public onlyOwner {
        uriExtension = _uriExtension;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    // sales toggle
    function setpublicSale(bool _publicSale) public onlyOwner {
        publicSale = _publicSale;
    }

    function setwlSale(bool _whitelistSale) public onlyOwner {
        whitelistSale = _whitelistSale;
    }

    // hash set
    function setwlMerkleRootHash(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // max per tx
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setwlmaxMintAmountPerTx(uint256 _wlmaxMintAmountPerTx)
        public
        onlyOwner
    {
        wlmaxMintAmountPerTx = _wlmaxMintAmountPerTx;
    }

    // pax per wallet
    function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
        maxLimitPerWallet = _maxLimitPerWallet;
    }

    function setwlmaxLimitPerWallet(uint256 _wlmaxLimitPerWallet)
        public
        onlyOwner
    {
        wlmaxLimitPerWallet = _wlmaxLimitPerWallet;
    }

    // price
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setwlPrice(uint256 _wlprice) public onlyOwner {
        wlprice = _wlprice;
    }

    function setusdcPrice(uint256 _usdcprice) public onlyOwner {
        usdcprice = _usdcprice;
    }

    function setusdcwlPrice(uint256 _usdcwlprice) public onlyOwner {
        usdcwlprice = _usdcwlprice;
    }

    // set usdc contract address
    function setUSDCcontractAddress(address _address) public onlyOwner {
        usdcAddress = _address;
    }

    // supply limit
    function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
        supplyLimit = _supplyLimit;
    }

    function setwlsupplyLimit(uint256 _wlsupplyLimit) public onlyOwner {
        wlsupplyLimit = _wlsupplyLimit;
    }

    // transfer lock
    function setTransferLock(bool _state) public onlyOwner {
        transferLock = _state;
    }

    // set royalties info

    function setRoyaltyTokens(
        uint256 _tokenId,
        address _receiver,
        uint96 _royaltyFeesInBips
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _royaltyFeesInBips);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    // ================== Set Functions End =======================

    // ================== Withdraw Function Start =======================

    function withdraw() public onlyOwner nonReentrant {
        //owner withdraw
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawUSDC() public onlyOwner nonReentrant {
        uint256 balance = usdcContract.balanceOf(address(this));
        usdcContract.transfer(msg.sender, balance);
    }

    // ================== Withdraw Function End=======================

    // ================== Read Functions Start =======================

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner));
            uint256 end = _nextTokenId();
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /*
     * @notice Block transfers.
     */

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (transferLock == true) {
            require(
                from == address(0) || to == address(0),
                "Transfers are not available at the moment."
            );
        }
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    event ethReceived(address, uint256);

    receive() external payable {
        emit ethReceived(msg.sender, msg.value);
    }
    // ================== Read Functions End =======================
}