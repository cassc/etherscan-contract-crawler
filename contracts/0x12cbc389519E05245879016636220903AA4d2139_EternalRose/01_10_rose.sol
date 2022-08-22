// SPDX-License-Identifier: MIT
// .__          __
// |  |   _____/  |_ __ __  ______
// |  |  /  _ \   __\  |  \/  ___/
// |  |_(  <_> )  | |  |  /\___ \
// |____/\____/|__| |____//____  >
//                             \/

pragma solidity ^0.8.10;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EternalRose is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum SalesConfig {
        NOT_YET,
        OK_FINE,
        IT_IS_OVER
    }

    SalesConfig public currentSaleState;

    uint16 public immutable maxTokenCount;
    uint16 public immutable maxMintPerAddress;
    uint256 public weiPerToken;
    string private _baseTokenURI;

    mapping(address => uint16) public mintedPerAddress;

    /// @param _maxTokenCount Maximum supply of tokens
    /// @param _reservedTokenCount Number of tokens to mint to team
    /// @param _weiPerToken Num of wei to mint one token
    /// @param _teamAddress address to mint remainder of reserve
    /// @param _airdropAddresses array of addresses to airdop tokens, expects < _reserveTokenCount
    constructor(
        uint16 _maxTokenCount,
        uint16 _reservedTokenCount,
        uint16 _maxMintPerAddress,
        uint256 _weiPerToken,
        address _teamAddress,
        address[] memory _airdropAddresses
    ) ERC721A("Eternal Rose", "EROSE") {
        require(
            _reservedTokenCount < _maxTokenCount,
            "reserve cannot be greater than max token count"
        );

        require(
            _airdropAddresses.length <= _reservedTokenCount,
            "too many addresses in airdrop list"
        );

        maxTokenCount = _maxTokenCount;
        maxMintPerAddress = _maxMintPerAddress;
        currentSaleState = SalesConfig.NOT_YET;
        setWeiPerToken(_weiPerToken);

        for (uint16 i = 0; i < _airdropAddresses.length; i++) {
            // mint reserve to the treasury
            _safeMint(_airdropAddresses[i], 1);
        }

        _safeMint(_teamAddress, _reservedTokenCount - _airdropAddresses.length);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setWeiPerToken(uint256 _weiPerToken) public onlyOwner {
        weiPerToken = _weiPerToken;
    }

    function publicMint(uint16 quantity) external payable nonReentrant {
        require(
            currentSaleState == SalesConfig.OK_FINE,
            "public mint is not open"
        );

        mintedPerAddress[msg.sender] += quantity;

        require(
            mintedPerAddress[msg.sender] <= maxMintPerAddress,
            "Can't mint more than maxMintPerAddress"
        );

        require(
            _totalMinted() + quantity <= maxTokenCount,
            "not enough supply available"
        );

        require(msg.value == quantity * weiPerToken, "incorrect mint price");
        _safeMint(msg.sender, quantity);

        // better safe than sorry.
        require(_totalMinted() <= maxTokenCount, "Max tokens already minted");
    }

    function startSale() external onlyOwner {
        currentSaleState = SalesConfig.OK_FINE;
    }

    function pauseSale() external onlyOwner {
        currentSaleState = SalesConfig.NOT_YET;
    }

    function endSale() external onlyOwner {
        currentSaleState = SalesConfig.IT_IS_OVER;
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
                        ".json"
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Something went wrong.");
    }
}