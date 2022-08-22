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

contract Lotus is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum SalesConfig {
        NOT_YET,
        OK_FINE,
        IT_IS_OVER
    }

    SalesConfig public currentSaleState;

    uint16 public immutable maxTokenCount;
    uint256 public erc20PerToken;
    uint8 public immutable erc20Decimals;

    ERC20 private mErc20;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// @dev metadata URI
    string private _baseTokenURI;

    /// @param _maxTokenCount Maximum supply of tokens
    /// @param _reservedTokenCount Number of tokens to mint to team
    /// @param _erc20Address address for erc-20
    /// @param _erc20PerToken Num of erc20 to mint one token
    /// @param _teamAddress address to mint remainder of reserve
    constructor(
        uint16 _maxTokenCount,
        uint16 _reservedTokenCount,
        address _erc20Address,
        uint256 _erc20PerToken,
        address _teamAddress
    ) ERC721A("Lotus", "LOTUS") {
        require(
            _reservedTokenCount < _maxTokenCount,
            "reserve cannot be greater than max token count"
        );
        mErc20 = ERC20(_erc20Address);
        erc20Decimals = mErc20.decimals();
        maxTokenCount = _maxTokenCount;
        currentSaleState = SalesConfig.NOT_YET;
        setErc20PerToken(_erc20PerToken);
        _safeMint(_teamAddress, _reservedTokenCount);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setErc20PerToken(uint256 _erc20PerToken) public onlyOwner {
        erc20PerToken = _erc20PerToken;
    }

    function publicMint(uint256 quantity) external nonReentrant {
        require(
            currentSaleState == SalesConfig.OK_FINE,
            "public mint is not open"
        );
        require(
            _totalMinted() + quantity <= maxTokenCount,
            "not enough supply available"
        );

        require(
            mErc20.transferFrom(
                msg.sender,
                BURN_ADDRESS,
                quantity * erc20PerToken
            ),
            "cannot burn erc20, check your approval amount"
        );

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