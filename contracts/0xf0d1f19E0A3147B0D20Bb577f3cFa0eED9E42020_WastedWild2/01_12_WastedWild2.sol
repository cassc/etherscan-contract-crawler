// SPDX-License-Identifier: MIT

    import "erc721a/contracts/ERC721A.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/math/SafeMath.sol";

    pragma solidity ^0.8.0;

    contract WastedWild2 is ERC721A, Ownable {
        using SafeMath for uint256;

        //price variables
        uint256 public constant PRICE_PER_TOKEN = 0.05 ether;
        uint256 public constant ARBO_HODLER_PRICE = 0.02 ether;

        //supply variables
        uint256 public _maxSupply = 3000;
        uint256 public _maxPerTxn = 3;

        //sale state control variables
        bool public _isClaimingEnabled = true;
        bool public _isArboMintingEnabled = true;
        bool public _isPublicMintingEnabled = true;
        bool public _isBurningEnabled = true;
        uint256 public _startSaleTimestamp = 1648216800; //3/25/2022 10:00AM EST
        uint256 public _whiteListWindow = 172800; //48 hours

        //wallet to withdraw to
        address payable public _abar =
            payable(address(0x96f10441b25f56AfE30FDB03c6853f0fEC70F389));

        //metadata variables
        string private _baseURI_ = "ipfs://QmW1iuCkEcVekJHtW1wR4S2DUu8Qvsvwfifwch3waRa33f/";

        //wawi claimed mapping
        mapping(address => uint256) public _wawiHoldings;

        //arbo minted mapping
        mapping(address => uint256) public _arboHoldings;

        //white lsit mapping
        mapping(address => uint256) public _whiteList;

        constructor() ERC721A("Wasted Wild V2", "WAWI2") {
        }

        //supply functions
        function setMaxSupply(uint256 maxSupply) external onlyOwner {
            _maxSupply = maxSupply;
        }

        function setMaxPerTxn(uint256 maxPerTxn) external onlyOwner {
            _maxPerTxn = maxPerTxn;
        }

        //sale state functions
        function toggleClaimingEnabled() external onlyOwner {
            _isClaimingEnabled = !_isClaimingEnabled;
        }

        function toggleArboMintingEnabled() external onlyOwner {
            _isArboMintingEnabled = !_isArboMintingEnabled;
        }

        function togglePublicMintingEnabled() external onlyOwner {
            _isPublicMintingEnabled = !_isPublicMintingEnabled;
        }

        function toggleBurningEnabled() external onlyOwner {
            _isBurningEnabled = !_isBurningEnabled;
        }

        function setStartSaleTimestamp(uint256 startSaleTimestamp) external onlyOwner {
            _startSaleTimestamp = startSaleTimestamp;
        }

        function setWhiteListWindow(uint256 whiteListWindow) external onlyOwner {
            _whiteListWindow = whiteListWindow;
        }

        //allow list mapping functions
        function setWawiHoldings(address[] calldata addresses, uint256[] calldata wawiBalance) external onlyOwner {
            uint256 count = addresses.length;
            for (uint256 i = 0; i < count; i++) {
                _wawiHoldings[addresses[i]] = wawiBalance[i];
            }
        }

        function setArboHoldings(address[] calldata addresses) external onlyOwner {
            uint256 count = addresses.length;
            for (uint256 i = 0; i < count; i++) {
                _arboHoldings[addresses[i]] = 1;
            }
        }

        function setWhiteList(address[] calldata addresses) external onlyOwner {
            uint256 count = addresses.length;
            for (uint256 i = 0; i < count; i++) {
                _whiteList[addresses[i]] = 1;
            }
        }

        //minting functions
        function _mintToken(address to, uint256 quantity) internal {
            _safeMint(to, quantity);
        }

        //for duplicating WAWI1 tokens
        function airdrop(address to, uint256 quantity) external onlyOwner {
            _mintToken(to, quantity);
        }

        function reserveTokens(uint256 quantity) external onlyOwner {
            _mintToken(msg.sender, quantity);
        }

        function claim() external{
            require(block.timestamp >= _startSaleTimestamp, "claiming has not started");
            require(_isClaimingEnabled, "claiming is not enabled");
            require(totalSupply() < _maxSupply, "sold out");
            require(totalSupply() + _wawiHoldings[msg.sender] <= _maxSupply, "exceeds max supply");
            require(
                _wawiHoldings[msg.sender] > 0,
                "No WAWI token or already claimed"
            );

            _mintToken(msg.sender, _wawiHoldings[msg.sender]);
            
            _wawiHoldings[msg.sender] = 0;
        }

        function arboHolderMint(uint256 tokensToMint) external payable {
            require(block.timestamp >= _startSaleTimestamp, "tree holders minting has not started");
            require(_isArboMintingEnabled, "minting is not enabled");
            require(totalSupply() < _maxSupply, "sold out");
            require(totalSupply() + tokensToMint <= _maxSupply, "exceeds max supply");
            require(tokensToMint <=_maxPerTxn, "max 3 tokens per txn");
            require(_arboHoldings[msg.sender] > 0, "no ARBO token or already claimed");
            require(msg.value == tokensToMint * ARBO_HODLER_PRICE, "wrong value");

            _mintToken(msg.sender, tokensToMint);
            
            _arboHoldings[msg.sender] = 0;
        }

        function publicMint(uint256 tokensToMint) external payable {
            require(block.timestamp >= _startSaleTimestamp, "minting has not started");

            if(block.timestamp < _startSaleTimestamp + _whiteListWindow){
                require(_whiteList[msg.sender] > 0, "need to be on whitelist to mint during this window");
            }

            require(_isPublicMintingEnabled, "minting is not enabled");
            require(totalSupply() < _maxSupply, "sold out");
            require(totalSupply() + tokensToMint <= _maxSupply, "exceeds max supply");  
            require(tokensToMint <= _maxPerTxn, "max 3 tokens per txn");
            require(msg.value == tokensToMint * PRICE_PER_TOKEN, "wrong value");

            _mintToken(msg.sender, tokensToMint);

            _whiteList[msg.sender] = 0;
        }

        function burn(uint256 tokenId) public {
            require(_isBurningEnabled, "burning is not enabled");
            _burn(tokenId, true);
        }

        function withdraw() external onlyOwner {
            uint256 balance = address(this).balance;
            _abar.transfer(balance);
        }

        function _baseURI() internal view override returns (string memory) {
            return _baseURI_;
        }

        function setBaseURI(string memory newBaseURI) public onlyOwner {
            _baseURI_ = newBaseURI;
        }
    }