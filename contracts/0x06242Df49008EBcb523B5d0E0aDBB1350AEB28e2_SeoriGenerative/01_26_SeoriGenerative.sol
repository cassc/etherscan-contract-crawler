// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./AntiScam/RestrictApprove/RestrictApprove.sol";

//tokenURI interface
interface ITokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract SeoriGenerative is ERC2981, DefaultOperatorFilterer, Ownable, ERC721A, AccessControl, RestrictApprove {
    constructor() ERC721A("SeoriGenerative", "SEORI") {
        //Role initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(AIRDROP_ROLE, msg.sender);

        //first mint and burn
        _mint(msg.sender, 5);

        //for test
        //setOnlyAllowlisted(false);
        //setMintCount(false);
        //setPause(false);
        //setMaxSupply(6);

        // Set royalty as 10%
        _setDefaultRoyalty(withdrawAddress, 1000);

        // Initialize RestrictApprove
        // To save deployment size, not use initializerAntiScam and initialize directly.
        //__RestrictApprove_init();
        _setCALLevel(1);
        _setRestrictEnabled(true);
        _setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);//Ethereum mainnet proxy
        // _setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);//Goerli testnet proxy
    }

    ///////////////////////////////////////////////////////////////////////////
    // Withdraw function
    ///////////////////////////////////////////////////////////////////////////

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Variables and Constants
    ///////////////////////////////////////////////////////////////////////////

    address public constant withdrawAddress =
        0xddf110763eBc75419A39150821c46a58dDD2d667;
    uint256 public constant maxSupply = 5000;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    uint256 public cost = 0.001 ether;
    uint8 public maxMintAmountPerTransaction = 100;
    uint16 public publicSaleMaxMintAmountPerAddress = 300;
    bool public paused = true;

    bool public onlyAllowlisted = true;
    bool public mintCount = true;
    bool public burnAndMintMode;// = false;

    bool public isSBT = false;

    //0 : Merkle Tree
    //1 : Mapping
    uint8 public allowlistType;// = 0;
    uint16 public saleId;// = 0;
    bytes32 public merkleRoot = 0xa5b07db99cc7e790aea5121ef230a1781b181eee17ba26a12a469781c539419a;
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;
    mapping(uint256 => mapping(address => uint256)) public allowlistUserAmount;

    ITokenURI public interfaceOfTokenURI;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Override internal mint function to restrict supply
    ///////////////////////////////////////////////////////////////////////////
    function _mint(address to, uint256 quantity) internal virtual override {
        if (totalSupply() + quantity > maxSupply) revert ("max NFT limit exceeded");
        super._mint(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint function for sale
    ///////////////////////////////////////////////////////////////////////////
    function mint(
        uint256 _mintAmount,
        uint256 _maxMintAmount,
        bytes32[] calldata _merkleProof,
        uint256 _burnId
    ) public payable callerIsUser {
        require(!paused, "the contract is paused");
        // Double check
        // require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmountPerTransaction,
            "max mint amount per session exceeded"
        );
        /* change check supply in _mint()
        require(
            _nextTokenId() + _mintAmount <= maxSupply,
            "max NFT limit exceeded"
        );
        */
        require(cost * _mintAmount <= msg.value, "insufficient funds");

        uint256 maxMintAmountPerAddress;
        if (onlyAllowlisted == true) {
            if (allowlistType == 0) {
                //Merkle tree
                bytes32 leaf = keccak256(
                    abi.encodePacked(msg.sender, _maxMintAmount)
                );
                require(
                    MerkleProof.verify(_merkleProof, merkleRoot, leaf),
                    "user is not allowlisted"
                );
                maxMintAmountPerAddress = _maxMintAmount;
            } else if (allowlistType == 1) {
                //Mapping
                require(
                    allowlistUserAmount[saleId][msg.sender] != 0,
                    "user is not allowlisted"
                );
                maxMintAmountPerAddress = allowlistUserAmount[saleId][
                    msg.sender
                ];
            }
        } else {
            maxMintAmountPerAddress = uint256(publicSaleMaxMintAmountPerAddress);
        }

        if (mintCount == true) {
            require(
                _mintAmount <=
                    maxMintAmountPerAddress -
                        userMintedAmount[saleId][msg.sender],
                "max NFT per address exceeded"
            );
            userMintedAmount[saleId][msg.sender] += _mintAmount;
        }

        if (burnAndMintMode == true) {
            require(_mintAmount == 1, "");
            require(msg.sender == ownerOf(_burnId), "Owner is different");
            _burn(_burnId);
        }

        // Under callerIsUser, safeMint wastes gas without meanings.
        //_safeMint(msg.sender, _mintAmount);
        _mint(msg.sender, _mintAmount);
    }


    function airdropMint(
        address[] calldata _airdropAddresses,
        uint256[] memory _UserMintAmount
    ) public {
        require(
            hasRole(AIRDROP_ROLE, msg.sender),
            "Caller is not a air dropper"
        );
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "max NFT limit exceeded"
        );
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i]);
        }
    }

    function setBurnAndMintMode(bool _burnAndMintMode) public onlyOwner {
        burnAndMintMode = _burnAndMintMode;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setAllowListType(uint256 _type) public onlyOwner {
        require(_type == 0 || _type == 1, "Allow list type error");
        allowlistType = uint8(_type);
    }

    function setAllowlistMapping(
        uint256 _saleId,
        address[] memory addresses,
        uint256[] memory saleSupplies
    ) public onlyOwner {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlistUserAmount[_saleId][addresses[i]] = saleSupplies[i];
        }
    }

    function getAllowlistUserAmount(
        address _address
    ) public view returns (uint256) {
        return allowlistUserAmount[saleId][_address];
    }

    function getUserMintedAmountBySaleId(
        uint256 _saleId,
        address _address
    ) public view returns (uint256) {
        return userMintedAmount[_saleId][_address];
    }

    function getUserMintedAmount(
        address _address
    ) public view returns (uint256) {
        return userMintedAmount[saleId][_address];
    }

    function setSaleId(uint256 _saleId) public onlyOwner {
        saleId = uint8(_saleId);
    }

    /* maxSupply changed to constant
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    */

    function setPublicSaleMaxMintAmountPerAddress(
        uint256 _publicSaleMaxMintAmountPerAddress
    ) public onlyOwner {
        publicSaleMaxMintAmountPerAddress = uint16(_publicSaleMaxMintAmountPerAddress);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyAllowlisted(bool _state) public onlyOwner {
        onlyAllowlisted = _state;
    }

    function setMaxMintAmountPerTransaction(
        uint256 _maxMintAmountPerTransaction
    ) public onlyOwner {
        maxMintAmountPerTransaction = uint8(_maxMintAmountPerTransaction);
    }

    function setMintCount(bool _state) public onlyOwner {
        mintCount = _state;
    }

    ///////////////////////////////////////////////////////////////////////////
    // tokenURI Descriptor
    ///////////////////////////////////////////////////////////////////////////

    function setInterfaceOfTokenURI(address _address) public onlyOwner {
        interfaceOfTokenURI = ITokenURI(_address);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _exists(tokenId);
        if (address(interfaceOfTokenURI) != address(0)) {
            return interfaceOfTokenURI.tokenURI(tokenId);
        }
        return "";
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721A set start TokenID
    ///////////////////////////////////////////////////////////////////////////

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    ///////////////////////////////////////////////////////////////////////////
    // external Mint / Burn function 
    ///////////////////////////////////////////////////////////////////////////

    function externalMint(address _address, uint256 _amount) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        /*
        require(
            _nextTokenId() - 1 + _amount <= maxSupply,
            "max NFT limit exceeded"
        );
        */
        _safeMint(_address, _amount);
    }

    function externalBurn(uint256[] memory _burnTokenIds) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            // For future extension, comment out the following check since it restricts burning byself. 
            // require(msg.sender == ownerOf(tokenId), "Owner is different");
            _burn(tokenId);
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // IERC721RestrictApprove Override setter functions
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @dev Set CAL Level.
     */
    function setCALLevel(uint256 level) external onlyOwner {
        _setCALLevel(level);
    }

    /**
     * @dev Set `calAddress` as the new proxy of the contract allow list.
     */
    function setCAL(address calAddress) external onlyOwner {
        _setCAL(calAddress);
    }

    /**
     * @dev Add `transferer` to local contract allow list.
     */
    function addLocalContractAllowList(address transferer) external onlyOwner {
        _addLocalContractAllowList(transferer);
    }

    /**
     * @dev Remove `transferer` from local contract allow list.
     */
    function removeLocalContractAllowList(address transferer) external onlyOwner {
        _removeLocalContractAllowList(transferer);
    }

    /**
     * @dev Set which the restriction by CAL is enabled.
     */
    function setRestrictEnabled(bool value)
        external
        onlyOwner
    {
        _setRestrictEnabled(value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // SBTizer 
    ///////////////////////////////////////////////////////////////////////////

    function setIsSBT(bool _state) public onlyOwner {
        isSBT = _state;
    }
    
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) 
        internal 
        virtual 
        override
        onlyTransferable(from, to, startTokenId, quantity)
    {
        require(
            isSBT == false ||
                from == address(0) ||
                to == address(0x000000000000000000000000000000000000dEaD),
            "transfer is prohibited"
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
        onlyWalletApprovable(operator, msg.sender, approved)
    {
        require(isSBT == false, "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) 
        public 
        payable 
        virtual 
        override 
        onlyAllowedOperatorApproval(to) 
        onlyTokenApprovable(to, tokenId)
    {
        require(isSBT == false, "approve is prohibited");
        super.approve(to, tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC2981 Royalty
    ///////////////////////////////////////////////////////////////////////////
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC165 Override
    ///////////////////////////////////////////////////////////////////////////
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC2981, ERC721A, AccessControl) returns (bool) {
        return
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // override transfer functions
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


}