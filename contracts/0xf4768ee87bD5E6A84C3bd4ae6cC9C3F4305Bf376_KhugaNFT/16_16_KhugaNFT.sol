// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a-contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

contract KhugaNFT is
    ERC721A,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

	struct mintStage{
		bytes32 					merkleRoot; // whitelist only
		mapping(address => uint256) amountClaimed;
		uint256						cost;
		uint256						maxAmountPerAddress;
		uint256						maxAmountPerTx;
	}

	uint256 public maxSupply = 5555;
    bool public paused = false;
    uint256 currMintStage = 255; // Placeholder for disable all mints
	mintStage[] public mintStages;

    string public uriPrefix;
    string public uriSuffix = ".json";

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {
		mintStage storage miawlistMintStage = mintStages.push();
		miawlistMintStage.merkleRoot = 0x00;
		miawlistMintStage.cost = 20000000000000000;
		miawlistMintStage.maxAmountPerAddress = 1;
		miawlistMintStage.maxAmountPerTx = 1;

		mintStage storage allowlistMintStage = mintStages.push();
		allowlistMintStage.merkleRoot = 0x00;
		allowlistMintStage.cost = 20000000000000000;
		allowlistMintStage.maxAmountPerAddress = 1;
		allowlistMintStage.maxAmountPerTx = 1;

		mintStage storage publicMintStage = mintStages.push();	
		publicMintStage.merkleRoot = 0x00;
		publicMintStage.cost = 25000000000000000;
		publicMintStage.maxAmountPerAddress = 2;
		publicMintStage.maxAmountPerTx = 2;
	}

    modifier notContract() {
        require(!_isContract(_msgSender()), "NOT_ALLOWED_CONTRACT");
        require(_msgSender() == tx.origin, "NOT_ALLOWED_PROXY");
        _;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    modifier mintCompliance(uint256 _stage, uint256 _mintAmount) {
        require(
			currMintStage == _stage, 
			"The sales stage is not yet started!"
		);

        require(
            !paused,
            "Contract is paused!"
        );

        require(
            _mintAmount > 0 && _mintAmount <= mintStages[_stage].maxAmountPerTx,
            "Invalid mint amount!"
        );

        require(
			mintStages[_stage].amountClaimed[_msgSender()] + _mintAmount <= mintStages[_stage].maxAmountPerAddress,
			"Maximum claim amount reached!"
		);

        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );

        require(msg.value >= mintStages[_stage].cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _whitelistLevel, uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_whitelistLevel, _mintAmount)
    {
        // Verify whitelist requirements
		require(_whitelistLevel <= 1, "Invalid whitelist level"); // there are only 2 levels of whitelist
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, mintStages[_whitelistLevel].merkleRoot, leaf),
            "Invalid proof!"
        );

        mintStages[_whitelistLevel].amountClaimed[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        notContract
        mintCompliance(2, _mintAmount)
    {
		mintStages[2].amountClaimed[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    // Reserve tokens
    function reserveTokens(address _receiver, uint256 _mintAmount)
        public
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        address to = _receiver;
        _safeMint(to, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Set Token Metadata Uri
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // Set Current Mint Price
    function setCost(uint256 _stage, uint256 _cost) public onlyOwner {
        mintStages[_stage].cost = _cost;
    }

    // Set Max Mint Amount
    function setMaxMintAmountPerTx(uint256 _stage, uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        mintStages[_stage].maxAmountPerTx = _maxMintAmountPerTx;
    }

    // Set Token Uri Prefix
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    // Set Token Uri Suffix
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // Set Whitelist Root Hash
    function setMerkleRoot(uint256 _whitelistLevel, bytes32 _merkleRoot) public onlyOwner {
		require(_whitelistLevel <= 1, "Invalid whitelist level");
        mintStages[_whitelistLevel].merkleRoot = _merkleRoot;
    }

    function pauseContract(bool pause) public onlyOwner{
		paused = pause;
    }

    function setRoyalties(address _recipient, uint96 _amount) 
        external 
        onlyOwner 
    {
        _setDefaultRoyalty(_recipient, _amount);
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721A, ERC2981) 
        returns (bool) 
    {
        // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

	function getMerkleRoot(uint256 _whitelistLevel) public onlyOwner view returns (bytes32){
		require(_whitelistLevel <= 1, "Invalid whitelist level");
        return mintStages[_whitelistLevel].merkleRoot;
    }

    // Set Whitelist Status
    function setMintStage(uint256 _stage) public onlyOwner {
		require(_stage <= 2, "Invalid Mint Stage");
        currMintStage = _stage;
    }

    function getClaimedAmount(uint256 _stage, address minter) public view returns (uint256) {
        return mintStages[_stage].amountClaimed[minter];
    }

	function getMintStage() public view returns (uint256) {
        return currMintStage;
    }

    function getMintCost(uint256 _stage) public view returns (uint256) {
        return mintStages[_stage].cost;
    }

    /* Opensea Operator Filter Registry */
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

    // Fund Withdrawal
    function withdrawFund() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "Balance is zero");
        transferFund(payable(0xBBC9F1C3ab6bb5ebfE284c1843EBf3A7aBc4aADd), address(this).balance);
    }

    function transferFund(address payable _recipient, uint256 _amount) internal {
        require(
            address(this).balance >= _amount,
            "Address: insufficient balance"
        );

        (bool success, ) = _recipient.call{value: _amount}("");
        require(
            success,
            "Failed to transfer fund!"
        );
    }
}