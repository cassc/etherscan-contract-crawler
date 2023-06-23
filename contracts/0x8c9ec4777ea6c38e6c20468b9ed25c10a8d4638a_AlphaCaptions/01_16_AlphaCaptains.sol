/*
 * Disclaimer: alphAI alfas NFTs and its project alphAI are intended for educational, entertainment, and experimental purposes only.
 * The information provided in our content, communications, and any other materials should not be construed as financial, investment, legal, or any other form of professional advice. By engaging with the Token and project, you acknowledge that you are participating in a high-risk experiment and assume full responsibility for any decisions you make. We strongly encourage individuals to conduct their own research and consult with qualified professionals before participating in any blockchain, cryptocurrency, or token-related activities.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AlphaCaptions is ERC721Upgradeable, OwnableUpgradeable {
    using Strings for uint256;

    string private _baseURIextended;
    string public unrevealURI;
    bool public reveal;

    string public mintStep;
    bool public mintPause;

    uint256 public mintPrice;
    uint256 public mintLimit;

    uint256 public startTime;

    IERC20 public tokenAddress;
    uint256 public whaleTokenAmount;
    uint256 public MAX_NFT_SUPPLY;
    uint8 public mintCounter;

    mapping(address => uint256) public referralMintCount;

    event MintNFT(
        address indexed _minter,
        uint256 _amount,
        address indexed _referrer
    );

    function initialize() public initializer {
        __Ownable_init();
        __ERC721_init("AlphaCaptions", "$ALPAH");

        unrevealURI = "https://peach-dear-puffin-631.mypinata.cloud/ipfs/QmeoJ2WdrLJ3mvA7Go5JWfr5Ua9pyq9Q1DZ6tS8q9eAXnS";
        tokenAddress = IERC20(0xF68415bE72377611e95d59bc710CcbBbf94C4Fa2);
        whaleTokenAmount = 1000000 * 10 ** 18;
        MAX_NFT_SUPPLY = 999;

        mintPrice = 69 * 10 ** 15;
        mintLimit = 10;
        mintPause = false;

        startTime = 1687467600;
    }

    function mint(
        address _receiver,
        uint256 _quantity,
        address _referrer
    ) private {
        for (uint256 i = 0; i < _quantity; i++) {
            require(mintCounter < MAX_NFT_SUPPLY, "Sale has already ended");
            mintCounter = mintCounter + 1;
            _safeMint(_receiver, mintCounter);
        }

        if (_referrer != address(0)) {
            referralMintCount[_receiver] = referralMintCount[_receiver] + 1;
        }
        emit MintNFT(msg.sender, _quantity, _referrer);
    }

    function mintNFTForOwner(uint256 _amount) public onlyOwner {
        mint(msg.sender, _amount, address(0));
    }

    function mintNFT(uint256 _quantity, address _referrer) public payable {
        require(_referrer != msg.sender, "Invalid referral address");
        require(_quantity > 0, "Invalid mint amount");
        require(mintPrice * _quantity <= msg.value, "ETH value is not correct");
        require(
            balanceOf(msg.sender) + _quantity <= mintLimit,
            "Exceeded Mint Count"
        );
        require(!mintPause, "Mint Paused.");

        if (
            block.timestamp > (startTime - 3600) &&
            tokenAddress.balanceOf(msg.sender) > whaleTokenAmount
        ) {
            mint(msg.sender, _quantity, _referrer);
            return;
        }

        require(startTime < block.timestamp, "Mint Time is not yet.");
        mint(msg.sender, _quantity, _referrer);
    }

    function withdraw() external onlyOwner {
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(address(this).balance);
    }

    function getReferralMintCount(
        address _user
    ) external view returns (uint256) {
        return referralMintCount[_user];
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!reveal) return unrevealURI;
        return
            bytes(_baseURIextended).length > 0
                ? string(
                    abi.encodePacked(
                        _baseURIextended,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setUnrevealURI(string memory _uri) external onlyOwner {
        unrevealURI = _uri;
    }

    function Reveal() public onlyOwner {
        reveal = true;
    }

    function UnReveal() public onlyOwner {
        reveal = false;
    }

    function setMintState(
        string memory _mintStep,
        uint256 _mintPrice,
        uint256 _mintLimit,
        bool _startNow
    ) external onlyOwner {
        mintStep = _mintStep;
        mintPrice = _mintPrice;
        mintLimit = _mintLimit;
        mintPause = !_startNow;
    }

    function getMintState()
        public
        view
        returns (
            string memory _mintStep,
            bool _mintPause,
            uint256 _mintLimit,
            uint256 _mintPrice
        )
    {
        _mintStep = mintStep;
        _mintPause = mintPause;
        _mintLimit = mintLimit;
        _mintPrice = mintPrice;
    }

    function setMaxSupply(uint256 _maxSupply) external {
        MAX_NFT_SUPPLY = _maxSupply;
    }

    function pause() public onlyOwner {
        mintPause = true;
    }

    function unPause() public onlyOwner {
        mintPause = false;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function settokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = IERC20(_tokenAddress);
    }
}