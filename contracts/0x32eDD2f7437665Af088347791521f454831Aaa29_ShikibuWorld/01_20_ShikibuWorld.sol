// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;
import "./contract-allow-list/contracts/ERC721AntiScam/restrictApprove/ERC721RestrictApprove.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./OperatorFilterRegistry/DefaultOperatorFilterer.sol";
import "./interface/ITokenURI.sol";

contract ShikibuWorld is
    Ownable,
    AccessControl,
    ERC721RestrictApprove,
    DefaultOperatorFilterer {
    using ECDSA for bytes32;

    function supportsInterface(bytes4 interfaceId) public view virtual 
        override(AccessControl,ERC721RestrictApprove) returns (bool) {
        return
        interfaceId == type(IAccessControl).interfaceId ||
        interfaceId == type(ERC721RestrictApprove).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    string public baseURI ="";
    string public baseExtension = ".json";
    ITokenURI public tokenuri;

    uint256 public constant MAX_SUPPLY = 10000;
    bytes32 public constant ADMIN = keccak256("ADMIN");

    uint256 public maxReservedSupply = 3295;
    uint256 public ReservedMinted;
    uint256 public maxPri2MintAmmount = 1;
    uint256 public mintCost = 0.001 ether;
    uint256 public maxBurnMintSupply = 2000;
    uint256 public burnMintCost = 0.001 ether;
    uint256 public burnMintIndex;

    address public withdrawAddress = 0xCEF8d9251d3fF8674ba91ab24F0ee3652074EC64;
    address public constant TREASURY_ADDRESS_1 = 0xCEF8d9251d3fF8674ba91ab24F0ee3652074EC64; // 1 + 499
    address public constant TREASURY_ADDRESS_2 = 0x60673e51562dBd400c6F999f20fF07F14436fa13; //     400
    address public constant TREASURY_ADDRESS_3 = 0x0a8D214fc82569f712d3F3Fa4B0fc921d49d74B0; //    1500
    address public constant TREASURY_ADDRESS_4 = 0xee93e2D824b62d408024D9fC87C1926d7a38428F; //     100

    address public adminSigner;

    mapping(address => uint256) public pri1MintCount;
    mapping(address => uint256) public pri2MintCount;
    
    struct BurnMintStruct {
        bool isDone;
        mapping(address => uint256) numberOfBurnMintByAddress;
    }
    mapping(uint256 => BurnMintStruct) public burnMintStructs;

    enum SalePhase {
        Locked,
        Pri1Sale,
        Pri2Sale,
        Pri3Sale,
        BurnMint
    }
    SalePhase public phase = SalePhase.Locked;

    constructor() ERC721A("Shikibu World", "SKB") {
        setBaseURI('https://shikibu-world.s3.ap-northeast-1.amazonaws.com/metadata/');
        adminSigner = 0xa1F043f0aBfA7F0979524d910B87B3c780E0cD31;
        _grantRole(ADMIN,0x1b632c9a883DF07A18d4b2813840E029bEceFf6D);
        _grantRole(ADMIN,0x480d565527086DC3dc2262648194E1e9cCAB70EF);
        _grantRole(ADMIN,0x3FFcb00bE71F4a0Aa2d8624fBA4e97203FA3EA3B);
        _grantRole(ADMIN,0xf3CfAD477A0f8443b0b6E81BF7A4a1fF7B69D46f);
        _grantRole(ADMIN,0x0dAE5FcaD0DF8E5C029D76927582DFBdFd7eeC79);
        _safeMint(TREASURY_ADDRESS_1,1);
    }

    ////////// modifiers //////////
    modifier onlyAdminOrOwner() {
        require(
            owner() == _msgSender() || hasRole(ADMIN, msg.sender),
            "caller is not the admin"
        );
        _;
    }

    ////////// public functions //////////
    // Private1セール(AL) function
    function pri1Mint(
        uint256 _mintAmount,
        uint256 _allocated,
        bytes calldata _signature
    ) external payable {
        // コントラクトからのミントガード
        require(tx.origin == msg.sender, "Cannot mint from contracts");

        // セールフェイズチェック
        require(phase == SalePhase.Pri1Sale, "Pri1Sale is disabled");

        // ミント数がゼロでないこと
        require(_mintAmount != 0, "mintAmount is zero");

        // 署名チェック
        require(
            keccak256(abi.encodePacked(phase, msg.sender, _allocated, "|", pri1MintCount[msg.sender]))
                .toEthSignedMessageHash()
                .recover(_signature) == adminSigner,
            "invalid proof."
        );

        // ミント数上限チェック
        require(
            pri1MintCount[msg.sender] + _mintAmount <= _allocated,
            "exceeds number of earned Tokens"
        );

        // ミントコストチェック
        require(mintCost * _mintAmount <= msg.value, "not enough eth");

        // ミント数がMAX SUPPLY - 予約枠を超えていないかチェック
        require(
            _mintAmount + totalSupply() - ReservedMinted <= MAX_SUPPLY - maxReservedSupply,
            "claim is over the max supply"
        );

        _safeMint(msg.sender, _mintAmount);

        // プレセールミント数済み数加算
        pri1MintCount[msg.sender] += _mintAmount;
    }

    // 予約者ミント(AL/予約あり) function
    function reservedMint(
        uint256 _mintAmount,
        uint256 _allocated,
        bytes calldata _signature
    ) external payable {
        // コントラクトからのミントガード
        require(tx.origin == msg.sender, "Cannot mint from contracts");

        // セールフェイズチェック
        require(phase == SalePhase.Pri1Sale || phase == SalePhase.Pri3Sale, "sale is disabled");

        // ミント数がゼロでないこと
        require(_mintAmount != 0, "mintAmount is zero");

        // 署名チェック
        require(
            keccak256(abi.encodePacked(phase, msg.sender, _allocated, "|", pri1MintCount[msg.sender], "RESERVED"))
                .toEthSignedMessageHash()
                .recover(_signature) == adminSigner,
            "invalid proof."
        );

        // ミント数上限チェック
        require(
            pri1MintCount[msg.sender] + _mintAmount <= _allocated,
            "exceeds number of earned Tokens"
        );

        // 予約ミント数上限チェック
        require(
            ReservedMinted + _mintAmount <= maxReservedSupply,
            "exceeds number of earned reserved Tokens"
        );

        // ミントコストチェック
        require(mintCost * _mintAmount <= msg.value, "not enough eth");

        // ミント数がMAX SUPPLYを超えていないかチェック
        require(
            _mintAmount + totalSupply() <= MAX_SUPPLY,
            "claim is over the max supply"
        );

        _safeMint(msg.sender, _mintAmount);

        // プレセールミント数済み加算
        pri1MintCount[msg.sender] += _mintAmount;

        // ミント済み予約枠加算
        ReservedMinted += _mintAmount;
    }

    // Private2(早押し)セール function
    function pri2Mint(
        uint256 _mintAmount,
        bytes calldata _signature
    ) external payable {
        // コントラクトからのミントガード
        require(tx.origin == msg.sender, "Cannot mint from contracts");
        
        // セールフェイズチェック
        require(phase == SalePhase.Pri2Sale, "Pri2Sale is disabled");
        
        // ミント数が1であること
        require(_mintAmount == 1, "mintAmount is not 1");

        // 署名チェック
        require(
            keccak256(abi.encodePacked(phase, msg.sender, maxPri2MintAmmount, "|", pri2MintCount[msg.sender]))
                .toEthSignedMessageHash()
                .recover(_signature) == adminSigner,
            "invalid proof."
        );

        // 早押しミント数上限チェック
        require(
            pri2MintCount[msg.sender] + _mintAmount <= maxPri2MintAmmount,
            "exceeds number of maxMint"
        );

        // ミントコストチェック
        require(mintCost * _mintAmount <= msg.value, "not enough eth");

        // ミント数がMAX SUPPLY - 予約枠を超えていないかチェック
        require(
            _mintAmount + totalSupply() - ReservedMinted <= MAX_SUPPLY - maxReservedSupply,
            "claim is over the max supply"
        );

        _safeMint(msg.sender, _mintAmount);
    
        // 早押しミント数済み加算
        pri2MintCount[msg.sender] += _mintAmount;
    }

    // AdminMint function
    function adminMint(
        address _mintTo,
        uint256 _mintAmount
    ) external onlyAdminOrOwner{
        // ミント数がゼロでないこと
        require(_mintAmount != 0, "mintAmount is zero");

        // ミント数がMAX SUPPLYを超えていないかチェック
        require(
            _mintAmount + totalSupply() <= MAX_SUPPLY,
            "claim is over the max supply"
        );

        _safeMint(_mintTo, _mintAmount);
    }

	function adminMint_array(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) external onlyAdminOrOwner{
	    uint256 supply = totalSupply();
	    uint256 _mintAmount = 0;
	    for (uint256 i = 0; i < _UserMintAmount.length; i++) {
	        _mintAmount += _UserMintAmount[i];
	    }
	    require(_mintAmount > 0, "need to mint at least 1 NFT");
	    require(supply + _mintAmount <= MAX_SUPPLY, "max NFT limit exceeded");
	    require(_airdropAddresses.length ==  _UserMintAmount.length, "array length unmuch");

	    for (uint256 i = 0; i < _UserMintAmount.length; i++) {
	        _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
	    }
	}

    // バーンミント function
    function burnMint(
        uint256[] memory _burnTokenIds,
        uint256 _allocated,
        bytes calldata _signature
    ) external payable {
        // コントラクトからのミントガード
        require(tx.origin == msg.sender, "Cannot mint from contracts");

        // セールフェイズチェック
        require(phase == SalePhase.BurnMint, "burnMint is disabled");

        // バーンミント数がゼロでないこと
        require(_burnTokenIds.length != 0, "the quantity is zero");

        // バーンミント署名チェック
        require(
            keccak256(abi.encodePacked(
                        phase,
                        burnMintIndex,
                        msg.sender,
                        _allocated, "|", 
                        burnMintStructs[burnMintIndex].numberOfBurnMintByAddress[msg.sender]))
                .toEthSignedMessageHash()
                .recover(_signature) == adminSigner,
            "invalid proof."
        );

        // バーンミント割り当て数を超えていないかチェック
        require(
            burnMintStructs[burnMintIndex].numberOfBurnMintByAddress[
                msg.sender
            ] +
                _burnTokenIds.length <=
                _allocated,
            "address already claimed max amount"
        );

        // ミントコストチェック
        require(burnMintCost * _burnTokenIds.length <= msg.value, "not enough eth");

        // バーン最大数を超えていないかチェック
        require(
            _burnTokenIds.length + _totalBurned() <= maxBurnMintSupply,
            "over total burn count"
        );

        // バーンミント割り当て数加算
        burnMintStructs[burnMintIndex].numberOfBurnMintByAddress[
                msg.sender
            ] += _burnTokenIds.length;

        // バーン実行
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(
                _msgSender() == ownerOf(tokenId),
                "sender is not the owner of the token"
            );
            _burn(tokenId);
        }

        // バーン後ミント実行
        _safeMint(msg.sender, _burnTokenIds.length);
    }

    ////////// onlyOwner functions //////////
    function setAdminRole(address[] memory admins) external onlyOwner{
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(ADMIN, admins[i]);
        }
    }

    function revokeAdminRole(address[] memory admins) external onlyOwner{
        for (uint256 i = 0; i < admins.length; i++) {
            _revokeRole(ADMIN, admins[i]);
        }
    }

    ////////// onlyAdminOrOwner functions //////////
    function setMaxReservedSupply(uint256 _value) public onlyAdminOrOwner {
        maxReservedSupply = _value;
    }

    function setmaxPri2MintAmmount(uint256 _value) public onlyAdminOrOwner {
        maxPri2MintAmmount = _value;
    }

    function setMintCost(uint256 _value) public onlyAdminOrOwner {
        mintCost = _value;
    }

    function setBaseURI(string memory _value) public onlyAdminOrOwner {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value) public onlyAdminOrOwner {
        baseExtension = _value;
    }

    function setTokenURI(ITokenURI _tokenuri) external onlyAdminOrOwner{
        tokenuri = _tokenuri;
    }

    function setAdminSigner(address _adminSigner) external onlyAdminOrOwner {
        require(_adminSigner != address(0), "address shouldn't be 0");
        adminSigner = _adminSigner;
    }

    function setPhase(SalePhase _phase) external onlyAdminOrOwner {
        phase = _phase;
    }

    function setWithdrawAddress(address _withdrawAddress) external onlyAdminOrOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() external payable onlyAdminOrOwner {
        require(
            withdrawAddress != address(0),
            "withdrawAddress shouldn't be 0"
        );
        (bool sent, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(sent, "failed to move fund to withdrawAddress contract");
    }

    function setBurnMintCost(uint256 _cost) external onlyAdminOrOwner {
        burnMintCost = _cost;
    }

    function setMaxBurnMintSupply(uint256 _amount) external onlyAdminOrOwner {
        maxBurnMintSupply = _amount;
    }

    function increaseBurnMintIndex() external onlyAdminOrOwner {
        burnMintStructs[burnMintIndex].isDone = true;
        burnMintIndex += 1;
    }

    ////////// OVERRIDES ERC721A functions //////////
    function _beforeTokenTransfers(
        address from,
        address /*to*/,
        uint256 /*startTokenId*/,
        uint256 quantity
    ) internal view override {
        // Treasury Lock-up
        if(block.timestamp > 1986303600) { // UNIXTIME 2032-12-11 00:00
            return; // Lock-up completed
        }

        if(from == TREASURY_ADDRESS_3) {
            uint32[10] memory treasuryUnlockTime= [
                1702220400, // UNIXTIME 2023-12-11 00:00
                1733842800, // UNIXTIME 2024-12-11 00:00
                1765378800, // UNIXTIME 2025-12-11 00:00
                1796914800, // UNIXTIME 2026-12-11 00:00
                1828450800, // UNIXTIME 2027-12-11 00:00
                1860073200, // UNIXTIME 2028-12-11 00:00
                1891609200, // UNIXTIME 2029-12-11 00:00
                1923145200, // UNIXTIME 2030-12-11 00:00
                1954681200, // UNIXTIME 2031-12-11 00:00
                1986303600  // UNIXTIME 2032-12-11 00:00
                ];
            uint16[10] memory treasuryLockAmmount= [
                1000, 900, 800,	700, 600, 500, 400, 300, 200, 100
            ];

            for(uint8 timeIndex = 0; timeIndex < treasuryUnlockTime.length; timeIndex++) {
                if(block.timestamp < treasuryUnlockTime[timeIndex]) {
                    require(
                        balanceOf(from) - quantity >= treasuryLockAmmount[timeIndex],
                        "Transfer is not possible during lockup.");
                    return;
                } 
            }
        }
    }

    ////////// OVERRIDES ERC721RestrictApprove functions //////////
    function addLocalContractAllowList(address transferer)
        public
        override
        onlyAdminOrOwner
    {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        public
        override
        onlyAdminOrOwner
    {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList() 
        public
        override
        view
        returns(address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCALLevel(uint256 level) public override onlyAdminOrOwner {
        CALLevel = level;
    }

    function setCAL(address calAddress) public override onlyAdminOrOwner {
        _setCAL(calAddress);
    }

    ////////// OVERRIDES OperatorFilter functions //////////
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    ////////// public functions //////////
    function totalBurned() public view virtual returns (uint256) {
        return _totalBurned();
    }

    ////////// other functions //////////
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (address(tokenuri) != address(0)) {
            return tokenuri.tokenURI(_tokenId);
        }
        return
           string(abi.encodePacked(ERC721A.tokenURI(_tokenId), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getBurnMintCount(address _address)
        external
        view
        returns (uint256)
    {
        return
            burnMintStructs[burnMintIndex].numberOfBurnMintByAddress[_address];
    }
    
    // to avoid renounce to undefined address
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(msg.sender));
    }

}