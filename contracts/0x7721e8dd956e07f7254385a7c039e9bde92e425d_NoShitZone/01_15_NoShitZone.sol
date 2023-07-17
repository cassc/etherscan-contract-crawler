// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract NoShitZone is ERC1155, ERC2981, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint32 public constant TOTAL_SUPPLY = 10000;
    uint32 public constant WALLET_LIMIT = 2;
    uint32 public constant LEGENDARY_SUPPLY = 7;
    uint32 public constant DOPE_SUPPLY = 3905 - 4; // Minus legendary
    uint32 public constant BASIC_SUPPLY = 6095 - 3; // Minus legendary
    uint32 public constant LEGENDARY_ID = 0;
    uint32 public constant DOPE_ID = 1;
    uint32 public constant BASIC_ID = 2;

    IERC20 public immutable _shitCoin;

    struct Status {
        uint32 basicSupply;
        uint32 basicMinted;
        uint32 walletLimit;
        uint256 ethPrice;
        uint256 shitPrice;
        uint32 userMinted;
        bool started;
        bool soldout;
    }

    uint32 public _legendaryMinted;
    uint32 public _dopeMinted;
    uint32 public _basicMinted;
    mapping(address => uint32) public _userMinted;

    address public _burner;
    bool public _started;
    uint256 public _shitPrice;
    uint256 public _ethPrice;
    string public _metadataURI = "https://metadata.pieceofshit.wtf/cleaner/";

    constructor(address shitCoin) ERC1155("") {
        require(LEGENDARY_SUPPLY + DOPE_SUPPLY + BASIC_SUPPLY == TOTAL_SUPPLY);

        _shitCoin = IERC20(shitCoin);
    }

    function purchase(uint32 amount, bool useEth) external payable {
        require(tx.origin == msg.sender, "NoShitZone: ?");
        require(_started, "NoShitZone: Not Started");

        _userMinted[msg.sender] += amount;
        require(_userMinted[msg.sender] <= WALLET_LIMIT, "NoShitZone: Exceed wallet limit");

        if (useEth) {
            require(msg.value == _ethPrice * amount, "NoShitZone: Insufficient Fund");
        } else {
            require(_shitCoin.transferFrom(msg.sender, address(this), _shitPrice * amount), "NoShitZone: Insufficient Fund");
        }

        internalMint(msg.sender, BASIC_ID, amount);
    }

    function airdrop(
        uint32 id,
        address[] memory tos,
        uint32[] memory amounts
    ) external onlyOwner {
        require(tos.length == amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) internalMint(tos[i], id, amounts[i]);
    }

    function internalMint(
        address minter,
        uint32 id,
        uint32 amount
    ) internal {
        if (id == LEGENDARY_ID) {
            _legendaryMinted += amount;
            require(_legendaryMinted <= LEGENDARY_SUPPLY, "ShitPlunger: Exceed max supply");
        } else if (id == DOPE_ID) {
            _dopeMinted += amount;
            require(_dopeMinted <= DOPE_SUPPLY, "ShitPlunger: Exceed max supply");
        } else if (id == BASIC_ID) {
            _basicMinted += amount;
            require(_basicMinted <= BASIC_SUPPLY, "ShitPlunger: Exceed max supply");
        } else {
            require(false, "NoShitZone: WTF is that NoShitZone");
        }

        _mint(minter, id, amount, "");
    }

    function burn(
        address who,
        uint32 amount,
        uint32 id
    ) external {
        require(msg.sender == _burner, "ShitPlunger: ?");

        _burn(who, id, amount);
    }

    function _status(address minter) public view returns (Status memory) {
        return
            Status({
                basicSupply: BASIC_SUPPLY,
                basicMinted: _basicMinted,
                walletLimit: WALLET_LIMIT,
                ethPrice: _ethPrice,
                shitPrice: _shitPrice,
                userMinted: _userMinted[minter],
                started: _started,
                soldout: _basicMinted >= BASIC_SUPPLY
            });
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, id.toString(), ".json"));
    }

    function setMetadataURI(string memory metadataURI) external onlyOwner {
        _metadataURI = metadataURI;
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setEthPrice(uint256 price) public onlyOwner {
        _ethPrice = price;
    }

    function setShitPrice(uint256 price) public onlyOwner {
        _shitPrice = price;
    }

    function setStarted(bool started) public onlyOwner {
        _started = started;
    }

    function withdrawFund(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            payable(msg.sender).sendValue(address(this).balance);
        } else {
            IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
        }
    }

    function name() public pure returns (string memory) {
        return "NoShitZone";
    }

    function symbol() public pure returns (string memory) {
        return "NOSHIT";
    }
}