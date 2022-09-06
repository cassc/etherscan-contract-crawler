// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "erc721psi/contracts/ERC721Psi.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
pragma solidity ^0.8.9;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
contract BodegaAirdrop is 
    ERC721Psi, 
    Ownable, 
    ReentrancyGuard
{
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    bytes32 public root;

    uint256 public maxSupply = 111;
    uint256 public airdropAmountLimit = 1;

    string public baseURI; 
    string public notRevealedUri = "ipfs://QmYUuwLoiRb8woXwJCCsr1gvbr8E21KuxRtmVBmnH1tZz7/hidden.json";
    string public baseExtension = ".json";

    Counters.Counter private _tokenIds;
    mapping(uint256 => address) public airdropAddresses;
    AggregatorV3Interface internal eth_usd_price_feed;
    IERC20 USDT;
    IERC20 USDC;
    uint256 USDT_DECIMAl = 10**6;
    uint256 USDC_DECIMAL = 10**6;
    uint256 default_decimal = 10**18;
    uint256 eth_usd_decimal = 10**8;
    uint256 public usdPrice = 300*eth_usd_decimal;

    constructor(string memory uri, bytes32 merkleroot)
        ERC721Psi("BodegaAirdrop", "NFT")
        ReentrancyGuard()
    {
        root = merkleroot;
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        eth_usd_price_feed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        setBaseURI(uri);
    }

    /**
     * Returns the ETH To USD Price
     */
    function getETHToUSD() public view returns (uint256) {
        (
            ,
            int256 answer,
            ,
            ,
        ) = eth_usd_price_feed.latestRoundData();
        return uint256(answer);
    }

    function getEthAmount() public view returns (uint256) {
        uint256 eth_to_usd = getETHToUSD();
        return default_decimal*usdPrice/eth_to_usd;
    }

    function getUSDTAllowance() public view returns(uint256){
        return USDT.allowance(msg.sender, address(this));
    }

    function getUSDCAllowance() public view returns(uint256) {
        return USDC.allowance(msg.sender, address(this));
    }

    function changeUSDPrice(uint256 price) public onlyOwner {
        usdPrice = price;
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }

    function airdrop(address account, uint256 _amount, uint256 cryptotype, uint256 coinamount,bytes32[] calldata _proof) 
    external 
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "Not allowed");
        require(_amount > 0, "zero amount");
        require(_amount <= airdropAmountLimit, "Airdrop AmountLimit");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Max supply exceeded"
        );

        if(cryptotype == 0){
            require(
                getEthAmount() * _amount <= msg.value,
                "Not enough ethers sent"
            );
        }else if(cryptotype == 1){
            require(coinamount <= getUSDTAllowance(), "Please approve tokens before transferring");
            require(usdPrice * _amount <= (coinamount*eth_usd_decimal/USDT_DECIMAl) ,"Not enough usdt sent");
            USDT.safeTransferFrom(msg.sender, address(this), coinamount);
        }else if(cryptotype == 2) {
            require(coinamount <= getUSDCAllowance(), "Please approve tokens before transferring");
            require(usdPrice * _amount <= (coinamount*eth_usd_decimal/USDC_DECIMAL) ,"Not enough usdc sent");
            USDC.safeTransferFrom(msg.sender, address(this), coinamount);
        }else{
            return;
        }

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, 1);
        airdropAddresses[tokenId] = msg.sender;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
    
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        root = merkleroot;
    }

    function setAirdropAmountLimit(uint256 amount)
        public
        onlyOwner
    {
        airdropAmountLimit = amount;
    }

    function totalSupply() public override view returns (uint) {
        return _tokenIds.current();
    }

    function withdraw(uint256 cryptotype) external onlyOwner {
        if(cryptotype == 0) {
            payable(msg.sender).transfer(address(this).balance); 
        }else if(cryptotype == 1) {
            USDT.safeTransfer(msg.sender, USDT.balanceOf(address(this)));
        }else {
            USDC.safeTransfer(msg.sender, USDC.balanceOf(address(this)));
        }
    }
}